apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://${prometheus_alb_dns}
    isDefault: true
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "spring-app"
    metrics_path: "/actuator/prometheus"
    static_configs:
      - targets: ["${spring_alb_dns}"]

