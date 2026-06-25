# 1. Pull the Debian 12 cloud image onto the node (skipped if already present).
resource "proxmox_virtual_environment_download_file" "debian" {
  content_type = "iso"
  datastore_id = var.image_datastore
  node_name    = var.proxmox_node
  url          = var.debian_image_url
  # Force an .img name so Proxmox accepts it as an importable disk image.
  file_name = "debian-12-genericcloud-amd64.img"
  overwrite = false
}

# 2. Create the VM from that image with cloud-init (user, SSH key, static IP).
resource "proxmox_virtual_environment_vm" "media" {
  name      = var.vm_name
  node_name = var.proxmox_node
  vm_id     = var.vm_id == 0 ? null : var.vm_id
  tags      = ["terraform", "media-docker"]

  # genericcloud has no qemu-guest-agent until first boot, so don't block on it.
  agent {
    enabled = false
  }

  cpu {
    cores = var.vm_cores
    type  = "host"
  }

  memory {
    dedicated = var.vm_memory_mb
  }

  scsi_hardware = "virtio-scsi-single"

  operating_system {
    type = "l26"
  }

  disk {
    datastore_id = var.vm_datastore
    file_id      = proxmox_virtual_environment_download_file.debian.id
    interface    = "scsi0"
    size         = var.vm_disk_gb
    discard      = "on"
  }

  network_device {
    bridge = var.vm_bridge
  }

  # Cloud images expect a serial console.
  serial_device {}

  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = "${var.vm_ip}/${var.vm_cidr_bits}"
        gateway = var.vm_gateway
      }
    }

    dns {
      servers = var.vm_nameservers
    }

    user_account {
      username = var.vm_user
      keys     = [trimspace(var.ssh_public_key)]
    }
  }

  lifecycle {
    # Proxmox normalises a few disk/cloud-init fields on read; ignore the churn.
    ignore_changes = [disk[0].file_id]
  }
}

# 3. Once the VM is up, SSH in and stand up the Docker stack.
resource "null_resource" "deploy" {
  depends_on = [proxmox_virtual_environment_vm.media]

  # Re-run provisioning if the VM or any deploy input changes.
  triggers = {
    vm_id  = proxmox_virtual_environment_vm.media.id
    script = sha256(local.provision_script)
  }

  connection {
    type        = "ssh"
    host        = var.vm_ip
    user        = var.vm_user
    private_key = file(pathexpand(var.ssh_private_key_path))
    timeout     = "5m"
  }

  provisioner "file" {
    content     = local.provision_script
    destination = "/tmp/provision.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision.sh",
      "sudo bash /tmp/provision.sh",
    ]
  }
}

locals {
  provision_script = templatefile("${path.module}/provision.sh.tftpl", {
    repo_url              = var.repo_url
    vm_user               = var.vm_user
    data_root             = var.data_root
    timezone              = var.timezone
    wireguard_private_key = var.wireguard_private_key
    vpn_server_countries  = var.vpn_server_countries
  })
}
