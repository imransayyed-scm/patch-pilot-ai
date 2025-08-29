# Patch Pilot AI 🛡️

**Patch Pilot is an AI-powered security co-pilot that automates the entire lifecycle of vulnerability remediation on AWS, transforming cryptic CVE reports into one-click patches.**

This project solves the real-world problem of vulnerability alert fatigue and slow, manual patching processes by creating an autonomous agent that continuously monitors for threats and provides an intelligent interface for remediation.

---

### 🚀 The Problem

Cloud security tools like AWS Inspector are great at *finding* vulnerabilities, but they often leave developers and operations teams with significant challenges:
*   **Alert Overload:** A long list of CVEs with little context on the *actual business risk*.
*   **Remediation Complexity:** Figuring out the exact command or process to fix a specific vulnerability.
*   **Manual Toil:** The slow, error-prone process of manually applying patches, especially at scale.
*   **Stale Data:** A vulnerability dashboard is only useful if it's constantly updated with the latest threats.

### ✨ The Solution

Patch Pilot acts as an intelligent layer on top of AWS security services. It **autonomously syncs** with AWS Inspector every hour and provides a simple, one-click interface to analyze and deploy fixes securely.

**Key Features:**
*   **Automated Vulnerability Sync:** An Amazon EventBridge scheduler runs every hour to automatically fetch the latest findings from AWS Inspector, ensuring the dashboard is always up-to-date.
*   **Unified Dashboard:** Displays all active, critical vulnerabilities in a single, clean interface.
*   **AI-Powered Risk Analysis:** For each vulnerability, an LLM provides a clear, human-readable summary of the business risk.
*   **AI-Generated Fixes:** The system automatically generates the precise, safe command needed to patch the vulnerability.
*   **One-Click Remediation:** Deploys the fix using AWS Systems Manager (SSM) Run Command, eliminating the need for SSH and manual intervention.

### 🏛️ Architecture

The entire application is built on a serverless, event-driven architecture for maximum scalability and cost-efficiency.

*   **Frontend:** A React (Vite) single-page application hosted on **AWS S3** and distributed globally via **Amazon CloudFront**.
*   **Backend:** An API built with **Amazon API Gateway** and **AWS Lambda** (Python).
*   **Database:** **Amazon DynamoDB** to store and track the state of each vulnerability finding.
*   **Automation:** **Amazon EventBridge Scheduler** to trigger hourly data synchronization.
*   **Security & Operations:**
    *   **Amazon Inspector:** The source for vulnerability detection.
    *   **AWS Systems Manager (SSM):** The agent for securely executing patch commands.
    *   **Google Gemini API:** The external AI model used for analysis and solution generation.

---

### ✅ Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **AWS Account** with administrative privileges.
2.  **AWS CLI** installed and configured (`aws configure`).
3.  **AWS SAM CLI** installed.
4.  **Node.js and npm** (v18 or higher).
5.  **Python** (v3.9 or higher).
6.  **A Google Gemini API Key** from [Google AI Studio](https://aistudio.google.com/app/apikey).
7.  **A vulnerable EC2 instance:**
    *   Launch an **Amazon Linux 2** instance (not Amazon Linux 2023).
    *   Attach an IAM Role to it with the `AmazonSSMManagedInstanceCore` managed policy.
    *   Enable **Amazon Inspector v2** in your AWS account, which will automatically start scanning the instance.
    *   (Optional) To guarantee findings, you can intentionally install a vulnerable package version.

### ⚙️ Setup and Deployment

This project is divided into a `backend` and a `frontend` directory.

**1. Backend Deployment (AWS SAM):**
```bash
# Navigate to the backend directory
cd patch-pilot-backend

# Build the serverless application
sam build

# Deploy with guided prompts. You will be asked for:
# - Stack Name (e.g., patch-pilot-backend-stack)
# - AWS Region
# - Your Google Gemini API Key (LlmApiKey)
# - To confirm changes and allow IAM role creation
sam deploy --guided
```
After deployment, **copy the `ApiUrl`** from the command line output.

**2. Frontend Deployment (AWS CloudFormation & S3 Sync):**
```bash
# Navigate to the frontend directory
cd patch-pilot-frontend

# Create a local environment file
touch .env.local

# Add the backend URL to the file
echo "VITE_API_URL=YOUR_COPIED_API_URL" > .env.local

# Deploy the S3 and CloudFront infrastructure
aws cloudformation deploy \
  --template-file template-frontend.yaml \
  --stack-name patch-pilot-frontend-stack \
  --capabilities CAPABILITY_IAM

# Note the S3BucketName and CloudFrontDistributionId from the output

# Install dependencies and build the static files
npm install
npm run build

# Sync the built files to the S3 bucket (replace with your bucket name)
aws s3 sync ./dist/ s3://YOUR_S3_BUCKET_NAME

# Invalidate the CloudFront cache to deploy changes (replace with your distribution ID)
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### 🕹️ Usage

Once deployed, navigate to your CloudFront URL. The application will:
1.  Load all findings currently in the database.
2.  Automatically update with new findings every hour.
3.  Allow you to click "Analyze" to get an AI-powered risk summary and fix.
4.  Allow you to click "Deploy Fix" to patch the EC2 instance automatically.
---
