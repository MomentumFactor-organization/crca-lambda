import json
import os
import boto3
import io 
import requests as rq
import botocore


DOMAIN_NAME = os.getenv("DOMAIN_NAME")
region_name = "us-west-1"

def get_secret(secret_name):
    secret_name = os.environ("SECRET_NAME")
    
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
    template = event.get("template_name")
    recipient = event["recipient"]
    subject = event["subject"]
    body = event["body"]

    MAILGUN_API_KEY = get_secret("MAILGUN_API_KEY") 
    MAILGUN_SIGNING_KEY = get_secret("MAILGUN_SIGNING_URL")
    
    DOMAIN_NAME = os.getenv("DOMAIN_NAME")

    response = rq.post(
        f"https://api.mailgun.net/v3/{DOMAIN_NAME}/messages",
        auth=("api", MAILGUN_API_KEY),
        data={
            "from": f"Mailgun Sandbox <postmaster@{DOMAIN_NAME}>",
            "to": recipient,
            "subject": subject,
            "text": body
        }
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
