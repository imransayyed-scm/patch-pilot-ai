# Patch Pilot AI 🛡️ (Terraform Edition)

**Patch Pilot is an AI-powered security co-pilot that automates the entire lifecycle of vulnerability remediation on AWS. This repository provides the complete application, fully defined and deployable with modular Terraform.**

This guide explains how to deploy the entire backend (API, database, functions) and frontend (S3, CloudFront) infrastructure using a single set of Terraform commands.

---

### ✅ Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Terraform CLI** (v1.3 or higher).
2.  **AWS CLI** installed and configured (`aws configure`).
3.  **Node.js and npm** (v18 or higher).
4.  **Python** (v3.9 or higher) and `pip`.
5.  **A Google Gemini API Key** from [Google AI Studio](https://aistudio.google.com/app/apikey).
6.  **A vulnerable EC2 instance** configured in your AWS account:
    *   Launch an **Amazon Linux 2** instance (not Amazon Linux 2023).
    *   Attach an IAM Role to it with the `AmazonSSMManagedInstanceCore` managed policy.
    *   Enable **Amazon Inspector v2** in your AWS account.

### 🏛️ Architecture

The application is composed of two main parts, both managed by Terraform:
*   **Backend:** A serverless API built with API Gateway, Lambda, and DynamoDB, with an EventBridge Scheduler for autonomous operation.
*   **Frontend:** A React Single-Page Application hosted on a private S3 bucket and delivered globally and securely via CloudFront with Origin Access Control (OAC).

### 🚀 Deployment Guide

Follow these steps to deploy the entire application from your local machine.

#### **Step 1: Configure Secrets**

1.  Navigate to the `terraform/` directory.
2.  Copy the example variables file:
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```
3.  Open the newly created `terraform.tfvars` file and paste in your Google Gemini API key. This file is ignored by git and keeps your secrets safe.

#### **Step 2: Deploy All Infrastructure with Terraform**

This single set of commands will create both the backend API and the frontend hosting infrastructure.

1.  Navigate to the `terraform/` directory.
2.  Initialize Terraform to download the necessary providers and modules:
    ```bash
    terraform init
    ```
3.  Review the planned changes (optional but recommended):
    ```bash
    terraform plan
    ```
4.  Apply the configuration to deploy all resources to your AWS account:
    ```bash
    terraform apply -auto-approve
    ```
5.  After the apply is complete, Terraform will print several outputs. These will be used in the next steps.

#### **Step 3: Configure and Build the Frontend**

1.  Navigate to the `patch-pilot-frontend/` directory.
2.  Create the local environment file and populate it with the API Gateway URL output from Terraform. This command does it for you:
    ```bash
    echo "VITE_API_URL=$(terraform -chdir=../terraform output -raw api_gateway_endpoint)" > .env.local
    ```
3.  Install dependencies and build the static website files:
    ```bash
    npm install
    npm run build
    ```

#### **Step 4: Upload Frontend to S3**

1.  Use the AWS CLI to sync your built `dist` folder to the S3 bucket created by Terraform. This command reads the bucket name directly from the Terraform state:
    ```bash
    aws s3 sync ./dist/ s3://$(terraform -chdir=../terraform output -raw frontend_s3_bucket_id)
    ```

#### **Step 5: Invalidate CloudFront Cache**

This final step makes your website changes live on the CDN.

1.  Use the AWS CLI to create a cache invalidation, reading the distribution ID from the Terraform state:
    ```bash
    aws cloudfront create-invalidation --distribution-id $(terraform -chdir=../terraform output -raw frontend_cloudfront_distribution_id) --paths "/*"
    ```

**Deployment is complete!** Your application is now live. Find the URL from the Terraform output:
```bash
terraform -chdir=../terraform output -raw frontend_website_url
```

### 🧹 Cleanup

To avoid ongoing AWS charges, you can destroy all the resources created by this project with a single command.

1.  Navigate to the `terraform/` directory.
2.  Run the destroy command:
    ```bash
    terraform destroy -auto-approve
    ```
---
