# Vue d'ensemble Architecture

## 🎯 Deux Modes de Déploiement

```mermaid
graph LR
    A[Frontend Angular] --> B{Mode ?}
    B -->|ECS| C[Spring Boot<br/>ECS Fargate]
    B -->|Serverless| D[Lambda<br/>API Gateway]
    
    C --> E[RDS PostgreSQL]
    D --> F[DynamoDB]
    
    C --> G[Prometheus]
    D --> H[CloudWatch]
    
    G --> I[Grafana ECS]
    H --> J[Grafana ECS]
    
    style C fill:#fff3e0
    style D fill:#e8f5e9
```

## 🏗️ Infrastructure Complète

```mermaid
graph TB
    subgraph "DNS & CDN"
        DNS[Route53<br/>sentori-studio.com]
        CERT[ACM Certificates<br/>*.sentori-studio.com]
    end
    
    subgraph "Mode ECS (dev)"
        ECS[ECS Cluster]
        ALB_ECS[Application Load Balancer]
        RDS[(RDS PostgreSQL)]
        PROM[Prometheus]
        GRAF_ECS[Grafana]
    end
    
    subgraph "Mode Serverless (serverless-dev)"
        APIGW[API Gateway]
        LAMBDA_RUN[Lambda Run API]
        LAMBDA_SENSOR[Lambda Sensor API]
        DYNAMO[(DynamoDB)]
        CW[CloudWatch Logs]
        GRAF_SLSS[Grafana]
    end
    
    subgraph "Infrastructure Partagée"
        VPC[VPC]
        S3[S3 Terraform State]
        LOCK[DynamoDB Lock Table]
    end
    
    DNS --> CERT
    DNS --> ALB_ECS
    DNS --> APIGW
    DNS --> GRAF_SLSS
    
    CERT --> ALB_ECS
    CERT --> APIGW
    CERT --> GRAF_SLSS
    
    ALB_ECS --> ECS
    ECS --> RDS
    ECS --> PROM
    PROM --> GRAF_ECS
    
    APIGW --> LAMBDA_RUN
    APIGW --> LAMBDA_SENSOR
    LAMBDA_RUN --> DYNAMO
    LAMBDA_SENSOR --> DYNAMO
    LAMBDA_RUN --> CW
    LAMBDA_SENSOR --> CW
    CW --> GRAF_SLSS
    
    VPC -.-> ECS
    VPC -.-> RDS
    VPC -.-> GRAF_ECS
    VPC -.-> GRAF_SLSS
    
    style ECS fill:#fff3e0
    style LAMBDA_RUN fill:#e8f5e9
    style LAMBDA_SENSOR fill:#e8f5e9
```

## 📊 Flux de Données

### Mode ECS

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant F as Frontend
    participant ALB as ALB
    participant API as Spring Boot
    participant DB as PostgreSQL
    participant P as Prometheus
    participant G as Grafana
    
    U->>F: Démarrer simulation
    F->>ALB: POST /api/runs/start
    ALB->>API: Forward
    API->>DB: INSERT run
    API->>DB: INSERT sensor_data
    API-->>F: Run créé
    
    loop Monitoring
        P->>API: Scrape /actuator/prometheus
        U->>G: Consulter dashboard
        G->>P: Query metrics
        G-->>U: Afficher graphiques
    end
```

### Mode Serverless

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant F as Frontend
    participant AG as API Gateway
    participant LR as Lambda Run
    participant LS as Lambda Sensor
    participant DB as DynamoDB
    participant CW as CloudWatch
    participant G as Grafana
    
    U->>F: Démarrer simulation
    F->>AG: POST /api/runs/start
    AG->>LR: Invoke
    LR->>DB: PutItem (Run)
    LR->>CW: Log metrics
    LR-->>F: Run créé
    
    F->>AG: POST /api/sensors/data
    AG->>LS: Invoke
    LS->>DB: PutItem (SensorData)
    LS->>CW: Log metrics
    
    loop Monitoring
        U->>G: Consulter dashboard
        G->>CW: Query logs
        G-->>U: Afficher graphiques
    end
```

## 🔐 Sécurité

```mermaid
graph TB
    subgraph "Authentification & Autorisation"
        A[Headers HTTP]
        B[X-User Header]
        C[API Key Future]
    end
    
    subgraph "Réseau"
        D[VPC]
        E[Security Groups]
        F[Private Subnets]
        G[Public Subnets]
    end
    
    subgraph "Certificats"
        H[ACM Wildcard]
        I[HTTPS Only]
    end
    
    A --> B
    A --> C
    
    D --> E
    D --> F
    D --> G
    
    F --> RDS[(RDS)]
    F --> ECS[ECS Tasks]
    G --> ALB[Load Balancer]
    
    H --> I
    I --> ALB
    I --> AG[API Gateway]
    
    style D fill:#e3f2fd
    style H fill:#fff9c4
```

## 🎛️ Environnements

| Environnement | Architecture | Objectif |
|---------------|-------------|----------|
| **dev** | ECS + RDS | Architecture classique, toujours actif |
| **serverless-dev** | Lambda + DynamoDB | Architecture serverless, pay-per-use |
| **cdn-dev** | CloudFront + S3 | Hébergement frontend (futur) |

## 🔄 Cycle de Vie

```mermaid
stateDiagram-v2
    [*] --> Provisioning: terraform apply
    
    Provisioning --> Running: Déploiement réussi
    Provisioning --> Failed: Erreur
    
    Running --> Updating: Changement config
    Updating --> Running: Mise à jour OK
    
    Running --> Scaling: Charge augmente
    Scaling --> Running: Auto-scaling
    
    Running --> Destroying: terraform destroy
    Destroying --> [*]: Ressources supprimées
    
    Failed --> Provisioning: Correction + Retry
```

