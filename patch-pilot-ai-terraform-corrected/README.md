# patch-pilot-ai - Terraform conversion (corrected)

This Terraform project maps the architecture described in the repo:
- Frontend: S3 + CloudFront (React Vite build)
- Backend: Lambda + API Gateway (HTTP API)
- Database: DynamoDB
- Automation: EventBridge scheduler to sync findings (Inspector) hourly
- IAM: Roles for Lambda with SSM & Inspector permissions
- Expects Google Gemini API Key to be provided as environment variable for the analyze lambda

Use the example root module to deploy a proof-of-concept. Tighten IAM policies before production.
