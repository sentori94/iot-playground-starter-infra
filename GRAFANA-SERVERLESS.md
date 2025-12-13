# 📊 Grafana en Architecture Serverless

## 🤔 Options pour Grafana

Quand on passe en full serverless, Grafana pose une question : **comment héberger Grafana lui-même ?**

### Option 1 : Grafana Cloud (100% Serverless) ⭐ RECOMMANDÉ

**Avantages :**
- ✅ Entièrement géré par Grafana Labs
- ✅ Pas de serveur à maintenir
- ✅ Auto-scaling automatique
- ✅ Haute disponibilité
- ✅ Plan gratuit généreux (14 jours de rétention, 10k séries)
- ✅ Intégration CloudWatch native
- ✅ URL personnalisée disponible

**Inconvénients :**
- ❌ Coût supplémentaire au-delà du plan gratuit (~$8/mois pour Pro)
- ❌ Données hébergées chez Grafana (pas dans votre VPC)

**Configuration :**
```bash
# 1. Créer un compte sur grafana.com
# 2. Créer un stack (ex: sentori-iot.grafana.net)
# 3. Ajouter CloudWatch datasource avec AWS Access Keys
# 4. Importer vos dashboards
```

**Coût :**
- Free tier : Gratuit (10k métriques, 14 jours retention)
- Pro : $8/utilisateur/mois (inclus dans le coût serverless global)

---

### Option 2 : Grafana sur ECS Fargate (Hybride)

**Scénario :** Architecture serverless SAUF Grafana qui reste sur ECS.

**Avantages :**
- ✅ Contrôle total sur Grafana
- ✅ Données restent dans votre VPC
- ✅ Configuration personnalisée illimitée
- ✅ Pas de limite de métriques

**Inconvénients :**
- ❌ ECS Fargate à maintenir (~$15/mois)
- ❌ Pas 100% serverless
- ❌ Besoin d'ALB (~$16/mois)
- ❌ Configuration manuelle requise

**Coût additionnel :**
- ECS Fargate (1 tâche) : ~$15/mois
- ALB : ~$16/mois
- **Total : ~$31/mois**

**Impact sur l'architecture "full serverless" :**
- ⚠️ Ce n'est plus vraiment full serverless si on garde ECS
- Mais c'est une solution viable si vous avez besoin de Grafana on-premise

---

### Option 3 : Grafana sur Lambda avec Container (Expérimental)

