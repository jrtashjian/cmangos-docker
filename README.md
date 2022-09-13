# [CMaNGOS](https://cmangos.net) powered by Docker

🚧 **UNDER DEVELOPMENT** 🚧

A collection of Docker images for the CMaNGOS project variants.

## Supported Variants and Clients

- World of Warcraft 1.12.1 (5875) used with [`cmangos-classic`](https://github.com/cmangos/mangos-classic)
- World of Warcraft - The Burning Crusade 2.4.3 (8606) used with [`cmangos-tbc`](https://github.com/cmangos/mangos-tbc)
- World of Warcraft - Wrath of the Lich King 3.3.5 (12340) used with [`cmangos-wotlk`](https://github.com/cmangos/mangos-wotlk)

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

Login with your client using the default username:password combos:

```
ADMINISTRATOR:ADMINISTRATOR
GAMEMASTER:GAMEMASTER
MODERATOR:MODERATOR
PLAYER:PLAYER
```

You are now running an entirely empty world of the core variant you chose!

## Installing the content database

TBD

## Extracting client data

Using the cmangos-extractors-variant container of your chosen core variant, extract the required client data like this:
```
docker run -it \
	-v "/path/to/WoW/client:/client" \
	-v "/home/$USER/cmangos-docker/extracted-data:/maps" \
	ghcr.io/jrtashjian/cmangos-extractors-classic
```

Follow the prompts to start the extraction. Initially, you'll probably want to extract everything:

1. Should all dataz (dbc, maps, vmaps and mmaps) be extracted? (y/n)  
   _YES_
2. How many CPU threads should be used for extracting mmaps? (leave empty to use all available threads)  
   _LEAVE EMPTY_
3. MMap Extraction Delay (leave blank for direct extraction)  
   _LEAVE BLANK_
4. Would you like the extraction of maps to be high-resolution? (y/n)  
   _YES_
5. Would you like the extraction of vmaps to be high-resolution? (y/n)  
   _YES_
```
Current Settings:
Extract DBCs/maps: 1, Extract vmaps: 1, Extract mmaps: 1, Processes for mmaps: all
maps extraction will be high-resolution
vmaps extraction will be high-resolution

Press (Enter) to continue, or interrupt with (CTRL+C)
```

Press Enter to start the extraction (this will take a while).

## Credits

Thanks to @korhaldragonir which this project was heavily inspired by [their own](https://github.com/korhaldragonir/cmangos-docker).  
Thanks to @vishnubob and contributors for the [wait-for-it.sh](https://github.com/vishnubob/wait-for-it) script.  
Thanks to @krallin and contributors for making [tini](https://github.com/krallin/tini/).  
Thanks to [CMaNGOS Community](https://github.com/cmangos).