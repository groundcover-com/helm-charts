//go:build helmtest

package groundcover_test

import (
	"regexp"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

type traceQueueSettings struct {
	Workers int    `yaml:"batchSendQueueWorkerCount"`
	Batches int    `yaml:"batchSendQueueMaxSize"`
	Bytes   string `yaml:"batchSendQueueMaxBytes"`
}

func TestTraceSendQueueLimitsDefaultToUnlimitedOnlyOnSensors(t *testing.T) {
	for _, tc := range []struct {
		name      string
		configMap string
		values    string
		expected  traceQueueSettings
	}{
		{name: "sensor limits are unlimited", configMap: "sensor-configuration", expected: traceQueueSettings{-1, -1, "-1"}},
		{name: "ingestor keeps automatic limits", configMap: "ingestor-config", expected: traceQueueSettings{0, 0, "0"}},
		{name: "metrics aggregator keeps automatic limits", configMap: "export-limits-test-metrics-aggregator-config", expected: traceQueueSettings{0, 0, "0"}},
		{name: "sensor can opt into automatic limits", configMap: "sensor-configuration", values: "agent:\n  sensor:\n    apmIngestor:\n      tracesOtlpEndpoint:\n        batchSendQueueWorkerCount: 0\n        batchSendQueueMaxSize: 0\n        batchSendQueueMaxBytes: 0\n", expected: traceQueueSettings{0, 0, "0"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			configYAML := renderConfigMapData(t, tc.values, tc.configMap, "config.yaml")
			var config struct {
				APMIngestor struct {
					TracesOTLPEndpoint traceQueueSettings `yaml:"tracesOtlpEndpoint"`
				} `yaml:"apmIngestor"`
			}
			require.NoError(t, yaml.Unmarshal([]byte(configYAML), &config))
			require.Equal(t, tc.expected, config.APMIngestor.TracesOTLPEndpoint)
		})
	}
}

// The trace send queue and retry settings are rendered key by key, so a value that is
// not passed through would silently fall back to the binary's defaults.
func TestTracesSendQueueSettingsReachEveryOtlpReceiver(t *testing.T) {
	t.Parallel()

	output, err := renderGroundcoverChart(t, "")
	require.NoError(t, err, string(output))
	rendered := string(output)
	// The ingestor, the metrics aggregator and the sensor each run an OTLP receiver.
	require.Equal(t, 2, strings.Count(rendered, "batchSendQueueWorkerCount: 0"), "non-sensor worker counts remain automatic")
	require.Equal(t, 2, strings.Count(rendered, "batchSendQueueMaxSize: 0"), "non-sensor batch limits remain automatic")
	require.Equal(t, 2, strings.Count(rendered, `batchSendQueueMaxBytes: "0"`), "non-sensor byte budgets remain automatic")
	// The logs client renders a backoffConfig of its own, so anchor on the traces block.
	tracesRetries := regexp.MustCompile(`batchSendQueueMaxSize: (?:-1|0)\n\s+batchSendQueueMaxBytes: "(?:-1|0)"\n\s+backoffConfig: ?\n\s+maxRetries: 10`)
	require.Len(t, tracesRetries.FindAllString(rendered, -1), 3, "default retry schedule")
}

func TestTraceSendQueueByteBudgetAcceptsMinusOneAsUnlimited(t *testing.T) {
	for _, value := range []string{"-1", `"-1"`} {
		t.Run(value, func(t *testing.T) {
			output, err := renderGroundcoverChart(t, "agent:\n  sensor:\n    apmIngestor:\n      tracesOtlpEndpoint:\n        batchSendQueueMaxBytes: "+value+"\n")
			require.NoError(t, err, string(output))
			require.Contains(t, string(output), `batchSendQueueMaxBytes: "-1"`)
		})
	}
}

func TestTracesSendQueueOverridesReachTheIngestorConfig(t *testing.T) {
	t.Parallel()

	output, err := renderGroundcoverChart(t, `ingestor:
  apmIngestor:
    tracesOtlpEndpoint:
      batchSendQueueWorkerCount: 3
      batchSendQueueMaxSize: 7
      batchSendQueueMaxBytes: 12345678
      backoffConfig:
        maxRetries: 2
        maxBackoff: 5s
`)
	require.NoError(t, err, string(output))
	rendered := string(output)
	require.Contains(t, rendered, "batchSendQueueWorkerCount: 3")
	require.Contains(t, rendered, "batchSendQueueMaxSize: 7")
	require.Contains(t, rendered, `batchSendQueueMaxBytes: "12345678"`)
	require.Contains(t, rendered, "maxRetries: 2")
	require.Contains(t, rendered, "maxBackoff: 5s")
}

// A numeric 0 is an empty value to Helm's default, so it must not fall back to a wait.
func TestExportAcquireWaitZeroRendersAsImmediateRefusal(t *testing.T) {
	t.Parallel()

	for name, values := range map[string]string{
		"unset":     "",
		"numeric 0": "ingestor:\n  apmIngestor:\n    otel:\n      direct:\n        exportAcquireWait: 0\n",
		"string 0s": "ingestor:\n  apmIngestor:\n    otel:\n      direct:\n        exportAcquireWait: 0s\n",
	} {
		t.Run(name, func(t *testing.T) {
			output, err := renderGroundcoverChart(t, values)
			require.NoError(t, err, string(output))
			require.Contains(t, string(output), "exportAcquireWait: 0s")
			require.NotContains(t, string(output), "exportAcquireWait: 1s")
		})
	}
}

// A partial override of the retry schedule must keep the keys it does not mention.
// This is load-bearing rather than cosmetic: ExportWithBackoff treats MaxRetries <= 0
// as a single attempt, so an override that dropped maxRetries would silently disable
// trace retries. What protects it is the chart default that Helm merges the override
// onto, which is why backoffConfig belongs in values.yaml and not only in the template.
func TestTracesBackoffPartialOverrideKeepsTheRestOfTheSchedule(t *testing.T) {
	t.Parallel()

	output, err := renderGroundcoverChart(t, `ingestor:
  apmIngestor:
    tracesOtlpEndpoint:
      backoffConfig:
        maxBackoff: 5s
`)
	require.NoError(t, err, string(output))
	rendered := string(output)
	// Anchored on the traces block: the logs client renders a backoffConfig of its own,
	// so an unanchored assertion would pass on that one instead.
	tracesSchedule := regexp.MustCompile(`batchSendQueueMaxBytes: "0"\n\s+backoffConfig: ?\n\s+maxBackoff: 5s\n\s+maxRetries: 10`)
	require.NotEmpty(t, tracesSchedule.FindAllString(rendered, -1),
		"the override applies and the attempt count it did not mention survives, since Helm merges it onto the chart default")
}

// The logs retry schedule must be configurable in the same shape as the traces one.
// Only maxBackoff was reachable before, so nobody could shorten the attempt count —
// and a failing batch holds a worker, a queue slot and its bytes for the whole
// sequence, which with ten attempts is about two minutes.
func TestLogsBackoffScheduleIsConfigurable(t *testing.T) {
	t.Parallel()

	shipped, err := renderGroundcoverChart(t, "")
	require.NoError(t, err, string(shipped))
	// Anchored on the logs client block, which is the only one carrying batchwait.
	unchanged := regexp.MustCompile(`batchwait: 5000ms\n\s+batchsize: \S+\n\s+backoffConfig: ?\n\s+minBackoff: 500ms\n\s+maxBackoff: 30s\n\s+maxRetries: 10`)
	require.NotEmpty(t, unchanged.FindAllString(string(shipped), -1), "the shipped logs schedule is unchanged")

	overridden, err := renderGroundcoverChart(t, "logBatchMinBackoff: 250ms\nlogBatchMaxRetries: 4\n")
	require.NoError(t, err, string(overridden))
	applied := regexp.MustCompile(`backoffConfig: ?\n\s+minBackoff: 250ms\n\s+maxBackoff: 30s\n\s+maxRetries: 4`)
	require.NotEmpty(t, applied.FindAllString(string(overridden), -1),
		"every part of the logs schedule is reachable, and overriding two keeps the third")
}
