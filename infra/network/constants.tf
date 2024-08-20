
variable "av_zone_a" {
  type = map

  default = {
    us-east-1      = "us-east-1a"
  }
}

variable "av_zone_b" {
  type = map

  default = {
    us-east-1      = "us-east-1b"
  }
}
