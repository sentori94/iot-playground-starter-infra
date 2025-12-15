# ===========================
# VPC pour Serverless
# ===========================
resource "aws_vpc" "serverless" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-vpc-${var.environment}"
    }
  )
}

# ===========================
# Internet Gateway
# ===========================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.serverless.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-igw-${var.environment}"
    }
  )
}

# ===========================
# Subnets Publics
# ===========================
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.serverless.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-public-${var.environment}-${count.index + 1}"
      Type = "Public"
    }
  )
}

# ===========================
# Subnets Privés
# ===========================
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.serverless.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-private-${var.environment}-${count.index + 1}"
      Type = "Private"
    }
  )
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
      Name = "${var.project}-eip-nat-${var.environment}-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ===========================
# NAT Gateways
# ===========================
resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-nat-${var.environment}-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ===========================
# Route Table Publique
# ===========================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.serverless.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-rt-public-${var.environment}"
    }
  )
}

# ===========================
# Route Tables Privées
# ===========================
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.serverless.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-rt-private-${var.environment}-${count.index + 1}"
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

