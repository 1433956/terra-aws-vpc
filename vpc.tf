resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

 tags = merge(
    local.common_tags,
    {
    Name= "${var.project}-${var.enviornment}"
    }
 )
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
tags = merge(
    local.common_tags,
    {
        Name="${var.project}-${var.enviornment}"
    }
)
}
#roboshop-dev-us-east-1a
resource "aws_subnet" "public" {
    count=length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index] #public_subnet_cidr
  availability_zone = local.az-names[count.index]
  map_public_ip_on_launch = true
  tags =merge(
    local.common_tags,
    {
      Name="${var.project}-${var.enviornment}-public-${local.az-names[count.index]}"
    }
  )
}
resource "aws_subnet" "private" {
    count=length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = local.az-names[count.index]
  
  tags =merge(
    var.private_subnet_tags,
    local.common_tags,
    {
      Name="${var.project}-${var.enviornment}-private-${local.az-names[count.index]}"
    }
  )
}
resource "aws_subnet" "database" {
    count=length(var.database_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidrs[count.index] #public_subnet_cidr
  availability_zone = local.az-names[count.index]
  
  tags =merge(
    var.database_subnet_tags,
    local.common_tags,
    {
      Name="${var.project}-${var.enviornment}-database-${local.az-names[count.index]}"
    }
  )
}
resource "aws_eip" "nat" {
  
  domain   = "vpc"
  tags = merge(
    var.eip_tags,
    local.common_tags,
    {
      Name="${var.project}-${var.enviornment}"
    }
  )
}
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = merge(
    var.nat_gateway_tags,
    local.common_tags,
    {
      Name="${var.project}-${var.enviornment}"
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.public_route_table_tags,
    local.common_tags,
    {
      Name="${var.project}-${var.enviornment}-public"
    }
  )

}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.private_route_table_tags,
    local.common_tags,
    {
      Name="${var.project}-${var.enviornment}-private"
    }
  )

}
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.database_route_table_tags,
    local.common_tags,
    {
      Name="${var.project}-${var.enviornment}-database"
    }
  )

}
resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}
resource "aws_route" "private" {
  
  route_table_id  = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.main.id
}
resource "aws_route" "database" {

  route_table_id= aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.main.id
}
resource "aws_route_table_association" "public" {
count=length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
count=length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
count=length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}


