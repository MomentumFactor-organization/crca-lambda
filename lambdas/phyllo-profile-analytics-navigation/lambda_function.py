import json
import os
import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')

# Initialize Secrets Manager client
secrets_manager = boto3.client('secretsmanager')

def get_secret(secret_name):
    try:
        response = secrets_manager.get_secret_value(SecretId=secret_name)
        secret = json.loads(response['SecretString'])
        return secret
    except ClientError as e:
        raise e

def lambda_handler(event, context):
    secret_name = os.environ['SECRET_MANAGER_NAME']
    secret = get_secret(secret_name)
    table_name = secret['DYNAMODB_TABLE_NAME_CREATORS']
    table = dynamodb.Table(table_name)

    # Determine if the request is from API Gateway
    if 'httpMethod' in event and event['httpMethod'] == 'POST':
        body = json.loads(event['body'])
        result_uuid = body.get('result_uuid')
        platform_username = body.get('platform_username')
    else:
        result_uuid = event.get('result_uuid')
        platform_username = event.get('platform_username')

    if not result_uuid or not platform_username:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Missing result_uuid or platform_username'})
        }

    # Query the DynamoDB table for items with the given result_uuid, sorted by match in descending order
    response = table.query(
        KeyConditionExpression=Key('result_uuid').eq(result_uuid),
        IndexName='MatchIndex',
        ScanIndexForward=False  # Descending order
    )

    items = response.get('Items', [])
    current_index = next((index for (index, d) in enumerate(items) if d["platform_username"] == platform_username), None)

    if current_index is None:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'platform_username not found in the result set'})
        }

    navigation = {
        'prev': items[current_index - 1]['platform_username'] if current_index > 0 else None,
        'next': items[current_index + 1]['platform_username'] if current_index < len(items) - 1 else None
    }

    return {
        'statusCode': 200,
        'body': json.dumps({'navigation': navigation})
    }
