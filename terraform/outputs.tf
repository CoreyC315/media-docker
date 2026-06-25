output "vm_id" {
  description = "Proxmox VMID that was created"
  value       = proxmox_virtual_environment_vm.media.vm_id
}

output "vm_ip" {
  value = var.vm_ip
}

output "mode" {
  value = nonsensitive(var.wireguard_private_key == "") ? "DEMO (qBittorrent has no VPN — UI only)" : "LIVE (qBittorrent behind gluetun VPN)"
}

output "service_urls" {
  description = "Open these once provisioning finishes"
  value = {
    jellyfin    = "http://${var.vm_ip}:8096"
    jellyseerr  = "http://${var.vm_ip}:5055"
    sonarr      = "http://${var.vm_ip}:8989"
    radarr      = "http://${var.vm_ip}:7878"
    prowlarr    = "http://${var.vm_ip}:9696"
    qbittorrent = "http://${var.vm_ip}:8080"
  }
}

output "ssh" {
  value = "ssh ${var.vm_user}@${var.vm_ip}"
}
