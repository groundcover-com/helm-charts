//go:build helmtest

package groundcover_test

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"groundcover.com/internal/testpath"
)

func TestChartInventoryReportsHelmErrorsWithoutRequiredValuePaths(t *testing.T) {
	t.Parallel()

	// The bucket-streamer validation error lacks the ".Values.<path> is required"
	// pattern. Inventory must report such errors instead of exiting silently.
	message := "inventory fixture: no object store configured"
	chart := t.TempDir()
	require.NoError(t, os.Mkdir(filepath.Join(chart, "templates"), 0o700))
	require.NoError(t, os.WriteFile(filepath.Join(chart, "Chart.yaml"),
		[]byte("apiVersion: v2\nname: inventory-error\nversion: 0.1.0\n"), 0o600))
	require.NoError(t, os.WriteFile(filepath.Join(chart, "templates", "validation.yaml"),
		fmt.Appendf(nil, "{{ fail %q }}\n", message), 0o600))

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, "bash", testpath.Join(t, "scripts", "helm", "chart-inventory.sh"),
		"--chart", chart, "--out", t.TempDir())
	output, err := cmd.CombinedOutput()

	require.NoError(t, ctx.Err())
	require.Error(t, err, "invalid charts must still fail inventory generation")
	require.Contains(t, string(output), message, "the original Helm diagnostic must reach the caller")
}
