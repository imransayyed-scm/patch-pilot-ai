# patch-pilot-ai - Terraform conversion (corrected)

This Terraform project maps the architecture described in the repo:
- Frontend: S3 + CloudFront (React Vite build)
- Backend: Lambda + API Gateway (HTTP API)
- Database: DynamoDB
- Automation: EventBridge scheduler to sync findings (Inspector) hourly
- IAM: Roles for Lambda with SSM & Inspector permissions
- Expects Google Gemini API Key to be provided as environment variable for the analyze lambda

Use the example root module to deploy a proof-of-concept. Tighten IAM policies before production.

patch-pilot-ai/
├── terraform/
│   ├── main.tf                 # Root module: orchestrates everything
│   ├── variables.tf            # Root variables (project name, region, API key)
│   ├── outputs.tf              # Root outputs (like the final API URL)
│   ├── terraform.tfvars.example # Example for user to copy for their secrets
│   │
│   ├── backend_code/             # SOURCE CODE FOR YOUR LAMBDAS
│   │   ├── get_findings/
│   │   │   ├── app.py
│   │   │   └── requirements.txt
│   │   ├── analyze_finding/
│   │   │   ├── app.py
│   │   │   └── requirements.txt
│   │   └── deploy_fix/
│   │       ├── app.py
│   │       └── requirements.txt
│   │
│   └── modules/                  # REUSABLE TERRAFORM MODULES
│       ├── api_gateway/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── dynamodb_table/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── lambda_function/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── scheduler/
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
│
└── patch-pilot-frontend/
    └── ... (frontend code remains the same)
