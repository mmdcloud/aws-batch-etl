resource "aws_autoscaling_group" "asg" {
  name                      = var.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type
  force_delete              = var.force_delete  
  target_group_arns         = var.target_group_arns
  vpc_zone_identifier       = var.vpc_zone_identifier
  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }
}
