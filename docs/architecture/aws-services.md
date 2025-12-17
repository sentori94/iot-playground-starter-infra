# Services AWS utilisés

Cette page résume les principaux services AWS du projet et leur rôle.

## 🧱 Compute & Conteneurs

**ECS Fargate**  
- Sert à exécuter les conteneurs :
  - Application Spring Boot (mode ECS classique)
  - Prometheus
  - Grafana (mode ECS, y compris pour le monitoring serverless)
- Permet de bénéficier de conteneurs managés **sans gérer d’instances EC2**.

**AWS Lambda**  
- Utilisé pour le backend Serverless :
  - `lambda_run_api` : gestion des runs (can-start, start, finish, interrupt-all)
  - `lambda_sensor_api` : ingestion des données capteurs
- Facturation **à l’appel et au temps d’exécution**.

## 🌐 Réseau & Accès

**VPC (Virtual Private Cloud)**  
- Fournit un réseau isolé pour :
  - ECS + RDS (mode ECS)
  - Grafana serverless (VPC dédié)
- Sépare **subnets publics** (ALB, NAT) et **subnets privés** (ECS, RDS, Grafana).

**Subnets publics / privés**  
- **Publics** : ressources exposées (ALB, NAT Gateway).
- **Privés** : ressources sensibles (ECS tasks, RDS, Grafana).

**NAT Gateway**  
- Permet aux ressources en subnets privés (ECS, Grafana) de sortir sur Internet (par exemple pour télécharger des images, plugins, etc.) **sans être exposées directement**.

**Application Load Balancer (ALB)**  
- Point d’entrée HTTP/HTTPS de l’architecture ECS et de Grafana serverless.
- Fait la terminaison TLS (certificat ACM) et distribue le trafic vers les tâches ECS.

**API Gateway**  
- Point d’entrée HTTP/HTTPS pour le backend Serverless.
- Route vers les Lambdas avec intégration REST.
- Gère les aspects CORS, throttling, monitoring côté API.

## 🗄️ Stockage & Bases de données

**RDS PostgreSQL**  
- Base de données relationnelle pour l’architecture ECS.
- Stocke les entités classiques : `runs`, `sensor_data`, etc.

**DynamoDB**  
- Base NoSQL pour l’architecture Serverless.
- Deux tables principales :
  - `Runs` : métadonnées des simulations
  - `SensorData` : mesures des capteurs
- Mode on-demand (pay-per-request), parfaitement adapté à Lambda.

**S3**  
- Utilisé pour stocker l’**état Terraform** (remote backend).
- Permet d’avoir un historique centralisé des déploiements infra.

## 🔐 DNS, Certificats & IAM

**Route53**  
- Gère le domaine `sentori-studio.com` et les sous-domaines :
  - `app-iot.sentori-studio.com` (frontend)
  - `api-lambda-iot.sentori-studio.com` (API Serverless)
  - `grafana-lambda-iot.sentori-studio.com` (Grafana serverless)

**AWS Certificate Manager (ACM)**  
- Fournit les certificats SSL/TLS pour les sous-domaines du projet.
- Intégré à ALB et API Gateway pour du HTTPS de bout en bout.

**IAM (Identity and Access Management)**  
- Définit les rôles et policies pour :
  - Lambdas (accès DynamoDB, CloudWatch)
  - ECS tasks (accès CloudWatch, ECR)
  - Terraform (droits de création/suppression des ressources)

## 📊 Observabilité

**CloudWatch**  
- Collecte les **logs des Lambdas** et des conteneurs ECS.
- Expose des métriques (invocations, erreurs, latence, capacité DynamoDB…).
- Sert de datasource pour Grafana en mode Serverless.

**Prometheus**  
- Déployé dans le VPC ECS.
- Scrape les métriques Spring Boot (`/actuator/prometheus`).
- Sert de datasource pour Grafana en mode ECS.

**Grafana**  
- Unifié pour les deux architectures :
  - Datasource Prometheus (ECS)
  - Datasource CloudWatch (Serverless)
- Affiche des dashboards centrés sur le métier : Sensor, User, Run.

## 📦 Images & Artefacts

**ECR (Elastic Container Registry)**  
- Stocke les images Docker :
  - Application Spring Boot
  - Grafana (image custom pour le mode serverless)
- Intégré à ECS pour le déploiement des tâches.
