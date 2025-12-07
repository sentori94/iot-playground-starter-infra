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
AWS_REGION = os.environ.get('TARGET_AWS_REGION', 'eu-west-3')
DEPLOYMENTS_TABLE = os.environ.get('DEPLOYMENTS_TABLE')
GITHUB_TOKEN_SECRET = os.environ.get('GITHUB_TOKEN_SECRET')
GITHUB_REPO_OWNER = os.environ.get('GITHUB_REPO_OWNER')
GITHUB_REPO_NAME = os.environ.get('GITHUB_REPO_NAME')
GITHUB_WORKFLOW_FILE = os.environ.get('GITHUB_WORKFLOW_FILE', 'terraform-destroy.yml')

# Table DynamoDB
table = dynamodb.Table(DEPLOYMENTS_TABLE)
http = urllib3.PoolManager()

def get_github_token():
    """Récupérer le GitHub token depuis Secrets Manager"""
    response = secretsmanager.get_secret_value(SecretId=GITHUB_TOKEN_SECRET)
    return json.loads(response['SecretString'])['token']

def trigger_github_workflow(token, mode, state_bucket_name, target_environment):
    """Déclencher le workflow GitHub Actions terraform-destroy.yml via repository_dispatch"""
    url = f'https://api.github.com/repos/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/dispatches'

    headers = {
        'Authorization': f'token {token}',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'User-Agent': 'Lambda-Infrastructure-Manager'
    }

    payload = {
        'event_type': 'trigger-destroy',
        'client_payload': {
            'state_bucket_name': state_bucket_name,
            'environment': target_environment
        }
    }

    response = http.request(
        'POST',
        url,
        body=json.dumps(payload).encode('utf-8'),
        headers=headers
    )

    if response.status != 204:
        return response.status, response.data, None

    # ✅ Le workflow démarre automatiquement via repository_dispatch
    print(f"✅ Repository dispatch event 'trigger-destroy' sent successfully")

    # Pour repository_dispatch, on ne peut pas récupérer le workflow_run_id immédiatement
    # car GitHub ne retourne pas d'ID. On laisse le periodic_status_updater le récupérer.

    return response.status, response.data, None

def lambda_handler(event, context):
    """
    Lambda pour détruire l'infrastructure en déclenchant le workflow GitHub Actions terraform-destroy.yml
    """
    try:
        # Parser le body de la requête
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event

        # Paramètres
        destruction_id = str(uuid.uuid4())
        timestamp = int(datetime.utcnow().timestamp())
        target_environment = body.get('environment', ENVIRONMENT)
        requested_by = body.get('user', 'anonymous')
        confirmed = body.get('confirmed', False)
        reason = body.get('reason', 'User requested destruction')
        state_bucket = body.get('state_bucket_name', os.environ.get('TERRAFORM_STATE_BUCKET', 'iot-playground-tfstate'))

        # Confirmation requise pour les environnements de production
        if target_environment == 'prod' and not confirmed:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'Confirmation required for production environment',
                    'message': 'Please set "confirmed": true to destroy production infrastructure'
                })
            }

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
        destruction_item = {
            'deployment_id': destruction_id,
            'environment': target_environment,
            'status': 'TRIGGERING',
            'terraform_action': 'destroy',
            'requested_by': requested_by,
            'reason': reason,
            'confirmed': confirmed,
            'state_bucket': state_bucket,
            'created_at': timestamp,
            'updated_at': timestamp,
            'workflow_file': GITHUB_WORKFLOW_FILE,
            'ttl': timestamp + (30 * 24 * 60 * 60)  # Expire après 30 jours
        }

        table.put_item(Item=destruction_item)
        print(f"✅ Destruction {destruction_id} created in DynamoDB")

        # Déclencher le workflow GitHub Actions
        status_code, response_data, workflow_info = trigger_github_workflow(
            github_token,
            'destroy',
            state_bucket,
            target_environment
        )

        if status_code == 204:
            # Succès - le workflow a été déclenché
            update_expression = 'SET #status = :status, updated_at = :timestamp'
            expression_values = {
                ':status': 'TRIGGERED',
                ':timestamp': int(datetime.utcnow().timestamp())
            }

            table.update_item(
                Key={'deployment_id': destruction_id},
                UpdateExpression=update_expression,
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues=expression_values
            )

            print(f"🗑️ GitHub Actions destruction workflow triggered successfully")

            response_body = {
                'success': True,
                'destruction_id': destruction_id,
                'status': 'TRIGGERED',
                'message': f'Infrastructure destruction triggered via GitHub Actions for environment: {target_environment}',
                'timestamp': datetime.utcnow().isoformat(),
                'environment': target_environment,
                'warning': '⚠️ This action cannot be undone',
                'check_status_url': f'/infra/status/{destruction_id}',
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
                Key={'deployment_id': destruction_id},
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

        # Si on a créé un destruction_id, mettre à jour le statut
        if 'destruction_id' in locals():
            try:
                table.update_item(
                    Key={'deployment_id': destruction_id},
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
                'message': 'Failed to initiate infrastructure destruction'
            })
        }
