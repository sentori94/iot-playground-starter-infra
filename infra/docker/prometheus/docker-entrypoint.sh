#!/bin/sh
set -e

echo "🚀 Starting Prometheus with dynamic configuration..."

# Créer le dossier de config s'il n'existe pas
mkdir -p /etc/prometheus

# Générer dynamiquement le fichier prometheus.yml à partir de la variable d'environnement
cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 1s

scrape_configs:
  - job_name: "spring-app"
    metrics_path: "/actuator/prometheus"
    static_configs:
      - targets: ["${SPRING_APP_URL}"]
EOF

echo "✅ Prometheus configuré pour scraper: ${SPRING_APP_URL}"

# Lancer Prometheus avec la commande par défaut
exec /bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus

