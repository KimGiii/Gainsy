#!/bin/bash
set -euo pipefail

# ── Docker ────────────────────────────────────────────────────────────────────
apt-get update -y
apt-get install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# ── AWS CLI v2 ────────────────────────────────────────────────────────────────
apt-get install -y unzip
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# ── nginx ─────────────────────────────────────────────────────────────────────
apt-get install -y nginx certbot python3-certbot-nginx

cat > /etc/nginx/sites-available/healthcare <<'NGINX'
server {
    listen 80;
    server_name _;

    location /actuator/health {
        proxy_pass http://127.0.0.1:8080;
    }

    location / {
        proxy_pass         http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/healthcare /etc/nginx/sites-enabled/healthcare
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# ── FCM 자격증명 디렉토리 ────────────────────────────────────────────────────
mkdir -p /etc/healthcare
chown ubuntu:ubuntu /etc/healthcare

# ── ECR 로그인 cron (12시간마다 토큰 갱신) ───────────────────────────────────
cat > /etc/cron.d/ecr-login <<CRON
0 */12 * * * root aws ecr get-login-password --region ${aws_region} \
  | docker login --username AWS --password-stdin ${ecr_registry} >> /var/log/ecr-login.log 2>&1
CRON

# ── CloudWatch Agent ──────────────────────────────────────────────────────────
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
  -O /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb
rm /tmp/amazon-cloudwatch-agent.deb

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWA'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/${project_name}/${environment}/syslog"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/${project_name}/${environment}/nginx-error"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "mem": { "measurement": ["mem_used_percent"] },
      "disk": { "measurement": ["disk_used_percent"], "resources": ["/"] }
    }
  }
}
CWA

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
