import json
import os
import boto3
import io 
import requests as rq


DOMAIN_NAME = os.getenv("DOMAIN_NAME")
region_name = "us-west-1"

def get_secret():
    secret_name = os.getenv("SECRET_NAME")
    
    client = boto3.client('secretsmanager', region_name=region_name)

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except Exception as e:
        print(f"Error fetching secret: {e}")
        raise e
    
    secret = get_secret_value_response['SecretString']
    return json.loads(secret)


def lambda_handler(event, context):
    records = event["Records"]
    
    for record in records:
        payload = record["body"]
        template = payload.get("template_name")
        recipient = payload["recipient"]
        subject = payload["subject"]
        body = payload["body"]
        
        secrets = get_secret()
        MAILGUN_API_KEY = secrets["MAILGUN_API_KEY"] 
        MAILGUN_SIGNING_KEY = secrets["MAILGUN_SIGNING_URL"]
        
        DOMAIN_NAME = os.getenv("DOMAIN_NAME")

        response = rq.post(
            f"https://api.mailgun.net/v3/{DOMAIN_NAME}/messages",
            auth=("api", MAILGUN_API_KEY),
            data={
                "from": f"Creator Catalyst Notification <noreply@{DOMAIN_NAME}>",
                "to": recipient,
                "subject": subject,
                "text": body
            }
        )
    return {
        'statusCode': 200,
        'body': json.dumps(f'Email sent to {recipient}')
    }
