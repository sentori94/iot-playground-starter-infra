import json
import os
import boto3
import urllib3
from datetime import datetime, timedelta

# Clients AWS
logs_client = boto3.client('logs')
secretsmanager = boto3.client('secretsmanager')

# Configuration
PROJECT = os.environ.get('PROJECT', 'iot-playground')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
GITHUB_TOKEN_SECRET = os.environ.get('GITHUB_TOKEN_SECRET')
GITHUB_REPO_OWNER = os.environ.get('GITHUB_REPO_OWNER')
GITHUB_REPO_NAME = os.environ.get('GITHUB_REPO_NAME')
CLOUDWATCH_LOG_GROUP = os.environ.get('CLOUDWATCH_LOG_GROUP', f'/ecs/{PROJECT}-spring-app-{ENVIRONMENT}')
IDLE_THRESHOLD_HOURS = int(os.environ.get('IDLE_THRESHOLD_HOURS', '2'))

http = urllib3.PoolManager()

def get_github_token():
    """Récupérer le GitHub token depuis Secrets Manager"""
    try:
        response = secretsmanager.get_secret_value(SecretId=GITHUB_TOKEN_SECRET)
        return json.loads(response['SecretString'])['token']
    except Exception as e:
        print(f"❌ Error getting GitHub token: {str(e)}")
        raise

def check_last_log_activity():
    """
    Vérifier la dernière activité dans les logs CloudWatch
    Retourne le timestamp du dernier log ou None si aucun log
    """
    try:
        # Calculer la fenêtre de temps (dernières IDLE_THRESHOLD_HOURS heures)
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(hours=IDLE_THRESHOLD_HOURS)
        
        start_timestamp = int(start_time.timestamp() * 1000)
        end_timestamp = int(end_time.timestamp() * 1000)
        
        print(f"🔍 Checking logs in {CLOUDWATCH_LOG_GROUP}")
        print(f"   Time window: {start_time.isoformat()} to {end_time.isoformat()}")
        
        # Vérifier si le log group existe
        try:
            logs_client.describe_log_groups(logGroupNamePrefix=CLOUDWATCH_LOG_GROUP)
        except logs_client.exceptions.ResourceNotFoundException:
            print(f"⚠️ Log group {CLOUDWATCH_LOG_GROUP} does not exist")
            return None
        
        # Rechercher les derniers logs
        response = logs_client.filter_log_events(
            logGroupName=CLOUDWATCH_LOG_GROUP,
            startTime=start_timestamp,
            endTime=end_timestamp,
            limit=1  # On veut juste savoir s'il y a AU MOINS un log
        )
        
        events = response.get('events', [])
        
        if events:
            last_log_time = events[0]['timestamp']
            last_log_datetime = datetime.fromtimestamp(last_log_time / 1000)
            print(f"✅ Found recent activity: last log at {last_log_datetime.isoformat()}")
            return last_log_time
        else:
            print(f"⚠️ No logs found in the last {IDLE_THRESHOLD_HOURS} hours")
            return None
            
    except Exception as e:
        print(f"❌ Error checking logs: {str(e)}")
        raise

def trigger_github_destroy_workflow():
    """Déclencher le workflow GitHub Actions de destruction"""
    try:
        github_token = get_github_token()
        
        url = f'https://api.github.com/repos/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/dispatches'
        
        payload = {
            'event_type': 'trigger-destroy',
            'client_payload': {
                'triggered_by': 'auto-destroy-idle-lambda',
                'reason': f'No activity detected in last {IDLE_THRESHOLD_HOURS} hours',
                'timestamp': datetime.utcnow().isoformat()
            }
        }
        
        headers = {
            'Authorization': f'token {github_token}',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json',
            'User-Agent': 'Lambda-Auto-Destroy'
        }
        
        print(f"🚀 Triggering GitHub Actions destroy workflow...")
        print(f"   Repository: {GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}")
        
        response = http.request(
            'POST',
            url,
            body=json.dumps(payload).encode('utf-8'),
            headers=headers
        )
        
        if response.status == 204:
            print(f"✅ Destroy workflow triggered successfully!")
            return True
        else:
            print(f"❌ Failed to trigger workflow: HTTP {response.status}")
            print(f"   Response: {response.data.decode('utf-8')}")
            return False
            
    except Exception as e:
        print(f"❌ Error triggering GitHub workflow: {str(e)}")
        raise

def lambda_handler(event, context):
    """
    Lambda qui vérifie l'inactivité de l'application Spring sur ECS
    et déclenche la destruction automatique si pas d'activité depuis IDLE_THRESHOLD_HOURS heures
    
    Cette lambda doit être déclenchée périodiquement (ex: toutes les heures) par EventBridge
    """
    try:
        print("=" * 60)
        print("🤖 Auto-Destroy Idle Infrastructure Check")
        print("=" * 60)
        print(f"Environment: {ENVIRONMENT}")
        print(f"Project: {PROJECT}")
        print(f"Idle threshold: {IDLE_THRESHOLD_HOURS} hours")
        print(f"CloudWatch Log Group: {CLOUDWATCH_LOG_GROUP}")
        print("")
        
        # Vérifier la dernière activité dans les logs
        last_activity = check_last_log_activity()
        
        if last_activity is None:
            # Pas d'activité détectée dans les dernières IDLE_THRESHOLD_HOURS heures
            print("")
            print("=" * 60)
            print(f"⚠️ NO ACTIVITY DETECTED in last {IDLE_THRESHOLD_HOURS} hours")
            print("🔥 Triggering infrastructure destruction...")
            print("=" * 60)
            print("")
            
            success = trigger_github_destroy_workflow()
            
            if success:
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'action': 'destroy_triggered',
                        'reason': f'No activity in last {IDLE_THRESHOLD_HOURS} hours',
                        'timestamp': datetime.utcnow().isoformat()
                    })
                }
            else:
                return {
                    'statusCode': 500,
                    'body': json.dumps({
                        'action': 'destroy_failed',
                        'reason': 'Failed to trigger GitHub workflow',
                        'timestamp': datetime.utcnow().isoformat()
                    })
                }
        else:
            # Activité détectée, infrastructure reste en place
            last_activity_time = datetime.fromtimestamp(last_activity / 1000)
            time_since_last_activity = datetime.utcnow() - last_activity_time
            
            print("")
            print("=" * 60)
            print(f"✅ ACTIVITY DETECTED - Infrastructure kept alive")
            print(f"   Last activity: {time_since_last_activity.seconds // 60} minutes ago")
            print("=" * 60)
            print("")
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'action': 'no_action',
                    'reason': 'Recent activity detected',
                    'last_activity': last_activity_time.isoformat(),
                    'time_since_last_activity_minutes': time_since_last_activity.seconds // 60,
                    'timestamp': datetime.utcnow().isoformat()
                })
            }
            
    except Exception as e:
        print(f"❌ Lambda execution error: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'action': 'error',
                'error': str(e),
                'timestamp': datetime.utcnow().isoformat()
            })
        }

