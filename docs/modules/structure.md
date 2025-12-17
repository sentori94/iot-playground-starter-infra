# Vue d'ensemble des modules Terraform

Cette section présente la **structure Terraform** du projet sans entrer dans les détails de syntaxe. L'objectif est de montrer comment l'infrastructure est découpée en briques réutilisables.

En entretien, tu peux t'appuyer sur cette page pour montrer que la partie Terraform est pensée de manière modulaire et maintenable, sans plonger dans le code brut.

## 🧱 Organisation générale

Le répertoire `infra/modules/` contient des modules utilisés par plusieurs environnements :

- Modules « classiques » : réseau, ECS, RDS, ALB, certificats, Grafana ECS…
- Modules « serverless » : DynamoDB, Lambdas, API Gateway, VPC dédié Grafana…

L'idée est de pouvoir :
- Recomposer facilement une **architecture ECS** ou **Serverless**
- Garder une **cohérence** entre les environnements (`dev`, `serverless-dev`, `inframanager-dev`, ...)
- Faire évoluer l’infra en ajoutant un nouvel environnement (ex: `serverless-staging`) en réutilisant les mêmes briques.

## 📂 Arborescence (simplifiée)

```text
infra/
├── envs/
│   ├── dev/                # Environnement ECS classique
│   ├── serverless-dev/     # Environnement Serverless (Lambda)
│   └── inframanager-dev/   # Environnement Infra Manager ECS
└── modules/
    ├── network/            # VPC, subnets, route tables
    ├── ecs/                # Cluster ECS de base
    ├── database/           # RDS PostgreSQL
    ├── alb/                # Application Load Balancer
    ├── acm_certificate/    # Certificats ACM
    ├── grafana_ecs/        # Grafana sur ECS (mode classique + serverless)
    └── serverless/
        ├── dynamodb_tables/
        ├── lambda_run_api/
        ├── lambda_sensor_api/
        ├── api_gateway_lambda_iot/
        └── vpc/            # VPC dédié Grafana serverless
```

## 🎯 Principes de design

- **Séparation des responsabilités** :
  - `network` pour le réseau
  - `ecs` / `database` / `alb` pour le backend ECS
  - `serverless/*` pour la partie Lambda + DynamoDB + API Gateway
  - `grafana_ecs` pour la brique d’observabilité commune

- **Réutilisation** :
  - Les mêmes modules réseau / sécurité servent à ECS et Grafana serverless.
  - Les modules serverless peuvent être branchés sur d'autres environnements futurs.

- **Lisibilité** :
  - Chaque environnement (`dev`, `serverless-dev`, `inframanager-dev`) assemble ces briques de manière déclarative dans son propre `main.tf`.

En un coup d’œil, cette page doit te permettre d’expliquer **comment est structurée l’infra** sans ouvrir un seul fichier `.tf` pendant l’entretien.
