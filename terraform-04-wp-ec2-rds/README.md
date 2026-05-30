# terraform-04-wp-ec2-rds

## Week 12 Lab — WordPress on EC2 + RDS MySQL

두 계층(web tier / database tier)으로 분리된 WordPress 아키텍처를 AWS에 Terraform으로 배포합니다.  
EC2에서 실행되는 Apache/PHP/WordPress가 **프라이빗 RDS MySQL 인스턴스**에 TCP/3306으로 연결됩니다.

---

## 아키텍처 요약

```
Browser ──HTTP/80──▶ EC2 (Apache + PHP + WordPress)
                         │
                         └──TCP/3306──▶ RDS MySQL (private, no public access)
```

| 리소스 | 설명 |
|--------|------|
| `aws_instance.wordpress` | Amazon Linux 2023, Apache + PHP, WordPress 파일 |
| `aws_db_instance.wordpress` | RDS MySQL 8.0, db.t3.micro, 20GiB gp2 |
| `aws_security_group.wordpress` | EC2 SG: HTTP/80 (0.0.0.0/0), SSH/22 (0.0.0.0/0) |
| `aws_security_group.rds` | RDS SG: MySQL/3306 **EC2 SG에서만** 허용 |
| `aws_db_subnet_group.wordpress` | 기본 VPC의 전체 서브넷 포함 |

---

## 사용 방법

### 1. 사전 준비 — AWS Academy 자격증명 설정

```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# RDS 비밀번호는 반드시 환경변수로만 전달 (tfvars에 절대 기록 금지)
export TF_VAR_db_master_password='Use-A-Lab-Only-Password-Here!'
```

### 2. tfvars 설정

```bash
cp terraform.tfvars.example terraform.tfvars
# 필요시 terraform.tfvars 편집 (db_master_password는 입력하지 않음)
```

### 3. 배포

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out plan.out
terraform apply plan.out   # RDS 생성에 5~10분 소요 — 정상
```

### 4. 출력값 확인

```bash
terraform output
```

| 출력값 | 용도 |
|--------|------|
| `instance_id` | EC2 인스턴스 ID |
| `wordpress_url` | 브라우저에서 WordPress 접속 |
| `health_check_url` | EC2 부트스트랩 성공 확인 |
| `db_check_url` | PHP → RDS 연결 확인 |
| `rds_endpoint` | RDS 엔드포인트 (VPC 내부 전용) |
| `security_group_ids` | EC2 SG, RDS SG ID (보안 경계 확인용) |

### 5. 연결 검증

```bash
# EC2 부트스트랩 확인
curl "$(terraform output -raw health_check_url)"

# PHP → RDS 연결 확인 (이 응답이 {"status":"ok",...} 가 되어야 WordPress 설치 진행)
curl "$(terraform output -raw db_check_url)"

# RDS PubliclyAccessible = false 확인 (반드시 false여야 함)
aws rds describe-db-instances \
  --db-instance-identifier "$(terraform output -raw rds_instance_id)" \
  --query 'DBInstances[0].{Status:DBInstanceStatus,Public:PubliclyAccessible}'
```

### 6. WordPress 브라우저 설치

`terraform output -raw wordpress_url` 을 브라우저에서 열고 설치 마법사를 완료합니다.

### 7. 정리 (반드시 실행)

```bash
terraform destroy
```

---

## 보안 규칙

- `publicly_accessible = false` — 절대 변경 금지
- RDS SG의 3306 포트는 EC2 SG ID만 허용 (0.0.0.0/0 금지)
- `terraform.tfvars`, `terraform.tfstate`, `.pem` 파일은 절대 Git에 커밋 금지
- 비밀번호는 `TF_VAR_db_master_password` 환경변수로만 전달
- 랩 종료 시 반드시 `terraform destroy` 실행

---

## 제출 증거 (commands.md에 기록)

- [ ] EC2 instance ID
- [ ] RDS endpoint address
- [ ] RDS `PubliclyAccessible` = false 확인
- [ ] selected subnet IDs
- [ ] security group IDs (EC2 SG + RDS SG)
- [ ] `health_check_url` HTTP 응답
- [ ] `db_check_url` PHP-to-RDS 결과
- [ ] RDS SG ingress rule (source = EC2 SG, not 0.0.0.0/0)
- [ ] EC2 IAM instance profile (expected: empty)
- [ ] WordPress 브라우저 설치 완료 스크린샷
- [ ] Reflection 작성
- [ ] Cleanup 확인
