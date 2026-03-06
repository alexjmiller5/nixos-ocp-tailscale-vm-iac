variable "ssh_public_key" {
  description = "SSH public key for instance access (also add to configuration.nix)"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7ZCS39YKZ+E/U0aFXe6qfBTfPOgT6NWN7LoOddv7/0"
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "sa-bogota-1"
}

variable "instance_shape" {
  description = "Instance shape (Always Free tier)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs (Always Free tier allows up to 4 total)"
  type        = number
  default     = 1
}

variable "instance_memory_gb" {
  description = "Memory in GB (Always Free tier allows up to 24 total)"
  type        = number
  default     = 6
}

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB (Always Free tier allows up to 200 total)"
  type        = number
  default     = 50
}
