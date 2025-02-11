import json
import os 
import boto3
import hashlib
import io
import botocore
import requests as rq

UNITARY_API_LOCATION = os.getenv("UNITARY_API_LOCATION")
UNITARY_API_KEY = os.getenv("UNITARY_API_KEY")
RESPONSE_WEBHOOK_URL = os.getenv("RESPONSE_WEBHOOK_URL")
MEDIA_BUCKET = os.getenv("MEDIA_BUCKET")
extensions = {"mp4":"video", 
              "mpeg":"video", 
              "webm":"video", 
              "mov":"video", 
              "mkv":"video", 
              "m4v":"video",
              "png":"image", 
              "jpeg":"image", 
              "jpg":"image"}
              
POSTS_BUCKET = os.getenv("POSTS_BUCKET")
POSTS_TABLE = os.getenv("POSTS_TABLE")


def download_file(url):
    # local_filename = url.split('/')[-1]
    # NOTE the stream=True parameter below
    mem_file = io.BytesIO()
    with rq.get(url, stream=True) as r:
        r.raise_for_status()
        # with open(local_filename, 'wb') as f:
        for chunk in r.iter_content(chunk_size=8192): 
            # If you have chunk encoded response uncomment if
            # and set chunk_size parameter to None.
            #if chunk: 
            mem_file.write(chunk)
    mem_file.seek(0)
    return mem_file

# def classify_media(filename):
#     extension = filename.split(".")[-1]
    

def lambda_handler(event, context):
    # TODO implement
    
    records = event["Records"]
    dynamodb = boto3.client("dynamodb")
    sqs = boto3.client("sqs")
    s3 = boto3.client("s3")
    media_urls = []
    for record in records: 
        post_id = record["body"]
        db_response = dynamodb.get_item(Key={"post_id":{"S":post_id}},TableName=POSTS_TABLE)
        current_post = db_response["Item"]
        platform = current_post["platform"]["S"]
        username = current_post["username"]["S"]
        post_file_s3 = f"posts/platform={platform}/username={username}/post_id={post_id}/last.json"
        print(f"Getting post file: {post_file_s3}")
        posts_obj = s3.get_object(Bucket=POSTS_BUCKET, Key=post_file_s3)
        post_data = posts_obj['Body'].read().decode('utf-8')
        posts = json.loads(post_data)
        for media in posts["media"]:
            if media["s3_url"] != None:
                media_id = hashlib.sha256(bytes(media["s3_url"].encode("utf-8")))
                media_filename = media["s3_url"].split("/")[-1]
                media_urls.append({"post_id":post_id,"file_url":media["s3_url"],
                                    "media_filename":media_filename,
                                    "tagged_data_file":f"tags/platform={platform}/username={username}/post_id={post_id}/vendor=unitary/media_id={media_filename.split('.')[0]}/data.json"})
    jobs_created = {}
    token_request_url = f'{UNITARY_API_LOCATION}/authenticate'
    response = rq.post(token_request_url, headers = {'Content-Type': 'application/json'},data=json.dumps({"key":UNITARY_API_KEY}))
    api_token = f'Bearer {json.loads(response.text)["api_token"]}'
    # check_all_files = True
    for media in media_urls:
        try:
            s3.get_object(Bucket=POSTS_BUCKET, Key=f"{media['tagged_data_file']}")
        except botocore.exceptions.ClientError as e:
            file = None
            if "s3://" in media["file_url"]:
                bucket_name = media["file_url"].split("/")[2]
                file_key = "/".join(media["file_url"].split("/")[3:])
                file = s3.get_object( Bucket=bucket_name, Key=file_key )["Body"]
            else:
                file = download_file(media["file_url"])
            # filename = media["s3_url"].split("/")[-1].split(".")[0]
            files=[('file',(media["media_filename"],file,'application/octet-stream'))]
            
            print(media)
            webhook_url =  f'{RESPONSE_WEBHOOK_URL}?post_id={media["post_id"]}&media_id={media["media_filename"].split(".")[0]}'
            print(webhook_url)
            media_extension = media["media_filename"].split(".")[-1].lower()
            unitary_endpoint_url = f'{UNITARY_API_LOCATION}/classify/items-characteristics/{extensions[media_extension]}'
            response = rq.post(unitary_endpoint_url,headers={'Authorization':api_token},files=files,data={"callback_url":webhook_url})
            jobs_created[media["media_filename"]]= response.text
            check_all_files = False
    # if check_all_files:
    #     sqs.send_message(QueueUrl=REPORT_METRICS_SQS,MessageBody=)
    print(jobs_created)
    return {
        'statusCode': 200,
        'body':json.dumps(jobs_created)
    }
