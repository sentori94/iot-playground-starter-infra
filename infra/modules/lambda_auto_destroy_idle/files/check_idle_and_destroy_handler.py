import json
import os
import boto3
import urllib3
from datetime import datetime, timedelta

# Clients AWS
logs_client = boto3.client('logs')
secretsmanager = boto3.client('secretsmanager')
sns_client = boto3.client('sns')

# Configuration
PROJECT = os.environ.get('PROJECT', 'iot-playground')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
GITHUB_TOKEN_SECRET = os.environ.get('GITHUB_TOKEN_SECRET')
GITHUB_REPO_OWNER = os.environ.get('GITHUB_REPO_OWNER')
GITHUB_REPO_NAME = os.environ.get('GITHUB_REPO_NAME')
CLOUDWATCH_LOG_GROUP = os.environ.get('CLOUDWATCH_LOG_GROUP', f'/ecs/{PROJECT}-spring-app-{ENVIRONMENT}')
LOG_FILTER_PATTERN = os.environ.get('LOG_FILTER_PATTERN', 'finished SUCCESS')
IDLE_THRESHOLD_HOURS = int(os.environ.get('IDLE_THRESHOLD_HOURS', '2'))
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

http = urllib3.PoolManager()

def send_notification(subject, message):
    """Envoyer une notification par email via SNS"""
    try:
        if not SNS_TOPIC_ARN:
            print("⚠️ SNS_TOPIC_ARN not configured, skipping notification")
            return False

        response = sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        print(f"📧 Email notification sent (MessageId: {response['MessageId']})")
        return True
    except Exception as e:
        print(f"⚠️ Failed to send email notification: {str(e)}")
        return False

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
    Recherche le pattern spécifique (ex: "finished SUCCESS")
    Retourne le timestamp du dernier log correspondant ou None
    """
    try:
        # Calculer la fenêtre de temps (dernières IDLE_THRESHOLD_HOURS heures)
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(hours=IDLE_THRESHOLD_HOURS)

        start_timestamp = int(start_time.timestamp() * 1000)
        end_timestamp = int(end_time.timestamp() * 1000)

        print(f"🔍 Checking logs in {CLOUDWATCH_LOG_GROUP}")
        print(f"   Time window: {start_time.isoformat()} to {end_time.isoformat()}")
        print(f"   Filter pattern: '{LOG_FILTER_PATTERN}'")

        # Vérifier si le log group existe
        try:
            logs_client.describe_log_groups(logGroupNamePrefix=CLOUDWATCH_LOG_GROUP)
        except logs_client.exceptions.ResourceNotFoundException:
            print(f"⚠️ Log group {CLOUDWATCH_LOG_GROUP} does not exist")
            return None

        # Rechercher les logs avec le pattern spécifique
        response = logs_client.filter_log_events(
            logGroupName=CLOUDWATCH_LOG_GROUP,
            startTime=start_timestamp,
            endTime=end_timestamp,
            filterPattern=LOG_FILTER_PATTERN,
            limit=1  # On veut juste savoir s'il y a AU MOINS un log correspondant
        )

        events = response.get('events', [])

        if events:
            last_log_time = events[0]['timestamp']
            last_log_datetime = datetime.fromtimestamp(last_log_time / 1000)
            last_log_message = events[0].get('message', '')[:100]  # Premiers 100 caractères
            print(f"✅ Found pattern '{LOG_FILTER_PATTERN}' in logs")
            print(f"   Last occurrence: {last_log_datetime.isoformat()}")
            print(f"   Message preview: {last_log_message}")
            return last_log_time
        else:
            print(f"⚠️ Pattern '{LOG_FILTER_PATTERN}' not found in the last {IDLE_THRESHOLD_HOURS} hours")
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
                'reason': f'No "{LOG_FILTER_PATTERN}" activity detected in last {IDLE_THRESHOLD_HOURS} hours',
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
    et déclenche la destruction automatique si le pattern n'est pas trouvé dans les logs
    depuis IDLE_THRESHOLD_HOURS heures

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
        print(f"Filter pattern: '{LOG_FILTER_PATTERN}'")
        print("")

        # Vérifier la dernière activité dans les logs
        last_activity = check_last_log_activity()

        if last_activity is None:
            # Pas d'activité détectée dans les dernières IDLE_THRESHOLD_HOURS heures
            print("")
            print("=" * 60)
            print(f"⚠️ NO '{LOG_FILTER_PATTERN}' ACTIVITY DETECTED in last {IDLE_THRESHOLD_HOURS} hours")
            print("🔥 Triggering infrastructure destruction...")
            print("=" * 60)
            print("")

            success = trigger_github_destroy_workflow()

            # Envoyer notification email
            email_subject = f"⚠️ [{PROJECT}-{ENVIRONMENT}] Infrastructure Destruction Triggered"
            email_message = f"""
