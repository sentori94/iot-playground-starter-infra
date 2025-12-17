# 🚀 Architecture Serverless Unifiée

## 📋 Vue d'ensemble

L'environnement `serverless-dev` est maintenant **unifié** et contient :

### Composants

1. **Lambdas** (toujours actives)
   - DynamoDB Tables (Runs, SensorData)
   - Lambda Run API
   - Lambda Sensor API
   - API Gateway

2. **Grafana** (optionnel - activable/désactivable)
   - VPC Serverless (subnets publics/privés)
   - ECS Cluster
   - Grafana ECS Service + Task
   - Application Load Balancer
   - IAM Role CloudWatch

---

## 🎯 Déploiement

### Via GitHub Actions

**Workflow : Deploy Serverless (Unified)**

#### Options disponibles :

| Component | Description |
|-----------|-------------|
| `lambdas` | Déploie DynamoDB + Lambdas + API Gateway |
| `grafana` | Déploie VPC + ECS + Grafana |
| `full` | Déploie TOUT (Lambdas + Grafana) |

| Action | Description |
|--------|-------------|
| `plan` | Affiche les changements |
| `apply` | Applique les changements |
| `destroy` | Détruit les ressources |

#### Exemples :

**Déployer uniquement les Lambdas :**
```
Component: lambdas
Action: apply
```

**Déployer uniquement Grafana :**
```
Component: grafana
Action: apply
```

**Déployer tout :**
```
Component: full
Action: apply
```

**Détruire Grafana uniquement :**
```
Component: grafana
Action: destroy
```

---

## 🔧 Configuration

### Variables importantes

**`enable_grafana`** (dans `terraform.tfvars`)
- `false` : Grafana non déployé (par défaut)
- `true` : Grafana déployé

**Le GitHub Action met automatiquement `enable_grafana = true` quand vous choisissez `grafana` ou `full`.**

### Terraform Targets

Le GitHub Action utilise des **targets Terraform** pour déployer sélectivement :

- **Lambdas** : `-target=module.dynamodb_tables -target=module.lambda_run_api -target=module.lambda_sensor_api -target=module.api_gateway_lambda_iot`
- **Grafana** : `-target=module.vpc_serverless -target=module.ecs_cluster_serverless -target=module.grafana_serverless ...`
- **Full** : Pas de target (tout est déployé)

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    serverless-dev                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐      ┌──────────────────┐            │
│  │    Lambdas       │      │    Grafana       │            │
│  │   (toujours)     │      │   (optionnel)    │            │
│  ├──────────────────┤      ├──────────────────┤            │
│  │ • DynamoDB       │      │ • VPC Serverless │            │
│  │ • Lambda Run API │      │ • ECS Cluster    │            │
│  │ • Lambda Sensor  │      │ • Grafana Task   │            │
│  │ • API Gateway    │      │ • ALB            │            │
│  └──────────────────┘      └──────────────────┘            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 💡 Avantages de l'architecture unifiée

✅ **1 seul état Terraform** (`serverless-dev/terraform.tfstate`)  
✅ **1 seul backend S3** (`iot-playground-tfstate-serverless`)  
✅ **1 seul GitHub Action** (avec sélection de composants)  
✅ **Variables centralisées** (tout dans `serverless-dev/terraform.tfvars`)  
✅ **Déploiement flexible** (Lambdas seules, Grafana seul, ou Full)  
✅ **Destruction ciblée** (destroy Grafana sans toucher aux Lambdas)  

---

## 🧪 Scénarios d'utilisation

### Scénario 1 : Développement (Lambdas uniquement)
```yaml
Component: lambdas
Action: apply
```
→ Déploie les Lambdas pour tester l'API  
→ Pas de coûts ECS/ALB

### Scénario 2 : Démo complète (Lambdas + Grafana)
```yaml
Component: full
Action: apply
```
→ Déploie tout pour une démo complète  
→ Grafana accessible via ALB

### Scénario 3 : Arrêt de Grafana pour économiser
```yaml
Component: grafana
Action: destroy
```
→ Détruit Grafana, VPC, ECS  
→ Les Lambdas continuent de fonctionner  
→ Économise ~$30-50/mois

### Scénario 4 : Redémarrage de Grafana
```yaml
Component: grafana
Action: apply
```
→ Redéploie Grafana sans toucher aux Lambdas  
→ Grafana reconnecté aux métriques CloudWatch

---

## 🗂️ Structure des fichiers

```
infra/envs/serverless-dev/
├── backend.tf           # Backend S3 + DynamoDB
├── main.tf              # Tous les modules (Lambdas + Grafana)
├── variables.tf         # Toutes les variables
├── terraform.tfvars     # Valeurs (enable_grafana = false par défaut)
├── outputs.tf           # Outputs Lambdas + Grafana
└── providers.tf         # Provider AWS
```

