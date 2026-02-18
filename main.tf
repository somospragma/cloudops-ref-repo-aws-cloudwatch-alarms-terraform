###########################################
####### CloudWatch Alarm Resources ########
###########################################

resource "aws_cloudwatch_metric_alarm" "alarm" {
  provider = aws.project
  for_each = var.alarm_config

  alarm_name          = local.alarm_names[each.key]
  alarm_description   = each.value.alarm_description
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  
  # Parámetros opcionales para alarmas simples
  threshold      = each.value.threshold
  metric_name    = each.value.metric_name
  namespace      = each.value.namespace
  period         = each.value.period
  statistic      = each.value.statistic
  
  # Configuración adicional
  datapoints_to_alarm = each.value.datapoints_to_alarm
  treat_missing_data  = each.value.treat_missing_data
  actions_enabled     = each.value.actions_enabled
  
  # Acciones
  alarm_actions             = each.value.alarm_actions
  ok_actions                = each.value.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions
  
  # Dimensiones
  dimensions = each.value.dimensions

  # Metric queries para alarmas complejas
  dynamic "metric_query" {
    for_each = each.value.metric_queries
    content {
      id          = metric_query.value.id
      expression  = metric_query.value.expression
      label       = metric_query.value.label
      return_data = metric_query.value.return_data

      dynamic "metric" {
        for_each = metric_query.value.metric != null ? [metric_query.value.metric] : []
        content {
          metric_name = metric.value.metric_name
          namespace   = metric.value.namespace
          period      = metric.value.period
          stat        = metric.value.stat
          dimensions  = metric.value.dimensions
        }
      }
    }
  }

  tags = merge(
    {
      Name = local.alarm_names[each.key]
    },
    each.value.additional_tags
  )
}
