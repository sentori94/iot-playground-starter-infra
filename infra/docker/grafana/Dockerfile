FROM grafana/grafana:latest

# Copier les dashboards et la configuration de provisioning (sauf datasources)
COPY dashboards/ /var/lib/grafana/dashboards/
COPY provisioning/dashboards/ /etc/grafana/provisioning/dashboards/

# Copier le script d'entrypoint qui générera le datasource dynamiquement
COPY --chmod=755 docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/docker-entrypoint.sh"]
