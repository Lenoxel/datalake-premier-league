output "glue_role_arn" {
  description = "ARN da IAM Role usada pelos Glue Jobs e Crawlers"
  value       = aws_iam_role.glue.arn
}

output "job_names" {
  description = "Nomes dos Glue Jobs criados"
  value       = { for k, v in aws_glue_job.this : k => v.name }
}

output "crawler_names" {
  description = "Nomes dos Glue Crawlers criados"
  value       = { for k, v in aws_glue_crawler.this : k => v.name }
}