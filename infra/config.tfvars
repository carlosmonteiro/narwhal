project = "narwhal"
region = "us-east-1"
account = "327498361889"

owner = "Carlos Monteiro"

environment = "EMR"
emr_release_label = "emr-7.0.0"
emr_main_instance_type = "m5.xlarge"
emr_core_instance_type = "m5.xlarge"
emr_core_instance_count = "2"

name_bucket       = "narwhal-327498361889"
versioning_bucket = "Enabled"
files_bucket      = "./pipeline"
files_data        = "./dados"
files_bash        = "./scripts"