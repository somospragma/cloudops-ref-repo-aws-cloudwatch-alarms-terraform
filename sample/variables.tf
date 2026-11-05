###################################################
# Variables Generales
###################################################

variable "client" {
  description = "Nombre del cliente/unidad de negocio"
  type        = string
}

variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Entorno (dev, qa, staging, pdn, prod, poc)"
  type        = string
}

###################################################
# Variables de Infraestructura
###################################################

variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  description = "Profile AWS para autenticación local"
  type        = string
}

variable "common_tags" {
  description = "Etiquetas comunes aplicadas a nivel de provider (default_tags)"
  type        = map(string)
  default     = {}
}

###################################################
# Variables del Módulo
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
}

variable "sns_topic_name" {
  description = "Nombre del topic SNS para notificaciones (vacío = no inyectar)"
  type        = string
  default     = ""
}
