# ---------------------------------------------------------------------------
# Event bus
# ---------------------------------------------------------------------------

variable "bus_name" {
  description = "Name of the custom EventBridge event bus to create. Cannot be 'default' (that is the account's built-in bus)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]{1,256}$", var.bus_name)) && var.bus_name != "default"
    error_message = "bus_name must be 1-256 characters of [a-zA-Z0-9._-] and cannot be 'default'."
  }
}

variable "bus_description" {
  description = "Optional description for the event bus (max 512 characters)."
  type        = string
  default     = null

  validation {
    condition     = var.bus_description == null ? true : length(var.bus_description) <= 512
    error_message = "bus_description must be 512 characters or fewer."
  }
}

variable "bus_kms_key_identifier" {
  description = "Customer-managed KMS key (id or ARN) used to encrypt events at rest on the bus. Null = the AWS-owned EventBridge key (still encrypted at rest, no extra cost). A CMK's key policy must grant EventBridge (events.amazonaws.com) kms:GenerateDataKey*/kms:Decrypt."
  type        = string
  default     = null
}

variable "bus_dead_letter_arn" {
  description = "Optional SQS queue ARN for the bus-level dead-letter queue (captures events that EventBridge cannot deliver to any rule). The queue policy must allow events.amazonaws.com to sqs:SendMessage. Null = no bus DLQ."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Rule
# ---------------------------------------------------------------------------

variable "rule_name" {
  description = "Name of the rule on the bus. Null = <bus_name>-rule. Rule names are unique per bus (max 64 characters)."
  type        = string
  default     = null

  validation {
    condition     = var.rule_name == null ? true : can(regex("^[a-zA-Z0-9._-]{1,64}$", var.rule_name))
    error_message = "rule_name must be 1-64 characters of [a-zA-Z0-9._-]."
  }
}

variable "rule_description" {
  description = "Optional description for the rule (max 512 characters)."
  type        = string
  default     = null

  validation {
    condition     = var.rule_description == null ? true : length(var.rule_description) <= 512
    error_message = "rule_description must be 512 characters or fewer."
  }
}

variable "event_pattern" {
  description = "EventBridge event pattern as a JSON string. Rules on a CUSTOM bus must filter by event pattern (schedule_expression rules are only allowed on the default bus, so this module does not expose them). Null = a catch-all pattern that matches every event from this account delivered to the bus."
  type        = string
  default     = null

  validation {
    condition     = var.event_pattern == null ? true : can(jsondecode(var.event_pattern))
    error_message = "event_pattern must be valid JSON."
  }
}

variable "rule_state" {
  description = "Rule state: ENABLED, DISABLED, or ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS."
  type        = string
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED", "ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS"], var.rule_state)
    error_message = "rule_state must be ENABLED, DISABLED, or ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS."
  }
}

# ---------------------------------------------------------------------------
# Target
# ---------------------------------------------------------------------------

variable "target_type" {
  description = "Where matched events are sent. 'log_group' (default) creates a CloudWatch Logs group plus the resource policy EventBridge needs to write to it — self-contained, free, and great for capturing/auditing events. 'external' sends to an ARN you supply in target_arn (SQS, SNS, Lambda, Step Functions, ...); you are responsible for that target's resource policy/permissions."
  type        = string
  default     = "log_group"

  validation {
    condition     = contains(["log_group", "external"], var.target_type)
    error_message = "target_type must be log_group or external."
  }
}

variable "target_id" {
  description = "Stable identifier for the target within the rule (1-64 characters of [a-zA-Z0-9._-])."
  type        = string
  default     = "primary"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]{1,64}$", var.target_id))
    error_message = "target_id must be 1-64 characters of [a-zA-Z0-9._-]."
  }
}

variable "target_arn" {
  description = "ARN of the destination when target_type = external. Ignored for target_type = log_group (the created log group is used)."
  type        = string
  default     = null
}

variable "target_role_arn" {
  description = "Optional IAM role ARN EventBridge assumes to deliver to the target (required for some targets such as Step Functions/Kinesis/ECS when target_type = external). Not used for log_group targets, which rely on the log group resource policy."
  type        = string
  default     = null
}

variable "target_input" {
  description = "Optional static JSON passed to the target instead of the matched event. Null = deliver the full matched event."
  type        = string
  default     = null

  validation {
    condition     = var.target_input == null ? true : can(jsondecode(var.target_input))
    error_message = "target_input must be valid JSON."
  }
}

variable "target_dead_letter_arn" {
  description = "Optional SQS queue ARN for the target-level dead-letter queue (captures events that fail delivery to this target after retries). The queue policy must allow events.amazonaws.com to sqs:SendMessage. Null = no target DLQ."
  type        = string
  default     = null
}

variable "target_maximum_event_age_in_seconds" {
  description = "Maximum age of an event (seconds) EventBridge will keep retrying delivery before discarding/DLQ-ing it. AWS allows 60-86400 (default 86400 = 24h)."
  type        = number
  default     = 86400

  validation {
    condition     = var.target_maximum_event_age_in_seconds >= 60 && var.target_maximum_event_age_in_seconds <= 86400
    error_message = "target_maximum_event_age_in_seconds must be between 60 and 86400."
  }
}

variable "target_maximum_retry_attempts" {
  description = "Maximum number of delivery retry attempts. AWS allows 0-185 (default 185)."
  type        = number
  default     = 185

  validation {
    condition     = var.target_maximum_retry_attempts >= 0 && var.target_maximum_retry_attempts <= 185
    error_message = "target_maximum_retry_attempts must be between 0 and 185."
  }
}

# ---------------------------------------------------------------------------
# Log-group target (used when target_type = log_group)
# ---------------------------------------------------------------------------

variable "log_group_name" {
  description = "Name of the CloudWatch Logs group to create as the target. Null = /aws/events/<bus_name>. Only used when target_type = log_group."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Retention for the target log group (days). 0 = never expire. Only used when target_type = log_group."
  type        = number
  default     = 14

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be one of the values CloudWatch Logs accepts (0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653)."
  }
}

variable "log_kms_key_id" {
  description = "Customer-managed KMS key ARN to encrypt the target log group. Null = AWS-managed CloudWatch Logs encryption at rest (no extra cost). The key policy must allow logs.<region>.amazonaws.com. Only used when target_type = log_group."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Tags
# ---------------------------------------------------------------------------

variable "tags" {
  description = "Tags applied to all resources that support tagging (bus, rule, log group)."
  type        = map(string)
  default     = {}
}
