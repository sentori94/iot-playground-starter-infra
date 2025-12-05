import json
import os
import boto3
from datetime import datetime
from boto3.dynamodb.conditions import Attr
from decimal import Decimal

# Clients AWS
dynamodb = boto3.resource('dynamodb')

PROJECT = os.environ.get('PROJECT', 'iot-playground')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
DEPLOYMENTS_TABLE = os.environ.get('DEPLOYMENTS_TABLE')
GITHUB_REPO_OWNER = os.environ.get('GITHUB_REPO_OWNER')
GITHUB_REPO_NAME = os.environ.get('GITHUB_REPO_NAME')

# Table DynamoDB
table = dynamodb.Table(DEPLOYMENTS_TABLE)

def decimal_to_int(obj):
    """Convertir les Decimal de DynamoDB en int pour la sérialisation JSON"""
    if isinstance(obj, list):
        return [decimal_to_int(i) for i in obj]
    elif isinstance(obj, dict):
        return {k: decimal_to_int(v) for k, v in obj.items()}
    elif isinstance(obj, Decimal):
        return int(obj)
    else:
        return obj

def lambda_handler(event, context):
    """
    Lambda pour récupérer le dernier déploiement en cours ou le plus récent

    Cette fonction est utile pour le frontend afin de:
    - Vérifier s'il y a un déploiement en cours
    - Afficher le statut actuel sur l'interface
    - Permettre le polling du statut

    Retourne le dernier déploiement (en priorité IN_PROGRESS, TRIGGERED, TRIGGERING)
    """
    try:
        # Scanner la table pour trouver le dernier déploiement
        # On cherche d'abord les déploiements actifs (TRIGGERING, TRIGGERED, IN_PROGRESS)
        active_statuses = ['TRIGGERING', 'TRIGGERED', 'IN_PROGRESS']

        print(f"🔍 Searching for latest deployment in table: {DEPLOYMENTS_TABLE}")

        # Scan avec filtre sur les statuts actifs
        response = table.scan(
            FilterExpression=Attr('status').is_in(active_statuses)
        )

        active_deployments = response.get('Items', [])

        # Si on a des déploiements actifs, prendre le plus récent
        if active_deployments:
            # Trier par created_at décroissant
            active_deployments.sort(key=lambda x: x.get('created_at', 0), reverse=True)
            latest_deployment = active_deployments[0]
            print(f"✅ Found active deployment: {latest_deployment['deployment_id']}")
        else:
            # Sinon, chercher le dernier déploiement terminé (SUCCESS ou FAILED)
            print("ℹ️ No active deployment found, searching for latest completed...")

            response = table.scan()
            all_deployments = response.get('Items', [])

            if not all_deployments:
                # Aucun déploiement trouvé
                return {
                    'statusCode': 200,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({
                        'success': True,
                        'deployment': None,
                        'message': 'No deployments found'
                    })
                }

            # Trier tous les déploiements par created_at décroissant
            all_deployments.sort(key=lambda x: x.get('created_at', 0), reverse=True)
            latest_deployment = all_deployments[0]
            print(f"ℹ️ Found latest completed deployment: {latest_deployment['deployment_id']}")

        # Construire la réponse
        deployment_info = {
            'deployment_id': latest_deployment['deployment_id'],
            'status': latest_deployment['status'],
            'terraform_action': latest_deployment.get('terraform_action', 'unknown'),
            'environment': latest_deployment.get('environment', ENVIRONMENT),
            'requested_by': latest_deployment.get('requested_by', 'unknown'),
            'state_bucket': latest_deployment.get('state_bucket', 'N/A'),
            'created_at': int(latest_deployment.get('created_at', 0)),
            'updated_at': int(latest_deployment.get('updated_at', 0)),
            'workflow_file': latest_deployment.get('workflow_file', 'bootstrap.yml'),
            'error_message': latest_deployment.get('error_message', None)
        }

        # Ajouter l'URL GitHub Actions si disponible
        if GITHUB_REPO_OWNER and GITHUB_REPO_NAME:
            deployment_info['github_actions_url'] = f'https://github.com/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/actions'

        # Calculer la durée si le déploiement est terminé
        if latest_deployment['status'] in ['SUCCESS', 'FAILED', 'CANCELLED']:
            duration = int(latest_deployment.get('updated_at', 0)) - int(latest_deployment.get('created_at', 0))
            deployment_info['duration_seconds'] = duration

        response_body = {
            'success': True,
            'deployment': deployment_info,
            'is_active': latest_deployment['status'] in active_statuses
        }

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response_body)
        }

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()

        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': str(e),
                'message': 'Failed to retrieve latest deployment'
            })
        }
