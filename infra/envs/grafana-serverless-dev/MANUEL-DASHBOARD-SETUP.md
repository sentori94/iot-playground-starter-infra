# 📊 Guide : Ajouter Manuellement le Dashboard Grafana

## 🎯 Objectif
Créer le dashboard "IoT Serverless - DynamoDB Data" manuellement dans Grafana.

---

## ✅ Prérequis

Avant de créer le dashboard, assurez-vous que :

### 1. Les tables Athena sont créées

Allez sur **AWS Athena Console** et exécutez ces requêtes :

```sql
-- Créer la table runs
CREATE EXTERNAL TABLE IF NOT EXISTS runs (
  id string,
  username string,
  status string,
  startedAt string,
  finishedAt string,
  params string,
  errorMessage string,
  grafanaUrl string
)
STORED BY 'org.apache.hadoop.hive.dynamodb.DynamoDBStorageHandler'
TBLPROPERTIES (
  "dynamodb.table.name" = "iot-playground-runs-serverless-dev",
  "dynamodb.column.mapping" = "id:id,username:username,status:status,startedAt:startedAt,finishedAt:finishedAt,params:params,errorMessage:errorMessage,grafanaUrl:grafanaUrl"
);
```

```sql
-- Créer la table sensor_data
CREATE EXTERNAL TABLE IF NOT EXISTS sensor_data (
  sensorId string,
  timestamp string,
  type string,
  reading double,
  user string,
  runId string
)
STORED BY 'org.apache.hadoop.hive.dynamodb.DynamoDBStorageHandler'
TBLPROPERTIES (
  "dynamodb.table.name" = "iot-playground-sensor-data-serverless-dev",
  "dynamodb.column.mapping" = "sensorId:sensorId,timestamp:timestamp,type:type,reading:reading,user:user,runId:runId"
);
```

### 2. Le datasource Athena est configuré

Dans Grafana :
1. **Configuration** → **Data sources**
2. Cliquer sur **"Athena-DynamoDB"** (ou ajouter un nouveau datasource "Amazon Athena")
3. Configuration :
   - **Authentication Provider** : AWS SDK Default
   - **Default Region** : `eu-west-3`
   - **Catalog** : `AwsDataCatalog`
   - **Database** : `iot_playground_grafana_serverless_dev`
   - **Workgroup** : `iot-playground-grafana-grafana-serverless-dev`
   - **Output Location** (optionnel) : `s3://iot-playground-athena-results-grafana-serverless-dev/results/`
4. **Save & Test** → Doit afficher "Success ✅"

---

## 📊 Créer le Dashboard Manuellement

### Étape 1 : Créer un nouveau dashboard

1. Dans Grafana, cliquer sur **"+" → Dashboard**
2. Cliquer sur **"Add a new panel"**

### Étape 2 : Panel 1 - Runs par Statut (Pie Chart)

**Configuration :**
- **Title** : `Runs par Statut`
- **Visualization** : `Pie chart`
- **Data source** : `Athena-DynamoDB`
- **Query** :
  ```sql
  SELECT status, COUNT(*) as count 
  FROM runs 
  GROUP BY status
  ```
- **Format** : `Table`

Cliquer **"Apply"**.

### Étape 3 : Panel 2 - Derniers Runs (Table)

1. Cliquer **"Add panel"**
2. **Configuration :**
   - **Title** : `Derniers Runs`
   - **Visualization** : `Table`
   - **Data source** : `Athena-DynamoDB`
   - **Query** :
     ```sql
     SELECT id, username, status, startedAt, finishedAt 
     FROM runs 
     ORDER BY startedAt DESC 
     LIMIT 20
     ```
   - **Format** : `Table`

Cliquer **"Apply"**.

### Étape 4 : Panel 3 - Sensor Readings (Time Series)

1. Cliquer **"Add panel"**
2. **Configuration :**
   - **Title** : `Sensor Readings (Time Series)`
   - **Visualization** : `Time series`
   - **Data source** : `Athena-DynamoDB`
   - **Query** :
     ```sql
     SELECT 
       from_iso8601_timestamp(timestamp) as time,
       sensorId,
       reading
     FROM sensor_data
     WHERE type = 'temperature'
       AND from_iso8601_timestamp(timestamp) > current_timestamp - interval '6' hour
     ORDER BY timestamp DESC
     LIMIT 1000
     ```
   - **Format** : `Time series`
   - **Field Config** :
     - **Unit** : `Celsius (°C)`
     - **Display name** : `${__field.labels.sensorId}`

Cliquer **"Apply"**.

### Étape 5 : Panel 4 - Sensor Data par Type (Bar Chart)

