//go:build helmtest

package groundcover_test

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

func TestStatsDHistogramSettingsReachSensorsAndIngestors(t *testing.T) {
	for _, target := range []struct {
		name, configMap, prefix string
	}{
		{"sensor", "sensor-configuration", "agent:\n  sensor:\n    apmIngestor:\n      otel:\n        direct:\n          statsd:"},
		{"ingestor", "ingestor-config", "ingestor:\n  apmIngestor:\n    otel:\n      direct:\n        statsd:"},
	} {
		t.Run(target.name, func(t *testing.T) {
			for _, enabled := range []bool{false, true} {
				t.Run(fmt.Sprintf("histograms=%t", enabled), func(t *testing.T) {
					values := ""
					expectedInterval := "60s"
					expectedBuckets := []float64{}
					if enabled {
						expectedInterval = "10s"
						expectedBuckets = []float64{100000000, 200000000, 500000000}
						values = target.prefix + "\n            aggregationInterval: 10s\n            histogramBuckets: [100000000, 200000000, 500000000]\n"
					}
					var config struct {
						APMIngestor struct {
							Otel struct {
								Direct struct {
									StatsD struct {
										Interval string    `yaml:"aggregationInterval"`
										Buckets  []float64 `yaml:"histogramBuckets"`
									} `yaml:"statsd"`
								} `yaml:"direct"`
							} `yaml:"otel"`
						} `yaml:"apmIngestor"`
					}
					data := renderConfigMapData(t, values, target.configMap, "config.yaml")
					require.NoError(t, yaml.Unmarshal([]byte(data), &config))
					require.Equal(t, expectedInterval, config.APMIngestor.Otel.Direct.StatsD.Interval)
					require.Equal(t, expectedBuckets, config.APMIngestor.Otel.Direct.StatsD.Buckets)
				})
			}
		})
	}
}
