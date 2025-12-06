# Lambda Auto-Destroy Idle Infrastructure

Ce module Lambda surveille l'activité de votre application Spring Boot sur ECS via CloudWatch Logs et déclenche automatiquement la destruction de l'infrastructure si aucune activité n'est détectée pendant une période définie.

## 🎯 Fonctionnement

1. **EventBridge** déclenche la Lambda toutes les heures (configurable)
2. La Lambda vérifie les logs CloudWatch de l'application Spring
3. Si **aucun log "finished SUCCESS"** n'a été trouvé dans les **2 dernières heures** (configurable)
4. La Lambda déclenche le workflow GitHub Actions `terraform-destroy.yml`
5. Un email de notification est envoyé via SNS

## 📋 Variables

| Variable | Description | Défaut |
|----------|-------------|--------|
| `project` | Nom du projet | - |
| `environment` | Environnement (dev, prod) | - |
| `aws_region` | Région AWS | - |
| `github_token_secret_arn` | ARN du secret GitHub token | - |
| `github_repo_owner` | Propriétaire du repo GitHub | - |
| `github_repo_name` | Nom du repo GitHub | - |
| `notification_email` | Email pour les notifications | - |
| `cloudwatch_log_group` | Groupe de logs à surveiller | `/ecs/{project}-spring-app-{env}` |
| `log_filter_pattern` | Pattern à rechercher dans les logs | `finished SUCCESS` |
| `idle_threshold_hours` | Heures d'inactivité avant destroy | `2` |
| `check_schedule` | Fréquence de vérification | `rate(1 hour)` |

## 💰 Coûts estimés

- **Lambda** : Gratuit (Free Tier couvre largement)
- **EventBridge** : Gratuit (Free Tier)
- **SNS** : $0.50/mois (1000 emails gratuits puis $2 par 100k)
- **CloudWatch Logs** : ~$0.01/mois

**Total : ~$0.01/mois** 💚 (ou ~$0.51 si > 1000 emails)

## 🔒 Sécurité

- La Lambda a uniquement accès en lecture aux logs CloudWatch
- Le token GitHub est stocké dans Secrets Manager
- Permissions IAM minimales (principe du moindre privilège)

## 📊 Logs

Les logs de la Lambda sont disponibles dans CloudWatch :
```
/aws/lambda/{project}-{environment}-auto-destroy-idle
```

## ⚙️ Exemple d'utilisation

```hcl
module "auto_destroy_idle" {
  source = "../../modules/lambda_auto_destroy_idle"

  project     = "iot-playground"
  environment = "dev"
  aws_region  = "eu-west-3"

  github_token_secret_arn = module.lambda_infra_manager.github_token_secret_arn
  github_repo_owner       = "your-github-username"
  github_repo_name        = "iot-playground-starter-infra"

  notification_email    = "walid.lamkharbech@gmail.com"
  cloudwatch_log_group  = "/ecs/iot-playground-spring-app-dev"
  log_filter_pattern    = "finished SUCCESS"
  idle_threshold_hours  = 2
  check_schedule        = "rate(1 hour)"
}
```

## ⚠️ Important

- Assurez-vous que le workflow `terraform-destroy.yml` supporte `repository_dispatch` avec l'event type `trigger-destroy`
- Le log group CloudWatch doit exister (créé automatiquement par ECS)
- **Confirmez votre email SNS** après le premier déploiement (vous recevrez un email de confirmation)
- Pour désactiver temporairement : désactiver la règle EventBridge dans la console AWS

## 📧 Notifications Email

Vous recevrez un email dans les cas suivants :
- ✅ Activité détectée ("finished SUCCESS" trouvé) - Infrastructure maintenue
- ⚠️ Inactivité détectée - Destruction de l'infrastructure déclenchée
- ❌ Erreur lors de la vérification
