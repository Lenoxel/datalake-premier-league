output "raw_zone_bucket" {
  description = "Nome do bucket raw-zone"
  value       = module.raw_zone.bucket_id
}

output "cleaned_zone_bucket" {
  description = "Nome do bucket cleaned-zone"
  value       = module.cleaned_zone.bucket_id
}

output "curated_zone_bucket" {
  description = "Nome do bucket curated-zone"
  value       = module.curated_zone.bucket_id
}

output "raw_zone_arn" {
  value = module.raw_zone.bucket_arn
}

output "cleaned_zone_arn" {
  value = module.cleaned_zone.bucket_arn
}

output "curated_zone_arn" {
  value = module.curated_zone.bucket_arn
}
