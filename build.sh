#!/bin/bash

# Initialize variables
MEMORY=""
CPUS=""
NAME=""
PORT=""
DATADIR=""
MODPACK_URL=""
MODPACK_NAME=""
SERVER_NAME=""
VERSION=""
HARDCORE=""

# Get user inputs with validation
read -p "Enter memory allocation (default is 4G): " MEMORY
if [ ! -z "$MEMORY" ]; then
    [[ ! $MEMORY =~ ^[0-9]+[GM]$ ]] && echo "Invalid format. Use number followed by G or M" && exit 1
fi
MEMORY=${MEMORY:-"4G"}

read -p "Enter number of CPUs (default is 2): " CPUS
if [ ! -z "$CPUS" ]; then
    [[ ! $CPUS =~ ^[0-9]+$ ]] && echo "Please enter a valid number" && exit 1
fi
CPUS=${CPUS:-"2"}

read -p "Enter container name: " NAME
NAME=${NAME:-"minecraft"}

read -p "Enter port number (default is 25565): " PORT
if [ ! -z "$PORT" ]; then
    [[ ! $PORT =~ ^[0-9]+$ ]] && echo "Please enter a valid port number" && exit 1
fi
PORT=${PORT:-"25565"}

read -p "Enter data directory (default is /data): " DATADIR
DATADIR=${DATADIR:-"~/MinecraftData/data"}

read -p "Enter server name (default is MinecraftServer): " SERVER_NAME
SERVER_NAME=${SERVER_NAME:-"MinecraftServer"}

read -p "Enter Minecraft version (format: x.xx or x.xx.x, press enter to skip): " VERSION
if [ ! -z "$VERSION" ]; then
    if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Invalid version format. Use x.xx or x.xx.x (e.g., 1.19 or 1.19.2)"
        exit 1
    fi
fi

read -p "Enable hardcore mode? (yes/no, default: no): " HARDCORE_INPUT
if [[ "${HARDCORE_INPUT,,}" == "yes" ]]; then
    HARDCORE="true"
else
    HARDCORE="false"
fi


read -p "Enter Modpack.zip url (optional): " MODPACK_URL

if [ ! -z "$MODPACK_URL" ]; then
    read -p "Enter Modpack name (e.g., atm8, ftb): " MODPACK_NAME
    while [ -z "$MODPACK_NAME" ]; do
        echo "Modpack name is required when URL is provided"
        read -p "Enter Modpack name: " MODPACK_NAME
    done
fi


# Create .env file with all values (they now all have defaults)
> .env
echo "MEMORY=$MEMORY" >> .env
echo "CPUS=$CPUS" >> .env
echo "NAME=$NAME" >> .env
echo "PORT=$PORT" >> .env
echo "DATADIR=$DATADIR" >> .env
echo "SNOOPER_ENABLED=false" >> .env
echo "ALLOW_FLIGHT=true" >> .env
echo "SERVER_NAME=$SERVER_NAME" >> .env
echo "HARDCORE=$HARDCORE" >> .env
[ ! -z "$MODPACK_NAME" ] && echo "MODPACK_NAME=$MODPACK_NAME" >> .env
[ ! -z "$MINECRAFT_VERSION" ] && echo "MINECRAFT_VERSION=$MINECRAFT_VERSION" >> .env

# Download modpack only if URL is provided
if [ ! -z "$MODPACK_URL" ]; then
    mkdir -p downloads
    curl -o "downloads/${MODPACK_NAME}.zip" "$MODPACK_URL"
fi

docker compose up -d