resource "aws_efs_file_system" "file_system" {
  creation_token   = var.creation_token
  encrypted        = var.encrypted
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  lifecycle_policy {
    transition_to_ia = var.transition_to_ia
  }
  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_efs_mount_target" "mount_target" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.file_system.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = var.security_group_ids
}

resource "aws_efs_backup_policy" "backup_policy" {
  file_system_id = aws_efs_file_system.file_system.id
  backup_policy {
    status = var.backup_policy_status
  }
}

resource "aws_efs_access_point" "access_point" {
  file_system_id = aws_efs_file_system.file_system.id
  posix_user {
    uid = var.posix_uid
    gid = var.posix_gid
  }
  root_directory {
    path = var.root_path
    creation_info {
      owner_uid   = var.posix_uid
      owner_gid   = var.posix_gid
      permissions = var.root_permissions
    }
  }
  tags = merge(var.tags, {
    Name = var.access_point_name
  })
}