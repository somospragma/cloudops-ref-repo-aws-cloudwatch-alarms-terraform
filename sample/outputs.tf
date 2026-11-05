output "alarm_arns" {
  description = "ARNs de las alarmas creadas"
  value       = module.cloudwatch_alarms.alarm_arns
}

output "alarm_names" {
  description = "Nombres de las alarmas creadas"
  value       = module.cloudwatch_alarms.alarm_names
}

output "alarm_info" {
  description = "Información completa de las alarmas creadas"
  value       = module.cloudwatch_alarms.alarm_info
}
