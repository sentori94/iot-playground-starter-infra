import os
import json
import gzip
import base64
import re
import csv
import pg8000.native
import boto3
from datetime import date
from urllib.parse import urlparse

# AWS X-Ray
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

# Patch automatique des bibliothèques AWS (boto3, etc.)
patch_all()

s3 = boto3.client("s3")

@xray_recorder.capture('lambda_handler')
def lambda_handler(event, context):
    try:
        # --- 1. Décodage CloudWatch ---
        with xray_recorder.capture('decode_cloudwatch_logs'):
            cw_data = event["awslogs"]["data"]
            decoded = gzip.decompress(base64.b64decode(cw_data)).decode("utf-8")
            payload = json.loads(decoded)

        for log_event in payload["logEvents"]:
            message = log_event["message"]
            match = re.search(r"Run ([0-9a-fA-F\-]{36}) finished SUCCESS", message)
            if not match:
                continue

            run_id = match.group(1)
            print(f"✅ Run detected: {run_id}")

            # Ajouter le run_id comme annotation X-Ray
            xray_recorder.put_annotation('run_id', run_id)

            # --- 2. Parser l'URL de la base de données ---
            with xray_recorder.capture('parse_db_url'):
                # URL format: jdbc:postgresql://host:port/database
                db_url = os.environ["DB_URL"]
                # Retirer le préfixe jdbc:postgresql://
                clean_url = db_url.replace("jdbc:postgresql://", "")
                # Parser host:port/database
                if "/" in clean_url:
                    host_port, database = clean_url.split("/", 1)
                    if ":" in host_port:
                        host, port = host_port.split(":")
                        port = int(port)
                    else:
                        host = host_port
                        port = 5432
                else:
                    host = clean_url
                    port = 5432
                    database = "postgres"

            # --- 3. Connexion à la base avec pg8000 ---
            with xray_recorder.capture('database_connection'):
                conn = pg8000.native.Connection(
                    host=host,
                    database=database,
                    user=os.environ["DB_USERNAME"],
                    password=os.environ["DB_PASSWORD"],
                    port=port
                )
                xray_recorder.put_metadata('database', 'host', host)
                xray_recorder.put_metadata('database', 'database', database)

            # --- 4. Requête ---
            with xray_recorder.capture('database_query'):
                rows = conn.run("SELECT * FROM runs WHERE id = :run_id", run_id=run_id)
                xray_recorder.put_metadata('query', 'rows_count', len(rows))

                if not rows:
                    print(f"No rows found for run {run_id}")
                    conn.close()
                    continue

                # Récupérer les noms de colonnes
                columns = conn.columns
                colnames = [col["name"] for col in columns]

            # --- 5. Génération du CSV ---
            with xray_recorder.capture('generate_csv'):
                local_path = f"/tmp/run_{run_id}.csv"
                with open(local_path, "w", newline="") as f:
                    writer = csv.writer(f)
                    writer.writerow(colnames)
                    writer.writerows(rows)

            # --- 6. Upload vers S3 ---
            with xray_recorder.capture('upload_to_s3'):
                s3_bucket = os.environ["REPORTS_BUCKET"]
                s3_path = f"reports/{date.today()}/run_{run_id}.csv"
                s3.upload_file(local_path, s3_bucket, s3_path)
                print(f"📤 Uploaded: s3://{s3_bucket}/{s3_path}")

                xray_recorder.put_metadata('s3', 'bucket', s3_bucket)
                xray_recorder.put_metadata('s3', 'key', s3_path)

            conn.close()

    except Exception as e:
        print(f"❌ Error: {e}")
        xray_recorder.put_annotation('error', str(e))
        raise e

    return {"statusCode": 200}
