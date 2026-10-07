//go:build helmtest

package groundcover_test

import (
	"bytes"
	"context"
	"errors"
	"io"
	"os/exec"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"

	"groundcover.com/internal/testpath"
)

const investigationRelease = "inv-test"

type probe struct {
	HTTPGet struct {
		Path string `yaml:"path"`
		Port string `yaml:"port"`
	} `yaml:"httpGet"`
}

type renderedObject struct {
	Kind     string `yaml:"kind"`
	Metadata struct {
		Name string `yaml:"name"`
	} `yaml:"metadata"`
	Spec struct {
		Replicas       *int `yaml:"replicas"`
		MaxUnavailable any  `yaml:"maxUnavailable"` // int or percentage string across the chart
		Template       struct {
			Spec struct {
				AutomountServiceAccountToken *bool `yaml:"automountServiceAccountToken"`
				InitContainers               []struct {
					Name string   `yaml:"name"`
					Args []string `yaml:"args"`
				} `yaml:"initContainers"`
				Containers []struct {
					ReadinessProbe probe `yaml:"readinessProbe"`
					LivenessProbe  probe `yaml:"livenessProbe"`
					Env            []struct {
						Name string `yaml:"name"`
					} `yaml:"env"`
				} `yaml:"containers"`
			} `yaml:"spec"`
		} `yaml:"template"`
	} `yaml:"spec"`
	Data map[string]string `yaml:"data"`
}

func renderInvestigationChart(t *testing.T, args ...string) []renderedObject {
	t.Helper()
	args = append([]string{"template", investigationRelease, testpath.Join(t, "k8s", "groundcover"), "--set", "clusterId=inv-test"}, args...)
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	out, err := exec.CommandContext(ctx, "helm", args...).CombinedOutput()
	require.NoError(t, err, string(out))

	var objects []renderedObject
	dec := yaml.NewDecoder(bytes.NewReader(out))
	for {
		var obj renderedObject
		if err := dec.Decode(&obj); err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			require.NoError(t, err)
		}
		if obj.Kind != "" {
			objects = append(objects, obj)
		}
	}
	return objects
}

func investigationServiceObjects(objects []renderedObject) map[string]renderedObject {
	byKind := map[string]renderedObject{}
	for _, obj := range objects {
		if strings.Contains(obj.Metadata.Name, "investigation-service") {
			byKind[obj.Kind] = obj
		}
	}
	return byKind
}

func requireInvestigationServiceRendered(t *testing.T, objects map[string]renderedObject) {
	t.Helper()
	require.ElementsMatch(t, []string{"Deployment", "Service", "ConfigMap", "PodDisruptionBudget"}, keys(objects))
	deployment := objects["Deployment"]
	require.NotNil(t, deployment.Spec.Replicas)
	require.Equal(t, 2, *deployment.Spec.Replicas)
	var initContainers []string
	for _, c := range deployment.Spec.Template.Spec.InitContainers {
		initContainers = append(initContainers, c.Name)
	}
	require.Equal(t, []string{"wait-for-db", "wait-for-temporal", "ensure-temporal-namespace"}, initContainers,
		"the service starts only once Postgres, Temporal and its namespace are ready")
	require.Equal(t, 1, objects["PodDisruptionBudget"].Spec.MaxUnavailable)
	config := renderedConfig(t, objects)
	for _, key := range []string{
		"server.port", "server.healthPort", "server.metricsPort",
		"postgres.host", "postgres.port", "postgres.name", "postgres.adminDbName", "postgres.user", "postgres.pass",
		"postgres.sslmode", "postgres.timeout", "postgres.interval", "postgres.maxConns", "postgres.enableTracing",
		"migrationsPath", "temporal.host", "temporal.port", "temporal.namespace",
		"telemetry.traces.enabled", "telemetry.instrumentation.serviceName", "telemetry.instrumentation.originCluster",
		"telemetry.pprof.enabled",
	} {
		_, ok := lookup(config, key)
		require.True(t, ok, "the chart declares %s; the service has no defaults", key)
	}
	name, _ := lookup(config, "postgres.name")
	require.Equal(t, "investigations", name, "the service owns the investigations database")
	pass, _ := lookup(config, "postgres.pass")
	require.Equal(t, "", pass, "the password comes from GC_POSTGRES_PASS")
	container := deployment.Spec.Template.Spec.Containers[0]
	require.Equal(t, "/ready", container.ReadinessProbe.HTTPGet.Path, "ready only once the service serves")
	require.Equal(t, "/health", container.LivenessProbe.HTTPGet.Path)
	require.Equal(t, "health-http", container.ReadinessProbe.HTTPGet.Port)
	automount := deployment.Spec.Template.Spec.AutomountServiceAccountToken
	require.True(t, automount != nil && !*automount, "the service never calls the Kubernetes API, so it gets no token")
}

