# IAM roles for ECS tasks are managed manually (outside Terraform) due to
# restricted iam:List*/Get* permissions on the ayal IAM user.
# See: ay-l-final-project-ecs-execution-role-manual, ay-l-final-project-ecs-task-role-manual
# Their ARNs are passed in via var.execution_role_arn / var.task_role_arn.