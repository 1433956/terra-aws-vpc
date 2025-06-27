locals {
  common_tags={
    project=var.project
    enviornment=var.enviornment
    terraform="true"

  }
  az-names=slice(data.aws_availability_zones.available.names,0,2)
}
