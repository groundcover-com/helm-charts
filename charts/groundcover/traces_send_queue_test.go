//go:build helmtest

package groundcover_test

import (
	"regexp"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

// The trace send queue and retry settings are rendered key by key, so a value that is
// not passed through would silently fall back to the binary's defaults.
func TestTracesSendQueueSettingsReachEveryOtlpReceiver(t *testing.T) {
	t.Parallel()

	output, err := renderGroundcoverChart(t, "")
	require.NoError(t, err, string(output))
	rendered := string(output)
	// The ingestor, the metrics aggregator and the sensor each run an OTLP receiver.
	require.Equal(t, 3, strings.Count(rendered, "batchSendQueueWorkerCount: 0"), "worker count left to the binary, which derives it from the cores available")
	require.Equal(t, 3, strings.Count(rendered, "batchSendQueueMaxSize: 0"), "batch backstop likewise derived")
	require.Equal(t, 3, strings.Count(rendered, `batchSendQueueMaxBytes: "0"`), "default byte budget, derived from the pod memory limit")
	// The logs client renders a backoffConfig of its own, so anchor on the traces block.
	tracesRetries := regexp.MustCompile(`batchSendQueueMaxSize: 0\n\s+batchSendQueueMaxBytes: "0"\n\s+backoffConfig: ?\n\s+maxRetries: 10`)
	require.Len(t, tracesRetries.FindAllString(rendered, -1), 3, "default retry schedule")
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
