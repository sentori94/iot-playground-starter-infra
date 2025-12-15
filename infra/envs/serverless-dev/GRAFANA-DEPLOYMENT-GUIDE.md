# 🚀 Guide de Déploiement Grafana Serverless

## 📋 Vue d'ensemble

Ce guide vous explique comment déployer Grafana sur ECS avec Athena pour visualiser les données DynamoDB de votre architecture serverless.

## 🎯 Architecture

```
Grafana ECS Fargate + ALB + HTTPS
  ├─ Datasource Athena → DynamoDB (Runs + SensorData)
  └─ Datasource CloudWatch → Métriques Lambda
```

---

## ✅ Prérequis

1. ✅ Infrastructure serverless Lambda déjà déployée
2. ✅ Tables DynamoDB créées (Runs et SensorData)
3. ✅ Certificat ACM pour `sentori-studio.com` validé
4. ✅ VPC et subnets existants (depuis environnement `dev`)
5. ✅ Cluster ECS existant

---

## 🚀 Méthodes de Déploiement

Il y a **2 méthodes** pour déployer Grafana :

### Méthode A : Via GitHub Actions (Recommandé) ⭐

Utilisez le workflow **"Deploy Grafana Serverless (ECS)"** qui gère tout automatiquement :

1. GitHub → **Actions** → **Deploy Grafana Serverless (ECS)**
2. **Run workflow**
3. Choisir :
   - **MODE** : `plan` ou `apply`
   - **ACTION** : 
     - `full` : Déploie tout (réseau + Athena + Grafana)
     - `athena-only` : Déploie uniquement Athena
     - `grafana-only` : Déploie Grafana + réseau + Athena (sans toucher aux Lambdas)
4. **Run**

**Avantages :**
- ✅ Ne touche pas aux Lambdas déjà déployées
- ✅ Crée automatiquement le backend S3 si nécessaire
- ✅ Options granulaires (athena-only, grafana-only)

### Méthode B : Déploiement Manuel (Locale)

Si vous préférez déployer en local, suivez les étapes ci-dessous.

---

## 📝 Étapes de Déploiement (Manuel)

### Étape 1 : Créer le Repo ECR

```bash
aws ecr create-repository \
  --repository-name iot-playground-grafana-serverless \
  --region eu-west-3
```

**Output :**
```json
{
  "repository": {
    "repositoryUri": "123456789.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless"
  }
}
```

Notez le `repositoryUri` pour plus tard.

---

### Étape 2 : Builder et Pousser l'Image Docker

```bash
# 1. Se connecter à ECR
aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin 123456789.dkr.ecr.eu-west-3.amazonaws.com

# 2. Aller dans le répertoire Docker
cd infra/docker/grafana-serverless

# 3. Builder l'image
docker build -t iot-playground-grafana-serverless:latest .

# 4. Tagger
docker tag iot-playground-grafana-serverless:latest 123456789.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless:latest

# 5. Pousser
docker push 123456789.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless:latest
```

---

### Étape 3 : Récupérer les IDs de Ressources Existantes

Vous devez récupérer les IDs depuis votre environnement `dev` existant :

```bash
cd infra/envs/dev

# VPC ID
terraform output vpc_id

# Subnet IDs publics (pour ALB)
terraform output public_subnet_ids

# Subnet IDs privés (pour Grafana)
terraform output private_subnet_ids

# ECS Cluster ID
terraform output ecs_cluster_id
```

---

### Étape 4 : Configurer `serverless-dev/terraform.tfvars`

Éditez le fichier et remplacez les valeurs `TODO` :

```hcl
# Network (remplacer avec vos vraies valeurs)
vpc_id              = "vpc-0abc123def456"
public_subnet_ids   = ["subnet-0abc111", "subnet-0abc222"]
private_subnet_ids  = ["subnet-0def333", "subnet-0def444"]
ecs_cluster_id      = "arn:aws:ecs:eu-west-3:123456789:cluster/iot-playground-dev"

# Grafana (remplacer avec votre ECR URI)
grafana_image_uri      = "123456789.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless"
grafana_image_tag      = "latest"
grafana_admin_password = "VotreMotDePasseSecurise123!"
```

