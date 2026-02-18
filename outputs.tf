output "alarm_info" {
  description = "Información de las alarmas creadas, incluyendo ARN y nombre"
  value = { for k, alarm in aws_cloudwatch_metric_alarm.alarm : k => { arn = alarm.arn, name = alarm.alarm_name } }
}

output "alarm_arns" {
  description = "Mapa de ARNs de las alarmas creadas, indexados por clave"
  value = { for k, alarm in aws_cloudwatch_metric_alarm.alarm : k => alarm.arn }
}

output "alarm_names" {
  description = "Mapa de nombres de las alarmas creadas, indexados por clave"
  value = { for k, alarm in aws_cloudwatch_metric_alarm.alarm : k => alarm.alarm_name }
}

output "alarm_ids" {
  description = "Mapa de IDs de las alarmas creadas, indexados por clave"
  value = { for k, alarm in aws_cloudwatch_metric_alarm.alarm : k => alarm.id }
}
