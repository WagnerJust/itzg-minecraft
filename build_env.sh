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
CF_API_KEY=""
CF_PAGE_URL=""
CF_FILENAME_MATCHER=""

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

read -p "Enter server type (VANILLA, FORGE, FABRIC, NEOFORGE, AUTO_CURSEFORGE default is VANILLA): " TYPE
TYPE=${TYPE:-"VANILLA"}

if [ "$TYPE" == "AUTO_CURSEFORGE" ]; then
    read -p "Enter CurseForge API Key: " CF_API_KEY
    while [ -z "$CF_API_KEY" ]; do
        echo "CurseForge API Key is required for AUTO_CURSEFORGE"
        read -p "Enter CurseForge API Key: " CF_API_KEY
    done

    read -p "Enter CurseForge Project Page URL: " CF_PAGE_URL
    while [ -z "$CF_PAGE_URL" ]; do
        echo "CurseForge Project Page URL is required"
        read -p "Enter CurseForge Project Page URL: " CF_PAGE_URL
    done

    read -p "Enter filename matcher pattern (e.g., 'server'): " CF_FILENAME_MATCHER
    while [ -z "$CF_FILENAME_MATCHER" ]; do
        echo "Filename matcher pattern is required"
        read -p "Enter filename matcher pattern: " CF_FILENAME_MATCHER
    done
fi

# Add modpack handling
MODPACK_URL=""
MODPACK_NAME=""
MODPACK_PATH=""
if [[ "$TYPE" == "FORGE" || "$TYPE" == "FABRIC" || "$TYPE" == "NEOFORGE" ]]; then
    read -p "Enter Modpack path (local path) or URL: " MODPACK_INPUT
    if [ ! -z "$MODPACK_INPUT" ]; then
        mkdir -p downloads
        read -p "Enter Modpack name: " MODPACK_NAME
        while [ -z "$MODPACK_NAME" ]; do
            echo "Modpack name is required"
            read -p "Enter Modpack name: " MODPACK_NAME
        done

        # Check if input is a URL or local path
        if [[ "$MODPACK_INPUT" =~ ^https?:// ]]; then
            # Handle URL
            echo "Downloading modpack to downloads/${MODPACK_NAME}.zip"
            curl -L -o "downloads/${MODPACK_NAME}.zip" "$MODPACK_INPUT"
            if file "downloads/${MODPACK_NAME}.zip" | grep -q "HTML"; then
                echo "The downloaded file is not a valid zip file. Please check the URL and try again."
                rm "downloads/${MODPACK_NAME}.zip"
                exit 1
            fi
        else
            # Handle local path
            if [ ! -f "$MODPACK_INPUT" ]; then
                echo "Local file does not exist: $MODPACK_INPUT"
                exit 1
            fi
            echo "Copying modpack to downloads/$MODPACK_NAME"
            cp "$MODPACK_INPUT" "downloads/$MODPACK_NAME"
        fi

        if ! zipinfo -t "downloads/${MODPACK_NAME}.zip" > /dev/null; then
            echo "The downloaded file is not a valid zip file. Please check the URL and try again."
            rm "downloads/${MODPACK_NAME}.zip"
            exit 1
        fi
        MODPACK_PATH="downloads/$MODPACK_NAME"
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
CF_API_KEY='$CF_API_KEY'
CF_PAGE_URL=$CF_PAGE_URL
CF_FILENAME_MATCHER=$CF_FILENAME_MATCHER
EOL

# Add modpack-specific variables only for FORGE, FABRIC, or NEOFORGE
if [[ "$TYPE" == "FORGE" || "$TYPE" == "FABRIC" || "$TYPE" == "NEOFORGE" ]]; then
    cat >> .env << EOL
GENERIC_PACK="$MODPACK_PATH"
USE_MODPACK_START_SCRIPT="false"
REMOVE_OLD_MODS="false"
SKIP_GENERIC_PACK_UPDATE_CHECK="true"
EOL
fi

# Allow additional environment variables
read -p "Enter additional environment variables (format: VAR1=value1 VAR2=value2): " ADDITIONAL_VARS
if [ ! -z "$ADDITIONAL_VARS" ]; then
    echo "" >> .env  # Add blank line for readability
    echo "# Additional custom variables" >> .env
    echo "$ADDITIONAL_VARS" | tr ' ' '\n' >> .env
fi