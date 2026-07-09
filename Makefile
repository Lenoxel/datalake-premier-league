# ─────────────────────────────────────────────
# Variables
# ─────────────────────────────────────────────
TF_ENV         := terraform/envs/dev
JOB_CLEANED    := datalake-premier-league-dev-cleaned_zone
JOB_CURATED    := datalake-premier-league-dev-curated_zone
CRAWLER_CLEANED := datalake-premier-league-dev-cleaned_zone-crawler
CRAWLER_CURATED := datalake-premier-league-dev-curated_zone-crawler

# ─────────────────────────────────────────────
# Terraform
# ─────────────────────────────────────────────
init:
	cd $(TF_ENV) && terraform init

plan:
	cd $(TF_ENV) && terraform plan

apply:
	cd $(TF_ENV) && terraform apply

destroy:
	cd $(TF_ENV) && terraform destroy

# ─────────────────────────────────────────────
# Deploy of PySpark scripts to S3
# ─────────────────────────────────────────────
deploy:
	chmod +x deploy.sh && ./deploy.sh

# ─────────────────────────────────────────────
# Glue Jobs
# ─────────────────────────────────────────────
run-cleaned:
	aws glue start-job-run --job-name $(JOB_CLEANED)

run-curated:
	aws glue start-job-run --job-name $(JOB_CURATED)

run-curated-iceberg:
	aws glue start-job-run --job-name $(JOB_CURATED) --arguments='{"--output_format":"iceberg"}'

status-cleaned:
	aws glue get-job-runs --job-name $(JOB_CLEANED) \
		--query 'JobRuns[0].{Status:JobRunState, Started:StartedOn, Duration:ExecutionTime}' \
		--output table

status-curated:
	aws glue get-job-runs --job-name $(JOB_CURATED) \
		--query 'JobRuns[0].{Status:JobRunState, Started:StartedOn, Duration:ExecutionTime}' \
		--output table

# ─────────────────────────────────────────────
# Glue Crawlers
# ─────────────────────────────────────────────
crawl-cleaned:
	aws glue start-crawler --name $(CRAWLER_CLEANED)

crawl-curated:
	aws glue start-crawler --name $(CRAWLER_CURATED)

status-crawler-cleaned:
	aws glue get-crawler --name $(CRAWLER_CLEANED) \
		--query 'Crawler.{State:State, LastRun:LastCrawl.StartTime}' \
		--output table

status-crawler-curated:
	aws glue get-crawler --name $(CRAWLER_CURATED) \
		--query 'Crawler.{State:State, LastRun:LastCrawl.StartTime}' \
		--output table

# ─────────────────────────────────────────────
# S3 Checks
# ─────────────────────────────────────────────
ls-cleaned:
	aws s3 ls s3://$$(cd $(TF_ENV) && terraform output -raw cleaned_zone_bucket)/matches/ --recursive | head -20

ls-curated:
	aws s3 ls s3://$$(cd $(TF_ENV) && terraform output -raw curated_zone_bucket)/ --recursive | head -20

# ─────────────────────────────────────────────
# Glue Catalog
# ─────────────────────────────────────────────
catalog-cleaned:
	aws glue get-tables --database-name cleaned-zone \
		--query 'TableList[*].Name'

catalog-curated:
	aws glue get-tables --database-name curated-zone \
		--query 'TableList[*].Name'

# ─────────────────────────────────────────────
# Step Functions
# ─────────────────────────────────────────────
run-pipeline:
	aws stepfunctions start-execution \
		--state-machine-arn $$(cd $(TF_ENV) && terraform output -raw state_machine_arn) \
		--name "exec-$$(date +%Y%m%d-%H%M%S)"

status-pipeline:
	aws stepfunctions list-executions \
		--state-machine-arn $$(cd $(TF_ENV) && terraform output -raw state_machine_arn) \
		--query 'executions[0].{Status:status, Start:startDate, Stop:stopDate}' \
		--output table