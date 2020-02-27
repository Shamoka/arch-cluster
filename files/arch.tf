provider "libvirt" {
	uri = var.qemu_uri
}

variable "qemu_uri" {
	type = string
}

variable "base_volume" {
	type = object({
		name = string
		pool = string
	})
}

variable "volume_pool" {
	type = string
}

variable "network" {
	type = object({
		name = string
		ip = string
		domain = string
	})
}

variable "path_cloudinit" {
	type = string
}

resource "libvirt_network" "network" {
	name = var.network.name
	mode = "nat"
	domain = var.network.domain
	addresses = [var.network.ip]

	dhcp {
		enabled = true
	}

	dns {
		enabled = true
	}
}
