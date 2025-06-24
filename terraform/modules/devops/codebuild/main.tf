# CodeBuild Configuration
resource "aws_s3_bucket" "codebuild_cache_bucket" {
  bucket        = var.cache_bucket_name
  force_destroy = var.force_destroy_cache_bucket
  tags = {
    Name = var.cache_bucket_name
  }
}

resource "aws_codebuild_project" "codebuild_project" {
  name          = var.codebuild_project_name
  description   = var.codebuild_project_description
  build_timeout = var.build_timeout
  service_role  = var.role

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codebuild_cache_bucket.bucket
  }

  environment {
    compute_type                = var.compute_type
    image                       = var.env_image
    type                        = var.env_type
    image_pull_credentials_type = var.image_pull_credentials_type
    privileged_mode             = var.privileged_mode
    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }
  }
  logs_config {
    cloudwatch_logs {
      group_name  = var.cloudwatch_group_name
      stream_name = var.cloudwatch_stream_name
    }
    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codebuild_cache_bucket.id}/build-log"
    }
  }
  source {
    type            = var.source_type
    location        = var.source_location
    git_clone_depth = var.source_git_clone_depth

    git_submodules_config {
      fetch_submodules = var.fetch_submodules
    }
  }
  source_version = var.source_version
  tags = {
    Name = var.codebuild_project_name
  }
}
