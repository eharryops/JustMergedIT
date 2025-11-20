output "vpc_id" {
  value = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.main[0].id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}
