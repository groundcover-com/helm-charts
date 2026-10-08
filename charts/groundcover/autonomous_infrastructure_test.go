//go:build helmtest

package groundcover_test

import (
	"bytes"
	"errors"
	"io"
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

type renderedEnvVar struct {
	Name  string `yaml:"name"`
	Value string `yaml:"value"`
}

type renderedDeployment struct {
	Kind     string `yaml:"kind"`
	Metadata struct {
		Name string `yaml:"name"`
	} `yaml:"metadata"`
	Spec struct {
		Template struct {
			Spec struct {
				Containers []struct {
					Name string           `yaml:"name"`
					Env  []renderedEnvVar `yaml:"env"`
				} `yaml:"containers"`
			} `yaml:"spec"`
		} `yaml:"template"`
	} `yaml:"spec"`
}

// k8s-watcher reads its opt-in only from the environment, so the chart flag has to reach it there.
func TestK8sWatcherOptsIntoAutonomousInfrastructureWithItsChartFlag(t *testing.T) {
	t.Parallel()

	for _, tc := range []struct {
		name   string
		values string
		want   string
	}{
		{name: "off by default", values: "", want: "false"},
		{name: "on with the flag", values: "global:\n  autonomousInfrastructure:\n    enabled: true\n", want: "true"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			output, err := renderGroundcoverChart(t, tc.values)
			require.NoError(t, err, string(output))
			require.Equal(t, tc.want, k8sWatcherEnv(t, output)["GC_AUTONOMOUSINFRASTRUCTURE_OPTIN"])
		})
	}
}

func k8sWatcherEnv(t *testing.T, manifests []byte) map[string]string {
	t.Helper()
	decoder := yaml.NewDecoder(bytes.NewReader(manifests))
	for {
		var object renderedDeployment
		err := decoder.Decode(&object)
		if errors.Is(err, io.EOF) {
			break
		}
		require.NoError(t, err)
		if object.Kind != "Deployment" || object.Metadata.Name != "k8s-watcher" {
			continue
		}
		env := map[string]string{}
		for _, container := range object.Spec.Template.Spec.Containers {
			if container.Name == "k8s-watcher" {
				for _, variable := range container.Env {
					env[variable.Name] = variable.Value
				}
			}
		}
		return env
	}
	t.Fatal("the chart rendered no k8s-watcher Deployment")
	return nil
}
