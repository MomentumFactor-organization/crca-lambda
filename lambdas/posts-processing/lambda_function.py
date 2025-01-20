import json
import os
import boto3
import io 
import requests as rq
import botocore


SCRAPER_RESULT_TABLE = os.getenv("SCRAPER_RESULT_TABLE")
POST_BATCH_SQS = os.getenv("POST_BATCH_SQS")
METRICS_REPORT_SQS = os.getenv("METRICS_REPORT_SQS")

def lambda_handler(event, context):
    run_id = json.loads(event["Records"][0]["body"])
    dynamodb = boto3.client("dynamodb")
    sqs = boto3.client('sqs')
    athena = boto3.client("athena",region_name="us-east-1")
    print("Getting run with id: ",run_id)
    
    response = dynamodb.get_item(Key={"id":{"S":run_id['id']}},TableName=SCRAPER_RESULT_TABLE)
    
    
    scrapper_run = response["Item"]
    platform = scrapper_run["platform"]["S"]
    username = scrapper_run["username"]["S"]
    publish_date = scrapper_run["publish_date"]["S"]
    posts_file = scrapper_run["posts_file"]["S"]
    
    print(f"Processing posts for {username} in {platform}")
    
    metrics_keys_data = json.load(open("./metrics_keys.json","r"))
    metrics_keys = metrics_keys_data[platform]
    
    s3 = boto3.client("s3",)
    s3_bucket = posts_file.split("/")[2]
    s3_uri = "/".join(posts_file.split("/")[3:])
    post_data = None
    if "s3" in posts_file:
        posts_obj = s3.get_object(Bucket=s3_bucket, Key=s3_uri)
        post_data = posts_obj['Body'].read().decode('utf-8')
    else: 
        response = rq.get(posts_file)
        post_data = response.text
    posts =  json.loads(post_data) 
    posts_processed = []
    
    for post in  posts:
        post["snapshot"] = publish_date
        sqs.send_message(QueueUrl=POST_BATCH_SQS,MessageBody=json.dumps(post))
    
    sqs.send_message(QueueUrl=METRICS_REPORT_SQS,MessageBody=json.dumps({"username":username,"platform":platform}))
    return {
        'statusCode': 200,
        'body': json.dumps(posts_processed)
    }
