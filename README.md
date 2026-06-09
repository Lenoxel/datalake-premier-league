# Terraform — Datalake da Premier League

## Arquitetura

```
raw-zone      →  dados brutos, como chegam da fonte
cleaned-zone  →  dados limpos e padronizados
curated-zone  →  dados prontos para consumo / análise
```

Nome dos buckets: `<projeto>-<env>-<layer>-<account_id>-<region>`

## Estrutura

```
terraform-datalake-premier-league/
├── bootstrap.sh
├── modules/
│   └── s3_bucket/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── envs/
    └── dev/
        ├── providers.tf
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars.example
```

## Primeiros passos

```bash
# 1. Bootstrap
chmod +x bootstrap.sh && ./bootstrap.sh

# 2. Preencher providers.tf com os valores impressos pelo bootstrap

# 3. Configurar variáveis
cd envs/dev
cp terraform.tfvars.example terraform.tfvars

# 4. Aplicar
terraform init
terraform plan
terraform apply
```
