import json
import boto3
import botocore
from io import BytesIO
import os

POSTS_BUCKET = os.getenv("POSTS_BUCKET")
TAGS_BUCKET = os.getenv("TAGS_BUCKET")
POSTS_TABLE = os.getenv("POSTS_TABLE")


def lambda_handler(event, context):
    dynamodb = boto3.client("dynamodb")
    
    print(event)
    post_id = event["queryStringParameters"]["post_id"]
    media_id = event["queryStringParameters"]["media_id"]
    
    post_entry = dynamodb.get_item(Key={"post_id":{"S":post_id}},TableName=POSTS_TABLE)
    
    post_data = post_entry["Item"]
    
    platform = post_data["platform"]["S"]
    username = post_data["username"]["S"]
    
    post_filename = f"posts/platform={platform}/username={username}/post_id={post_id}/last.json"
    # post_filename = f"{post_data['snapshot']}.json"
    print("Posts file",post_filename)
    json_data = json.loads(event["body"], encoding="utf-8")["result"]
    json_payload = json.dumps(json_data)
    tags_folder = f"tags/platform={platform}/username={username}/post_id={post_id}/vendor=unitary/media_id={media_id}"
    posts_tags_folder = f"tags/platform={platform}/username={username}/post_id={post_id}/vendor=unitary"
    tags_filename = f"{tags_folder}/data.json"
    
    s3 = boto3.client("s3")
    
    s3.upload_fileobj(
                BytesIO(json_payload.encode()),
                TAGS_BUCKET,
                f"{tags_filename}"
        )
    post_obj = s3.get_object(Bucket=POSTS_BUCKET, Key=post_filename)
    post = json.loads(post_obj['Body'].read().decode('utf-8'))
    # current_tag_files = s3.list_objects(Prefix=posts_tags_folder,Bucket=POSTS_BUCKET)
    # print("Current Contents", current_tag_files)
    # if len(post["media"]) > len(current_tag_files["Contents"]):
    #     dynamodb.update_item(Key={"post_id":{"S":post_id}},UpdateExpression="SET tagged = true",TableName=POSTS_TABLE)
    return {
        'statusCode': 200,
        'body': json.dumps({"media_id":event["queryStringParameters"]["media_id"],"post_id":event["queryStringParameters"]["post_id"]})
    }