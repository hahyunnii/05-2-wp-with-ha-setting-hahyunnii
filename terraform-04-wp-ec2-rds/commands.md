# Week 12 Lab — WordPress on EC2 + RDS MySQL
# Commands Log & Evidence File

## 0. Safety Rules (confirm before starting)

```text
- AWS Academy credentials are temporary — never commit passwords, state files, or .pem keys to Git
- RDS must stay publicly_accessible = false at all times
- Use db.t3.micro and 20 GiB storage only
- Run terraform destroy at the end of the lab session
```

---

## 1. Preflight Checks

```bash
# Navigate to the lab folder
cd terraform-04-wp-ec2-rds

# Confirm AWS Academy credentials are set
test -n "$AWS_ACCESS_KEY_ID"     && echo "AWS_ACCESS_KEY_ID is set"
test -n "$AWS_SECRET_ACCESS_KEY" && echo "AWS_SECRET_ACCESS_KEY is set"
test -n "$AWS_SESSION_TOKEN"     && echo "AWS_SESSION_TOKEN is set"
test -n "$TF_VAR_db_master_password" && echo "TF_VAR_db_master_password is set"

# Set RDS password as environment variable (never in tfvars!)
# export TF_VAR_db_master_password='Use-A-Lab-Only-Password-Here'

# Confirm AWS credentials are active
aws sts get-caller-identity

# Confirm default region
aws configure get region

# Confirm Terraform version
terraform version
```

Key output:

Interpretation:

---

## 2. Init → Plan → Apply

```bash
# Copy tfvars example
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if needed (do NOT add db_master_password here)

# Initialize working directory and download AWS provider
terraform init

# Normalize formatting
terraform fmt

# Check syntax and resource references
terraform validate

# Preview the plan (RDS + EC2 + SGs + subnet group)
terraform plan -out plan.out

# Apply the plan — RDS creation takes 5-10 minutes, this is normal
terraform apply plan.out
```

Key output:

Interpretation:

---

## 3. Terraform Outputs

```bash
# Print all outputs — copy these values into this file immediately
terraform output
```

### Evidence — Terraform & Infrastructure

| Output | Value |
|--------|-------|
| instance_id | *(paste here)* |
| rds_endpoint | *(paste here)* |
| rds_instance_id | *(paste here)* |
| db_name | *(paste here)* |
| selected_subnet_ids | *(paste here)* |
| security_group_ids | *(paste here)* |
| wordpress_url | *(paste here)* |
| health_check_url | *(paste here)* |
| db_check_url | *(paste here)* |

---

## 4. Connectivity Verification

```bash
# 1. Confirm EC2 bootstrap wrote the health file (Apache is up)
curl "$(terraform output -raw health_check_url)"

# 2. Confirm PHP on EC2 can authenticate to RDS — DO NOT proceed to WordPress
#    setup until this returns {"status":"ok",...}
curl "$(terraform output -raw db_check_url)"

# 3. Confirm RDS is available and NOT publicly accessible
aws rds describe-db-instances \
  --db-instance-identifier "$(terraform output -raw rds_instance_id)" \
  --query 'DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address,Public:PubliclyAccessible,Engine:Engine}'

# 4. Confirm RDS SG allows 3306 from EC2 SG only (not 0.0.0.0/0)
RDS_SG_ID=$(terraform output -json security_group_ids | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['rds'])")
aws ec2 describe-security-groups \
  --group-ids "$RDS_SG_ID" \
  --query 'SecurityGroups[0].IpPermissions'

# 5. Confirm EC2 IAM instance profile is empty (MySQL password auth, not IAM)
aws ec2 describe-instances \
  --instance-ids "$(terraform output -raw instance_id)" \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'
```

### Evidence — Connectivity & WordPress

| Check | Result |
|-------|--------|
| health_check_url HTTP response | *(paste output)* |
| db_check_url PHP-to-RDS result | *(paste output)* |
| RDS PubliclyAccessible flag | *(must be false)* |
| RDS SG ingress source | *(must be EC2 SG, not 0.0.0.0/0)* |
| EC2 IAM instance profile | *(expected: empty/null)* |

---

## 5. WordPress Browser Setup

```bash
# Open the WordPress URL in your browser
terraform output -raw wordpress_url
```

Steps to complete in browser:
1. Open `wordpress_url` in your browser
2. Select language → click Continue
3. Enter site title, admin username, admin password, and admin email
4. Click **Install WordPress**
5. Log in at `/wp-admin` and confirm the dashboard loads

Screenshot: *(attach WordPress setup completion screenshot)*

---

## 6. Reflection

**What moved to RDS vs. what still lives on EC2:**

*(Write your answer here)*

- Moved to RDS: WordPress database tables (posts, users, options, etc.)
- Still on EC2: Apache, PHP, WordPress application files, wp-config.php, media uploads

**What does `publicly_accessible = false` protect against?**

*(Write your answer here)*

---

## 7. Cleanup

```bash
# Destroy all resources — always run this before the lab session ends
terraform destroy
```

Cleanup confirmation: *(paste "Destroy complete! Resources: X destroyed" line)*

---

## Credential Handling Note

```text
AWS Academy temporary credentials must be stored in environment variables only.
Never put AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN,
or TF_VAR_db_master_password into terraform.tfvars or any committed file.
Do not commit: terraform.tfvars, terraform.tfstate, .pem key files,
or any file containing credential strings.
```
