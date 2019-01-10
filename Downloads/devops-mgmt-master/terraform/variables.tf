variable "ProjectName" {}
variable "AWSRegion" {}
variable "EnvType" {}
variable "VPC" {}

variable "VPNPrivateSG" {}
variable "CSRAccessSG" {}
variable "AppAZ" {}
variable "AppSubnet" {}
variable "AppKey" {}

variable "InstanceType" {
  type = "map"

  default = {
    "dev"  = "t2.small"
    "test" = "t2.medium"
    "prod" = "m5.large"
  }
}

variable "ImageID" {
  type = "map"

  default = {
    "us-east-1" = "ami-11cd996e"
    "us-east-2" = ""
    "us-west-1" = ""
    "us-west-2" = ""
  }
}
