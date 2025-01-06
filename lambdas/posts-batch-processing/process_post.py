import boto3
import botocore
import hashlib
import json 

from io import BytesIO


def extract_post(post,metrics_keys,metrics_bucket,posts_bucket):
    post_id = hashlib.sha256(bytes(post["original_url"],encoding="utf-8")).hexdigest() 
    creator_username = post["creator_user"] 
    platform_id = post["platform_id"]
    snapshot = post["snapshot"]
    metrics_data = {}
    for metric_key in metrics_keys: 
        metrics_data[metric_key] = post[metric_key]
    s3_post = process_post(post,post_id,posts_bucket)
    s3_metrics = process_metrics(metrics_data,platform_id,creator_username,post_id,snapshot,metrics_bucket)
    return post_id
    
def process_post(post_data,post_id,bucket):
    s3 = boto3.client("s3")
    
    json_payload = json.dumps(post_data)
    
    post_suburi = f"platform={post_data['platform_id']}/username={post_data['creator_user']}/post_id={post_id}"
    snapshot = post_data['snapshot']
    post_s3_location = f"s3://{bucket}/{post_suburi}/last.json"
    try:
        s3.get_object(Bucket=bucket, Key=f"/hist/{post_suburi}/snapshot={snapshot}/data.json")
    except botocore.exceptions.ClientError as e:
        s3.upload_fileobj(
                BytesIO(json_payload.encode()),
                bucket,
                f"hist/{post_suburi}/snapshot={snapshot}/data.json"
        )
        s3.upload_fileobj(
                BytesIO(json_payload.encode()),
                bucket,
                f"posts/{post_suburi}/last.json"
        )
    return post_s3_location

def process_metrics(metrics_data,platform_id,creator_username,post_id,snapshot,bucket):
    s3 = boto3.client("s3")

    json_payload = json.dumps(metrics_data)

    metrics_suburi = f"platform={platform_id}/username={creator_username}/post_id={post_id}"
    snapshot = snapshot
    metrics_s3_location = f"s3://{bucket}/{metrics_suburi}/last.json"
    
    try:
        s3.get_object(Bucket=bucket, Key=f"hist/{metrics_suburi}/snapshot={snapshot}/data.json")
    except botocore.exceptions.ClientError as e:
        s3.upload_fileobj(
                BytesIO(json_payload.encode()),
                bucket,
                f"hist/{metrics_suburi}/snapshot={snapshot}/data.json"
        )
        s3.upload_fileobj(
                BytesIO(json_payload.encode()),
                bucket,
                f"metrics/{metrics_suburi}/last.json"
        )
    return metrics_s3_location
