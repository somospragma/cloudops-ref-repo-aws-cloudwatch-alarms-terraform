# Terraform Module — CloudWatch Alarms

Módulo reutilizable de Terraform que crea **alarmas de Amazon CloudWatch** de forma dinámica mediante un mapa de configuración. Soporta tanto alarmas simples (una métrica + threshold) como alarmas complejas basadas en `metric_queries` (expresiones matemáticas sobre múltiples métricas).

## Recursos creados

| Recurso | Descripción |
|---------|-------------|
| `aws_cloudwatch_metric_alarm` | Alarmas de CloudWatch (dinámico con `for_each` sobre `alarm_config`) |

## Convención de nombramiento

```
{client}-{project}-{environment}-cw-alarm-{key}
```

Donde `{key}` es la clave del mapa `alarm_config` (ej: `ec2-web-high-cpu`).

Ejemplo resultante: `dtl-vin-dev-cw-alarm-ec2-web-high-cpu`

## Requisitos

| Requisito | Versión |
|-----------|---------|
| Terraform | `>= 1.0` |
| AWS Provider | `>= 5.0` |

El módulo requiere un **provider alias** `aws.project`:

```hcl
providers = {
  aws.project = aws.principal
}
```

## Variables

### Gobernanza (obligatorias)

| Variable | Tipo | Descripción | Validación |
|----------|------|-------------|------------|
| `client` | `string` | Nombre del cliente/unidad de negocio | Solo minúsculas, números y guiones |
| `project` | `string` | Nombre del proyecto | Solo minúsculas, números y guiones |
| `environment` | `string` | Entorno de despliegue | `dev`, `qa`, `pdn` |

### Configuración de alarmas (obligatoria)

| Variable | Tipo | Descripción |
|----------|------|-------------|
| `alarm_config` | `map(object({...}))` | Mapa de alarmas a crear. Cada clave se convierte en el sufijo del nombre de la alarma |

Cada entrada del mapa `alarm_config` acepta:

| Atributo | Tipo | Default | Requerido | Descripción |
|----------|------|---------|-----------|-------------|
| `alarm_description` | `string` | — | **Sí** | Descripción de la alarma |
| `comparison_operator` | `string` | — | **Sí** | Operador de comparación (ver valores válidos abajo) |
| `evaluation_periods` | `number` | — | **Sí** | Períodos de evaluación |
| `threshold` | `number` | `null` | No | Umbral para alarmas simples (no usar con `metric_queries`) |
| `metric_name` | `string` | `null` | No | Nombre de la métrica (para alarmas simples) |
| `namespace` | `string` | `null` | No | Namespace de la métrica (ej: `AWS/EC2`, `CWAgent`) |
| `period` | `number` | `null` | No | Período en segundos |
| `statistic` | `string` | `null` | No | Estadística (`Average`, `Sum`, `Maximum`, `Minimum`, `SampleCount`) |
| `datapoints_to_alarm` | `number` | `null` | No | Datapoints necesarios para activar la alarma |
| `treat_missing_data` | `string` | `"missing"` | No | Tratamiento de datos faltantes |
| `actions_enabled` | `bool` | `true` | No | Habilitar acciones de la alarma |
| `alarm_actions` | `list(string)` | `[]` | No | ARNs de acciones al entrar en ALARM |
| `ok_actions` | `list(string)` | `[]` | No | ARNs de acciones al volver a OK |
| `insufficient_data_actions` | `list(string)` | `[]` | No | ARNs de acciones con datos insuficientes |
| `dimensions` | `map(string)` | `{}` | No | Dimensiones para filtrar la métrica **(ver sección de identificación de recursos)** |
| `additional_tags` | `map(string)` | `{}` | No | Tags adicionales para la alarma |
| `metric_queries` | `list(object({...}))` | `[]` | No | Queries de métricas para alarmas complejas (ver sección dedicada) |

#### Valores válidos de `comparison_operator`

- `GreaterThanOrEqualToThreshold`
- `GreaterThanThreshold`
- `LessThanThreshold`
- `LessThanOrEqualToThreshold`

#### Valores válidos de `treat_missing_data`

- `missing` — Tratar como datos faltantes (default)
- `ignore` — Mantener el estado actual de la alarma
- `breaching` — Tratar como si se superara el umbral
- `notBreaching` — Tratar como si NO se superara el umbral

