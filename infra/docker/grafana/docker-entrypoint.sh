#!/bin/bash
set -e

echo "🚀 Starting Grafana with dynamic configuration..."

# Créer le dossier des datasources s'il n'existe pas
mkdir -p /etc/grafana/provisioning/datasources

# Générer dynamiquement le fichier datasource à partir de la variable d'environnement
cat > /etc/grafana/provisioning/datasources/prometheus.yml <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://${PROMETHEUS_URL}
    isDefault: true
EOF

echo "✅ Datasource Prometheus configuré avec l'URL: http://${PROMETHEUS_URL}"

# Lancer Grafana avec la commande par défaut
exec /run.sh

