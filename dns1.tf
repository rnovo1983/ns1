provider "vsphere" {
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"

  allow_unverified_ssl = true
}
data "vsphere_datacenter" "dc" {
  name = "Datacenter1"
}
data "vsphere_datastore" "datastore" {
  name          = "Toshiba"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
data "vsphere_resource_pool" "pool" {
  name          = "rpool1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "template_ubuntu01"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
  name             = "NS1"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus     = 2
  memory       = 1024
  guest_id     = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }
  
  disk {
    name             = "NS1.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }
  
  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
     linux_options {
       host_name = "NS1"
       domain    = "test.internal"
     }

    network_interface {
    }

      ipv4_gateway = "192.168.1.1"
    }
  }


  provisioner "chef" {
		environment         = "_default"
		run_list            = ["apache::default","apache::motd"]
		node_name           = "NS1"
		server_url          = "https://192.168.1.160/organizations/mecorp"
		recreate_client     = true
		user_name           = "rnovo"
		user_key            = "${file("~/chef-repo/rnovo.pem")}"
		ssl_verify_mode     = ":verify_none"
		#on_failure          = "continue"
	}
  	
	connection {
		type      = "ssh"
		user      = "${var.con_user}"
		password  = "${var.con_password}"
	}
}
