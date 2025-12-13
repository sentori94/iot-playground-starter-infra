# 🚀 Quick Start - Déploiement Lambda Serverless

## ⚡ En 5 Minutes

### 1️⃣ Vérifier les Prérequis
```bash
# AWS CLI configuré ?
aws sts get-caller-identity

# Terraform installé ?
terraform version

# Python installé (pour tests) ?
python --version
```

### 2️⃣ Déployer l'Infrastructure
```bash
cd infra/envs/serverless-dev

# Initialiser Terraform
terraform init

# Voir ce qui va être créé
terraform plan

# Déployer !
terraform apply
# Tapez 'yes' quand demandé
```

**Temps estimé:** 3-5 minutes ⏱️

### 3️⃣ Récupérer les URLs
```bash
# API Gateway URL
terraform output api_gateway_url

# Custom Domain (si configuré)
terraform output lambda_api_custom_domain
```

### 4️⃣ Tester les APIs depuis le Frontend
Votre application frontend dispose d'un onglet pour tester l'ingestion de données capteurs.

### 5️⃣ Voir les Métriques dans CloudWatch
1. Ouvrir AWS Console: https://console.aws.amazon.com/cloudwatch/
2. Région: **eu-west-3**
3. Metrics → All metrics → **IoTPlayground/Sensors**
4. Voir les métriques `SensorReading` et `DataIngested`

---

## 🎯 Test Rapide avec cURL

```bash
# Remplacer par votre URL
API_URL="https://api-lambda-iot.sentori-studio.com"

# 1. Ingérer une donnée capteur
curl -X POST "$API_URL/sensors/data" \
  -H "Content-Type: application/json" \
  -H "X-User: testuser" \
  -H "X-Run-Id: quick-start-001" \
  -d '{
    "sensorId": "sensor-001",
    "type": "temperature",
    "reading": 23.5
  }'

# 2. Récupérer les données
curl "$API_URL/sensors/data?limit=10"

# 3. Récupérer tous les runs
curl "$API_URL/api/runs/all"
```

---

## 🔍 Vérifier que Tout Fonctionne

### ✅ DynamoDB Tables Créées
```bash
aws dynamodb list-tables --region eu-west-3 | grep iot-playground
```

Vous devriez voir:
- `iot-playground-runs-dev`
- `iot-playground-sensor-data-dev`

### ✅ Lambdas Déployées
```bash
aws lambda list-functions --region eu-west-3 | grep iot-playground
```

Vous devriez voir:
- `iot-playground-run-api-dev`
- `iot-playground-sensor-api-dev`

### ✅ API Gateway Créé
```bash
aws apigateway get-rest-apis --region eu-west-3 | grep iot-playground
```

---

## 🐛 Dépannage Rapide

### Problème: Terraform init échoue
```bash
# Vérifier les credentials AWS
aws sts get-caller-identity

# Si erreur, reconfigurer
aws configure
```

### Problème: API Gateway retourne 403
```bash
# Vérifier que le certificat ACM est validé
aws acm list-certificates --region eu-west-3

# Attendre validation DNS (peut prendre 5-10 min)
```

### Problème: Lambda retourne erreur 500
```bash
# Voir les logs
aws logs tail /aws/lambda/iot-playground-sensor-api-dev --follow

# Vérifier les permissions IAM
aws lambda get-function --function-name iot-playground-sensor-api-dev
```

### Problème: Pas de métriques dans CloudWatch
```bash
# Attendre 1-2 minutes après ingestion
# Vérifier le namespace
aws cloudwatch list-metrics --namespace IoTPlayground/Sensors
```

---

## 🎨 Configurer Grafana (5 minutes)

### 1. Ouvrir Grafana
```
https://grafana-iot.sentori-studio.com
```

### 2. Ajouter CloudWatch comme Datasource
- Configuration → Data sources → Add data source
- Choisir **CloudWatch**
- Default Region: `eu-west-3`
- Authentication: **AWS SDK Default** (ou Access Key)
- Save & Test

### 3. Importer le Dashboard
- Dashboards → Import
- Upload file: `infra/docker/grafana/dashboards/iot-sensors-cloudwatch.json`
- Select CloudWatch datasource
- Import

### 4. Voir les Métriques
Votre dashboard devrait afficher:
- Sensor Readings
- Data Ingestion Rate
- Lambda Invocations
- Lambda Errors
- Lambda Duration
- DynamoDB Metrics

---

## 🔄 Mettre à Jour le Code Lambda

Si vous modifiez le code Python dans `infra/modules/serverless/lambda_*/files/handler.py`:

```bash
cd infra/envs/serverless-dev

# Terraform va automatiquement recréer le ZIP et update la Lambda
terraform apply
```

---

## 🗑️ Nettoyer (Supprimer Tout)

**⚠️ ATTENTION: Ceci supprime TOUT !**

```bash
cd infra/envs/serverless-dev

# Supprimer toutes les ressources serverless
terraform destroy
```

---

## 📞 Ressources Utiles

- 📖 [Documentation complète](./infra/modules/README-LAMBDA-SERVERLESS.md)
- 📋 [Guide de migration](./MIGRATION-GUIDE.md)
- 📦 [Résumé implémentation](./IMPLEMENTATION-SUMMARY.md)
- 🌐 [AWS Lambda Docs](https://docs.aws.amazon.com/lambda/)
- 🗄️ [DynamoDB Docs](https://docs.aws.amazon.com/dynamodb/)
- 🚪 [API Gateway Docs](https://docs.aws.amazon.com/apigateway/)

---

## 🎉 Félicitations !

Vous avez déployé une architecture serverless complète en moins de 10 minutes ! 🚀

**Prochaines étapes suggérées:**
1. ✅ Tester avec votre frontend
2. ✅ Configurer les alarmes CloudWatch
3. ✅ Optimiser les coûts avec DynamoDB TTL
4. ✅ Ajouter de l'authentification (Cognito)
5. ✅ Migrer vos données existantes

---

**Besoin d'aide ?** Consultez le [MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md) ou ouvrez une issue sur GitHub.

