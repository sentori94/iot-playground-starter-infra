import json
import gzip
import base64
import re

def lambda_handler(event, context):
    # CloudWatch Logs envoient les données gzippées + encodées base64
    cw_data = event['awslogs']['data']
    decoded = gzip.decompress(base64.b64decode(cw_data)).decode('utf-8')
    payload = json.loads(decoded)

    # Chaque message est dans "logEvents"
    for log_event in payload['logEvents']:
        message = log_event['message']
        print(f"Raw message: {message}")

        # Extraire le runId via regex
        match = re.search(r"Run ([0-9a-fA-F\-]{36}) finished SUCCESS", message)
        if match:
            run_id = match.group(1)
            print(f"✅ Run finished successfully with ID: {run_id}")
            # Tu peux ensuite traiter ce run_id (ex: exporter un rapport)
        else:
            print("No run_id match found")

    return {"statusCode": 200}
