# Architecture Serverless

## 🎯 Vue d'ensemble

L'architecture Serverless remplace complètement le backend Spring Boot par des **fonctions Lambda Python** et la base PostgreSQL par **DynamoDB**. Cette approche "sans serveur" permet de ne payer que pour les requêtes effectuées, réduisant drastiquement les coûts pour les applications à faible trafic.

### Composants Principaux

**API Gateway** : Point d'entrée HTTPS (`api-lambda-iot.sentori-studio.com`) qui route les requêtes vers les Lambdas appropriées

**Lambda Functions** : Deux fonctions Python 3.11 isolées :
- `lambda_run_api` : Gestion des simulations (démarrer, finir, lister)
- `lambda_sensor_api` : Ingestion et récupération des données capteurs

**DynamoDB** : Deux tables NoSQL en mode on-demand :
- `Runs` : Stocke les métadonnées des simulations
- `SensorData` : Stocke les mesures des capteurs

**CloudWatch Logs** : Collecte les logs et métriques custom des Lambdas

**Grafana (Optionnel)** : Conteneur ECS qui query CloudWatch pour afficher les dashboards

## 📋 Ressources AWS

### Lambda Functions

| Fonction | Runtime | Mémoire | Timeout | Trigger |
|----------|---------|---------|---------|---------|
| **run-api** | Python 3.11 | 512 MB | 30s | API Gateway |
| **sensor-api** | Python 3.11 | 512 MB | 30s | API Gateway |

### DynamoDB Tables

**Runs Table**
```
Partition Key: id (String, UUID)
Attributes:
  - username (String)
  - status (String: RUNNING, COMPLETED, FAILED, INTERRUPTED)
  - startedAt (String, ISO 8601)
  - finishedAt (String, ISO 8601, optional)
  - duration (Number, seconds)
  - interval (Number, seconds)
  - params (Map)
  - grafanaUrl (String)
```

**SensorData Table**
```
Partition Key: id (String, UUID)
Sort Key: timestamp (String, ISO 8601)
Attributes:
  - runId (String, UUID)
  - username (String)
  - sensorId (String)
  - temperature (Number)
  - humidity (Number, optional)
  - pressure (Number, optional)
```

## 🔄 Flux API

### Démarrer une Simulation

1. Frontend envoie `POST /api/runs/start` avec `{duration, interval}`
2. API Gateway invoque `lambda_run_api`
3. Lambda vérifie la limite (max 5 simulations concurrentes globales)
4. Si OK : génère un UUID, écrit dans DynamoDB `Runs` avec status `RUNNING`
5. Retourne `{id, grafanaUrl, ...}` au frontend

### Ingérer des Données Capteur

1. Frontend envoie `POST /api/sensors/data` avec `{runId, sensorId, temperature}`
2. API Gateway invoque `lambda_sensor_api`
3. Lambda valide les données et écrit dans DynamoDB `SensorData`
4. Logs les métriques custom dans CloudWatch
5. Retourne `201 Created`

Le frontend répète cette opération toutes les N secondes (selon l'interval configuré) jusqu'à la fin de la simulation.

## 🎛️ Endpoints API

### Run Controller

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/runs/can-start` | Vérifier limite (5 max global) |
| GET | `/api/runs/running` | Lister runs actifs (tous users) |
| POST | `/api/runs/start` | Démarrer simulation |
| POST | `/api/runs/{id}/finish` | Terminer simulation |
| POST | `/api/runs/interrupt-all` | Interrompre toutes simulations |
| GET | `/api/runs/{id}` | Détails d'un run |
| GET | `/api/runs` | Liste paginée |
| GET | `/api/runs/all` | Tous les runs |

### Sensor Controller

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/sensors/data` | Ingérer données capteur |
| GET | `/api/sensors/data` | Récupérer données |

## 📊 Monitoring CloudWatch

CloudWatch collecte automatiquement plusieurs types de métriques :

### Métriques Lambda Standard
- **Invocations** : Nombre d'appels aux fonctions
- **Duration** : Temps d'exécution moyen
- **Errors** : Taux d'erreur
- **Throttles** : Invocations rejetées par limite de concurrence

### Métriques Custom
Les Lambdas loggent des métriques métier spécifiques :
- `run_started` / `run_completed` : Suivi des simulations
- `sensor_data_ingested` : Volume de données capteur
- `temperature_avg` : Température moyenne par run

### Métriques DynamoDB
- **ConsumedReadCapacity** / **ConsumedWriteCapacity** : Utilisation des tables
- **SuccessfulRequestLatency** : Latence des requêtes

Grafana query ces métriques via le plugin CloudWatch pour afficher des dashboards temps réel.

## 💰 Coûts

**Configuration actuelle** (serverless-dev)

| Ressource | Coût Idle | Coût Actif (estimation) |
|-----------|-----------|-------------------------|
| Lambda (2 fonctions) | $0 | $0.0000002 / invocation |
| DynamoDB (2 tables, on-demand) | $0 | $0.25 / million writes |
| API Gateway | $0 | $3.50 / million requests |
| CloudWatch Logs | ~$0.50/mois | Variable |
| **Grafana ECS** | ~$40/mois | ~$40/mois |
| **VPC (NAT, IGW)** | ~$40/mois | ~$40/mois |
| **TOTAL** | **~$80/mois** | **~$80/mois + usage** |

!!! tip "Économie"
    Pour réduire les coûts, détruire Grafana quand non utilisé :
    ```bash
    Component: grafana
    Action: destroy
    ```
    → Coût idle : **~$1/mois** (CloudWatch Logs uniquement)

## 🔐 Sécurité

### API Gateway
- **HTTPS obligatoire** : Certificat ACM wildcard pour `*.sentori-studio.com`
- **Custom Domain** : Domaine personnalisé avec Route53
- **CORS configuré** : Headers autorisés pour le frontend Angular

### Lambda
- **IAM Execution Role** : Permissions minimales (lecture/écriture DynamoDB, logs CloudWatch)
- **Environment Variables** : Configuration injectée au runtime (tables DynamoDB, région)
- **Pas de VPC** : Les Lambdas sont publiques pour réduire les coûts (pas de NAT Gateway)

### DynamoDB
- **Encryption at Rest** : Chiffrement automatique avec clés AWS
- **IAM Permissions** : Accès restreint aux Lambdas uniquement

## 🚀 Déploiement

Le déploiement est géré via **GitHub Actions** avec un workflow unifié (`deploy-serverless-unified.yml`) qui permet de déployer :

- **Lambdas uniquement** : DynamoDB + Lambda Functions + API Gateway (~5 min)
- **Grafana uniquement** : VPC + ECS + ALB (~10 min)
- **Full** : Tout l'environnement serverless (~15 min)

Les ressources sont créées avec Terraform en utilisant des **targets** pour déployer/détruire de manière granulaire et indépendante.

