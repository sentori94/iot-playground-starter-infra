# iot-playground-starter-infra (Terraform) – Version *Access Keys* (sans OIDC)

Infra pour **ECR + EKS + RDS** avec backend S3/DynamoDB. Authentification CI/CD via
**clés IAM** stockées comme secrets GitHub (plus simple que l’OIDC).

## Secrets GitHub à créer
Dans chacun des repos concernés (code et/ou infra) :
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` = `eu-west-3`

Crée deux IAM Users si possible:
- `ci-ecr` (permissions ECR push/pull)
- `tf-infra` (permissions S3 backend + DynamoDB lock + Describe + EKS Describe + SSM GetParameter)

## Ordre conseillé
1. `infra/global/backend/` : crée le bucket S3 et la table DynamoDB (state/lock)
2. `infra/envs/dev/ecr/` : crée/import ECR (`api-sensors`, `simulator`, `frontend`)
3. `infra/envs/dev/rds/` : crée/import RDS + SubnetGroup + SG
4. `infra/envs/dev/eks/` : data sources EKS + add-ons (ALB Controller)
5. `infra/envs/dev/apps/` : déploiements Helm (consomme ECR)

## Placeholders à remplacer
- `<STATE_BUCKET_NAME>` : nom unique du bucket S3 pour le state
- `<ACCOUNT_ID>` : ID de ton compte AWS

## Imports utiles (exemples)
```bash
# ECR
terraform import 'aws_ecr_repository.repos["api-sensors"]' api-sensors
terraform import 'aws_ecr_repository.repos["simulator"]'  simulator
terraform import 'aws_ecr_repository.repos["frontend"]'   frontend

# RDS
terraform import aws_db_instance.postgres iot-sensors-db
```