Infrastructure Auto-Destroy Alert
==================================

⚠️ DESTRUCTION DE L'INFRASTRUCTURE DÉCLENCHÉE

Détails:
--------
Projet: {PROJECT}
Environnement: {ENVIRONMENT}
Raison: Aucune activité "{LOG_FILTER_PATTERN}" détectée dans les {IDLE_THRESHOLD_HOURS} dernières heures
Timestamp: {datetime.utcnow().isoformat()} UTC

CloudWatch Log Group: {CLOUDWATCH_LOG_GROUP}
Pattern recherché: "{LOG_FILTER_PATTERN}"

Action:
-------
Le workflow GitHub Actions "terraform-destroy.yml" a été déclenché automatiquement.

Repository: {GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}
Workflow Status: {'✅ Déclenché avec succès' if success else '❌ Échec du déclenchement'}

Pour suivre l'exécution:
https://github.com/{GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}/actions

--
Message automatique généré par Lambda Auto-Destroy
"""
            send_notification(email_subject, email_message)

            if success:
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'action': 'destroy_triggered',
                        'reason': f'No "{LOG_FILTER_PATTERN}" activity in last {IDLE_THRESHOLD_HOURS} hours',
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
            minutes_ago = time_since_last_activity.seconds // 60

            print("")
            print("=" * 60)
            print(f"✅ '{LOG_FILTER_PATTERN}' ACTIVITY DETECTED - Infrastructure kept alive")
            print(f"   Last activity: {minutes_ago} minutes ago")
            print("=" * 60)
            print("")

            # Envoyer notification email
            email_subject = f"✅ [{PROJECT}-{ENVIRONMENT}] Infrastructure Active"
            email_message = f"""
Infrastructure Activity Check
=============================

✅ INFRASTRUCTURE MAINTENUE ACTIVE

Détails:
--------
Projet: {PROJECT}
Environnement: {ENVIRONMENT}
Pattern trouvé: "{LOG_FILTER_PATTERN}"
Dernière activité: Il y a {minutes_ago} minutes ({last_activity_time.isoformat()} UTC)
Timestamp vérification: {datetime.utcnow().isoformat()} UTC

CloudWatch Log Group: {CLOUDWATCH_LOG_GROUP}

Status:
-------
L'infrastructure reste en place car une activité récente a été détectée.
Prochaine vérification: Dans 1 heure

--
Message automatique généré par Lambda Auto-Destroy
"""
            send_notification(email_subject, email_message)

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'action': 'no_action',
                    'reason': f'Recent "{LOG_FILTER_PATTERN}" activity detected',
                    'last_activity': last_activity_time.isoformat(),
                    'time_since_last_activity_minutes': minutes_ago,
                    'timestamp': datetime.utcnow().isoformat()
                })
            }

    except Exception as e:
        print(f"❌ Lambda execution error: {str(e)}")
        import traceback
        traceback.print_exc()

        # Envoyer notification d'erreur
        email_subject = f"❌ [{PROJECT}-{ENVIRONMENT}] Auto-Destroy Check Error"
        email_message = f"""
Infrastructure Check Error
==========================

❌ ERREUR LORS DE LA VÉRIFICATION

Détails:
--------
Projet: {PROJECT}
Environnement: {ENVIRONMENT}
Erreur: {str(e)}
Timestamp: {datetime.utcnow().isoformat()} UTC

Action requise:
---------------
Vérifiez les logs CloudWatch de la Lambda:
/aws/lambda/{PROJECT}-{ENVIRONMENT}-auto-destroy-idle

--
Message automatique généré par Lambda Auto-Destroy
"""
        send_notification(email_subject, email_message)

        return {
            'statusCode': 500,
            'body': json.dumps({
                'action': 'error',
                'error': str(e),
                'timestamp': datetime.utcnow().isoformat()
            })
        }

