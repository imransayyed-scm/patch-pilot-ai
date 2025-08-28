# patch-pilot-ai - Terraform conversion (modules)

This repo contains Terraform **reusable modules** and a root example to deploy the core resources used by the original `patch-pilot-ai` application:
- Lambda functions (zip path must be supplied)
- S3 bucket for reports
- DynamoDB table for email recipients
- SES email identity (sender)
- EventBridge scheduled rule
- IAM role for Lambda

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
