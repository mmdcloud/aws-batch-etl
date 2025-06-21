# Registering vault provider
data "vault_generic_secret" "rds" {
  path = "secret/rds"
}

# -----------------------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------------------
module "vpc" {
  source                = "./modules/vpc/vpc"
  vpc_name              = "cdc-vpc"
  vpc_cidr_block        = "10.0.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true
  internet_gateway_name = "cdc-vpc-igw"
}

# RDS Security Group
module "rds_sg" {
  source = "./modules/vpc/security_groups"
  vpc_id = module.vpc.vpc_id
  name   = "rds-sg"
  ingress = [
    {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
    }
  ]
  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# Public Subnets
module "public_subnets" {
  source = "./modules/vpc/subnets"
  name   = "public-subnet"
  subnets = [
    {
      subnet = "10.0.1.0/24"
      az     = "us-east-1a"
    },
    {
      subnet = "10.0.2.0/24"
      az     = "us-east-1b"
    },
    {
      subnet = "10.0.3.0/24"
      az     = "us-east-1c"
    }
  ]
  vpc_id                  = module.vpc.vpc_id
  map_public_ip_on_launch = true
}

# Private Subnets
module "private_subnets" {
  source = "./modules/vpc/subnets"
  name   = "private-subnet"
  subnets = [
    {
      subnet = "10.0.6.0/24"
      az     = "us-east-1a"
    },
    {
      subnet = "10.0.5.0/24"
      az     = "us-east-1b"
    },
    {
      subnet = "10.0.4.0/24"
      az     = "us-east-1c"
    }
  ]
  vpc_id                  = module.vpc.vpc_id
  map_public_ip_on_launch = false
}

# Public Route Table
module "public_rt" {
  source  = "./modules/vpc/route_tables"
  name    = "public-route-table"
  subnets = module.public_subnets.subnets[*]
  routes = [
    {
      cidr_block     = "0.0.0.0/0"
      gateway_id     = module.vpc.igw_id
      nat_gateway_id = ""
    }
  ]
  vpc_id = module.vpc.vpc_id
}

# Private Route Table
module "private_rt" {
  source  = "./modules/vpc/route_tables"
  name    = "private-route-table"
  subnets = module.private_subnets.subnets[*]
  routes  = []
  vpc_id  = module.vpc.vpc_id
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
  source                          = "./modules/rds"
  db_name                         = "cdcsourcedb"
  allocated_storage               = 100
  engine                          = "postgres"
  engine_version                  = "17.2"
  instance_class                  = "db.t4g.large"
  multi_az                        = true
  username                        = tostring(data.vault_generic_secret.rds.data["username"])
  password                        = tostring(data.vault_generic_secret.rds.data["password"])
  subnet_group_name               = "cdc-rds-subnet-group"
  backup_retention_period         = 7
  backup_window                   = "03:00-06:00"
  maintenance_window              = "Mon:00:00-Mon:03:00"
  subnet_group_ids = [
    module.private_subnets.subnets[0].id,
    module.private_subnets.subnets[1].id,
    module.private_subnets.subnets[2].id
  ]
  vpc_security_group_ids                = [module.rds_sg.id]
  publicly_accessible                   = false
  deletion_protection                   = false
  skip_final_snapshot                   = true
  max_allocated_storage                 = 500
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  parameter_group_name                  = "cdc-postgres17-params"
  parameter_group_family                = "postgres17"
  parameters = []
}

# -----------------------------------------------------------------------------------------
# S3 Configuration
# -----------------------------------------------------------------------------------------
module "silver_bucket" {
  source             = "./modules/s3"
  bucket_name        = "silverbucketetl"
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
  bucket_name        = "bronzebucketetl"
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
  bucket_name        = "bronzebucketetl"
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
  namespace_name      = "invoice-processing-namespace"
  admin_username      = "admin"
  admin_user_password = "AdminPassword123!"
  db_name             = "invoice_db"
  workgroups = [
    {
      workgroup_name      = "invoice-processing-workgroup"
      base_capacity       = 128
      publicly_accessible = false
      subnet_ids          = module.private_subnets.subnets[*].id
      security_group_ids  = [module.redshift_security_group.id]
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
# Airflow Configuration
# -----------------------------------------------------------------------------------------

# Launch Template for Airflow
module "airflow_launch_template" {
  source                               = "./modules/launch_template"
  name                                 = "airflow_launch_template"
  description                          = "airflow_launch_template"
  ebs_optimized                        = false
  image_id                             = "ami-005fc0f236362e99f"
  instance_type                        = "t2.micro"
  instance_initiated_shutdown_behavior = "stop"
  instance_profile_name                = aws_iam_instance_profile.iam_instance_profile.name
  key_name                             = "madmaxkeypair"
  network_interfaces = [
    {
      associate_public_ip_address = true
      security_groups             = [module.carshub_asg_frontend_sg.id]
    }
  ]
  user_data = base64encode(templatefile("${path.module}/../../scripts/airflow_installation.sh", {}))
}

# Auto Scaling Group for Airflow Template
module "airflow__asg" {
  source                    = "./modules/auto_scaling_group"
  name                      = "carshub_frontend_asg_${var.env}"
  min_size                  = 3
  max_size                  = 50
  desired_capacity          = 3
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  target_group_arns         = [module.carshub_frontend_lb.target_groups[0].arn]
  vpc_zone_identifier       = module.carshub_private_subnets.subnets[*].id
  launch_template_id        = module.carshub_frontend_launch_template.id
  launch_template_version   = "$Latest"
}

# Frontend Load Balancer
module "carshub_frontend_lb" {
  source                     = "../../../modules/load-balancer"
  lb_name                    = "carshub-frontend-lb-${var.env}"
  lb_is_internal             = false
  lb_ip_address_type         = "ipv4"
  load_balancer_type         = "application"
  enable_deletion_protection = true
  security_groups            = [module.carshub_frontend_lb_sg.id]
  subnets                    = module.carshub_public_subnets.subnets[*].id
  target_groups = [
    {
      target_group_name      = "carshub-frontend-tg-${var.env}"
      target_port            = 80
      target_ip_address_type = "ipv4"
      target_protocol        = "HTTP"
      target_type            = "instance"
      target_vpc_id          = module.carshub_vpc.vpc_id

      health_check_interval            = 30
      health_check_path                = "/auth/signin"
      health_check_enabled             = true
      health_check_protocol            = "HTTP"
      health_check_timeout             = 5
      health_check_healthy_threshold   = 3
      health_check_unhealthy_threshold = 3
      health_check_port                = 80
    }
  ]
  listeners = [
    {
      listener_port     = 80
      listener_protocol = "HTTP"
      default_actions = [
        {
          type             = "forward"
          target_group_arn = module.carshub_frontend_lb.target_groups[0].arn
        }
      ]
    }
  ]
}