locals {
  common_variables = {
    region = "ap-southeast-1"
    profile = "default"
  }

  common_tags = {
    Environment = "dev"
    Project = "terraform-project"
    Owner = "kentaindeed"
    CreatedBy = "terraform"
    CreatedAt = "2025-01-01"
  }

  availability_zones = [
    "ap-northeast-1a", 
    "ap-northeast-1d", 
    "ap-northeast-1c"
]

}