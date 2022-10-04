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
cases = dynamodb.Table('camcussion_cases_v2')


def lambda_handler(event, context):
    try:
        print(event)
        token = event['headers']['authorization']
        decoded_token = decode_token(token)
        user=getUserID(token)
        case = json.loads(event['body'])
        #TODO validate that token can write cases for given subject
    except:
        return {
            'statusCode': 401
        }

    #print(decoded_token)

    case["id"] = str(uuid.uuid4())
    case["validated_result"] = "preprocess"

    print('creating case for subject '+ case['subject_uuid'])
    response = cases.put_item(Item=case)
    print(response)

    return {
        'statusCode': 200,
        'isBase64Encoded': False,
        'headers': { 'Content-Type': 'application/json'},
        'body': json.dumps(case)
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
                        'XXX')
    # get the keys
    jwks = requests.get(jwks_url).json()
    return jwt.decode(token, jwks, options={"verify_aud": False})
