## Terraform Setup — SCD Data Warehousing

This Terraform configuration provisions the AWS infrastructure required to run the SCD data warehousing pipeline. It creates the following resources:

- **S3 Bucket** (`s3-scd-warehousing-us-west-2-tf`) — destination for NiFi file uploads; Snowpipe reads from here
- **EC2 Instance** (`ec2-scd-warehousing-us-west-2-tf`) — runs Docker with Apache NiFi and JupyterLab
- **IAM Role + Instance Profile** — grants the EC2 instance full S3 access
- **Security Group** — allows SSH inbound; NiFi and JupyterLab are accessed via SSH port forwarding
- **SSH Key Pair** — auto-generated RSA key; private key saved as `ec2-scd-warehousing-us-west-2-tf.pem`

---

### Prerequisites

1. Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and configure credentials:

```
aws configure
```

Enter your AWS Access Key ID, Secret Access Key, and set the region to `us-west-2`.

2. Install [Terraform](https://developer.hashicorp.com/terraform/downloads).

---

### Step 1 — Initialize Terraform

Downloads the required providers (AWS, TLS, Local) and prepares the working directory.

```
terraform init
```

---

### Step 2 — Validate Configuration

Checks all Terraform files for syntax errors before applying.

```
terraform validate
```

---

### Step 3 — Preview Changes

Shows all resources Terraform will create or modify without making any changes.

```
terraform plan
```

---

### Step 4 — Apply (Interactive)

Creates all AWS resources. You will be prompted to confirm before Terraform proceeds.

```
terraform apply
```

---

### Step 5 — Apply (Auto-Approve)

Creates all resources without a confirmation prompt. Useful for automation.

```
terraform apply --auto-approve
```

---

### Step 6 — Fix PEM File Permissions on Windows

After `terraform apply`, fix permissions on the generated key file so SSH accepts it.

```
icacls "ec2-scd-warehousing-us-west-2-tf.pem" /inheritance:r
icacls "ec2-scd-warehousing-us-west-2-tf.pem" /grant:r "%USERNAME%:R"
```

---

### Step 7 — Connect to EC2

```
ssh -i "ec2-scd-warehousing-us-west-2-tf.pem" ec2-user@<EC2_PUBLIC_DNS>
```

To access NiFi and JupyterLab via SSH port forwarding:

```
ssh -i "ec2-scd-warehousing-us-west-2-tf.pem" ec2-user@<EC2_PUBLIC_DNS> -L 2080:localhost:2080 -L 4888:localhost:4888 -L 8050:localhost:8050
```

- NiFi UI: `http://localhost:2080/nifi/`
- JupyterLab: `http://localhost:4888/lab`

---

### Step 8 — Destroy Resources

Removes all resources managed by this Terraform configuration. Use with caution.

```
terraform destroy
```
