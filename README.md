# iot-playground-starter-infra (Minimal)

## Contenu
- **infra/envs/dev/** : crée VPC + 2 subnets privés + SG + RDS + ECR (1 seul repo backend).
- **.github/workflows/bootstrap.yml** : pipeline GitHub Actions avec `plan` ou `apply`.

## Secrets GitHub nécessaires
À mettre dans **Settings > Secrets and variables > Actions** du repo :
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` = `eu-west-3`
- `DB_USERNAME` (ex: postgres)
- `DB_PASSWORD` (ton mot de passe choisi)

## Paramètres à donner lors du lancement du workflow
- `MODE` : `plan` (voir diff) ou `apply` (créer/modifier).
- `STATE_BUCKET_NAME` : un nom **unique** pour le bucket S3 du state (ex: `iot-playground-tfstate-walid`).

## Résultat attendu
Après un `apply` réussi :
- 1 VPC `10.30.0.0/16`
- 2 subnets privés (eu-west-3a, eu-west-3b)
- 1 Security Group RDS (5432 ouvert au VPC)
- 1 base PostgreSQL RDS (db.t3.micro)
- 1 repo ECR `iot-backend`
