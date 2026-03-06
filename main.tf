locals {
  compartment_ocid = "<your-tenancy-ocid>"
}

provider "oci" {
  auth                = "SecurityToken"
  config_file_profile = "DEFAULT"
  region              = var.region
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = local.compartment_ocid
}

data "oci_core_images" "ubuntu_images" {
  compartment_id           = local.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_vcn" "free_vcn" {
  compartment_id = local.compartment_ocid
  cidr_block     = "10.0.0.0/16"
  display_name   = "always-free-vcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.free_vcn.id
  enabled        = true
}

resource "oci_core_default_route_table" "default_route" {
  manage_default_resource_id = oci_core_vcn.free_vcn.default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.igw.id
    destination       = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "free_subnet" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.free_vcn.id
  cidr_block     = "10.0.0.0/24"
  route_table_id = oci_core_vcn.free_vcn.default_route_table_id
}

resource "oci_core_instance" "always_free_arm" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = local.compartment_ocid
  display_name        = "always-free-arm-vm"
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.free_subnet.id
    assign_public_ip = true
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_images.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_gb
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}