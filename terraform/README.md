# Terraform — Premier League Datalake

## Overview

This directory contains the Terraform configuration for the Premier League datalake deployment.

It currently provisions:
- AWS S3 buckets for `raw-zone`, `cleaned-zone`, and `curated-zone`
- AWS Glue resources for ETL jobs and crawlers
- reusable modules for S3 buckets and compute resources

## Architecture

```
raw-zone      → raw ingested data
cleaned-zone  → cleaned and normalized data
curated-zone  → analytics-ready data
```

Bucket naming convention:
`<project>-<env>-<layer>-<account_id>-<region>`

## Current structure

```
terraform/
├── .gitignore
├── README.md
├── bootstrap.sh
├── envs/
│   └── dev/
│       ├── main.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── terraform.tfvars
│       └── terraform.tfvars.example
└── modules/
    ├── athena/
    ├── compute/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    └── s3_bucket/
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

## Modules

- `modules/s3_bucket`: reusable S3 bucket module for the datalake layers.
- `modules/compute`: Glue compute module for jobs, crawlers, and Glue catalog databases.
- `modules/athena`: Athena-related resources placeholder.

## Environment configuration

The current environment configuration is located in `envs/dev`.

- `envs/dev/providers.tf`: backend and AWS provider configuration.
- `envs/dev/main.tf`: environment module definitions.
- `envs/dev/variables.tf`: environment-specific variables.
- `envs/dev/outputs.tf`: outputs for bucket names and ARNs.
- `envs/dev/terraform.tfvars.example`: sample variable values.

> `envs/dev/terraform.tfvars` should not be committed; it is ignored by `.gitignore`.

## Bootstrap remote state

Before the first `terraform init`, create the remote state bucket and DynamoDB lock table using:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

The script prints the values to use in `envs/dev/providers.tf` for:
- `bucket`
- `dynamodb_table`
- `region`

## Quick start

```bash
cd terraform
chmod +x bootstrap.sh
./bootstrap.sh

cd envs/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Notes

- The `compute` module uses the `raw-zone` bucket for Glue script storage.
- The `curated-zone` layer currently contains the `reports` prefix.
- The `envs/dev` setup creates three data lake layer buckets and one compute module.
