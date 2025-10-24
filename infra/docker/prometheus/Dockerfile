# On part de l’image officielle Prometheus
FROM prom/prometheus:v2.52.0

# Copier le script d'entrypoint qui générera la config dynamiquement
COPY --chmod=755 docker-entrypoint.sh /docker-entrypoint.sh

# Dossier de config Prometheus
VOLUME ["/etc/prometheus"]

# Prometheus expose son UI sur le port 9090
EXPOSE 9090

ENTRYPOINT ["/docker-entrypoint.sh"]
