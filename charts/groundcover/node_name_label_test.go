//go:build helmtest

package groundcover_test

import (
	"testing"

	"github.com/stretchr/testify/require"
)

// A second `nodes:` mapping anywhere under global.labelEnrichment silently replaces the first,
// so the setting can disappear from the rendered sensor config while values.yaml still shows it.
func TestSensorConfigCarriesTheNodeNameLabelSetting(t *testing.T) {
	t.Parallel()

	output, err := renderGroundcoverChart(t, `global:
  labelEnrichment:
    nodes:
      nameLabel:
        enabled: true
`)
	require.NoError(t, err, string(output))
	require.Contains(t, string(output), "nameLabel:", string(output))

	defaults, err := renderGroundcoverChart(t, "")
	require.NoError(t, err, string(defaults))
	require.Contains(t, string(defaults), "nameLabel:", string(defaults))
}
