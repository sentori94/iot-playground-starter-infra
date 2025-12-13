# ✅ Checklist de Déploiement - Architecture Serverless

## 📋 Phase 1: Préparation

- [ ] AWS CLI configuré et testé (`aws sts get-caller-identity`)
- [ ] Terraform >= 1.6.0 installé (`terraform version`)
- [ ] Secrets GitHub configurés (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
- [ ] Route53 zone `sentori-studio.com` existe
- [ ] Accès au repo GitHub `sentori94/iot-playground-starter-infra`

## 📋 Phase 2: Déploiement Infrastructure

- [ ] `cd infra/envs/dev`
- [ ] `terraform init` (sans erreur)
- [ ] `terraform plan` (vérifier les ressources à créer)
- [ ] `terraform apply` (taper 'yes')
- [ ] Attendre 3-5 minutes ⏱️
- [ ] Vérifier: "Apply complete! Resources: XX added"

## 📋 Phase 3: Vérification des Ressources

### DynamoDB
- [ ] Table `iot-playground-runs-dev` créée
- [ ] Table `iot-playground-sensor-data-dev` créée
- [ ] GSI configurés sur les deux tables

**Commande:**
```bash
aws dynamodb list-tables --region eu-west-3 | grep iot-playground
```

### Lambda
- [ ] Fonction `iot-playground-run-api-dev` déployée
- [ ] Fonction `iot-playground-sensor-api-dev` déployée
- [ ] Logs CloudWatch créés

**Commande:**
```bash
aws lambda list-functions --region eu-west-3 | grep iot-playground
```

### API Gateway
- [ ] API `iot-playground-lambda-api-dev` créée
- [ ] Stage `dev` déployé
- [ ] Custom domain configuré
- [ ] Certificat ACM validé

**Commande:**
```bash
aws apigateway get-rest-apis --region eu-west-3 | grep iot-playground
```

### Route53
- [ ] Enregistrement DNS `api-lambda-iot.sentori-studio.com` créé
- [ ] DNS résolu correctement

**Commande:**
```bash
nslookup api-lambda-iot.sentori-studio.com
```

## 📋 Phase 4: Tests des APIs

### Test 1: Health Check
- [ ] API répond (status 200)

**Commande:**
```bash
curl https://api-lambda-iot.sentori-studio.com/api/runs/all
```

### Test 2: Script de Test Automatique
- [ ] Exécuter `.\scripts\test-lambda-apis.ps1` (Windows)
- [ ] OU `./scripts/test-lambda-apis.sh` (Linux/Mac)
- [ ] Tous les tests passent ✅

### Test 3: Ingestion de Données
- [ ] POST /sensors/data retourne 200
- [ ] Données visibles avec GET /sensors/data

**Commande:**
```bash
curl -X POST https://api-lambda-iot.sentori-studio.com/sensors/data \
  -H "Content-Type: application/json" \
  -H "X-User: testuser" \
  -H "X-Run-Id: test-001" \
  -d '{"sensorId":"sensor-001","type":"temperature","reading":23.5}'
```

### Test 4: Vérification DynamoDB
- [ ] Données présentes dans la table SensorData

**Commande:**
```bash
aws dynamodb scan --table-name iot-playground-sensor-data-dev --limit 5
```

## 📋 Phase 5: Métriques CloudWatch

### Vérification
- [ ] Métriques Lambda visibles (Invocations, Errors, Duration)
- [ ] Métriques custom visibles (IoTPlayground/Sensors)
- [ ] Namespace `IoTPlayground/Sensors` existe

**Commande:**
```bash
aws cloudwatch list-metrics --namespace IoTPlayground/Sensors
```

### Voir les Logs
- [ ] Logs Lambda Run API accessibles
- [ ] Logs Lambda Sensor API accessibles

**Commande:**
```bash
aws logs tail /aws/lambda/iot-playground-sensor-api-dev --follow
```

## 📋 Phase 6: Configuration Grafana

### Datasource CloudWatch
- [ ] Grafana accessible (`https://grafana-iot.sentori-studio.com`)
- [ ] CloudWatch datasource ajouté
- [ ] Région `eu-west-3` configurée
- [ ] Connexion testée avec succès

### Dashboard
- [ ] Dashboard importé depuis `iot-sensors-cloudwatch.json`
- [ ] Panels affichent des données
- [ ] Métriques en temps réel visibles

## 📋 Phase 7: Test de Charge (Optionnel)

- [ ] Python 3.x installé
- [ ] Dependencies installées (`pip install -r scripts/requirements.txt`)
- [ ] Script de test exécuté

**Commande:**
```bash
python scripts/bulk_ingest_test.py --runs 3 --sensors 5 --data-points 50
```

### Résultats Attendus
- [ ] Taux de succès > 95%
- [ ] Pas d'erreur de throttling
- [ ] Métriques visibles dans CloudWatch après 1-2 min

## 📋 Phase 8: Mise à Jour Frontend (Si applicable)

- [ ] Variable d'environnement API_URL mise à jour
- [ ] Changé de `api-iot.sentori-studio.com` vers `api-lambda-iot.sentori-studio.com`
- [ ] Pagination adaptée (voir MIGRATION-GUIDE.md)
- [ ] Tests E2E passent
- [ ] Déployé en production

## 📋 Phase 9: Monitoring & Alarmes

### CloudWatch Alarms
- [ ] Alarme Lambda Errors configurée
- [ ] Alarme Lambda Duration configurée
- [ ] Alarme DynamoDB Throttling configurée
- [ ] SNS Topic pour notifications (optionnel)

**Exemple:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name lambda-sensor-api-errors \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

## 📋 Phase 10: Documentation & Handoff

- [ ] README.md lu et compris
- [ ] QUICKSTART.md testé
- [ ] MIGRATION-GUIDE.md consulté (si migration)
- [ ] Équipe formée sur la nouvelle architecture
- [ ] Runbook créé pour l'équipe ops

## 📋 Phase 11: Décommissionnement Ancienne Infra (Optionnel)

⚠️ **ATTENTION: Faire après validation complète!**

- [ ] Backup final de PostgreSQL effectué
- [ ] Validation que tout fonctionne en serverless
- [ ] Plan de rollback en place
- [ ] Commenté les anciens modules dans main.tf
- [ ] `terraform apply` pour détruire les anciennes ressources
- [ ] Vérification des économies de coûts

**Modules à commenter:**
```terraform
# module "database" { ... }
# module "spring_app_service" { ... }
# module "spring_app_alb" { ... }
# module "prometheus_service" { ... }
```

## 📊 Métriques de Succès

### Performance
- [ ] Latence < 200ms (p95)
- [ ] Disponibilité > 99.9%
- [ ] Pas d'erreur 5xx

### Coûts
- [ ] Facture AWS réduite de ~$50-60/mois
- [ ] Coûts serverless < $5/mois
- [ ] ROI positif

### Scalabilité
- [ ] Supporte 1000+ req/s
- [ ] Auto-scaling fonctionne
- [ ] Pas de cold start problématique

## 🎉 FÉLICITATIONS !

Si toutes les cases sont cochées, vous avez réussi la migration vers serverless ! 🚀

**Économies:** ~95% par rapport à l'ancienne architecture  
**Scalabilité:** Infinie (managed services)  
**Maintenance:** Quasi-nulle

---

## 📞 Support

**En cas de problème:**
1. Consulter [QUICKSTART.md](./QUICKSTART.md) section Dépannage
2. Vérifier les logs Lambda
3. Consulter [MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md)
4. Ouvrir une issue GitHub

**Ressources:**
- [README-LAMBDA-SERVERLESS.md](./infra/modules/README-LAMBDA-SERVERLESS.md)
- [IMPLEMENTATION-SUMMARY.md](./IMPLEMENTATION-SUMMARY.md)
- AWS Support (si plan Business/Enterprise)

---

**Date de déploiement:** __________  
**Déployé par:** __________  
**Environnement:** dev / staging / prod  
**Status:** ✅ Succès / ⚠️ Problèmes / ❌ Échec

