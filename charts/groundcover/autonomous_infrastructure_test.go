//go:build helmtest

package groundcover_test

import (
	"bytes"
	"encoding/json"
	"io"
	"os"
	"regexp"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"

	"groundcover.com/internal/testpath"
)

func TestK8sWatcherOptsIntoAutonomousInfrastructureWithItsChartFlag(t *testing.T) {
	t.Parallel()

	for _, tc := range []struct {
		name   string
		values string
		want   bool
	}{
		{name: "off by default", values: "", want: false},
		{name: "on with the flag", values: "global:\n  autonomousInfrastructure:\n    enabled: true\n", want: true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			var config struct {
				AutonomousInfrastructure struct {
					Enabled *bool `yaml:"enabled"`
				} `yaml:"autonomousInfrastructure"`
			}
			require.NoError(t, yaml.Unmarshal([]byte(renderConfigMapData(t, tc.values, "k8s-watcher-config", "config.yaml")), &config))
			require.NotNil(t, config.AutonomousInfrastructure.Enabled, "the watcher config must carry the flag explicitly")
			require.Equal(t, tc.want, *config.AutonomousInfrastructure.Enabled)
		})
	}
}

// The workers push their own telemetry, so the chart-wide telemetry switch has to silence them too.
func TestAutonomousInfrastructureWorkersFollowTheGlobalTelemetrySwitch(t *testing.T) {
	t.Parallel()

	const enabled = "global:\n  autonomousInfrastructure:\n    enabled: true\n"
	const disabled = enabled + "  telemetry:\n    enabled: false\n"

	for _, configMap := range []string{
		"export-limits-test-autoinfra-algo-config",
		"export-limits-test-autoinfra-recommendations-config",
	} {
		t.Run(configMap, func(t *testing.T) {
			t.Parallel()

			require.Equal(t, "true", renderConfigMapData(t, disabled, configMap, "OTEL_SDK_DISABLED"))
			require.Contains(t, renderConfigMapData(t, enabled, configMap, "OTEL_EXPORTER_OTLP_ENDPOINT"), ":4318")
		})
	}
}

// The CronJob overrides the image's command, so a renamed module or image in
// services/autoinfra leaves the chart pulling an image that does not exist or
// running a module that is no longer in it.
func TestAutonomousInfrastructureCronJobsRunWhatTheirImagesBuild(t *testing.T) {
	t.Parallel()

	output, err := renderGroundcoverChart(t, "global:\n  autonomousInfrastructure:\n    enabled: true\n")
	require.NoError(t, err, string(output))

	for _, tc := range []struct {
		cronJob    string
		serviceDir string
	}{
		{cronJob: "export-limits-test-autoinfra-algo", serviceDir: "algo"},
		{cronJob: "export-limits-test-autoinfra-recommendations", serviceDir: "recommendations"},
	} {
		t.Run(tc.serviceDir, func(t *testing.T) {
			t.Parallel()

			container := renderedCronJobContainer(t, output, tc.cronJob)
			require.Equal(t, dockerfileCmd(t, tc.serviceDir), container.Command)
			require.Contains(t, container.Image, "/"+taskfileService(t, tc.serviceDir)+":")
		})
	}
}

type renderedContainer struct {
	Image   string   `yaml:"image"`
	Command []string `yaml:"command"`
}

func renderedCronJobContainer(t *testing.T, output []byte, name string) renderedContainer {
	t.Helper()

	decoder := yaml.NewDecoder(bytes.NewReader(output))
	for {
		var manifest struct {
			Kind     string `yaml:"kind"`
			Metadata struct {
				Name string `yaml:"name"`
			} `yaml:"metadata"`
			Spec struct {
				JobTemplate struct {
					Spec struct {
						Template struct {
							Spec struct {
								Containers []renderedContainer `yaml:"containers"`
							} `yaml:"spec"`
						} `yaml:"template"`
					} `yaml:"spec"`
				} `yaml:"jobTemplate"`
			} `yaml:"spec"`
		}
		err := decoder.Decode(&manifest)
		if err == io.EOF {
			break
		}
		require.NoError(t, err)
		if manifest.Kind == "CronJob" && manifest.Metadata.Name == name {
			containers := manifest.Spec.JobTemplate.Spec.Template.Spec.Containers
			require.Len(t, containers, 1, "CronJob %s", name)
			return containers[0]
		}
	}
	require.Failf(t, "CronJob not rendered", "%s", name)
	return renderedContainer{}
}

var dockerfileCmdLine = regexp.MustCompile(`(?m)^CMD (\[.*\])\s*$`)

func dockerfileCmd(t *testing.T, serviceDir string) []string {
	t.Helper()

	dockerfile, err := os.ReadFile(testpath.Join(t, "services", "autoinfra", serviceDir, "Dockerfile"))
	require.NoError(t, err)
	match := dockerfileCmdLine.FindAllSubmatch(dockerfile, -1)
	require.NotEmpty(t, match, "no exec-form CMD in %s/Dockerfile", serviceDir)

	var cmd []string
	require.NoError(t, json.Unmarshal(match[len(match)-1][1], &cmd))
	return cmd
}

var taskfileServiceLine = regexp.MustCompile(`(?m)^\s+SERVICE:\s*(\S+)\s*$`)

// The published image is named after the Taskfile's SERVICE (`task <service>:image`).
func taskfileService(t *testing.T, serviceDir string) string {
	t.Helper()

	taskfile, err := os.ReadFile(testpath.Join(t, "services", "autoinfra", serviceDir, "Taskfile.yml"))
	require.NoError(t, err)
	match := taskfileServiceLine.FindSubmatch(taskfile)
	require.NotNil(t, match, "no SERVICE var in %s/Taskfile.yml", serviceDir)
	return strings.Trim(string(match[1]), `'"`)
}
