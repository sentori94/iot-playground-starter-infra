FROM grafana/grafana:10.2.3

# Passer en root pour installer les packages
USER root

# Installer AWS CLI v2 pour Alpine Linux
RUN apk add --no-cache \
    python3 \
    py3-pip \
    bash \
    curl \
    && pip3 install --no-cache-dir awscli \
    && rm -rf /var/cache/apk/*

# Installer le plugin Athena
RUN grafana cli plugins install grafana-athena-datasource

# Copier les fichiers de provisioning
COPY provisioning/ /etc/grafana/provisioning/

# Copier les dashboards
COPY dashboards/ /var/lib/grafana/dashboards/

# Copier le script d'initialisation Athena
COPY init-athena.sh /usr/local/bin/init-athena.sh
RUN chmod +x /usr/local/bin/init-athena.sh

# Revenir à l'utilisateur grafana
USER grafana

# Utiliser le script d'init comme entrypoint
ENTRYPOINT ["/usr/local/bin/init-athena.sh"]

