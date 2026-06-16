output "state_machine_arn" {
  description = "ARN da State Machine"
  value       = aws_sfn_state_machine.pipeline.arn
}

output "state_machine_name" {
  description = "Nome da State Machine"
  value       = aws_sfn_state_machine.pipeline.name
}