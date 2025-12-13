# Guide de Migration - Spring Boot vers Lambda Serverless

## 📋 Checklist de Migration

### Phase 1: Préparation (Avant déploiement)
- [ ] Vérifier que les secrets AWS sont configurés dans GitHub
- [ ] Valider les DNS Route53 (sentori-studio.com zone existe)
- [ ] Backup de la base PostgreSQL actuelle (si données à migrer)
- [ ] Tester Terraform en local : `terraform plan`

### Phase 2: Déploiement Infrastructure
- [ ] Pousser le code sur `main` pour déclencher le workflow
- [ ] Vérifier le déploiement GitHub Actions
- [ ] Valider la création des tables DynamoDB
- [ ] Valider la création des Lambdas
- [ ] Valider l'API Gateway
- [ ] Tester le custom domain : `https://api-lambda-iot.sentori-studio.com`

### Phase 3: Migration des Données (Si nécessaire)

#### Script de migration PostgreSQL → DynamoDB

**Exporter les Runs depuis PostgreSQL:**
```sql
COPY (
  SELECT 
    id::text,
    username,
    status,
    started_at,
    finished_at,
    params,
    error_message,
    grafana_url
  FROM runs
) TO '/tmp/runs_export.csv' WITH CSV HEADER;
```

**Script Python pour importer dans DynamoDB:**
```python
import boto3
import csv
from datetime import datetime

dynamodb = boto3.resource('dynamodb', region_name='eu-west-3')
table = dynamodb.Table('iot-playground-runs-dev')

with open('runs_export.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        item = {
            'id': row['id'],
            'username': row['username'],
            'status': row['status'],
            'startedAt': row['started_at'],
            'finishedAt': row['finished_at'] if row['finished_at'] else None,
            'params': eval(row['params']) if row['params'] else {},
            'errorMessage': row['error_message'] if row['error_message'] else None,
            'grafanaUrl': row['grafana_url'] if row['grafana_url'] else None
        }
        # Nettoyer les None
        item = {k: v for k, v in item.items() if v is not None}
        table.put_item(Item=item)
        print(f"Imported run: {item['id']}")
```

**Exporter SensorData (similaire):**
```sql
COPY (
  SELECT 
    sensor_id,
    timestamp,
    type,
    reading
  FROM sensor_data
  ORDER BY timestamp DESC
  LIMIT 10000  -- Ajuster selon besoins
) TO '/tmp/sensor_data_export.csv' WITH CSV HEADER;
```

### Phase 4: Configuration Grafana

#### Ajouter CloudWatch comme datasource

1. **Dans Grafana UI:**
   - Settings > Data sources > Add data source
   - Choisir "CloudWatch"
   - Default Region: `eu-west-3`
   - Authentication Provider: AWS SDK Default (ou Access & Secret Key)

2. **Configuration IAM pour Grafana:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:DescribeAlarmsForMetric",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics"
      ],
      "Resource": "*"
    }
  ]
}
```

3. **Créer un Dashboard Grafana:**

**Panel 1: Sensor Readings (Time series)**
```
Namespace: IoTPlayground/Sensors
Metric: SensorReading
Dimensions: SensorId, User, RunId
Statistic: Average
Period: 60s
```

**Panel 2: Data Ingestion Rate (Counter)**
```
Namespace: IoTPlayground/Sensors
Metric: DataIngested
Dimensions: User, RunId
Statistic: Sum
Period: 60s
```

#### Ajouter DynamoDB comme datasource (Optionnel via Athena)

1. Créer une table Athena sur DynamoDB
2. Ajouter Athena comme datasource dans Grafana
3. Requêter avec SQL standard

### Phase 5: Mise à jour du Frontend

**Ancienne URL (Spring Boot):**
```javascript
const API_URL = 'https://api-iot.sentori-studio.com';
```

**Nouvelle URL (Lambda):**
```javascript
const API_URL = 'https://api-lambda-iot.sentori-studio.com';
```

**Changements dans les appels API:**

✅ **Endpoints identiques:**
- `GET /api/runs` → Même endpoint
- `GET /api/runs/{id}` → Même endpoint
- `POST /sensors/data` → Même endpoint
- `GET /sensors/data` → Même endpoint

⚠️ **Différences de pagination:**

**Avant (Spring Boot - Pageable):**
```javascript
fetch('/api/runs?page=0&size=20&sort=startedAt,desc')
```

**Après (Lambda - DynamoDB):**
```javascript
fetch('/api/runs?limit=20')
// Pour page suivante:
fetch('/api/runs?limit=20&lastKey=' + encodeURIComponent(nextKey))
```

**Adaptation du code frontend:**
```javascript
// Avant
async function fetchRuns(page = 0, size = 20) {
  const response = await fetch(`${API_URL}/api/runs?page=${page}&size=${size}&sort=startedAt,desc`);
  const data = await response.json();
  return {
    runs: data.content,
    totalPages: data.totalPages,
    totalElements: data.totalElements
  };
}

