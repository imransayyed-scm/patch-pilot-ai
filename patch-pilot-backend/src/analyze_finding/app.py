import boto3
import os
import json
import requests
import re

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])
LLM_API_KEY = os.environ.get('LLM_API_KEY')
LLM_API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key={LLM_API_KEY}"

def lambda_handler(event, context):
    finding_id = event['pathParameters']['findingId']
    
    response = table.get_item(Key={'id': finding_id})
    item = response.get('Item')

    if not item:
        return {'statusCode': 404, 'body': json.dumps('Finding not found')}

    package_name = item.get('title', '').split(' ')[-1]
    
    prompt = f"""
    You are an expert cybersecurity analyst. Your task is to analyze a vulnerability and provide a report in a valid JSON format.

    **Finding Details:**
    - CVE ID: {item.get('packageName', 'N/A')}
    - Vulnerability Title: {item.get('title')}
    - Package Name: {package_name}
    - Vulnerable OS: Amazon Linux 2

    **Your Response (MUST be a single, valid JSON object with NO markdown, comments, or extra text):**
    {{
      "riskSummary": "Provide a 2-3 sentence summary explaining the business impact of this vulnerability. Focus on what an attacker could do.",
      "suggestedFix": "Provide the single, specific shell command to fix this vulnerability using yum. For example: 'sudo yum update {package_name} -y'."
    }}
    """
    
    payload = {"contents":[{"parts":[{"text": prompt}]}]}
    headers = {'Content-Type': 'application/json'}
    response = requests.post(LLM_API_URL, json=payload, headers=headers)
    
    if response.status_code != 200:
        return {'statusCode': 502, 'body': json.dumps(f"Error from LLM API: {response.text}")}

    try:
        response_json = response.json()
        ai_response_text = response_json['candidates'][0]['content']['parts'][0]['text']
        
        match = re.search(r'\{.*\}', ai_response_text, re.DOTALL)
        clean_json_text = match.group(0) if match else ai_response_text
        ai_data = json.loads(clean_json_text)

    except (KeyError, IndexError, json.JSONDecodeError) as e:
        return {'statusCode': 500, 'body': json.dumps(f'Failed to parse AI response. Error: {e}. Raw Text: {ai_response_text}')}

    table.update_item(
        Key={'id': finding_id},
        UpdateExpression="set riskSummary=:r, suggestedFix=:f, #s=:t",
        ExpressionAttributeValues={':r': ai_data['riskSummary'], ':f': ai_data['suggestedFix'], ':t': 'Analyzed'},
        ExpressionAttributeNames={"#s": "status"}
    )

    return {'statusCode': 200, 'headers': {'Access-Control-Allow-Origin': '*'}, 'body': json.dumps({'message': 'Analysis complete'})}
