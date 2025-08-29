import boto3
import os
import json

inspector_client = boto3.client('inspector2')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    filter_criteria = {
        'findingStatus': [{'comparison': 'EQUALS', 'value': 'ACTIVE'}],
        'severity': [{'comparison': 'EQUALS', 'value': 'CRITICAL'}, {'comparison': 'EQUALS', 'value': 'HIGH'}]
    }
    
    paginator = inspector_client.get_paginator('list_findings')
    pages = paginator.paginate(filterCriteria=filter_criteria)

    for page in pages:
        for finding in page.get('findings', []):
            finding_id = finding['findingArn'].split('/')[-1]
            
            # Check if item exists to avoid duplicate processing
            response = table.get_item(Key={'id': finding_id})
            if 'Item' in response:
                continue # Skip if already in DB

            item = {
                'id': finding_id,
                'title': finding['title'],
                'severity': finding['severity'],
                'instanceId': finding.get('resources', [{}])[0].get('id', 'N/A'),
                'packageName': finding.get('packageVulnerabilityDetails', {}).get('vulnerabilityId', 'N/A'),
                'status': 'New'
            }
            table.put_item(Item=item)
    
    # Return all items currently in the table
    response = table.scan()
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(response.get('Items', []))
    }