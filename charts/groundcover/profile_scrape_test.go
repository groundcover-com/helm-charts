//go:build helmtest

package groundcover_test

import (
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

type renderedProfilesReceiver struct {
	Enabled *bool          `yaml:"enabled"`
	Scrape  map[string]any `yaml:"scrape"`
}

func renderedProfilesReceiverOf(t *testing.T, values, configMapName string) renderedProfilesReceiver {
	t.Helper()
	var config struct {
		Receivers struct {
			Profiles renderedProfilesReceiver `yaml:"profiles"`
		} `yaml:"receivers"`
	}
	require.NoError(t, yaml.Unmarshal([]byte(renderConfigMapData(t, values, configMapName, "config.yaml")), &config))
	return config.Receivers.Profiles
}

func TestProfileScrapeSettingsRenderForEveryCollectingSensorAndNoOther(t *testing.T) {
	t.Parallel()
	const scrapeValues = `{receivers: {profiles: {scrape: {enabled: true, interval: 2m, maxBodySize: 1024,
    extraAnnotationPrefixes: [com.acme.corp], defaultPort: 6060}}}}`
	enabledEveryTwoMinutes := map[string]any{
		"enabled": true, "interval": "2m", "extraAnnotationPrefixes": []any{"com.acme.corp"}, "defaultPort": 6060,
	}
	enabledByDefault := map[string]any{"enabled": true, "interval": "2m", "extraAnnotationPrefixes": []any{}, "defaultPort": 0}
	tests := []struct {
		name         string
		values       string
		configMap    string
		wantScrape   map[string]any
		wantRawPprof bool
	}{
		{
			name:         "the agent collects and ingests, so it gets scraping and the raw pprof receiver",
			values:       "agent: {sensor: " + scrapeValues + "}",
			configMap:    "sensor-configuration",
			wantScrape:   enabledEveryTwoMinutes,
			wantRawPprof: true,
		},
		{
			name:       "an agent with ingestion off still collects, so it still gets scraping",
			values:     "agent: {sensor: {ingestionEnabled: false, receivers: {profiles: {scrape: {enabled: true, interval: 2m}}}}}",
			configMap:  "sensor-configuration",
			wantScrape: enabledByDefault,
		},
		{
			name:         "the ingestor does not collect, so it never gets scraping",
			values:       "agent: {sensor: " + scrapeValues + "}",
			configMap:    "ingestor-config",
			wantRawPprof: true,
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()

			profiles := renderedProfilesReceiverOf(t, test.values, test.configMap)

			require.Equal(t, test.wantScrape, profiles.Scrape, "only the documented settings are configurable")
			require.Equal(t, test.wantRawPprof, profiles.Enabled != nil, "the raw pprof receiver renders only where ingestion runs")
		})
	}
}
