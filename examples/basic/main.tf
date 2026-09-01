provider "aws" {
  region = var.aws_region
}

# A custom bus with a rule that matches "OrderPlaced" events from "my.app",
# delivered to a created CloudWatch Logs group (self-contained, free).
module "eventbridge" {
  source = "../.."

  bus_name = "iacbazaar-example-orders"

  rule_description = "Capture order events for auditing"
  event_pattern = jsonencode({
    source        = ["my.app"]
    "detail-type" = ["OrderPlaced"]
  })

  target_type        = "log_group"
  log_retention_days = 14

  tags = {
    Environment = "example"
    ManagedBy   = "iac-bazaar"
  }
}
