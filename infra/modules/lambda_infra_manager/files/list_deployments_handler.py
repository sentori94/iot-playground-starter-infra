import json
import os
import boto3
from datetime import datetime
from boto3.dynamodb.conditions import Attr, Key
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

def lambda_handler(event, context):
    """
    Lambda pour lister tous les déploiements avec filtres optionnels

    Query Parameters optionnels:
    - status: filtrer par statut (TRIGGERING, TRIGGERED, IN_PROGRESS, SUCCESS, FAILED)
    - limit: nombre maximum de résultats (défaut: 50)
    - active_only: true/false - afficher uniquement les déploiements actifs

    Exemple: GET /infra/deployments?active_only=true&limit=10
    """
    try:
        # Récupérer les query parameters
        query_params = event.get('queryStringParameters') or {}
        status_filter = query_params.get('status')
        limit = int(query_params.get('limit', 50))
        active_only = query_params.get('active_only', '').lower() == 'true'

        print(f"🔍 Listing deployments from table: {DEPLOYMENTS_TABLE}")
        print(f"   Filters: status={status_filter}, limit={limit}, active_only={active_only}")

        # Préparer le scan
        scan_kwargs = {
            'Limit': min(limit, 100)  # Maximum 100 pour éviter les abus
        }

        # Filtrer par statut si spécifié
        if status_filter:
            scan_kwargs['FilterExpression'] = Attr('status').eq(status_filter)
        elif active_only:
            # Filtrer uniquement les déploiements actifs
            active_statuses = ['TRIGGERING', 'TRIGGERED', 'IN_PROGRESS']
            scan_kwargs['FilterExpression'] = Attr('status').is_in(active_statuses)

        # Scanner la table
        response = table.scan(**scan_kwargs)
        deployments = response.get('Items', [])

        print(f"✅ Found {len(deployments)} deployment(s)")

        # Trier par created_at décroissant (plus récent en premier)
        deployments.sort(key=lambda x: x.get('created_at', 0), reverse=True)

        # Formatter les déploiements pour la réponse
        formatted_deployments = []
        for deployment in deployments:
            deployment_info = {
                'deployment_id': deployment['deployment_id'],
                'status': deployment['status'],
                'terraform_action': deployment.get('terraform_action', 'unknown'),
                'environment': deployment.get('environment', ENVIRONMENT),
                'requested_by': deployment.get('requested_by', 'unknown'),
                'state_bucket': deployment.get('state_bucket', 'N/A'),
                'created_at': int(deployment.get('created_at', 0)),
                'updated_at': int(deployment.get('updated_at', 0)),
                'workflow_file': deployment.get('workflow_file', 'bootstrap.yml'),
                'error_message': deployment.get('error_message', None)
            }

            # Calculer la durée si terminé
            if deployment['status'] in ['SUCCESS', 'FAILED', 'CANCELLED']:
                duration = int(deployment.get('updated_at', 0)) - int(deployment.get('created_at', 0))
                deployment_info['duration_seconds'] = duration

            # Ajouter un flag is_active
            deployment_info['is_active'] = deployment['status'] in ['TRIGGERING', 'TRIGGERED', 'IN_PROGRESS']

            formatted_deployments.append(deployment_info)

        # Statistiques
        total_count = len(formatted_deployments)
        active_count = sum(1 for d in formatted_deployments if d['is_active'])
        completed_count = sum(1 for d in formatted_deployments if d['status'] in ['SUCCESS', 'FAILED'])

        response_body = {
            'success': True,
            'deployments': formatted_deployments,
            'count': total_count,
            'statistics': {
                'total': total_count,
                'active': active_count,
                'completed': completed_count,
                'success': sum(1 for d in formatted_deployments if d['status'] == 'SUCCESS'),
                'failed': sum(1 for d in formatted_deployments if d['status'] == 'FAILED')
            },
            'github_actions_url': f'https://github.com/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/actions' if GITHUB_REPO_OWNER and GITHUB_REPO_NAME else None
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
                'message': 'Failed to list deployments'
            })
        }
