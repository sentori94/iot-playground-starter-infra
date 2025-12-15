FROM grafana/grafana:10.2.3

# Installer le plugin Athena
RUN grafana cli plugins install grafana-athena-datasource

# Copier les fichiers de provisioning
COPY provisioning/ /etc/grafana/provisioning/

# Copier les dashboards
COPY dashboards/ /var/lib/grafana/dashboards/

USER grafana

