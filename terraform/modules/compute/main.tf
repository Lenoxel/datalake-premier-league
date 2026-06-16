# ── IAM Role para o Glue ─────────────────────────────────────────
resource "aws_iam_role" "glue" {
  name = "${var.prefix}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# Política gerenciada da AWS com permissões base do Glue (CloudWatch, Glue Catalog, etc.)
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Política inline com acesso aos buckets do datalake e ao bucket de scripts
resource "aws_iam_role_policy" "glue_s3" {
  name = "${var.prefix}-glue-s3-policy"
  role = aws_iam_role.glue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = concat(
        var.bucket_arns,
        [for arn in var.bucket_arns : "${arn}/*"],
        [
          "arn:aws:s3:::${var.scripts_bucket}",
          "arn:aws:s3:::${var.scripts_bucket}/*"
        ]
      )
    }]
  })
}

# ── Glue Jobs ────────────────────────────────────────────────────
resource "aws_glue_job" "this" {
  for_each = var.jobs

  name         = "${var.prefix}-${each.key}"
  role_arn     = aws_iam_role.glue.arn
  glue_version = "4.0"

  command {
    name            = "glueetl"
    script_location = "s3://${var.scripts_bucket}/glue/${each.key}.py"
    python_version  = "3"
  }

  default_arguments = merge(
    {
      "--job-language"                     = "python"
      "--enable-continuous-cloudwatch-log" = "true"
      "--enable-job-insights"              = "true"
      "--TempDir"                          = "s3://${var.scripts_bucket}/glue/tmp/"
    },
    each.value.extra_args
  )

  number_of_workers = each.value.number_of_workers
  worker_type       = each.value.worker_type

  tags = var.tags
}

# ── Glue Catalog Databases ───────────────────────────────────────
resource "aws_glue_catalog_database" "this" {
  for_each = var.crawlers

  name = each.value.database_name
}

# ── Glue Crawlers ────────────────────────────────────────────────
resource "aws_glue_crawler" "this" {
  for_each = var.crawlers

  name          = "${var.prefix}-${each.key}-crawler"
  role          = aws_iam_role.glue.arn
  database_name = aws_glue_catalog_database.this[each.key].name

  s3_target {
    path = "s3://${each.value.bucket_id}/${each.value.path}"
  }

  tags = var.tags
}