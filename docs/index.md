# IoT Playground Infrastructure

!!! info "Projet"
    Infrastructure as Code pour une plateforme IoT de simulation de capteurs avec deux architectures déployables : **ECS (Classic)** et **Serverless (Lambda)**.

## 🎯 Objectif

Comparer deux architectures AWS pour une application IoT :

- **ECS + RDS PostgreSQL** (architecture traditionnelle)
- **Lambda + DynamoDB** (architecture serverless)

## 🏗️ Architecture Globale

```mermaid
graph TB
    subgraph "Frontend Angular"
        A[Application Web]
    end
    
    subgraph "Architecture ECS"
        B[Spring Boot<br/>ECS Fargate]
        C[RDS PostgreSQL]
        D[Prometheus]
        E[Grafana ECS]
    end
    
    subgraph "Architecture Serverless"
        F[Lambda Run API]
        G[Lambda Sensor API]
        H[DynamoDB]
        I[CloudWatch Logs]
        J[Grafana ECS]
    end
    
    A -->|REST API| B
    A -->|REST API| F
    A -->|REST API| G
    
    B --> C
    B --> D
    D --> E
    
    F --> H
    G --> H
    F --> I
    G --> I
    I --> J
    
    style A fill:#e1f5ff
    style B fill:#fff3e0
    style F fill:#e8f5e9
    style G fill:#e8f5e9
```

## 📊 Comparaison Rapide

| Critère | ECS Classic | Serverless |
|---------|-------------|------------|
| **Coût (idle)** | ~$80/mois | ~$0/mois |
| **Coût (actif)** | ~$80/mois | Variable |
| **Scalabilité** | Manuelle | Automatique |
| **Cold Start** | Non | Oui (~1s) |
| **Base de données** | PostgreSQL | DynamoDB |
| **Monitoring** | Prometheus | CloudWatch |

## 🚀 Démarrage Rapide

=== "Serverless"

    ```bash
    # 1. Déployer les lambdas
    GitHub Actions → Deploy Serverless (Unified)
    Component: lambdas
    Action: apply
    
    # 2. Déployer Grafana (optionnel)
    Component: grafana
    Action: apply
    ```

=== "ECS"

    ```bash
    # Déployer l'infrastructure complète
    cd infra/envs/dev
    terraform init
    terraform apply
    ```

## 🌐 URLs

- **API Lambda** : `https://api-lambda-iot.sentori-studio.com`
- **Grafana Serverless** : `https://grafana-lambda-iot.sentori-studio.com`
- **Frontend** : À définir

## 📁 Structure du Projet

```
iot-playground-starter-infra/
├── infra/
│   ├── envs/
│   │   ├── dev/              # Infrastructure ECS
│   │   ├── serverless-dev/   # Infrastructure Serverless
│   │   └── cdn-dev/          # CDN pour le frontend
│   ├── modules/              # Modules Terraform réutilisables
│   └── docker/               # Images Docker (Grafana, Prometheus)
├── scripts/                  # Scripts utilitaires
└── .github/workflows/        # CI/CD GitHub Actions
```

## 🔗 Liens Utiles

- [Architecture ECS](architecture/ecs.md)
- [Architecture Serverless](architecture/serverless.md)
- [Guide de déploiement](deployment/quickstart.md)
- [API Reference](api/run-controller.md)

