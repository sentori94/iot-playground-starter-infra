# Si le réseau existe déjà ailleurs, ne pas appliquer ce fichier (ou importer)
resource "aws_vpc" "main" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "iotp-vpc-dev", Project = "iot-playground-starter" }
}
