# Backend configuration
# Le bucket S3 doit être créé manuellement avant terraform init
bucket         = "iot-playground-tfstate-serverless"
key            = "serverless-dev/terraform.tfstate"
region         = "eu-west-3"
encrypt        = true
dynamodb_table = "terraform-lock"

