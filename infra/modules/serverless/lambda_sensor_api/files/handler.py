import json
import boto3
import os
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
cloudwatch = boto3.client('cloudwatch')

TABLE_NAME = os.environ['SENSOR_DATA_TABLE_NAME']
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    """
    Handler pour les endpoints Sensor API:
    - POST /api/sensors/data (ingestion)
    - GET /api/sensors/data (liste)
    """

    http_method = event.get('httpMethod', '')
    path = event.get('path', '')

    print(f"[SENSOR-API] {http_method} {path}")

    try:
        if http_method == 'POST':
            return ingest_sensor_data(event)
        elif http_method == 'GET':
            return list_sensor_data(event)
        else:
            print(f"[SENSOR-API] Method not allowed: {http_method}")
            return response(405, {'error': 'Method not allowed'})

    except Exception as e:
        print(f"[SENSOR-API] ERROR: {str(e)}")
        return response(500, {'error': 'Internal server error', 'details': str(e)})


def ingest_sensor_data(event):
    """
    POST /api/sensors/data
    Ingestion de données capteur avec métriques CloudWatch
    """
    headers = event.get('headers', {})
    user = headers.get('X-User') or headers.get('x-user', 'unknown')
    run_id = headers.get('X-Run-Id') or headers.get('x-run-id', 'unknown')

    try:
        body = json.loads(event.get('body', '{}'))
    except json.JSONDecodeError:
        return response(400, {'error': 'Invalid JSON body'})

    # Validation des données
    sensor_id = body.get('sensorId')
    sensor_type = body.get('type')
    reading = body.get('reading')

    if not sensor_id or not sensor_type or reading is None:
        print(f"[SENSOR-API] Validation failed: missing fields")
        return response(400, {'error': 'Missing required fields: sensorId, type, reading'})

    # Timestamp actuel
    timestamp = datetime.utcnow().isoformat() + 'Z'

    print(f"[SENSOR-API] Ingesting data: sensor={sensor_id}, type={sensor_type}, reading={reading}, user={user}, runId={run_id}")

    # Préparer l'item DynamoDB
    item = {
        'sensorId': sensor_id,
        'timestamp': timestamp,
        'type': sensor_type,
        'reading': Decimal(str(reading)),
        'user': user,
        'runId': run_id
    }

    # Sauvegarder dans DynamoDB
    table.put_item(Item=item)

    # Publier les métriques CloudWatch
    publish_metrics(sensor_id, reading, user, run_id, sensor_type)

    print(f"[SENSOR-API] Data saved successfully: {sensor_id} at {timestamp}")

    # Retourner la réponse
    return response(200, {
        'message': 'Data ingested successfully',
        'sensorId': sensor_id,
        'timestamp': timestamp
    })


def list_sensor_data(event):
    """
    GET /api/sensors/data
    Liste toutes les données capteur (ou filtré par query params)
    """
    query_params = event.get('queryStringParameters') or {}

    # Paramètres optionnels
    sensor_id = query_params.get('sensorId')
    run_id = query_params.get('runId')
    limit = int(query_params.get('limit', 100))

    print(f"[SENSOR-API] Listing data: sensorId={sensor_id}, runId={run_id}, limit={limit}")

    if sensor_id:
        # Query par sensorId
        result = table.query(
            KeyConditionExpression='sensorId = :sid',
            ExpressionAttributeValues={':sid': sensor_id},
            Limit=limit,
            ScanIndexForward=False  # Tri décroissant par timestamp
        )
    elif run_id:
        # Query par runId (utilise le GSI)
        result = table.query(
            IndexName='runId-timestamp-index',
            KeyConditionExpression='runId = :rid',
            ExpressionAttributeValues={':rid': run_id},
            Limit=limit,
            ScanIndexForward=False
        )
    else:
        # Scan (attention à la performance sur de grandes tables)
        result = table.scan(Limit=limit)

    items = result.get('Items', [])
    print(f"[SENSOR-API] Retrieved {len(items)} sensor data records")
    items = [convert_decimals(item) for item in items]

    return response(200, {
        'items': items,
        'count': len(items)
    })


def publish_metrics(sensor_id, reading, user, run_id, sensor_type):
    """Publie les métriques vers CloudWatch pour Grafana avec haute résolution (1s)"""
    try:
        # Métrique principale avec dimensions
        cloudwatch.put_metric_data(
            Namespace='IoTPlayground/Sensors',
            MetricData=[
                {
                    'MetricName': 'SensorReading',
                    'Value': float(reading),
                    'Unit': 'None',
                    'Timestamp': datetime.utcnow(),
                    'StorageResolution': 1,  # Haute résolution: 1 seconde (au lieu de 60s par défaut)
                    'Dimensions': [
                        {'Name': 'SensorId', 'Value': sensor_id},
                        {'Name': 'User', 'Value': user},
                        {'Name': 'RunId', 'Value': run_id},
                        {'Name': 'Type', 'Value': sensor_type}
                    ]
                },
                # Compteur d'ingestion
                {
                    'MetricName': 'DataIngested',
                    'Value': 1,
                    'Unit': 'Count',
                    'Timestamp': datetime.utcnow(),
                    'StorageResolution': 1,  # Haute résolution: 1 seconde
                    'Dimensions': [
                        {'Name': 'SensorId', 'Value': sensor_id},
                        {'Name': 'User', 'Value': user},
                        {'Name': 'RunId', 'Value': run_id}
                    ]
                }
            ]
        )
    except Exception as e:
        print(f"Error publishing metrics: {str(e)}")
        # Ne pas bloquer l'ingestion si les métriques échouent


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

