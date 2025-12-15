# Script PowerShell pour récupérer les valeurs nécessaires

Write-Host "`n🔍 Récupération des valeurs depuis l'environnement dev...`n" -ForegroundColor Cyan

cd ..\dev

$VPC_ID = terraform output -raw vpc_id 2>$null
$ECS_CLUSTER_ID = terraform output -raw ecs_cluster_id 2>$null
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text 2>$null)

cd ..\serverless-dev

Write-Host "📋 Valeurs récupérées :`n" -ForegroundColor Cyan
Write-Host "VPC_ID             = `"$VPC_ID`""
Write-Host "ECS_CLUSTER_ID     = `"$ECS_CLUSTER_ID`""
Write-Host "GRAFANA_IMAGE_URI  = `"$ACCOUNT_ID.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless`""
Write-Host ""
Write-Host "✏️  Copier ces valeurs dans terraform.tfvars" -ForegroundColor Yellow
Write-Host ""

