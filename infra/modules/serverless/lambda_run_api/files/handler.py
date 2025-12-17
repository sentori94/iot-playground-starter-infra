import json
import boto3
import os
from datetime import datetime
from decimal import Decimal
from boto3.dynamodb.conditions import Key, Attr

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
    - GET /api/runs/running (runs en cours)
    - GET /api/runs/can-start (vérifier si on peut démarrer)
    - POST /api/runs/start (démarrer un run)
    - POST /api/runs/interrupt-all (interrompre tous les runs)
    - POST /api/runs/{id}/finish (terminer un run)
    """

    http_method = event.get('httpMethod', '')
    path = event.get('path', '')
    path_params = event.get('pathParameters') or {}
    query_params = event.get('queryStringParameters') or {}

    # Log de la requête entrante
    print(f"[RUN-API] {http_method} {path} - Query: {query_params}")

    try:
        # Routes spécifiques d'abord (avant {id})

        # GET /api/runs/can-start
        if http_method == 'GET' and 'can-start' in path:
            return can_start_simulation(event)

        # GET /api/runs/running
        elif http_method == 'GET' and 'running' in path:
            return get_running_simulations(event)

        # GET /api/runs/all
        elif http_method == 'GET' and 'all' in path:
            print(f"[RUN-API] Fetching all runs")
            return get_all_runs()

        # POST /api/runs/interrupt-all
        elif http_method == 'POST' and 'interrupt-all' in path:
            return interrupt_all_runs(event)

        # POST /api/runs/start
        elif http_method == 'POST' and 'start' in path:
            return start_run(event)

        # POST /api/runs/{id}/finish
        elif http_method == 'POST' and path_params.get('id') and 'finish' in path:
            run_id = path_params['id']
            return finish_run(run_id, event)

        # GET /api/runs/{id} (après toutes les routes spécifiques)
        elif http_method == 'GET' and path_params.get('id'):
            run_id = path_params['id']
            print(f"[RUN-API] Fetching run: {run_id}")
            return get_run_by_id(run_id)


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
        import traceback
        traceback.print_exc()
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


def can_start_simulation(event):
    """
    GET /api/runs/can-start
    Vérifie si on peut démarrer une nouvelle simulation
    Limite: 5 runs en cours maximum GLOBAUX (tous utilisateurs confondus)
    """
    print(f"[RUN-API] can-start: Checking global running simulations")

    # Compter TOUS les runs en cours (tous utilisateurs)
    try:
        result = table.scan(
            FilterExpression=Attr('status').eq('RUNNING')
        )

        items = result.get('Items', [])
        running_count = len(items)

        print(f"[RUN-API] can-start: Found {running_count} RUNNING items (ALL users)")

        # Log les IDs des runs trouvés pour debug
        if running_count > 0:
            run_ids = [item.get('id', 'no-id') for item in items]
            users = [item.get('username', 'no-user') for item in items]
            print(f"[RUN-API] can-start: Running run IDs: {run_ids}")
            print(f"[RUN-API] can-start: Users: {users}")

    except Exception as e:
        print(f"[RUN-API] can-start: ERROR scanning DynamoDB: {str(e)}")
        # En cas d'erreur, on retourne une réponse safe
        running_count = 0

    max_concurrent_runs = 5  # Limite GLOBALE (Spring Boot par défaut: 5)
    can_start = running_count < max_concurrent_runs
    available = max(0, max_concurrent_runs - running_count)

    print(f"[RUN-API] can-start: Result - canStart={can_start}, currentRunning={running_count}, maxAllowed={max_concurrent_runs}, available={available}")

    # Match exact du modèle Java CanStartRunResponse
    return response(200, {
        'canStart': can_start,
        'currentRunning': running_count,
        'maxAllowed': max_concurrent_runs,
        'available': available
    })


def start_run(event):
    """
    POST /api/runs/start
    Démarre une nouvelle simulation
    Body: { "params": {...} }
    """
    headers = event.get('headers', {})
    user = headers.get('x-user') or headers.get('X-User') or 'unknown'
    if not user or user.strip() == '':
        user = 'unknown'

    try:
        body = json.loads(event.get('body', '{}'))
    except json.JSONDecodeError:
        return response(400, {'error': 'Invalid JSON body'})

    # Vérifier si l'utilisateur peut démarrer une nouvelle simulation
    can_start_response = can_start_simulation(event)
    can_start_data = json.loads(can_start_response['body'])

    if not can_start_data['canStart']:
        print(f"[RUN-API] User '{user}' cannot start simulation (limit reached)")
        return response(400, {
            'error': 'Maximum concurrent runs reached',
            'currentRunning': can_start_data['currentRunning'],
            'maxAllowed': can_start_data['maxAllowed']
        })

    # Générer un ID unique pour le run
    import uuid
    run_id = str(uuid.uuid4())
    started_at = datetime.utcnow().isoformat() + 'Z'

    # Extraire les paramètres du body
    # Le body peut contenir soit { "duration": 60, "interval": 5 }
    # soit { "params": { "duration": 60, "interval": 5 } }
    params = body.get('params', body)  # Si params n'existe pas, utiliser body directement
    duration = params.get('duration', 60)  # Défaut: 60 secondes
    interval = params.get('interval', 5)   # Défaut: 5 secondes

    print(f"[RUN-API] Body received: {json.dumps(body)}")
    print(f"[RUN-API] Extracted params: duration={duration}, interval={interval}")

    # Créer le run dans DynamoDB
    grafana_base_url = os.environ.get('GRAFANA_URL', 'http://localhost:3000')

    item = {
        'id': run_id,
        'username': user,
        'status': 'RUNNING',
        'startedAt': started_at,
        'duration': duration,
        'interval': interval,
        'params': params,  # Stocker l'objet params complet
        'grafanaUrl': f'{grafana_base_url}/d/iot-serverless-cloudwatch/iot-serverless-sensor-monitoring-cloudwatch?orgId=1&from=now-3h&to=now&refresh=5s&var-SensorId=All&var-User=All&var-RunId={run_id}'
    }

    table.put_item(Item=item)

    print(f"[RUN-API] Run started: {run_id} by user '{user}' (duration={duration}s, interval={interval}s)")

    return response(201, convert_decimals(item))


def finish_run(run_id, event):
    """
    POST /api/runs/{id}/finish
    Termine un run en cours
    Body (optionnel): { "errorMessage": "..." }
    """
    print(f"[RUN-API] Finishing run: {run_id}")

    # Vérifier si le run existe
    result = table.get_item(Key={'id': run_id})

    if 'Item' not in result:
        print(f"[RUN-API] Run not found: {run_id}")
        return response(404, {'error': 'Run not found'})

    run = result['Item']

    # Vérifier si le run est déjà terminé
    if run.get('status') != 'RUNNING':
        print(f"[RUN-API] Run already finished: {run_id}")
        return response(400, {'error': 'Run is not running'})

    # Parser le body pour récupérer l'éventuel message d'erreur
    error_message = None
    try:
        body = json.loads(event.get('body', '{}'))
        error_message = body.get('errorMessage')
    except:
        pass

    finished_at = datetime.utcnow().isoformat() + 'Z'

    # Mettre à jour le run
    update_expression = 'SET #s = :status, finishedAt = :finished_at'
    expression_values = {
        ':status': 'FAILED' if error_message else 'COMPLETED',
        ':finished_at': finished_at
    }
    expression_names = {'#s': 'status'}

    if error_message:
        update_expression += ', errorMessage = :error_message'
        expression_values[':error_message'] = error_message

    table.update_item(
        Key={'id': run_id},
        UpdateExpression=update_expression,
        ExpressionAttributeNames=expression_names,
        ExpressionAttributeValues=expression_values
    )

    print(f"[RUN-API] Run finished: {run_id} - Status: {'FAILED' if error_message else 'COMPLETED'}")

    # Récupérer le run mis à jour
    updated_result = table.get_item(Key={'id': run_id})
    updated_item = convert_decimals(updated_result['Item'])

    return response(200, updated_item)


def get_running_simulations(event):
    """
    GET /api/runs/running
    Récupère TOUS les runs en cours (tous utilisateurs confondus)
    """
    print(f"[RUN-API] Fetching running simulations (ALL users)")

    # Scanner pour récupérer TOUS les runs RUNNING
    result = table.scan(
        FilterExpression=Attr('status').eq('RUNNING')
    )

    items = result.get('Items', [])

    # Tri par startedAt décroissant
    items.sort(key=lambda x: x.get('startedAt', ''), reverse=True)

    items = [convert_decimals(item) for item in items]

    print(f"[RUN-API] Found {len(items)} running simulations (ALL users)")

    return response(200, items)


def interrupt_all_runs(event):
    """
    POST /api/runs/interrupt-all
    Interrompt TOUS les runs en cours (tous utilisateurs confondus)
    """
    print(f"[RUN-API] Interrupting ALL running simulations (ALL users)")

    # Récupérer TOUS les runs RUNNING (tous utilisateurs)
    try:
        result = table.scan(
            FilterExpression=Attr('status').eq('RUNNING')
        )
    except Exception as e:
        print(f"[RUN-API] Error scanning for running simulations: {str(e)}")
        return response(500, {'error': 'Failed to fetch running simulations'})

    items = result.get('Items', [])
    print(f"[RUN-API] Found {len(items)} running simulations to interrupt (ALL users)")

    if len(items) == 0:
        print(f"[RUN-API] No running simulations to interrupt")
        return response(200, {
            'interrupted': 0,
            'message': 'No running simulations to interrupt'
        })

    interrupted_count = 0
    failed_count = 0
    finished_at = datetime.utcnow().isoformat() + 'Z'

    # Terminer chaque run avec status INTERRUPTED
    for item in items:
        run_id = item['id']
        username = item.get('username', 'unknown')
        try:
            table.update_item(
                Key={'id': run_id},
                UpdateExpression='SET #s = :status, finishedAt = :finished_at, errorMessage = :error_msg',
                ExpressionAttributeNames={'#s': 'status'},
                ExpressionAttributeValues={
                    ':status': 'INTERRUPTED',
                    ':finished_at': finished_at,
                    ':error_msg': 'Interrupted by user'
                }
            )
            interrupted_count += 1
            print(f"[RUN-API] Successfully interrupted run: {run_id} (user: {username})")
        except Exception as e:
            failed_count += 1
            print(f"[RUN-API] ERROR - Failed to interrupt run {run_id}: {str(e)}")

    print(f"[RUN-API] Interrupted {interrupted_count}/{len(items)} runs (ALL users) (failed: {failed_count})")

    # Retourner la réponse (match Spring Boot)
    return response(200, {
        'interrupted': interrupted_count,
        'message': f'{interrupted_count} simulation(s) interrupted'
    })


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

