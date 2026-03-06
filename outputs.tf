output "instance_public_ip" {
  value       = oci_core_instance.always_free_arm.public_ip
  description = "Public IP of the Oracle Cloud instance"
}

output "install_command" {
  value       = "After 'terraform apply' completes, run:\n  ./install-nixos.sh ${oci_core_instance.always_free_arm.public_ip}"
  description = "Command to install NixOS on the instance"
}