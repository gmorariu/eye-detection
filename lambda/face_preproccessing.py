import dlib
import imutils
import time
import io
from imutils import face_utils
import cv2
import numpy as np
import json
import boto3
import tempfile
from boto3.dynamodb.conditions import Key
import requests
from jose import jwt
from pprint import pprint
from math import *
from datetime import datetime

detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("xxx")

dynamodb = boto3.resource('dynamodb')
cases = dynamodb.Table('camcussion_cases_v2')
subjects = dynamodb.Table('camcussion_subjects')

s3 = boto3.client('s3')
bucket = "camcussion"

sns_client = boto3.client('sns')

test = False
test_subject_uuid = "1c44697c-06e7-456d-898e-e14ef281bf8d"
test_case_uuid = "681d94a7-a24a-4063-843f-1730bb2ef98b"

#test_subject_uuid = "1c44697c-06e7-456d-898e-e14ef281bf8d"
#test_case_uuid = "01dc5907-7095-4bb7-b01e-4d7181effb24"

def lambda_handler(event, context):

    if test == False:
        print(event)
        try:
            subject_uuid = event['subject_uuid']
            case_uuid = event["case_uuid"]
        except:
            print("Not found")
            return {
                'statusCode': 401
            }
    else:
        subject_uuid = test_subject_uuid
        case_uuid = test_case_uuid

    print("subject_uuid: " + subject_uuid)
    print("case_uuid: " + case_uuid)
    subject_data = subjects.get_item(Key={'id':subject_uuid})
    subject_dict = subject_data['Item']
    subject_dict['dob'] = datetime.strptime(subject_dict['dob'], '%m/%d/%Y')

    cases_data = cases.query(
        KeyConditionExpression=Key('subject_uuid').eq(subject_uuid)
    )

    case_dict = None
    base_dict = None
    for c in cases_data['Items']:
        if c['id'] == case_uuid:
            case_dict = c
            continue
        if c['type'] == "test":
            continue
        c['timestamp'] = datetime.strptime(c['timestamp'], '%m/%d/%Y %H:%M')
        if base_dict == None:
            base_dict = c
        else:
            if base_dict['timestamp'] < c['timestamp']:
                base_dict = c

    #case_data = cases.get_item(Key={'subject_uuid': subject_uuid, 'id': case_uuid})
    #case_dict = case_data['Item']

    print(subject_dict)
    print(case_dict)
    print(base_dict)



    file_name = "new/"+subject_uuid+'/'+case_uuid+'/video.mp4'
    fn = "/tmp/video.mp4"
    img_path = "/tmp/thumbnail.jpeg"
    img_path_dest = "cases/"+subject_uuid+'/'+case_uuid+'/thumbnail.jpeg'
    img2_path = "/tmp/face.jpeg"
    img2_path_dest = "cases/"+subject_uuid+'/face.jpeg'
    video_ext = 'mp4'
    video_rotated = "/tmp/video_rotated.avi"

    video_path = "/tmp/video_cropped."+video_ext
    video_path_dest = "cases/"+subject_uuid+'/'+case_uuid+'/video.'+video_ext

    video_ext2 = 'webm'
    video2_path = "/tmp/video_cropped."+video_ext2
    video2_path_dest = "cases/"+subject_uuid+'/'+case_uuid+'/video.'+video_ext2


    f = open(fn, "wb")
    s3.download_fileobj(bucket, file_name, f)
    print("video downloaded in tmp")
    print(f.name)
    f.close()

    cap = cv2.VideoCapture(f.name)
    fps = cap.get(cv2.CAP_PROP_FPS)
    print("Frame rate : {0}".format(fps))
    print("Frame width : {0}".format(int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))))
    print("Frame height : {0}".format(int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))))
    size = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))

    #out = cv2.VideoWriter(video_path,cv2.VideoWriter_fourcc(*'mp4v'), cap.get(cv2.CAP_PROP_FPS), (size, size))
    out = cv2.VideoWriter(video_rotated,cv2.VideoWriter_fourcc(*'FFV1'), fps, (int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)),int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))))

    count = 0
    success = True
    min_size=None

    prevImage = None
    prevAngle = None
    currAngle = None
    p_r_x=None
    p_r_y=None
    p_l_x=None
    p_l_y=None
    max_jump_allowed=100
    max_rotation_allowed=0.8
    error_count = 0

    while success:
        success,image = cap.read()
        if not success:
            break
        if count%1 == 0 :
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            rects = detector(gray, 0)
            r_x=None
            r_y=None
            l_x=None
            l_y=None
            for (i, rect) in enumerate(rects):
                shape = predictor(gray, rect)
                shape = face_utils.shape_to_np(shape)
                for (name, (i, j)) in face_utils.FACIAL_LANDMARKS_IDXS.items():
                    pts = shape[i:j]
                    if name == "right_eye":
                        r_x = pts[0][0]
                        r_y = pts[0][1]
                    if name == "left_eye":
                        l_x = pts[3][0]
                        l_y = pts[3][1]

            if r_x is None:
                if prevImage is not None:
                    out.write(image)
                print("cannot detect eyes - skipping frame")
                error_count += 1
                continue
            if l_x-r_x < 300:
                if prevImage is not None:
                    out.write(image)
                print("image resolution too low - skipping frame")
                error_count += 1
                continue

            if p_r_x is not None:
                if ((r_x+max_jump_allowed) < p_r_x) or ((r_x-max_jump_allowed) > p_r_x):
                    print("too much shake - skipping frame")
                    if prevImage is not None:
                        out.write(image)
                    error_count += 1
                    continue
                if ((r_y+max_jump_allowed) < p_r_y) or ((r_y-max_jump_allowed) > p_r_y):
                    print("too much shake - skipping frame")
                    if prevImage is not None:
                        out.write(image)
                    error_count += 1
                    continue
                if ((l_x+max_jump_allowed) < p_l_x) or ((l_x-max_jump_allowed) > p_l_x):
                    print("too much shake - skipping frame")
                    if prevImage is not None:
                        out.write(image)
                    error_count += 1
                    continue
                if ((l_y+max_jump_allowed) < p_l_y) or ((l_y-max_jump_allowed) > p_l_y):
                    print("too much shake - skipping frame")
                    if prevImage is not None:
                        out.write(image)
                    error_count += 1
                    continue

            p_r_x=r_x
            p_r_y=r_y
            p_l_x=l_x
            p_l_y=l_y

            if r_y > l_y:
                #print("angle:-", degrees(atan(abs(r_y-l_y)/abs(r_x-l_x))))
                if prevAngle is not None:
                    if ((prevAngle-max_rotation_allowed)>( -degrees(atan(abs(r_y-l_y)/abs(r_x-l_x))))) or ((prevAngle+max_rotation_allowed)<( -degrees(atan(abs(r_y-l_y)/abs(r_x-l_x))))):
                        print("too much rotation - skipping frame")
                        if prevImage is not None:
                            out.write(image)
                        error_count += 1
                        continue
                currAngle = -degrees(atan(abs(r_y-l_y)/abs(r_x-l_x)))
            else:
                #print("angle:", degrees(atan(abs(r_y-l_y)/abs(r_x-l_x))))
                if prevAngle is not None:
                    if ((prevAngle-max_rotation_allowed)>( degrees(atan(abs(r_y-l_y)/abs(r_x-l_x))))) or ((prevAngle+max_rotation_allowed)<( degrees(atan(abs(r_y-l_y)/abs(r_x-l_x))))):
                        print("too much rotation - skipping frame")
                        if prevImage is not None:
                            out.write(image)
                        error_count += 1
                        continue
                currAngle = degrees(atan(abs(r_y-l_y)/abs(r_x-l_x)))

            if prevAngle is not None:
                if currAngle is None:
                    currAngle = prevAngle
                else:
                    currAngle = (currAngle+3*prevAngle)/4

            num_rows, num_cols = image.shape[:2]
            if currAngle<0:
                rotation_matrix = cv2.getRotationMatrix2D((int(r_x), int(r_y)), (360+currAngle), 1)
                image = cv2.warpAffine(image, rotation_matrix, (num_cols, num_rows))
            else:
                rotation_matrix = cv2.getRotationMatrix2D((int(r_x), int(r_y)), (0+currAngle), 1)
                image = cv2.warpAffine(image, rotation_matrix, (num_cols, num_rows))
            prevAngle = currAngle
            #print("prevAngle:", prevAngle)
            if min_size == None:
                min_size = l_x-r_x
            elif (min_size>(l_x-r_x)):
                min_size = l_x-r_x
            prevImage = image
            out.write(image)
        count+=1
        if error_count > 9:
            out.release()
            response = cases.update_item(
                Key={
                    'id': case_uuid,
                    'subject_uuid': subject_uuid
                },
                UpdateExpression="set validated_result = :v",
                ExpressionAttributeValues={
                    ':v': 'insufficient_data'
                },
                ReturnValues="UPDATED_NEW"
            )
            return {
                'statusCode': 200,
                'isBase64Encoded': False,
                'headers': { 'Content-Type': 'application/json'},
                'body': json.dumps({})
            }
    out.release()
    print("number of errors in aligning: "+str(error_count))
    print("detected frame size is "+str(min_size))

    if min_size < 300:
        response = cases.update_item(
            Key={
                'id': case_uuid,
                'subject_uuid': subject_uuid
            },
            UpdateExpression="set validated_result = :v",
            ExpressionAttributeValues={
                ':v': 'insufficient_data'
            },
            ReturnValues="UPDATED_NEW"
        )
        return {
            'statusCode': 200,
            'isBase64Encoded': False,
            'headers': { 'Content-Type': 'application/json'},
            'body': json.dumps({})
        }

    prevImage = None
    p_r_x=None
    p_r_y=None
    p_l_x=None
    p_l_y=None
    max_jump_allowed=100
    error_count = 0
    count = 0
    cap1 = cv2.VideoCapture(video_rotated)
    out1 = cv2.VideoWriter(video_path,cv2.VideoWriter_fourcc(*'mp4v'), cap.get(cv2.CAP_PROP_FPS), (min_size,min_size))
    out2 = cv2.VideoWriter(video2_path,cv2.VideoWriter_fourcc(*'vp80'), cap.get(cv2.CAP_PROP_FPS), (min_size, min_size))
    success = True

    while success:
        success,image = cap1.read()
        if not success:
            break

        r_x=None
        r_y=None
        l_x=None
        l_y=None
        if count%1 == 0 :
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            rects = detector(gray, 0)
            for (i, rect) in enumerate(rects):
                shape = predictor(gray, rect)
                shape = face_utils.shape_to_np(shape)

                if count == 0:
                    height, width, channels = image.shape
                    radius = shape[8][1] - shape[29][1]
                    if radius*2 > width:
                        radius = int(width/2)
                    if radius*2 > height:
                        radius = int(height/2)
                    sq_y = shape[29][1]-radius
                    sq_x = shape[29][0]-radius
                    if sq_y < 0:
                        sq_y = 0
                    if sq_x < 0:
                        sq_x = 0
                    roi2 = image[sq_y:sq_y+radius+radius, sq_x:sq_x+radius+radius]

                for (name, (i, j)) in face_utils.FACIAL_LANDMARKS_IDXS.items():
                    pts = shape[i:j]
                    if name == "right_eye":
                        r_x = pts[0][0]
                        r_y = pts[0][1]
                    if name == "left_eye":
                        l_x = pts[3][0]
                        l_y = pts[3][1]

            if r_x is None:
                if prevImage is not None:
                    out.write(image)
                error_count += 1
                print("cannot detect eyes - skipping frame")
                continue
            if l_x-r_x < 300:
                if prevImage is not None:
                    out.write(image)
                error_count += 1
                print("image resolution too low - skipping frame")
                continue

            if p_r_x is not None:
                if ((r_x+max_jump_allowed) < p_r_x) or ((r_x-max_jump_allowed) > p_r_x):
                    print("too much shake - skipping frame")
                    if prevImage is not None:
                        out.write(image)
                    error_count += 1
                    continue
                if ((r_y+max_jump_allowed) < p_r_y) or ((r_y-max_jump_allowed) > p_r_y):
                    print("too much shake - skipping frame")
                    if prevImage is not None:
                        out.write(image)
                    error_count += 1
                    continue
                if ((l_x+max_jump_allowed) < p_l_x) or ((l_x-max_jump_allowed) > p_l_x):
                    print("too much shake - skipping frame")
                    if prevImage is not None:
                        out.write(image)
                    error_count += 1
                    continue
                if ((l_y+max_jump_allowed) < p_l_y) or ((l_y-max_jump_allowed) > p_l_y):
                    print("too much shake - skipping frame")
                    if prevImage is not None:
                        out.write(image)
                    error_count += 1
                    continue
                r_x = int((3*p_r_x+r_x)/4)
                r_y = int((3*p_r_y+r_y)/4)
                l_x = int((3*p_l_x+l_x)/4)
                l_y = int((3*p_l_y+l_y)/4)
            p_r_x=r_x
            p_r_y=r_y
            p_l_x=l_x
            p_l_y=l_y

            roi = image[int(((l_y+r_y)/2)-((l_x-r_x)/2)):int(((l_y+r_y)/2)+((l_x-r_x)/2)), r_x:l_x]
            roi = imutils.resize(roi, width=min_size, inter=cv2.INTER_CUBIC)
            if count == 0:
                cv2.imwrite(img_path, roi)
                response = s3.upload_file(img_path, bucket, img_path_dest)
                if case_dict['type'] != 'test':
                    cv2.imwrite(img2_path, roi2)
                    response = s3.upload_file(img2_path, bucket, img2_path_dest)
                print("Image written")
            prevImage = roi
            out1.write(roi)
            out2.write(roi)
        count+=1
        if error_count > 9:
            out1.release()
            out2.release()
            response = cases.update_item(
                Key={
                    'id': case_uuid,
                    'subject_uuid': subject_uuid
                },
                UpdateExpression="set validated_result = :v",
                ExpressionAttributeValues={
                    ':v': 'insufficient_data'
                },
                ReturnValues="UPDATED_NEW"
            )
            return {
                'statusCode': 200,
                'isBase64Encoded': False,
                'headers': { 'Content-Type': 'application/json'},
                'body': json.dumps({})
            }
    out1.release()
    out2.release()

    print("number of errors on cropping: "+str(error_count))



    response = s3.upload_file(video_path, bucket, video_path_dest)
    response = s3.upload_file(video2_path, bucket, video2_path_dest)

    print("video cropped")
    if case_dict['type'] == 'test':
        response = cases.update_item(
            Key={
                'id': case_uuid,
                'subject_uuid': subject_uuid
            },
            UpdateExpression="set recording_link = :r, thumbnail_link = :t, validated_result = :v",
            ExpressionAttributeValues={
                ':r': 'https://xxx.us-west-2.amazonaws.com/cases/'+subject_uuid+'/'+case_uuid+'/video.mp4',
                ':t': 'https://xxx.us-west-2.amazonaws.com/cases/'+subject_uuid+'/'+case_uuid+'/thumbnail.jpeg',
                ':v': 'new'
            },
            ReturnValues="UPDATED_NEW"
        )
    else:
        response = cases.update_item(
            Key={
                'id': case_uuid,
                'subject_uuid': subject_uuid
            },
            UpdateExpression="set recording_link = :r, thumbnail_link = :t, validated_result = :v",
            ExpressionAttributeValues={
                ':r': 'https://xxx.us-west-2.amazonaws.com/cases/'+subject_uuid+'/'+case_uuid+'/video.mp4',
                ':t': 'https://xxx.us-west-2.amazonaws.com/cases/'+subject_uuid+'/'+case_uuid+'/thumbnail.jpeg',
                ':v': 'no_concussion'
            },
            ReturnValues="UPDATED_NEW"
        )
    print("database updated")
    if case_dict['type'] == 'test':
        generate_case_page(subject_dict, case_dict, base_dict)
        print("case page created")
    else:
        print("baseline case - skipping case page generation")


    return {
        'statusCode': 200,
        'isBase64Encoded': False,
        'headers': { 'Content-Type': 'application/json'},
        'body': json.dumps({'recording_link': 'https://xxx.us-west-2.amazonaws.com/cases/'+subject_uuid+'/'+case_uuid+'/video.mp4',
            'thumbnail_link': 'https://xxx.us-west-2.amazonaws.com/cases/'+subject_uuid+'/'+case_uuid+'/thumbnail.jpeg'
        })
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

def junk():
    success = True
    count = 0
    while success:
        success,image = cap.read()
        if not success:
            break
        image = image[0:size, 0:size]
        if count == 0:
            cv2.imwrite(img_path, image)
            response = s3.upload_file(img_path, bucket, img_path_dest)
            print("Image written")
        out.write(image)
        count+=1
    out.release()

def generate_case_page(subject, case, base):
    f = io.open("case_t.html",'r', encoding="utf-8")
    filedata = f.read()
    f.close()

    filedata = filedata.replace("{{@base_video_url_webm}}",  'https://xxx.us-west-2.amazonaws.com/cases/'+subject['id']+'/'+base['id']+'/video.webm')
    filedata = filedata.replace("{{@case_video_url_webm}}",  'https://xxx.us-west-2.amazonaws.com/cases/'+subject['id']+'/'+case['id']+'/video.webm')
    filedata = filedata.replace("{{@base_video_url_mp4}}",  'https://xxx.us-west-2.amazonaws.com/cases/'+subject['id']+'/'+base['id']+'/video.mp4')
    filedata = filedata.replace("{{@case_video_url_mp4}}",  'https://xxx.us-west-2.amazonaws.com/cases/'+subject['id']+'/'+case['id']+'/video.mp4')
    filedata = filedata.replace("{{@gender}}",  subject['gender'])
    filedata = filedata.replace("{{@age}}",  str(calculateAge(subject['dob'])))
    answers = case['questions_answers']

    for a in answers:
        if a['question'] == 'Aware of location':
            filedata = filedata.replace("{{@location}}",  a['answer'])
        if a['question'] == 'Can count or repeat words backwards':
            filedata = filedata.replace("{{@backwards}}",  a['answer'])
        if a['question'] == 'Nausea':
            filedata = filedata.replace("{{@nausea}}",  a['answer'])
        if a['question'] == 'Dizziness':
            filedata = filedata.replace("{{@dizziness}}",  a['answer'])
        if a['question'] == 'Sensitivity to light':
            filedata = filedata.replace("{{@sensitivity_to_light}}",  a['answer'])
        if a['question'] == 'Sensitivity to sound':
            filedata = filedata.replace("{{@sensitivity_to_sound}}",  a['answer'])

    apiulr='https://xxx.execute-api.us-west-2.amazonaws.com/prod/cases/diagnostic?subject_uuid='+subject['id']+'&case_uuid='+case['id']+'&diagnostic='

    filedata = filedata.replace("{{@no_concussion}}",  apiulr+'no_concussion')
    filedata = filedata.replace("{{@insufficient_data}}",  apiulr+'insufficient_data')
    filedata = filedata.replace("{{@concussion}}",  apiulr+'concussion')

    f = io.open('/tmp/index.html','w')
    f.write(filedata)
    f.close()

    response = s3.upload_file('/tmp/index.html', bucket, "cases/"+subject['id']+'/'+case['id']+'/index.html', ExtraArgs={'ContentType': 'text/html'})

    response = sns_client.publish(
        PhoneNumber='xxx',
        Message='A new case is ready to review: https://xxx.us-west-2.amazonaws.com/cases/'+subject['id']+'/'+case['id']+'/index.html',
        MessageAttributes={
            'AWS.MM.SMS.OriginationNumber': {
                'DataType': 'String',
                'StringValue': 'xxx'
            }
        }
    )
    if test == False:
        response = sns_client.publish(
            PhoneNumber='xxx',
            Message='A new case is ready to review: https://xxx.us-west-2.amazonaws.com/cases/'+subject['id']+'/'+case['id']+'/index.html',
            MessageAttributes={
                'AWS.MM.SMS.OriginationNumber': {
                    'DataType': 'String',
                    'StringValue': 'xxx'
                }
            }
        )

def calculateAge(birthDate):
    days_in_year = 365.2425
    age = int((datetime.now() - birthDate).days / days_in_year)
    return age
