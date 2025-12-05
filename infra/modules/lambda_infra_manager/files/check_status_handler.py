import json
import os
import boto3
import urllib3
from datetime import datetime
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

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super(DecimalEncoder, self).default(obj)

def get_github_token():
    """Récupérer le GitHub token depuis Secrets Manager"""
    response = secretsmanager.get_secret_value(SecretId=GITHUB_TOKEN_SECRET)
    return json.loads(response['SecretString'])['token']

def get_workflow_runs(token, workflow_file, limit=20):
    """Récupérer les derniers workflow runs pour un fichier spécifique"""
    # Extraire le nom du workflow sans extension
    workflow_name = workflow_file.replace('.yml', '').replace('.yaml', '')

    url = f'https://api.github.com/repos/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/actions/runs?per_page={limit}'

    headers = {
        'Authorization': f'token {token}',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'Lambda-Infrastructure-Manager'
    }

    response = http.request('GET', url, headers=headers)

    if response.status == 200:
        data = json.loads(response.data.decode('utf-8'))
        # Filtrer par fichier workflow
        filtered_runs = []
        for run in data.get('workflow_runs', []):
            if workflow_file in run.get('path', '') or workflow_name in run.get('name', ''):
                filtered_runs.append(run)
        return filtered_runs
    return []

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

        print(f"🔍 Checking status for deployment: {deployment_id}")

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
                        'error': 'Deployment not found',
                        'deployment_id': deployment_id
                    })
                }

            deployment_data = response['Item']
            current_status = deployment_data.get('status')

            print(f"📊 Current status in DynamoDB: {current_status}")

        except Exception as e:
            print(f"❌ Error fetching from DynamoDB: {str(e)}")
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

        # Si déjà terminé (SUCCESS, FAILED, CANCELLED), ne pas vérifier GitHub
        if current_status in ['SUCCESS', 'FAILED', 'CANCELLED']:
            print(f"✅ Deployment already in final state: {current_status}")
            return build_response(deployment_data, None)

        # Vérifier l'état des workflows GitHub
        workflow_status = None
        try:
            # Si on a déjà le workflow_run_id, interroger directement l'API GitHub
            workflow_run_id = deployment_data.get('workflow_run_id')

            if workflow_run_id:
                print(f"🎯 Direct query for workflow_run_id: {workflow_run_id}")
                github_token = get_github_token()

                # Interroger directement le run spécifique
                url = f'https://api.github.com/repos/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/actions/runs/{workflow_run_id}'

                headers = {
                    'Authorization': f'token {github_token}',
                    'Accept': 'application/vnd.github.v3+json',
                    'User-Agent': 'Lambda-Infrastructure-Manager'
                }

                response = http.request('GET', url, headers=headers)

                if response.status == 200:
                    run = json.loads(response.data.decode('utf-8'))

                    workflow_status = {
                        'id': run['id'],
                        'status': run['status'],
                        'conclusion': run.get('conclusion'),
                        'html_url': run['html_url'],
                        'created_at': run['created_at'],
                        'updated_at': run['updated_at']
                    }

                    print(f"📊 Workflow status: {run['status']}, conclusion: {run.get('conclusion')}")

                    # Mettre à jour le statut si le workflow est terminé
                    if run['status'] == 'completed':
                        conclusion = run.get('conclusion')

                        if conclusion == 'success':
                            new_status = 'SUCCESS'
                        elif conclusion == 'cancelled':
                            new_status = 'CANCELLED'
                        else:
                            new_status = 'FAILED'

                        print(f"🔄 Updating status from {current_status} to {new_status}")

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

                    elif run['status'] == 'in_progress' and current_status == 'TRIGGERED':
                        print(f"🔄 Updating status from TRIGGERED to IN_PROGRESS")
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
                else:
                    print(f"⚠️ Failed to fetch workflow run: HTTP {response.status}")

            else:
                # Fallback: ancienne logique avec matching par timestamp (pour compatibilité)
                print(f"⚠️ No workflow_run_id found, falling back to timestamp matching")
                github_token = get_github_token()
                workflow_file = deployment_data.get('workflow_file', 'bootstrap.yml')
                created_at = int(deployment_data.get('created_at', 0))

                print(f"🔎 Searching for workflow: {workflow_file}")
                print(f"📅 Deployment created at: {created_at} ({datetime.fromtimestamp(created_at).isoformat()})")

                workflow_runs = get_workflow_runs(github_token, workflow_file)
                print(f"📋 Found {len(workflow_runs)} workflow runs")

                # Chercher le workflow correspondant
                matched_run = None
                best_time_diff = float('inf')

                for run in workflow_runs:
                    # Parser la date du workflow
                    run_created_str = run.get('created_at', '')
                    try:
                        run_created = datetime.strptime(run_created_str, '%Y-%m-%dT%H:%M:%SZ').timestamp()
                    except:
                        continue

                    # Calculer la différence de temps (en secondes)
                    time_diff = abs(run_created - created_at)

                    print(f"  Run {run['id']}: created={run_created_str}, diff={time_diff}s, status={run['status']}")

                    # Prendre le run le plus proche dans une fenêtre de 10 minutes
                    if time_diff < 600 and time_diff < best_time_diff:  # 10 minutes au lieu de 2
                        matched_run = run
                        best_time_diff = time_diff

                if matched_run:
                    print(f"✅ Matched workflow run: {matched_run['id']} (diff: {best_time_diff}s)")

                    workflow_status = {
                        'id': matched_run['id'],
                        'status': matched_run['status'],
                        'conclusion': matched_run.get('conclusion'),
                        'html_url': matched_run['html_url'],
                        'created_at': matched_run['created_at'],
                        'updated_at': matched_run['updated_at']
                    }

                    # Sauvegarder le workflow_run_id pour les prochaines fois
                    print(f"💾 Saving workflow_run_id to DynamoDB")
                    table.update_item(
                        Key={'deployment_id': deployment_id},
                        UpdateExpression='SET workflow_run_id = :run_id, github_url = :url, updated_at = :timestamp',
                        ExpressionAttributeValues={
                            ':run_id': matched_run['id'],
                            ':url': matched_run['html_url'],
                            ':timestamp': int(datetime.utcnow().timestamp())
                        }
                    )
                    deployment_data['workflow_run_id'] = matched_run['id']
                    deployment_data['github_url'] = matched_run['html_url']

                    # Mettre à jour le statut
                    if matched_run['status'] == 'completed':
                        conclusion = matched_run.get('conclusion')

                        if conclusion == 'success':
                            new_status = 'SUCCESS'
                        elif conclusion == 'cancelled':
                            new_status = 'CANCELLED'
                        else:
                            new_status = 'FAILED'

                        print(f"🔄 Updating status from {current_status} to {new_status}")

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

                    elif matched_run['status'] == 'in_progress' and current_status == 'TRIGGERED':
                        print(f"🔄 Updating status from TRIGGERED to IN_PROGRESS")
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
                else:
                    print(f"⚠️ No matching workflow run found within 10 minutes window")

        except Exception as e:
            print(f"❌ Error checking GitHub workflow status: {str(e)}")
            import traceback
            traceback.print_exc()
            workflow_status = {'error': str(e)}

        return build_response(deployment_data, workflow_status)

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

def build_response(deployment_data, workflow_status):
    """Construire la réponse JSON"""
    response_body = {
        'success': True,
        'deployment_id': deployment_data['deployment_id'],
        'status': deployment_data.get('status', 'UNKNOWN'),
        'environment': deployment_data.get('environment'),
        'terraform_action': deployment_data.get('terraform_action'),
        'requested_by': deployment_data.get('requested_by'),
        'state_bucket': deployment_data.get('state_bucket'),
        'workflow_file': deployment_data.get('workflow_file'),
        'created_at': int(deployment_data.get('created_at', 0)),
        'updated_at': int(deployment_data.get('updated_at', 0)),
        'completed_at': int(deployment_data.get('completed_at', 0)) if 'completed_at' in deployment_data else None,
        'workflow_run_id': deployment_data.get('workflow_run_id'),
        'github_url': deployment_data.get('github_url'),
        'error_message': deployment_data.get('error_message')
    }

    if workflow_status:
        response_body['workflow_status'] = workflow_status

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(response_body, cls=DecimalEncoder)
    }
