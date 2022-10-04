import json
import boto3
from boto3.dynamodb.conditions import Key
import requests
from jose import jwt
from pprint import pprint
import uuid


lambda_client = boto3.client('lambda')

dynamodb = boto3.resource('dynamodb')
users = dynamodb.Table('camcussion_users')
subjects = dynamodb.Table('camcussion_subjects')
cases = dynamodb.Table('camcussion_cases_v2')

def lambda_handler(event, context):
    print(event)
    try:
        token = event['headers']['authorization']
        decoded_token = decode_token(token)
        user=getUserID(token)
        case = json.loads(event['body'])
        subject_uuid = case['subject_uuid']
        case_uuid = case["id"]

        #TODO validate that token can read cases for given subject
        #TODO validate the case exists
    except:
        print("Not found")
        return {
            'statusCode': 401
        }

    #subject_uuid = '5d1c9747-f4b6-4e71-88c0-a2f7934640ab'
    #case_uuid = '2b21f7a7-aeec-4500-aa1f-a49a995df71d'
    response = lambda_client.invoke_async(
        FunctionName = 'arn:aws:lambda:us-west-2:XXX:function:camcussion-face-preproccessing',
        InvokeArgs = json.dumps({'subject_uuid': subject_uuid, 'case_uuid':case_uuid})
    )


    print(response)
    return {
        'statusCode': 200,
        'isBase64Encoded': False,
        'headers': { 'Content-Type': 'application/json'},
        'body': json.dumps({'recording_link': '',
            'thumbnail_link': ''
        })
    }


def getUserID(token):
    client = boto3.client('cognito-identity')
    l={'cognito-idp.us-west-2.amazonaws.com/xxx': token}
    u=client.get_id(AccountId='xxx', IdentityPoolId='uxxx', Logins=l)
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
