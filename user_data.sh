#!/bin/bash
set -e

# -------------------------------
# 1. 시스템 업데이트 및 필수 패키지 설치
# -------------------------------
apt-get update -y
# apt-get upgrade -y  # 디스크 공간 절약을 위해 제거
apt-get install -y curl wget gnupg2 ca-certificates lsb-release software-properties-common

# -------------------------------
# 2. Python 3.12 설치
# -------------------------------
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update
apt-get install -y python3.12 python3.12-venv python3.12-dev

# -------------------------------
# 3. Node.js 22 LTS 설치
# -------------------------------
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# -------------------------------
# 4. Docker & Compose 설치
# -------------------------------
apt-get install -y docker.io docker-compose
systemctl enable docker
systemctl start docker

# -------------------------------
# 5. n8n 환경 설정 (최신 권장사항 적용)
# -------------------------------
mkdir -p /opt/n8n
cd /opt/n8n

# 환경 변수 파일 (최신 n8n 설정)
cat <<EOF > .env
# ========================================
# 데이터베이스 설정
# ========================================
POSTGRES_USER="n8n"
POSTGRES_PASSWORD="${postgres_password}"
POSTGRES_DB="n8ndb"
POSTGRES_HOST="postgres"
POSTGRES_PORT="${postgres_port}"

# ========================================
# Redis 설정
# ========================================
REDIS_HOST="redis"
REDIS_PORT="${redis_port}"

# ========================================
# n8n 기본 설정
# ========================================
N8N_PROTOCOL="http"
N8N_PORT="${n8n_port}"
N8N_HOST="0.0.0.0"
WEBHOOK_URL="https://${subdomain}.${domain_name}"

# ========================================
# 실행 모드 및 성능 최적화 (t2.micro 최적화)
# ========================================
# 실행 모드: production
N8N_MODE="production"

# 워커 프로세스 수 (t2.micro: 1개로 제한)
N8N_WORKERS="1"

# 메모리 제한 (t2.micro: 1GB RAM 고려하여 512MB로 제한)
NODE_OPTIONS="--max-old-space-size=512"

# ========================================
# 데이터베이스 성능 최적화 (t2.micro 최적화)
# ========================================
# 연결 풀 설정 (메모리 절약을 위해 최소화)
DB_TYPE="postgresdb"
DB_POSTGRESDB_HOST="postgres"
DB_POSTGRESDB_PORT="${postgres_port}"
DB_POSTGRESDB_DATABASE="n8ndb"
DB_POSTGRESDB_USER="n8n"
DB_POSTGRESDB_PASSWORD="${postgres_password}"
DB_POSTGRESDB_SCHEMA="public"
DB_POSTGRESDB_POOL_MIN="1"
DB_POSTGRESDB_POOL_MAX="3"

# ========================================
# 보안 설정
# ========================================
# 기본 인증
N8N_BASIC_AUTH_ACTIVE="true"
N8N_BASIC_AUTH_USER="n8n"
N8N_BASIC_AUTH_PASSWORD="${n8n_auth_password}"

# 세션 보안
N8N_SECURE_COOKIE="true"
N8N_COOKIE_SECURE="true"

# ========================================
# 로깅 설정
# ========================================
N8N_LOG_LEVEL="info"
N8N_LOG_OUTPUT="console"

# ========================================
# 파일 저장소 설정
# ========================================
# 바이너리 데이터 저장소: 파일시스템 사용
N8N_DEFAULT_BINARY_DATA_MODE="filesystem"
N8N_BINARY_DATA_STORAGE_PATH="/home/node/.n8n"

# ========================================
# 웹훅 및 API 설정
# ========================================
# 웹훅 URL 검증 비활성화 (프록시 환경)
N8N_DISABLE_WEBHOOK_VERIFICATION="true"

# ========================================
# 성능 최적화 추가 설정
# ========================================
# 캐시 설정
N8N_CACHE_ENABLED="true"
N8N_CACHE_TTL="3600"

# 실행 히스토리 제한
N8N_EXECUTION_DATA_SAVE_ON_ERROR="all"
N8N_EXECUTION_DATA_SAVE_ON_SUCCESS="all"
N8N_EXECUTION_DATA_SAVE_MANUAL_EXECUTIONS="true"
N8N_EXECUTION_DATA_SAVE_DATA_MAX_AGE="168"
N8N_EXECUTION_DATA_SAVE_DATA_PRUNE="true"

# ========================================
# 헬스체크 설정
# ========================================
# 헬스체크 엔드포인트 활성화
N8N_HEALTH_CHECK_ENABLED="true"
EOF

# -------------------------------
# 6. docker-compose.yml 구성 (최신 설정)
# -------------------------------
cat <<EOF > docker-compose.yml
version: "3.8"

services:
  postgres:
    image: postgres:15
    restart: always
    env_file:
      - .env
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: "n8n"
      POSTGRES_PASSWORD: "${postgres_password}"
      POSTGRES_DB: "n8ndb"
      # t2.micro 최적화: PostgreSQL 메모리 설정
      POSTGRES_SHARED_BUFFERS: 128MB
      POSTGRES_EFFECTIVE_CACHE_SIZE: 256MB
      POSTGRES_WORK_MEM: 4MB
      POSTGRES_MAINTENANCE_WORK_MEM: 32MB
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n -d n8ndb"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    # 메모리 제한 설정
    deploy:
      resources:
        limits:
          memory: 256M
        reservations:
          memory: 128M

  redis:
    image: redis:7-alpine
    restart: always
    command: redis-server --appendonly yes --maxmemory 128mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    # 메모리 제한 설정
    deploy:
      resources:
        limits:
          memory: 128M
        reservations:
          memory: 64M

  n8n:
    image: n8nio/n8n:latest
    restart: always
    ports:
      - "80:${n8n_port}"
    env_file:
      - .env
    volumes:
      - n8n_files:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:5678/ || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    environment:
      # 추가 성능 최적화 (t2.micro 최적화)
      NODE_ENV: production
      # 메모리 제한 (t2.micro: 512MB로 제한)
      NODE_OPTIONS: "--max-old-space-size=512"
    # 메모리 제한 설정
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

volumes:
  postgres_data:
  redis_data:
  n8n_files:
EOF

# 권한 설정
chown -R 1000:1000 /opt/n8n

# -------------------------------
# 7. 컨테이너 실행
# -------------------------------
docker-compose up -d

# -------------------------------
# 8. 헬스체크 스크립트 생성
# -------------------------------
cat <<EOF > /opt/n8n/healthcheck.sh
#!/bin/bash

# n8n 헬스체크
if curl -f http://localhost:5678/ > /dev/null 2>&1; then
    echo "n8n is healthy"
    exit 0
else
    echo "n8n is not healthy"
    exit 1
fi
EOF

chmod +x /opt/n8n/healthcheck.sh

# -------------------------------
# 9. 시스템 최적화 (t2.micro 최적화)
# -------------------------------
# 시스템 제한 설정
cat <<EOF >> /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536
EOF

# Docker 데몬 최적화 (t2.micro 메모리 절약)
cat <<EOF > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "5m",
    "max-file": "2"
  }
}
EOF

# 스왑 파일 생성 (t2.micro 메모리 부족 시 대비)
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 시스템 메모리 최적화
cat <<EOF >> /etc/sysctl.conf
# 메모리 최적화
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# 네트워크 최적화
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
EOF

sysctl -p

systemctl restart docker

echo "n8n t2.micro 최적화 설정 적용 완료!"