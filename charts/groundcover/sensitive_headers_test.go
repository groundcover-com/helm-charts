//go:build helmtest

package groundcover_test

import (
	"os"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

func defaultSensitiveHeaderKeys(t *testing.T) []string {
	t.Helper()

	_, filename, _, ok := runtime.Caller(0)
	require.True(t, ok)

	values, err := os.ReadFile(filepath.Join(filepath.Dir(filename), "values.yaml"))
	require.NoError(t, err)

	var chart struct {
		Agent struct {
			Sensor struct {
				SensitiveHeadersObfuscationConfig struct {
					Enabled      bool     `yaml:"enabled"`
					SpecificKeys []string `yaml:"specificKeys"`
				} `yaml:"sensitiveHeadersObfuscationConfig"`
			} `yaml:"sensor"`
		} `yaml:"agent"`
	}
	require.NoError(t, yaml.Unmarshal(values, &chart))
	require.True(t, chart.Agent.Sensor.SensitiveHeadersObfuscationConfig.Enabled,
		"default sensitive header obfuscation should be on")

	return chart.Agent.Sensor.SensitiveHeadersObfuscationConfig.SpecificKeys
}

func TestDefaultSensitiveHeadersObfuscateDatadogAPIKey(t *testing.T) {
	t.Parallel()

	require.Contains(t, defaultSensitiveHeaderKeys(t), "dd-api-key",
		"default sensor header obfuscation must redact Datadog API keys")
}

// Customer traces held live IMDS credentials and Secrets Manager secrets.
func TestDefaultHostHeadersToDropIncludesCloudCredentialEndpoints(t *testing.T) {
	t.Parallel()

	configYAML := renderConfigMapData(t, "", "sensor-configuration", "config.yaml")
	var config struct {
		HostHeadersToDrop []string `yaml:"hostHeadersToDrop"`
	}
	require.NoError(t, yaml.Unmarshal([]byte(configYAML), &config))
	require.Subset(t, config.HostHeadersToDrop, []string{
		"169.254.169.254", "metadata.google.internal", "169.254.170.2", "169.254.170.23",
		"secretsmanager.*.amazonaws.com", "secretsmanager-fips.*.amazonaws.com", "secretsmanager.*.amazonaws.com.cn",
	})
}
