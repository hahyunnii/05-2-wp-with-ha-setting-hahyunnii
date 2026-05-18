# Student Templates for 2-Wordpress web service with HA (high availability) configuration

This folder contains student-facing Terraform templates based on the three toy examples.

## Purpose

- Two EC2 instances with ALB (HA) configuration
- Each server runs WordPress sites (with S3 bucket media offloading)
- Using the terraform for initializing the platform
- Using the user-data script for initializing the EC2 instances with WordPress server

## The following directories are just examples; you can refer the code, but you will need to fix them

1. `terraform-01-ec2-webserver`
   - Students complete the single-instance baseline

2. `terraform-02-ec2-two-subnets`
   - Students extend the baseline with multi-subnet placement and `for_each`

3. `terraform-03-alb-two-ec2`
   - Students extend the second example with ALB resources

## Important Note

- You need to check your configuration; script examples are not perfect.
- Write commands.md and report.md for submission
- Make finished.txt for notifying me of the finish

