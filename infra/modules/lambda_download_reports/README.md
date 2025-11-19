# Lambda Download Reports + API Gateway

Ce module crée une API Gateway REST avec un Lambda qui permet de télécharger tous les rapports du bucket S3 sous forme de fichier ZIP.

## Architecture

- **Lambda Function** : Récupère tous les fichiers du bucket S3 reports et les compresse en ZIP
- **API Gateway** : Expose une API REST avec endpoint GET `/download`
- **API Key** : Sécurisation avec clé API et throttling pour limiter l'utilisation
- **Usage Plan** : 
  - Rate limit: 2 requêtes/seconde (configurable)
  - Burst limit: 5 requêtes max (configurable)
  - Quota: 100 requêtes/jour

## Utilisation

### 1. Récupérer l'API Key

Après le déploiement Terraform, récupérez l'API Key :

```bash
terraform output -raw reports_api_key
```

### 2. Récupérer l'URL de l'API

```bash
terraform output reports_api_endpoint
```

### 3. Télécharger les rapports

Utilisez curl avec l'API Key dans le header `x-api-key` :

```bash
curl -H "x-api-key: VOTRE_API_KEY" \
     "https://xxxxx.execute-api.eu-west-3.amazonaws.com/prod/download" \
     -o reports.zip
```

Ou avec wget :

```bash
wget --header="x-api-key: VOTRE_API_KEY" \
     "https://xxxxx.execute-api.eu-west-3.amazonaws.com/prod/download" \
     -O reports.zip
```

### 4. Exemple avec Python

```python
import requests

api_key = "votre_api_key"
endpoint = "https://xxxxx.execute-api.eu-west-3.amazonaws.com/prod/download"

headers = {
    "x-api-key": api_key
}

response = requests.get(endpoint, headers=headers)

if response.status_code == 200:
    with open("reports.zip", "wb") as f:
        f.write(response.content)
    print("Rapports téléchargés avec succès!")
else:
    print(f"Erreur: {response.status_code} - {response.text}")
```

## Variables

| Variable | Description | Défaut |
|----------|-------------|--------|
| `project` | Nom du projet | - |
| `environment` | Environnement (dev, prod) | - |
| `reports_bucket` | Nom du bucket S3 contenant les rapports | - |
| `api_throttle_rate_limit` | Limite de requêtes par seconde | 2 |
| `api_throttle_burst_limit` | Limite de burst | 5 |

## Outputs

| Output | Description |
|--------|-------------|
| `api_endpoint` | URL complète de l'API |
| `api_key_id` | ID de l'API Key |
| `api_key_value` | Valeur de l'API Key (sensible) |
| `lambda_function_name` | Nom de la fonction Lambda |
| `api_gateway_id` | ID de l'API Gateway |

## Sécurité

- ✅ API Key obligatoire pour accéder à l'API
- ✅ Throttling configuré (2 req/s, burst 5)
- ✅ Quota journalier (100 requêtes/jour)
- ✅ Lambda avec permissions IAM minimales (lecture seule sur le bucket S3)
- ✅ API Key marquée comme sensible dans les outputs Terraform

## Notes

- Le Lambda a un timeout de 60 secondes et 512 MB de mémoire
- Les fichiers sont zippés en mémoire (BytesIO) pour économiser l'espace disque
- Le nom du fichier ZIP contient un timestamp pour faciliter l'organisation
- Si le bucket est vide, l'API retourne un 404 avec le message "No reports found"

