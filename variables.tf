###################################################
# Variables Generales
###################################################

variable "client" {
  description = "Nombre del cliente/unidad de negocio (ej: dtl). Máx 10 caracteres (PC-IAC-003)."
  type        = string

  validation {
    condition     = length(var.client) > 0 && length(var.client) <= 10 && can(regex("^[a-z0-9-]+$", var.client))
    error_message = "El nombre del cliente no puede estar vacío, debe tener máximo 10 caracteres y contener solo minúsculas, números y guiones."
  }
}

variable "project" {
  description = "Nombre del proyecto. Máx 15 caracteres (PC-IAC-003)."
  type        = string

  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 15 && can(regex("^[a-z0-9-]+$", var.project))
    error_message = "El nombre del proyecto no puede estar vacío, debe tener máximo 15 caracteres y contener solo minúsculas, números y guiones."
  }
}

variable "environment" {
  description = "Entorno de despliegue (dev, qa, staging, pdn, prod, poc)"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "staging", "pdn", "prod", "poc"], var.environment)
    error_message = "El entorno debe ser uno de: dev, qa, staging, pdn, prod, poc."
  }
}

###################################################
# Variables de Configuración de Alarmas
###################################################
variable "alarm_config" {
  description = "Configuración de alarmas de CloudWatch"
  type = map(object({
    alarm_description         = string
    comparison_operator       = string
    evaluation_periods        = number
    threshold                 = optional(number)
    metric_name               = optional(string)
    namespace                 = optional(string)
    period                    = optional(number)
    statistic                 = optional(string)
    datapoints_to_alarm       = optional(number)
    treat_missing_data        = optional(string, "missing")
    actions_enabled           = optional(bool, true)
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    dimensions                = optional(map(string), {})
    additional_tags           = optional(map(string), {})
    metric_queries = optional(list(object({
      id          = string
      expression  = optional(string)
      label       = optional(string)
      return_data = optional(bool)
      metric = optional(object({
        metric_name = string
        namespace   = string
        period      = number
        stat        = string
        dimensions  = optional(map(string), {})
      }))
    })), [])
  }))

  validation {
    condition = alltrue([
      for alarm_key, alarm in var.alarm_config :
      contains(["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold"], alarm.comparison_operator)
    ])
    error_message = "comparison_operator debe ser uno de: GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold."
  }

  validation {
    condition = alltrue([
      for alarm_key, alarm in var.alarm_config :
      alarm.treat_missing_data == null || contains(["missing", "ignore", "breaching", "notBreaching"], alarm.treat_missing_data)
    ])
    error_message = "treat_missing_data debe ser uno de: missing, ignore, breaching, notBreaching."
  }
}
