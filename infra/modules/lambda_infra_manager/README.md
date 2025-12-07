# Configuration des Domaines Personnalisés pour Infrastructure Manager

## Vue d'ensemble

Le module `lambda_infra_manager` supporte maintenant l'utilisation de domaines personnalisés pour toutes ses API Lambda. Configuration simple et automatique !

## Endpoints disponibles

L'Infrastructure Manager expose 6 endpoints via API Gateway HTTP API :

1. **POST** `/infra/create` - Créer une nouvelle infrastructure
2. **POST** `/infra/destroy` - Détruire une infrastructure
3. **GET** `/infra/status/{deploymentId}` - Vérifier le statut d'un déploiement
4. **GET** `/infra/latest-deployment` - Obtenir le dernier déploiement
5. **GET** `/infra/list-deployments` - Lister tous les déploiements
6. **POST** `/infra/cancel-deployment` - Annuler un déploiement

## Configuration

### Dans `terraform.tfvars`

Ajoutez simplement ces deux lignes :

```hcl
route53_zone_name           = "sentori-studio.com"
infra_manager_domain_name   = "infra-manager-iot.sentori-studio.com"
```

### Résultat

**Avant (sans domaine personnalisé) :**
```
https://abc123xyz.execute-api.eu-west-3.amazonaws.com/infra/create
```

**Après (avec domaine personnalisé) :**
```
https://infra-manager-iot.sentori-studio.com/infra/create
```

## Ce qui se passe automatiquement

1. ✅ **Module Route53** : Récupère la zone hébergée
2. ✅ **Certificat ACM** : Créé et validé automatiquement via DNS
3. ✅ **Domaine API Gateway HTTP** : Configuré avec le certificat
4. ✅ **Mapping** : Tous les endpoints mappés au domaine personnalisé
5. ✅ **Route53 A Record** : Alias créé automatiquement
6. ✅ **Outputs mis à jour** : Tous les endpoints retournent l'URL personnalisée

## Déploiement

```bash
cd infra/envs/inframanager-dev
terraform init
terraform plan
terraform apply
```

⏱️ **Note** : La validation du certificat SSL prend environ 5-10 minutes la première fois.

## Vérification des endpoints

Après le déploiement :

```bash
terraform output api_endpoints
```

Vous verrez tous vos endpoints avec votre domaine personnalisé :

```json
{
  "cancel_deployment" = "https://infra-manager-iot.sentori-studio.com/infra/cancel-deployment"
  "check_status" = "https://infra-manager-iot.sentori-studio.com/infra/status/{deploymentId}"
  "create_infra" = "https://infra-manager-iot.sentori-studio.com/infra/create"
  "destroy_infra" = "https://infra-manager-iot.sentori-studio.com/infra/destroy"
  "latest_deployment" = "https://infra-manager-iot.sentori-studio.com/infra/latest-deployment"
  "list_deployments" = "https://infra-manager-iot.sentori-studio.com/infra/list-deployments"
}
```

## Test rapide

```bash
# Tester l'endpoint de liste des déploiements
curl https://infra-manager-iot.sentori-studio.com/infra/list-deployments

# Créer une nouvelle infrastructure
curl -X POST https://infra-manager-iot.sentori-studio.com/infra/create \
  -H "Content-Type: application/json" \
  -d '{"environment": "test-env-1"}'
```

## Variables disponibles

| Variable | Description | Requis |
|----------|-------------|--------|
| `route53_zone_name` | Nom de votre zone Route53 | Oui (pour domaine personnalisé) |
| `infra_manager_domain_name` | Domaine pour l'API (ex: infra-manager.example.com) | Non |

## Configuration optionnelle

Si vous ne configurez pas `infra_manager_domain_name`, l'API Gateway continuera de fonctionner avec son URL par défaut AWS. C'est totalement optionnel !

## Différence avec lambda_download_reports

- **lambda_download_reports** : Utilise API Gateway REST API (v1)
- **lambda_infra_manager** : Utilise API Gateway HTTP API (v2)

Les deux supportent les domaines personnalisés, mais la syntaxe Terraform diffère légèrement.

## Outputs disponibles

- `api_gateway_url` : URL de base de l'API
- `api_endpoints` : Tous les endpoints avec URLs complètes
- `custom_domain_name` : Nom du domaine personnalisé (si configuré)
- `custom_domain_target` : Target domain pour Route53 alias

## Notes importantes

- **HTTPS obligatoire** : API Gateway force toujours HTTPS
- **Coût** : Aucun coût supplémentaire pour le domaine personnalisé ou le certificat ACM
- **Multi-endpoints** : Tous les endpoints Lambda partagent le même domaine
- **CORS** : Déjà configuré pour accepter toutes les origines (à personnaliser si besoin)

