#!/bin/bash

# Initialize variables
INIT_MEMORY=""
MAX_MEMORY=""
PORT=""
DATADIR=""
SERVER_NAME=""
VERSION=""
TYPE=""
ENABLE_RCON=""
RCON_PASSWORD=""
RCON_PORT=""
OPS_LIST=""

# Get user inputs with validation
read -p "Enter initial memory allocation (default is 2G): " INIT_MEMORY
INIT_MEMORY=${INIT_MEMORY:-"2G"}

read -p "Enter maximum memory allocation (default is 4G): " MAX_MEMORY
MAX_MEMORY=${MAX_MEMORY:-"4G"}

read -p "Enter port number (default is 25565): " PORT
PORT=${PORT:-"25565"}

read -p "Enter data directory (default is ~/Minecraft/data): " DATADIR
DATADIR=${DATADIR:-"~/Minecraft/data"}

read -p "Enter server name (default is MinecraftServer): " SERVER_NAME
SERVER_NAME=${SERVER_NAME:-"MinecraftServer"}

read -p "Enter Minecraft version (format: x.xx or x.xx.x, press enter for latest): " VERSION
if [ ! -z "$VERSION" ]; then
    if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Invalid version format. Use x.xx or x.xx.x (e.g., 1.19 or 1.19.2)"
        exit 1
    fi
fi

read -p "Enter server type (VANILLA, FORGE, FABRIC, NEOFORGE, default is VANILLA): " TYPE
TYPE=${TYPE:-"VANILLA"}

# Add modpack handling
MODPACK_URL=""
MODPACK_NAME=""

if [[ "$TYPE" == "FORGE" || "$TYPE" == "FABRIC" || "$TYPE" == "NEOFORGE" ]]; then
    read -p "Enter Modpack URL (optional): " MODPACK_URL
    if [ ! -z "$MODPACK_URL" ]; then
        read -p "Enter Modpack name: " MODPACK_NAME
        while [ -z "$MODPACK_NAME" ]; do
            echo "Modpack name is required when URL is provided"
            read -p "Enter Modpack name: " MODPACK_NAME
        done
        
        echo "Downloading modpack to downloads/${MODPACK_NAME}.zip"
        mkdir -p downloads
        curl -L -o "downloads/${MODPACK_NAME}.zip" "$MODPACK_URL"
        if file "downloads/${MODPACK_NAME}.zip" | grep -q "HTML"; then
            echo "The downloaded file is not a valid zip file. Please check the URL and try again."
            rm "downloads/${MODPACK_NAME}.zip"
            exit 1
        fi
    fi
fi

read -p "Enable RCON? (yes/no, default: no): " ENABLE_RCON_INPUT
if [[ "${ENABLE_RCON_INPUT,,}" == "yes" ]]; then
    ENABLE_RCON="true"
    read -p "Enter RCON password: " RCON_PASSWORD
    read -p "Enter RCON port (default 25575): " RCON_PORT
    RCON_PORT=${RCON_PORT:-"25575"}
else
    ENABLE_RCON="false"
    RCON_PASSWORD=""
    RCON_PORT="25575"
fi

read -p "Enter operator usernames (comma-separated, press enter to skip): " OPS_LIST

# Remove existing .env file if it exists
rm -f .env

# Create .env file
cat > .env << EOL
INIT_MEMORY=$INIT_MEMORY
MAX_MEMORY=$MAX_MEMORY
PORT=$PORT
DATADIR=$DATADIR
SERVER_NAME=$SERVER_NAME
VERSION=${VERSION}
TYPE=$TYPE
ENABLE_RCON=$ENABLE_RCON
RCON_PASSWORD=$RCON_PASSWORD
RCON_PORT=$RCON_PORT
OPS_LIST=$OPS_LIST
MODPACK_NAME=$MODPACK_NAME
EOL

# Start the server
docker compose up -d