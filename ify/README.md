# Infrastructure Orchestration: Real-Time Graph Pipelines (ify)

This repository contains the Terraform infrastructure for a multi-phase real-time graph data pipeline. It orchestrates the ingestion of Code Property Graphs (CPG) into AWS Neptune and provides a frontend environment for querying them.

## 🚀 Customer-Centric Deployment

The entire infrastructure is parameterized using a single variable: `project_name`. This allows you to deploy isolated and distinctly named environments for different customers without touching the code.

### Usage Example
By default, the project name is set to `client-c`. To deploy for a specific customer, use the `-var` flag:

```bash
# Preview changes for "acme-corp"
terraform plan -var="project_name=acme-corp"

# Deploy for "acme-corp"
terraform apply -var="project_name=acme-corp"
```

Resources in AWS (S3 buckets, Lambda functions, Neptune clusters, IAM roles) will automatically be prefixed with your chosen project name (e.g., `acme-corp-cpg-bucket`).

---

## 🏗️ What is included?

The orchestration is split into two major functional phases within a shared, secure networking environment.

### 1. Networking Foundation (`/networking`)
- **Shared VPC**: Isolated network for all phases.
- **Public & Private Subnets**: Public subnets for the Reader Phase (EC2) and Private subnets for the Writer Phase (Neptune).
- **Security Groups**: Granular rules allowing the Chat UI to communicate with Neptune on port `8182`.

### 2. Writer Phase: Data Ingestion (`/writer-phase`)
- **AWS S3**: Secure storage for CPG artifacts (`vertices.csv`, `edges.csv`).
- **AWS Neptune**: High-performance graph database for CPG storage.
- **AWS Lambda**: Automated Python loader that triggers Neptune's bulk loader when invoked.
- **IAM**: Least-privilege roles for Neptune-to-S3 access and Lambda execution.

### 3. Reader Phase: Chat App (`/reader-phase`)
- **AWS EC2**: A self-hosted GitHub Actions runner that hosts the Chat UI.
- **Elastic IP (Static IP)**: A permanent public IP address so your application endpoint never changes on reboot.
- **Automatic Setup**: User Data scripts that install Docker, Docker Compose, and inject the correct Neptune endpoints into your `.env` files at boot time.

### 4. Full-Stack Monitoring (`/monitoring`)
- **CloudWatch Dashboard**: A unified dashboard that monitors both Neptune (Writer) and EC2 (Reader) metrics in a single view.

---

## 🛠️ Step-by-Step Deployment

1. **Initialize**:
   ```bash
   terraform init
   ```

2. **Plan**:
   ```bash
   terraform plan -var="project_name=YOUR_CLIENT_NAME"
   ```

3. **Deploy**:
   ```bash
   terraform apply -var="project_name=YOUR_CLIENT_NAME"
   ```

4. **Verify**:
   Use the terminal outputs for the S3 bucket name, Lambda name, and Elastic IP to complete your GitHub Actions pipeline configuration.
