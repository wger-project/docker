# Monitoring with grafana

This setup allows you to monitor the application with prometheus and grafana.

* Set the `EXPOSE_PROMETHEUS_METRICS` to true in your env file
* Set `PROMETHEUS_URL_PATH` to something unique like a UUID, but it can be anything.
  The metrics will then be available under `/prometheus/<the-url-path>/metrics`.
* Copy `prometheus.example.yml` to `prometheus.yml` and change the value of
  `metrics_path` to use the url path configured above.
* If you want to protect the prometheus service with a password, copy `web.example.yml`
  to `web.yml`, generate a password hash with `python3 gen-pass.py` and enter it there.
  If you don't need this, comment the line where the file is mapped into the container
  in the compose file.
* Configure grafana to use prometheus as a data source
  