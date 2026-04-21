variable "ec2_instance_id" { type = string }
variable "neptune_cluster_id" { type = string }

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "ify-full-stack-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Neptune", "CPUUtilization", "DBClusterIdentifier", var.neptune_cluster_id],
            [".", "EngineUptime", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Writer Phase: Neptune Compute"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.ec2_instance_id],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Reader Phase: Chat App EC2 Runner"
          period  = 300
        }
      }
    ]
  })
}
