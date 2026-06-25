provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_tls_insecure

  # bpg uses SSH to the Proxmox node to import the downloaded cloud image as a
  # VM disk. Requires key-based root SSH to the node (load your key into
  # ssh-agent first: `ssh-add`).
  ssh {
    agent    = true
    username = var.proxmox_ssh_user
  }
}
