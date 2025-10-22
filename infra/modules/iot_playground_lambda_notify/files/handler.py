import json

def lambda_handler(event, context):
    print("✅ Lambda triggered by EventBridge Pipe")
    print(json.dumps(event))
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Event received", "event": event})
    }
