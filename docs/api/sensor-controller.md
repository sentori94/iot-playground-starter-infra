# API Sensor Controller

Gestion de l'ingestion et récupération des données de capteurs IoT.

## 🎯 Base URL

- **Serverless** : `https://api-lambda-iot.sentori-studio.com`
- **ECS** : `https://api-ecs-iot.sentori-studio.com` (futur)

## 📋 Endpoints

### POST `/api/sensors/data`

Ingère une mesure de capteur dans le système.

**Headers**
```
Content-Type: application/json
X-User: username
X-Run-Id: run-uuid
```

**Body**
```json
{
  "runId": "550e8400-e29b-41d4-a716-446655440000",
  "sensorId": "sensor-001",
  "temperature": 23.5,
  "humidity": 65.2,
  "pressure": 1013.25
}
```

**Response 201**
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "runId": "550e8400-e29b-41d4-a716-446655440000",
  "sensorId": "sensor-001",
  "timestamp": "2025-01-15T10:30:05Z",
  "temperature": 23.5,
  "humidity": 65.2,
  "pressure": 1013.25
}
```

**Response 400** (validation error)
```json
{
  "error": "Invalid sensor data",
  "details": "temperature must be a number"
}
```

**Response 404** (run not found)
```json
{
  "error": "Run not found"
}
```

---

### GET `/api/sensors/data`

Récupère les données de capteurs filtrées.

**Query Parameters**
- `runId` (optional) : UUID du run
- `sensorId` (optional) : ID du capteur
- `startDate` (optional) : Date de début (ISO 8601)
- `endDate` (optional) : Date de fin (ISO 8601)
- `limit` (optional) : Nombre max de résultats (défaut: 100)

**Examples**
```bash
# Toutes les données d'un run
GET /api/sensors/data?runId=550e8400-e29b-41d4-a716-446655440000

# Données d'un capteur spécifique
GET /api/sensors/data?sensorId=sensor-001

# Données dans une période
GET /api/sensors/data?startDate=2025-01-15T10:00:00Z&endDate=2025-01-15T11:00:00Z
```

**Response 200**
```json
[
  {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "runId": "550e8400-e29b-41d4-a716-446655440000",
    "sensorId": "sensor-001",
    "timestamp": "2025-01-15T10:30:05Z",
    "temperature": 23.5,
    "humidity": 65.2,
    "pressure": 1013.25
  },
  {
    "id": "660e8400-e29b-41d4-a716-446655440002",
    "runId": "550e8400-e29b-41d4-a716-446655440000",
    "sensorId": "sensor-001",
    "timestamp": "2025-01-15T10:30:10Z",
    "temperature": 23.7,
    "humidity": 65.0,
    "pressure": 1013.20
  }
]
```

---

## 📊 Format des Données

### Capteur Simple (Température uniquement)
```json
{
  "runId": "...",
  "sensorId": "temp-sensor-01",
  "temperature": 23.5
}
```

### Capteur Complet (Température, Humidité, Pression)
```json
{
  "runId": "...",
  "sensorId": "multi-sensor-01",
  "temperature": 23.5,
  "humidity": 65.2,
  "pressure": 1013.25
}
```

## 🔄 Flux d'Ingestion Typique

1. Frontend démarre une simulation via `POST /api/runs/start`
2. Récupère le `runId` dans la réponse
3. Toutes les N secondes (interval configuré) :
   - Génère des données de capteur (température aléatoire)
   - Envoie via `POST /api/sensors/data` avec le `runId`
4. Continue jusqu'à la fin de la durée configurée
5. Termine la simulation via `POST /api/runs/{id}/finish`

## 🔐 Authentification

Les headers suivants sont requis :
- `X-User` : Identifiant de l'utilisateur (string)
- `X-Run-Id` : UUID du run associé (optionnel sur GET)

## 🚨 Codes d'Erreur

| Code | Description |
|------|-------------|
| 201 | Created |
| 200 | Success (GET) |
| 400 | Bad Request (validation) |
| 404 | Run not found |
| 405 | Method not allowed |
| 500 | Internal server error |

## 💡 Exemples

### Exemple complet avec cURL

```bash
# 1. Démarrer un run
RUN_ID=$(curl -X POST https://api-lambda-iot.sentori-studio.com/api/runs/start \
  -H "Content-Type: application/json" \
  -H "X-User: demo-user" \
  -d '{"duration": 60, "interval": 5}' | jq -r '.id')

# 2. Ingérer des données
curl -X POST https://api-lambda-iot.sentori-studio.com/api/sensors/data \
  -H "Content-Type: application/json" \
  -H "X-User: demo-user" \
  -H "X-Run-Id: $RUN_ID" \
  -d "{
    \"runId\": \"$RUN_ID\",
    \"sensorId\": \"temp-sensor-01\",
    \"temperature\": 23.5
  }"

# 3. Récupérer les données
curl "https://api-lambda-iot.sentori-studio.com/api/sensors/data?runId=$RUN_ID"
```

## 🔗 Liens

- [Run Controller API](run-controller.md)
- [Guide Simulations](../guide/simulations.md)

