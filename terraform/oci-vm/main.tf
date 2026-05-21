data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "ubuntu_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  cidr_block     = var.vcn_cidr
  display_name   = "${var.display_name}-vcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  enabled        = true
  display_name   = "${var.display_name}-igw"
}

resource "oci_core_default_route_table" "default_route" {
  manage_default_resource_id = oci_core_vcn.this.default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.igw.id
    destination       = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  cidr_block     = var.subnet_cidr
  route_table_id = oci_core_vcn.this.default_route_table_id
  display_name   = "${var.display_name}-subnet"
}

resource "oci_core_instance" "this" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain_index].name
  compartment_id      = var.compartment_id
  display_name        = var.display_name
  shape               = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.this.id
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
