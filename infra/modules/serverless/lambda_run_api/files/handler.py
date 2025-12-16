import json
import boto3
import os
from datetime import datetime
from decimal import Decimal
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
cloudwatch = boto3.client('cloudwatch')

TABLE_NAME = os.environ['RUNS_TABLE_NAME']
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    """
    Handler pour les endpoints Run API:
    - GET /api/runs (avec pagination)
    - GET /api/runs/{id}
    - GET /api/runs/all
    """

    http_method = event.get('httpMethod', '')
    path = event.get('path', '')
    path_params = event.get('pathParameters') or {}
    query_params = event.get('queryStringParameters') or {}

    # Log de la requête entrante
    print(f"[RUN-API] {http_method} {path} - Query: {query_params}")

    try:
        # GET /api/runs/{id}
        if http_method == 'GET' and path_params.get('id'):
            run_id = path_params['id']
            print(f"[RUN-API] Fetching run: {run_id}")
            return get_run_by_id(run_id)

        # GET /api/runs/all
        elif http_method == 'GET' and 'all' in path:
            print(f"[RUN-API] Fetching all runs")
            return get_all_runs()

        # GET /api/runs (avec pagination)
        elif http_method == 'GET':
            limit = query_params.get('limit', 20)
            print(f"[RUN-API] Listing runs (limit: {limit})")
            return list_runs_paginated(query_params)

        else:
            print(f"[RUN-API] Method not allowed: {http_method} {path}")
            return response(405, {'error': 'Method not allowed'})

    except Exception as e:
        print(f"[RUN-API] ERROR: {str(e)}")
        return response(500, {'error': 'Internal server error', 'details': str(e)})


def get_run_by_id(run_id):
    """Récupère un run par son ID (UUID)"""
    result = table.get_item(Key={'id': run_id})

    if 'Item' not in result:
        print(f"[RUN-API] Run not found: {run_id}")
        return response(404, {'error': 'Run not found'})

    item = convert_decimals(result['Item'])
    print(f"[RUN-API] Run retrieved: {run_id} - Status: {item.get('status')}")
    return response(200, item)


def get_all_runs():
    """Récupère tous les runs triés par startedAt DESC"""
    # Scan avec tri en mémoire (pour small datasets)
    # Pour production avec beaucoup de données, utiliser le GSI startedAt-index
    result = table.scan()
    items = result.get('Items', [])

    # Tri par startedAt décroissant
    items.sort(key=lambda x: x.get('startedAt', ''), reverse=True)

    items = [convert_decimals(item) for item in items]
    print(f"[RUN-API] Retrieved {len(items)} runs")
    return response(200, items)


def list_runs_paginated(query_params):
    """
    Liste paginée des runs
    Query params:
    - limit: nombre d'items par page (défaut: 20)
    - lastKey: clé de pagination (base64 encoded)
    """
    limit = int(query_params.get('limit', 20))
    last_key = query_params.get('lastKey')

    scan_kwargs = {
        'Limit': limit
    }

    if last_key:
        # Décoder la clé de pagination
        import base64
        scan_kwargs['ExclusiveStartKey'] = json.loads(base64.b64decode(last_key))

    result = table.scan(**scan_kwargs)
    items = result.get('Items', [])

    # Tri par startedAt décroissant
    items.sort(key=lambda x: x.get('startedAt', ''), reverse=True)

    items = [convert_decimals(item) for item in items]

    response_data = {
        'items': items,
        'count': len(items)
    }

    # Ajouter la clé de pagination si présente
    if 'LastEvaluatedKey' in result:
        import base64
        next_key = base64.b64encode(json.dumps(result['LastEvaluatedKey']).encode()).decode()
        response_data['nextKey'] = next_key
        print(f"[RUN-API] Paginated response: {len(items)} items, has next page")
    else:
        print(f"[RUN-API] Paginated response: {len(items)} items, last page")

    return response(200, response_data)


def convert_decimals(obj):
    """Convertit les Decimal de DynamoDB en float pour JSON"""
    if isinstance(obj, list):
        return [convert_decimals(i) for i in obj]
    elif isinstance(obj, dict):
        return {k: convert_decimals(v) for k, v in obj.items()}
    elif isinstance(obj, Decimal):
        return float(obj) if obj % 1 else int(obj)
    else:
        return obj


def response(status_code, body):
    """Retourne une réponse HTTP avec CORS"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-User,X-Run-Id',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps(body, default=str)
    }

