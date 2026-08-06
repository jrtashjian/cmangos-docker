# [CMaNGOS](https://cmangos.net) powered by Docker

A collection of Docker images and compose files for running [CMaNGOS](https://cmangos.net) locally.

## Supported clients

| Client | Build | Core |
| --- | --- | --- |
| World of Warcraft | 1.12.1 (5875) | [cmangos-classic](https://github.com/cmangos/mangos-classic) |
| The Burning Crusade | 2.4.3 (8606) | [cmangos-tbc](https://github.com/cmangos/mangos-tbc) |
| Wrath of the Lich King | 3.3.5 (12340) | [cmangos-wotlk](https://github.com/cmangos/mangos-wotlk) |

## Available images

Images are published to `ghcr.io/jrtashjian`. Replace `<core>` with `classic`, `tbc`, or `wotlk`.

Every image is also tagged with a build date (`YYYY.MM.DD`) so you can pin a known release instead of tracking `latest`.

| Image | Tag | What you get |
| --- | --- | --- |
| `cmangos-realmd-<core>` | `latest` | Login server |
| `cmangos-extractors-<core>` | `latest` | Client data extractors |
| `cmangos-mangosd-<core>` | `latest` | World server (default build) |
| | `with-ahbot` | World server + auction house bot |
| | `with-playerbot` | World server + playerbots |
| | `with-playerbot-ahbot` | World server + both bots |

Examples:

```
ghcr.io/jrtashjian/cmangos-mangosd-classic:latest
ghcr.io/jrtashjian/cmangos-mangosd-classic:with-playerbot
ghcr.io/jrtashjian/cmangos-mangosd-classic:2026.08.05-with-ahbot
```

To use a bot-enabled world server with compose, change the `mangosd` image tag in your `docker-compose.yml`.

## Quick start

### 1. Create a working directory

```bash
mkdir ~/cmangos-docker && cd ~/cmangos-docker
```

This directory will hold your compose file and extracted client data.

### 2. Download a compose file

Pick the core that matches your WoW client.

If you want classic:

```bash
wget -O docker-compose.yml https://raw.githubusercontent.com/jrtashjian/cmangos-docker/master/docker-compose.classic.yml
```

If you want TBC:

```bash
wget -O docker-compose.yml https://raw.githubusercontent.com/jrtashjian/cmangos-docker/master/docker-compose.tbc.yml
```

If you want WotLK:

```bash
wget -O docker-compose.yml https://raw.githubusercontent.com/jrtashjian/cmangos-docker/master/docker-compose.wotlk.yml
```

### 3. Extract client data

CMaNGOS needs data extracted from a real WoW client (Cameras, dbc, maps, mmaps, vmaps). Run the extractors image once, pointing it at your client install and an output folder.

Replace `classic` with `tbc` or `wotlk` if needed, and update the client path:

```bash
docker run --rm \
	-v "/path/to/WoW/client:/client" \
	-v "$HOME/cmangos-docker/extracted-data:/maps" \
	ghcr.io/jrtashjian/cmangos-extractors-classic:latest
```

When finished you should have:

```
~/cmangos-docker/extracted-data
├─ Cameras
├─ dbc
├─ maps
├─ mmaps
└─ vmaps
```

The compose files mount `./extracted-data` into the world server automatically.

### 4. Start the server

```bash
docker compose up -d
```

This starts MariaDB, the login server (`realmd`), and the world server (`mangosd`). On first boot, mangosd installs the [latest full content database](https://github.com/orgs/cmangos/repositories?q=-db) — that can take a while.

Check progress with:

```bash
docker compose logs -f mangosd
```

### 5. Point your client at the server

Edit your WoW client's `realmlist.wtf`:

```
set realmlist 127.0.0.1
```

### 6. Log in

Default accounts (unless you configure `ACCOUNTS`):

```
ADMINISTRATOR:ADMINISTRATOR
GAMEMASTER:GAMEMASTER
MODERATOR:MODERATOR
PLAYER:PLAYER
```

## Advanced setup

For custom configuration, use the example compose file with a `.env`:

```bash
mkdir ~/cmangos-docker && cd ~/cmangos-docker
wget -O docker-compose.yml https://raw.githubusercontent.com/jrtashjian/cmangos-docker/master/docker-compose.example.yml
wget -O .env https://raw.githubusercontent.com/jrtashjian/cmangos-docker/master/.env.example
```

Edit `.env` — at minimum set `CORE_VARIANT` (`classic`, `tbc`, or `wotlk`). Other options cover database credentials, separate DB hosts, accounts, and server settings.

Extract client data into `./extracted-data` (same as quick start), then:

```bash
docker compose up -d
```

To use a bot-enabled mangosd image, change the image tag in `docker-compose.yml` (for example `:with-playerbot`).

## Creating accounts

### Automated

Create a `.env` file next to `docker-compose.yml` and set `ACCOUNTS`. When present, the four default seed accounts are removed and replaced with the ones you define:

```bash
# Format: username:password[:gmlevel],...
# username: letters and digits only
# gmlevel: 0=PLAYER, 1=MODERATOR, 2=GAMEMASTER, 3=ADMINISTRATOR
ACCOUNTS=admin:changeme:3,player:changeme
```

Accounts are created or updated each time `realmd` starts.

### Manual

Start the database and login server, then open a mangosd console:

```bash
docker compose up -d database realmd
docker compose run --rm -e MANGOSD_CONSOLE_ENABLE=1 mangosd
```

In the console:

```
account create username password
```

For more detail, see the [official CMaNGOS instructions](https://github.com/cmangos/issues/wiki/Installation-Instructions#creating-first-account).

## Credits

Thanks to @korhaldragonir which this project was heavily inspired by [their own](https://github.com/korhaldragonir/cmangos-docker).  
Thanks to @vishnubob and contributors for the [wait-for-it.sh](https://github.com/vishnubob/wait-for-it) script.  
Thanks to [CMaNGOS Community](https://github.com/cmangos).
