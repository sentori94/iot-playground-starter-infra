import json
import os
import boto3
import uuid
from datetime import datetime
import urllib3

# Clients AWS
dynamodb = boto3.resource('dynamodb')
secretsmanager = boto3.client('secretsmanager')

PROJECT = os.environ.get('PROJECT', 'iot-playground')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
AWS_REGION = os.environ.get('AWS_REGION', 'eu-west-3')
DEPLOYMENTS_TABLE = os.environ.get('DEPLOYMENTS_TABLE')
GITHUB_TOKEN_SECRET = os.environ.get('GITHUB_TOKEN_SECRET')
GITHUB_REPO_OWNER = os.environ.get('GITHUB_REPO_OWNER')
GITHUB_REPO_NAME = os.environ.get('GITHUB_REPO_NAME')
GITHUB_WORKFLOW_FILE = os.environ.get('GITHUB_WORKFLOW_FILE', 'bootstrap.yml')

# Table DynamoDB
table = dynamodb.Table(DEPLOYMENTS_TABLE)
http = urllib3.PoolManager()

def get_github_token():
    """Récupérer le GitHub token depuis Secrets Manager"""
    response = secretsmanager.get_secret_value(SecretId=GITHUB_TOKEN_SECRET)
    return json.loads(response['SecretString'])['token']

def trigger_github_workflow(token, mode, state_bucket_name, target_environment):
    """Déclencher le workflow GitHub Actions bootstrap.yml"""
    url = f'https://api.github.com/repos/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/actions/workflows/{GITHUB_WORKFLOW_FILE}/dispatches'

    headers = {
        'Authorization': f'token {token}',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'User-Agent': 'Lambda-Infrastructure-Manager'
    }

    payload = {
        'ref': 'main',  # ou 'master' selon votre branche
        'inputs': {
            'MODE': mode,
            'STATE_BUCKET_NAME': state_bucket_name,
            'CLEAN_SECRETS': 'false'
        }
    }

    response = http.request(
        'POST',
        url,
        body=json.dumps(payload).encode('utf-8'),
        headers=headers
    )

    return response.status, response.data

def lambda_handler(event, context):
    """
    Lambda pour créer l'infrastructure en déclenchant le workflow GitHub Actions bootstrap.yml
    """
    try:
        # Parser le body de la requête
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event

        # Paramètres
        deployment_id = str(uuid.uuid4())
        timestamp = int(datetime.utcnow().timestamp())
        target_environment = body.get('environment', ENVIRONMENT)
        requested_by = body.get('user', 'anonymous')
        state_bucket = body.get('state_bucket_name', os.environ.get('TERRAFORM_STATE_BUCKET', 'iot-playground-tfstate'))
        mode = body.get('mode', 'apply')  # plan ou apply

        # Récupérer le GitHub token
        try:
            github_token = get_github_token()
        except Exception as e:
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': f'Failed to retrieve GitHub token: {str(e)}',
                    'message': 'Make sure to store your GitHub PAT in Secrets Manager'
                })
            }

        # Créer l'entrée dans DynamoDB
        deployment_item = {
            'deployment_id': deployment_id,
            'environment': target_environment,
            'status': 'TRIGGERING',
            'terraform_action': mode,
            'requested_by': requested_by,
            'state_bucket': state_bucket,
            'created_at': timestamp,
            'updated_at': timestamp,
            'workflow_file': GITHUB_WORKFLOW_FILE,
            'ttl': timestamp + (30 * 24 * 60 * 60)  # Expire après 30 jours
        }

        table.put_item(Item=deployment_item)
        print(f"✅ Deployment {deployment_id} created in DynamoDB")

        # Déclencher le workflow GitHub Actions
        status_code, response_data = trigger_github_workflow(
            github_token,
            mode,
            state_bucket,
            target_environment
        )

        if status_code == 204:
            # Succès - le workflow a été déclenché
            table.update_item(
                Key={'deployment_id': deployment_id},
                UpdateExpression='SET #status = :status, updated_at = :timestamp',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'TRIGGERED',
                    ':timestamp': int(datetime.utcnow().timestamp())
                }
            )

            print(f"🚀 GitHub Actions workflow triggered successfully")

            response_body = {
                'success': True,
                'deployment_id': deployment_id,
                'status': 'TRIGGERED',
                'message': f'Infrastructure deployment triggered via GitHub Actions (bootstrap.yml)',
                'timestamp': datetime.utcnow().isoformat(),
                'mode': mode,
                'environment': target_environment,
                'check_status_url': f'/infra/status/{deployment_id}',
                'github_actions_url': f'https://github.com/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/actions'
            }

            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps(response_body)
            }
        else:
            # Erreur lors du déclenchement
            error_msg = response_data.decode('utf-8') if response_data else 'Unknown error'

            table.update_item(
                Key={'deployment_id': deployment_id},
                UpdateExpression='SET #status = :status, error_message = :error, updated_at = :timestamp',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'FAILED',
                    ':error': f'GitHub API error {status_code}: {error_msg}',
                    ':timestamp': int(datetime.utcnow().timestamp())
                }
            )

            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': f'Failed to trigger GitHub workflow (HTTP {status_code})',
                    'details': error_msg
                })
            }

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()

        # Si on a créé un deployment_id, mettre à jour le statut
        if 'deployment_id' in locals():
            try:
                table.update_item(
                    Key={'deployment_id': deployment_id},
                    UpdateExpression='SET #status = :status, error_message = :error, updated_at = :timestamp',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={
                        ':status': 'FAILED',
                        ':error': str(e),
                        ':timestamp': int(datetime.utcnow().timestamp())
                    }
                )
            except:
                pass

        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': str(e),
                'message': 'Failed to initiate infrastructure deployment'
            })
        }
