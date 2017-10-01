# -- VPC and Subnets

resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Project = "${var.project_name}"
  }
}

resource "aws_subnet" "ecs_subnet" {

  count = "${length(var.aws_availability_zones)}"

  availability_zone = "${element(var.aws_availability_zones,count.index)}"
  cidr_block = "10.0.${count.index}.0/24"
  vpc_id = "${aws_vpc.ecs_vpc.id}"

  tags = {
    Project = "${var.project_name}"
  }
}

resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = "${aws_vpc.ecs_vpc.id}"

  tags = {
    Project = "${var.project_name}"
  }
}

resource "aws_route_table" "main_route_table" {
  vpc_id = "${aws_vpc.ecs_vpc.id}"

  # all traffic to igw
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vpc_igw.id}"
  }

  tags = {
    Project = "${var.project_name}"
  }
}

resource "aws_route_table_association" "subnet_route_table" {
  count = "${length(var.aws_availability_zones)}"
  subnet_id = "${element(aws_subnet.ecs_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.main_route_table.id}"
}


# -- Security Groups

# Allow internal routing and all outgoing traffic - default SG for all instances and ELB
resource "aws_security_group" "internal_traffic" {
  description = "Allow traffic between instances"

  vpc_id = "${aws_vpc.ecs_vpc.id}"

  ingress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    self = true
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "${var.project_name}"
    Name = "Internal"
  }
}

# Allow incoming SSH traffic, used on all EC2 instances
resource "aws_security_group" "instance_sg" {
  description = "Traffic to ECS instances"

  vpc_id = "${aws_vpc.ecs_vpc.id}"

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "${var.project_name}"
    Name = "IncomingSSH"
  }
}

# Allow incoming web traffic, to be attached to ELBs
resource "aws_security_group" "elb_sg" {
  description = "Web traffic to ECS ELB"

  vpc_id = "${aws_vpc.ecs_vpc.id}"

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "${var.project_name}"
    Name = "IncomingWeb"
  }
}


# -- IAM Roles and policy attachments

# IAM role and policy attachments to give EC2 instances access to ECS
resource "aws_iam_role" "ec2_ecs_role" {
  name = "${replace(var.project_name, "-", "_")}_ec2_ecs_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "attach_ecs_policy_to_ec2_role" {
  name = "attach_ecs_policy_to_ec2_role"
  roles = ["${aws_iam_role.ec2_ecs_role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2_ecs_instance_profile" {
  name = "ec2_ecs_instance_profile"
  role = "${aws_iam_role.ec2_ecs_role.id}"
}

# IAM role and policy for containers to access ELBs
resource "aws_iam_role" "ecs_service_role" {
  name = "${replace(var.project_name, "-", "_")}_ecs_service_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "attach_ecs_service_policy" {
  name = "attach_ecs_service_policy"
  roles = ["${aws_iam_role.ecs_service_role.id}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}


# -- Cloud init template
data "template_file" "ec2_ecs_cloud_config" {
  template = "${file("cloud_config.yml")}"
  vars {
    cluster_name = "${aws_ecs_cluster.ecs_cluster.name}"
  }
}


# -- Launch configuration
resource "aws_launch_configuration" "ec2_ecs_lc" {

  image_id = "${lookup(var.aws_ami_ids, var.aws_region)}"
  instance_type = "t2.micro"

  key_name = "${var.keypair_name}"
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.ec2_ecs_instance_profile.id}"

  security_groups = [
    "${aws_security_group.internal_traffic.id}",
    "${aws_security_group.instance_sg.id}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  user_data = "${data.template_file.ec2_ecs_cloud_config.rendered}"
}

resource "aws_autoscaling_group" "ecs_instance_asg" {
  launch_configuration = "${aws_launch_configuration.ec2_ecs_lc.name}"

  min_size = 2
  max_size = 2
  desired_capacity = 2

  vpc_zone_identifier = ["${aws_subnet.ecs_subnet.*.id}"]

  termination_policies = ["OldestInstance"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "Project"
    value = "${var.project_name}"
    propagate_at_launch = true
  }
}


# -- Cluster Name
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}"
}

# Autoscaling group
