variable "nodes" {
	type = list(object({
		name = string
		memory = string
		vcpu = string
		network = string
	}))
}

resource "libvirt_cloudinit_disk" "init" {
	name = "${var.nodes[count.index].name}_cloudinit.iso"
	pool = var.volume_pool
	user_data = data.template_file.user_data[count.index].rendered
	meta_data = data.template_file.meta_data[count.index].rendered
	network_config = data.template_file.network_config[count.index].rendered
	count = length(var.nodes)
}

data "template_file" "user_data" {
	template = file("${var.path_cloudinit}/user-data-${var.nodes[count.index].name}")
	count = length(var.nodes)
}

data "template_file" "meta_data" {
	template = file("${var.path_cloudinit}/meta-data-${var.nodes[count.index].name}")
	count = length(var.nodes)
}

data "template_file" "network_config" {
	template = file("${var.path_cloudinit}/network-config-${var.nodes[count.index].name}")
	count = length(var.nodes)
}

resource "libvirt_volume" "base" {
	count = length(var.nodes)
	name = "root_${var.nodes[count.index].name}"
	pool = var.volume_pool
	base_volume_name = var.base_volume.name
	base_volume_pool = var.base_volume.pool
}

resource "libvirt_domain" "nodes" {
	count = length(var.nodes)
	name = var.nodes[count.index].name
	memory = var.nodes[count.index].memory
	vcpu = var.nodes[count.index].vcpu

	qemu_agent = true

	running = true

	disk {
		volume_id = libvirt_volume.base[count.index].id
	}

	disk {
		volume_id = split(";", libvirt_cloudinit_disk.init[count.index].id)[0]
	}

	network_interface {
		network_id = libvirt_network.network.id
		wait_for_lease = true
	}
}

output "nodes_info" {
	value = libvirt_domain.nodes
}
