# 🚀 ECS Microservices Infrastructure - Home Assignment

## 📋 Project Overview

This project implements a **scalable microservices architecture** on AWS using **Amazon ECS** with **Terraform Infrastructure as Code**. The solution demonstrates a complete workflow for processing requests through a secure, event-driven architecture with proper monitoring and auto-scaling capabilities.

### 🏗️ Architecture Summary

The infrastructure consists of two main microservices orchestrated through AWS ECS:

1. **API Service** - Handles incoming HTTP requests and queues messages
2. **Worker Service** - Processes queued messages and stores results in S3

**Data Flow**: `HTTP Request → API Service → SQS Queue → Worker Service → S3 Storage`

---

## 🎯 Strong Suits & Key Features


### ✅ **Security Best Practices**
- **IAM roles** with principle of least privilege
- **SSM Parameter Store** for secure token management with encryption
- **VPC security groups** with controlled network access
- **Container security** with non-root user execution and read-only filesystems
- **ALB integration** with proper health checks and routing

### ✅ **Scalability & Performance**
- **Auto-scaling policies** based on CPU, memory, and SQS queue depth
- **Optimized scaling cooldowns** for cost-effective operations
- **Free-tier optimized** resource allocation (256 CPU/Memory units)
- **Bridge networking** mode to avoid ENI limitations on t2.micro instances

### ✅ **Monitoring & Observability**
- **CloudWatch Container Insights** enabled for comprehensive monitoring
- **Custom CloudWatch alarms** for service health and performance metrics
- **SNS notifications** for critical alerts and scaling events
- **Execute command** enabled for debugging and troubleshooting

### ✅ **Production-Ready Features**
- **Health checks** with configurable retry policies
- **Graceful shutdown** with proper draining policies
- **Load balancing** with Application Load Balancer
- **Container image management** with digest-based deployments for consistency

---

## 🧪 Testing Strategy & Results

### **Simple API Testing Approach**

The microservice workflow can be easily tested using a simple curl command that validates the complete end-to-end functionality:

### **How to Test the Workflow**

#### **Step 1: Get the API URL**
```bash
cd terraform
terraform output api_url
```

#### **Step 2: Retrieve the SSM Token**
```bash
aws ssm get-parameter --name "/api/token" --with-decryption --query 'Parameter.Value' --output text
```

#### **Step 3: Test the API Endpoint**
```bash
curl -X POST <API_URL>/submit \
  -H "Content-Type: application/json" \
  -d '{
    "token": "<SSM_TOKEN>",
    "email_timestream": "2025-06-09T10:30:45.123Z"
  }'
```

#### **Example Execution:**
```bash
# Get API URL
$ terraform output api_url
"http://devops-cluster-api-alb-809352025.us-east-1.elb.amazonaws.com"

# Get SSM Token
$ aws ssm get-parameter --name "/api/token" --with-decryption --query 'Parameter.Value' --output text
my-secret-token

# Test the workflow
$ curl -X POST http://devops-cluster-api-alb-809352025.us-east-1.elb.amazonaws.com/submit \
  -H "Content-Type: application/json" \
  -d '{
    "token": "my-secret-token",
    "email_timestream": "2025-06-09T10:30:45.123Z"
  }'

{"message":"Payload accepted and queued."}
```

✅ **This confirms:**
- **SSM Token Retrieval**: Successfully retrieved secure token from Parameter Store
- **API Processing**: Request accepted and validated
- **SQS Queuing**: Message queued for worker service processing
- **End-to-End Flow**: Complete workflow from API → SQS → Worker → S3

#### **Step 4: Verify Complete Success**
After running the curl command, **check your S3 bucket** for a new object to confirm the worker service successfully processed the message:

```bash
# List objects in the S3 bucket to see the new file created by the worker
aws s3 ls s3://devops-worker-bucket-<random-suffix>/
```

✅ **Complete Success Indicators:**
- API returns: `{"message":"Payload accepted and queued."}`
- **New object appears in S3 bucket** (confirms worker processed the message)
- Object contains the email data with ISO timestamp from your request

### **Environment Considerations**
⚠️ **Note**: Some AWS permissions might be missing in restricted environments, but the infrastructure works perfectly in environments with proper IAM permissions. The simple curl test provides immediate validation of the complete workflow.

---

## 🏛️ Technical Architecture

### **Infrastructure Components**

#### **ECS Cluster Configuration**
- **EC2 Launch Type** with Auto Scaling Groups for cost optimization
- **Container Insights** enabled for monitoring
- **Bridge Network Mode** for t2.micro compatibility
- **Optimized Capacity Providers** with managed scaling

#### **Microservices Design**
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Client    │───▶│ ALB + API   │───▶│ SQS Queue   │───▶│   Worker    │
│             │    │  Service    │    │             │    │  Service    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                          │                                      │
                          ▼                                      ▼
                   ┌─────────────┐                      ┌─────────────┐
                   │ SSM Token   │                      │ S3 Storage  │
                   │  Parameter  │                      │   Bucket    │
                   └─────────────┘                      └─────────────┘
```

#### **Security Architecture**
- **IAM Task Roles** with specific permissions for each service
- **SSM Parameter Store** with SecureString encryption
- **VPC Security Groups** with least-privilege access
- **ALB SSL/TLS** termination ready (certificate can be added)

---

## 🔄 CI/CD Integration

### **Container Images**
The microservices use **GitHub Container Registry (GHCR)** for simplicity:
- **API Service**: `ghcr.io/guyerreich/checkpoint-home-assignment-api-ms`
- **Worker Service**: `ghcr.io/guyerreich/checkpoint-home-assignment-worker-ms`

Both images are **publicly available** and automatically built from their respective repositories.

### **Deployment Strategy**
- **Digest-based deployments** ensure consistency across environments
- **Rolling updates** with zero-downtime deployment
- **Health check integration** prevents unhealthy deployments

---

## 🔧 Possible Improvements & Future Enhancements

### **1. Serverless Architecture Migration**
**Current**: ECS with EC2 instances
**Improvement**: AWS API Gateway + Lambda functions
- **Cost Reduction**: Pay-per-request pricing model
- **Enhanced Security**: No server management, automatic scaling
- **Simplified Operations**: Reduced infrastructure complexity
- **Better Performance**: Cold start optimizations for small workloads

### **2. Enhanced Container Management**
**Current**: Digest-based image deployment
**Improvements**:
- **Semantic Versioning**: Implement proper SemVer control in microservice repositories
- **Latest Tag Strategy**: Use latest tags with CD triggers for automatic deployments
- **Auto-Deployment Pipeline**: Change from digest to latest tags to enable force deployment from microservice repositories, allowing automatic AWS updates when new container versions are pushed
- **Multi-stage Builds**: Optimize container images for security and size

### **3. Advanced DevOps Practices**
- **GitOps Implementation**: ArgoCD or Flux for declarative deployments
- **Security Scanning**: Container vulnerability scanning and compliance checks

### **4. Monitoring & Alerting Enhancements**
- **CI/CD Status Alerts**: Email notifications for deployment status
- **Advanced Health Checks**: easier health check by making sure each image supllies the right means(packages) to test the health check.

### **5. Security Improvements**
**Current**: Raw SSM parameter retrieval
**Enhancement**: API microservice handles SSM decryption internally
- **Better Security**: Credentials never exposed in plain text
- **Audit Trail**: Detailed access logging for compliance
- **Role-based Access**: Fine-grained permission control

### **6. Data Format Standardization**
**Known Issue**: API expects `email_timestream` as ISO date format instead of tick number