---

## ⚙️ Variables d'environnement

### Lambdas (toujours nécessaires)

```hcl
project                = "iot-playground"
env                    = "serverless-dev"
aws_region             = "eu-west-3"
route53_zone_name      = "sentori-studio.com"
lambda_api_domain_name = "api-lambda-iot.sentori-studio.com"
grafana_url            = "http://localhost:3000"  # Sera mis à jour après déploiement
```

### Grafana (optionnelles - utilisées si `enable_grafana = true`)

```hcl
enable_grafana         = false  # true pour activer Grafana
vpc_cidr               = "10.1.0.0/16"
availability_zones     = ["eu-west-3a", "eu-west-3b"]
grafana_image_uri      = "908518190934.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless"
grafana_image_tag      = "latest"
grafana_admin_password = "ChangeMe123!"
```

---

## 🔄 Migration depuis l'ancienne architecture

### Avant (2 environnements séparés)

- `serverless-dev` : Lambdas + DynamoDB
- `grafana-serverless-dev` : Grafana + VPC + ECS

### Après (1 environnement unifié)

- `serverless-dev` : Tout (Lambdas + Grafana optionnel)

### Étapes de migration

1. ✅ **Détruire l'ancienne infra Grafana**
   ```bash
   cd scripts
   ./destroy-grafana-standalone.ps1
   ```

2. ✅ **Déployer l'architecture unifiée**
   - GitHub Actions → Deploy Serverless (Unified)
   - Component: `full`
   - Action: `apply`

---

## 📖 Outputs

Après un `terraform apply`, vous obtenez :

### Lambdas
```
api_gateway_url              = https://xxxxx.execute-api.eu-west-3.amazonaws.com
lambda_api_custom_domain     = api-lambda-iot.sentori-studio.com
dynamodb_runs_table          = iot-playground-runs-serverless-dev
dynamodb_sensor_data_table   = iot-playground-sensor-data-serverless-dev
lambda_run_api_function_name = iot-playground-run-api-serverless-dev
lambda_sensor_api_function_name = iot-playground-sensor-api-serverless-dev
```

### Grafana (si déployé)
```
grafana_alb_url = grafana-serverless-dev-xxxxx.eu-west-3.elb.amazonaws.com
grafana_url     = http://grafana-serverless-dev-xxxxx.eu-west-3.elb.amazonaws.com
```

---

## 🛡️ Sécurité

- Backend S3 chiffré (AES256)
- Versioning activé sur S3
- DynamoDB Lock pour éviter les conflits
- Grafana admin password dans les variables sensibles
- IAM Roles avec permissions minimales (Least Privilege)

---

## 💰 Coûts estimés

| Composant | Coût mensuel (eu-west-3) |
|-----------|--------------------------|
| **Lambdas** (toujours actifs) | ~$5-10 (usage faible) |
| **DynamoDB** (on-demand) | ~$1-5 (usage faible) |
| **API Gateway** | ~$3-5 |
| **Grafana ECS** (si activé) | ~$30-50 |
| **VPC NAT Gateway** (si activé) | ~$30-35 |
| **ALB** (si activé) | ~$20 |
| **TOTAL (Lambdas seules)** | ~$10-20/mois |
| **TOTAL (Full)** | ~$80-120/mois |

**Recommandation** : Détruire Grafana quand inutilisé pour économiser ~$80-100/mois.

---

## 🎓 Best Practices

1. **Développement** : Déployez uniquement `lambdas`
2. **Démo/Présentation** : Déployez `full`
3. **Après démo** : Destroy `grafana` pour économiser
4. **Production** : Gardez `full` avec `desired_count = 1`
5. **Toujours** : Vérifiez les outputs après `apply`

---

## 📞 Troubleshooting

### Problème : Grafana ne se déploie pas

**Solution** : Vérifiez que `enable_grafana = true` dans `terraform.tfvars`

### Problème : Erreur "Resource already exists"

**Solution** : Utilisez des targets spécifiques :
```bash
terraform destroy -target=module.grafana_serverless
terraform apply -target=module.grafana_serverless
```

### Problème : Backend S3 n'existe pas

**Solution** : Le GitHub Action le crée automatiquement. Sinon :
```bash
aws s3api create-bucket --bucket iot-playground-tfstate-serverless --region eu-west-3 --create-bucket-configuration LocationConstraint=eu-west-3
```

---

## 🔗 Liens utiles

- [Terraform Docs](https://www.terraform.io/docs)
- [AWS Lambda Pricing](https://aws.amazon.com/lambda/pricing/)
- [AWS ECS Pricing](https://aws.amazon.com/ecs/pricing/)
- [Grafana Docs](https://grafana.com/docs/)

---

**🎉 L'architecture serverless est maintenant unifiée et flexible !**

