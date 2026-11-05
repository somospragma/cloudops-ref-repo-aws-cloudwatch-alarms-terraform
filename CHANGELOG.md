# Changelog

## [Unreleased]

## [1.0.0] - 2026-11-03

### Added
- Recurso `aws_cloudwatch_metric_alarm` con `for_each` para alarmas dinámicas.
- Soporte para `metric_queries` con bloques `dynamic` anidados.
- Variables de gobernanza (`client`, `project`, `environment`).
- Nomenclatura estándar `{client}-{project}-{environment}-cw-alarm-{key}`.
- Directorio `sample/` con ejemplo funcional (PC-IAC-026) y `terraform.tfvars.sample`.

### Changed
- `environment` acepta `dev`, `qa`, `staging`, `pdn`, `prod`, `poc`.
- Límites de longitud en `client` (máx 10) y `project` (máx 15) por PC-IAC-003.
- `versions.tf`: `required_version >= 1.14.0`, `aws >= 4.31.0`.
- `sample/`: etiquetas vía `common_tags` en `default_tags` del provider (sin tags quemadas).
