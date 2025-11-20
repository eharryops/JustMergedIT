resource "aws_vpc" "main" {
  count      = var.use_existing_vpc ? 0 : 1
  cidr_block = var.vpc_cidr
  tags = {
    Name = "main-vpc"
    "karpenter.sh/discovery" = var.eks_cluster_name
  }
}

resource "aws_subnet" "public_a" {
  vpc_id = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.main[0].id
  cidr_block              = var.public_subnet_cidrs[0]
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "public-subnet"
    "karpenter.sh/discovery" = var.eks_cluster_name
  }
}

resource "aws_subnet" "public_b" {
  vpc_id = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.main[0].id
  cidr_block              = var.public_subnet_cidrs[1]
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"
  tags = {
    Name = "public-subnet"
    "karpenter.sh/discovery" = var.eks_cluster_name
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.main[0].id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "private-subnet"
    "karpenter.sh/discovery" = var.eks_cluster_name
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.main[0].id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "private-subnet"
    "karpenter.sh/discovery" = var.eks_cluster_name
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.main[0].id
  tags   = { Name = "main-gateway" }
}

resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  tags          = { Name = "main-nat" }
  depends_on    = [aws_eip.nat]
}

resource "aws_route_table" "public" {
  vpc_id = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.main[0].id
  tags   = { Name = "public-rt" }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.main[0].id
  tags   = { Name = "private-rt" }
}

resource "aws_route" "private_nat_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_assoc_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

