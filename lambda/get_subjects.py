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
    except :
        return {
            'statusCode': 401
        }
    print('getting data for user '+ decoded_token['sub'])
    data = users.query(
        KeyConditionExpression=Key('id').eq(decoded_token['sub'])
    )
    print(data)
    result = []
    if data['Items']:
        for group in data['Items']:
            for subject in group['subjects']:
                subject_data = subjects.get_item(Key={'id':subject})
                sbj = subject_data['Item']
                sbj['team'] = group['subject_group_name']
                result.append(sbj)
    else:
        #There are no teams created for this user. Create one for now until we decide to deal with multiple teams
        print('creating default subject group for user '+ decoded_token['sub'])
        user = {}
        user['id'] = decoded_token['sub']
        user['subject_group_uuid'] = str(uuid.uuid4())
        user['subject_group_name'] = 'My Team'
        user['subjects'] = []
        response = users.put_item(Item=user)


    #print(result)
    return {
        'statusCode': 200,
        'isBase64Encoded': False,
        'headers': { 'Content-Type': 'application/json'},
        'body': json.dumps({'Items':result})
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
