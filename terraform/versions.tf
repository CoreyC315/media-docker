terraform {
  required_version = ">= 1.5"

  required_providers {
    # Modern, well-maintained Proxmox provider with first-class cloud-init.
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.60.0, < 1.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2"
    }
  }
}
