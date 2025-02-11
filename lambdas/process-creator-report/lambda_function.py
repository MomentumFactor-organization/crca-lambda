import json
import boto3
import os

REPORT_BATCH_SQS = os.getenv("REPORT_BATCH_SQS")


def lambda_handler(event, context):
    sqs = boto3.client("sqs")
    report = json.loads(event["body"])
    creators = report["data"]
    result_creators = []
    for creator in creators: 
        sqs.send_message(QueueUrl=REPORT_BATCH_SQS,
        MessageBody=json.dumps(creator) )
    
    return {
        'statusCode': 200,
        'body': f"Sent users for processing"
    }