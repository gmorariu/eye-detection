import json
import boto3
from boto3.dynamodb.conditions import Key
import requests
from jose import jwt
from pprint import pprint

dynamodb = boto3.resource('dynamodb')
users = dynamodb.Table('camcussion_users')
subjects = dynamodb.Table('camcussion_subjects')
cases = dynamodb.Table('camcussion_cases_v2')


def lambda_handler(event, context):
    #print(event)
    try:
        token = event['headers']['authorization']
        decoded_token = decode_token(token)
        user=getUserID(token)
        #TODO validate that token can read cases for given subject
    except:
        return {
            'statusCode': 401
        }
    subject_id = event['queryStringParameters']['subject_uuid']
    print('getting cases for subject '+ subject_id)
    #print(decoded_token)

    #scan_kwargs = {
    #    'FilterExpression': Key('manager_id').eq('53049d49-8d76-44e8-b5e3-b4cabe8b44d0'),
        #'FilterExpression': Key('id').eq('68f32e5e-7d98-47c4-b652-66a2d932e834')
    #}
    #data = table.scan(**scan_kwargs)
    data = cases.query(
        KeyConditionExpression=Key('subject_uuid').eq(subject_id)
    )
    #print(data)
    return {
        'statusCode': 200,
        'isBase64Encoded': False,
        'headers': { 'Content-Type': 'application/json'},
        'body': json.dumps(data)
    }

def getUserID(token):
    client = boto3.client('cognito-identity')
    l={'cognito-idp.us-west-2.amazonaws.com/xxx': token}
    u=client.get_id(AccountId='xxx', IdentityPoolId='xxx', Logins=l)
    return u['IdentityId']

def decode_token(token):
    # build the URL where the public keys are
    jwks_url = 'https://cognito-idp.{}.amazonaws.com/{}/' \
                '.well-known/jwks.json'.format(
                        'us-west-2',
                        'xxx')
    # get the keys
    jwks = requests.get(jwks_url).json()
    return jwt.decode(token, jwks, options={"verify_aud": False})
