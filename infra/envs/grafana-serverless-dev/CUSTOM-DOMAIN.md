# 🌐 Custom Domain pour Grafana Serverless

## 📋 État Actuel

Le custom domain `grafana-lambda-iot.sentori-studio.com` est **désactivé** pour permettre le déploiement initial.

**Grafana est accessible via l'URL ALB :**
```
https://<alb-dns-name>.eu-west-3.elb.amazonaws.com
```

Vous pouvez récupérer cette URL avec :
```bash
cd infra/envs/grafana-serverless-dev
terraform output grafana_url
```

---

## ✅ Activer le Custom Domain (Plus Tard)

### Prérequis

1. Le certificat ACM pour `sentori-studio.com` doit être **créé et validé** (créé par `serverless-dev`)
2. Vérifier que le certificat existe :
   ```bash
   aws acm list-certificates --region eu-west-3 \
     --query "CertificateSummaryList[?DomainName=='sentori-studio.com']"
   ```

### Étapes

#### 1. Activer le data source du certificat

Dans `grafana-serverless-dev/main.tf`, **dé-commenter** le data source :

```terraform
# ===========================
# Data: Certificat ACM (depuis serverless-dev)
# ===========================
data "aws_acm_certificate" "lambda_api" {
  count       = 1  # Activer
  domain      = "sentori-studio.com"
  statuses    = ["ISSUED"]
  most_recent = true
}
```

#### 2. Activer le custom domain dans le module Grafana

Remplacer les lignes actuelles :

```terraform
# AVANT (désactivé)
custom_domain_name     = ""
certificate_arn        = ""
route53_zone_id        = ""
```

Par :

```terraform
# APRÈS (activé)
custom_domain_name     = var.grafana_domain_name
certificate_arn        = length(data.aws_acm_certificate.lambda_api) > 0 ? data.aws_acm_certificate.lambda_api[0].arn : ""
route53_zone_id        = var.route53_zone_name != "" ? data.aws_route53_zone.main[0].zone_id : ""
```

#### 3. Redéployer

```bash
cd infra/envs/grafana-serverless-dev
terraform apply
```

**Temps estimé :** 2-3 minutes (création du custom domain + enregistrement DNS)

#### 4. Accéder à Grafana

Après le déploiement :
```
https://grafana-lambda-iot.sentori-studio.com
```

---

## 🔄 Ordre de Déploiement Recommandé

1. **D'abord** : Déployer les Lambdas (`serverless-dev`) → Crée le certificat ACM
2. **Ensuite** : Déployer Grafana sans custom domain (état actuel)
3. **Enfin** : Activer le custom domain Grafana (suivre les étapes ci-dessus)

---

## 🐛 Troubleshooting

### Le certificat n'est pas trouvé

Vérifier qu'il est bien créé et **ISSUED** :
```bash
aws acm list-certificates --region eu-west-3
```

Si le certificat n'existe pas, déployez d'abord `serverless-dev` :
```bash
cd infra/envs/serverless-dev
terraform apply
```

### Le DNS ne résout pas

Attendre 5-15 minutes pour la propagation DNS après l'activation du custom domain.

Vérifier l'enregistrement DNS :
```bash
dig grafana-lambda-iot.sentori-studio.com
```

---

## 💡 Alternative : Utiliser l'URL ALB Directement

Si vous ne voulez pas de custom domain, vous pouvez continuer à utiliser l'URL ALB directe. Elle est **fonctionnelle** et **sécurisée** (HTTPS via certificat ALB auto-signé).

Pour ne pas voir l'avertissement de certificat dans le navigateur, ajoutez une exception de sécurité ou utilisez le custom domain.

