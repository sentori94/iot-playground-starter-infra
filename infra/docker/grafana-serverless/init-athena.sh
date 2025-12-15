#!/bin/bash

echo "🚀 Démarrage de Grafana..."

# Variables d'environnement attendues
ATHENA_DATABASE=${ATHENA_DATABASE:-"iot_playground_grafana_serverless_dev"}
ATHENA_WORKGROUP=${ATHENA_WORKGROUP:-"iot-playground-grafana-grafana-serverless-dev"}
AWS_REGION=${AWS_REGION:-"eu-west-3"}

# Lancer l'initialisation Athena en arrière-plan (ne bloque pas le démarrage de Grafana)
(
  sleep 30  # Attendre que Grafana démarre

  echo "📋 Initialisation Athena en arrière-plan..."
  echo "  Database: $ATHENA_DATABASE"
  echo "  Workgroup: $ATHENA_WORKGROUP"
  echo "  Region: $AWS_REGION"

  # Créer la table runs
  echo "🔄 Création de la table runs..."
  aws athena start-query-execution \
    --query-string "CREATE EXTERNAL TABLE IF NOT EXISTS runs (id string, username string, status string, startedAt string, finishedAt string, params string, errorMessage string, grafanaUrl string) STORED BY 'org.apache.hadoop.hive.dynamodb.DynamoDBStorageHandler' TBLPROPERTIES ('dynamodb.table.name' = 'iot-playground-runs-serverless-dev', 'dynamodb.column.mapping' = 'id:id,username:username,status:status,startedAt:startedAt,finishedAt:finishedAt,params:params,errorMessage:errorMessage,grafanaUrl:grafanaUrl');" \
    --query-execution-context Database="$ATHENA_DATABASE" \
    --work-group "$ATHENA_WORKGROUP" \
    --region "$AWS_REGION" \
    2>/dev/null && echo "✅ Table runs créée" || echo "⚠️  Table runs existe déjà"

  # Créer la table sensor_data
  echo "🔄 Création de la table sensor_data..."
  aws athena start-query-execution \
    --query-string "CREATE EXTERNAL TABLE IF NOT EXISTS sensor_data (sensorId string, timestamp string, type string, reading double, user string, runId string) STORED BY 'org.apache.hadoop.hive.dynamodb.DynamoDBStorageHandler' TBLPROPERTIES ('dynamodb.table.name' = 'iot-playground-sensor-data-serverless-dev', 'dynamodb.column.mapping' = 'sensorId:sensorId,timestamp:timestamp,type:type,reading:reading,user:user,runId:runId');" \
    --query-execution-context Database="$ATHENA_DATABASE" \
    --work-group "$ATHENA_WORKGROUP" \
    --region "$AWS_REGION" \
    2>/dev/null && echo "✅ Table sensor_data créée" || echo "⚠️  Table sensor_data existe déjà"

  echo "✅ Initialisation Athena terminée"
) &

# Démarrer Grafana immédiatement
exec /run.sh "$@"

