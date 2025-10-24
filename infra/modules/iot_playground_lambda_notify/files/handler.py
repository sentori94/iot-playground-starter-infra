import os
import json
import gzip
import base64
import re
import csv
import psycopg2
import boto3
from datetime import date

s3 = boto3.client("s3")
secretsmanager = boto3.client("secretsmanager")

def get_db_credentials(secret_arn):
    """Lit le secret et retourne les valeurs db_host/db_name/db_user/db_pass."""
    response = secretsmanager.get_secret_value(SecretId=secret_arn)
    secret_data = json.loads(response["SecretString"])
    return (
        secret_data["db_host"],
        secret_data["db_name"],
        secret_data["db_user"],
        secret_data["db_pass"]
    )

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

            # --- 2. Récupérer les credentials du secret manager ---
            secret_arn = os.environ["DB_SECRET_ARN"]
            db_host, db_name, db_user, db_pass = get_db_credentials(secret_arn)

            # --- 3. Connexion à la base ---
            conn = psycopg2.connect(
                host=db_host, dbname=db_name, user=db_user, password=db_pass, port=5432
            )
            cursor = conn.cursor()

            cursor.execute("SELECT * FROM runs WHERE run_id = %s;", (run_id,))
            rows = cursor.fetchall()
            colnames = [desc[0] for desc in cursor.description]

            if not rows:
                print(f"No rows found for run {run_id}")
                continue

            # --- 4. Génération du CSV ---
            local_path = f"/tmp/run_{run_id}.csv"
            with open(local_path, "w", newline="") as f:
                writer = csv.writer(f)
                writer.writerow(colnames)
                writer.writerows(rows)

            # --- 5. Upload vers S3 ---
            s3_bucket = os.environ["REPORTS_BUCKET"]
            s3_path = f"reports/{date.today()}/run_{run_id}.csv"
            s3.upload_file(local_path, s3_bucket, s3_path)
            print(f"📤 Uploaded: s3://{s3_bucket}/{s3_path}")

            cursor.close()
            conn.close()

    except Exception as e:
        print(f"❌ Error: {e}")
        raise e

    return {"statusCode": 200}