func TestInvestigationService_DefaultValuesRenderNothing(t *testing.T) {
	t.Parallel()

	objects := investigationServiceObjects(renderInvestigationChart(t))

	require.Empty(t, objects, "the service is disabled by default")
}

func TestInvestigationService_EnablingItRendersTheService(t *testing.T) {
	t.Parallel()

	objects := investigationServiceObjects(renderInvestigationChart(t, "--set", "global.investigationService.enabled=true"))

	requireInvestigationServiceRendered(t, objects)
}

func renderedConfig(t *testing.T, objects map[string]renderedObject) map[string]any {
	t.Helper()
	var config map[string]any
	require.NoError(t, yaml.Unmarshal([]byte(objects["ConfigMap"].Data["config.yaml"]), &config))
	return config
}

// lookup follows a "."-separated path through nested maps.
func lookup(m map[string]any, path string) (any, bool) {
	var current any = m
	for _, key := range strings.Split(path, ".") {
		inner, ok := current.(map[string]any)
		if !ok {
			return nil, false
		}
		if current, ok = inner[key]; !ok {
			return nil, false
		}
	}
	return current, true
}

func envNames(objects map[string]renderedObject) []string {
	var names []string
	for _, e := range objects["Deployment"].Spec.Template.Spec.Containers[0].Env {
		names = append(names, e.Name)
	}
	return names
}

func TestInvestigationService_TelemetryOnExportsWithTheAPIKeyFromTheEnvironment(t *testing.T) {
	t.Parallel()

	objects := investigationServiceObjects(renderInvestigationChart(t, "--set", "global.investigationService.enabled=true"))

	config := renderedConfig(t, objects)
	enabled, _ := lookup(config, "telemetry.traces.enabled")
	require.Equal(t, true, enabled)
	pgTracing, _ := lookup(config, "postgres.enableTracing")
	require.Equal(t, true, pgTracing, "Postgres queries are traced while telemetry is on")
	for _, key := range []string{"telemetry.traces.endpoint", "telemetry.traces.headers.apikey",
		"telemetry.instrumentation.tracingTargets", "telemetry.instrumentation.metricsTargets"} {
		_, ok := lookup(config, key)
		require.True(t, ok, "telemetry on renders %s", key)
	}
	apikey, _ := lookup(config, "telemetry.traces.headers.apikey")
	require.Equal(t, "", apikey, "the key comes only from GC_TELEMETRY_TRACES_HEADERS_APIKEY; no placeholder can reach the exporter")
	require.ElementsMatch(t, []string{"GC_GROUNDCOVERVERSION", "POD_NAME", "GC_POSTGRES_PASS", "GC_TELEMETRY_TRACES_HEADERS_APIKEY"},
		envNames(objects), "secrets reach the service only through these GC_ overrides")
}

func TestInvestigationService_TelemetryOffExportsNothing(t *testing.T) {
	t.Parallel()

	objects := investigationServiceObjects(renderInvestigationChart(t,
		"--set", "global.investigationService.enabled=true", "--set", "global.telemetry.enabled=false"))

	requireInvestigationServiceRendered(t, objects)
	config := renderedConfig(t, objects)
	enabled, _ := lookup(config, "telemetry.traces.enabled")
	require.Equal(t, false, enabled)
	pgTracing, _ := lookup(config, "postgres.enableTracing")
	require.Equal(t, false, pgTracing)
	for _, key := range []string{"telemetry.traces.headers", "telemetry.instrumentation.tracingTargets", "telemetry.instrumentation.metricsTargets"} {
		_, ok := lookup(config, key)
		require.False(t, ok, "telemetry off renders no %s", key)
	}
	require.ElementsMatch(t, []string{"GC_GROUNDCOVERVERSION", "POD_NAME", "GC_POSTGRES_PASS"}, envNames(objects))
}

func TestInvestigationService_WaitsForTheDatabaseItConnectsTo(t *testing.T) {
	t.Parallel()

	objects := investigationServiceObjects(renderInvestigationChart(t, "--set", "global.investigationService.enabled=true",
		"--set", "dbManager.db.host=external-pg", "--set-string", "dbManager.db.port=6543"))

	config := renderedConfig(t, objects)
	host, _ := lookup(config, "postgres.host")
	port, _ := lookup(config, "postgres.port")
	require.Equal(t, "external-pg", host)
	require.Equal(t, "6543", port)
	waitForDB := objects["Deployment"].Spec.Template.Spec.InitContainers[0]
	require.Equal(t, "wait-for-db", waitForDB.Name)
	require.Contains(t, strings.Join(waitForDB.Args, " "), "-h external-pg")
	require.Contains(t, strings.Join(waitForDB.Args, " "), "-p 6543")
}

func keys(m map[string]renderedObject) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	return out
}
