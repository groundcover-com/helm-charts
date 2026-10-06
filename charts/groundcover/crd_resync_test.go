//go:build helmtest

package groundcover_test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/spf13/viper"
	"github.com/stretchr/testify/require"
	"groundcover.com/internal/shared/k8s_controller/config"
)

func TestCRDResyncPeriodRendersForEachComponent(t *testing.T) {
	for _, component := range []struct {
		name      string
		configMap string
		watchKey  string
		values    func(string) string
	}{
		{
			name: "sensor", configMap: "sensor-configuration", watchKey: "k8sEntitiesWatch",
			values: func(period string) string {
				return fmt.Sprintf("agent:\n  sensor:\n    k8sEntitiesWatch:\n      crd:\n        resyncPeriod: %s\n", period)
			},
		},
		{
			name: "Kubernetes entity watcher", configMap: "k8s-watcher-config", watchKey: "watch",
			values: func(period string) string {
				return fmt.Sprintf("k8sWatcher:\n  watch:\n    crd:\n      resyncPeriod: %s\n", period)
			},
		},
	} {
		t.Run(component.name, func(t *testing.T) {
			for _, tc := range []struct {
				name   string
				values string
				period string
			}{
				{name: "defaults to 60 minutes", period: "60m"},
				{name: "renders a custom duration", values: component.values("5m"), period: "5m"},
			} {
				t.Run(tc.name, func(t *testing.T) {
					rendered := renderConfigMapData(t, tc.values, component.configMap, "config.yaml")
					v := viper.New()
					v.SetConfigType("yaml")
					require.NoError(t, v.ReadConfig(strings.NewReader(rendered)))
					require.Equal(t, tc.period, v.GetString(component.watchKey+".crd.resyncPeriod"))
					var watchers config.WatchersConfig
					require.NoError(t, v.UnmarshalKey(component.watchKey, &watchers))
					period, err := time.ParseDuration(tc.period)
					require.NoError(t, err)
					require.Equal(t, period, watchers.GetCRDResyncPeriod())
				})
			}
		})
	}
}
