variable "prefix" {
  description = "Prefixo usado nos nomes dos recursos"
  type        = string
}

variable "cleaned_zone_job_name" {
  description = "Nome do Glue Job da cleaned zone"
  type        = string
}

variable "curated_zone_job_name" {
  description = "Nome do Glue Job da curated zone"
  type        = string
}

variable "cleaned_zone_crawler_name" {
  description = "Nome do Glue Crawler da cleaned zone"
  type        = string
}

variable "curated_zone_crawler_name" {
  description = "Nome do Glue Crawler da curated zone"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}