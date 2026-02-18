# Dislicores IAC Vinua - Terraform Module CloudWatch Alarms

Módulo Terraform para crear alarmas de CloudWatch con nomenclatura estandarizada Dislicores.

## Nomenclatura

Patrón: `{project}-cw-alarm-{key}-{environment}`

Ejemplo: `vin-cw-alarm-ec2-artemis3-high-cpu-pdn`

## Uso

```hcl
module "cloudwatch_alarms" {
  source = "path/to/Dislicores-iac-vinua-terraform-module-cloudwatch-alarms"

  providers = {
    aws.project = aws.project
  }

  project     = "vin"
  environment = "pdn"
  
  alarm_config = {
    high-cpu = {
      alarm_description   = "CPU usage above 80%"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      treat_missing_data  = "notBreaching"
      dimensions = {
        InstanceId = "i-0c4bf96ab0f5c1842"
      }
      alarm_actions = ["arn:aws:sns:us-east-1:123456789012:topic"]
    }
  }
}
```

## Variables

- `project`: Nombre del proyecto (ej: "vin")
- `environment`: Ambiente (dev, qa, lab, pdn)
- `alarm_config`: Mapa de configuraciones de alarmas

## Outputs

- `alarm_arns`: ARNs de las alarmas creadas
- `alarm_names`: Nombres de las alarmas creadas
