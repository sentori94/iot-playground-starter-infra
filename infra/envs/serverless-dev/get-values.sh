#!/bin/bash

# Script pour récupérer les valeurs nécessaires depuis l'environnement dev

echo "🔍 Récupération des valeurs depuis l'environnement dev..."
echo ""

cd ../dev

VPC_ID=$(terraform output -raw vpc_id 2>/dev/null)
ECS_CLUSTER_ID=$(terraform output -raw ecs_cluster_id 2>/dev/null)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)

cd ../serverless-dev

echo "📋 Valeurs récupérées :"
echo ""
echo "VPC_ID             = \"$VPC_ID\""
echo "ECS_CLUSTER_ID     = \"$ECS_CLUSTER_ID\""
echo "GRAFANA_IMAGE_URI  = \"$ACCOUNT_ID.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless\""
echo ""
echo "✏️  Copier ces valeurs dans terraform.tfvars"
echo ""
echo "Ou lancer ce script pour mettre à jour automatiquement :"
echo "  ./update-tfvars.sh"

