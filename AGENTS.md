# AGENTS.md

## Project overview
This repository implements a Premier League data lake with Terraform-managed AWS infrastructure and PySpark/Glue ETL jobs. Main entry points are the Terraform environment in [terraform/envs/dev](terraform/envs/dev), the Glue job sources in [src](src), and deployment helpers in [deploy.sh](deploy.sh) and [Makefile](Makefile).

## Working conventions
- Prefer small, focused changes that match the existing module and file layout.
- Keep Terraform changes inside the existing module structure under [terraform/modules](terraform/modules) unless the change is truly environment-specific.
- Keep Glue job logic in the existing Python files under [src/cleaned_zone/job.py](src/cleaned_zone/job.py) and [src/curated_zone/job.py](src/curated_zone/job.py).
- Preserve the current data-lake flow: raw -> cleaned -> curated.

## Common commands
Use the repository helpers before making infrastructure or deployment changes:
- `make init`, `make plan`, `make apply`, `make destroy`
- `make deploy`
- `make run-cleaned`, `make run-curated`, `make run-pipeline`

For local Terraform configuration, copy [terraform/envs/dev/terraform.tfvars.example](terraform/envs/dev/terraform.tfvars.example) to `terraform.tfvars` and keep the real values local; the file is not meant to be committed.

## Important project details
- The deployment script uploads the Glue scripts to S3 from the repository root and expects Terraform outputs to be available.
- Bucket and resource naming follows the project/environment/layer convention described in [README.md](README.md).
- ETL jobs are written for AWS Glue/PySpark and should remain compatible with that runtime.

## When editing
- Update docs only when behavior or workflow changes materially.
- If you change Terraform variables or outputs, verify the related files in [terraform/envs/dev](terraform/envs/dev) and the relevant module under [terraform/modules](terraform/modules).
- If you change ETL behavior, keep the output schema and partitioning expectations consistent with the existing jobs.
