//go:build helmtest

package groundcover_test

import (
	"bytes"
	"io"
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

type renderedConfigMap struct {
	Kind     string `yaml:"kind"`
	Metadata struct {
		Name string `yaml:"name"`
	} `yaml:"metadata"`
	Data map[string]string `yaml:"data"`
}

func renderConfigMapData(t *testing.T, values, name, key string) string {
	t.Helper()

	output, err := renderGroundcoverChart(t, values)
	require.NoError(t, err, string(output))

	decoder := yaml.NewDecoder(bytes.NewReader(output))
	for {
		var manifest renderedConfigMap
		err := decoder.Decode(&manifest)
		if err == io.EOF {
			break
		}
		require.NoError(t, err)
		if manifest.Kind == "ConfigMap" && manifest.Metadata.Name == name {
			value, ok := manifest.Data[key]
			require.True(t, ok, "ConfigMap %s is missing %s", name, key)
			return value
		}
	}

	require.FailNow(t, "rendered ConfigMap is missing", name)
	return ""
}

func TestProfilingVectorPipelineRendersEveryStorageMode(t *testing.T) {
	testCases := []struct {
		name       string
		values     string
		sinkName   string
		sinkType   string
		attributes map[string]any
	}{
		{
			name:     "local ClickHouse",
			sinkName: "clickhouse_profiling",
			sinkType: "clickhouse",
			attributes: map[string]any{
				"table": "profiling",
			},
		},
		{
			name: "AWS S3",
			values: `vector:
  objectStorage:
    s3Bucket: profiling-bucket
    region: eu-west-1
`,
			sinkName: "s3_profiling",
			sinkType: "aws_s3",
			attributes: map[string]any{
				"bucket":     "profiling-bucket",
				"region":     "eu-west-1",
				"key_prefix": "v4/profiling/",
			},
		},
		{
			name: "GCS",
			values: `vector:
  objectStorage:
    gcsBucket: profiling-bucket
`,
			sinkName: "gcs_profiling",
			sinkType: "gcp_cloud_storage",
			attributes: map[string]any{
				"bucket":     "profiling-bucket",
				"key_prefix": "v4/profiling/",
			},
		},
		{
			name: "Azure",
			values: `vector:
  objectStorage:
    azureBlobContainer: profiling-container
    azureConnectionString: profiling-connection
`,
			sinkName: "azure_profiling",
			sinkType: "azure_blob",
			attributes: map[string]any{
				"container_name":    "profiling-container",
				"connection_string": "profiling-connection",
				"blob_prefix":       "v4/profiling/",
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			vectorYAML := renderConfigMapData(t, tc.values, "vector-config-map", "vector.yaml")
			var config struct {
				Transforms map[string]map[string]any `yaml:"transforms"`
				Sinks      map[string]map[string]any `yaml:"sinks"`
			}
			require.NoError(t, yaml.Unmarshal([]byte(vectorYAML), &config))

			_, hasProfilingTransform := config.Transforms["profiling"]
			require.False(t, hasProfilingTransform, "profiling records must not require a Vector remap")

			sink, ok := config.Sinks[tc.sinkName]
			require.True(t, ok, "missing profiling sink %s", tc.sinkName)
			require.Equal(t, tc.sinkType, sink["type"])
			require.Equal(t, []any{"custom_from_logs_routing.profiling"}, sink["inputs"])
			for key, expected := range tc.attributes {
				require.Equal(t, expected, sink[key], key)
			}
			encoding, ok := sink["encoding"].(map[string]any)
			require.True(t, ok, "profiling sink encoding is missing")
			require.Equal(t, "rfc3339", encoding["timestamp_format"])
			require.Equal(t, []any{"log_type"}, encoding["except_fields"])
			if tc.sinkType != "clickhouse" {
				require.Equal(t, "json", encoding["codec"])
			}
		})
	}
}
