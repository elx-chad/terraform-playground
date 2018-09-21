provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

terraform {
  backend "s3" {
    bucket         = "arkyco-terraform-remote-state-storage"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "arkyco-terraform-state-lock-dynamo"
    encrypt        = true
  }
}

resource "aws_security_group" "ssh-only-from-anywhere" {
  name = "ssh-only-from-anywhere"
  description = "Allow only ssh comms from anywhere"
  vpc_id = "${var.vpc_id}"

  # Allow SSH from Anywhere
  ingress {
    from_port = 0
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Allow SSH from anywhere"
  }
}

resource "aws_security_group" "internet-access" {
  name = "internet-access"
  description = "Allow instances to access internet"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "playground-instance" {
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = true
  subnet_id                   = "${var.subnet_id}"
  vpc_security_group_ids      = ["${aws_security_group.ssh-only-from-anywhere.id}",
                                "${aws_security_group.internet-access.id}"]

  tags {
    Name = "playground-instance",
    Purpose = "Terraform testing"
  }

  provisioner "file" {
    source = "../chef-repo/"
    destination = "/tmp/chef-repo"

    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = "${file("/Users/cmiller-elyxor/.ssh/arkyco-alpha.pem")}"
    }
  }

  provisioner "file" {
    source = "first-boot.json"
    destination = "/tmp/first-boot.json"

    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = "${file("/Users/cmiller-elyxor/.ssh/arkyco-alpha.pem")}"
    }
  }

  provisioner "remote-exec" {
      inline = [
        "curl -L https://omnitruck.chef.io/install.sh | sudo bash",
        "sudo chef-client --local-mode -j /tmp/first-boot.json --config-option chef_repo_path=/tmp/chef-repo"
      ]

      connection {
        type = "ssh"
        user = "ec2-user"
        private_key = "${file("/Users/cmiller-elyxor/.ssh/arkyco-alpha.pem")}"
      }
  }
}
