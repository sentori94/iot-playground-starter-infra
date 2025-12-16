# 📊 Documentation : Logging & Metrics CloudWatch

## 🎯 Vue d'ensemble

Ce document explique comment les Lambdas envoient des **logs** et des **métriques** vers CloudWatch pour le monitoring dans Grafana.

---

## 📝 1. CloudWatch Logs (Logs Structurés)

### Concept

Les logs sont des **messages textuels** envoyés automatiquement vers CloudWatch Logs via `print()` dans Python.

### Format des Logs

Tous les logs utilisent un **préfixe** pour faciliter le filtrage dans Grafana :

```python
print(f"[SENSOR-API] Message ici")  # Pour la Lambda Sensor API
print(f"[RUN-API] Message ici")      # Pour la Lambda Run API
```

### Exemples de Logs Sensor API

#### 1. Requête entrante
```python
print(f"[SENSOR-API] {http_method} {path}")
```
**Affiche :** `[SENSOR-API] POST /sensors/data`

**Utilité :** Voir quelles routes sont appelées

---

#### 2. Ingestion de données
```python
print(f"[SENSOR-API] Ingesting data: sensor={sensor_id}, type={sensor_type}, reading={reading}, user={user}, runId={run_id}")
```
**Affiche :** `[SENSOR-API] Ingesting data: sensor=sensor-001, type=temperature, reading=22.5, user=john, runId=run-abc123`

**Utilité :** 
- Voir **quelle donnée** est en train d'être ingérée
- Tracer le **lien** entre sensor, user et run
- Débugger si des valeurs sont incorrectes

---

#### 3. Succès de sauvegarde
```python
print(f"[SENSOR-API] Data saved successfully: {sensor_id} at {timestamp}")
```
**Affiche :** `[SENSOR-API] Data saved successfully: sensor-001 at 2025-01-16T14:30:00Z`

**Utilité :** Confirmer que la donnée est bien dans DynamoDB

---

#### 4. Récupération de données
```python
print(f"[SENSOR-API] Retrieved {len(items)} sensor data records")
```
**Affiche :** `[SENSOR-API] Retrieved 150 sensor data records`

**Utilité :** Voir combien d'enregistrements sont retournés

---

#### 5. Validation échouée
```python
print(f"[SENSOR-API] Validation failed: missing fields")
```
**Affiche :** `[SENSOR-API] Validation failed: missing fields`

**Utilité :** Identifier les requêtes malformées

---

#### 6. Erreurs
```python
print(f"[SENSOR-API] ERROR: {str(e)}")
```
**Affiche :** `[SENSOR-API] ERROR: Table 'xxx' not found`

**Utilité :** Débugger les erreurs

---

### Filtrer les Logs dans Grafana

Dans le panel "Lambda Logs", vous pouvez filtrer :

```
[SENSOR-API]          # Voir uniquement les logs Sensor API
[RUN-API]             # Voir uniquement les logs Run API
ERROR                 # Voir uniquement les erreurs
sensor=sensor-001     # Voir les logs pour un sensor spécifique
user=john             # Voir les logs pour un user spécifique
runId=run-abc123      # Voir les logs pour un run spécifique
```

---

## 📈 2. CloudWatch Metrics (Métriques Custom)

### Concept

Les **métriques** sont des **valeurs numériques** envoyées vers CloudWatch pour créer des graphiques dans Grafana.

### Fonction `publish_metrics()`

Cette fonction envoie 2 types de métriques :

#### Métrique 1 : `SensorReading` (Valeur du capteur)

```python
{
    'MetricName': 'SensorReading',
    'Value': float(reading),          # Ex: 22.5
    'Unit': 'None',
    'Timestamp': datetime.utcnow(),
    'Dimensions': [
        {'Name': 'SensorId', 'Value': sensor_id},      # Ex: sensor-001
        {'Name': 'User', 'Value': user},               # Ex: john
        {'Name': 'RunId', 'Value': run_id},            # Ex: run-abc123
        {'Name': 'Type', 'Value': sensor_type}         # Ex: temperature
    ]
}
```

**Namespace :** `IoTPlayground/Sensors`

**Utilité :**
- Voir l'**évolution des valeurs** des capteurs dans le temps
- Comparer les valeurs entre différents capteurs
- Filtrer par user, run ou type de capteur

**Exemple dans Grafana :**
- Graphique : Température moyenne par sensor
- Graphique : Température min/max par user
- Graphique : Température par run

---

#### Métrique 2 : `DataIngested` (Compteur d'ingestion)

```python
{
    'MetricName': 'DataIngested',
    'Value': 1,                        # Incrémente de 1 à chaque appel
    'Unit': 'Count',
    'Timestamp': datetime.utcnow(),
    'Dimensions': [
        {'Name': 'SensorId', 'Value': sensor_id},
        {'Name': 'User', 'Value': user},
        {'Name': 'RunId', 'Value': run_id}
    ]
}
```