---

## ¿Cómo identificar el recurso a monitorear?

Este es el punto más importante del módulo. CloudWatch usa **dimensiones** (`dimensions`) para identificar la serie temporal de una métrica. Las dimensiones son pares clave-valor, pero **no siempre es un ID críptico** — en la mayoría de servicios AWS es simplemente el **nombre del recurso**.

### Las 3 formas de identificar recursos

| Forma | ¿Necesita ID? | ¿Cuándo usarla? | Campo del módulo |
|-------|---------------|------------------|------------------|
| **Por nombre del recurso** | ❌ No | La mayoría de servicios (RDS, Lambda, SQS, DynamoDB, etc.) | `dimensions` |
| **Por ID del recurso** | ✅ Sí | Solo EC2 (`InstanceId`) y algunos casos de ALB/CloudFront | `dimensions` |
| **Por Tag** | ❌ No | Cuando quieres monitorear grupos de recursos dinámicamente | `metric_queries` con SEARCH o data sources de Terraform |

---

### Forma 1: Por nombre del recurso (la más común — NO necesita ID)

La mayoría de servicios AWS usan el **nombre que tú le pusiste al recurso** como dimensión. No necesitas buscar ningún ID:

```hcl
# Lambda — solo necesitas el nombre de la función
dimensions = { FunctionName = "mi-funcion-lambda" }

# RDS — solo necesitas el nombre de la base de datos
dimensions = { DBInstanceIdentifier = "mi-base-de-datos-prod" }

# SQS — solo necesitas el nombre de la cola
dimensions = { QueueName = "mi-cola-sqs" }

# DynamoDB — solo necesitas el nombre de la tabla
dimensions = { TableName = "mi-tabla-dynamo" }

# API Gateway REST — solo necesitas el nombre del API
dimensions = { ApiName = "mi-api-rest" }

# ECS — necesitas nombre del cluster + nombre del servicio
dimensions = {
  ClusterName = "mi-cluster"
  ServiceName = "mi-servicio"
}

# S3 — nombre del bucket + tipo de storage
dimensions = {
  BucketName  = "mi-bucket"
  StorageType = "StandardStorage"
}

# ElastiCache — nombre del cluster
dimensions = { CacheClusterId = "mi-cluster-redis" }

# SNS — nombre del topic
dimensions = { TopicName = "mi-topic" }
```

Ejemplo completo con Lambda:

```hcl
alarm_config = {
  "lambda-api-high-errors" = {
    alarm_description   = "Errores > 10 en Lambda mi-funcion-api"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    threshold           = 10
    metric_name         = "Errors"
    namespace           = "AWS/Lambda"
    period              = 300
    statistic           = "Sum"
    dimensions = {
      FunctionName = "mi-funcion-api"  # <-- Solo el nombre, NO un ID
    }
  }
}
```

---

### Forma 2: Por ID del recurso (solo algunos servicios lo requieren)

Algunos servicios **sí requieren un ID** porque no tienen un nombre legible como dimensión:

```hcl
# EC2 — requiere InstanceId (i-xxxx)
dimensions = { InstanceId = "i-0123456789abcdef0" }

# ALB — requiere el ARN suffix del load balancer
dimensions = { LoadBalancer = "app/mi-alb/1234567890abcdef" }

# NLB — requiere el ARN suffix del load balancer
dimensions = { LoadBalancer = "net/mi-nlb/1234567890abcdef" }

# CloudFront — requiere DistributionId
dimensions = { DistributionId = "E1234567890" }
```

Ejemplo completo con EC2:

```hcl
alarm_config = {
  "ec2-web01-high-cpu" = {
    alarm_description   = "CPU > 85% en instancia web-01"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    threshold           = 85
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 300
    statistic           = "Average"
    dimensions = {
      InstanceId = "i-0123456789abcdef0"  # <-- Aquí sí necesitas el ID
    }
  }
}
```

> **Tip:** Si el ID viene de otro recurso Terraform, puedes referenciarlo directamente: `InstanceId = aws_instance.web.id` o pasarlo como variable.

#### Métricas de CWAgent (CloudWatch Agent)

Cuando se usa el CloudWatch Agent, el namespace es `CWAgent` y las dimensiones dependen de la configuración del agente. Aquí sí se necesita el `InstanceId` más dimensiones adicionales:

