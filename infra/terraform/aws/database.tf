# ── RDS PostgreSQL ────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "postgres" {
  name       = "${var.project_name}-${var.environment}-db-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-db-subnet" })
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = "16.3"
  instance_class = var.rds_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  deletion_protection     = var.environment == "prod"
  skip_final_snapshot     = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-prod-final-snapshot" : null

  performance_insights_enabled = var.environment == "prod"

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-postgres" })
}

# ── ElastiCache Redis ─────────────────────────────────────────────────────────

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-${var.environment}-redis-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = local.common_tags
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project_name}-${var.environment}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  snapshot_retention_limit = var.environment == "prod" ? 3 : 0
  snapshot_window          = "02:00-03:00"

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-redis" })
}
