resource "aws_iam_role" "sfn" {
  name = "${var.prefix}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "sfn" {
  name = "${var.prefix}-sfn-policy"
  role = aws_iam_role.sfn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:StartCrawler",
          "glue:GetCrawler",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "sfn" {
  name              = "/aws/states/${var.prefix}-pipeline"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_sfn_state_machine" "pipeline" {
  name     = "${var.prefix}-etl-pipeline"
  role_arn = aws_iam_role.sfn.arn
  type     = "STANDARD"

  definition = jsonencode({
    Comment = "Pipeline ETL Premier League: raw_zone -> cleaned zone -> curated zone"
    StartAt = "Run Cleaned Zone Job"
    States = {
      "Run Cleaned Zone Job" = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.cleaned_zone_job_name
        }
        Next  = "Start Cleaned Zone Crawler"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "Pipeline Failed"
        }]
      }

      "Start Cleaned Zone Crawler" = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:glue:startCrawler"
        Parameters = {
          Name = var.cleaned_zone_crawler_name
        }
        Next = "Wait For Cleaned Zone Crawler"
      }

      "Wait For Cleaned Zone Crawler" = {
        Type    = "Wait"
        Seconds = 15
        Next    = "Check Cleaned Zone Crawler"
      }

      "Check Cleaned Zone Crawler" = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:glue:getCrawler"
        Parameters = {
          Name = var.cleaned_zone_crawler_name
        }
        Next = "Is Cleaned Zone Crawler Ready?"
      }

      "Is Cleaned Zone Crawler Ready?" = {
        Type = "Choice"
        Choices = [{
          Variable     = "$.Crawler.State"
          StringEquals = "READY"
          Next         = "Run Curated Zone Job"
        }]
        Default = "Wait For Cleaned Zone Crawler"
      }

      "Run Curated Zone Job" = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.curated_zone_job_name
        }
        Next  = "Start Curated Zone Crawler"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "Pipeline Failed"
        }]
      }

      "Start Curated Zone Crawler" = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:glue:startCrawler"
        Parameters = {
          Name = var.curated_zone_crawler_name
        }
        Next = "Wait For Curated Zone Crawler"
      }

      "Wait For Curated Zone Crawler" = {
        Type    = "Wait"
        Seconds = 15
        Next    = "Check Curated Zone Crawler"
      }

      "Check Curated Zone Crawler" = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:glue:getCrawler"
        Parameters = {
          Name = var.curated_zone_crawler_name
        }
        Next = "Is Curated Zone Crawler Ready?"
      }

      "Is Curated Zone Crawler Ready?" = {
        Type = "Choice"
        Choices = [{
          Variable     = "$.Crawler.State"
          StringEquals = "READY"
          Next         = "Pipeline Succeeded"
        }]
        Default = "Wait For Curated Zone Crawler"
      }

      "Pipeline Succeeded" = {
        Type = "Succeed"
      }

      "Pipeline Failed" = {
        Type  = "Fail"
        Error = "PipelineError"
        Cause = "A step in the ETL pipeline failed. Check the logs for more details."
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn.arn}:*"
    include_execution_data = true
    level                  = "ERROR"
  }

  tags = var.tags
}