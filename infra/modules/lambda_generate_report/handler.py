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

s3 = boto3.client("s3")

def lambda_handler(event, context):
    try:
        # --- 1. Décodage CloudWatch ---
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

            # --- 2. Parser l'URL de la base de données ---
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
            conn = pg8000.native.Connection(
                host=host,
                database=database,
                user=os.environ["DB_USERNAME"],
                password=os.environ["DB_PASSWORD"],
                port=port
            )

            # --- 4. Requête ---
            rows = conn.run("SELECT * FROM runs WHERE id = :run_id", run_id=run_id)

            if not rows:
                print(f"No rows found for run {run_id}")
                conn.close()
                continue

            # Récupérer les noms de colonnes
            columns = conn.columns
            colnames = [col["name"] for col in columns]

            # --- 5. Génération du CSV ---
            local_path = f"/tmp/run_{run_id}.csv"
            with open(local_path, "w", newline="") as f:
                writer = csv.writer(f)
                writer.writerow(colnames)
                writer.writerows(rows)

            # --- 6. Upload vers S3 ---
            s3_bucket = os.environ["REPORTS_BUCKET"]
            s3_path = f"reports/{date.today()}/run_{run_id}.csv"
            s3.upload_file(local_path, s3_bucket, s3_path)
            print(f"📤 Uploaded: s3://{s3_bucket}/{s3_path}")

            conn.close()

    except Exception as e:
        print(f"❌ Error: {e}")
        raise e

    return {"statusCode": 200}
