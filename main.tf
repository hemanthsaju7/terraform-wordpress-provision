module "awsvpc" {
  source = "/var/terraform/modules/vpc/"

  project_name = var.project_name
  project_env  = var.project_env
  vpc_cidr     = var.cidr_block
  region       = var.region
}

resource "aws_security_group" "bastion" {
  name_prefix = "bastion-"
  description = "accept ssh traffic"
  vpc_id      = module.awsvpc.vpc

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "${var.project_name}-${var.project_env}-bastion",
    project = var.project_name,
    env     = var.project_env
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "frontend" {
  name_prefix = "frontend-"
  description = "accept http, https and ssh traffic"
  vpc_id      = module.awsvpc.vpc

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "${var.project_name}-${var.project_env}-frontend",
    project = var.project_name,
    env     = var.project_env
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "backend" {
  name_prefix = "backend-"
  description = "accept ssh, sql traffic"
  vpc_id      = module.awsvpc.vpc

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "${var.project_name}-${var.project_env}-backend",
    project = var.project_name,
    env     = var.project_env
  }

  lifecycle {
    create_before_destroy = true
  }
}

#create key pair in the name "key" in the project directory.
resource "aws_key_pair" "mykey" {
    key_name   = "${var.project_name}-${var.project_env}"
    public_key = file("key.pub")
    tags = {
      Name    = "${var.project_name}-${var.project_env}",
      project = var.project_name
      env     = var.project_env
    }
  }


  resource "aws_instance" "bastion" {
    ami                    = var.instance_ami
    instance_type          = var.instance_type
    subnet_id              = module.awsvpc.public2
    key_name               = aws_key_pair.mykey.id
    vpc_security_group_ids = [aws_security_group.bastion.id]
    tags = {
      Name    = "${var.project_name}-${var.project_env}-bastion",
      project = var.project_name,
      env     = var.project_env
    }
  }


  resource "aws_instance" "backend" {
    ami                    = var.instance_ami
    instance_type          = var.instance_type
    subnet_id              = module.awsvpc.private1
    user_data              = file("mysql.sh")
    key_name               = aws_key_pair.mykey.id
    vpc_security_group_ids = [aws_security_group.backend.id]
    tags = {
        Name    = "${var.project_name}-${var.project_env}-backend",
        project = var.project_name,
        env     = var.project_env
      }
      depends_on = [module.awsvpc.ngw, module.awsvpc.rt_private, module.awsvpc.rt_association_private1]
}

  resource "aws_instance" "frontend" {
    ami                    = var.instance_ami
    instance_type          = var.instance_type
    subnet_id              = module.awsvpc.public1
    key_name               = aws_key_pair.mykey.id
    vpc_security_group_ids = [aws_security_group.frontend.id]
    user_data = data.template_file.wp_config.rendered
    tags = {
        Name    = "${var.project_name}-${var.project_env}-frontend",
        project = var.project_name,
        env     = var.project_env
      }
    depends_on = [ aws_instance.backend]
  }


data "template_file" "wp_config" {
  template = "${file("${path.module}/wordpress.tmpl")}"
  vars = {
    privateip = "${aws_instance.backend.private_ip}"
  }
}

resource "aws_route53_record" "record" {
    zone_id = var.hosted_zone
    name    = "example.com"
    type    = "A"
    ttl     = "300"
    records = [aws_instance.frontend.public_ip]
}
