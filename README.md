# media-docker

A self-hosted media server you can stand up on a single VM with Docker — no
Kubernetes required. Distilled from a larger k8s homelab ("Teyvat") down to the
essentials.

Stack:

| Service | Purpose | WebUI |
|---|---|---|
| **gluetun** | VPN gateway (ProtonVPN/WireGuard) + kill switch | — |
| **qBittorrent** | Download client (locked behind the VPN) | http://VM-IP:8080 |
| **Prowlarr** | Indexer manager (feeds Sonarr/Radarr) | http://VM-IP:9696 |
| **Sonarr** | TV shows | http://VM-IP:8989 |
| **Radarr** | Movies | http://VM-IP:7878 |
| **Jellyfin** | Media server / player | http://VM-IP:8096 |
| **Jellyseerr** | Media request portal (Overseerr for Jellyfin) | http://VM-IP:5055 |

## Prerequisites

1. A Proxmox VM running Debian 12 or Ubuntu 22.04+ (2 vCPU / 4 GB RAM is plenty
   to start; give it more disk or an NFS mount for media).
2. Docker + the Compose plugin:
   ```bash
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker $USER   # log out / back in after this
   ```
3. A **ProtonVPN** account (the free tier does **not** support port forwarding;
   a paid plan is recommended so torrents seed).

## Setup

```bash
git clone https://github.com/CoreyC315/media-docker.git
cd media-docker

# 1. Configure
cp .env.example .env
nano .env                      # set TZ, DATA_ROOT, and your WireGuard key

# 2. Create the data layout (match DATA_ROOT in your .env)
sudo mkdir -p /srv/data/torrents /srv/data/media/tv /srv/data/media/movies
sudo chown -R 1000:1000 /srv/data

# 3. Launch
docker compose up -d
docker compose logs -f gluetun   # confirm the VPN connects before anything else
```

Then open each WebUI from the table above and wire the apps together (below).

## First-run wiring

The containers don't know about each other until you connect them in the UIs.
Because qBittorrent shares gluetun's network, **other apps reach it at the
gluetun container, not at `qbittorrent`.**

1. **qBittorrent** (`:8080`) — grab the temp admin password from
   `docker compose logs qbittorrent`, log in, change it. Set the default save
   path to `/data/torrents`.
2. **Prowlarr** (`:9696`) — add your indexers. Then **Settings → Apps** → add
   Sonarr and Radarr so indexers sync automatically.
   - Sonarr server: `http://sonarr:8989`
   - Radarr server: `http://radarr:7878`
3. **Sonarr** (`:8989`) / **Radarr** (`:7878`):
   - **Download client** → add qBittorrent, host `gluetun`, port `8080`.
   - **Media management → Root folder**: `/data/media/tv` (Sonarr) and
     `/data/media/movies` (Radarr).
4. **Jellyfin** (`:8096`) — run the setup wizard, add libraries pointing at
   `/data/media/tv` and `/data/media/movies`.
5. **Jellyseerr** (`:5055`) — run the wizard, sign in with Jellyfin
   (`http://jellyfin:8096`), then connect your services so requests flow
   automatically:
   - Sonarr: `http://sonarr:8989`, Radarr: `http://radarr:7878` (use each
     app's API key from its Settings → General).
   This is what you hand to friends/coworkers — they request titles here
   instead of touching Sonarr/Radarr directly.

> **Why one `/data` mount?** qBittorrent, Sonarr, and Radarr all see the same
> filesystem at `/data`, so moving a finished download into the library is an
> instant hardlink instead of a slow full copy. Don't split torrents and media
> onto separate mounts.

## Hardware transcoding (optional)

Jellyfin transcoding is CPU-only by default. If your VM has an Intel/AMD iGPU
passed through from Proxmox, uncomment the `devices:` block under `jellyfin` in
`docker-compose.yml`, then enable VAAPI in Jellyfin → Dashboard → Playback.

## Common commands

```bash
docker compose ps                 # status
docker compose logs -f <service>  # tail logs
docker compose pull && docker compose up -d   # update images
docker compose down               # stop everything (config/ is preserved)
```

## Backup

All app state lives in `./config/`. Back that up (`tar czf config-backup.tgz
config/`) and you can rebuild the whole stack anywhere. Media in `DATA_ROOT` is
separate — back it up however you back up the NAS/disk.

## Notes

- Image versions are pinned. Bump them in `docker-compose.yml` when you want to
  update, rather than chasing `:latest`.
- `.env` and `config/` are gitignored — secrets and runtime state stay local.
