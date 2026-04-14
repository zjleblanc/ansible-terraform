# CMDB-oriented outputs for the created VMs (e.g. for Ansible inventory or config DB)

output "aap_job_url" {
  description = "URL of the Ansible Automation Platform job."
  value       = var.aap_job_url
}

output "aap_workflow_url" {
  description = "URL of the Ansible Automation Platform workflow."
  value       = var.aap_workflow_url
}
