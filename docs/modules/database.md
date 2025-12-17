# Modules Base de données (RDS & DynamoDB)

Cette partie couvre les deux approches de stockage :
- **RDS PostgreSQL** pour l’architecture ECS
- **DynamoDB** pour l’architecture Serverless

## 🐘 RDS PostgreSQL (module `database`)

- Crée une instance RDS dans des subnets privés
- Géré via le module `infra/modules/database`
- Utilisé par :
  - Environnement `dev` (Spring Boot)

**Rôle** : stocker les runs et les données capteurs dans un modèle relationnel classique.

## 🧾 DynamoDB (module `serverless/dynamodb_tables`)

- Crée deux tables principales :
  - `Runs` : métadonnées des simulations
  - `SensorData` : données de capteurs
- Mode on-demand (pay-per-request)
- Utilisé par :
  - Environnement `serverless-dev`

**Rôle** : fournir un stockage scalable, sans gestion de serveur, parfaitement adapté aux Lambdas.

## 🔍 Angle à présenter en entretien

- Tu as **volontairement mis en regard** deux types de stockage : relationnel vs NoSQL.
- La logique métier reste la même (Runs + SensorData), seul le **modèle de données** change.
- C’est un excellent support pour discuter de :
  - transactions vs scalabilité
  - schéma fixé vs flexible
  - coûts et patterns d’accès.
