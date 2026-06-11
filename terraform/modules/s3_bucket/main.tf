# ─────────────────────────────────────────────
# Módulo: s3_bucket
# Cria um bucket S3 com boas práticas aplicadas:
#   - Nome com namespace regional (account_id + region)
#   - Versionamento habilitado
#   - Bloqueio de acesso público
#   - Criptografia SSE-S3 por padrão
# ─────────────────────────────────────────────

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "this" {
  bucket = "${var.prefix}-${var.layer}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  tags = merge(var.tags, {
    Layer = var.layer
  })
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "prefixes" {
  for_each = toset(var.prefixes)

  bucket  = aws_s3_bucket.this.id
  key     = "${each.value}/"
  content = ""

  tags = var.tags
}
