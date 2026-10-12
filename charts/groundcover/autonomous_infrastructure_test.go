//go:build helmtest

package groundcover_test

import (
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

func TestK8sWatcherOptsIntoAutonomousInfrastructureWithItsChartFlag(t *testing.T) {
	t.Parallel()

	for _, tc := range []struct {
		name   string
		values string
		want   bool
	}{
		{name: "off by default", values: "", want: false},
		{name: "on with the flag", values: "global:\n  autonomousInfrastructure:\n    enabled: true\n", want: true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			var config struct {
				AutonomousInfrastructure struct {
					Enabled *bool `yaml:"enabled"`
				} `yaml:"autonomousInfrastructure"`
			}
			require.NoError(t, yaml.Unmarshal([]byte(renderConfigMapData(t, tc.values, "k8s-watcher-config", "config.yaml")), &config))
			require.NotNil(t, config.AutonomousInfrastructure.Enabled, "the watcher config must carry the flag explicitly")
			require.Equal(t, tc.want, *config.AutonomousInfrastructure.Enabled)
		})
	}
}

// The workers push their own telemetry, so the chart-wide telemetry switch has to silence them too.
func TestAutonomousInfrastructureWorkersFollowTheGlobalTelemetrySwitch(t *testing.T) {
	t.Parallel()

	const enabled = "global:\n  autonomousInfrastructure:\n    enabled: true\n"
	const disabled = enabled + "  telemetry:\n    enabled: false\n"

	for _, configMap := range []string{
		"export-limits-test-autoinfra-config",
		"export-limits-test-workload-recommendations-config",
	} {
		t.Run(configMap, func(t *testing.T) {
			t.Parallel()

			require.Equal(t, "true", renderConfigMapData(t, disabled, configMap, "OTEL_SDK_DISABLED"))
			require.Contains(t, renderConfigMapData(t, enabled, configMap, "OTEL_EXPORTER_OTLP_ENDPOINT"), ":4318")
		})
	}
}