**Utilité :**
- Compter le **nombre de données ingérées** par sensor
- Compter le nombre de données par user
- Compter le nombre de données par run

**Exemple dans Grafana :**
- Graphique : Nombre de données ingérées par sensor (sum)
- Graphique : Nombre de données par user (sum)
- Graphique : Taux d'ingestion (données/minute)

---

### Dimensions Expliquées

Les **dimensions** sont comme des **tags** qui permettent de **filtrer** et **grouper** les métriques dans Grafana.

#### Exemple Concret

Imaginez ces 3 requêtes :

**Requête 1 :**
```json
{
  "sensorId": "sensor-001",
  "type": "temperature",
  "reading": 22.5,
  "user": "john",
  "runId": "run-abc123"
}
```

**Requête 2 :**
```json
{
  "sensorId": "sensor-002",
  "type": "humidity",
  "reading": 65.0,
  "user": "john",
  "runId": "run-abc123"
}
```

**Requête 3 :**
```json
{
  "sensorId": "sensor-001",
  "type": "temperature",
  "reading": 23.1,
  "user": "jane",
  "runId": "run-xyz789"
}
```

---

### Requêtes Grafana Possibles

#### 1. Voir toutes les températures du sensor-001
```
Namespace: IoTPlayground/Sensors
Metric: SensorReading
Dimensions: 
  - SensorId = sensor-001
  - Type = temperature
```
**Résultat :** 22.5, 23.1

---

#### 2. Voir toutes les données de l'user john
```
Namespace: IoTPlayground/Sensors
Metric: SensorReading
Dimensions: 
  - User = john
```
**Résultat :** 22.5 (temperature), 65.0 (humidity)

---

#### 3. Voir toutes les données du run run-abc123
```
Namespace: IoTPlayground/Sensors
Metric: SensorReading
Dimensions: 
  - RunId = run-abc123
```
**Résultat :** 22.5 (sensor-001), 65.0 (sensor-002)

---

#### 4. Compter le nombre de données ingérées par sensor
```
Namespace: IoTPlayground/Sensors
Metric: DataIngested
Statistic: Sum
Dimensions: 
  - SensorId = sensor-001
```
**Résultat :** 2 (2 données ingérées par sensor-001)

---

## 🔗 3. Relations entre Runs, Sensors et Users

### Architecture des Données

```
User (john)
  └── Run (run-abc123)
        ├── Sensor Data 1 (sensor-001, temperature, 22.5)
        ├── Sensor Data 2 (sensor-002, humidity, 65.0)
        └── Sensor Data 3 (sensor-001, temperature, 23.0)

User (jane)
  └── Run (run-xyz789)
        ├── Sensor Data 4 (sensor-001, temperature, 23.1)
        └── Sensor Data 5 (sensor-003, pressure, 1013.25)
```

### Comment c'est tracé ?

Chaque donnée sensor est **liée** à :
1. **Un sensor** (identifié par `sensorId`)
2. **Un user** (identifié par `user`)
3. **Un run** (identifié par `runId`)

Ces 3 informations sont stockées :
- ✅ Dans **DynamoDB** (pour stockage permanent)
- ✅ Dans les **logs CloudWatch** (pour debugging)
- ✅ Dans les **métriques CloudWatch** (pour graphiques)

---

### Exemple de Traçabilité

**Scénario :** L'utilisateur "john" lance une simulation (run-abc123) avec 2 capteurs.

#### 1. Logs CloudWatch

```
[SENSOR-API] POST /sensors/data
[SENSOR-API] Ingesting data: sensor=sensor-001, type=temperature, reading=22.5, user=john, runId=run-abc123
[SENSOR-API] Data saved successfully: sensor-001 at 2025-01-16T14:30:00Z

[SENSOR-API] POST /sensors/data
[SENSOR-API] Ingesting data: sensor=sensor-002, type=humidity, reading=65.0, user=john, runId=run-abc123
[SENSOR-API] Data saved successfully: sensor-002 at 2025-01-16T14:30:05Z
```

#### 2. Métriques CloudWatch

**Métrique SensorReading :**
```
IoTPlayground/Sensors : SensorReading
  - Dimension: SensorId=sensor-001, User=john, RunId=run-abc123, Type=temperature
    Value: 22.5
  - Dimension: SensorId=sensor-002, User=john, RunId=run-abc123, Type=humidity
    Value: 65.0
```

**Métrique DataIngested :**
```
IoTPlayground/Sensors : DataIngested
  - Dimension: SensorId=sensor-001, User=john, RunId=run-abc123
    Count: 1
  - Dimension: SensorId=sensor-002, User=john, RunId=run-abc123
    Count: 1
```

#### 3. DynamoDB

