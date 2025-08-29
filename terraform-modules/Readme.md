# Patch Pilot AI 🛡️ (Terraform Edition)

**Patch Pilot is an AI-powered security co-pilot that automates the entire lifecycle of vulnerability remediation on AWS. This repository provides the complete application, fully defined and deployable with modular Terraform.**

---

### ✅ Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Terraform CLI** (v1.3 or higher).
2.  **AWS CLI** installed and configured (`aws configure`).
3.  **Node.js and npm** (v18 or higher).
4.  **Python** (v3.9 or higher) and `pip`.
5.  **A Google Gemini API Key** from [Google AI Studio](https://aistudio.google.com/app/apikey).
6.  **A vulnerable EC2 instance** configured in your AWS account (see previous guides).

### 🏛️ Architecture

The application is composed of two main parts, both managed by Terraform:
*   **Backend:** A serverless API built with API Gateway, Lambda, and DynamoDB, with an EventBridge Scheduler for autonomous operation.
*   **Frontend:** A React Single-Page Application hosted on S3 and delivered globally via CloudFront.

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
2.  Initialize Terraform to download the necessary providers:
    ```bash
    terraform init
    ```
3.  Apply the configuration to deploy all resources to your AWS account:
    ```bash
    terraform apply -auto-approve
    ```
4.  After the apply is complete, Terraform will print several outputs. **Note these three values for the next steps:**
    *   `api_gateway_endpoint`
    *   `frontend_s3_bucket_id`
    *   `frontend_cloudfront_distribution_id`

#### **Step 3: Configure and Build the Frontend**

1.  Navigate to the `patch-pilot-frontend/` directory.
2.  Create the local environment file and populate it with the API Gateway URL you just copied:
    ```bash
    echo "VITE_API_URL=$(terraform -chdir=../terraform output -raw api_gateway_endpoint)" > .env.local
    ```
3.  Install dependencies and build the static website files:
    ```bash
    npm install
    npm run build
    ```

#### **Step 4: Upload Frontend to S3**

1.  Use the AWS CLI to sync your built `dist` folder to the S3 bucket created by Terraform.
    ```bash
    # Replace BUCKET_NAME with the 'frontend_s3_bucket_id' output from Terraform
    aws s3 sync ./dist/ s3://BUCKET_NAME
    ```

#### **Step 5: Invalidate CloudFront Cache**

This final step makes your website changes live on the CDN.

1.  Use the AWS CLI to create a cache invalidation.
    ```bash
    # Replace DISTRIBUTION_ID with the 'frontend_cloudfront_distribution_id' output
    aws cloudfront create-invalidation --distribution-id DISTRIBUTION_ID --paths "/*"
    ```

**Deployment is complete!** Your application is now live at the `frontend_website_url` shown in the Terraform output.

### 🧹 Cleanup

To avoid ongoing AWS charges, you can destroy all the resources created by this project with a single command.

1.  Navigate to the `terraform/` directory.
2.  Run the destroy command:
    ```bash
    terraform destroy -auto-approve
    ```

---
