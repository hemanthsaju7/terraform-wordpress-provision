output "vpc" {
  value = aws_vpc.main.id
}

output "public1" {
  value = aws_subnet.public1.id
}

output "public2" {
  value = aws_subnet.public2.id
}

output "private1" {
  value = aws_subnet.private1.id
}

output "ngw" {
    value = aws_nat_gateway.ngw.id
}

output "rt_private" {
    value = aws_route_table.private.id
}

output "rt_association_private1" {
    value = aws_route_table_association.private1
}