---

### Étape 5 : Déployer avec Terraform

```bash
cd infra/envs/serverless-dev

# Initialiser (si pas déjà fait)
terraform init

# Voir ce qui va être créé
terraform plan

# Déployer
terraform apply
```

**Temps estimé :** 5-8 minutes

---

### Étape 6 : Créer les Tables Athena

Après le déploiement Terraform, vous devez créer les tables Athena qui mappent DynamoDB.

**Option A : Via AWS Console Athena**

1. Aller sur **Athena Console** → Région `eu-west-3`
2. Sélectionner le workgroup : `iot-playground-grafana-serverless-dev`
3. Sélectionner la database : `iot_playground_serverless_dev`
4. Exécuter ces 2 requêtes :

```sql
-- Créer la table runs
CREATE EXTERNAL TABLE IF NOT EXISTS runs (
  id string,
  username string,
  status string,
  startedAt string,
  finishedAt string,
  params string,
  errorMessage string,
  grafanaUrl string
)
STORED BY 'org.apache.hadoop.hive.dynamodb.DynamoDBStorageHandler'
TBLPROPERTIES (
  "dynamodb.table.name" = "iot-playground-runs-serverless-dev",
  "dynamodb.column.mapping" = "id:id,username:username,status:status,startedAt:startedAt,finishedAt:finishedAt,params:params,errorMessage:errorMessage,grafanaUrl:grafanaUrl"
);

-- Créer la table sensor_data
CREATE EXTERNAL TABLE IF NOT EXISTS sensor_data (
  sensorId string,
  timestamp string,
  type string,
  reading double,
  user string,
  runId string
)
STORED BY 'org.apache.hadoop.hive.dynamodb.DynamoDBStorageHandler'
TBLPROPERTIES (
  "dynamodb.table.name" = "iot-playground-sensor-data-serverless-dev",
  "dynamodb.column.mapping" = "sensorId:sensorId,timestamp:timestamp,type:type,reading:reading,user:user,runId:runId"
);
```

**Option B : Via Named Queries (automatique)**

Les named queries ont été créées par Terraform. Exécutez-les dans Athena :
- `create-runs-table`
- `create-sensor-data-table`

---

### Étape 7 : Vérifier que Tout Fonctionne

#### 7.1 Tester Athena

```sql
-- Vérifier que les tables existent
SHOW TABLES;

-- Tester une requête sur runs
SELECT * FROM runs LIMIT 10;

-- Tester une requête sur sensor_data
SELECT * FROM sensor_data LIMIT 10;
```

#### 7.2 Accéder à Grafana

```bash
# Récupérer l'URL Grafana
cd infra/envs/serverless-dev
terraform output grafana_url
```

**URL :** `https://grafana-lambda-iot.sentori-studio.com`

**Credentials :**
- Username: `admin`
- Password: (celui configuré dans `terraform.tfvars`)

#### 7.3 Vérifier les Datasources

1. Se connecter à Grafana
2. Aller dans **Configuration** → **Data sources**
3. Vérifier que 2 datasources sont configurés :
   - ✅ **Athena-DynamoDB** (default)
   - ✅ **CloudWatch**
4. Cliquer sur chacun → **Save & Test** → Doit afficher "Success"

#### 7.4 Vérifier le Dashboard

1. Aller dans **Dashboards**
2. Ouvrir **IoT Serverless - DynamoDB Data**
3. Vérifier que les panels affichent des données

---

## 🎨 Utilisation de Grafana

### Requêtes SQL Athena Utiles

**Runs par statut :**
```sql
SELECT status, COUNT(*) as count 
FROM runs 
GROUP BY status;
```

**Runs des dernières 24h :**
```sql
SELECT id, username, status, startedAt
FROM runs
WHERE from_iso8601_timestamp(startedAt) > current_timestamp - interval '24' hour
ORDER BY startedAt DESC;
```

