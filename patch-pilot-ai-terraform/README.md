# patch-pilot-ai - Terraform conversion (modules)

# 1) Ensure your repo has the lambda folders:
#    src/get_findings, src/analyze_finding, src/deploy_fix
#    each containing app.py (handler: app.lambda_handler)

# 2) Set your AWS creds for the target account/region
export AWS_PROFILE=your-profile
export AWS_REGION=ap-south-1

# 3) Initialize & apply
terraform init
terraform plan -var="llm_api_key=YOUR_SECRET_KEY"
terraform apply -auto-approve -var="llm_api_key=YOUR_SECRET_KEY"

# 4) Get the API URL
terraform output api_base_url

#Notes / tips:

LLM key is stored as a Lambda env var (LLM_API_KEY). For production, consider AWS Secrets Manager and an IAM policy to read it at runtime instead.
I set broad SSM permissions (ssm:SendCommand on *) to match the hackathon template; tighten to instance ARNs if you can.
The runtime defaults to python3.9 to align with your earlier code. Bump to python3.11/3.12 when your packaging/env is ready.
If your handlers aren’t named app.lambda_handler, update handler fields accordingly.
CloudFront + S3 for the React app,
Route53/ACM for a custom domain,
Secret Manager wiring for the LLM key.


Structure:
```
patch-pilot-ai-terraform/
├── modules/
│   ├── lambda/
│   ├── s3/
│   ├── dynamodb/
│   ├── ses/
│   ├── eventbridge/
│   └── iam/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

> Note: You may need to verify SES email/domain in your account (SES may require identity verification and sandbox removal). Supply actual lambda zip files and adjust IAM policies to least privilege for production.
