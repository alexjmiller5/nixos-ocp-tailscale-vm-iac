output "instance_public_ip" {
  value       = oci_core_instance.this.public_ip
  description = "Public IPv4 of the OCI instance."
}

output "instance_ocid" {
  value       = oci_core_instance.this.id
  description = "OCID of the OCI instance."
}
