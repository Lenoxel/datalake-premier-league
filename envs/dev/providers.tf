terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ── Backend remoto no S3 ──────────────────
  # Antes do primeiro 'terraform init', rode o bootstrap.sh para criar
  # o bucket de state e a tabela DynamoDB, depois substitua os valores abaixo.
  backend "s3" {
    bucket         = "datalake-premier-league-tfstate-450974104425"
    key            = "datalake-premier-league/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "datalake-premier-league-tfstate-lock"
    use_lockfile   = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "datalake-premier-league"
      ManagedBy = "Terraform"
    }
  }
}
