# Module CDN (S3 + CloudFront)

Ce module crée une infrastructure CDN complète avec un bucket S3 et une distribution CloudFront pour héberger des fichiers statiques (site web, images, etc.).

## Architecture

- **S3 Bucket** : Stockage sécurisé avec versioning, encryption et CORS
- **CloudFront** : Distribution CDN avec Origin Access Control (OAC)
- **Sécurité** : Accès S3 restreint uniquement à CloudFront
- **Support HTTPS** : Redirection automatique vers HTTPS
- **Support SPA** : Gestion des erreurs 403/404 pour les Single Page Applications

## Fonctionnalités

### S3 Bucket
- ✅ Accès public bloqué
- ✅ Versioning activé
- ✅ Encryption au repos (AES256)
- ✅ Configuration CORS
- ✅ Politique d'accès restreinte à CloudFront uniquement

### CloudFront Distribution
- ✅ HTTPS par défaut avec redirection
- ✅ Compression automatique
- ✅ Origin Access Control (OAC) moderne
- ✅ Cache optimisé (TTL configurable)
- ✅ Support IPv6
- ✅ Gestion des erreurs pour SPA (redirige 403/404 vers index.html)
- ✅ Support optionnel pour domaine personnalisé + certificat ACM

## Utilisation

### Configuration de base

```hcl
module "cdn" {
  source = "../../modules/cdn"

  project     = "mon-projet"
  environment = "prod"
  tags = {
    Project = "mon-projet"
    Environment = "prod"
  }
}
```

### Avec domaine personnalisé

```hcl
module "cdn" {
  source = "../../modules/cdn"

  project                = "mon-projet"
  environment            = "prod"
  domain_name            = "cdn.example.com"
  acm_certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/..."
  
  tags = {
    Project = "mon-projet"
    Environment = "prod"
  }
}
```

**Note importante** : Le certificat ACM doit être créé dans la région `us-east-1` pour être utilisé avec CloudFront.

## Variables

| Variable | Description | Type | Défaut | Requis |
|----------|-------------|------|--------|--------|
| `project` | Nom du projet | string | - | ✅ |
| `environment` | Environnement (dev, staging, prod) | string | - | ✅ |
| `domain_name` | Nom de domaine personnalisé | string | "" | ❌ |
| `acm_certificate_arn` | ARN du certificat ACM (us-east-1) | string | "" | ❌ |
| `price_class` | Classe de prix CloudFront | string | "PriceClass_100" | ❌ |
| `tags` | Tags à appliquer aux ressources | map(string) | {} | ❌ |

### Classes de prix CloudFront

- `PriceClass_100` : USA, Canada, Europe (moins cher)
- `PriceClass_200` : + Asie, Afrique, Moyen-Orient
- `PriceClass_All` : Tous les edge locations (plus cher)

## Outputs

| Output | Description |
|--------|-------------|
| `s3_bucket_name` | Nom du bucket S3 |
| `s3_bucket_arn` | ARN du bucket S3 |
| `cloudfront_distribution_id` | ID de la distribution CloudFront |
| `cloudfront_domain_name` | Nom de domaine CloudFront |
| `cloudfront_url` | URL complète de la distribution |
| `cloudfront_arn` | ARN de la distribution CloudFront |

## Déploiement

### 1. Via GitHub Actions

Utilisez le workflow `.github/workflows/deploy-cdn.yml` :

```bash
# Plan
gh workflow run deploy-cdn.yml \
  -f MODE=plan \
  -f STATE_BUCKET_NAME=iot-playground-tfstate-cdn \
  -f ENVIRONMENT=dev

# Apply
gh workflow run deploy-cdn.yml \
  -f MODE=apply \
  -f STATE_BUCKET_NAME=iot-playground-tfstate-cdn \
  -f ENVIRONMENT=dev
```

### 2. Manuellement

```bash
cd infra/envs/cdn-dev

# Initialiser
terraform init \
  -backend-config="bucket=iot-playground-tfstate-cdn" \
  -backend-config="key=dev/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=terraform-locks-cdn"

# Plan
terraform plan -var="env=dev"

# Apply
terraform apply -var="env=dev"
```

## Upload de fichiers vers S3

Après déploiement, vous pouvez uploader des fichiers :

```bash
# Via AWS CLI
aws s3 sync ./dist/ s3://iot-playground-cdn-dev/ --delete

# Invalider le cache CloudFront
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
```

## Configuration DNS (optionnel)

Si vous utilisez un domaine personnalisé, créez un enregistrement CNAME ou ALIAS :

**Route53 (ALIAS recommandé) :**
```hcl
resource "aws_route53_record" "cdn" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "cdn.example.com"
  type    = "A"

  alias {
    name                   = module.cdn.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2"  # Zone ID CloudFront (fixe)
    evaluate_target_health = false
  }
}
```

**Autre DNS (CNAME) :**
```
cdn.example.com  →  d1234567890abc.cloudfront.net
```

## Sécurité

### Bonnes pratiques implémentées

1. ✅ Bucket S3 non-public
2. ✅ Accès S3 restreint à CloudFront via OAC
3. ✅ HTTPS obligatoire (redirection)
4. ✅ Encryption au repos
5. ✅ Versioning activé
6. ✅ TLS 1.2 minimum
7. ✅ Compression activée

### Recommandations supplémentaires

- Activez AWS CloudTrail pour l'audit
- Configurez AWS WAF sur CloudFront pour la protection DDoS
- Utilisez S3 Lifecycle policies pour archiver les anciennes versions

## Coûts estimés

Estimation mensuelle pour un site avec trafic modéré :

- **S3** : ~$0.023/GB stocké + $0.09/GB transféré
- **CloudFront** : ~$0.085/GB (premiers 10 TB)
- **Requests** : ~$0.01 par 10,000 requêtes HTTPS

**Exemple** : Site de 1 GB avec 100 GB/mois de trafic ≈ $9-10/mois

## Troubleshooting

### Distribution CloudFront lente à déployer
Les distributions CloudFront prennent 15-20 minutes à se déployer. C'est normal.

### Erreur 403 sur CloudFront
Vérifiez que :
- Le fichier existe dans S3
- La bucket policy autorise CloudFront
- L'OAC est correctement configuré

### Certificat ACM non disponible
Le certificat doit être dans `us-east-1`. Créez-le dans cette région.

## Exemples d'utilisation

Voir `infra/envs/cdn-dev/` et `infra/envs/cdn-prod/` pour des exemples complets de configuration par environnement.
