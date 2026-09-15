//go:build helmtest

package groundcover_test

import (
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

func TestDefaultConnectorCatalogIncludesMonday(t *testing.T) {
	t.Parallel()

	configYAML := renderConfigMapData(t, `global:
  commHub:
    enabled: true
`, "export-limits-test-comm-hub-config", "config.yaml")

	type catalogEntry struct {
		ID           string `yaml:"id"`
		DisplayName  string `yaml:"displayName"`
		Description  string `yaml:"description"`
		MCPServerURL string `yaml:"mcpServerURL"`
		AuthMode     string `yaml:"authMode"`
		IconDomain   string `yaml:"iconDomain"`
		SetupHelp    string `yaml:"setupHelp"`
	}
	var config struct {
		ConnectorCatalog struct {
			Entries []catalogEntry `yaml:"entries"`
		} `yaml:"connectorCatalog"`
	}
	require.NoError(t, yaml.Unmarshal([]byte(configYAML), &config))

	for _, entry := range config.ConnectorCatalog.Entries {
		if entry.ID != "monday" {
			continue
		}
		require.Equal(t, catalogEntry{
			ID:           "monday",
			DisplayName:  "monday.com",
			Description:  "Connect monday.com to access boards, items, workspaces, and updates.",
			MCPServerURL: "https://mcp.monday.com/mcp",
			AuthMode:     "oauth",
			IconDomain:   "monday.com",
			SetupHelp:    "A monday.com admin must allow MCP access under Administration → Permissions → AI Connectors before users can connect.",
		}, entry)
		return
	}

	t.Fatal("default connector catalog does not include monday")
}
