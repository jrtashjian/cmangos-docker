# [CMaNGOS](https://cmangos.net) powered by Docker

A collection of Docker images for the CMaNGOS project variants.

## Supported Variants and Clients

- World of Warcraft 1.12.1 (5875) used with [`cmangos-classic`](https://github.com/cmangos/mangos-classic)
- World of Warcraft - The Burning Crusade 2.4.3 (8606) used with [`cmangos-tbc`](https://github.com/cmangos/mangos-tbc)
- World of Warcraft - Wrath of the Lich King 3.3.5 (12340) used with [`cmangos-wotlk`](https://github.com/cmangos/mangos-wotlk)

## Available Images

Published at `ghcr.io/jrtashjian`. Replace `<core>` with `classic`, `tbc`, or `wotlk`. Every image also has a dated tag (`YYYY.MM.DD`) for pinning.

| Image | Tag | What you get |
| --- | --- | --- |
| `cmangos-realmd-<core>` | `latest` | Login server |
| `cmangos-extractors-<core>` | `latest` | Client data extractors |
| `cmangos-mangosd-<core>` | `latest` | World server |
| | `with-ahbot` | + auction house bot |
| | `with-playerbot` | + playerbots |
| | `with-playerbot-ahbot` | + both bots |

Examples: `ghcr.io/jrtashjian/cmangos-mangosd-classic:with-playerbot`, `ghcr.io/jrtashjian/cmangos-mangosd-classic:2026.08.05-with-ahbot`

## Quick Start Guide

Create a directory on your machine to store everything:
```
mkdir ~/cmangos-docker && cd ~/cmangos-docker
```

Copy one of the pre-configured docker-compose files onto your machine for the variant you want to run.

If you want `cmangos-classic`:
```
wget -O docker-compose.yml https://raw.githubusercontent.com/jrtashjian/cmangos-docker/master/docker-compose.classic.yml
```

If you want `cmangos-tbc`:
```
wget -O docker-compose.yml https://raw.githubusercontent.com/jrtashjian/cmangos-docker/master/docker-compose.tbc.yml
```

If you want `cmangos-wotlk`:
```
wget -O docker-compose.yml https://raw.githubusercontent.com/jrtashjian/cmangos-docker/master/docker-compose.wotlk.yml
```

Place the [extracted client data files](#extracting-client-data) (Cameras, dbc, maps, mmaps, vmaps) into a volume or folder which will be mapped into a container.

```
~/cmangos-docker/extracted-data
├─ Cameras
├─ dbc
├─ maps
├─ mmaps
└─ vmaps
```

Run `docker-compose up` to start your server!

Update your World of Warcraft client's `realmlist.wtf` file to point to your localhost IP address.

```
set realmlist 127.0.0.1
```

Login with your client using the default username:password combos (unless `ACCOUNTS` is set, in which case these are replaced by your configured accounts):

```
ADMINISTRATOR:ADMINISTRATOR
GAMEMASTER:GAMEMASTER
MODERATOR:MODERATOR
PLAYER:PLAYER
```

You are now running local server for the core variant you chose with the [latest full content database](https://github.com/orgs/cmangos/repositories?q=-db).

## Extracting client data

Using the cmangos-extractors-variant container of your chosen core variant, extract the required client data like this:

```
docker run \
	-v "/path/to/WoW/client:/client" \
	-v "/home/$USER/cmangos-docker/extracted-data:/maps" \
	ghcr.io/jrtashjian/cmangos-extractors-classic:latest
```

## Creating accounts

### Automated (env var)

Set the `ACCOUNTS` variable in your `.env` file. When present, the four default seed accounts (`ADMINISTRATOR`, `GAMEMASTER`, `MODERATOR`, `PLAYER`) are removed and replaced with the accounts you define. Expansion is derived automatically from `CORE_VARIANT`.

```bash
# Format: username:password[:gmlevel],...
# username: letters/digits only; gmlevel: 0=PLAYER, 1=MODERATOR, 2=GAMEMASTER, 3=ADMINISTRATOR
ACCOUNTS=admin:changeme:3,player:changeme
```

Accounts are upserted each time `realmd` starts. Default seed accounts not listed in `ACCOUNTS` are removed.

### Manual (console)

Ensure the database and realmd services are running:

```bash
docker compose up database realmd
```

Start the mangosd server with console access enabled:

```bash
docker compose run --rm -e MANGOSD_CONSOLE_ENABLE=1 mangosd
```

In the mangosd console, create a new user account (replace `username` and `password` with your desired credentials):

```
account create username password
```

For more details, see the [official instructions](https://github.com/cmangos/issues/wiki/Installation-Instructions#creating-first-account).

## Credits

Thanks to @korhaldragonir which this project was heavily inspired by [their own](https://github.com/korhaldragonir/cmangos-docker).  
Thanks to @vishnubob and contributors for the [wait-for-it.sh](https://github.com/vishnubob/wait-for-it) script.  
Thanks to [CMaNGOS Community](https://github.com/cmangos).