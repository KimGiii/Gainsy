# ── EC2 ───────────────────────────────────────────────────────────────────────

output "app_public_ip" {
  description = "애플리케이션 서버 공인 IP (Elastic IP)"
  value       = aws_eip.app.public_ip
}

output "app_instance_id" {
  description = "EC2 인스턴스 ID"
  value       = aws_instance.app.id
}

# ── RDS ───────────────────────────────────────────────────────────────────────

output "db_endpoint" {
  description = "RDS 엔드포인트 (host:port)"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "db_url" {
  description = "Spring datasource URL"
  value       = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${var.db_name}"
  sensitive   = true
}

# ── ElastiCache ───────────────────────────────────────────────────────────────

output "redis_host" {
  description = "ElastiCache Redis 엔드포인트"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
  sensitive   = true
}

# ── ECR ───────────────────────────────────────────────────────────────────────

output "ecr_repository_url" {
  description = "ECR 리포지토리 URL"
  value       = aws_ecr_repository.api.repository_url
}

output "ecr_registry" {
  description = "ECR 레지스트리 호스트 (account_id.dkr.ecr.region.amazonaws.com)"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# ── S3 ────────────────────────────────────────────────────────────────────────

output "progress_photo_bucket_name" {
  description = "진행 사진 저장용 S3 버킷 이름"
  value       = aws_s3_bucket.progress_photos.bucket
}

output "progress_photo_bucket_region" {
  description = "진행 사진 저장용 S3 버킷 리전"
  value       = var.aws_region
}

output "progress_photo_bucket_access_policy_arn" {
  description = "EC2 IAM 역할에 연결된 S3 접근 정책 ARN"
  value       = aws_iam_policy.progress_photo_bucket_access.arn
}

# ── GitHub Actions 시크릿 출력 가이드 ─────────────────────────────────────────

output "github_secrets_guide" {
  description = "GitHub Actions에 등록할 시크릿 값 요약"
  sensitive   = true
  value = <<-EOT
    === GitHub Actions 시크릿 등록 값 ===
    DEV_SSH_HOST     = ${aws_eip.app.public_ip}
    DEV_DB_URL       = jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${var.db_name}
    DEV_REDIS_HOST   = ${aws_elasticache_cluster.redis.cache_nodes[0].address}
    ECR_REGISTRY     = ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
  EOT
}
