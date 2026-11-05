module "cloudwatch_alarms" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client      = var.client
  project     = var.project
  environment = var.environment

  alarm_config = local.alarm_config_transformed
}
