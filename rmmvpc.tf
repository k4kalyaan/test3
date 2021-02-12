variable "TF_VERSION" {
 default = "0.12"
 description = "terraform engine version to be used in schematics"
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.ibm_region
}

##################################################################################################

resource "ibm_is_vpc" "vpc" {
  name           = "${var.prefix}vpc"
  resource_group = var.resource_group
}


resource "ibm_is_security_group" "sg" {
  name           = "${var.prefix}sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group
}


resource "ibm_is_security_group_rule" "ssh" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_subnet" "subnet" {
  name                     = "${var.prefix}subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zone
  total_ipv4_address_count = 8
  resource_group           = var.resource_group
}


data "ibm_is_ssh_key" "ssh_key_id" {
  name = var.ssh_key
}


resource "ibm_is_instance" "vsi" {
  name           = "${var.prefix}vsi"
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.zone
  keys           = [data.ibm_is_ssh_key.ssh_key_id.id]
  resource_group = var.resource_group
  image          = var.image
  profile        = var.profile

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.sg.id]
  }
}

resource "ibm_is_floating_ip" "fip" {
  name           = "${var.prefix}fip"
  target         = ibm_is_instance.vsi.primary_network_interface[0].id
  resource_group = var.resource_group
}

output "PUBLIC_IP" {
  value = ibm_is_floating_ip.fip.address
}

/**
Variable Section
*/

variable ibmcloud_api_key {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  type        = string
}

variable ssh_key {
   description = "The IBM Cloud platform SSH keys"
   type        = string
  
}

variable ibm_region {
    description = "IBM Cloud region where all resources will be deployed"
    type        = string
}

variable resource_group {
 type        = string
}


variable image {
  default = "cos://us-south/cos-davidng-south/centos7v1n1-test.qcow2""
}

variable profile {
  default = "cx2-2x4"
}


variable prefix {
  description = "The prefix of VPC."
  type        = string
}

variable zone {
  description = "The value of the zone of VPC."
  type        = string
}

**********************************************************************************
#to declare the image value from the coss bucket
#variable "rmm_cos_image_url" {
  #default     = "cos://us-south/cos-davidng-south/centos7v1n1-test.qcow2"
  #description = "The COS image object URL for RMM image."
#}

#variable "rmm_vpc_image_name" {
 #default     = "centos7v1n1-test.qcow2"
  #description = "The name of the custom image to be provisioned in your IBM Cloud account."
#}

**********************************************************************************