1. Cliquer **"Add panel"**
2. **Configuration :**
   - **Title** : `Sensor Data par Type`
   - **Visualization** : `Bar chart`
   - **Data source** : `Athena-DynamoDB`
   - **Query** :
     ```sql
     SELECT type, COUNT(*) as count 
     FROM sensor_data 
     GROUP BY type
     ```
   - **Format** : `Table`

Cliquer **"Apply"**.

### Étape 6 : Panel 5 - Statistiques par Sensor (Table)

1. Cliquer **"Add panel"**
2. **Configuration :**
   - **Title** : `Statistiques par Sensor`
   - **Visualization** : `Table`
   - **Data source** : `Athena-DynamoDB`
   - **Query** :
     ```sql
     SELECT 
       sensorId,
       type,
       AVG(reading) as avg_reading,
       MIN(reading) as min_reading,
       MAX(reading) as max_reading,
       COUNT(*) as count
     FROM sensor_data
     GROUP BY sensorId, type
     ORDER BY count DESC
     LIMIT 20
     ```
   - **Format** : `Table`

Cliquer **"Apply"**.

### Étape 7 : Panel 6 - CloudWatch Lambda Invocations (Optionnel)

1. Cliquer **"Add panel"**
2. **Configuration :**
   - **Title** : `Lambda Invocations`
   - **Visualization** : `Time series`
   - **Data source** : `CloudWatch`
   - **Query** :
     - **Namespace** : `AWS/Lambda`
     - **Metric** : `Invocations`
     - **Dimensions** : `FunctionName = iot-playground-sensor-api-serverless-dev`
     - **Statistic** : `Sum`
     - **Period** : `5 minutes`

Cliquer **"Apply"**.

---

## 💾 Sauvegarder le Dashboard

1. Cliquer sur l'icône **"Save dashboard"** (en haut à droite)
2. **Title** : `IoT Serverless - DynamoDB Data`
3. **Folder** : `General` (ou créer un nouveau dossier)
4. Cliquer **"Save"**

---

## 🧪 Tester avec des Données

Si vous n'avez pas encore de données dans DynamoDB, voici comment tester :

### Option 1 : Insérer des données de test via AWS Console

**DynamoDB Console → Table `iot-playground-runs-serverless-dev` → Create item :**

```json
{
  "id": "test-run-001",
  "username": "test-user",
  "status": "COMPLETED",
  "startedAt": "2025-01-15T10:00:00Z",
  "finishedAt": "2025-01-15T10:05:00Z",
  "params": "{}"
}
```

**DynamoDB Console → Table `iot-playground-sensor-data-serverless-dev` → Create item :**

```json
{
  "sensorId": "sensor-001",
  "timestamp": "2025-01-15T10:00:00Z",
  "type": "temperature",
  "reading": 22.5,
  "user": "test-user",
  "runId": "test-run-001"
}
```

### Option 2 : Utiliser l'API Lambda (quand déployée)

```bash
curl -X POST https://api-lambda-iot.sentori-studio.com/sensors/data \
  -H "Content-Type: application/json" \
  -d '{
    "sensorId": "sensor-001",
    "type": "temperature",
    "reading": 22.5,
    "user": "test-user",
    "runId": "test-run-001"
  }'
```

---

## 🐛 Troubleshooting

### Le datasource Athena ne se connecte pas

- Vérifier les permissions IAM du rôle de tâche Grafana
- Vérifier que le workgroup et la database existent dans Athena Console

### Les requêtes Athena retournent "Table not found"

- Vérifier que les tables `runs` et `sensor_data` sont créées dans Athena
- Vérifier le nom de la database : `iot_playground_grafana_serverless_dev`

### Pas de données dans les panels

- Vérifier qu'il y a des données dans DynamoDB
- Tester les requêtes SQL directement dans Athena Console

### Les timestamps ne s'affichent pas correctement

Utiliser la fonction `from_iso8601_timestamp()` dans les requêtes Athena :
```sql
SELECT from_iso8601_timestamp(timestamp) as time, ...
```

---

## 📚 Requêtes SQL Utiles

### Compter le nombre total d'enregistrements

```sql
SELECT COUNT(*) FROM runs;
SELECT COUNT(*) FROM sensor_data;
```

### Données des dernières 24h

```sql
SELECT * 
FROM sensor_data 
WHERE from_iso8601_timestamp(timestamp) > current_timestamp - interval '24' hour
ORDER BY timestamp DESC;
```

### Moyenne des lectures par type

```sql
SELECT 
  type,
  AVG(reading) as avg_reading,
  MIN(reading) as min_reading,
  MAX(reading) as max_reading
FROM sensor_data
GROUP BY type;
```

---

**Voilà ! Votre dashboard est maintenant créé manuellement ! 🎉**

Une fois que vous aurez des données dans DynamoDB (via les Lambdas), le dashboard affichera les visualisations automatiquement.

