# ===========================
# Bastion Module
# ===========================

data "aws_ami" "ubuntu22" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.name}-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu22.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_name

  tags = merge(var.tags, {
    Name = var.name
  })
}

# Association EIP si fournie
resource "aws_eip_association" "bastion" {
  count         = var.eip_allocation_id != "" ? 1 : 0
  instance_id   = aws_instance.bastion.id
  allocation_id = var.eip_allocation_id
}

