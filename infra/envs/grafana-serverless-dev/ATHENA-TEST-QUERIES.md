# 🧪 Requêtes SQL pour Tester Athena

## 📋 Prérequis

**Avant de lancer les requêtes, sélectionnez le bon workgroup :**
- Workgroup : `iot-playground-grafana-grafana-serverless-dev`
- Database : `iot_playground_grafana_serverless_dev`

---

## ✅ Requêtes de Test (par ordre de difficulté)

### 1. Vérifier que les tables existent

```sql
SHOW TABLES;
```

**Résultat attendu :**
```
runs
sensor_data
```

---

### 2. Compter les enregistrements dans chaque table

```sql
SELECT COUNT(*) as total_runs FROM runs;
```

```sql
SELECT COUNT(*) as total_sensor_data FROM sensor_data;
```

**Résultat attendu :** Un nombre (probablement 0 si pas encore de données)

---

### 3. Voir la structure des tables

```sql
DESCRIBE runs;
```

```sql
DESCRIBE sensor_data;
```

**Résultat attendu :** Liste des colonnes avec leurs types

---

### 4. Récupérer toutes les données (LIMIT 10)

```sql
SELECT * FROM runs LIMIT 10;
```

```sql
SELECT * FROM sensor_data LIMIT 10;
```

**Résultat attendu :** Les 10 premiers enregistrements (vide si pas de données)

---

### 5. Grouper par statut (Runs)

```sql
SELECT 
  status, 
  COUNT(*) as count 
FROM runs 
GROUP BY status;
```

**Résultat attendu :**
```
status       | count
-------------|------
COMPLETED    | 5
RUNNING      | 2
FAILED       | 1
```

---

### 6. Grouper par type de sensor

```sql
SELECT 
  type, 
  COUNT(*) as count 
FROM sensor_data 
GROUP BY type;
```

**Résultat attendu :**
```
type         | count
-------------|------
temperature  | 100
humidity     | 80
pressure     | 60
```

---

### 7. Statistiques sur les lectures de sensors

```sql
SELECT 
  type,
  AVG(reading) as avg_reading,
  MIN(reading) as min_reading,
  MAX(reading) as max_reading,
  COUNT(*) as total_readings
FROM sensor_data
GROUP BY type;
```

**Résultat attendu :**
```
type        | avg_reading | min_reading | max_reading | total_readings
------------|-------------|-------------|-------------|---------------
temperature | 22.5        | 18.0        | 28.0        | 100
humidity    | 65.3        | 45.0        | 85.0        | 80
```

---

### 8. Derniers runs (triés par date)

```sql
SELECT 
  id, 
  username, 
  status, 
  startedAt, 
  finishedAt
FROM runs
ORDER BY startedAt DESC
LIMIT 10;
```

---

### 9. Sensor data des dernières 24 heures

```sql
SELECT 
  sensorId,
  timestamp,
  type,
  reading
FROM sensor_data
WHERE from_iso8601_timestamp(timestamp) > current_timestamp - interval '24' hour
ORDER BY timestamp DESC
LIMIT 50;
```

**Note :** Cette requête utilise `from_iso8601_timestamp()` pour convertir les timestamps ISO 8601.

---

### 10. Moyenne des lectures par sensor ID

```sql
SELECT 
  sensorId,
  type,
  AVG(reading) as avg_reading,
  COUNT(*) as count
FROM sensor_data
GROUP BY sensorId, type
ORDER BY count DESC
LIMIT 20;
```

---

## 🐛 Si vous avez l'erreur "No output location"

### Solution 1 : Utiliser le workgroup configuré

Dans Athena Console :
1. En haut à droite, cliquer sur **"Workgroup"**
2. Sélectionner : `iot-playground-grafana-grafana-serverless-dev`
3. Relancer la requête

### Solution 2 : Redéployer le module Athena (avec la correction)

```bash
cd infra/envs/grafana-serverless-dev
terraform apply -target=module.athena_dynamodb
```

Cela ajoutera `enforce_workgroup_configuration = true` dans le workgroup.

### Solution 3 : Configurer manuellement

Dans Athena Console :
1. **Settings** (en haut à droite)
2. **Manage**
3. **Query result location** : `s3://iot-playground-athena-results-grafana-serverless-dev/results/`
4. **Save**

---

## 📝 Insérer des Données de Test dans DynamoDB

Si vous n'avez pas encore de données, voici comment en ajouter via AWS Console :

### Table `iot-playground-runs-serverless-dev`

**DynamoDB Console → Create item :**

```json
{
  "id": "test-run-001",
  "username": "test-user",
  "status": "COMPLETED",
  "startedAt": "2025-01-15T10:00:00Z",
  "finishedAt": "2025-01-15T10:05:00Z",
  "params": "{}",
  "grafanaUrl": "http://grafana.example.com"
}
```

```json
{
  "id": "test-run-002",
  "username": "john-doe",
  "status": "RUNNING",
  "startedAt": "2025-01-15T11:00:00Z",
  "params": "{\"mode\": \"fast\"}"
}
```

### Table `iot-playground-sensor-data-serverless-dev`

**DynamoDB Console → Create item :**

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

```json
{
  "sensorId": "sensor-001",
  "timestamp": "2025-01-15T10:01:00Z",
  "type": "temperature",
  "reading": 23.1,
  "user": "test-user",
  "runId": "test-run-001"
}
```

```json
{
  "sensorId": "sensor-002",
  "timestamp": "2025-01-15T10:00:00Z",
  "type": "humidity",
  "reading": 65.3,
  "user": "test-user",
  "runId": "test-run-001"
}
```

---

## ✅ Vérification Finale

Après avoir inséré des données de test, relancez les requêtes :

```sql
-- Doit retourner au moins 2
SELECT COUNT(*) FROM runs;

-- Doit retourner au moins 3
SELECT COUNT(*) FROM sensor_data;

-- Doit afficher les données
SELECT * FROM runs LIMIT 10;
SELECT * FROM sensor_data LIMIT 10;
```

---

**Voilà ! Vous pouvez maintenant tester Athena avec ces requêtes !** 🎉

Une fois que les requêtes fonctionnent dans Athena Console, elles fonctionneront aussi dans Grafana.

