variable "storage_nodes" {
	type = list(object({
		name = string
		memory = string
		vcpu = string
		network = string
	}))
}

variable "storage_size" {
	type = string
}

resource "libvirt_cloudinit_disk" "storage_init" {
	name = "${var.storage_nodes[count.index].name}_cloudinit.iso"
	pool = var.volume_pool
	user_data = data.template_file.storage_user_data[count.index].rendered
	meta_data = data.template_file.storage_meta_data[count.index].rendered
	network_config = data.template_file.storage_network_config[count.index].rendered
	count = length(var.storage_nodes)
}

data "template_file" "storage_user_data" {
	template = file("${var.path_cloudinit}/user-data-${var.storage_nodes[count.index].name}")
	count = length(var.storage_nodes)
}

data "template_file" "storage_meta_data" {
	template = file("${var.path_cloudinit}/meta-data-${var.storage_nodes[count.index].name}")
	count = length(var.storage_nodes)
}

data "template_file" "storage_network_config" {
	template = file("${var.path_cloudinit}/network-config-${var.storage_nodes[count.index].name}")
	count = length(var.storage_nodes)
}

resource "libvirt_volume" "storage_base" {
	name = "root_${var.storage_nodes[count.index].name}"
	pool = var.volume_pool
	base_volume_name = var.base_volume.name
	base_volume_pool = var.base_volume.pool
	count = length(var.storage_nodes)
}

resource "libvirt_volume" "storage" {
	name = "storage_${var.storage_nodes[count.index].name}"
	pool = var.volume_pool
	size = var.storage_size
	count = length(var.storage_nodes)
}

resource "libvirt_domain" "storage_nodes" {
	count = length(var.storage_nodes)
	name = var.storage_nodes[count.index].name
	memory = var.storage_nodes[count.index].memory
	vcpu = var.storage_nodes[count.index].vcpu

	qemu_agent = true

	running = true

	disk {
		volume_id = libvirt_volume.storage_base[count.index].id
	}

	disk {
		volume_id = libvirt_volume.storage[count.index].id
	}

	disk {
		volume_id = split(";", libvirt_cloudinit_disk.storage_init[count.index].id)[0]
	}

	network_interface {
		network_id = libvirt_network.network.id
		wait_for_lease = true
	}
}

output "storage_nodes_info" {
	value = libvirt_domain.storage_nodes
}
