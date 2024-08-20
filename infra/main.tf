variable "region" { default = "us-east-1" }
variable "emr_release_label" {}
variable "emr_main_instance_type" {}
variable "emr_core_instance_type" {}
variable "emr_core_instance_count" {}
variable "project" {}
variable "owner" {}
variable "environment" {}
variable "account" {}
variable "name_bucket" {}
variable "versioning_bucket" {}
variable "files_bucket" {}
variable "files_data" {}
variable "files_bash" {}

locals {
  tags = {
    "owner"   = var.owner
    "project" = var.project
    "stage"   = var.environment
  }
}

provider "aws" {
  region  = var.region
}

terraform {
  backend "s3" {
    bucket = "terraform-states-327498361889"
    key    = "narwhal/terraform.tfstate"
    region = "us-east-1"
    #    dynamodb_table = "terraform-lock-table"
    #    encrypt        = true
  }
}

module "s3" {
  source            = "./s3"
  name_bucket       = var.name_bucket
  versioning_bucket = var.versioning_bucket
  files_bucket      = var.files_bucket
  files_data        = var.files_data
  files_bash        = var.files_bash
}

module "ssh" {
  source      = "./ssh"
  project     = var.project
  environment = var.environment
}

module "network" {
  source = "./network"
  region = var.region
  tags   = local.tags
}

locals {
  configurations_json = jsonencode([
    {
      "Classification" : "flink-conf",
      "Properties" : {
        "parallelism.default" : "2",
        "taskmanager.numberOfTaskSlots" : "2",
        "taskmanager.memory.process.size" : "2G",
        "jobmanager.memory.process.size" : "1G",
        "execution.checkpointing.interval" : "180000",
        "execution.checkpointing.mode" : "EXACTLY_ONCE"
      }
    }
  ])
}

module "emr" {
  source                       = "./emr"
  project                      = var.project
  environment                  = var.environment
  tags                         = local.tags
  release_label                = var.emr_release_label
  applications                 = ["Hadoop", "Flink", "Zeppelin"]
  main_instance_type           = var.emr_main_instance_type
  core_instance_type           = var.emr_core_instance_type
  core_instance_count          = var.emr_core_instance_count
  configurations               = local.configurations_json
  key_name                     = module.ssh.deployer_key_name
  vpc_id                       = module.network.vpc_id
  public_subnet                = module.network.public_subnet_2
  additional_security_group_id = module.network.integration_service_security_group_id
}

output "emr_main_address" {
  value = module.emr.emr_main_address
}
