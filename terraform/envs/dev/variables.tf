variable "project_name" {
  description = "Nome curto do projeto - usado na composição do nome dos buckets"
  type        = string
  default     = "datalake-premier-league"
}

variable "owner" {
  description = "Responsável pelo projeto (seu nome ou email)"
  type        = string
  default     = "gabriel-lenon"
}

variable "aws_region" {
  description = "Região AWS onde os recursos serão provisionados"
  type        = string
  default     = "us-east-1"
}
