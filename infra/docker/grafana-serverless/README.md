# 🐳 Grafana Serverless - Docker Image

## 📦 Repo ECR

**Nom du repo à créer manuellement :** `iot-playground-grafana-serverless`

```bash
# Créer le repo ECR
aws ecr create-repository \
  --repository-name iot-playground-grafana-serverless \
  --region eu-west-3
```

---

## 🔧 Contenu de l'Image

Cette image Grafana personnalisée inclut :

- **Grafana 10.2.3** (base officielle)
- **Plugin Athena** préinstallé (pour requêter DynamoDB)
- **Datasources préconfigurés** :
  - Athena-DynamoDB (principal)
  - CloudWatch (métriques Lambda)
- **Dashboard exemple** pour visualiser les données DynamoDB

---

## 🚀 Builder et Pousser l'Image

### Étape 1 : Se connecter à ECR

```bash
aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com
```

### Étape 2 : Builder l'image

```bash
cd infra/docker/grafana-serverless

docker build -t iot-playground-grafana-serverless:latest .
```

### Étape 3 : Tagger l'image

```bash
docker tag iot-playground-grafana-serverless:latest <ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless:latest
```

### Étape 4 : Pousser vers ECR

```bash
docker push <ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless:latest
```

---

## ⚙️ Variables d'Environnement

L'image attend ces variables d'environnement (fournies par Terraform) :

- `AWS_REGION` : Région AWS (ex: eu-west-3)
- `ATHENA_WORKGROUP` : Nom du workgroup Athena
- `ATHENA_DATABASE` : Nom de la database Athena
- `GF_SERVER_ROOT_URL` : URL publique de Grafana
- `GF_SECURITY_ADMIN_PASSWORD` : Mot de passe admin

---

## 📊 Datasources Configurés

### 1. Athena-DynamoDB (Principal)

Requête les tables DynamoDB via Athena :
- **runs** : Informations sur les exécutions
- **sensor_data** : Données des capteurs

**Exemples de requêtes SQL :**

```sql
-- Runs par statut
SELECT status, COUNT(*) as count 
FROM runs 
GROUP BY status;

-- Sensor readings (dernières 24h)
SELECT 
  from_iso8601_timestamp(timestamp) as time,
  sensorId,
  type,
  reading
FROM sensor_data
WHERE from_iso8601_timestamp(timestamp) > current_timestamp - interval '24' hour
ORDER BY timestamp DESC;

-- Moyenne par sensor
SELECT 
  sensorId,
  type,
  AVG(reading) as avg_reading,
  COUNT(*) as count
FROM sensor_data
GROUP BY sensorId, type;
```

### 2. CloudWatch (Métriques Lambda)

Visualise les métriques Lambda et custom :
- Invocations, Errors, Duration (métriques Lambda AWS)
- SensorReading, DataIngested (métriques custom)

---

## 🎨 Dashboard Inclus

**Dashboard : IoT Serverless - DynamoDB Data**

Panels inclus :
1. **Runs par Statut** (Pie chart)
2. **Derniers Runs** (Table)
3. **Sensor Readings** (Time series)
4. **Sensor Data par Type** (Bar chart)
5. **Sensor Data par Sensor ID** (Table)
6. **Lambda Invocations** (CloudWatch)
7. **Custom Metrics** (CloudWatch)

---

## 🔄 Mise à Jour de l'Image

Pour mettre à jour l'image après modifications :

```bash
# 1. Rebuild
docker build -t iot-playground-grafana-serverless:latest .

# 2. Retag
docker tag iot-playground-grafana-serverless:latest <ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless:latest

# 3. Push
docker push <ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless:latest

# 4. Redémarrer le service ECS
aws ecs update-service \
  --cluster iot-playground-serverless-dev \
  --service iot-playground-grafana-serverless-serverless-dev \
  --force-new-deployment \
  --region eu-west-3
```

---

## 📝 Structure des Fichiers

```
infra/docker/grafana-serverless/
├── Dockerfile
├── provisioning/
│   ├── datasources/
│   │   └── datasources.yml          # Config Athena + CloudWatch
│   └── dashboards/
│       └── dashboards.yml            # Config provider dashboards
└── dashboards/
    └── iot-serverless-dynamodb.json  # Dashboard principal
```

---

## 🔐 Permissions IAM

Le rôle IAM de la tâche Grafana (créé par Terraform) inclut :
- ✅ Athena (requêtes SQL)
- ✅ DynamoDB (scan/query via Athena)
- ✅ CloudWatch (métriques)
- ✅ S3 (résultats Athena)
- ✅ Glue Data Catalog

---

## 🌐 Accès

Après déploiement, Grafana sera accessible sur :
- **URL custom** : https://grafana-lambda-iot.sentori-studio.com
- **Credentials** : admin / `<mot_de_passe_terraform>`

---

## 🐛 Troubleshooting

### Athena ne retourne pas de données

1. Vérifier que les tables Athena sont créées :
```sql
SHOW TABLES IN iot_playground_serverless_dev;
```

2. Exécuter les named queries dans Athena Console :
- `create-runs-table`
- `create-sensor-data-table`

### Plugin Athena non trouvé

Rebuild l'image en forçant :
```bash
docker build --no-cache -t iot-playground-grafana-serverless:latest .
```

### Datasource Athena ne se connecte pas

Vérifier les permissions IAM du rôle de tâche Grafana dans AWS Console.

---

**Image maintenue pour :** IoT Playground Serverless Architecture

