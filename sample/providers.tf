provider "aws" {
  alias   = "principal"
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      Client      = var.client
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
