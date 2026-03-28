############################################
# S3 BUCKET CREATION
############################################
resource "aws_s3_bucket" "my_bucket" {
  bucket = "s3-scd-warehousing-us-west-2-tf" # Must be globally unique

  tags = {
    Name        = "s3-scd-warehousing-us-west-2-tf"
    Environment = "Dev"
  }
}

############################################
# IAM ROLE WITH S3 FULL ACCESS FOR EC2
############################################
resource "aws_iam_role" "ec2_role" {
  name = "ec2-scd-warehousing-us-west-2-tf-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach S3 Full Access policy
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-scd-warehousing-us-west-2-tf-profile"
  role = aws_iam_role.ec2_role.name
}

############################################
# EC2 INSTANCE CONFIGURATION
############################################
# Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Default Subnet
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group - allow SSH (NiFi & JupyterLab accessed via SSH tunneling)
resource "aws_security_group" "allow_ssh" {
  name        = "ec2-scd-warehousing-us-west-2-tf-sg"
  description = "Allow SSH and ports 4000-38888 inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4000
    to_port     = 38888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Generate SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register key in AWS
resource "aws_key_pair" "keypair" {
  key_name   = "ec2-scd-warehousing-us-west-2-tf-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Save private key locally
resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/ec2-scd-warehousing-us-west-2-tf.pem"
  file_permission = "0600"
}

# EC2 Instance
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.large"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name               = aws_key_pair.keypair.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # Add EBS storage
  root_block_device {
    volume_type = "gp3"
    volume_size = 16
  }

  depends_on = [
    aws_s3_bucket.my_bucket,
    aws_iam_role_policy_attachment.s3_full_access
  ]

  tags = {
    Name = "ec2-scd-warehousing-us-west-2-tf"
  }
}
