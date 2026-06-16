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
    "athena-results",
  ]

  tags = local.common_tags
}

# ── Compute (Glue Jobs + Crawlers) ──────────────────────────────
module "compute" {
  source = "../../modules/compute"

  prefix         = local.prefix
  scripts_bucket = module.raw_zone.bucket_id

  bucket_arns = [
    module.raw_zone.bucket_arn,
    module.cleaned_zone.bucket_arn,
    module.curated_zone.bucket_arn,
  ]

  jobs = {
    cleaned_zone = {
      number_of_workers = 2
      worker_type       = "G.1X"
      extra_args = {
        "--raw_bucket"     = module.raw_zone.bucket_id
        "--cleaned_bucket" = module.cleaned_zone.bucket_id
      }
    }
    curated_zone = {
      number_of_workers = 2
      worker_type       = "G.1X"
      extra_args = {
        "--cleaned_bucket" = module.cleaned_zone.bucket_id
        "--curated_bucket" = module.curated_zone.bucket_id
      }
    }
  }

  crawlers = {
    cleaned_zone = {
      database_name = "cleaned-zone"
      bucket_id     = module.cleaned_zone.bucket_id
      path         = "matches/"
    }
    curated_zone = {
      database_name = "curated-zone"
      bucket_id     = module.curated_zone.bucket_id
      path        = "reports/"
    }
  }

  tags = local.common_tags
}

# ── Step Functions Pipeline ──────────────────────────────────────
module "step_functions" {
  source = "../../modules/step_functions"

  prefix = local.prefix

  cleaned_zone_job_name     = module.compute.job_names["cleaned_zone"]
  curated_zone_job_name     = module.compute.job_names["curated_zone"]
  cleaned_zone_crawler_name = module.compute.crawler_names["cleaned_zone"]
  curated_zone_crawler_name = module.compute.crawler_names["curated_zone"]

  tags = local.common_tags
}