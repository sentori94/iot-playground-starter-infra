import json
import os
import boto3
import urllib3
from datetime import datetime
from boto3.dynamodb.conditions import Attr
from decimal import Decimal

# Clients AWS
dynamodb = boto3.resource('dynamodb')
secretsmanager = boto3.client('secretsmanager')

PROJECT = os.environ.get('PROJECT', 'iot-playground')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
DEPLOYMENTS_TABLE = os.environ.get('DEPLOYMENTS_TABLE')
GITHUB_TOKEN_SECRET = os.environ.get('GITHUB_TOKEN_SECRET')
GITHUB_REPO_OWNER = os.environ.get('GITHUB_REPO_OWNER')
GITHUB_REPO_NAME = os.environ.get('GITHUB_REPO_NAME')

# Table DynamoDB
table = dynamodb.Table(DEPLOYMENTS_TABLE)
http = urllib3.PoolManager()

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

def get_github_token():
    """Récupérer le GitHub token depuis Secrets Manager"""
    try:
        response = secretsmanager.get_secret_value(SecretId=GITHUB_TOKEN_SECRET)
        secret_data = json.loads(response['SecretString'])
        token = secret_data.get('token')
        if not token:
            print(f"⚠️ Token field not found in secret")
            return None
        return token
    except Exception as e:
        print(f"⚠️ Failed to get GitHub token: {str(e)}")
        import traceback
        traceback.print_exc()
        return None

def check_and_update_github_status(deployment_data):
    """Vérifier et mettre à jour le statut depuis GitHub si le déploiement est actif"""
    try:
        deployment_id = deployment_data['deployment_id']
        current_status = deployment_data.get('status')
        workflow_run_id = deployment_data.get('workflow_run_id')

        # Si déjà terminé ou pas de workflow_run_id, ne pas vérifier
        if current_status in ['SUCCESS', 'FAILED', 'CANCELLED'] or not workflow_run_id:
            print(f"ℹ️ Deployment {deployment_id} status: {current_status}, workflow_run_id: {workflow_run_id} - No need to check GitHub")
            return deployment_data

        print(f"🔄 Checking GitHub status for active deployment {deployment_id} (workflow_run_id: {workflow_run_id})")

        # Récupérer le token GitHub
        github_token = get_github_token()
        if not github_token:
            print(f"⚠️ Cannot check GitHub status without token")
            return deployment_data

        # Interroger l'API GitHub
        url = f'https://api.github.com/repos/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/actions/runs/{workflow_run_id}'

        headers = {
            'Authorization': f'token {github_token}',
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'Lambda-Infrastructure-Manager'
        }

        print(f"📡 Calling GitHub API: {url}")
        response = http.request('GET', url, headers=headers, timeout=10.0)

        if response.status != 200:
            print(f"⚠️ Failed to fetch workflow: HTTP {response.status}")
            print(f"Response body: {response.data.decode('utf-8')[:500]}")
            return deployment_data

        run = json.loads(response.data.decode('utf-8'))
        github_status = run.get('status')
        conclusion = run.get('conclusion')

        print(f"📊 GitHub status: {github_status}, conclusion: {conclusion}")

        # Déterminer le nouveau statut
        new_status = None

        if github_status == 'completed':
            if conclusion == 'success':
                new_status = 'SUCCESS'
            elif conclusion == 'cancelled':
                new_status = 'CANCELLED'
            else:
                new_status = 'FAILED'

            # Mettre à jour DynamoDB
            print(f"✅ Updating deployment {deployment_id} to {new_status}")
            table.update_item(
                Key={'deployment_id': deployment_id},
                UpdateExpression='SET #status = :status, updated_at = :timestamp, completed_at = :completed',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': new_status,
                    ':timestamp': int(datetime.utcnow().timestamp()),
                    ':completed': int(datetime.utcnow().timestamp())
                }
            )
            deployment_data['status'] = new_status
            deployment_data['completed_at'] = int(datetime.utcnow().timestamp())

        elif github_status == 'in_progress' and current_status != 'IN_PROGRESS':
            new_status = 'IN_PROGRESS'
            print(f"🔄 Updating deployment {deployment_id} to IN_PROGRESS")
            table.update_item(
                Key={'deployment_id': deployment_id},
                UpdateExpression='SET #status = :status, updated_at = :timestamp',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'IN_PROGRESS',
                    ':timestamp': int(datetime.utcnow().timestamp())
                }
            )
            deployment_data['status'] = 'IN_PROGRESS'

        elif github_status == 'queued' and current_status == 'TRIGGERED':
            # Le workflow est en queue, on garde TRIGGERED
            print(f"ℹ️ Deployment {deployment_id} is queued in GitHub")

        else:
            print(f"ℹ️ No status update needed. GitHub: {github_status}, Current: {current_status}")

        return deployment_data

    except Exception as e:
        print(f"⚠️ Error checking GitHub status: {str(e)}")
        import traceback
        traceback.print_exc()
        return deployment_data

def lambda_handler(event, context):
    """
    Lambda pour récupérer le dernier déploiement en cours ou le plus récent

    Cette fonction est utile pour le frontend afin de:
    - Vérifier s'il y a un déploiement en cours
    - Afficher le statut actuel sur l'interface
    - Permettre le polling du statut
    - Mettre à jour le statut depuis GitHub si le déploiement est actif

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

            # Vérifier et mettre à jour le statut depuis GitHub
            latest_deployment = check_and_update_github_status(latest_deployment)
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
            if latest_deployment.get('workflow_run_id'):
                deployment_info['workflow_run_url'] = f'https://github.com/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/actions/runs/{latest_deployment["workflow_run_id"]}'

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
