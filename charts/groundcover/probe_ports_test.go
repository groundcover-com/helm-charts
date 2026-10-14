//go:build helmtest

package groundcover_test

import (
	"bytes"
	"io"
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

type renderedProbe struct {
	HTTPGet *struct {
		Port any `yaml:"port"`
	} `yaml:"httpGet"`
}

type renderedWorkload struct {
	Kind     string `yaml:"kind"`
	Metadata struct {
		Name string `yaml:"name"`
	} `yaml:"metadata"`
	Spec struct {
		Template struct {
			Spec struct {
				Containers []struct {
					Name  string `yaml:"name"`
					Ports []struct {
						Name string `yaml:"name"`
					} `yaml:"ports"`
					ReadinessProbe *renderedProbe `yaml:"readinessProbe"`
					LivenessProbe  *renderedProbe `yaml:"livenessProbe"`
				} `yaml:"containers"`
			} `yaml:"spec"`
		} `yaml:"template"`
	} `yaml:"spec"`
}

// undeclaredProbePorts lists every workload probe that targets a named port
// its container does not declare, which kubelet cannot resolve, so the pod
// never becomes Ready.
func undeclaredProbePorts(t *testing.T, values string) []string {
	t.Helper()
	output, err := renderGroundcoverChart(t, values)
	require.NoError(t, err, string(output))

	var undeclared []string
	decoder := yaml.NewDecoder(bytes.NewReader(output))
	for {
		var workload renderedWorkload
		err := decoder.Decode(&workload)
		if err == io.EOF {
			break
		}
		require.NoError(t, err)
		if workload.Kind != "DaemonSet" && workload.Kind != "Deployment" && workload.Kind != "StatefulSet" {
			continue
		}
		for _, container := range workload.Spec.Template.Spec.Containers {
			declared := map[string]bool{}
			for _, port := range container.Ports {
				declared[port.Name] = true
			}
			for _, probe := range []*renderedProbe{container.ReadinessProbe, container.LivenessProbe} {
				if probe == nil || probe.HTTPGet == nil {
					continue
				}
				if name, named := probe.HTTPGet.Port.(string); named && !declared[name] {
					undeclared = append(undeclared, workload.Kind+"/"+workload.Metadata.Name+"/"+container.Name+": "+name)
				}
			}
		}
	}
	return undeclared
}

func TestEveryProbeTargetsAPortItsContainerDeclares(t *testing.T) {
	t.Parallel()
	tests := []struct {
		name   string
		values string
	}{
		{name: "with the default values", values: ""},
		{name: "with a collection-only agent, which scrapes profiles without ingesting", values: "agent: {sensor: {ingestionEnabled: false}}"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()

			require.Empty(t, undeclaredProbePorts(t, test.values))
		})
	}
}
