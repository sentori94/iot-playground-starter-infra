
import json
import boto3
import os
from io import BytesIO
import zipfile
from datetime import datetime

s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    Lambda handler to download all reports from S3 bucket as a zip file
    """
    bucket_name = os.environ.get('REPORTS_BUCKET')
    
    if not bucket_name:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': 'REPORTS_BUCKET not configured'})
        }
    
    try:
        # Liste tous les objets du bucket
        response = s3.list_objects_v2(Bucket=bucket_name)
        
        if 'Contents' not in response or len(response['Contents']) == 0:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps({'message': 'No reports found'})
            }
        
        # Créer un fichier ZIP en mémoire
        zip_buffer = BytesIO()
        
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
            for obj in response['Contents']:
                key = obj['Key']
                print(f"Adding {key} to zip...")
                
                # Télécharger l'objet
                file_obj = s3.get_object(Bucket=bucket_name, Key=key)
                file_content = file_obj['Body'].read()
                
                # Ajouter au ZIP
                zip_file.writestr(key, file_content)
        
        # Récupérer le contenu du ZIP
        zip_buffer.seek(0)
        zip_content = zip_buffer.read()
        
        # Encoder en base64 pour API Gateway
        import base64
        zip_base64 = base64.b64encode(zip_content).decode('utf-8')
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/zip',
                'Content-Disposition': f'attachment; filename="reports_{timestamp}.zip"'
            },
            'body': zip_base64,
            'isBase64Encoded': True
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': str(e)})
        }

