import json
import boto3
from boto3.dynamodb.conditions import Key, Attr
#import requests
#from jose import jwt
#from pprint import pprint
#import uuid


lambda_client = boto3.client('lambda')
sns_client = boto3.client('sns')
cognito = boto3.client('cognito-idp')

dynamodb = boto3.resource('dynamodb')
cases = dynamodb.Table('camcussion_cases_v2')
users = dynamodb.Table('camcussion_users')

def lambda_handler(event, context):
    print(event['queryStringParameters'])

    response = cases.update_item(
                    Key={
                        'subject_uuid': event['queryStringParameters']['subject_uuid'],
                        'id': event['queryStringParameters']['case_uuid']
                    },
                    UpdateExpression="set validated_result = :L",
                    ExpressionAttributeValues={
                        ':L': event['queryStringParameters']['diagnostic'],
                    },
                    ReturnValues="UPDATED_NEW"
                )
    print(response)

    try:
        scan_kwargs = {
            'FilterExpression': Attr('subjects').contains(event['queryStringParameters']['subject_uuid'])
        }
        response = users.scan(**scan_kwargs)

        print(response['Items'][0]['id'])
        response = cognito.list_users(
            UserPoolId='xxx',
            Filter='sub = "'+response['Items'][0]['id']+'"'
        )
        notification_number=None
        for a in response['Users'][0]['Attributes']:
            if a['Name'] == 'phone_number':
                notification_number = a['Value']

        if notification_number:
            print('Notification sent')
            response = sns_client.publish(
                PhoneNumber=notification_number,
                Message='New incident results are available.',
                MessageAttributes={
                    'AWS.MM.SMS.OriginationNumber': {
                        'DataType': 'String',
                        'StringValue': 'xxx'
                    }
                }
            )
        else:
            print('No Notification sent - No number found')
    except Exception as e:
        print(e)






    return {
        'statusCode': 302,
        'headers': {
            'Location': 'https://xxx.us-west-2.amazonaws.com/casepageres/html/response-confirmation.html'
        },
        'body': json.dumps(event['queryStringParameters'])
    }