**Sensor readings par type :**
```sql
SELECT 
  type,
  AVG(reading) as avg_reading,
  MIN(reading) as min_reading,
  MAX(reading) as max_reading,
  COUNT(*) as count
FROM sensor_data
GROUP BY type;
```

**Time series des températures :**
```sql
SELECT 
  from_iso8601_timestamp(timestamp) as time,
  sensorId,
  reading as temperature
FROM sensor_data
WHERE type = 'temperature'
  AND from_iso8601_timestamp(timestamp) > current_timestamp - interval '6' hour
ORDER BY timestamp;
```

---

## 🔧 Configuration Avancée

### Ajouter un Nouveau Dashboard

1. Créer le JSON du dashboard dans Grafana UI
2. Exporter le JSON
3. Sauvegarder dans `infra/docker/grafana-serverless/dashboards/mon-dashboard.json`
4. Rebuild et repush l'image Docker
5. Redéployer le service ECS

### Changer le Mot de Passe Admin

```bash
# Méthode 1 : Via terraform.tfvars
# Éditer grafana_admin_password dans terraform.tfvars
# Puis redéployer : terraform apply

# Méthode 2 : Via Grafana UI
# Se connecter → Configuration → Change Password
```

### Ajouter un Nouveau Datasource

Éditer `infra/docker/grafana-serverless/provisioning/datasources/datasources.yml`, puis rebuild l'image.

---

## 🐛 Troubleshooting

### Problème : Grafana ne démarre pas

**Vérifier les logs :**
```bash
aws logs tail /ecs/iot-playground-grafana-serverless-serverless-dev --follow
```

### Problème : Athena ne retourne pas de données

1. Vérifier que les tables sont créées :
```sql
SHOW TABLES IN iot_playground_serverless_dev;
```

2. Vérifier les permissions IAM du rôle Grafana

3. Tester la requête directement dans Athena Console

### Problème : "403 Forbidden" sur l'ALB

Vérifier que le certificat ACM est bien validé :
```bash
aws acm describe-certificate --certificate-arn <ARN> --region eu-west-3
```

### Problème : Datasource Athena ne se connecte pas

1. Vérifier que le workgroup existe :
```bash
aws athena get-work-group --work-group iot-playground-grafana-serverless-dev
```

2. Vérifier les variables d'environnement dans la task ECS

---

## 💰 Coûts Estimés

**Grafana ECS Fargate (always-on) :**
- ECS Fargate (0.5 vCPU, 1GB RAM) : ~$15/mois
- ALB : ~$16/mois
- S3 Athena results : < $1/mois
- **Total : ~$32/mois**

**Note :** C'est less cher que Grafana Cloud Pro ($8/user/mois) si vous avez plusieurs utilisateurs.

---

## 🔄 Mise à Jour

Pour mettre à jour Grafana ou les dashboards :

```bash
# 1. Modifier les fichiers dans infra/docker/grafana-serverless/
# 2. Rebuild l'image
cd infra/docker/grafana-serverless
docker build -t iot-playground-grafana-serverless:latest .

# 3. Push vers ECR
docker tag iot-playground-grafana-serverless:latest <ECR_URI>:latest
docker push <ECR_URI>:latest

# 4. Forcer un nouveau déploiement ECS
aws ecs update-service \
  --cluster iot-playground-serverless-dev \
  --service iot-playground-grafana-serverless-serverless-dev \
  --force-new-deployment \
  --region eu-west-3
```

---

## ✅ Checklist Finale

- [ ] Repo ECR créé
- [ ] Image Docker buildée et pushée
- [ ] terraform.tfvars configuré avec les bonnes valeurs
- [ ] `terraform apply` réussi
- [ ] Tables Athena créées
- [ ] Grafana accessible sur https://grafana-lambda-iot.sentori-studio.com
- [ ] Datasources testés et fonctionnels
- [ ] Dashboard affiche des données
- [ ] Mot de passe admin changé

---

**Félicitations ! Votre Grafana Serverless est déployé et opérationnel ! 🎉**

