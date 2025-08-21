# Patch Pilot AI 🛡️

**Patch Pilot is an AI-powered security co-pilot that automates the entire lifecycle of vulnerability remediation on AWS, transforming cryptic CVE reports into one-click patches.**

This project was built for the AWS Hackathon to solve the real-world problem of vulnerability alert fatigue and slow, manual patching processes in the cloud.

---

### 🚀 The Problem

Cloud security tools like AWS Inspector are great at *finding* vulnerabilities, but they often leave developers and operations teams with significant challenges:
*   **Alert Overload:** A long list of CVEs with little context on the *actual business risk*.
*   **Remediation Complexity:** Figuring out the exact command or process to fix a specific vulnerability.
*   **Manual Toil:** The slow, error-prone process of manually applying patches, especially at scale.

### ✨ The Solution

Patch Pilot acts as an intelligent layer on top of AWS security services. It connects to AWS Inspector, analyzes new findings using a Large Language Model (LLM), and provides a simple, one-click interface to deploy fixes securely.

**Key Features:**
*   **Unified Dashboard:** Displays all active, critical vulnerabilities in a single, clean interface.
*   **AI-Powered Risk Analysis:** For each vulnerability, an LLM provides a clear, human-readable summary of the business risk.
*   **AI-Generated Fixes:** The system automatically generates the precise, safe command needed to patch the vulnerability.
*   **One-Click Remediation:** Deploys the fix using AWS Systems Manager (SSM) Run Command, eliminating the need for SSH and manual intervention.

### 🏛️ Architecture

The entire application is built on a serverless, event-driven architecture for maximum scalability and cost-efficiency.

*   **Frontend:** A React (Vite) single-page application hosted on **AWS S3** and distributed globally via **Amazon CloudFront**.
*   **Backend:** An API built with **Amazon API Gateway** and **AWS Lambda** (Python).
*   **Database:** **Amazon DynamoDB** to store and track the state of each vulnerability finding.
*   **Security & Operations:**
    *   **Amazon Inspector:** The source for vulnerability detection.
    *   **AWS Systems Manager (SSM):** The agent for securely executing patch commands.
    *   **Google Gemini API:** The external AI model used for analysis and solution generation.

![Architecture Diagram](https'//i.imgur.com/your-architecture-diagram.png')  _<(Optional: Create and link to a simple diagram)_

### 🛠️ Tech Stack

*   **Frontend:** React, Vite, Material-UI
*   **Backend:** Python 3.11, Boto3
*   **Infrastructure:** AWS SAM (Serverless Application Model), CloudFormation
*   **AI:** Google Gemini API

### ⚙️ Setup and Deployment

This project is divided into a `backend` and a `frontend` directory.

**1. Backend Deployment (AWS SAM):**
```bash
# Navigate to the backend directory
cd patch-pilot-backend

# Build the serverless application
sam build

# Deploy with guided prompts (you will be asked for your LLM API Key)
sam deploy --guided
```
This will deploy the entire backend stack. Copy the `ApiUrl` from the output.

**2. Frontend Deployment:**
# In a separate terminal, outside your backend folder
npm create vite@latest patch-pilot-frontend -- --template react
cd patch-pilot-frontend
npm install
npm install @mui/material @emotion/react @emotion/styled
aws s3 sync ./dist/ s3://patch-pilot-ai-frontend-hackthon-2025

```bash
# Navigate to the frontend directory
cd patch-pilot-frontend

# Update the VITE_API_URL in the .env.local file with the backend's ApiUrl
# (See the full guide for details)

# Install dependencies
npm install

# Build the static files
npm run build

# Deploy the static files to S3 (See full guide for S3/CloudFront setup)
aws s3 sync ./dist s3://your-frontend-bucket-name
```

### 🕹️ Usage

Once deployed, simply navigate to the CloudFront URL. The application will:
1.  Automatically load all active, high-severity findings from AWS Inspector.
2.  Allow you to click "Analyze" to get an AI-powered risk summary and fix.
3.  Allow you to click "Deploy Fix" to patch the EC2 instance automatically.

---
