output "bucket_id" {
  description = "ID (nome) do bucket criado"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN do bucket criado"
  value       = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "Nome de domínio regional do bucket"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
