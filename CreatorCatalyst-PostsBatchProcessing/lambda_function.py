import json
import os
import boto3
import io 
import botocore
from process_post import *

MEDIA_PROCESSING_SQS = os.getenv("MEDIA_PROCESSING_SQS")
# ATHENA_TABLE = os.getenv("ATHENA_TABLE")
METRICS_REPORT_SQS = os.getenv("METRICS_REPORT_SQS")
POSTS_TABLE = os.getenv("POSTS_TABLE")
POSTS_DATA_BUCKET = os.getenv("POSTS_DATA_BUCKET")
POSTS_METRICS_BUCKET = os.getenv("POSTS_METRICS_BUCKET")

def lambda_handler(event, context):

    dynamodb = boto3.client("dynamodb")
    sqs = boto3.client('sqs')
    athena = boto3.client("athena",region_name="us-east-1")
    posts_records = event["Records"]
    metrics_keys_data = json.load(open("./metrics_keys.json","r"))
    
    for post_data in posts_records:
        post = json.loads(post_data["body"])
        if post["original_url"] != None:
            metrics_keys = metrics_keys_data[post["platform_id"]]
            creator_id = post["creator_id"] if "creator_id" in post.keys() else "" 
            post_filename = f"{post["snapshot"]}.json"
            post_id = extract_post(post,metrics_keys,POSTS_METRICS_BUCKET,POSTS_DATA_BUCKET)
            try:
                dynamodb.put_item(Item=
                    {"platform":{
                        "S":post["platform_id"]
                    },"username":{
                        "S":post["creator_user"]
                    },"url":{
                        "S":post["original_url"]
                    },"post_id":{
                        "S":post_id
                    },"creator_id":{
                        "S":str(creator_id)
                    }
                    },ConditionExpression="attribute_not_exists(id)",
                    TableName=POSTS_TABLE)
                sqs.send_message(QueueUrl=MEDIA_PROCESSING_SQS,MessageBody=f"{post_id}")
                    
            except botocore.exceptions.ClientError as e:
                if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                    print('Post Already Exists')
                else:
                    raise e
       
    # athena.start_query_execution(f"MSCK REPAIR TABLE {ATHENA_TABLE};")
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
