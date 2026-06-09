variable "prefix" {
  description = "Prefixo do projeto usado na composição do nome do bucket (ex: datalake-premier-league-dev)"
  type        = string
}

variable "layer" {
  description = "Camada do datalake: raw-zone | cleaned-zone | curated-zone"
  type        = string

  validation {
    condition     = contains(["raw-zone", "cleaned-zone", "curated-zone"], var.layer)
    error_message = "O valor de 'layer' deve ser: raw-zone, cleaned-zone ou curated-zone."
  }
}

variable "prefixes" {
  description = "Lista de prefixos (pastas) a criar dentro do bucket"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags padrão aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
