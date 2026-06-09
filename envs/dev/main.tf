locals {
  prefix = "${var.project_name}-${local.env}"
  env    = "dev"

  common_tags = {
    Project     = var.project_name
    Environment = local.env
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

# ── raw-zone ────────────────────────────────
module "raw_zone" {
  source = "../../modules/s3_bucket"

  prefix = local.prefix
  layer  = "raw-zone"

  prefixes = [
    "matches",
  ]

  tags = local.common_tags
}

# ── cleaned-zone ────────────────────────────
module "cleaned_zone" {
  source = "../../modules/s3_bucket"

  prefix = local.prefix
  layer  = "cleaned-zone"

  prefixes = [
    "matches",
  ]

  tags = local.common_tags
}

# ── curated-zone ────────────────────────────
module "curated_zone" {
  source = "../../modules/s3_bucket"

  prefix = local.prefix
  layer  = "curated-zone"

  prefixes = [
    "reports",
  ]

  tags = local.common_tags
}
