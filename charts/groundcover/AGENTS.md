# groundcover chart

- The metrics-aggregator ConfigMap renders its own copy of the sensor config, `metrics-aggregator.config` in `templates/metrics-aggregator/_config.tpl`, so sensor-only changes to `groundcover.sensor.config` in `templates/_sensor.tpl` do not roll the aggregator. When a config change applies to both, make it in both files in the same PR; otherwise edit only the one that needs it.
