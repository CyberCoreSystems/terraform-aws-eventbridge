# EventBridge custom event bus + a rule (event-pattern filtered) + a target.
# Secure by default: the bus is encrypted at rest (AWS-owned key, or a CMK you
# supply) and, for the built-in CloudWatch Logs target, the log group resource
# policy is least-privilege (only this account's EventBridge can write, via an
# aws:SourceAccount confused-deputy guard). The default rule pattern is a
# catch-all so the stack stands up with just a bus name; supply event_pattern
# for real routing.

data "aws_caller_identity" "current" {}

locals {
  rule_name        = coalesce(var.rule_name, "${var.bus_name}-rule")
  log_group_name   = coalesce(var.log_group_name, "/aws/events/${var.bus_name}")
  create_log_group = var.target_type == "log_group"

  # Rules on a custom bus must be event-pattern based. Default to every event
  # from this account so the module is functional with zero routing config.
  event_pattern = coalesce(
    var.event_pattern,
    jsonencode({ account = [data.aws_caller_identity.current.account_id] })
  )

  target_arn = local.create_log_group ? aws_cloudwatch_log_group.target[0].arn : var.target_arn
}

# ---------------------------------------------------------------------------
# Event bus -- encrypted at rest (AWS-owned key by default, CMK when provided)
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_event_bus" "this" {
  name               = var.bus_name
  description        = var.bus_description
  kms_key_identifier = var.bus_kms_key_identifier

  dynamic "dead_letter_config" {
    for_each = var.bus_dead_letter_arn != null ? [1] : []
    content {
      arn = var.bus_dead_letter_arn
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Rule (event-pattern filtered, on the custom bus)
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "this" {
  name           = local.rule_name
  description    = var.rule_description
  event_bus_name = aws_cloudwatch_event_bus.this.name
  event_pattern  = local.event_pattern
  state          = var.rule_state

  tags = var.tags
}

# ---------------------------------------------------------------------------
# CloudWatch Logs target (created when target_type = log_group)
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "target" {
  # checkov:skip=CKV_AWS_338: retention is a deliberate buyer knob via var.log_retention_days (default 14 days for event-delivery debugging logs); >=1-year retention is a compliance/cost tradeoff the buyer sets
  count = local.create_log_group ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = var.tags
}

# Resource policy that lets EventBridge deliver to the log group. Scoped to this
# account (confused-deputy guard) and to this specific log group. Both the
# classic events.amazonaws.com and the newer delivery.logs.amazonaws.com
# principals are granted so delivery works across EventBridge versions.
data "aws_iam_policy_document" "logs" {
  count = local.create_log_group ? 1 : 0

  statement {
    sid    = "AllowEventBridgeToWriteLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${aws_cloudwatch_log_group.target[0].arn}:*"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "logs" {
  count = local.create_log_group ? 1 : 0

  policy_name     = "${local.rule_name}-eventbridge-logs"
  policy_document = data.aws_iam_policy_document.logs[0].json
}

# ---------------------------------------------------------------------------
# Target wiring
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_event_target" "this" {
  rule           = aws_cloudwatch_event_rule.this.name
  event_bus_name = aws_cloudwatch_event_bus.this.name
  target_id      = var.target_id
  arn            = local.target_arn
  role_arn       = var.target_role_arn
  input          = var.target_input

  dynamic "dead_letter_config" {
    for_each = var.target_dead_letter_arn != null ? [1] : []
    content {
      arn = var.target_dead_letter_arn
    }
  }

  retry_policy {
    maximum_event_age_in_seconds = var.target_maximum_event_age_in_seconds
    maximum_retry_attempts       = var.target_maximum_retry_attempts
  }

  # Ensure the log group's delivery permissions exist before the target so
  # EventBridge can write from the first matched event.
  depends_on = [aws_cloudwatch_log_resource_policy.logs]

  lifecycle {
    precondition {
      condition     = var.target_type != "external" || var.target_arn != null
      error_message = "target_arn is required when target_type = \"external\"."
    }
  }
}
