#!/usr/bin/env bash
# Cria o bucket S3 de backend e a tabela DynamoDB de lock
# antes do primeiro `terraform init`.
#
# Uso:
#   chmod +x bootstrap.sh
#   ./bootstrap.sh

set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-us-east-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROJECT="datalake-premier-league"

STATE_BUCKET="${PROJECT}-tfstate-${ACCOUNT_ID}"
LOCK_TABLE="${PROJECT}-tfstate-lock"

echo ">>> Região  : $REGION"
echo ">>> Conta   : $ACCOUNT_ID"
echo ">>> Bucket  : $STATE_BUCKET"
echo ">>> DynamoDB: $LOCK_TABLE"
echo ""

# Criar bucket de state
if aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
  echo "[OK] Bucket '$STATE_BUCKET' já existe."
else
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$STATE_BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$STATE_BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  echo "[CRIADO] Bucket '$STATE_BUCKET'"
fi

aws s3api put-bucket-versioning \
  --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-public-access-block \
  --bucket "$STATE_BUCKET" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "[OK] Versionamento e bloqueio público configurados."

# Criar tabela DynamoDB de lock
if aws dynamodb describe-table --table-name "$LOCK_TABLE" --region "$REGION" 2>/dev/null; then
  echo "[OK] Tabela '$LOCK_TABLE' já existe."
else
  aws dynamodb create-table \
    --table-name "$LOCK_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
  echo "[CRIADO] Tabela DynamoDB '$LOCK_TABLE'"
fi

echo ""
echo "✅  Bootstrap concluído!"
echo ""
echo "Atualize envs/dev/providers.tf com:"
echo "  bucket         = \"$STATE_BUCKET\""
echo "  dynamodb_table = \"$LOCK_TABLE\""
echo "  region         = \"$REGION\""
echo ""
echo "Depois execute:"
echo "  cd envs/dev && terraform init && terraform plan"
