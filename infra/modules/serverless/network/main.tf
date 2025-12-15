# ===========================
# Subnets Publics pour ALB Grafana
# ===========================
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.public_subnet_cidr_base, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-public-serverless-${var.environment}-${count.index + 1}"
      Type = "Public"
    }
  )
}

# ===========================
# Subnets Privés pour Grafana ECS
# ===========================
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.private_subnet_cidr_base, 4, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-private-serverless-${var.environment}-${count.index + 1}"
      Type = "Private"
    }
  )
}

# ===========================
# Internet Gateway (si pas déjà existant)
# ===========================
data "aws_internet_gateway" "existing" {
  count = var.create_internet_gateway ? 0 : 1

  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_internet_gateway" "main" {
  count  = var.create_internet_gateway ? 1 : 0
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-igw-serverless-${var.environment}"
    }
  )
}

locals {
  internet_gateway_id = var.create_internet_gateway ? aws_internet_gateway.main[0].id : data.aws_internet_gateway.existing[0].id
}

# ===========================
# Elastic IPs pour NAT Gateway
# ===========================
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-eip-nat-serverless-${var.environment}-${count.index + 1}"
    }
  )
}

# ===========================
# NAT Gateways (1 par AZ)
# ===========================
resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-nat-serverless-${var.environment}-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ===========================
# Route Table Publique
# ===========================
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = local.internet_gateway_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-rt-public-serverless-${var.environment}"
    }
  )
}

# ===========================
# Route Table Privée (1 par AZ)
# ===========================
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-rt-private-serverless-${var.environment}-${count.index + 1}"
    }
  )
}

# ===========================
# Associations Route Tables
# ===========================
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

