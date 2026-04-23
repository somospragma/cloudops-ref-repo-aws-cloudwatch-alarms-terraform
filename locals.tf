###################################################
# Variables Locales
###################################################

locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  alarm_names = {
    for k, v in var.alarm_config : k => "${local.governance_prefix}-cw-alarm-${k}"
  }
}
