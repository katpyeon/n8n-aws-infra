# n8n AWS Infrastructure

[English](README_EN.md) | 한국어

외부에서 안전하게 접근할 수 있는 n8n 서버를 AWS에 원클릭으로 배포하는 Terraform 프로젝트입니다.

## 💰 비용 정보
- **도메인 구매**: $15 (1회성)
- **월 운영비**: $25~30 (도메인 제외)
- **EC2**: t2.micro (가장 저렴한 플랜)

## ⚠️ 사전 준비사항
1. **AWS Route53에서 도메인 구매 필수** ($15)
2. **EC2 사양을 높이고 싶다면** `user_data.sh`의 도커 설정을 사양에 맞게 변경
3. **문제 해결은 AI와 함께 진행**
4. **모든 진행은 macOS 기준**

## 🚀 배포 단계

### 1. AWS IAM 생성

#### IAM 사용자 생성 (CLI용)
1. **AWS Console** → **IAM** → **Users** → **Create user**
2. **사용자명**: `terraform-user`
3. **액세스 키 생성**: ✅ **Programmatic access** 체크
4. **권한 설정**: ✅ **Attach policies directly** 선택
5. **정책 연결**: 아래 5개 정책 연결
6. **생성 완료**: Access Key ID와 Secret Access Key 저장

#### 필수 정책
- **AmazonEC2FullAccess**: EC2 인스턴스 생성 및 관리
- **AmazonRoute53FullAccess**: 도메인 레코드 등록
- **AWSCertificateManagerFullAccess**: SSL 인증서 발급 및 검증
- **ElasticLoadBalancingFullAccess**: 로드밸런서 생성 및 설정
- **IAMReadOnlyAccess**: IAM 사용자 정보 조회

### 2. AWS CLI 설치 및 설정

```bash
# Homebrew로 설치
brew install awscli

# 설정
aws configure --profile terraform-user
```

#### 설정 정보
```
AWS Access Key ID: [YOUR_ACCESS_KEY]
AWS Secret Access Key: [YOUR_SECRET_KEY]
Default region name: ap-northeast-2
Default output format: json
```

#### 설정 확인
```bash
# 설정 파일 확인
cat ~/.aws/credentials
```

### 3. Terraform 배포

#### 환경변수 설정
```bash
# 1. 설정 파일 생성
cp terraform.tfvars.example terraform.tfvars

# 2. 실제 값으로 수정
nano terraform.tfvars
```

#### 단계별 검증 (권장)
```bash
# 1단계: 네트워킹
terraform apply -target=aws_vpc.main -target=aws_subnet.public -target=aws_subnet.public_2 -target=aws_internet_gateway.igw -target=aws_route_table.public -target=aws_route.default_route -target=aws_route_table_association.public_assoc -target=aws_route_table_association.public_assoc_2

# 2단계: 보안 그룹
terraform apply -target=aws_security_group.alb_sg -target=aws_security_group.ec2_sg

# 3단계: 로드밸런서
terraform apply -target=aws_lb.alb -target=aws_lb_target_group.tg -target=aws_lb_listener.https

# 4단계: SSL 인증서
terraform apply -target=aws_acm_certificate.cert -target=aws_route53_record.cert_validation -target=aws_acm_certificate_validation.cert_validation

# 5단계: EC2 인스턴스
terraform apply -target=aws_instance.n8n -target=aws_lb_target_group_attachment.att

# 6단계: DNS 설정
terraform apply -target=aws_route53_record.alias
```

#### URL 접속 및 확인
- **테라폼 배포가 끝나도 바로 접속되는게 아님**
- **도커 배포가 끝나야 함** 

##### 도커 배포 상태 확인 방법
1. **AWS 콘솔** → **EC2** → **인스턴스**에서 생성된 인스턴스 선택
2. **연결** → **EC2 Instance Connect** → **연결**
3. **웹 콘솔에서 다음 명령어로 도커 상태 확인**:
   ```bash
   # 도커 컨테이너 상태 확인
   sudo docker ps
   
   # n8n 컨테이너가 실행 중인지 확인
   sudo docker logs n8n
   
   # 도커 이미지 다운로드 상태 확인
   sudo docker images
   ```

##### 접속 가능한 경우
- **브라우저에서 URL 접속**
- **"안전하지 않은 웹사이트" 경고**가 나오면:
  1. **AWS 콘솔** → **로드밸런싱** → **대상그룹**에서 상태 확인
  2. **문제 없다면** 인증서 적용 대기 중 (최대 24시간)
  3. **"안전하지 않은 접속"으로 들어가면 n8n 접속 가능**

#### 전체 삭제 및 재배포
```bash
# 전체 삭제
terraform destroy

# 삭제 확인 후 전체 재배포
terraform apply
```

---

<a href="https://www.buymeacoffee.com/katpyeon" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="40" />
</a>%