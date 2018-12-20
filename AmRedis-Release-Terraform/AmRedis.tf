##[ VPC一式 定義 ]##############################################################

## VPC
resource "aws_vpc" "VPC" {
  cidr_block                       = "${var.vpc_cidr_block}"
  assign_generated_ipv6_cidr_block = true
  instance_tenancy                 = "default"
  tags {
    Name = "${var.title}-${var.env}"
  }
}

## Subnet
resource "aws_subnet" "Subnet" {
  vpc_id            = "${aws_vpc.VPC.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.VPC.cidr_block, 8, 0)}"
  ipv6_cidr_block   = "${cidrsubnet(aws_vpc.VPC.ipv6_cidr_block, 8, 0)}"  
  availability_zone = "${var.aws_az}"
  tags {
    Name = "${var.title}-${var.env}"
  }
}

## SubnetGroup for ElastiCache
resource "aws_elasticache_subnet_group" "SubnetGroup" {
  name       = "${var.title}-subnet-group-${var.env}"
  subnet_ids = ["${aws_subnet.Subnet.id}"]
}

## gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = "${aws_vpc.VPC.id}"
  tags {
    Name = "${var.title}-${var.env}"
  }
}

## routetable
resource "aws_route_table" "RouteTable" {
  vpc_id = "${aws_vpc.VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IGW.id}"
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = "${aws_internet_gateway.IGW.id}"
  }
# VPC Peeringする場合は、生成後、定義を追加しておくとよい。
# ただ、VPC作り直すと、Peering作り直しになるので注意
# Peeringに関しては、承諾処理が必要になるため、Terraformでは無理。
# Peering先からRedisSegmentに対するRoutingは別途設定が必要
# route {
#   cidr_block = "172.31.0.0/16"
#   gateway_id = "pcx-************"
# }
  tags {
    Name = "${var.title}-${var.env}"
  }
}

## routable default association
resource "aws_main_route_table_association" "RouteTableAssoc" {
  vpc_id         = "${aws_vpc.VPC.id}"
  route_table_id = "${aws_route_table.RouteTable.id}"  
}

## security group（Lambda側のVPC設定で必要）
resource "aws_security_group" "Security" {
  name     = "${var.title}-Security-${var.env}"
  vpc_id   = "${aws_vpc.VPC.id}"
  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
#   self = true
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
  tags {
    Name = "${var.title}-${var.env}"
  }
}

##[ ElastiCache 定義 ]##########################################################

# https://qiita.com/Anorlondo448/items/70b26e329828221c829e
# 目安：3:30 ぐらいかかる。ながい。
# Subnetの設定をしないとダメ
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.title}-ec-${var.env}"
  engine               = "redis"
  engine_version       = "5.0.0"
  node_type            = "cache.t2.micro"
  port                 = 6379
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  subnet_group_name = "${aws_elasticache_subnet_group.SubnetGroup.name}"
  tags {
    Name = "${var.title}-${var.env}"
  }
}

################################################################################
