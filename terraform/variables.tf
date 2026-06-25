# ============================================================================
# Proxmox connection
# ============================================================================
variable "proxmox_endpoint" {
  description = "Proxmox API URL, e.g. https://10.0.10.24:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token in the form USER@REALM!TOKENID=SECRET (create under Datacenter -> API Tokens)"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Name of the Proxmox node to deploy on (see `pvecm nodes` / the web UI), e.g. PM-Playground"
  type        = string
}

variable "proxmox_ssh_user" {
  description = "SSH user on the Proxmox node (used by the provider to import the disk image)"
  type        = string
  default     = "root"
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (true for self-signed Proxmox certs)"
  type        = bool
  default     = true
}

# ============================================================================
# VM shape
# ============================================================================
variable "vm_name" {
  description = "VM name"
  type        = string
  default     = "media-docker"
}

variable "vm_id" {
  description = "Proxmox VMID. Leave 0 to let Proxmox pick the next free id."
  type        = number
  default     = 0
}

variable "vm_cores" {
  type    = number
  default = 4
}

variable "vm_memory_mb" {
  type    = number
  default = 6144
}

variable "vm_disk_gb" {
  description = "Root disk size. Holds the OS, app config, AND media — size for your library."
  type        = number
  default     = 60
}

variable "vm_datastore" {
  description = "Proxmox storage for the VM disk (e.g. local-lvm, vm-hdd-storage)"
  type        = string
}

variable "image_datastore" {
  description = "Storage that can hold the downloaded cloud image (ISO content type), e.g. local"
  type        = string
  default     = "local"
}

variable "debian_image_url" {
  description = "Debian 12 generic cloud image URL"
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}

# ============================================================================
# Network — static IP (so the address is known for provisioning)
# ============================================================================
variable "vm_bridge" {
  type    = string
  default = "vmbr0"
}

variable "vm_ip" {
  description = "Static IPv4 for the VM, e.g. 10.0.10.40"
  type        = string
}

variable "vm_cidr_bits" {
  description = "Subnet prefix length, e.g. 24 for a /24"
  type        = number
  default     = 24
}

variable "vm_gateway" {
  description = "Default gateway, e.g. 10.0.10.1"
  type        = string
}

variable "vm_nameservers" {
  type    = list(string)
  default = ["1.1.1.1", "8.8.8.8"]
}

# ============================================================================
# Guest OS / access
# ============================================================================
variable "vm_user" {
  description = "Login user created on the VM"
  type        = string
  default     = "corey"
}

variable "ssh_public_key" {
  description = "Public key injected into the VM for the login user"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Matching private key, used by Terraform to SSH in and deploy the stack"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "timezone" {
  type    = string
  default = "America/Detroit"
}

# ============================================================================
# Media stack config
# ============================================================================
variable "repo_url" {
  description = "Git repo holding the docker-compose stack"
  type        = string
  default     = "https://github.com/CoreyC315/media-docker.git"
}

variable "data_root" {
  description = "Path on the VM that holds torrents + media (mounted at /data in containers)"
  type        = string
  default     = "/srv/data"
}

variable "wireguard_private_key" {
  description = <<-EOT
    ProtonVPN WireGuard private key. Leave EMPTY for demo mode: the stack comes
    up with all UIs reachable but qBittorrent runs without the VPN (no real
    downloading). Set it to go fully live behind the gluetun kill switch.
  EOT
  type        = string
  default     = ""
  sensitive   = true
}

variable "vpn_server_countries" {
  type    = string
  default = "United States"
}
