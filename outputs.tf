output "event_bus_name" {
  description = "Name of the custom event bus."
  value       = aws_cloudwatch_event_bus.this.name
}

output "event_bus_arn" {
  description = "ARN of the custom event bus."
  value       = aws_cloudwatch_event_bus.this.arn
}

output "rule_name" {
  description = "Name of the rule."
  value       = aws_cloudwatch_event_rule.this.name
}

output "rule_arn" {
  description = "ARN of the rule."
  value       = aws_cloudwatch_event_rule.this.arn
}

output "target_id" {
  description = "Identifier of the target attached to the rule."
  value       = aws_cloudwatch_event_target.this.target_id
}

output "target_arn" {
  description = "ARN of the destination the rule delivers to."
  value       = aws_cloudwatch_event_target.this.arn
}

output "log_group_name" {
  description = "Name of the created CloudWatch Logs target group; null when target_type != log_group."
  value       = try(aws_cloudwatch_log_group.target[0].name, null)
}

output "log_group_arn" {
  description = "ARN of the created CloudWatch Logs target group; null when target_type != log_group."
  value       = try(aws_cloudwatch_log_group.target[0].arn, null)
}
