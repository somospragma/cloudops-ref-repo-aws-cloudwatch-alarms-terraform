###################################################
# Variables Locales
###################################################

locals {
  # Generar nombres de recursos siguiendo la convención de nomenclatura estándar
  alarm_names = {
    for k, v in var.alarm_config : k => "${var.project}-cw-alarm-${k}-${var.environment}"
  }
}
