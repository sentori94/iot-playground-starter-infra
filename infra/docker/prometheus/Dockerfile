# On part de l’image officielle Prometheus
FROM prom/prometheus:v2.52.0
ADD prometheus.yml /etc/prometheus/

# Dossier de config Prometheus
VOLUME ["/etc/prometheus"]

# Prometheus expose son UI sur le port 9090
EXPOSE 9090