**Concept :** Déployer Grafana comme une Lambda Container (jusqu'à 10 GB).

**Avantages :**
- ✅ Vraiment serverless
- ✅ Pas de serveur à gérer
- ✅ Pay-per-use

**Inconvénients :**
- ❌ Cold start très long (10-30 secondes)
- ❌ Timeout Lambda (15 minutes max)
- ❌ Complexe à configurer
- ❌ Stockage éphémère
- ❌ Besoin de RDS ou S3 pour la persistance
- ❌ Pas officiellement supporté par Grafana

**Verdict :** ❌ Pas recommandé pour production

---

### Option 4 : Pas de Grafana, CloudWatch Dashboards

**Alternative simple :** Utiliser les dashboards CloudWatch natifs.

**Avantages :**
- ✅ 100% AWS natif
- ✅ Coût inclus dans CloudWatch
- ✅ Aucun serveur à gérer
- ✅ Intégration parfaite avec Lambda/DynamoDB

**Inconvénients :**
- ❌ Interface moins flexible que Grafana
- ❌ Moins de types de visualisation
- ❌ Pas de plugins
- ❌ Alerting basique

**Coût :**
- Inclus dans CloudWatch (pas de coût additionnel)

---

### Option 5 : Grafana ECS On-Demand (IP Publique) ⭐ MEILLEURE SOLUTION HYBRIDE

**Concept :** Grafana sur ECS Fargate avec IP publique, **desired_count = 0** par défaut, qu'on démarre uniquement quand on en a besoin.

**Architecture :**
```
Frontend → Bouton "Démarrer Grafana" 
    ↓
Lambda ou API qui fait: 
  aws ecs update-service --desired-count 1
    ↓
ECS Fargate démarre (30-60 secondes)
    ↓
IP publique accessible directement
  https://<public-ip>:3000
    ↓
Après utilisation: desired_count = 0
```

**Avantages :**
- ✅ **Coût quasi-nul** quand éteint (0 tâche = $0/mois)
- ✅ **Pas besoin d'ALB** (~$16/mois économisés !)
- ✅ Contrôle total sur Grafana
- ✅ Données dans votre VPC
- ✅ On/Off à la demande depuis le frontend
- ✅ Compatible avec votre workflow ECS existant

**Inconvénients :**
- ⚠️ Démarrage ~30-60 secondes (acceptable)
- ⚠️ IP publique change à chaque démarrage (sauf Elastic IP)
- ⚠️ Besoin d'un mécanisme pour récupérer l'IP dynamique
- ⚠️ Pas de HTTPS sans ALB (ou utiliser self-signed cert)

**Coût :**
- **ECS Fargate (actif) :** ~$0.05/heure = $1.20/jour si utilisé 24h
- **ECS Fargate (éteint) :** $0 🎉
- **Exemple :** 2h d'utilisation/jour = ~$3/mois
- **Elastic IP (optionnel) :** $0.005/heure non attachée = ~$3.60/mois

**Coût estimé réaliste :** **$0-5/mois** selon usage

---

## 🎯 Recommandation Finale

### Pour votre cas (IoT Playground)

**Choix recommandé : Option 5 - Grafana ECS On-Demand** 🎯

**Pourquoi c'est la meilleure solution pour vous :**
1. **Coût minimal** : $0 quand éteint, ~$3-5/mois selon usage réel
2. **Cohérent avec votre infra ECS existante** : Réutilise ce que vous avez déjà fait
3. **Contrôle total** : Grafana dans votre VPC, configuration custom
4. **UX fluide** : Bouton "Démarrer Grafana" dans le frontend
5. **Pas d'ALB nécessaire** : Économie de $16/mois
6. **Multi-mode compatible** : Fonctionne pour ECS ET Serverless

**Alternative si vous préférez zéro gestion :**
- **Grafana Cloud** (gratuit, mais données chez Grafana Labs)

**Architecture complète :**
```
Frontend (React/Vue)
    ↓
Choix utilisateur : ECS ou Serverless
    ↓
┌─────────────────┬──────────────────┐
│   Mode ECS      │  Mode Serverless │
├─────────────────┼──────────────────┤
│ Spring Boot     │ Lambda Python    │
│ RDS PostgreSQL  │ DynamoDB         │
│ Prometheus      │ CloudWatch       │
│ Grafana (ECS)   │ Grafana Cloud ☁️ │
└─────────────────┴──────────────────┘
```

---

## 🔧 Configuration Grafana Cloud

### Étape 1 : Créer un Stack Grafana Cloud

```bash
# Aller sur https://grafana.com/auth/sign-up/create-user
# Créer un compte gratuit
# Créer un stack : sentori-iot.grafana.net
```

### Étape 2 : Ajouter CloudWatch Datasource

Dans Grafana Cloud :
1. Configuration → Data sources → Add data source
2. Choisir **CloudWatch**
3. Authentication : **Access & secret key**
4. Créer un IAM User avec la policy suivante :

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:DescribeAlarmsForMetric",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeRegions",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

5. Entrer les credentials AWS
6. Default Region : `eu-west-3`
7. Save & Test

### Étape 3 : Importer le Dashboard

```bash
# Importer le dashboard depuis :
infra/docker/grafana/dashboards/iot-sensors-cloudwatch.json

# Ou créer un nouveau dashboard avec ces panels :
# - Sensor Readings (Metric: SensorReading)
# - Data Ingestion Rate (Metric: DataIngested)
# - Lambda Invocations
# - Lambda Errors
# - Lambda Duration
```

### Étape 4 : Intégrer dans le Frontend

**Option A : iFrame**
```html
<iframe 
  src="https://sentori-iot.grafana.net/d/iot-sensors?orgId=1&refresh=10s&kiosk" 
  width="100%" 
  height="600px"
></iframe>
```

**Option B : Lien direct**
```javascript
const grafanaUrl = "https://sentori-iot.grafana.net/d/iot-sensors";
window.open(grafanaUrl, '_blank');
```

---

## 💰 Comparaison de Coûts

| Solution | Coût mensuel | Maintenance | On-Demand | Contrôle |
|----------|--------------|-------------|-----------|----------|
| **Grafana ECS On-Demand** ⭐ | **$0-5** | ⚠️ Faible | ✅ Oui | ✅ Total |
| **Grafana Cloud (Free)** | $0 | ✅ Aucune | ✅ Oui | ❌ Limité |
| **Grafana Cloud (Pro)** | $8 | ✅ Aucune | ✅ Oui | ❌ Limité |
| **Grafana ECS Always-On** | $31 | ⚠️ Moyenne | ❌ Non | ✅ Total |
| **CloudWatch Dashboards** | $0 | ✅ Aucune | ✅ Oui | ❌ Basique |

---

## 📊 Architecture Finale Recommandée

### Mode Serverless complet

```
┌─────────────────────────────────────────┐
│           Frontend React/Vue            │
│  (Choix: ECS classique ou Serverless)   │
└────────────┬────────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
    ▼                 ▼
┌───────────┐   ┌──────────────┐
│  Mode ECS │   │  Serverless  │
│           │   │              │
│ Spring    │   │ Lambda API   │
│ + RDS     │   │ + DynamoDB   │
│ + Grafana │   │ + CloudWatch │
│   (ECS)   │   │              │
└───────────┘   └──────┬───────┘
                       │
                       ▼
              ┌─────────────────┐
              │  Grafana Cloud  │
              │  (sentori-iot)  │
              │                 │
              │  CloudWatch DS  │
              └─────────────────┘
```

**Avantages de cette architecture :**
1. ✅ Mode ECS : Grafana auto-hébergé (contrôle total)
2. ✅ Mode Serverless : Grafana Cloud (pas de serveur)
3. ✅ L'utilisateur choisit ce qu'il préfère
4. ✅ Deux expériences complètes et isolées
5. ✅ Coûts optimisés selon le mode

---

## 🎯 Action Items

### Pour l'implémentation

1. **Créer un compte Grafana Cloud**
   - URL : https://grafana.com/auth/sign-up
   - Stack : sentori-iot.grafana.net

2. **Créer IAM User pour CloudWatch**
   ```bash
   aws iam create-user --user-name grafana-cloudwatch-reader
   aws iam attach-user-policy \
     --user-name grafana-cloudwatch-reader \
     --policy-arn arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess
   aws iam create-access-key --user-name grafana-cloudwatch-reader
   ```

3. **Configurer le datasource CloudWatch dans Grafana Cloud**

4. **Importer/créer les dashboards**

5. **Mettre à jour le frontend**
   ```javascript
   // Dans le composant Serverless
   const GRAFANA_URL = "https://sentori-iot.grafana.net/d/iot-sensors";
   
   // Afficher un bouton ou iframe
   <a href={GRAFANA_URL} target="_blank">
     Voir les métriques Grafana
   </a>
   ```

---

## 📚 Ressources

- [Grafana Cloud Free Tier](https://grafana.com/pricing/)
- [Grafana CloudWatch Plugin](https://grafana.com/docs/grafana/latest/datasources/aws-cloudwatch/)
- [AWS IAM Policies for CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/auth-and-access-control-cw.html)

---

**Conclusion :** Pour une architecture 100% serverless, **Grafana Cloud** est la meilleure option. C'est simple, gratuit pour commencer, et ne nécessite aucune gestion de serveur. 🚀

