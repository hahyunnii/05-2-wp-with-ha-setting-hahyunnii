output "instance_id" {
  description = "EC2 instance identifier"
  value       = aws_instance.wordpress.id
}

output "wordpress_url" {
  description = "Public URL to access WordPress (open in browser after health checks pass)"
  value       = "http://${aws_instance.wordpress.public_ip}"
}

output "health_check_url" {
  description = "URL to confirm EC2 bootstrap succeeded (Apache + health file written)"
  value       = "http://${aws_instance.wordpress.public_ip}/health.html"
}

output "db_check_url" {
  description = "URL to confirm PHP-to-RDS connectivity from EC2"
  value       = "http://${aws_instance.wordpress.public_ip}/db-health.php"
}

output "rds_endpoint" {
  description = "Private RDS hostname:port — only reachable from within the VPC"
  value       = "${aws_db_instance.wordpress.address}:${aws_db_instance.wordpress.port}"
}

output "rds_instance_id" {
  description = "RDS resource identifier"
  value       = aws_db_instance.wordpress.identifier
}

output "db_name" {
  description = "WordPress database name on RDS"
  value       = aws_db_instance.wordpress.db_name
}

output "selected_subnet_ids" {
  description = "Subnet IDs used by the DB subnet group"
  value       = local.subnet_ids
}

output "security_group_ids" {
  description = "Map of EC2 SG and RDS SG IDs for security boundary verification"
  value = {
    wordpress_ec2 = aws_security_group.wordpress.id
    rds           = aws_security_group.rds.id
  }
}
