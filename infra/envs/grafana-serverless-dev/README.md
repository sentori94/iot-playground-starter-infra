# 🎯 Grafana Serverless - CloudWatch Monitoring (SIMPLIFIÉ)

## ✅ Architecture Simple

```
Lambda Python → CloudWatch Logs + Metrics → Grafana
```

**Fini Athena ! Fini DynamoDB pour les dashboards !**

## 📊 Ce qui est visualisé

### CloudWatch Metrics (Automatiques)
- **Lambda Invocations** (nombre d'appels)
- **Lambda Errors** (erreurs)
- **Lambda Duration** (temps d'exécution)

### CloudWatch Logs (Automatiques)
- Logs de toutes les Lambdas en temps réel
- Filtrage et recherche

## 🚀 Déploiement

### 1. Builder l'image Grafana

```bash
GitHub Actions → "Build & Push Grafana Serverless Image" → Run
```

**Temps :** 3-4 minutes

### 2. Déployer l'infrastructure

```bash
GitHub Actions → "Deploy Grafana Serverless (ECS)" → Run
MODE: apply
ACTION: full
```

**Temps :** 5-8 minutes

### 3. Accéder à Grafana

URL : `http://<alb-dns-name>.eu-west-3.elb.amazonaws.com`

**Login :**
- Username : `admin`
- Password : (celui dans terraform.tfvars)

### 4. Dashboard disponible

**"IoT Serverless - CloudWatch Monitoring"**

- ✅ Lambda Invocations (Run API & Sensor API)
- ✅ Lambda Errors
- ✅ Lambda Duration
- ✅ Lambda Logs (temps réel)

## 📝 Avantages vs Athena

| Critère | Athena (Ancien) | CloudWatch (Nouveau) |
|---------|-----------------|----------------------|
| Complexité | ⚠️ Élevée | ✅ Simple |
| Configuration | ❌ Tables, Workgroup, S3 | ✅ Aucune |
| Coût | 💰 S3 + Athena queries | 💰 CloudWatch uniquement |
| Temps réel | ⏱️ Non | ✅ Oui |
| Maintenance | ❌ Complexe | ✅ Aucune |

## 🔧 Permissions IAM

Le rôle Grafana a accès à :
- ✅ `cloudwatch:GetMetricData`
- ✅ `cloudwatch:ListMetrics`
- ✅ `logs:DescribeLogGroups`
- ✅ `logs:FilterLogEvents`
- ✅ `logs:StartQuery`

**Pas besoin d'accès à DynamoDB ou Athena !**

## 💡 Pour votre Certif AWS

CloudWatch est **beaucoup plus standard** et **plus simple** qu'Athena pour la monitoring.

**Services AWS utilisés :**
- ✅ Lambda
- ✅ CloudWatch Logs & Metrics
- ✅ ECS Fargate
- ✅ ALB
- ✅ VPC

**Pas besoin de connaître :**
- ❌ Athena (complexe)
- ❌ DynamoDB Connector for Athena
- ❌ Glue Data Catalog

## 📚 Ressources

- [CloudWatch Logs Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html)
- [Grafana CloudWatch Plugin](https://grafana.com/docs/grafana/latest/datasources/cloudwatch/)

---

**Architecture simplifiée et prête pour votre certif AWS ! 🎉**

