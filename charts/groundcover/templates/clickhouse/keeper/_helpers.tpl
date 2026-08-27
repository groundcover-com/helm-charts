{{/*
Shared keeper helpers, used by both the primary (templates/clickhouse/keeper)
and standby (templates/clickhouse/standby/keeper) StatefulSets. Callers pass
a ctx dict: "root" (top-level context), "values" (.Values.keeper or
.Values.standbyKeeper), "valuesPath" (its values.yaml key, as a string, for
resize-policy annotation paths), "nameSuffix" (composed-name suffix and
app.kubernetes.io/name label value, e.g. "clickhouse-keeper").
*/}}

{{- define "clickhouseKeeper.fullname" -}}
{{- printf "%s-%s" .root.Release.Name .nameSuffix | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "clickhouseKeeper.headlessFullname" -}}
{{- printf "%s-headless" (include "clickhouseKeeper.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "clickhouseKeeper.selectorLabels" -}}
app: {{ include "clickhouseKeeper.fullname" . }}
{{- end -}}

{{- define "clickhouseKeeper.labels" -}}
{{ include "clickhouseKeeper.selectorLabels" . }}
{{- include "groundcover.labels" .root | nindent 0 }}
app.kubernetes.io/name: {{ .nameSuffix }}
{{- end -}}

{{/*
Generate raft configuration XML for keeper nodes
*/}}
{{- define "clickhouseKeeper.raftConfiguration" -}}
<raft_configuration>
{{- $fullname := include "clickhouseKeeper.fullname" . -}}
{{- $headless := include "clickhouseKeeper.headlessFullname" . -}}
{{- $namespace := .root.Release.Namespace -}}
{{- $raftPort := .values.ports.raft | int -}}
{{- range $i := until (.values.replicas | int) }}
    <server>
        <id>{{ $i }}</id>
        <hostname>{{ $fullname }}-{{ $i }}.{{ $headless }}.{{ $namespace }}.svc.cluster.local</hostname>
        <port>{{ $raftPort }}</port>
    </server>
{{- end }}
</raft_configuration>
{{- end -}}

{{- define "clickhouseKeeper.statefulset" -}}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "clickhouseKeeper.fullname" . }}
  namespace: {{ .root.Release.Namespace }}
  labels:
    {{- include "clickhouseKeeper.labels" . | nindent 4 }}
    {{- with .values.additionalLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  replicas: {{ .values.replicas }}
  serviceName: {{ include "clickhouseKeeper.headlessFullname" . }}
  podManagementPolicy: {{ .values.podManagementPolicy }}
  updateStrategy:
    type: RollingUpdate
  selector:
    matchLabels:
      {{- include "clickhouseKeeper.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "clickhouseKeeper.selectorLabels" . | nindent 8 }}
        {{- include "groundcover.labels" .root | nindent 8 }}
        {{- with .values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- with .values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- with .values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if .values.priorityClassName }}
      priorityClassName: {{ .values.priorityClassName }}
      {{- end }}
      imagePullSecrets: {{ include "imagePullSecrets" .root }}
      securityContext:
        runAsUser: {{ .values.securityContext.runAsUser }}
        fsGroup: {{ .values.securityContext.fsGroup }}
      volumes:
        - name: working-dir
          emptyDir: {}
        - name: etc-clickhouse-keeper
          emptyDir: {}
        - name: keeper-config
          configMap:
            name: {{ include "clickhouseKeeper.fullname" . }}
            items:
              - key: keeper_config.xml
                path: keeper_config.xml
      initContainers:
        - name: server-id-injector
          image: '{{ tpl .root.Values.curl.image.repository .root }}:{{ tpl .root.Values.curl.image.tag .root }}'
          command:
            - bash
            - '-xc'
            - >-
              export KEEPER_ID=${HOSTNAME##*-};
              sed "s/KEEPER_ID/${KEEPER_ID}/g" /tmp/clickhouse-keeper/keeper_config.xml > /etc/clickhouse-keeper/keeper_config.xml;
              cat /etc/clickhouse-keeper/keeper_config.xml
          volumeMounts:
            - name: keeper-config
              mountPath: /tmp/clickhouse-keeper
            - name: etc-clickhouse-keeper
              mountPath: /etc/clickhouse-keeper
      containers:
        - name: clickhouse-keeper
          image: {{ .values.image.repository }}:{{ .values.image.tag }}
          imagePullPolicy: {{ .values.image.pullPolicy }}
          ports:
            - name: client
              containerPort: {{ .values.ports.client }}
              protocol: TCP
            - name: raft
              containerPort: {{ .values.ports.raft }}
              protocol: TCP
          resources:
            {{- toYaml .values.resources | nindent 12 }}
          {{- include "groundcover.containerResizePolicy" (dict "value" .values.resizePolicy "path" (printf "%s.resizePolicy" .valuesPath) "kubeVersion" .root.Capabilities.KubeVersion.GitVersion "indent" 10) }}
          volumeMounts:
            - name: working-dir
              mountPath: /var/lib/clickhouse_keeper
            - name: both-paths
              mountPath: /var/lib/clickhouse_keeper/coordination/logs
              subPath: logs
            - name: both-paths
              mountPath: /var/lib/clickhouse_keeper/coordination/snapshots
              subPath: snapshots
            - name: etc-clickhouse-keeper
              mountPath: /etc/clickhouse-keeper
          livenessProbe:
            exec:
              command:
                - bash
                - '-xc'
                - >-
                  date && OK=$(exec 3<>/dev/tcp/127.0.0.1/{{ .values.ports.client }};
                  printf 'ruok' >&3; IFS=; tee <&3; exec 3<&-;);
                  if [[ "${OK}" == "imok" ]]; then exit 0; else exit 1; fi
            initialDelaySeconds: {{ .values.livenessProbe.initialDelaySeconds }}
            timeoutSeconds: {{ .values.livenessProbe.timeoutSeconds }}
            periodSeconds: {{ .values.livenessProbe.periodSeconds }}
            successThreshold: {{ .values.livenessProbe.successThreshold }}
            failureThreshold: {{ .values.livenessProbe.failureThreshold }}
      restartPolicy: Always
      terminationGracePeriodSeconds: {{ .values.terminationGracePeriodSeconds }}
  volumeClaimTemplates:
    - metadata:
        name: both-paths
        labels:
          {{- include "clickhouseKeeper.labels" . | nindent 10 }}
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: {{ .values.persistence.size }}
        {{- if .values.persistence.storageClass }}
        storageClassName: {{ .values.persistence.storageClass | quote }}
        {{- end }}
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Retain
    whenScaled: Retain
{{- end -}}

{{- define "clickhouseKeeper.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "clickhouseKeeper.fullname" . }}
  namespace: {{ .root.Release.Namespace }}
  labels:
    {{- include "clickhouseKeeper.labels" . | nindent 4 }}
data:
  keeper_config.xml: |
{{- if .values.config.configOverride }}
{{ tpl .values.config.configOverride .root | indent 4 }}
{{- else }}
    <clickhouse>
        <keeper_server>
            <coordination_settings>
                <min_session_timeout_ms>{{ .values.config.coordinationSettings.minSessionTimeoutMs }}</min_session_timeout_ms>
                <operation_timeout_ms>{{ .values.config.coordinationSettings.operationTimeoutMs }}</operation_timeout_ms>
                <raft_logs_level>{{ .values.config.coordinationSettings.raftLogsLevel }}</raft_logs_level>
                <session_timeout_ms>{{ .values.config.coordinationSettings.sessionTimeoutMs }}</session_timeout_ms>
            </coordination_settings>
            <hostname_checks_enabled>{{ .values.config.hostnameChecksEnabled }}</hostname_checks_enabled>
            <log_storage_path>/var/lib/clickhouse_keeper/coordination/logs</log_storage_path>
            {{ include "clickhouseKeeper.raftConfiguration" . | indent 12 }}
            <server_id>KEEPER_ID</server_id>
            <snapshot_storage_path>/var/lib/clickhouse_keeper/coordination/snapshots</snapshot_storage_path>
            <storage_path>/var/lib/clickhouse_keeper</storage_path>
            <tcp_port>{{ .values.ports.client }}</tcp_port>
        </keeper_server>
        <listen_host>0.0.0.0</listen_host>
        <logger>
            <console>true</console>
            <level>{{ .values.config.logLevel }}</level>
        </logger>
        <max_connections>{{ .values.config.maxConnections }}</max_connections>
        <openSSL>
            <server>
                <cacheSessions>true</cacheSessions>
                <certificateFile>/etc/clickhouse-keeper/server.crt</certificateFile>
                <dhParamsFile>/etc/clickhouse-keeper/dhparam.pem</dhParamsFile>
                <disableProtocols>sslv2,sslv3</disableProtocols>
                <loadDefaultCAFile>true</loadDefaultCAFile>
                <preferServerCiphers>true</preferServerCiphers>
                <privateKeyFile>/etc/clickhouse-keeper/server.key</privateKeyFile>
                <verificationMode>none</verificationMode>
            </server>
        </openSSL>
        <prometheus>
            <asynchronous_metrics>true</asynchronous_metrics>
            <endpoint>/metrics</endpoint>
            <events>true</events>
            <metrics>true</metrics>
        </prometheus>
    </clickhouse>
{{- end }}
{{- end -}}

{{- define "clickhouseKeeper.headlessService" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "clickhouseKeeper.headlessFullname" . }}
  namespace: {{ .root.Release.Namespace }}
  labels:
    {{- include "clickhouseKeeper.labels" . | nindent 4 }}
spec:
  type: ClusterIP
  clusterIP: None
  ports:
    - name: raft
      protocol: TCP
      port: {{ .values.ports.raft }}
      targetPort: {{ .values.ports.raft }}
  selector:
    {{- include "clickhouseKeeper.selectorLabels" . | nindent 4 }}
{{- end -}}

{{- define "clickhouseKeeper.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "clickhouseKeeper.fullname" . }}
  namespace: {{ .root.Release.Namespace }}
  labels:
    {{- include "clickhouseKeeper.labels" . | nindent 4 }}
spec:
  type: ClusterIP
  ports:
    - name: client
      protocol: TCP
      port: {{ .values.ports.client }}
      targetPort: {{ .values.ports.client }}
  selector:
    {{- include "clickhouseKeeper.selectorLabels" . | nindent 4 }}
{{- end -}}

{{- define "clickhouseKeeper.pdb" -}}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "clickhouseKeeper.fullname" . }}
  namespace: {{ .root.Release.Namespace }}
  labels:
    {{- include "clickhouseKeeper.labels" . | nindent 4 }}
spec:
  maxUnavailable: {{ .values.pdb.maxUnavailable }}
  selector:
    matchLabels:
      {{- include "clickhouseKeeper.selectorLabels" . | nindent 6 }}
{{- end -}}
