# -----------------------------------------------------------------------------------------
# Registering vault provider
# -----------------------------------------------------------------------------------------
data "vault_generic_secret" "rds" {
  path = "secret/rds"
}

data "vault_generic_secret" "redshift" {
  path = "secret/redshift"
}

# -----------------------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------------------
module "vpc" {
  source                  = "./modules/vpc"
  vpc_name                = "vpc"
  vpc_cidr                = "10.0.0.0/16"
  azs                     = var.azs
  public_subnets          = var.public_subnets
  private_subnets         = var.private_subnets
  enable_dns_hostnames    = true
  enable_dns_support      = true
  create_igw              = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = true
  single_nat_gateway      = false
  one_nat_gateway_per_az  = true
  tags = {
    Project = "batch-etl"
  }
}

module "rds_sg" {
  source = "./modules/security-groups"
  name   = "rds-sg"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      description = "RDS Traffic"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  egress_rules = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  tags = {
    Name = "rds-sg"
  }
}

module "redshift_sg" {
  source = "./modules/security-groups"
  name   = "rds-sg"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      description = "Redshift Traffic"
      from_port   = 5439
      to_port     = 5439
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  egress_rules = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  tags = {
    Name = "rds-sg"
  }
}

module "emr_sg" {
  source = "./modules/security-groups"
  name   = "emr-sg"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      description = "EMR Traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  egress_rules = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  tags = {
    Name = "emr-sg"
  }
}

# -----------------------------------------------------------------------------------------
# Secrets Manager
# -----------------------------------------------------------------------------------------
module "db_credentials" {
  source                  = "./modules/secrets-manager"
  name                    = "rds-secrets"
  description             = "rds-secrets"
  recovery_window_in_days = 0
  secret_string = jsonencode({
    username = tostring(data.vault_generic_secret.rds.data["username"])
    password = tostring(data.vault_generic_secret.rds.data["password"])
  })
}

# -----------------------------------------------------------------------------------------
# RDS Instance
# -----------------------------------------------------------------------------------------
module "source_db" {
  source                  = "./modules/rds"
  db_name                 = "cdcsourcedb"
  allocated_storage       = 100
  engine                  = "postgres"
  engine_version          = "17.2"
  instance_class          = "db.t4g.large"
  multi_az                = true
  username                = tostring(data.vault_generic_secret.rds.data["username"])
  password                = tostring(data.vault_generic_secret.rds.data["password"])
  subnet_group_name       = "cdc-rds-subnet-group"
  backup_retention_period = 7
  backup_window           = "03:00-06:00"
  maintenance_window      = "Mon:00:00-Mon:03:00"
  subnet_group_ids = [
    module.vpc.public_subnets[0],
    module.vpc.public_subnets[1],
    module.vpc.public_subnets[2]
  ]
  vpc_security_group_ids                = [module.rds_sg.id]
  publicly_accessible                   = true
  deletion_protection                   = false
  skip_final_snapshot                   = true
  max_allocated_storage                 = 500
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  parameter_group_name                  = "cdc-postgres17-params"
  parameter_group_family                = "postgres17"
  parameters                            = []
}

# -----------------------------------------------------------------------------------------
# S3 Configuration
# -----------------------------------------------------------------------------------------
module "silver_bucket" {
  source             = "./modules/s3"
  bucket_name        = "silverbucketetletlpro"
  objects            = []
  versioning_enabled = "Enabled"
  cors = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    },
    {
      allowed_headers = ["*"]
      allowed_methods = ["PUT"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    }
  ]
  bucket_policy = ""
  force_destroy = false
  bucket_notification = {
    queue           = []
    lambda_function = []
  }
}

module "bronze_bucket" {
  source             = "./modules/s3"
  bucket_name        = "bronzebucketetletlpro"
  objects            = []
  versioning_enabled = "Enabled"
  cors = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    },
    {
      allowed_headers = ["*"]
      allowed_methods = ["PUT"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    }
  ]
  bucket_policy = ""
  force_destroy = false
  bucket_notification = {
    queue           = []
    lambda_function = []
  }
}

module "gold_bucket" {
  source             = "./modules/s3"
  bucket_name        = "bronzebucketetletlpro"
  objects            = []
  versioning_enabled = "Enabled"
  cors = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    },
    {
      allowed_headers = ["*"]
      allowed_methods = ["PUT"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    }
  ]
  bucket_policy = ""
  force_destroy = false
  bucket_notification = {
    queue           = []
    lambda_function = []
  }
}

# -----------------------------------------------------------------------------------------
# Redshift Configuration
# -----------------------------------------------------------------------------------------
module "redshift_serverless" {
  source              = "./modules/redshift"
  namespace_name      = "warehouse-namespace"
  admin_username      = tostring(data.vault_generic_secret.redshift.data["username"])
  admin_user_password = tostring(data.vault_generic_secret.redshift.data["password"])
  db_name             = "processed_records"
  workgroups = [
    {
      workgroup_name      = "warehouse-workgroup"
      base_capacity       = 128
      publicly_accessible = false
      subnet_ids          = module.vpc.public_subnets
      security_group_ids  = [module.redshift_sg.id]
      config_parameters = [
        {
          parameter_key   = "enable_user_activity_logging"
          parameter_value = "true"
        }
      ]
    }
  ]
}

# -----------------------------------------------------------------------------------------
# EMR Serverless Configuration
# -----------------------------------------------------------------------------------------
module "emr_serverless" {
  source                         = "./modules/emr"
  name                           = "cdc-emr-serverless"
  release_label                  = "emr-7.0.0"
  type                           = "Spark"
  maximum_cpu                    = "100 vCPU"
  maximum_memory                 = "500 GB"
  subnet_ids                     = module.vpc.public_subnets
  security_group_ids             = [module.emr_sg.id]
  auto_start_enabled             = true
  auto_stop_enabled              = true
  auto_stop_idle_timeout_minutes = 30
  initial_capacity = [
    {
      initial_capacity_type = "Driver"
      worker_count          = 1
      worker_configuration = {
        cpu    = "4 vCPU"
        memory = "16 GB"
      }
    },
    {
      initial_capacity_type = "Executor"
      worker_count          = 5
      worker_configuration = {
        cpu    = "8 vCPU"
        memory = "32 GB"
      }
    }
  ]
}

# -----------------------------------------------------------------------------------------
# Airflow Configuration
# -----------------------------------------------------------------------------------------
