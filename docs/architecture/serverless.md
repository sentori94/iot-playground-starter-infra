# Architecture Serverless

## 🎯 Vue d'ensemble

```mermaid
graph TB
    subgraph "API Gateway"
        AG[API Gateway<br/>api-lambda-iot.sentori-studio.com]
    end
    
    subgraph "Lambda Functions"
        LR[Lambda Run API<br/>Python 3.11]
        LS[Lambda Sensor API<br/>Python 3.11]
    end
    
    subgraph "Stockage"
        DR[(DynamoDB Runs)]
        DS[(DynamoDB SensorData)]
    end
    
    subgraph "Monitoring"
        CW[CloudWatch Logs]
        GRAF[Grafana ECS<br/>grafana-lambda-iot.sentori-studio.com]
    end
    
    subgraph "Réseau"
        VPC[VPC 10.1.0.0/16]
        PUB[Public Subnets]
        PRIV[Private Subnets]
        ALB[ALB Grafana]
    end
    
    AG -->|invoke| LR
    AG -->|invoke| LS
    
    LR --> DR
    LS --> DS
    
    LR -.log.-> CW
    LS -.log.-> CW
    
    CW --> GRAF
    
    GRAF --> ALB
    ALB --> PUB
    PRIV --> GRAF
    VPC --> PUB
    VPC --> PRIV
    
    style LR fill:#e8f5e9
    style LS fill:#e8f5e9
    style AG fill:#e1f5ff
    style GRAF fill:#fff3e0
```

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

```mermaid
sequenceDiagram
    participant F as Frontend
    participant AG as API Gateway
    participant LR as Lambda Run
    participant DR as DynamoDB Runs
    participant CW as CloudWatch
    
    F->>AG: POST /api/runs/start<br/>{duration: 60, interval: 5}
    AG->>LR: Invoke
    
    LR->>LR: Check can-start<br/>(max 5 concurrent)
    
    alt Limite atteinte
        LR-->>F: 400 Bad Request<br/>Max concurrent reached
    else OK
        LR->>LR: Generate UUID
        LR->>DR: PutItem<br/>{id, status: RUNNING, ...}
        LR->>CW: PutMetricData<br/>run_started=1
        LR-->>F: 201 Created<br/>{id, grafanaUrl, ...}
    end
```

### Ingérer des Données Capteur

```mermaid
sequenceDiagram
    participant F as Frontend
    participant AG as API Gateway
    participant LS as Lambda Sensor
    participant DS as DynamoDB SensorData
    participant CW as CloudWatch
    
    loop Toutes les 5 secondes
        F->>AG: POST /api/sensors/data<br/>{runId, sensorId, temperature}
        AG->>LS: Invoke
        LS->>LS: Validate data
        LS->>DS: PutItem<br/>{id, timestamp, ...}
        LS->>CW: PutMetricData<br/>temperature=XX
        LS-->>F: 201 Created
    end
```

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

```mermaid
graph LR
    subgraph "Lambda Metrics"
        A[Invocations]
        B[Duration]
        C[Errors]
        D[Throttles]
    end
    
    subgraph "Custom Metrics"
        E[run_started]
        F[run_completed]
        G[sensor_data_ingested]
        H[temperature_avg]
    end
    
    subgraph "DynamoDB Metrics"
        I[ConsumedReadCapacity]
        J[ConsumedWriteCapacity]
    end
    
    A --> GRAF[Grafana Dashboard]
    B --> GRAF
    C --> GRAF
    E --> GRAF
    F --> GRAF
    G --> GRAF
    H --> GRAF
    I --> GRAF
    J --> GRAF
    
    style GRAF fill:#fff3e0
```

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

```mermaid
graph TB
    subgraph "API Gateway"
        A[HTTPS Only]
        B[Custom Domain]
        C[ACM Certificate]
    end
    
    subgraph "Lambda"
        D[IAM Execution Role]
        E[VPC Endpoints Future]
        F[Environment Variables]
    end
    
    subgraph "DynamoDB"
        G[Encryption at Rest]
        H[IAM Permissions]
    end
    
    A --> B
    B --> C
    D --> H
    F -.contains.-> CREDS[Secrets]
    
    style A fill:#fff9c4
    style D fill:#fff9c4
    style G fill:#fff9c4
```

## 🚀 Déploiement

```mermaid
graph LR
    A[Git Push] --> B[GitHub Actions]
    B --> C{Component}
    
    C -->|lambdas| D[Deploy Lambdas]
    C -->|grafana| E[Deploy Grafana]
    C -->|full| F[Deploy All]
    
    D --> G[Terraform Apply<br/>-target=lambdas]
    E --> H[Terraform Apply<br/>-target=grafana]
    F --> I[Terraform Apply<br/>no target]
    
    G --> J[Lambda + DynamoDB + API Gateway]
    H --> K[VPC + ECS + Grafana]
    I --> L[Tout créé]
    
    style B fill:#e8f5e9
```