```hcl
# CPU con CWAgent (Windows)
dimensions = {
  InstanceId = "i-0123456789abcdef0"
  objectname = "Processor"
  instance   = "_Total"
}

# Memoria con CWAgent (Windows)
dimensions = {
  InstanceId = "i-0123456789abcdef0"
  objectname = "Memory"
}

# Disco con CWAgent (Linux)
dimensions = {
  InstanceId = "i-0123456789abcdef0"
  path       = "/"
  device     = "xvda1"
  fstype     = "ext4"
}
```

---

### Forma 3: Por Tag (monitorear grupos de recursos dinámicamente)

CloudWatch Metric Alarms **no soporta filtrar por tag directamente en `dimensions`**, pero el módulo lo soporta de dos maneras:

#### Opción A: Data source de Terraform (resuelve IDs por tag en tiempo de plan)

Terraform busca los recursos por tag, obtiene sus IDs y genera una alarma por cada uno automáticamente. Esto va en el código que **consume** el módulo (no dentro del módulo):

```hcl
# 1. Buscar instancias por tag
data "aws_instances" "web_servers" {
  filter {
    name   = "tag:Role"
    values = ["web"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# 2. Generar una alarma por cada instancia encontrada
locals {
  web_cpu_alarms = {
    for idx, id in data.aws_instances.web_servers.ids :
    "ec2-web-${idx}-high-cpu" => {
      alarm_description   = "CPU > 85% en instancia web ${id}"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      threshold           = 85
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      dimensions          = { InstanceId = id }
      # ... resto de campos opcionales con defaults
    }
  }
}

# 3. Pasar al módulo
module "cloudwatch_alarms" {
  source       = "git::https://<repo-url>.git?ref=v1.0.0"
  # ...
  alarm_config = local.web_cpu_alarms
}
```

> **Ventaja:** Genera alarmas individuales por recurso, cada una con su propio estado (ALARM/OK).
> **Consideración:** Si se agregan/eliminan instancias, hay que hacer `terraform apply` para actualizar las alarmas.

Esto funciona con cualquier data source de AWS, no solo EC2:

```hcl
# RDS por tag
data "aws_db_instances" "prod" {
  filter {
    name   = "tag:Environment"
    values = ["production"]
  }
}

# Lambda por tag (usando aws_lambda_functions)
data "aws_lambda_functions" "api" {}
# Luego filtrar en locals por el tag que necesites
```

#### Opción B: SEARCH expression en metric_queries (resuelve por tag en tiempo real)

Usa una expresión `SEARCH` que busca métricas por tag directamente en CloudWatch, sin necesidad de conocer IDs:

```hcl
alarm_config = {
  "all-web-high-cpu" = {
    alarm_description   = "CPU > 85% en cualquier instancia con tag Role=web"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    threshold           = 85
    metric_queries = [
      {
        id          = "e1"
        expression  = "SEARCH('{AWS/EC2,InstanceId} Role=web CPUUtilization', 'Average', 300)"
        label       = "CPU por instancia web"
        return_data = false
      },
      {
        id          = "e2"
        expression  = "MAX(METRICS())"
        label       = "Max CPU en instancias web"
        return_data = true
      }
    ]
  }
}
```

> **Ventaja:** Detecta automáticamente nuevos recursos con el tag sin necesidad de re-apply.
> **Consideración:** La alarma es una sola para todo el grupo (no individual por recurso). Se activa si **cualquiera** de los recursos supera el umbral.
> **Importante:** Cuando se usan `metric_queries`, los campos `metric_name`, `namespace`, `period`, `statistic` y `dimensions` deben dejarse en `null` / vacíos.

#### ¿Cuál opción elegir?

| Criterio | Opción A (Data source) | Opción B (SEARCH) |
|----------|------------------------|--------------------|
| Alarma individual por recurso | ✅ Sí | ❌ No (una alarma para el grupo) |
| Detecta nuevos recursos automáticamente | ❌ Requiere re-apply | ✅ Sí, en tiempo real |
| Necesita conocer IDs | ❌ Los resuelve Terraform | ❌ No |
| Complejidad | Media | Baja |

---

## Alarmas complejas con `metric_queries`

Para alarmas basadas en expresiones matemáticas o múltiples métricas, se usa el atributo `metric_queries` en vez de los campos simples.

