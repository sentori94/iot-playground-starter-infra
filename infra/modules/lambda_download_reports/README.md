# Configuration d'un Domaine Personnalisé pour l'API Gateway Lambda

## Vue d'ensemble

Ce module supporte maintenant l'utilisation d'un nom de domaine personnalisé pour votre API Gateway Lambda de téléchargement de rapports. C'est simple à configurer !

## Ce qui a été ajouté

1. **Module ACM Certificate** (`infra/modules/acm_certificate/`) : Gère automatiquement les certificats SSL via AWS Certificate Manager avec validation DNS
2. **Configuration du domaine personnalisé** dans le module `lambda_download_reports` : Crée le domaine API Gateway et le mapping
3. **Enregistrement Route53** : Associe automatiquement votre domaine à l'API Gateway

## Comment l'utiliser

### 1. Dans votre fichier `terraform.tfvars`

Ajoutez simplement ces variables :

```hcl
# Zone Route53 (obligatoire)
route53_zone_name = "example.com"

# Domaine personnalisé pour l'API Reports (optionnel)
api_reports_domain_name = "api-reports.example.com"
```

### 2. Déploiement

```bash
cd infra/envs/dev
terraform init
terraform plan
terraform apply
```

## Ce qui se passe automatiquement

1. **Certificat SSL** : Un certificat ACM est créé pour votre domaine avec validation DNS automatique via Route53
2. **Domaine API Gateway** : Un domaine personnalisé régional est créé et associé au certificat
3. **Mapping** : L'API est automatiquement mappée au domaine personnalisé
4. **Route53** : Un enregistrement A (alias) est créé pointant vers le domaine API Gateway
5. **URL mise à jour** : L'output `api_endpoint` retourne automatiquement l'URL avec votre domaine personnalisé

## Résultat

### Avant (sans domaine personnalisé)
```
API Endpoint: https://abc123xyz.execute-api.eu-west-3.amazonaws.com/dev/download
```

### Après (avec domaine personnalisé)
```
API Endpoint: https://api-reports.example.com/download
```

## Configuration optionnelle

Si vous ne configurez pas `api_reports_domain_name`, l'API Gateway continuera de fonctionner avec son URL par défaut. C'est totalement optionnel !

## Variables disponibles

| Variable | Description | Requis |
|----------|-------------|--------|
| `route53_zone_name` | Nom de votre zone Route53 hébergée | Oui (pour domaine personnalisé) |
| `api_reports_domain_name` | Nom de domaine pour l'API (ex: api-reports.example.com) | Non |

## Notes importantes

- **Propagation DNS** : La première fois, la validation du certificat peut prendre 5-10 minutes
- **Région** : Le certificat ACM doit être dans la même région que votre API Gateway (eu-west-3 dans votre cas)
- **HTTPS uniquement** : Les domaines personnalisés API Gateway utilisent toujours HTTPS
- **Coût** : Pas de coût supplémentaire pour le domaine personnalisé API Gateway ni pour les certificats ACM

## Exemple de configuration complète

```hcl
# terraform.tfvars
project                  = "iot-playground"
env                      = "dev"
route53_zone_name        = "sentori-studio.com"
api_reports_domain_name  = "api-reports.sentori-studio.com"
backend_domain_name      = "api.sentori-studio.com"
grafana_domain_name      = "grafana.sentori-studio.com"
prometheus_domain_name   = "prometheus.sentori-studio.com"
```

## Outputs disponibles

Après le déploiement, vous pouvez voir :

```bash
terraform output
```

- `lambda_download_reports_api_endpoint` : URL complète de l'API (avec domaine personnalisé si configuré)
- `lambda_download_reports_custom_domain` : Nom du domaine personnalisé
- `lambda_download_reports_api_key_id` : ID de la clé API

## Dépannage

### Le certificat ne se valide pas
- Vérifiez que la zone Route53 est bien configurée
- Attendez 10-15 minutes pour la propagation DNS
- Vérifiez les enregistrements de validation dans Route53

### L'API ne répond pas sur le domaine personnalisé
- Attendez quelques minutes après le déploiement pour la propagation
- Vérifiez que le mapping est créé dans la console API Gateway
- Testez avec `curl -v https://votre-domaine.com/download`

