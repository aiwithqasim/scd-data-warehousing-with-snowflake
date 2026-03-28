############################################
# S3 BUCKET OUTPUTS
############################################
output "s3_bucket_name" {
  description = "Name of the S3 bucket created"
  value       = aws_s3_bucket.my_bucket.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.my_bucket.arn
}

output "s3_bucket_region" {
  description = "AWS region where the S3 bucket is hosted"
  value       = aws_s3_bucket.my_bucket.region
}

############################################
# IAM OUTPUTS
############################################
output "iam_role_name" {
  description = "Name of the IAM role attached to the EC2 instance"
  value       = aws_iam_role.ec2_role.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

############################################
# SECURITY GROUP OUTPUTS
############################################
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.allow_ssh.id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.allow_ssh.name
}

output "security_group_allowed_ports" {
  description = "Inbound ports allowed by the security group"
  value       = "SSH: 22 | Port forwarding range: 4000-38888"
}

############################################
# EC2 INSTANCE OUTPUTS
############################################
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ec2_instance.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.ec2_instance.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.ec2_instance.public_dns
}

output "ec2_instance_type" {
  description = "Instance type of the EC2 instance"
  value       = aws_instance.ec2_instance.instance_type
}

output "ec2_ami_id" {
  description = "AMI ID used for the EC2 instance"
  value       = aws_instance.ec2_instance.ami
}

output "ec2_availability_zone" {
  description = "Availability zone where the EC2 instance is launched"
  value       = aws_instance.ec2_instance.availability_zone
}

output "ec2_subnet_id" {
  description = "Subnet ID the EC2 instance is placed in"
  value       = aws_instance.ec2_instance.subnet_id
}

output "ec2_vpc_id" {
  description = "VPC ID the EC2 instance is placed in"
  value       = data.aws_vpc.default.id
}

output "ec2_root_volume_size_gb" {
  description = "Root EBS volume size in GB"
  value       = aws_instance.ec2_instance.root_block_device[0].volume_size
}

############################################
# SSH KEY OUTPUTS
############################################
output "ssh_key_name" {
  description = "Name of the AWS key pair registered"
  value       = aws_key_pair.keypair.key_name
}

output "ssh_private_key_path" {
  description = "Local path where the private key PEM file is saved"
  value       = local_file.private_key_pem.filename
}

############################################
# SSH CONNECTION COMMAND
############################################
output "ssh_connection_command" {
  description = "Command to SSH into the EC2 instance"
  value       = "ssh -i ${local_file.private_key_pem.filename} ec2-user@${aws_instance.ec2_instance.public_ip}"
}
