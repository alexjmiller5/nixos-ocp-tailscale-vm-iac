variable "compartment_id" {
  type        = string
  description = "OCI compartment OCID."
}

variable "region" {
  type        = string
  description = "OCI region."
  default     = "us-ashburn-1"
}

variable "vcn_cidr" {
  type        = string
  description = "CIDR for the VCN. Each VM stack should pick a distinct block."
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR for the subnet — must be inside vcn_cidr."
  default     = "10.0.0.0/24"
}

variable "shape" {
  type        = string
  description = "Compute shape."
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  type        = number
  description = "OCPUs (Always Free total cap: 4)."
  default     = 1
}

variable "memory_gb" {
  type        = number
  description = "Memory in GB (Always Free total cap: 24)."
  default     = 6
}

variable "boot_volume_size_gb" {
  type        = number
  description = "Boot volume in GB (Always Free total cap: 200)."
  default     = 50
}

variable "display_name" {
  type        = string
  description = "Human-readable instance name (also seen in OCI console)."
}

variable "ssh_public_key" {
  type        = string
  description = "Public SSH key authorized on the instance."
}

variable "availability_domain_index" {
  type        = number
  description = "Index into the compartment's availability_domains list. Some regions place Always Free ARM quota in a non-zero AD."
  default     = 0
}
