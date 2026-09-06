# =========================================================
# Policy A (primary):   ALBRequestCountPerTarget — reacts fastest
#                        to real incoming traffic.
# Policy B (safety net): ECSServiceAverageCPUUtilization — catches
#                        cases where traffic is low but a single
#                        request is CPU-heavy (e.g. slow DB query
#                        or a runaway process).
# =========================================================

resource "aws_appautoscaling_target" "web" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.web.name}"
  scalable_dimension  = "ecs:service:DesiredCount"
  min_capacity        = var.web_min_capacity
  max_capacity        = var.web_max_capacity
}

# --- Policy A: ALBRequestCountPerTarget (primary) ---
resource "aws_appautoscaling_policy" "web_request_count" {
  name               = "ay-l-final-project-web-request-count"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.web.service_namespace
  resource_id        = aws_appautoscaling_target.web.resource_id
  scalable_dimension = aws_appautoscaling_target.web.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label          = "${var.alb_arn_suffix}/${var.web_target_group_arn_suffix}"
    }
    target_value       = var.web_autoscaling_request_count_target
    scale_out_cooldown = 60
    scale_in_cooldown  = 180
  }
}

# --- Policy B: ECSServiceAverageCPUUtilization (safety net) ---
resource "aws_appautoscaling_policy" "web_cpu" {
  name               = "ay-l-final-project-web-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.web.service_namespace
  resource_id        = aws_appautoscaling_target.web.resource_id
  scalable_dimension = aws_appautoscaling_target.web.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.web_autoscaling_cpu_target
    scale_out_cooldown = 60
    scale_in_cooldown  = 180
  }
}