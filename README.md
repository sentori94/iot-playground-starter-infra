# 🚀 IoT Playground - Infrastructure as Code

Infrastructure Terraform pour IoT Playground avec **2 architectures disponibles** : ECS classique et Serverless Lambda.

Ce projet met en place toute l’infrastructure backend d’un **simulateur IoT** :
- une application web permet de lancer des **simulations de capteurs** (runs),
- des mesures (par exemple des températures) sont générées et envoyées vers le backend,
- les données sont stockées et visualisées en temps réel dans **Grafana**, avec des filtres par utilisateur, run et capteur.

L’originalité du projet est d’exposer **la même API fonctionnelle** via deux stacks différentes :
- une version **ECS + RDS PostgreSQL**,
- une version **Serverless Lambda + DynamoDB**,
ce qui permet de comparer concrètement les deux architectures.

## 📚 Documentation

Documentation complète disponible en ligne :

**🌐 [https://sentori94.github.io/iot-playground-starter-infra/](https://sentori94.github.io/iot-playground-starter-infra/)**

## 🏗️ Architectures Disponibles

### ⚡ Architecture Serverless (Lambda + DynamoDB)
**Mode d'exécution : Serverless**
- **Lambda Python 3.11** : Run API + Sensor API
- **DynamoDB** : Tables Runs & SensorData (pay-per-request)
- **API Gateway** : REST API avec custom domain
- **CloudWatch Metrics** : Métriques pour Grafana
- **Route53** : DNS `api-lambda-iot.sentori-studio.com`

📂 [Configuration](./infra/envs/serverless-dev/)

### 🐳 Architecture ECS (Fargate + RDS)
**Mode d'exécution : Conteneurs**
- **VPC + Subnets** : Réseau isolé
- **ECS Fargate** : Spring Boot application
- **RDS PostgreSQL** : Base de données relationnelle
- **ALB** : Load balancing
- **Prometheus + Grafana** : Monitoring
- **ECR** : Container registry

📂 [Configuration](./infra/envs/dev/)

> 💡 **Choix de l'architecture** : L'utilisateur pourra choisir entre les deux modes depuis le frontend (onglet Serverless vs ECS classique).

## 📁 Structure du Projet

```
infra/
├── envs/
│   ├── dev/                    # Architecture ECS (Fargate + RDS)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   └── serverless-dev/         # Architecture Serverless (Lambda + DynamoDB)
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── outputs.tf
├── modules/
│   ├── serverless/             # Modules Serverless
│   │   ├── dynamodb_tables/    # Tables DynamoDB
│   │   ├── lambda_run_api/     # Lambda Run API
│   │   ├── lambda_sensor_api/  # Lambda Sensor API
│   │   └── api_gateway_lambda_iot/ # API Gateway
│   ├── network/                # VPC, subnets (ECS)
│   ├── database/               # RDS PostgreSQL (ECS)
│   ├── ecs/                    # ECS Cluster
│   ├── alb/                    # Application Load Balancer
│   └── route53/                # DNS management
└── templates/                  # Configuration templates

.github/workflows/
├── deploy-serverless-unified.yml   # Déploiement Serverless (unifié)
├── destroy-serverless.yml          # Destruction contrôlée de l’infra serverless
├── deploy-infra-manager.yml        # Infra Manager pour ECS
└── deploy-docs.yml                 # Publication de la documentation
```

## 🌐 Domaines Configurés

| Service | Domaine | Architecture |
|---------|---------|--------------|
| Frontend | `app-iot.sentori-studio.com` | Front |
| Lambda API | `api-lambda-iot.sentori-studio.com` | Serverless |
| Backend Spring | `api-iot.sentori-studio.com` | ECS |
| Grafana Serverless | `grafana-lambda-iot.sentori-studio.com` | Observabilité |

## 📚 Ressources Complémentaires

- Documentation détaillée d’architecture et de déploiement : voir le site MkDocs ci-dessus.
- Détails des modules Terraform : `infra/README-MODULES.md`.
