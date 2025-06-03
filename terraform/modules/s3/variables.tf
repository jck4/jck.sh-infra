variable "tf_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "jcksh-terraform-state"
}

variable "backups_bucket" {
  description = "Name of the S3 bucket for FoundryVTT backups"
  type        = string
  default     = "jcksh-foundryvtt-backups"
} 