# 🚀 IoT Playground - Infrastructure as Code

Infrastructure Terraform pour IoT Playground avec **2 architectures disponibles** : ECS classique et Serverless Lambda.

## 🏗️ Architectures Disponibles

### ⚡ Architecture Serverless (Lambda + DynamoDB)
**Mode d'exécution : Serverless**
- **Lambda Python 3.11** : Run API + Sensor API
- **DynamoDB** : Tables Runs & SensorData (pay-per-request)
- **API Gateway** : REST API avec custom domain
- **CloudWatch Metrics** : Métriques pour Grafana
- **Route53** : DNS `api-lambda-iot.sentori-studio.com`
- **Coût** : ~$3/mois pour 10k req/jour

📚 [Documentation Serverless](./infra/modules/README-LAMBDA-SERVERLESS.md)  
📂 [Configuration](./infra/envs/serverless-dev/)

### 🐳 Architecture ECS (Fargate + RDS)
**Mode d'exécution : Conteneurs**
- **VPC + Subnets** : Réseau isolé
- **ECS Fargate** : Spring Boot application
- **RDS PostgreSQL** : Base de données relationnelle
- **ALB** : Load balancing
- **Prometheus + Grafana** : Monitoring
- **ECR** : Container registry
- **Coût** : ~$60/mois

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
│   ├── serverless/             # 🆕 Modules Serverless
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
├── deploy-lambdas.yml          # Déploiement Serverless
└── bootstrap.yml               # Déploiement ECS
```

## ⚡ Quick Start

### Option 1 : Architecture Serverless (Lambda + DynamoDB)

```bash
cd infra/envs/serverless-dev
terraform init
terraform plan
terraform apply
```

**Endpoints déployés :**
- `https://api-lambda-iot.sentori-studio.com/api/runs`
- `https://api-lambda-iot.sentori-studio.com/sensors/data`

### Option 2 : Architecture ECS (Fargate + RDS)

```bash
cd infra/envs/dev
terraform init
terraform plan
terraform apply
```

**Endpoints déployés :**
- `https://api-iot.sentori-studio.com/api/runs`
- `https://api-iot.sentori-studio.com/sensors/data`

## 🔐 Secrets GitHub Requis

Dans **Settings > Secrets and variables > Actions** :
- `AWS_ACCESS_KEY_ID` : Clé d'accès AWS
- `AWS_SECRET_ACCESS_KEY` : Clé secrète AWS

## 🌐 Domaines Configurés

| Service | Domaine | Architecture |
|---------|---------|--------------|
| **Lambda API** | `api-lambda-iot.sentori-studio.com` | Serverless |
| **Backend Spring** | `api-iot.sentori-studio.com` | ECS |
| Grafana | `grafana-iot.sentori-studio.com` | ECS / Serverless |
| Prometheus | `prometheus-iot.sentori-studio.com` | ECS |
| Reports API | `api-reports-iot.sentori-studio.com` | Serverless |

## 📊 Endpoints Lambda API

### Run API
```bash
# Liste paginée
GET /api/runs?limit=20&lastKey=xxx

# Par ID
GET /api/runs/{uuid}

# Tous les runs
GET /api/runs/all
```

### Sensor API
```bash
# Ingestion
POST /sensors/data
Headers: X-User, X-Run-Id
Body: {"sensorId":"sensor-001","type":"temperature","reading":23.5}

# Liste
GET /sensors/data?sensorId=xxx&runId=yyy&limit=100
```

## 💰 Comparaison de Coûts (10k req/jour)

| Composant | Architecture Serverless | Architecture ECS |
|-----------|------------------------|------------------|
| Compute | Lambda: ~$0.50/mois | ECS Fargate: ~$30/mois |
| Database | DynamoDB: ~$1/mois | RDS: ~$15/mois |
| Network | API Gateway: ~$1/mois | ALB: ~$16/mois |
| Monitoring | CloudWatch: ~$0.50/mois | Prometheus: inclus |
| **TOTAL** | **~$3/mois** 🎉 | **~$60/mois** |

**Différence :** La solution Serverless coûte **95% moins cher** pour les petits volumes.  
**À noter :** Les coûts ECS sont plus prévisibles, tandis que Serverless est pay-per-use.

## 🚀 Déploiement via GitHub Actions

### Workflow Lambda (Automatique)
```yaml
# .github/workflows/deploy-lambdas.yml
# Se déclenche sur push dans main avec changements Lambda
```

**Déclencher manuellement:**
1. Aller dans **Actions** > **Deploy Lambda APIs**
2. Cliquer sur **Run workflow**
3. Sélectionner la branche `main`

## 📚 Documentation

- [Architecture Lambda Serverless](./infra/modules/README-LAMBDA-SERVERLESS.md)
- [Guide de Migration](./MIGRATION-GUIDE.md)
- [Documentation Modules](./infra/README-MODULES.md)

## 🛠️ Commandes Utiles

### Terraform
```bash
# Voir le plan
terraform plan

# Appliquer les changements
terraform apply

# Détruire les ressources
terraform destroy

# Voir les outputs
terraform output
```

### Logs Lambda
```bash
# Suivre les logs en temps réel
aws logs tail /aws/lambda/iot-playground-run-api-dev --follow
aws logs tail /aws/lambda/iot-playground-sensor-api-dev --follow
```

### Métriques CloudWatch
```bash
# Voir les invocations Lambda
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=iot-playground-sensor-api-dev \
  --start-time $(date -u -d "1 hour ago" +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## 🤝 Contributing

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changes (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📞 Support

Pour toute question ou problème :
- 📖 Consulter la [documentation](./infra/modules/README-LAMBDA-SERVERLESS.md)
- 🐛 Ouvrir une issue sur GitHub
- 📧 Contacter l'équipe Sentori Studio

---

**Version:** 2.0.0 (Serverless)  
**Dernière mise à jour:** Décembre 2025  
**Auteur:** Sentori Studio
