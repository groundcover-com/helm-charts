//go:build helmtest

package groundcover_test

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

func renderGroundcoverChart(t *testing.T, values string) ([]byte, error) {
	t.Helper()

	_, filename, _, ok := runtime.Caller(0)
	require.True(t, ok)
	chartDir := filepath.Dir(filename)
	valuesPath := filepath.Join(t.TempDir(), "values.yaml")
	require.NoError(t, os.WriteFile(valuesPath, []byte(values), 0o600))

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, "helm", "template", "export-limits-test", chartDir,
		"--set", "clusterId=export-limits-test",
		"--values", valuesPath,
	)
	output, err := cmd.CombinedOutput()
	if ctx.Err() != nil {
		return output, fmt.Errorf("render groundcover chart: %w", ctx.Err())
	}
	if err != nil {
		return output, fmt.Errorf("render groundcover chart: %w", err)
	}
	return output, nil
}

func TestExportByteBudgetsPreserveExactInt64Values(t *testing.T) {
	t.Parallel()

	const exactBudget = "9007199254740993"
	values := fmt.Sprintf(`agent:
  sensor:
    apmIngestor:
      otel:
        direct:
          maxConcurrentTraceExportBytes: %q
          maxConcurrentLogExportBytes: %q
          maxConcurrentMetricExportBytes: %q
`, exactBudget, exactBudget, exactBudget)

	output, err := renderGroundcoverChart(t, values)
	require.NoError(t, err, string(output))
	for _, field := range []string{
		"maxConcurrentTraceExportBytes",
		"maxConcurrentLogExportBytes",
		"maxConcurrentMetricExportBytes",
	} {
		require.Contains(t, string(output), fmt.Sprintf("%s: %q", field, exactBudget))
	}
}

func TestExportByteBudgetsRejectUnsafeNumericValues(t *testing.T) {
	t.Parallel()

	output, err := renderGroundcoverChart(t, `agent:
  sensor:
    apmIngestor:
      otel:
        direct:
          maxConcurrentTraceExportBytes: 9007199254740993
`)

	require.Error(t, err)
	require.Contains(t, string(output), "maxConcurrentTraceExportBytes must be a non-negative integer")
}

func TestExportByteBudgetsAcceptMaxInt64(t *testing.T) {
	t.Parallel()

	output, err := renderGroundcoverChart(t, `agent:
  sensor:
    apmIngestor:
      otel:
        direct:
          maxConcurrentTraceExportBytes: "9223372036854775807"
`)

	require.NoError(t, err, string(output))
	require.Contains(t, string(output), `maxConcurrentTraceExportBytes: "9223372036854775807"`)
}

func TestExportByteBudgetsRejectValuesAboveMaxInt64(t *testing.T) {
	t.Parallel()

	output, err := renderGroundcoverChart(t, `agent:
  sensor:
    apmIngestor:
      otel:
        direct:
          maxConcurrentTraceExportBytes: "9223372036854775808"
`)

	require.Error(t, err)
	require.Contains(t, string(output), "maxConcurrentTraceExportBytes must not exceed 9223372036854775807")
}

func TestExportPercentagesRejectFractionalValues(t *testing.T) {
	t.Parallel()

	output, err := renderGroundcoverChart(t, `agent:
  sensor:
    apmIngestor:
      otel:
        direct:
          maxConcurrentTraceExportPodMemoryPercentage: 10.5
`)

	require.Error(t, err)
	require.Contains(t, string(output), "maxConcurrentTraceExportPodMemoryPercentage must be a non-negative integer")
}
