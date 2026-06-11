variable "prefix" {
  description = "Prefixo usado nos nomes dos recursos"
  type        = string
}

variable "scripts_bucket" {
  description = "Nome do bucket onde os scripts PySpark serão armazenados antes de rodar"
  type        = string
}

variable "bucket_arns" {
  description = "ARNs dos buckets do datalake que o Glue precisa acessar (raw, cleaned, curated)"
  type        = list(string)
}

variable "jobs" {
  description = "Mapa de Glue Jobs a criar"
  type = map(object({
    number_of_workers = number
    worker_type       = string
    extra_args        = map(string)
  }))
}

variable "crawlers" {
  description = "Mapa de Glue Crawlers a criar"
  type = map(object({
    database_name = string
    bucket_id     = string
  }))
}

variable "tags" {
  description = "Tags padrão"
  type        = map(string)
  default     = {}
}