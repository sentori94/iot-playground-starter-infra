import json
import os
import boto3
from datetime import datetime
from decimal import Decimal
import urllib3

# Clients AWS
dynamodb = boto3.resource('dynamodb')
secretsmanager = boto3.client('secretsmanager')

PROJECT = os.environ.get('PROJECT', 'iot-playground')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
AWS_REGION = os.environ.get('TARGET_AWS_REGION', 'eu-west-3')
DEPLOYMENTS_TABLE = os.environ.get('DEPLOYMENTS_TABLE')
GITHUB_TOKEN_SECRET = os.environ.get('GITHUB_TOKEN_SECRET')
GITHUB_REPO_OWNER = os.environ.get('GITHUB_REPO_OWNER')
GITHUB_REPO_NAME = os.environ.get('GITHUB_REPO_NAME')

# Table DynamoDB
table = dynamodb.Table(DEPLOYMENTS_TABLE)
http = urllib3.PoolManager()

class DecimalEncoder(json.JSONEncoder):
    """Helper pour encoder les Decimal de DynamoDB en JSON"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super(DecimalEncoder, self).default(obj)

def get_github_token():
    """Récupérer le GitHub token depuis Secrets Manager"""
    response = secretsmanager.get_secret_value(SecretId=GITHUB_TOKEN_SECRET)
    return json.loads(response['SecretString'])['token']

def get_workflow_runs(token, limit=10):
    """Récupérer les derniers workflow runs"""
    url = f'https://api.github.com/repos/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/actions/runs?per_page={limit}'

    headers = {
        'Authorization': f'token {token}',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'Lambda-Infrastructure-Manager'
    }

    response = http.request('GET', url, headers=headers)

    if response.status == 200:
        return json.loads(response.data.decode('utf-8'))
    return None

def lambda_handler(event, context):
    """
    Lambda pour vérifier l'état d'un déploiement d'infrastructure
    Lit depuis DynamoDB et vérifie le statut des GitHub Actions
    """
    try:
        # Récupérer le deployment_id depuis le path
        deployment_id = None

        if 'pathParameters' in event and event['pathParameters']:
            deployment_id = event['pathParameters'].get('deploymentId')
        elif 'deployment_id' in event:
            deployment_id = event['deployment_id']

        if not deployment_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'Missing deployment_id parameter'
                })
            }

        # Récupérer les données depuis DynamoDB
        try:
            response = table.get_item(Key={'deployment_id': deployment_id})
            if 'Item' not in response:
                return {
                    'statusCode': 404,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({
                        'success': False,
                        'error': f'Deployment {deployment_id} not found'
                    })
                }

            deployment_data = response['Item']
        except Exception as e:
            print(f"Error fetching from DynamoDB: {str(e)}")
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'Failed to fetch deployment data',
                    'details': str(e)
                })
            }

        # Vérifier l'état des workflows GitHub si on a déclenché récemment
        workflow_status = None
        try:
            github_token = get_github_token()
            workflow_runs = get_workflow_runs(github_token)

            if workflow_runs and 'workflow_runs' in workflow_runs:
                # Trouver le workflow le plus récent qui correspond à notre timestamp
                created_at = deployment_data.get('created_at')
                workflow_file = deployment_data.get('workflow_file', 'bootstrap.yml')

                for run in workflow_runs['workflow_runs']:
                    # Vérifier si c'est le bon workflow
                    if workflow_file in run['path']:
                        run_created = datetime.strptime(run['created_at'], '%Y-%m-%dT%H:%M:%SZ').timestamp()

                        # Si le run a été créé dans les 2 minutes après notre déploiement
                        if abs(run_created - created_at) < 120:
                            workflow_status = {
                                'id': run['id'],
                                'status': run['status'],  # queued, in_progress, completed
                                'conclusion': run.get('conclusion'),  # success, failure, cancelled
                                'html_url': run['html_url'],
                                'created_at': run['created_at'],
                                'updated_at': run['updated_at']
                            }

                            # Mettre à jour DynamoDB avec le workflow_run_id
                            if 'workflow_run_id' not in deployment_data:
                                table.update_item(
                                    Key={'deployment_id': deployment_id},
                                    UpdateExpression='SET workflow_run_id = :run_id, github_url = :url',
                                    ExpressionAttributeValues={
                                        ':run_id': run['id'],
                                        ':url': run['html_url']
                                    }
                                )

                            # Mettre à jour le statut dans DynamoDB si terminé
                            if run['status'] == 'completed':
                                new_status = 'COMPLETED' if run['conclusion'] == 'success' else 'FAILED'
                                if deployment_data.get('status') not in ['COMPLETED', 'FAILED']:
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
                            break
        except Exception as e:
            print(f"Error fetching GitHub workflow status: {str(e)}")
            workflow_status = {'error': str(e)}

        # Construire la réponse
        response_body = {
            'success': True,
            'deployment_id': deployment_id,
            'status': deployment_data.get('status', 'UNKNOWN'),
            'environment': deployment_data.get('environment'),
            'terraform_action': deployment_data.get('terraform_action'),
            'requested_by': deployment_data.get('requested_by'),
            'state_bucket': deployment_data.get('state_bucket'),
            'created_at': datetime.fromtimestamp(int(deployment_data['created_at'])).isoformat() if 'created_at' in deployment_data else None,
            'updated_at': datetime.fromtimestamp(int(deployment_data['updated_at'])).isoformat() if 'updated_at' in deployment_data else None,
            'completed_at': datetime.fromtimestamp(int(deployment_data['completed_at'])).isoformat() if 'completed_at' in deployment_data else None,
            'workflow_status': workflow_status,
            'github_url': deployment_data.get('github_url'),
            'error_message': deployment_data.get('error_message')
        }

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response_body, cls=DecimalEncoder)
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
                'message': 'Failed to check deployment status'
            })
        }