Cada elemento de `metric_queries` acepta:

| Atributo | Tipo | Descripción |
|----------|------|-------------|
| `id` | `string` | Identificador único de la query (ej: `m1`, `e1`) |
| `expression` | `string` | Expresión matemática (ej: `m1 / m2 * 100`) |
| `label` | `string` | Etiqueta para la query |
| `return_data` | `bool` | Si `true`, esta query es la que se evalúa contra el threshold |
| `metric` | `object` | Definición de la métrica (si no es una expresión) |

El objeto `metric` dentro de cada query acepta:

| Atributo | Tipo | Descripción |
|----------|------|-------------|
| `metric_name` | `string` | Nombre de la métrica |
| `namespace` | `string` | Namespace de la métrica |
| `period` | `number` | Período en segundos |
| `stat` | `string` | Estadística (`Average`, `Sum`, etc.) |
| `dimensions` | `map(string)` | Dimensiones para filtrar la métrica |

### Ejemplo: Alarma de porcentaje de errores 5xx en ALB

```hcl
alarm_config = {
  "alb-high-5xx-rate" = {
    alarm_description   = "Tasa de errores 5xx > 5% en ALB"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 5
    metric_queries = [
      {
        id          = "m1"
        return_data = false
        metric = {
          metric_name = "HTTPCode_ELB_5XX_Count"
          namespace   = "AWS/ApplicationELB"
          period      = 300
          stat        = "Sum"
          dimensions = {
            LoadBalancer = "app/mi-alb/1234567890abcdef"
          }
        }
      },
      {
        id          = "m2"
        return_data = false
        metric = {
          metric_name = "RequestCount"
          namespace   = "AWS/ApplicationELB"
          period      = 300
          stat        = "Sum"
          dimensions = {
            LoadBalancer = "app/mi-alb/1234567890abcdef"
          }
        }
      },
      {
        id          = "e1"
        expression  = "IF(m2 > 0, m1 / m2 * 100, 0)"
        label       = "5xx Error Rate %"
        return_data = true
      }
    ]
  }
}
```

---

## Integración con SNS (notificaciones)

El módulo acepta ARNs de SNS topics directamente en `alarm_actions` y `ok_actions`. El directorio `sample/` muestra un patrón recomendado donde se inyecta el ARN del SNS topic desde un data source:

```hcl
# En el consumidor del módulo:
data "aws_sns_topic" "notifications" {
  name = "mi-topic-monitoring"
}

# En locals.tf del consumidor:
locals {
  alarm_config_transformed = {
    for key, config in var.alarm_config : key => merge(config, {
      alarm_actions = length(config.alarm_actions) > 0 ? config.alarm_actions : [data.aws_sns_topic.notifications.arn]
      ok_actions    = length(config.ok_actions) > 0 ? config.ok_actions : [data.aws_sns_topic.notifications.arn]
    })
  }
}
```

---

## Outputs

| Output | Tipo | Descripción |
|--------|------|-------------|
| `alarm_info` | `map(object)` | Mapa con `arn` y `name` de cada alarma, indexado por clave |
| `alarm_arns` | `map(string)` | Mapa de ARNs de las alarmas, indexado por clave |
| `alarm_names` | `map(string)` | Mapa de nombres de las alarmas, indexado por clave |
| `alarm_ids` | `map(string)` | Mapa de IDs de las alarmas, indexado por clave |

---

## Ejemplo completo de uso

