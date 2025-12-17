# Modules Compute (ECS & Lambda)

Cette section décrit comment la puissance de calcul est factorisée en modules Terraform.

## 🐳 ECS (module `ecs`)

- Définit un **cluster ECS Fargate** partagé pour :
  - L’application Spring Boot
  - Prometheus
  - Grafana (mode ECS classique)
- Paramètres typiques :
  - vCPU / mémoire par tâche
  - Auto-scaling possible selon la charge

**Idée clé** : encapsuler toute la brique "cluster conteneurs" dans un module unique.

## ⚡ Lambda (modules `serverless/lambda_*`)

Modules dédiés :
- `lambda_run_api` :
  - Fonction Python pour gérer les runs (can-start, start, finish, interrupt-all…)
  - Connectée à DynamoDB (table Runs)
  - Exposée via API Gateway
- `lambda_sensor_api` :
  - Fonction Python pour l’ingestion des données capteurs
  - Connectée à DynamoDB (table SensorData)
  - Exposée via API Gateway

**Idée clé** : chaque Lambda a son module, avec ses variables propres (noms de tables, URL Grafana, etc.), mais suit les mêmes conventions (tags, logs, IAM).

## 🔍 Ce que ça montre

- Une **approche modulaire** côté compute : on peut faire évoluer ECS ou Lambda indépendamment.
- Possibilité de réutiliser ces modules dans d’autres environnements (staging, prod…).
- En entretien, tu peux montrer que tu sais découper proprement la couche compute entre conteneurs et fonctions serverless.
