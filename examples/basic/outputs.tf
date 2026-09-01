output "event_bus_arn" {
  description = "ARN of the custom event bus."
  value       = module.eventbridge.event_bus_arn
}

output "rule_arn" {
  description = "ARN of the rule."
  value       = module.eventbridge.rule_arn
}

output "log_group_name" {
  description = "Name of the target CloudWatch Logs group."
  value       = module.eventbridge.log_group_name
}
