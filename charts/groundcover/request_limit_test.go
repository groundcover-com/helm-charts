//go:build helmtest

package groundcover_test

import (
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

func renderedConcurrentRequestLimit(t *testing.T, values, configMapName string) string {
	t.Helper()
	configYAML := renderConfigMapData(t, values, configMapName, "config.yaml")
	var config struct {
		APMIngestor struct {
			Otel struct {
				Direct struct {
					MaxConcurrentRequests string `yaml:"maxConcurrentRequests"`
				} `yaml:"direct"`
			} `yaml:"otel"`
		} `yaml:"apmIngestor"`
	}
	require.NoError(t, yaml.Unmarshal([]byte(configYAML), &config))
	return config.APMIngestor.Otel.Direct.MaxConcurrentRequests
}

func TestConcurrentRequestLimitRendersForSensorAndIngestor(t *testing.T) {
	t.Parallel()

	values := `agent:
  sensor:
    apmIngestor:
      otel:
        direct:
          maxConcurrentRequests: 3
ingestor:
  apmIngestor:
    otel:
      direct:
        maxConcurrentRequests: 7
global:
  ingestor:
    apmIngestor:
      otel:
        direct:
          maxConcurrentRequests: 11
`

	require.Equal(t, "3", renderedConcurrentRequestLimit(t, values, "sensor-configuration"))
	require.Equal(t, "11", renderedConcurrentRequestLimit(t, values, "ingestor-config"))
}

func TestConcurrentRequestLimitDefaultsToUnlimited(t *testing.T) {
	t.Parallel()

	require.Equal(t, "0", renderedConcurrentRequestLimit(t, "", "sensor-configuration"))
	require.Equal(t, "0", renderedConcurrentRequestLimit(t, "", "ingestor-config"))
}

func TestConcurrentRequestLimitRejectsNegativeValues(t *testing.T) {
	t.Parallel()

	output, err := renderGroundcoverChart(t, `agent:
  sensor:
    apmIngestor:
      otel:
        direct:
          maxConcurrentRequests: -1
`)

	require.Error(t, err)
	require.Contains(t, string(output), "maxConcurrentRequests must be a non-negative integer")
}

func TestConcurrentRequestLimitRejectsMalformedValues(t *testing.T) {
	t.Parallel()

	for _, value := range []string{"false", "[]", "{}"} {
		t.Run(value, func(t *testing.T) {
			output, err := renderGroundcoverChart(t, `agent:
  sensor:
    apmIngestor:
      otel:
        direct:
          maxConcurrentRequests: `+value+"\n")

			require.Error(t, err)
			require.Contains(t, string(output), "maxConcurrentRequests must be a non-negative integer")
		})
	}
}
