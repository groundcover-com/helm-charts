//go:build helmtest

package groundcover_test

import (
	"bytes"
	"fmt"
	"io"
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

type renderedIngress struct {
	Kind string `yaml:"kind"`
	Spec struct {
		Rules []struct {
			HTTP struct {
				Paths []struct {
					Path     string `yaml:"path"`
					PathType string `yaml:"pathType"`
					Backend  struct {
						Service struct {
							Name string `yaml:"name"`
							Port struct {
								Name   string `yaml:"name"`
								Number int    `yaml:"number"`
							} `yaml:"port"`
						} `yaml:"service"`
					} `yaml:"backend"`
				} `yaml:"paths"`
			} `yaml:"http"`
		} `yaml:"rules"`
	} `yaml:"spec"`
}

func renderedIngressPaths(t *testing.T, values string) map[string]renderedIngressPath {
	t.Helper()
	output, err := renderGroundcoverChart(t, values)
	require.NoError(t, err, string(output))

	paths := make(map[string]renderedIngressPath)
	decoder := yaml.NewDecoder(bytes.NewReader(output))
	for {
		var manifest renderedIngress
		err := decoder.Decode(&manifest)
		if err == io.EOF {
			break
		}
		require.NoError(t, err)
		if manifest.Kind != "Ingress" {
			continue
		}
		for _, rule := range manifest.Spec.Rules {
			for _, path := range rule.HTTP.Paths {
				paths[path.Path] = renderedIngressPath{
					pathType:    path.PathType,
					serviceName: path.Backend.Service.Name,
					portName:    path.Backend.Service.Port.Name,
					portNumber:  path.Backend.Service.Port.Number,
				}
			}
		}
	}
	return paths
}

type renderedIngressPath struct {
	pathType    string
	serviceName string
	portName    string
	portNumber  int
}

func TestOTLPProfileIngressRendersExactHTTPAndGRPCRoutes(t *testing.T) {
	paths := renderedIngressPaths(t, profileIngressValues(true, true))

	require.Equal(t, renderedIngressPath{
		pathType:    "Exact",
		serviceName: "export-limits-test-ingestor",
		portName:    "otlp-http",
	}, paths["/v1development/profiles"])
	require.Equal(t, renderedIngressPath{
		pathType:    "Exact",
		serviceName: "export-limits-test-ingestor-grpc",
		portName:    "otlp-grpc",
	}, paths["/opentelemetry.proto.collector.profiles.v1development.ProfilesService/Export"])
	require.Equal(t, renderedIngressPath{
		pathType:    "Exact",
		serviceName: "export-limits-test-ingestor",
		portName:    "profiles",
	}, paths["/profiling/upload"])
}

func TestOTLPProfileIngressRequiresItsApplicationReceivers(t *testing.T) {
	testCases := []struct {
		name                   string
		profileReceiverEnabled bool
		otlpReceiverEnabled    bool
		message                string
	}{
		{
			name:                   "raw profile receiver",
			profileReceiverEnabled: false,
			otlpReceiverEnabled:    true,
			message:                "incloud-ingress.profileIngestion.enabled requires ingestor.receivers.profiles.enabled=true",
		},
		{
			name:                   "OTLP receiver",
			profileReceiverEnabled: true,
			otlpReceiverEnabled:    false,
			message:                "incloud-ingress.profileIngestion.otlp.enabled requires ingestor.apmIngestor.otel.direct.otlp.enabled=true",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			output, err := renderGroundcoverChart(t, profileIngressValues(tc.profileReceiverEnabled, tc.otlpReceiverEnabled))
			require.Error(t, err)
			require.Contains(t, string(output), tc.message)
		})
	}
}

func TestProfileIngressRejectsNonBooleanEnableFlags(t *testing.T) {
	testCases := []struct {
		name                  string
		profileIngressEnabled string
		otlpIngressEnabled    string
		message               string
	}{
		{
			name:                  "profile ingress",
			profileIngressEnabled: `"false"`,
			otlpIngressEnabled:    "true",
			message:               "incloud-ingress.profileIngestion.enabled must be a boolean",
		},
		{
			name:                  "OTLP profile ingress",
			profileIngressEnabled: "true",
			otlpIngressEnabled:    `"false"`,
			message:               "incloud-ingress.profileIngestion.otlp.enabled must be a boolean",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			values := profileIngressValuesWithFlags(true, true, tc.profileIngressEnabled, tc.otlpIngressEnabled)
			output, err := renderGroundcoverChart(t, values)
			require.Error(t, err)
			require.Contains(t, string(output), tc.message)
		})
	}
}

func profileIngressValues(profileReceiverEnabled, otlpReceiverEnabled bool) string {
	return profileIngressValuesWithFlags(profileReceiverEnabled, otlpReceiverEnabled, "true", "true")
}

func profileIngressValuesWithFlags(
	profileReceiverEnabled bool,
	otlpReceiverEnabled bool,
	profileIngressEnabled string,
	otlpIngressEnabled string,
) string {
	return fmt.Sprintf(`global:
  ingress:
    site: profiles.test
incloud-ingress:
  enabled: true
  profileIngestion:
    enabled: %s
    otlp:
      enabled: %s
ingestor:
  receivers:
    profiles:
      enabled: %t
      port: 8028
  apmIngestor:
    otel:
      direct:
        otlp:
          enabled: %t
          httpPort: 4318
          grpcPort: 4317
`, profileIngressEnabled, otlpIngressEnabled, profileReceiverEnabled, otlpReceiverEnabled)
}
