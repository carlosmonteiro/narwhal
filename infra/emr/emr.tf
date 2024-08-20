
variable "project" { }
variable "environment" { }
variable "tags" { }
variable "key_name" { }
variable "vpc_id" { }
variable "public_subnet" { }
variable "additional_security_group_id" { }
variable "release_label" { }
variable "applications" { }
variable "main_instance_type" { }
variable "core_instance_type" { }
variable "core_instance_count" { }

variable "core_instance_ebs_volume_size" { default = "80" }
variable "security_configuration_name" { default = null }
variable "log_uri" { default = "s3://narwhal-327498361889" }

variable "configurations" { default = null }

variable "steps" {
  type = list(object(
    {
      name = string
      action_on_failure = string
      hadoop_jar_step = list(object(
        {
          args       = list(string)
          jar        = string
          main_class = string
          properties = map(string)
        }
      ))
    }
  ))
  default = null
}

variable "bootstrap_action" {
  type = set(object(
    {
      name = string
      path = string
      args = list(string)
    }
  ))
  default = []
}

variable "kerberos_attributes" {
  type = set(object(
    {
      kdc_admin_password = string
      realm              = string
    }
  ))
  default = []
}

resource "aws_emr_cluster" "emr_cluster" {
  name                   = "${var.project}-cluster-${var.environment}"
  release_label          = var.release_label
  applications           = var.applications
  security_configuration = var.security_configuration_name
  service_role           = aws_iam_role.emr_service_role.arn
  log_uri                = var.log_uri
  configurations         = var.configurations
  step                   = var.steps
  tags                   = var.tags

  master_instance_group {
    instance_type  = var.main_instance_type
    instance_count = "1"
  }

  core_instance_group {
    instance_type = var.core_instance_type
    instance_count = var.core_instance_count
    ebs_config {
      size = var.core_instance_ebs_volume_size
      type = "gp2"
      volumes_per_instance = 1
    }
  }

  ec2_attributes {
    key_name = var.key_name
    subnet_id = var.public_subnet
    instance_profile = aws_iam_instance_profile.emr_ec2_instance_profile.arn
    emr_managed_master_security_group = aws_security_group.main_security_group.id
    emr_managed_slave_security_group = aws_security_group.core_security_group.id
    additional_master_security_groups = var.additional_security_group_id
    additional_slave_security_groups = var.additional_security_group_id
  }

  dynamic "bootstrap_action" {
    for_each = var.bootstrap_action
    content {
      name = bootstrap_action.value["name"]
      path = bootstrap_action.value["path"]
      args = bootstrap_action.value["args"]
    }
  }

  dynamic "kerberos_attributes" {
    for_each = var.kerberos_attributes
    content {
      realm              = kerberos_attributes.value["realm"]
      kdc_admin_password = kerberos_attributes.value["kdc_admin_password"]
    }
  }

  lifecycle {
    ignore_changes = [
      step
    ]
  }

}

output "emr_main_address" {
  value = aws_emr_cluster.emr_cluster.master_public_dns
}