```hcl
module "cloudwatch_alarms" {
  source = "git::https://<repo-url>.git?ref=v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  client      = "dtl"
  project     = "vin"
  environment = "dev"

  alarm_config = {
    # Alarma simple — EC2 CPU por Instance ID
    "ec2-web01-high-cpu" = {
      alarm_description   = "CPU > 85% en web-01"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      threshold           = 85
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      datapoints_to_alarm = 2
      treat_missing_data  = "notBreaching"
      alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:mi-topic"]
      ok_actions          = ["arn:aws:sns:us-east-1:123456789012:mi-topic"]
      dimensions = {
        InstanceId = "i-0123456789abcdef0"
      }
      additional_tags = {
        Criticality = "High"
        Server      = "web-01"
      }
    }

    # Alarma simple — RDS conexiones
    "rds-prod-high-connections" = {
      alarm_description   = "Conexiones > 100 en RDS prod"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      threshold           = 100
      metric_name         = "DatabaseConnections"
      namespace           = "AWS/RDS"
      period              = 60
      statistic           = "Average"
      alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:mi-topic"]
      dimensions = {
        DBInstanceIdentifier = "mi-db-prod"
      }
    }

    # Alarma compleja — Tasa de errores Lambda
    "lambda-api-error-rate" = {
      alarm_description   = "Tasa de errores > 10% en Lambda API"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 3
      threshold           = 10
      alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:mi-topic"]
      metric_queries = [
        {
          id          = "errors"
          return_data = false
          metric = {
            metric_name = "Errors"
            namespace   = "AWS/Lambda"
            period      = 300
            stat        = "Sum"
            dimensions  = { FunctionName = "mi-funcion-api" }
          }
        },
        {
          id          = "invocations"
          return_data = false
          metric = {
            metric_name = "Invocations"
            namespace   = "AWS/Lambda"
            period      = 300
            stat        = "Sum"
            dimensions  = { FunctionName = "mi-funcion-api" }
          }
        },
        {
          id          = "error_rate"
          expression  = "IF(invocations > 0, errors / invocations * 100, 0)"
          label       = "Error Rate %"
          return_data = true
        }
      ]
    }
  }
}
```

---

## Referencia rápida de dimensiones por servicio

| Servicio | Namespace | Dimensión principal | Ejemplo | ¿Necesita ID? |
|----------|-----------|---------------------|---------|---------------|
| EC2 | `AWS/EC2` | `InstanceId` | `i-0123456789abcdef0` | ✅ Sí |
| RDS | `AWS/RDS` | `DBInstanceIdentifier` | `mi-db-prod` | ❌ No, usa nombre |
| Lambda | `AWS/Lambda` | `FunctionName` | `mi-funcion` | ❌ No, usa nombre |
| SQS | `AWS/SQS` | `QueueName` | `mi-cola` | ❌ No, usa nombre |
| DynamoDB | `AWS/DynamoDB` | `TableName` | `mi-tabla` | ❌ No, usa nombre |
| API Gateway | `AWS/ApiGateway` | `ApiName` | `mi-api` | ❌ No, usa nombre |
| ECS | `AWS/ECS` | `ClusterName` + `ServiceName` | `mi-cluster` / `mi-svc` | ❌ No, usa nombres |
| S3 | `AWS/S3` | `BucketName` + `StorageType` | `mi-bucket` / `StandardStorage` | ❌ No, usa nombre |
| ElastiCache | `AWS/ElastiCache` | `CacheClusterId` | `mi-redis` | ❌ No, usa nombre |
| SNS | `AWS/SNS` | `TopicName` | `mi-topic` | ❌ No, usa nombre |
| ALB | `AWS/ApplicationELB` | `LoadBalancer` | `app/mi-alb/abc123` | ⚠️ ARN suffix |
| NLB | `AWS/NetworkELB` | `LoadBalancer` | `net/mi-nlb/abc123` | ⚠️ ARN suffix |
| CloudFront | `AWS/CloudFront` | `DistributionId` | `E1234567890` | ✅ Sí |
| CWAgent | `CWAgent` | `InstanceId` + (varía) | `i-abc` + `objectname`, `instance` | ✅ Sí |

---

## Estructura del módulo

```
.
├── main.tf          # Recurso aws_cloudwatch_metric_alarm con for_each y metric_queries dinámicas
├── variables.tf     # Variables de entrada (gobernanza + alarm_config)
├── outputs.tf       # Outputs (ARNs, nombres, IDs, info)
├── locals.tf        # Variables locales (nomenclatura)
├── data.tf          # Data sources
├── versions.tf      # Versiones requeridas de Terraform y providers
├── providers.tf     # Configuración de providers
├── CHANGELOG.md     # Historial de cambios
└── sample/          # Ejemplo funcional
    ├── main.tf            # Invocación del módulo
    ├── variables.tf       # Variables del ejemplo
    ├── locals.tf          # Transformación de alarm_config con SNS
    ├── terraform.tfvars   # Valores de ejemplo (EC2 CPU + memoria con CWAgent)
    ├── data.tf            # Data sources (SNS topic)
    ├── providers.tf       # Provider con default_tags
    ├── outputs.tf         # Outputs del ejemplo
    └── README.md
```
