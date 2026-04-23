# Ejemplo de Uso del Módulo CloudWatch Alarms

## Ejecución

```bash
cd sample/
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Flujo de Datos (PC-IAC-026)

```
terraform.tfvars → variables.tf → data.tf → locals.tf → main.tf → ../
```

## Notas

- Los `alarm_actions` vacíos en `terraform.tfvars` se llenan automáticamente con el SNS topic obtenido desde data source.
- Ajustar `sns_topic_name` en `terraform.tfvars` para apuntar al topic SNS de notificaciones.
