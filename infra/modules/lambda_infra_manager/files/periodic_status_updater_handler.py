import json
import os
import boto3
import urllib3
from datetime import datetime
from decimal import Decimal
from boto3.dynamodb.conditions import Attr

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

def get_github_token():
    """Récupérer le GitHub token depuis Secrets Manager"""
    response = secretsmanager.get_secret_value(SecretId=GITHUB_TOKEN_SECRET)
    return json.loads(response['SecretString'])['token']

def update_deployment_status(deployment_id, workflow_run_id, github_token):
    """Mettre à jour le statut d'un déploiement en interrogeant GitHub"""
    try:
        # Interroger l'API GitHub
        url = f'https://api.github.com/repos/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/actions/runs/{workflow_run_id}'

        headers = {
            'Authorization': f'token {github_token}',
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'Lambda-Status-Updater'
        }

        response = http.request('GET', url, headers=headers)

        if response.status != 200:
            print(f"⚠️ Failed to fetch workflow {workflow_run_id}: HTTP {response.status}")
            return False

        run = json.loads(response.data.decode('utf-8'))

        current_github_status = run['status']
        conclusion = run.get('conclusion')

        print(f"  GitHub status: {current_github_status}, conclusion: {conclusion}")

        # Déterminer le nouveau statut
        if current_github_status == 'completed':
            if conclusion == 'success':
                new_status = 'SUCCESS'
            elif conclusion == 'cancelled':
                new_status = 'CANCELLED'
            else:
                new_status = 'FAILED'

            # Mettre à jour DynamoDB
            print(f"  ✅ Updating to {new_status}")
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
            return True

        elif current_github_status == 'in_progress':
            # Mettre à jour vers IN_PROGRESS
            print(f"  🔄 Updating to IN_PROGRESS")
            table.update_item(
                Key={'deployment_id': deployment_id},
                UpdateExpression='SET #status = :status, updated_at = :timestamp',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'IN_PROGRESS',
                    ':timestamp': int(datetime.utcnow().timestamp())
                }
            )
            return False  # Pas encore terminé

        return False  # Toujours en cours

    except Exception as e:
        print(f"❌ Error updating deployment {deployment_id}: {str(e)}")
        return False

def lambda_handler(event, context):
    """
    Lambda déclenchée périodiquement par EventBridge pour mettre à jour
    les statuts des déploiements actifs en interrogeant GitHub Actions
    """
    try:
        print("🔄 Starting periodic status update...")

        # Récupérer le GitHub token
        try:
            github_token = get_github_token()
        except Exception as e:
            print(f"❌ Failed to get GitHub token: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'success': False,
                    'error': 'Failed to retrieve GitHub token'
                })
            }

        # Scanner DynamoDB pour tous les déploiements actifs
        active_statuses = ['TRIGGERING', 'TRIGGERED', 'IN_PROGRESS']

        response = table.scan(
            FilterExpression=Attr('status').is_in(active_statuses)
        )

        active_deployments = response.get('Items', [])

        print(f"📊 Found {len(active_deployments)} active deployment(s)")

        if not active_deployments:
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'success': True,
                    'message': 'No active deployments to update',
                    'updated': 0
                })
            }

        updated_count = 0
        completed_count = 0

        for deployment in active_deployments:
            deployment_id = deployment['deployment_id']
            workflow_run_id = deployment.get('workflow_run_id')
            current_status = deployment.get('status')

            print(f"\n🔍 Checking deployment: {deployment_id}")
            print(f"  Current status: {current_status}")
            print(f"  Workflow run ID: {workflow_run_id}")

            if not workflow_run_id:
                print(f"  ⚠️ No workflow_run_id, skipping")
                continue

            # Mettre à jour le statut
            is_completed = update_deployment_status(deployment_id, workflow_run_id, github_token)

            updated_count += 1
            if is_completed:
                completed_count += 1

        print(f"\n✅ Status update complete: {updated_count} updated, {completed_count} completed")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'success': True,
                'message': 'Status update complete',
                'active_deployments': len(active_deployments),
                'updated': updated_count,
                'completed': completed_count
            })
        }

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()

        return {
            'statusCode': 500,
            'body': json.dumps({
                'success': False,
                'error': str(e),
                'message': 'Failed to update deployment statuses'
            })
        }

