
provider "aws" {
  region = "${var.AWSRegion}"
}

data "aws_availability_zones" "available" {}

#Nexus Instance
resource "aws_instance" "demo-app" {
  availability_zone           = "${data.aws_availability_zones.available.names[0]}"
  instance_type               = "${lookup(var.InstanceType, var.EnvType)}"
  ami                         = "${lookup(var.ImageID, var.AWSRegion)}"
  monitoring                  = true
  key_name                    = "${var.AppKey}"
  vpc_security_group_ids      = ["${var.VPNPrivateSG}", "${var.CSRAccessSG }"]
  subnet_id                   = "${var.AppSubnet}"
  provisioner "local-exec" {
    command = "ssh-keyscan ${aws_instance.demo-app.private_ip} >> /var/lib/jenkins/.ssh/known_hosts"
  }
  tags {
    Name        = "${var.ProjectName}-demo-app"
  }
}

resource "ansible_host" "demo-app" {
    inventory_hostname = "${aws_instance.demo-app.private_ip}"
    groups = ["demo-app"]
    vars {
        foo = "bar"
    }
}

output "demo-app-ip" {
  value = "${aws_instance.demo-app.private_ip}"
}