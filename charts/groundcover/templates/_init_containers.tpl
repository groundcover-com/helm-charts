{{/*
Generic init container to wait for an HTTP endpoint to be ready.

Parameters:
  - root: The root context ($)
  - name: Container name (e.g., "check-ingestion-endpoint-ready")
  - env: The environment variables to include (e.g., .Values.agent.initContainers.checkIngestion.builtinEnv)
  - url: The URL to check
  - expectedCode: Expected HTTP status code (e.g., "200", "204")
  - serviceName: Human-readable service name for log messages

Usage:
  {{- include "groundcover.initContainer.waitForEndpoint" (dict 
      "root" $ 
      "name" "check-ingestion-endpoint-ready"
      "env" .Values.agent.initContainers.checkIngestion.builtinEnv
      "url" (include "ingestion.health.http.url" .)
      "expectedCode" "200"
      "serviceName" "ingestion endpoint"
  ) | nindent 8 }}
*/}}
{{- define "groundcover.initContainer.waitForEndpoint" -}}
- name: {{ .name }}
  env:
  {{- with .env }}
    {{ tpl (toYaml .) $.root | nindent 4 }}
  {{- end }}
  args:
  - |
      while true; do
        RESPONSE=$(mktemp)
        HTTP_CODE=$(curl -H "apikey:$API_KEY" \
      {{- if .root.Values.global.ingestion.tls_skip_verify }}
        -k \
      {{- end }}
        -sw '%{http_code}' {{ .url }} -o "$RESPONSE")
        if [ "$HTTP_CODE" -eq {{ .expectedCode }} ]; then
          rm -f "$RESPONSE"
          break
        fi
        echo "Waiting for {{ .serviceName }}... (HTTP $HTTP_CODE)"
        if [ -s "$RESPONSE" ]; then
          echo "Response: $(cat "$RESPONSE")"
        fi
        rm -f "$RESPONSE"
        sleep 2
      done
      echo {{ .serviceName }} is up
  command:
    - /bin/sh
    - -c
  image: '{{ tpl .root.Values.curl.image.repository .root }}:{{ tpl .root.Values.curl.image.tag .root }}'
{{- end -}}

