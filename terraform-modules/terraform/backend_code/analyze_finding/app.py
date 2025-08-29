import boto3
import os
import json
import requests
import re # Import the regular expression library

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

    # Extract the package name more robustly
    package_name = item.get('title', '').split(' ')[-1]
    
    prompt = f"""
    You are an expert cybersecurity analyst and AWS professional named 'Patch Pilot'.
    Your task is to analyze a vulnerability finding and provide a clear, concise, and actionable report in a valid JSON format.

    **Finding Details:**
    - CVE ID: {item.get('packageName', 'N/A')}
    - Vulnerability Title: {item.get('title')}
    - Package Name: {package_name}
    - Vulnerable OS: Amazon Linux 2

    **Your Response (MUST be a single, valid JSON object with NO markdown formatting, no comments, and no extra text):**
    {{
      "riskSummary": "Provide a 2-3 sentence summary explaining the business impact of this vulnerability. Focus on what an attacker could do.",
      "suggestedFix": "Provide the single, specific shell command needed to fix this vulnerability using the AWS Systems Manager (SSM) Run Command. For Amazon Linux 2, this is almost always 'sudo yum update {package_name} -y'."
    }}
    """
    
    payload = {"contents":[{"parts":[{"text": prompt}]}]}
    headers = {'Content-Type': 'application/json'}
    response = requests.post(LLM_API_URL, json=payload, headers=headers)
    
    # --- V V V DEBUGGING LOGS V V V ---
    print("--- LLM API Response ---")
    print(f"Status Code: {response.status_code}")
    print(f"Raw Response Body: {response.text}")
    # --- ^ ^ ^ DEBUGGING LOGS ^ ^ ^ ---

    if response.status_code != 200:
        # If the API call itself failed, return an error
        return {'statusCode': 502, 'body': json.dumps(f"Error from LLM API: {response.text}")}

    response_json = response.json()
    
    # Extract the text and make it more robust
    try:
        ai_response_text = response_json['candidates'][0]['content']['parts'][0]['text']
        
        # --- V V V FIX: Clean the text before parsing V V V ---
        # Use regex to find content between ```json and ``` or just { and }
        match = re.search(r'```json\s*(\{.*?\})\s*```|(\{.*?\})', ai_response_text, re.DOTALL)
        if match:
            # Prioritize the explicitly marked JSON block, otherwise take the first JSON-like block
            clean_json_text = match.group(1) if match.group(1) else match.group(2)
        else:
            clean_json_text = ai_response_text # Fallback to original text if no block is found

        print(f"Cleaned text to be parsed: {clean_json_text}")
        ai_data = json.loads(clean_json_text)
        # --- ^ ^ ^ FIX ^ ^ ^ ---

    except (KeyError, IndexError, json.JSONDecodeError) as e:
        print(f"Failed to parse AI response. Error: {e}")
        print(f"Original AI Text was: {ai_response_text}")
        return {'statusCode': 500, 'body': json.dumps('Failed to parse response from AI model')}

    table.update_item(
        Key={'id': finding_id},
        UpdateExpression="set riskSummary=:r, suggestedFix=:f, #s=:t",
        ExpressionAttributeValues={
            ':r': ai_data['riskSummary'],
            ':f': ai_data['suggestedFix'],
            ':t': 'Analyzed'
        },
        ExpressionAttributeNames={
            "#s": "status"
        }
    )

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        },
        'body': json.dumps({'message': 'Analysis complete'})
    }