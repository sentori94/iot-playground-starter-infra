import json
import os
import boto3
from datetime import datetime

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
    Lambda pour annuler/arrêter un déploiement en cours

    Cette fonction marque un déploiement comme CANCELLED dans DynamoDB.
    Note: Le workflow GitHub Actions continuera jusqu'à la fin, mais le statut
    sera marqué comme annulé pour l'interface utilisateur.

    Path Parameter:
    - deploymentId: ID du déploiement à annuler

    Body (optionnel):
    - reason: raison de l'annulation
    """
    try:
        # Récupérer le deployment_id depuis le path
        path_parameters = event.get('pathParameters') or {}
        deployment_id = path_parameters.get('deploymentId')

        if not deployment_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': 'deployment_id is required'
                })
            }

        # Parser le body pour récupérer la raison (optionnelle)
        body = {}
        if 'body' in event and event['body']:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']

        reason = body.get('reason', 'Cancelled by user')
        cancelled_by = body.get('user', 'unknown')

        print(f"🛑 Cancelling deployment: {deployment_id}")
        print(f"   Reason: {reason}")
        print(f"   Cancelled by: {cancelled_by}")

        # Vérifier que le déploiement existe
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

        deployment = response['Item']
        current_status = deployment.get('status')

        # Vérifier si le déploiement peut être annulé
        cancellable_statuses = ['TRIGGERING', 'TRIGGERED', 'IN_PROGRESS']

        if current_status not in cancellable_statuses:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'error': f'Cannot cancel deployment with status: {current_status}',
                    'message': 'Only deployments with status TRIGGERING, TRIGGERED, or IN_PROGRESS can be cancelled',
                    'current_status': current_status
                })
            }

        # Mettre à jour le statut en CANCELLED
        timestamp = int(datetime.utcnow().timestamp())

        table.update_item(
            Key={'deployment_id': deployment_id},
            UpdateExpression='SET #status = :status, updated_at = :timestamp, error_message = :error, cancelled_by = :cancelled_by, cancelled_at = :cancelled_at',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': 'CANCELLED',
                ':timestamp': timestamp,
                ':error': f'Cancelled: {reason}',
                ':cancelled_by': cancelled_by,
                ':cancelled_at': timestamp
            }
        )

        print(f"✅ Deployment {deployment_id} marked as CANCELLED")

        # Récupérer le déploiement mis à jour
        updated_response = table.get_item(Key={'deployment_id': deployment_id})
        updated_deployment = updated_response['Item']

        response_body = {
            'success': True,
            'message': 'Deployment cancelled successfully',
            'deployment': {
                'deployment_id': updated_deployment['deployment_id'],
                'status': updated_deployment['status'],
                'terraform_action': updated_deployment.get('terraform_action', 'unknown'),
                'environment': updated_deployment.get('environment', ENVIRONMENT),
                'requested_by': updated_deployment.get('requested_by', 'unknown'),
                'cancelled_by': updated_deployment.get('cancelled_by'),
                'cancelled_at': updated_deployment.get('cancelled_at'),
                'created_at': updated_deployment.get('created_at'),
                'updated_at': updated_deployment.get('updated_at'),
                'error_message': updated_deployment.get('error_message'),
                'previous_status': current_status
            },
            'note': 'The GitHub Actions workflow will continue to run, but the status is marked as cancelled.'
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
                'message': 'Failed to cancel deployment'
            })
        }

