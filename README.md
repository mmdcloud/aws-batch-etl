# Enterprise Batch ETL Pipeline with High-Availability Apache Airflow on AWS

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Apache Airflow](https://img.shields.io/badge/Apache%20Airflow-2.x-017CEE?logo=apache-airflow)](https://airflow.apache.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A production-grade, highly available batch ETL data platform built on AWS using Terraform. This infrastructure orchestrates complex data pipelines using Apache Airflow running on ECS Fargate, with multi-layered data lake architecture (Bronze/Silver/Gold) and integration with EMR Serverless and Redshift Serverless for scalable data processing and analytics.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Data Sources                                │
│                    (RDS PostgreSQL - CDC)                           │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Apache Airflow (HA)                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐     │
│  │  Webserver   │  │  Scheduler   │  │  Celery Workers      │     │
│  │  (ECS x2)    │  │  (ECS x2)    │  │  (ECS Auto-scaling)  │     │
│  └──────────────┘  └──────────────┘  └──────────────────────┘     │
│         │                  │                      │                 │
│         └──────────────────┴──────────────────────┘                │
│                            │                                        │
│         ┌──────────────────┼────────────────────┐                  │
│         ▼                  ▼                    ▼                   │
│  ┌──────────┐      ┌────────────┐      ┌──────────────┐           │
│  │ RDS PG   │      │   Redis    │      │     EFS      │           │
│  │(Metadata)│      │(Message Q) │      │(DAGs/Logs)   │           │
│  └──────────┘      └────────────┘      └──────────────┘           │
└─────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Medallion Architecture                           │
│                                                                     │
│  ┌──────────┐         ┌──────────┐         ┌──────────┐           │
│  │  Bronze  │  ═════► │  Silver  │  ═════► │   Gold   │           │
│  │   (Raw)  │         │(Cleaned) │         │(Curated) │           │
│  │  S3 Bucket         │  S3 Bucket         │ S3 Bucket            │
│  └──────────┘         └──────────┘         └──────────┘           │
│       │                     │                     │                │
│       └─────────────────────┴─────────────────────┘                │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
    ┌──────────────────┐           ┌──────────────────┐
    │  EMR Serverless  │           │    Redshift      │
    │  (Spark Jobs)    │           │   Serverless     │
    │  Data Transform  │           │  (Data Warehouse)│
    └──────────────────┘           └──────────────────┘
```

## ✨ Key Features

### High-Availability Airflow Architecture
- **Multi-AZ Deployment**: All components distributed across 3 availability zones
- **Auto-scaling Workers**: Dynamic scaling based on queue depth (3-20 instances)
- **Load Balanced Webserver**: Application Load Balancer with health checks
- **Fault-Tolerant Scheduler**: Multiple scheduler instances with HA locking
- **Persistent Storage**: EFS for DAGs and logs, S3 for remote logging

### Enterprise Data Platform
- **Medallion Architecture**: Bronze (raw) → Silver (cleaned) → Gold (curated) data layers
- **Change Data Capture**: RDS PostgreSQL with CDC enabled for real-time data ingestion
- **Serverless Processing**: EMR Serverless for Spark-based transformations
- **Serverless Warehousing**: Redshift Serverless for analytics and BI workloads
- **Secret Management**: HashiCorp Vault integration for secure credential storage

### Production-Grade Operations
- **Infrastructure as Code**: 100% Terraform-managed with modular architecture
- **Comprehensive Monitoring**: CloudWatch alarms for all critical metrics
- **Automated Logging**: Centralized logging via Kinesis Firehose and FluentBit
- **Security Hardening**: VPC isolation, security groups, encryption at rest and in transit
- **Performance Insights**: RDS Enhanced Monitoring and Performance Insights enabled
- **Disaster Recovery**: Automated backups, multi-AZ replication, point-in-time recovery

## 📋 Prerequisites

### Required Tools
- **Terraform**: >= 1.5.0
- **AWS CLI**: >= 2.x configured with appropriate credentials
- **HashiCorp Vault**: For secret management
- **Docker**: For building Airflow container images
- **Python**: >= 3.11 for Airflow DAG development

### AWS Service Quotas
Ensure you have sufficient quotas for:
- ECS Fargate vCPUs (minimum 40 vCPUs)
- RDS instances (db.r6g.large and db.t4g.large)
- ElastiCache nodes (cache.t4g.micro)
- Redshift Serverless RPUs (minimum 128 RPUs)
- EMR Serverless vCPUs (minimum 100 vCPUs)

### Vault Secrets Setup

This infrastructure requires the following secrets in HashiCorp Vault:

```bash
# RDS credentials
vault kv put secret/rds \
  username="admin" \
  password="your-secure-password"

# Redis auth token
vault kv put secret/redis \
  auth_token="your-redis-auth-token"

# Airflow metadata DB credentials
vault kv put secret/airflow_metadata_db \
  username="airflow" \
  password="your-airflow-db-password"

# Redshift credentials
vault kv put secret/redshift \
  username="admin" \
  password="your-redshift-password"
```

## 🚀 Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/your-org/batch-etl-pipeline.git
cd batch-etl-pipeline
```

### 2. Set Up Terraform Variables

Create `terraform.tfvars`:

```hcl
# Region Configuration
region = "us-east-1"

# Network Configuration
azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# Domain Configuration
domain_name = "airflow.yourdomain.com"

# Vault Configuration
vault_address = "https://vault.yourdomain.com"
vault_token   = "your-vault-token"
```

### 3. Build and Push Airflow Docker Images

```bash
# Build webserver image
cd docker/webserver
docker build -t airflow-webserver:latest .
docker tag airflow-webserver:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/airflow-webserver:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/airflow-webserver:latest

# Build scheduler/worker image
cd ../scheduler-worker
docker build -t airflow-worker:latest .
docker tag airflow-worker:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/airflow-worker:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/airflow-worker:latest
```

### 4. Initialize Vault Provider

```bash
export VAULT_ADDR="https://vault.yourdomain.com"
export VAULT_TOKEN="your-vault-token"
```

### 5. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### 6. Initialize Airflow Database

```bash
# Get ECS cluster name
CLUSTER=$(terraform output -raw ecs_cluster_name)

# Run database initialization (one-time)
aws ecs run-task \
  --cluster $CLUSTER \
  --launch-type FARGATE \
  --task-definition airflow-init \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=DISABLED}" \
  --overrides '{"containerOverrides":[{"name":"init","command":["airflow","db","migrate"]}]}'

# Create admin user
aws ecs run-task \
  --cluster $CLUSTER \
  --launch-type FARGATE \
  --task-definition airflow-init \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=DISABLED}" \
  --overrides '{"containerOverrides":[{"name":"init","command":["airflow","users","create","--username","admin","--firstname","Admin","--lastname","User","--role","Admin","--email","admin@example.com","--password","admin123"]}]}'
```

### 7. Access Airflow UI

```bash
# Get ALB DNS name
terraform output airflow_webserver_url

# Open in browser (or configure Route53 for custom domain)
```

## 📁 Project Structure

```
.
├── main.tf                           # Main infrastructure orchestration
├── variables.tf                      # Input variable definitions
├── outputs.tf                        # Output values
├── terraform.tfvars                  # Variable values (gitignored)
├── provider.tf                       # Provider configurations
├── modules/
│   ├── vpc/                          # VPC with public/private subnets
│   ├── security-groups/              # Security group configurations
│   ├── rds/                          # RDS PostgreSQL module
│   ├── elasticache/                  # Redis cluster module
│   ├── efs/                          # EFS file system module
│   ├── s3/                           # S3 bucket configurations
│   ├── emr/                          # EMR Serverless module
│   ├── redshift/                     # Redshift Serverless module
│   ├── iam/                          # IAM roles and policies
│   ├── secrets-manager/              # AWS Secrets Manager
│   ├── cloudwatch/                   # CloudWatch alarms and logs
│   └── sns/                          # SNS topic for notifications
├── docker/
│   ├── webserver/
│   │   ├── Dockerfile                # Airflow webserver image
│   │   └── requirements.txt          # Python dependencies
│   └── scheduler-worker/
│       ├── Dockerfile                # Airflow scheduler/worker image
│       └── requirements.txt          # Python dependencies
├── dags/
│   ├── example_etl_dag.py           # Sample ETL pipeline
│   └── emr_spark_job_dag.py         # EMR Serverless job DAG
├── scripts/
│   ├── init-airflow.sh              # Airflow initialization script
│   └── deploy-dags.sh               # DAG deployment script
└── README.md                         # This file
```

## 🔧 Configuration Deep Dive

### Airflow Component Sizing

#### Webserver (ECS Fargate)
```hcl
cpu    = 2048  # 2 vCPU
memory = 4096  # 4 GB
desired_count = 2  # Active-active HA
```

#### Scheduler (ECS Fargate)
```hcl
cpu    = 2048  # 2 vCPU
memory = 4096  # 4 GB
desired_count = 2  # HA with leader election
```

#### Workers (ECS Fargate with Auto-scaling)
```hcl
cpu    = 2048  # 2 vCPU
memory = 4096  # 4 GB
min_capacity = 3
max_capacity = 20
target_cpu_utilization = 70%
```

### Database Configuration

#### Airflow Metadata Database (RDS PostgreSQL)
```hcl
instance_class = "db.r6g.large"  # 2 vCPU, 16 GB RAM
multi_az       = true
storage_type   = "gp3"
allocated_storage = 100 GB
max_allocated_storage = 1000 GB
backup_retention_period = 30 days
performance_insights_enabled = true
```

**Optimized Parameters:**
- `max_connections`: 500
- `shared_buffers`: 10% of instance memory
- `effective_cache_size`: 50% of instance memory
- `log_min_duration_statement`: 1000ms

#### Source Database (RDS PostgreSQL - CDC Enabled)
```hcl
instance_class = "db.t4g.large"  # 2 vCPU, 8 GB RAM
multi_az       = true
allocated_storage = 100 GB
max_allocated_storage = 500 GB
backup_retention_period = 7 days
```

### Message Broker (ElastiCache Redis)
```hcl
node_type            = "cache.t4g.micro"
num_cache_clusters   = 3  # Multi-AZ
engine_version       = "7.0"
auth_token_enabled   = true
transit_encryption   = true
at_rest_encryption   = true
snapshot_retention   = 7 days
```

### Shared File System (EFS)
```hcl
performance_mode         = "generalPurpose"
throughput_mode          = "bursting"
encrypted                = true
transition_to_ia         = "AFTER_30_DAYS"
backup_policy_status     = "ENABLED"
```

### EMR Serverless Configuration
```hcl
release_label     = "emr-7.0.0"
application_type  = "Spark"
maximum_capacity  = "100 vCPU / 500 GB"
auto_stop_enabled = true
idle_timeout      = 30 minutes

initial_capacity:
  - Driver:   1 worker  @ 4 vCPU, 16 GB
  - Executor: 5 workers @ 8 vCPU, 32 GB each
```

### Redshift Serverless
```hcl
base_capacity       = 128 RPUs
publicly_accessible = false
multi_az            = true (via subnet placement)
```

## 🔐 Security Architecture

### Network Security

#### VPC Design
- **3 Public Subnets**: ALB, NAT Gateways
- **3 Private Subnets**: ECS tasks, RDS, ElastiCache, EFS
- **NAT Gateway per AZ**: High-availability internet egress

#### Security Groups (Principle of Least Privilege)

**Webserver Security Group:**
- Inbound: Port 8080 from ALB only
- Outbound: All traffic (for DB, Redis, EFS access)

**Scheduler/Worker Security Groups:**
- Inbound: None (no direct access needed)
- Outbound: All traffic (for DB, Redis, EFS, AWS API calls)

**RDS Security Groups:**
- Inbound: Port 5432 from Webserver, Scheduler, Worker SGs only
- Outbound: None needed

**Redis Security Group:**
- Inbound: Port 6379 from Webserver, Scheduler, Worker SGs only
- Outbound: None needed

**EFS Security Group:**
- Inbound: Port 2049 (NFS) from Webserver, Scheduler, Worker SGs only
- Outbound: None needed

### Encryption

**Data at Rest:**
- RDS: AWS-managed encryption enabled
- ElastiCache: AES-256 encryption enabled
- EFS: AWS-managed KMS encryption
- S3: Default SSE-S3 encryption
- Redshift: AWS-managed encryption

**Data in Transit:**
- RDS: SSL/TLS connections enforced
- ElastiCache: TLS enabled with auth token
- ALB: HTTPS termination (when configured)
- All AWS API calls: TLS 1.2+

### IAM Roles

**ECS Task Execution Role:**
- `ecr:GetAuthorizationToken`
- `ecr:BatchCheckLayerAvailability`
- `ecr:GetDownloadUrlForLayer`
- `ecr:BatchGetImage`
- `logs:CreateLogStream`
- `logs:PutLogEvents`

**ECS Task Role (Airflow):**
- `s3:*` on Bronze/Silver/Gold buckets
- `emr-serverless:*` for job submission
- `redshift-data:*` for query execution
- `secretsmanager:GetSecretValue` for credentials
- `rds:DescribeDBInstances`

## 📊 Monitoring and Observability

### CloudWatch Alarms

The infrastructure includes comprehensive monitoring with SNS email notifications:

#### RDS Alarms
```hcl
- High CPU Utilization (>80% for 10 minutes)
- High Connection Count (>400 connections)
- Low Free Storage Space (<10 GB)
- Read/Write Latency spikes
```

#### Redis Alarms
```hcl
- High CPU Utilization (>75%)
- High Memory Usage (>80%)
- High Evictions (>1000/5min)
```

#### ECS Service Alarms
```hcl
- Scheduler High CPU (>80%)
- Worker High CPU (>80%)
- Service Task Count (below desired)
```

#### ALB Alarms
```hcl
- Unhealthy Targets Detected
- High HTTP 5xx Error Rate (>1%)
- High Response Time (>2 seconds)
```

### Logging Strategy

**Application Logs:**
- ECS tasks → FluentBit sidecar → Kinesis Data Firehose → S3
- Retention: 30 days in CloudWatch, long-term in S3

**Airflow Logs:**
- Task logs → EFS → S3 (via remote logging)
- Webserver/Scheduler logs → CloudWatch Logs

**Database Logs:**
- RDS PostgreSQL → CloudWatch Logs
- Slow query log enabled (>1000ms)
- Connection log enabled

**Redis Logs:**
- Slow log → CloudWatch Logs (JSON format)

### Key Metrics Dashboard

```
Airflow Performance:
- DAG run duration
- Task success/failure rate
- Scheduler heartbeat
- Worker queue depth
- Task queue length

Infrastructure Health:
- RDS CPU, Memory, Connections
- Redis CPU, Memory, Cache hits
- ECS CPU, Memory utilization
- ALB request count, latency
- EFS throughput, IOPS
```

## 🧪 Testing and Validation

### Smoke Tests

```bash
# Test Airflow webserver health
curl http://<alb-dns>/health

# Test database connectivity
aws rds describe-db-instances --db-instance-identifier airflow-metadata-db

# Test Redis connectivity
redis-cli -h <redis-endpoint> -p 6379 --tls --askpass PING

# Test EFS mount
aws efs describe-file-systems --file-system-id <efs-id>

# Verify EMR Serverless application
aws emr-serverless list-applications

# Check Redshift Serverless namespace
aws redshift-serverless list-namespaces
```

### Sample ETL DAG

```python
from airflow import DAG
from airflow.providers.amazon.aws.operators.emr import EmrServerlessStartJobOperator
from airflow.providers.amazon.aws.transfers.s3_to_redshift import S3ToRedshiftOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'daily_etl_pipeline',
    default_args=default_args,
    description='Daily batch ETL from Bronze to Gold',
    schedule_interval='0 2 * * *',  # 2 AM daily
    catchup=False,
) as dag:

    # Submit Spark job to EMR Serverless
    transform_bronze_to_silver = EmrServerlessStartJobOperator(
        task_id='transform_bronze_to_silver',
        application_id='{{ var.value.emr_application_id }}',
        execution_role_arn='{{ var.value.emr_execution_role }}',
        job_driver={
            'sparkSubmit': {
                'entryPoint': 's3://scripts-bucket/transform_silver.py',
                'sparkSubmitParameters': '--conf spark.executor.cores=4 --conf spark.executor.memory=16g'
            }
        },
        configuration_overrides={
            'monitoringConfiguration': {
                's3MonitoringConfiguration': {
                    'logUri': 's3://logs-bucket/emr-logs/'
                }
            }
        }
    )

    transform_silver_to_gold = EmrServerlessStartJobOperator(
        task_id='transform_silver_to_gold',
        application_id='{{ var.value.emr_application_id }}',
        execution_role_arn='{{ var.value.emr_execution_role }}',
        job_driver={
            'sparkSubmit': {
                'entryPoint': 's3://scripts-bucket/transform_gold.py',
            }
        }
    )

    load_to_redshift = S3ToRedshiftOperator(
        task_id='load_to_redshift',
        schema='analytics',
        table='daily_metrics',
        s3_bucket='gold-bucket',
        s3_key='daily_metrics/{{ ds }}/',
        copy_options=['FORMAT AS PARQUET'],
        redshift_conn_id='redshift_default',
    )

    transform_bronze_to_silver >> transform_silver_to_gold >> load_to_redshift
```

## 📈 Scaling Considerations

### Horizontal Scaling

**Airflow Workers:**
- Auto-scales from 3 to 20 instances based on CPU
- Consider queue-based scaling for better responsiveness:
  ```hcl
  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace   = "AWS/SQS"  # If using SQS for task queue
  ```

**EMR Serverless:**
- Auto-scales workers based on job requirements
- Configure max capacity based on workload:
  ```hcl
  maximum_capacity = "200 vCPU / 1000 GB"  # For larger workloads
  ```

**Redshift Serverless:**
- Scales RPUs automatically (base: 128, max: 512)
- Monitor query queue time and adjust base capacity

### Vertical Scaling

**When to scale UP:**
- RDS connections consistently >70% of max_connections
- Redis memory usage consistently >70%
- ECS task CPU consistently >80%
- Airflow task execution time increasing

**Recommended paths:**

```hcl
# Airflow RDS (when >400 connections sustained)
db.r6g.large → db.r6g.xlarge (4 vCPU, 32 GB)

# Redis (when memory >70% sustained)
cache.t4g.micro → cache.t4g.small

# ECS Tasks (when CPU >80% sustained)
2048/4096 → 4096/8192 (4 vCPU, 8 GB)
```

## 💰 Cost Optimization

### Estimated Monthly Costs (us-east-1)

| Component | Configuration | Monthly Cost |
|-----------|---------------|--------------|
| **Compute** | | |
| ECS Fargate (Webserver x2) | 2 vCPU, 4 GB | $59.52 |
| ECS Fargate (Scheduler x2) | 2 vCPU, 4 GB | $59.52 |
| ECS Fargate (Workers avg 5) | 2 vCPU, 4 GB | $148.80 |
| EMR Serverless | 50 vCPU-hours/day | $120.00 |
| **Storage** | | |
| RDS PostgreSQL (r6g.large) | Multi-AZ, 100 GB | $518.40 |
| RDS PostgreSQL (t4g.large) | Multi-AZ, 100 GB | $259.20 |
| ElastiCache Redis | 3-node cluster | $80.64 |
| EFS | 50 GB | $15.00 |
| S3 (Bronze/Silver/Gold) | 1 TB total | $23.00 |
| **Analytics** | | |
| Redshift Serverless | 128 RPUs, 8 hrs/day | $384.00 |
| **Networking** | | |
| NAT Gateways (3 AZs) | 100 GB data | $135.00 |
| ALB | 100 GB processed | $22.50 |
| Data Transfer | 100 GB out | $9.00 |
| **Monitoring** | | |
| CloudWatch Logs | 50 GB | $25.00 |
| CloudWatch Alarms | 20 alarms | $2.00 |
| **Total Estimated** | | **~$1,861.58/month** |

### Cost Reduction Strategies

1. **Use Savings Plans / Reserved Instances**
   - RDS Reserved Instances: Save 30-40%
   - ECS Fargate Compute Savings Plans: Save 20%
   - Estimated savings: $200-300/month

2. **Right-size Resources**
   ```bash
   # Analyze actual usage
   aws cloudwatch get-metric-statistics \
     --namespace AWS/ECS \
     --metric-name CPUUtilization \
     --dimensions Name=ServiceName,Value=airflow-worker \
     --statistics Average \
     --start-time 2024-01-01T00:00:00Z \
     --end-time 2024-01-31T23:59:59Z \
     --period 86400
   ```

3. **Optimize S3 Storage**
   ```hcl
   # Add lifecycle policies
   lifecycle_rule = [{
     id      = "archive-old-data"
     enabled = true
     
     transition = [{
       days          = 90
       storage_class = "GLACIER"
     }]
     
     expiration = {
       days = 365
     }
   }]
   ```

4. **Auto-stop Idle Resources**
   - EMR Serverless: Already configured (30 min idle timeout)
   - Consider scheduling Redshift Serverless for business hours only
   - Use spot instances for non-critical workers (not recommended for production)

5. **Optimize Network Costs**
   - Use VPC Endpoints for S3/DynamoDB (saves NAT Gateway costs)
   - Batch data transfers during off-peak hours
   - Consider single NAT Gateway for dev/staging

## 🔄 Disaster Recovery

### Backup Strategy

**RDS Automated Backups:**
- Retention: 30 days (metadata DB), 7 days (source DB)
- Backup window: 03:00-06:00 UTC
- Point-in-time recovery enabled
- Automated cross-region backup replication (optional)

**ElastiCache Snapshots:**
- Daily automatic snapshots
- Retention: 7 days
- Snapshot window: 03:00-05:00 UTC

**EFS Automatic Backups:**
- AWS Backup integration enabled
- Daily backups with 30-day retention

**S3 Versioning:**
- Enabled on all data buckets
- Lifecycle policies for version management

### Recovery Procedures

**RDS Failure:**
```bash
# Automatic failover to standby (Multi-AZ)
# Manual recovery from backup:
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier airflow-metadata-db-restored \
  --db-snapshot-identifier manual-snapshot-2024-01-15
```

**Redis Failure:**
```bash
# Automatic failover to replica (Multi-AZ enabled)
# Manual recovery from snapshot:
aws elasticache create-cache-cluster \
  --cache-cluster-id airflow-redis-restored \
  --snapshot-name airflow-redis-snapshot-2024-01-15
```

**Complete Region Failure:**
1. Deploy infrastructure in secondary region using Terraform
2. Restore RDS from cross-region replica or snapshot
3. Sync S3 data using cross-region replication
4. Update DNS records to point to new region
5. Deploy latest DAGs to new EFS

**RTO/RPO Targets:**
- RTO (Recovery Time Objective): 4 hours
- RPO (Recovery Point Objective): 15 minutes

## 🐛 Troubleshooting

### Common Issues

#### Issue: Airflow Tasks Stuck in Queued State

**Symptoms:**
- Tasks remain in queue for extended periods
- Workers not picking up tasks

**Diagnosis:**
```bash
# Check worker count
aws ecs describe-services \
  --cluster ha-airflow-ecs-cluster \
  --services airflow-worker

# Check Redis queue depth
redis-cli -h <redis-endpoint> -p 6379 --tls --askpass LLEN celery

# Check worker logs
aws logs tail /aws/ecs/airflow-worker --follow
```

**Resolution:**
- Increase worker desired count
- Check for worker OOM kills (increase memory)
- Verify Redis connectivity from workers

#### Issue: High RDS Connection Count

**Symptoms:**
- Connection errors in Airflow logs
- `DatabaseError: too many connections`

**Diagnosis:**
```bash
# Check current connections
aws rds describe-db-instances \
  --db-instance-identifier airflow-metadata-db \
  --query 'DBInstances[0].DbInstanceStatus'

# Query from Airflow
SELECT count(*) FROM pg_stat_activity;
```

**Resolution:**
```python
# Adjust Airflow config
AIRFLOW__CORE__SQL_ALCHEMY_POOL_SIZE = 5
AIRFLOW__CORE__SQL_ALCHEMY_MAX_OVERFLOW = 10
AIRFLOW__CORE__SQL_ALCHEMY_POOL_RECYCLE = 1800

# Or increase RDS max_connections parameter
```

#### Issue: EFS Mount Timeouts

**Symptoms:**
- Tasks fail with I/O errors
- DAGs not appearing in UI

**Diagnosis:**
```bash
# Check EFS security group allows NFS (port 2049)
aws ec2 describe-security-groups --group-ids <efs-sg-id>

# Check mount targets
aws efs describe-mount-targets --file-system-id <efs-id>

# Check ECS task network configuration
aws ecs describe-tasks --cluster ha-airflow-ecs-cluster --tasks <task-arn>
```

**Resolution:**
- Verify security group allows inbound 2049 from ECS task SG
- Ensure mount target exists in all subnets
- Check VPC DNS resolution enabled

#### Issue: EMR Serverless Jobs Failing

**Symptoms:**
- Jobs stuck in PENDING or FAILED state
- Spark driver/executor failures

**Diagnosis:**
```bash
# Check job details
aws emr-serverless get-job-run \
  --application-id <app-id> \
  --job-run-id <job-run-id>

# Check logs
aws s3 ls s3://logs-bucket/emr-logs/<job-run-id>/
```

**Resolution:**
- Verify IAM role has S3 access permissions
- Check Spark configuration (memory, cores)
- Ensure subnet security group allows egress
- Review job logs in S3 for application errors

#### Issue: Redshift Serverless Query Timeout

**Symptoms:**
- COPY/UNLOAD operations timing out
- High query queue time

**Diagnosis:**
```bash
# Check workgroup capacity
aws redshift-serverless get-workgroup --workgroup-name warehouse-workgroup

# Query performance
aws redshift-data execute-statement \
  --database processed_records \
  --sql "SELECT query, elapsed, queue_time FROM svl_qlog ORDER BY endtime DESC LIMIT 10"
```

**Resolution:**
- Increase base capacity (128 → 256 RPUs)
- Optimize COPY operations with multiple files
- Add distribution/sort keys to tables
- Use VACUUM and ANALYZE regularly

#### Issue: High ALB 5xx Errors

**Symptoms:**
- Users experiencing 502/504 errors
- Airflow UI intermittently unavailable

**Diagnosis:**
```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <tg-arn>

# Check webserver logs
aws logs tail /aws/ecs/airflow-webserver --follow --filter-pattern "ERROR"

# Check container health
aws ecs describe-tasks --cluster ha-airflow-ecs-cluster --tasks <task-arn>
```

**Resolution:**
- Verify health check endpoint responding (port 8080)
- Check webserver container not crashing (OOM/CPU)
- Increase webserver task count
- Review database connection pool settings

### Performance Tuning

#### Airflow Scheduler Performance

```python
# Optimize scheduler performance
AIRFLOW__SCHEDULER__MAX_TIS_PER_QUERY = 512
AIRFLOW__SCHEDULER__PARSING_PROCESSES = 4
AIRFLOW__SCHEDULER__FILE_PARSING_SORT_MODE = "modified_time"
AIRFLOW__CORE__PARALLELISM = 64
AIRFLOW__CORE__MAX_ACTIVE_RUNS_PER_DAG = 16
```

#### Database Tuning

```sql
-- Airflow metadata DB optimizations
-- Add indexes for common queries
CREATE INDEX idx_dag_run_state ON dag_run(state);
CREATE INDEX idx_task_instance_state ON task_instance(state, execution_date);

-- Regular maintenance
VACUUM ANALYZE task_instance;
VACUUM ANALYZE dag_run;
```

#### Worker Optimization

```python
# Celery worker configuration
AIRFLOW__CELERY__WORKER_CONCURRENCY = 16
AIRFLOW__CELERY__WORKER_PREFETCH_MULTIPLIER = 1
AIRFLOW__CELERY__TASK_ACKS_LATE = True
AIRFLOW__CELERY__WORKER_AUTOSCALE = "16,8"  # max,min
```

## 🔒 Security Compliance

### Compliance Considerations

**GDPR/Data Privacy:**
- Enable CloudTrail for audit logging
- Implement data retention policies
- Use encryption for PII data
- Configure VPC Flow Logs

**SOC 2 / ISO 27001:**
- Multi-factor authentication for Airflow UI
- Regular security patching (container images)
- Automated vulnerability scanning (ECR)
- Incident response procedures documented

**HIPAA (if applicable):**
- Enable encryption at rest (all services)
- Enable encryption in transit (TLS 1.2+)
- Implement access logging
- Regular access reviews

### Security Hardening Checklist

```bash
# 1. Enable GuardDuty
aws guardduty create-detector --enable

# 2. Enable Security Hub
aws securityhub enable-security-hub

# 3. Enable AWS Config
aws configservice put-configuration-recorder --configuration-recorder name=default,roleARN=<role>
aws configservice put-delivery-channel --delivery-channel name=default,s3BucketName=<bucket>

# 4. Enable VPC Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids <vpc-id> \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /aws/vpc/flowlogs

# 5. Enable CloudTrail
aws cloudtrail create-trail \
  --name management-events \
  --s3-bucket-name <bucket> \
  --is-multi-region-trail

# 6. Rotate IAM access keys quarterly
# 7. Review IAM policies for over-permissive access
# 8. Enable MFA for all IAM users
# 9. Regular penetration testing
# 10. Implement AWS WAF on ALB (optional)
```

## 📚 Additional Resources

### Official Documentation
- [Apache Airflow Docs](https://airflow.apache.org/docs/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [EMR Serverless Guide](https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/)
- [Redshift Serverless Docs](https://docs.aws.amazon.com/redshift/latest/mgmt/serverless-workgroup-namespace.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Blog Posts & Tutorials
- [Building Production Airflow on AWS](https://aws.amazon.com/blogs/big-data/)
- [Airflow Best Practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html)
- [Medallion Architecture on AWS](https://databricks.com/glossary/medallion-architecture)

### Community Resources
- [Airflow Slack Channel](https://apache-airflow.slack.com)
- [AWS re:Post](https://repost.aws/)
- [Terraform Registry Modules](https://registry.terraform.io/)

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes with proper commit messages
4. Add tests if applicable
5. Update documentation (README, inline comments)
6. Submit a pull request

### Development Workflow

```bash
# Run terraform validation
terraform fmt -recursive
terraform validate

# Run security scanning
tfsec .
checkov -d .

# Test in isolated environment
terraform workspace new dev
terraform apply
# ... test changes ...
terraform destroy
terraform workspace select default
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Maintainers

- **DevOps Team**: devops@yourcompany.com
- **Data Engineering Team**: data-eng@yourcompany.com
- **On-Call Rotation**: Slack #airflow-oncall

## 🗺️ Roadmap

### Q1 2025
- [ ] Implement GitOps for DAG deployment
- [ ] Add data quality checks with Great Expectations
- [ ] Integrate with Datadog for enhanced monitoring
- [ ] Implement blue/green deployment for Airflow

### Q2 2025
- [ ] Multi-region disaster recovery setup
- [ ] Add Apache Iceberg for data lake tables
- [ ] Implement data lineage with OpenLineage
- [ ] Add dbt integration for transformation

### Q3 2025
- [ ] Kubernetes migration (EKS with Karpenter)
- [ ] Real-time streaming with Apache Flink
- [ ] Cost optimization with Spot instances
- [ ] Enhanced security with AWS PrivateLink

### Q4 2025
- [ ] Machine learning pipeline integration (SageMaker)
- [ ] Advanced data governance (AWS Lake Formation)
- [ ] Self-service analytics portal
- [ ] Automated DAG generation from metadata

## 📞 Support

### Getting Help

**For Infrastructure Issues:**
- Create an issue in this repository
- Contact: infrastructure@yourcompany.com
- Slack: #data-platform-support

**For Airflow DAG Issues:**
- Contact: data-engineering@yourcompany.com
- Slack: #airflow-help
- [Internal Wiki](https://wiki.company.com/airflow)

**For Incidents:**
- Page on-call: PagerDuty
- Slack: #incidents
- Follow runbooks: [Incident Response](docs/runbooks/)

### SLA Commitments

- **P0 (Critical)**: 15 min response, 2 hour resolution
- **P1 (High)**: 1 hour response, 4 hour resolution
- **P2 (Medium)**: 4 hour response, 24 hour resolution
- **P3 (Low)**: 1 business day response, best effort

---

**Built with ❤️ by the Data Platform Team**

*Last Updated: December 2024*
