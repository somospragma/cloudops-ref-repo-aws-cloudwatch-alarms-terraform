data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_sns_topic" "notifications" {
  count    = length(var.sns_topic_name) > 0 ? 1 : 0
  provider = aws.principal
  name     = var.sns_topic_name
}
