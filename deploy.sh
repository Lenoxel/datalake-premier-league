#!/usr/bin/env bash
# Uploads PySpark scripts to S3.
# Must be run from the root of the repository before terraform apply.
#
# Usage:
#   chmod +x deploy.sh
#   ./deploy.sh

set -euo pipefail

echo ">>> Finding bucket name from Terraform outputs..."
cd terraform/envs/dev
RAW_BUCKET=$(terraform output -raw raw_zone_bucket)
cd ../../..

echo ">>> Bucket: $RAW_BUCKET"
echo ""

echo ">>> Uploading PySpark scripts to S3..."

aws s3 cp src/cleaned_zone/job.py \
  s3://${RAW_BUCKET}/glue/cleaned_zone.py \
  && echo "[OK] cleaned_zone.py"

aws s3 cp src/curated_zone/job.py \
  s3://${RAW_BUCKET}/glue/curated_zone.py \
  && echo "[OK] curated_zone.py"

echo ""
echo "✅  Deploy completed. You can now run terraform apply if needed."