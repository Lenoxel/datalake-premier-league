# Premier League Datalake

## Overview

This repository contains the Premier League datalake implementation, including Terraform infrastructure and AWS Glue ETL job code.

It currently includes:
- `terraform/`: infrastructure as code for S3 data lake layers, Glue compute resources, and environment configuration
- `src/`: Glue job source code for data cleaning and curation
- `queries/`: query artifacts and related code

## Architecture

```
raw-zone      → raw ingested data
cleaned-zone  → cleaned and normalized data
curated-zone  → analytics-ready data
```

Bucket naming convention:
`<project>-<env>-<layer>-<account_id>-<region>`

## Repository structure

```
.
├── Makefile
├── README.md
├── deploy.sh
├── queries/
│   └── job.py
├── src/
│   ├── cleaned_zone/
│   │   └── job.py
│   └── curated_zone/
│       └── job.py
└── terraform/
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
        ├── s3_bucket/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        └── step_functions/
            ├── main.tf
            ├── outputs.tf
            └── variables.tf
```

## Terraform

The `terraform/` directory contains infrastructure configuration for the datalake.

- `terraform/bootstrap.sh`: creates the remote state S3 bucket and DynamoDB locking table.
- `terraform/envs/dev/`: environment-specific configuration.
- `terraform/modules/s3_bucket/`: reusable S3 bucket module for each data lake layer.
- `terraform/modules/compute/`: Glue job and crawler module.
- `terraform/modules/step_functions/`: AWS Step Functions state machine for orchestrating the ETL pipeline.
- `terraform/modules/athena/`: Athena-related resources placeholder.

### Deploying Terraform

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

## Makefile commands

This repository includes a `Makefile` that simplifies common tasks.

- `make init` — initialize Terraform in `terraform/envs/dev`
- `make plan` — run `terraform plan` in `terraform/envs/dev`
- `make apply` — run `terraform apply` in `terraform/envs/dev`
- `make destroy` — run `terraform destroy` in `terraform/envs/dev`
- `make deploy` — deploy Glue scripts using `deploy.sh`
- `make run-cleaned` — start the cleaned-zone Glue job
- `make run-curated` — start the curated-zone Glue job
- `make status-cleaned` — show the latest cleaned-zone Glue job run status
- `make status-curated` — show the latest curated-zone Glue job run status
- `make crawl-cleaned` — start the cleaned-zone Glue crawler
- `make crawl-curated` — start the curated-zone Glue crawler
- `make status-crawler-cleaned` — show the cleaned-zone crawler status
- `make status-crawler-curated` — show the curated-zone crawler status
- `make ls-cleaned` — list sample objects in the cleaned zone S3 prefix
- `make ls-curated` — list sample objects in the curated zone S3 bucket
- `make catalog-cleaned` — list Glue catalog tables in the `cleaned-zone` database
- `make catalog-curated` — list Glue catalog tables in the `curated-zone` database
- `make run-pipeline` — start a Step Functions state machine execution
- `make status-pipeline` — show the status of the latest Step Functions execution

## Glue job source code

The `src/` directory contains Python code for AWS Glue jobs.

- `src/cleaned_zone/job.py`: ETL code that reads raw match CSVs, normalizes column names, parses dates, computes seasons, and writes cleaned Parquet output.
- `src/curated_zone/job.py`: placeholder for curation logic.

## Queries

The `queries/` directory currently contains query artifacts used by the project.

## Notes

- Remote state configuration is managed in `terraform/envs/dev/providers.tf`.
- `terraform/envs/dev/terraform.tfvars` is excluded from version control and should not be committed.
- The Glue compute module currently stores scripts in the `raw-zone` bucket under the `glue/` prefix.
