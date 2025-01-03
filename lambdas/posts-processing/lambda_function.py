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
        # if post["original_url"] != None:
        #     post["snapshot"] = publish_date
        #     post_snapshot = publish_date
        #     post_data = json.dumps(post)
        #     creator_id = post["creator_id"] if "creator_id" in post.keys() else "" 
        #     post_filename = f"{post_snapshot}.json"
        #     post_id = extract_post(post,metrics_keys,POSTS_METRICS_BUCKET,POSTS_DATA_BUCKET)
        #     try:
        #         dynamodb.put_item(Item=
        #             {"platform":{
        #                 "S":post["platform_id"]
        #             },"username":{
        #                 "S":post["creator_user"]
        #             },"url":{
        #                 "S":post["original_url"]
        #             },"post_id":{
        #                 "S":post_id
        #             },"creator_id":{
        #                 "S":str(creator_id)
        #             }
        #             },ConditionExpression="attribute_not_exists(id)",
        #             TableName=POSTS_TABLE)
        #         posts_processed.append(post_id)
        #     except botocore.exceptions.ClientError as e:
        #         if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
        #             print('Post Already Exists')
        #         else:
        #             raise e
    
    sqs.send_message(QueueUrl=METRICS_REPORT_SQS,MessageBody=json.dumps({"username":username,"platform":platform}))
    return {
        'statusCode': 200,
        'body': json.dumps(posts_processed)
    }
