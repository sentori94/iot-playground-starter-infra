# Modules Monitoring & Observabilité

Cette partie regroupe les briques liées à la visibilité sur le système : métriques, logs, dashboards.

## 📈 Grafana ECS (module `grafana_ecs`)

- Déploie un conteneur Grafana sur ECS Fargate
- S’appuie sur :
  - un ALB (HTTPS)
  - un VPC (subnets publics/privés)
- Datasources :
  - Prometheus (mode ECS)
  - CloudWatch (mode Serverless)

## 📊 Prometheus (via ECS)

- Déployé dans l’architecture ECS
- Scrape les métriques Spring Boot (`/actuator/prometheus`)
- Sert de datasource principale à Grafana dans ce mode.

## 👀 CloudWatch (Serverless)

- Les Lambdas envoient leurs logs dans CloudWatch Logs
- Des métriques custom sont dérivées pour alimenter les dashboards Grafana :
  - nombre de runs démarrés/terminés
  - volume de données capteur
  - latence / erreurs des Lambdas

## 🔍 À vendre en entretien

- Tu as **deux chaînes de monitoring** :
  - ECS → Prometheus → Grafana
  - Lambda → CloudWatch → Grafana
- Mais une **expérience unifiée** côté utilisateur (mêmes filtres : Run, User, Sensor).
- L’observabilité fait partie intégrante du design, pas un ajout de dernière minute.
