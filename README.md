# terraform-wordpress-provision
This is a document for creating infra and deploying Wordpress in it using terraform.  We will be making 1 VPC with 3 Subnets: 2 Private and 1 Public, 1 NAT Gateways, 1 Internet Gateway, and 2 Route Tables.

Here we are creating 3 instances - bastion,frontend and backend. Installing Wordpress on frontend and mariadb on backend instance.
We can only access frondend and backend instances by sshing to bastion server.