**Table sensor-data :**
```json
[
  {
    "sensorId": "sensor-001",
    "timestamp": "2025-01-16T14:30:00Z",
    "type": "temperature",
    "reading": 22.5,
    "user": "john",
    "runId": "run-abc123"
  },
  {
    "sensorId": "sensor-002",
    "timestamp": "2025-01-16T14:30:05Z",
    "type": "humidity",
    "reading": 65.0,
    "user": "john",
    "runId": "run-abc123"
  }
]
```

---

## 🎨 4. Visualisation dans Grafana

### Dashboards Possibles

#### Dashboard 1 : Vue par Sensor
```
Panel 1: Température du sensor-001 (ligne)
Panel 2: Humidité du sensor-002 (ligne)
Panel 3: Nombre de données par sensor (bar chart)
```

#### Dashboard 2 : Vue par User
```
Panel 1: Tous les sensors de l'user john (multi-lignes)
Panel 2: Nombre de runs par user (stat)
Panel 3: Logs de l'user john (logs)
```

#### Dashboard 3 : Vue par Run
```
Panel 1: Tous les sensors du run-abc123 (multi-lignes)
Panel 2: Durée du run (stat)
Panel 3: Nombre de données ingérées (stat)
Panel 4: Logs du run (logs)
```

---

## 🔍 5. Requêtes Grafana Utiles

### Logs

#### Voir tous les logs d'un run spécifique
```
Filter: runId=run-abc123
```

#### Voir toutes les erreurs
```
Filter: ERROR
```

#### Voir les données ingérées d'un sensor
```
Filter: [SENSOR-API] Ingesting data: sensor=sensor-001
```

---

### Métriques

#### Température moyenne par sensor
```
Namespace: IoTPlayground/Sensors
Metric: SensorReading
Statistic: Average
Dimensions: Type=temperature
Group by: SensorId
```

#### Nombre total de données ingérées
```
Namespace: IoTPlayground/Sensors
Metric: DataIngested
Statistic: Sum
```

#### Taux d'ingestion (données par minute)
```
Namespace: IoTPlayground/Sensors
Metric: DataIngested
Statistic: Sum
Period: 1 minute
```

---

## 💡 6. Bonnes Pratiques

### ✅ À Faire

1. **Toujours inclure le runId** dans les requêtes pour tracer l'origine
2. **Utiliser des logs structurés** avec des préfixes `[API-NAME]`
3. **Logger les valeurs importantes** (sensor, reading, user, runId)
4. **Utiliser les dimensions CloudWatch** pour filtrer facilement

### ❌ À Éviter

1. **Ne pas logger de données sensibles** (mots de passe, tokens)
2. **Ne pas spammer les logs** (éviter les boucles qui loggent)
3. **Ne pas bloquer l'ingestion** si les métriques échouent (try/except)

---

## 🚀 7. Exemple Complet

### Code
```python
# Requête entrante
print(f"[SENSOR-API] POST /sensors/data")
print(f"[SENSOR-API] Ingesting data: sensor=sensor-001, type=temperature, reading=22.5, user=john, runId=run-abc123")

# Sauvegarde DynamoDB
table.put_item(Item=item)

# Envoi métriques CloudWatch
cloudwatch.put_metric_data(
    Namespace='IoTPlayground/Sensors',
    MetricData=[
        {
            'MetricName': 'SensorReading',
            'Value': 22.5,
            'Dimensions': [
                {'Name': 'SensorId', 'Value': 'sensor-001'},
                {'Name': 'User', 'Value': 'john'},
                {'Name': 'RunId', 'Value': 'run-abc123'},
                {'Name': 'Type', 'Value': 'temperature'}
            ]
        }
    ]
)

# Confirmation
print(f"[SENSOR-API] Data saved successfully: sensor-001 at 2025-01-16T14:30:00Z")
```

### Résultat dans CloudWatch Logs
```
[SENSOR-API] POST /sensors/data
[SENSOR-API] Ingesting data: sensor=sensor-001, type=temperature, reading=22.5, user=john, runId=run-abc123
[SENSOR-API] Data saved successfully: sensor-001 at 2025-01-16T14:30:00Z
```

### Résultat dans CloudWatch Metrics
```
IoTPlayground/Sensors : SensorReading = 22.5
  Dimensions: SensorId=sensor-001, User=john, RunId=run-abc123, Type=temperature
```

### Résultat dans Grafana
- **Panel Logs** : Affiche les 3 lignes de logs
- **Panel Metrics** : Affiche un point sur le graphique (timestamp, 22.5)

---

## 📚 Ressources

- [CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
- [CloudWatch Metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/working_with_metrics.html)
- [Grafana CloudWatch Plugin](https://grafana.com/docs/grafana/latest/datasources/cloudwatch/)

---

**Voilà ! Vous avez maintenant une traçabilité complète entre Users, Runs et Sensors ! 🎉**

