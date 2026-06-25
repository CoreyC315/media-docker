# Terraform — one-shot deploy

`terraform apply` provisions a Proxmox VM, installs Docker, and brings up the
whole media stack on a static IP you choose. No manual VM building.

What it does:

1. Downloads the Debian 12 cloud image to your node (once).
2. Creates a cloud-init VM (user, SSH key, static IP).
3. SSHes in and runs the same install → clone → `docker compose up` steps the
   README at the repo root describes — automatically.

## Prerequisites

- **Terraform** ≥ 1.5 (or OpenTofu).
- A **Proxmox API token**. In the PVE UI: *Datacenter → Permissions → API Tokens
  → Add* (e.g. user `terraform@pve`, token id `media`). Give it a role with VM
  + datastore privileges (`PVEVMAdmin` on `/` is simplest for a lab). Copy the
  full `user@realm!tokenid=secret` string.
- **Root SSH to the Proxmox node** via your ssh-agent — the provider shells into
  the node to import the disk image. Run `ssh-add` first, and make sure
  `ssh root@<node>` works key-only.
- An **SSH keypair** for logging into the new VM.
- The target **storage names** (`vm_datastore` for the disk, `image_datastore`
  for the image) and a **free static IP** on your bridge.

## Usage

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars        # fill in token, node, storage, IP, SSH key

terraform init
terraform apply
```

When it finishes, the outputs print the service URLs, e.g.:

```
service_urls = {
  jellyfin    = "http://10.0.10.41:8096"
  jellyseerr  = "http://10.0.10.41:5055"
  ...
}
mode = "DEMO (qBittorrent has no VPN — UI only)"
```

## Demo vs. live

- **Leave `wireguard_private_key = ""`** → *demo mode*: every UI is reachable,
  but qBittorrent runs without the VPN (no real downloading). Great for showing
  the services off.
- **Set `wireguard_private_key`** to your ProtonVPN WireGuard key → *live mode*:
  qBittorrent runs behind the gluetun kill switch. Re-run `terraform apply` after
  setting it and the stack flips over automatically.

## Tearing it down

```bash
terraform destroy
```

Removes the VM entirely. (The downloaded base image is left on the node.)

## Notes / gotchas

- **Static IP required.** Terraform needs to know the address to SSH in and
  deploy, so DHCP isn't supported here — pick a free IP.
- **Disk holds everything.** OS + app config + media all live on the VM's root
  disk. Bump `vm_disk_gb` for a real library, or attach/mount bigger storage
  later and point `data_root` at it.
- **The provider needs node SSH**, not just the API token — this is a quirk of
  importing cloud images. If `apply` hangs on the disk step, that's almost
  always the missing `ssh-add` / root SSH.
- Uses the `bpg/proxmox` provider (pinned `< 1.0`), not the Telmate one.
