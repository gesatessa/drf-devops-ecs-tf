# EFS for media storage
# EFS is used to store user-uploaded media files persistently
# and share them across multiple ECS tasks.

# NFS protocol uses port 2049
# NFS: Network File System, a distributed file system protocol

resource "aws_efs_file_system" "media" {
  encrypted = true
  tags = {
    Name = "${local.prefix}-efs-media"
  }

}

resource "aws_security_group" "efs" {
  name   = "${local.prefix}-efs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    #cidr_blocks = [aws_vpc.main.cidr_block]

    security_groups = [aws_security_group.ecs_tasks.id]
    description     = "Allow NFS access from ECS tasks"
  }
}

# Mount targets for EFS in each private subnet ---------------------- #
# we need mount targets so that ECS tasks can connect to EFS
# from each availability zone
# we have 2 private subnets (a and b), so we create 2 mount targets
resource "aws_efs_mount_target" "private_a" {
  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = aws_subnet.private_a.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "private_b" {
  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = aws_subnet.private_b.id
  security_groups = [aws_security_group.efs.id]
}

# Access point for EFS ---------------------- #
# Access points simplify the process of connecting to EFS
# root_directory enforces a specific directory structure and permissions
# where ECS tasks will read/write media files

resource "aws_efs_access_point" "media_ap" {
  file_system_id = aws_efs_file_system.media.id
  root_directory {
    path = "api/media" # directory inside EFS where media files are stored

    creation_info {
      owner_gid   = 101 # comes from the ecs user inside the container (see Dockerfile)
      owner_uid   = 101
      permissions = "755"
    }
  }
}