// Après
async function fetchRuns(limit = 20, lastKey = null) {
  let url = `${API_URL}/api/runs?limit=${limit}`;
  if (lastKey) {
    url += `&lastKey=${encodeURIComponent(lastKey)}`;
  }
  const response = await fetch(url);
  const data = await response.json();
  return {
    runs: data.items,
    nextKey: data.nextKey, // Pour pagination
    count: data.count
  };
}
```

### Phase 6: Tests

**Exécuter les scripts de test:**
```bash
# Linux/Mac
./scripts/test-lambda-apis.sh

# Windows PowerShell
.\scripts\test-lambda-apis.ps1
```

**Tests manuels:**
```bash
# 1. Créer un run
curl -X POST https://api-lambda-iot.sentori-studio.com/api/runs \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","status":"RUNNING","params":{"test":true}}'

# 2. Ingérer des données
for i in {1..10}; do
  curl -X POST https://api-lambda-iot.sentori-studio.com/sensors/data \
    -H "Content-Type: application/json" \
    -H "X-User: testuser" \
    -H "X-Run-Id: test-run-001" \
    -d "{\"sensorId\":\"sensor-001\",\"type\":\"temperature\",\"reading\":$((20 + RANDOM % 10))}"
  sleep 1
done

# 3. Vérifier dans Grafana que les métriques apparaissent
```

### Phase 7: Monitoring

**CloudWatch Alarms à configurer:**

1. **Lambda Errors > 5%**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name lambda-run-api-errors \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=FunctionName,Value=iot-playground-run-api-dev
```

2. **Lambda Duration > 10s**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name lambda-sensor-api-duration \
  --metric-name Duration \
  --namespace AWS/Lambda \
  --statistic Average \
  --period 60 \
  --threshold 10000 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=FunctionName,Value=iot-playground-sensor-api-dev
```

3. **DynamoDB Throttling**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name dynamodb-sensor-data-throttles \
  --metric-name UserErrors \
  --namespace AWS/DynamoDB \
  --statistic Sum \
  --period 60 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=TableName,Value=iot-playground-sensor-data-dev
```

### Phase 8: Décommissionnement de l'ancienne infrastructure

⚠️ **Faire cette étape APRÈS validation complète !**

```bash
# 1. Commenter les anciens modules dans infra/envs/dev/main.tf
# - module.spring_app_service
# - module.spring_app_alb
# - module.database (RDS)
# - module.prometheus_service
# - module.grafana_service (si non utilisé)

# 2. Appliquer
terraform apply

# 3. Vérifier les économies de coûts
aws ce get-cost-and-usage \
  --time-period Start=2025-01-01,End=2025-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE
```

### Phase 9: Optimisations (Optionnel)

**1. Activer le caching API Gateway:**
```terraform
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  stage_name  = aws_api_gateway_stage.lambda_iot.stage_name
  method_path = "*/*"

  settings {
    caching_enabled = true
    cache_ttl_in_seconds = 300  # 5 minutes
  }
}
```

**2. Ajouter DynamoDB TTL pour auto-cleanup:**
```python
# Dans le handler, ajouter TTL (30 jours)
import time
ttl = int(time.time()) + (30 * 24 * 60 * 60)
item['ttl'] = ttl
```

**3. Lambda Provisioned Concurrency (si traffic élevé):**
```terraform
resource "aws_lambda_provisioned_concurrency_config" "sensor_api" {
  function_name                     = aws_lambda_function.sensor_api.function_name
  provisioned_concurrent_executions = 2
  qualifier                         = aws_lambda_function.sensor_api.version
}
```

## 🔄 Rollback Plan

Si problème critique, rollback rapide:

1. **Remettre l'ancien domaine dans le frontend:**
```javascript
const API_URL = 'https://api-iot.sentori-studio.com'; // Ancien
```

2. **L'ancienne infra Spring Boot reste active** jusqu'à validation complète

3. **Pour supprimer la nouvelle infra Lambda:**
```bash
cd infra/envs/dev
terraform destroy -target=module.lambda_run_api
terraform destroy -target=module.lambda_sensor_api
terraform destroy -target=module.api_gateway_lambda_iot
terraform destroy -target=module.dynamodb_tables
```

## 📞 Support

**Logs Lambda:**
```bash
aws logs tail /aws/lambda/iot-playground-run-api-dev --follow
aws logs tail /aws/lambda/iot-playground-sensor-api-dev --follow
```

**Métriques temps réel:**
```bash
watch -n 5 'aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=iot-playground-sensor-api-dev \
  --start-time $(date -u -d "5 minutes ago" +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum'
```

---

**Estimation temps migration:** 2-4 heures  
**Downtime:** 0 (blue-green deployment)  
**Coût économisé:** ~$50-100/mois (RDS + ECS vs Lambda + DynamoDB)

