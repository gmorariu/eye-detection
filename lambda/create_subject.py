import json
import boto3
from boto3.dynamodb.conditions import Key
import requests
from jose import jwt
from pprint import pprint
import uuid

dynamodb = boto3.resource('dynamodb')
users = dynamodb.Table('camcussion_users')
subjects = dynamodb.Table('camcussion_subjects')

def lambda_handler(event, context):
    print(event)
    try:
        token = event['headers']['authorization']
        decoded_token = decode_token(token)
        user=getUserID(token)
        body = json.loads(event['body'])
    except Exception:
        return {
            'statusCode': 401
        }
    print('creating subject for user '+ decoded_token['sub'])

    subject = body['subject']
    isNew = False
    if not (("id" in subject) and (subject["id"])):
        subject["id"] = str(uuid.uuid4())
        isNew = True
    team = body['team']

    data = users.query(
        KeyConditionExpression=Key('id').eq(decoded_token['sub'])
    )
    #print(data)
    result = []
    for group in data['Items']:
        if group['subject_group_name'] == team:
            response = subjects.put_item(Item=subject)
            group['subjects'].append(subject['id'])
            if isNew:
                response = users.update_item(
                    Key={
                        'id': decoded_token['sub'],
                        'subject_group_uuid': group['subject_group_uuid']
                    },
                    UpdateExpression="set subjects = :L",
                    ExpressionAttributeValues={
                        ':L': group['subjects'],
                    },
                    ReturnValues="UPDATED_NEW"
                )
            return {
                'statusCode': 200,
                'isBase64Encoded': False,
                'headers': { 'Content-Type': 'application/json'},
                'body': json.dumps({'subject_id': subject["id"]})
            }

    #print(result)
    return {
        'statusCode': 404,
        'error': 'Subject group not found'
    }

def getUserID(token):
    client = boto3.client('cognito-identity')
    l={'cognito-idp.us-west-2.amazonaws.com/xxx': token}
    u=client.get_id(AccountId='xxx', IdentityPoolId='xxx', Logins=l)
    return u['IdentityId']

def decode_token(token):
    jwks_url = 'https://cognito-idp.{}.amazonaws.com/{}/' \
                '.well-known/jwks.json'.format(
                        'us-west-2',
                        'xxx')
    # get the keys
    jwks = requests.get(jwks_url).json()
    return jwt.decode(token, jwks, options={"verify_aud": False})
