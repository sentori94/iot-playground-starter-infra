# Architecture Serverless Lambda - IoT Playground

## 🎯 Vue d'ensemble

Cette architecture remplace les contrôleurs Spring Boot (RunController & SensorController) par des **Lambda Python serverless** avec **DynamoDB** et **CloudWatch Metrics** pour Grafana.

## 🏗️ Architecture

```
┌─────────────────┐
│   Frontend      │
│  (React/Vue)    │
└────────┬────────┘
         │ HTTPS
         ▼
┌─────────────────────────────────────────┐
│  API Gateway (api-lambda-iot.sentori... │
│  - /api/runs                             │
│  - /api/runs/{id}                        │
│  - /api/runs/all                         │
│  - /sensors/data (POST/GET)              │
└──────────┬──────────────────────────────┘
           │
    ┌──────┴──────┐
    ▼             ▼
┌────────┐   ┌────────┐
│Lambda  │   │Lambda  │
│Run API │   │Sensor  │
└───┬────┘   └───┬────┘
    │            │
    │ ┌──────────┴─────────┐
    │ │                    │
    ▼ ▼                    ▼
┌──────────┐       ┌──────────────┐
│DynamoDB  │       │  CloudWatch  │
│- Runs    │       │   Metrics    │
│- Sensor  │       │ (pour Grafana)│
└──────────┘       └──────────────┘
```

## 📦 Modules Terraform

Tous les modules serverless sont regroupés dans `infra/modules/serverless/`.

### 1. `serverless/dynamodb_tables`
Crée 2 tables DynamoDB :
- **Runs** : Stocke les exécutions (id, username, status, startedAt, finishedAt, params, errorMessage, grafanaUrl)
- **SensorData** : Stocke les données capteurs (sensorId, timestamp, type, reading, user, runId)

**Indexes:**
- GSI `username-startedAt-index` sur Runs
- GSI `runId-timestamp-index` sur SensorData

### 2. `serverless/lambda_run_api`
Lambda Python 3.11 pour gérer les runs :
- **GET /api/runs** : Liste paginée (avec `?limit=20&lastKey=xxx`)
- **GET /api/runs/{id}** : Récupère un run par UUID
- **GET /api/runs/all** : Tous les runs triés par startedAt DESC

**Permissions IAM:**
- DynamoDB: GetItem, Query, Scan sur table Runs
- CloudWatch Logs

### 3. `serverless/lambda_sensor_api`
Lambda Python 3.11 pour gérer les capteurs :
- **POST /sensors/data** : Ingestion avec headers `X-User` et `X-Run-Id`
- **GET /sensors/data** : Liste avec filtres optionnels `?sensorId=xxx&runId=yyy`

**Fonctionnalités:**
- Publie métriques vers **CloudWatch** (namespace `IoTPlayground/Sensors`)
- Métriques: `SensorReading` (valeur) et `DataIngested` (compteur)
- Dimensions: SensorId, User, RunId, Type

**Permissions IAM:**
- DynamoDB: GetItem, PutItem, Query, Scan sur table SensorData
- CloudWatch: PutMetricData
- CloudWatch Logs

### 4. `serverless/api_gateway_lambda_iot`
API Gateway REST avec :
- Toutes les routes vers les lambdas
- Custom domain `api-lambda-iot.sentori-studio.com`
- Certificat ACM
- CORS configuré
- Stage `dev`

## 🚀 Déploiement

### Prérequis
- AWS CLI configuré
- Terraform >= 1.6.0
- Secrets GitHub : `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

### Déploiement manuel
```bash
cd infra/envs/serverless-dev
terraform init
terraform plan
terraform apply
```

### Déploiement automatique (GitHub Actions)
Le workflow `.github/workflows/deploy-lambdas.yml` se déclenche sur :
- Push sur `main` avec changements dans les modules Lambda
- Workflow manual dispatch

```bash
git add .
git commit -m "feat: add lambda serverless architecture"
git push origin main
```

## 📊 Grafana & CloudWatch

### Configuration Grafana

**Option recommandée : Grafana Cloud** (voir [GRAFANA-SERVERLESS.md](../../GRAFANA-SERVERLESS.md))

1. Créer un compte sur grafana.com
2. Créer un stack (ex: sentori-iot.grafana.net)
3. Ajouter datasource **CloudWatch**
4. Région: `eu-west-3`
5. Namespace: `IoTPlayground/Sensors`

### Requêtes CloudWatch pour Grafana
```
Métrique: SensorReading
Dimensions: SensorId, User, RunId, Type
Agrégation: Average, Sum, Max
```

### Alternative : CloudWatch Dashboards
Pour rester 100% serverless, vous pouvez aussi utiliser les dashboards CloudWatch natifs sans Grafana.

## 🧪 Tests

### Test API Gateway
```bash
# Récupérer tous les runs
curl https://api-lambda-iot.sentori-studio.com/api/runs/all

