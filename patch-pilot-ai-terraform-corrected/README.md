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
│   ├── main.tf                   # Root orchestration
│   ├── variables.tf              # Root variables (region, project, etc.)
│   ├── outputs.tf                # Root outputs (API URL, table name, etc.)
│   ├── terraform.tfvars.example  # Example vars
│   │
│   ├── backend_code/             # Lambda source code
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
│   └── modules/
│       ├── api_gateway/          # HTTP API Gateway module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── dynamodb_table/       # DynamoDB module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── lambda_function/      # Generic Lambda module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── scheduler/            # EventBridge scheduler
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
│
└── patch-pilot-frontend/
    └── ... (frontend React code unchanged)
