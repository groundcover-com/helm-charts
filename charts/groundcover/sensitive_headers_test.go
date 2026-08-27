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