# Récupérer un run par ID
curl https://api-lambda-iot.sentori-studio.com/api/runs/{uuid}

# Ingérer des données capteur
curl -X POST https://api-lambda-iot.sentori-studio.com/sensors/data \
  -H "Content-Type: application/json" \
  -H "X-User: testuser" \
  -H "X-Run-Id: test-run-123" \
  -d '{
    "sensorId": "sensor-001",
    "type": "temperature",
    "reading": 23.5
  }'

# Liste des données capteurs
curl https://api-lambda-iot.sentori-studio.com/sensors/data?sensorId=sensor-001
```

### Test local (optionnel avec SAM CLI)
```bash
sam local invoke LambdaRunApi --event events/get-runs.json
```

## 📝 Comparaison ECS vs Serverless

### Différences clés
| Architecture ECS | Architecture Serverless |
|------------------|------------------------|
| PostgreSQL RDS | DynamoDB |
| JPA/Hibernate | boto3 SDK |
| Prometheus metrics | CloudWatch Metrics |
| @GetMapping | API Gateway routes |
| Always-on | Pay-per-use |
| Long-running | Stateless (30s timeout) |
| $60/mois | $3/mois |

> 💡 **Note** : Les deux architectures coexistent. L'utilisateur choisit son mode depuis le frontend (onglet ECS ou Serverless).

### Modèles de données

**RunEntity (Spring)** → **Runs (DynamoDB)**
```python
{
  "id": "uuid-string",
  "username": "john",
  "status": "SUCCESS",
  "startedAt": "2025-01-01T10:00:00Z",
  "finishedAt": "2025-01-01T10:05:00Z",
  "params": {"key": "value"},
  "errorMessage": null,
  "grafanaUrl": "https://..."
}
```

**SensorData (Spring)** → **SensorData (DynamoDB)**
```python
{
  "sensorId": "sensor-001",
  "timestamp": "2025-01-01T10:00:00Z",
  "type": "temperature",
  "reading": 23.5,
  "user": "john",
  "runId": "run-uuid"
}
```

## 💰 Coûts estimés

### DynamoDB (Pay-per-request)
- Lectures: $0.25 / million
- Écritures: $1.25 / million

### Lambda
- 1M requêtes gratuites/mois
- $0.20 / million après
- Compute: $0.0000166667 / GB-seconde

### API Gateway
- 1M appels: $3.50

**Estimation mensuelle (10k requêtes/jour):**
- Lambda: ~$0.50
- DynamoDB: ~$1
- API Gateway: ~$1
- CloudWatch: ~$0.50
**Total: ~$3/mois** 🎉

## 🔒 Sécurité

### IAM Least Privilege
Chaque Lambda a uniquement accès à sa table DynamoDB spécifique.

### CORS
Configuré pour accepter les domaines frontend.

### À améliorer (optionnel)
- [ ] API Key sur API Gateway
- [ ] Cognito User Pool pour auth
- [ ] WAF pour protection DDoS
- [ ] VPC Endpoints pour DynamoDB (si besoin de VPC)

## 📚 Documentation

- [AWS Lambda Python](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html)
- [DynamoDB SDK Python](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/dynamodb.html)
- [API Gateway Proxy Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html)
- [CloudWatch Metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/working_with_metrics.html)

## 🎯 Prochaines étapes

1. ✅ Déployer l'infrastructure
2. ⬜ Migrer les données existantes de PostgreSQL → DynamoDB
3. ⬜ Configurer Grafana pour lire CloudWatch
4. ⬜ Mettre à jour le frontend pour pointer vers la nouvelle API
5. ⬜ Ajouter des alarmes CloudWatch
6. ⬜ Décommissionner l'ancienne infrastructure Spring Boot + RDS

---

**Auteur:** Sentori Studio  
**Date:** Décembre 2025  
**Version:** 1.0.0

