import boto3
import os
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])
ssm_client = boto3.client('ssm')

def lambda_handler(event, context):
    finding_id = event['pathParameters']['findingId']
    
    response = table.get_item(Key={'id': finding_id})
    item = response.get('Item')

    if not item or 'suggestedFix' not in item:
        return {'statusCode': 404, 'body': json.dumps('Finding or fix not found')}

    instance_id = item['instanceId']
    command = item['suggestedFix']

    ssm_client.send_command(
        InstanceIds=[instance_id],
        DocumentName='AWS-RunShellScript',
        Parameters={'commands': [command]}
    )
    
    table.update_item(
        Key={'id': finding_id},
        UpdateExpression="set #s=:t",
        ExpressionAttributeValues={':t': 'Patched'},
        ExpressionAttributeNames={"#s": "status"}
    )

    return {'statusCode': 200, 'headers': {'Access-Control-Allow-Origin': '*'}, 'body': json.dumps({'message': 'Patch command sent'})}
