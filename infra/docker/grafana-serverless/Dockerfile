FROM grafana/grafana:10.2.3

USER root

# Installer uniquement bash pour les scripts de provisioning
RUN apk add --no-cache bash

# Copier les fichiers de provisioning
COPY provisioning/ /etc/grafana/provisioning/

# Copier les dashboards
COPY dashboards/ /var/lib/grafana/dashboards/

USER grafana


