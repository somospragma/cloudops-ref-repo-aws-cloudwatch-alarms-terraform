locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  sns_topic_arn = length(var.sns_topic_name) > 0 ? data.aws_sns_topic.notifications[0].arn : ""

  alarm_config_transformed = {
    for key, config in var.alarm_config : key => merge(config, {
      alarm_actions = length(config.alarm_actions) > 0 ? config.alarm_actions : (
        length(local.sns_topic_arn) > 0 ? [local.sns_topic_arn] : []
      )
      ok_actions = length(config.ok_actions) > 0 ? config.ok_actions : (
        length(local.sns_topic_arn) > 0 ? [local.sns_topic_arn] : []
      )
    })
  }
}
