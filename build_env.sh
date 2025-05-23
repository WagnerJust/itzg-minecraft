#!/bin/bash

# Get real user's home directory even when running with sudo
if [ ! -z "$SUDO_USER" ]; then
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_HOME=$HOME
fi

# Function to read existing value from .env file
get_env_value() {
    local var_name=$1
    if [ -f .env ]; then
        grep "^${var_name}=" .env | cut -d '=' -f2-
    fi
}

# Initialize variables with existing values if .env exists
INIT_MEMORY=$(get_env_value "INIT_MEMORY")
MAX_MEMORY=$(get_env_value "MAX_MEMORY")
PORT=$(get_env_value "PORT")
DATADIR=$(get_env_value "DATADIR")
SERVER_NAME=$(get_env_value "SERVER_NAME")
VERSION=$(get_env_value "VERSION")
TYPE=$(get_env_value "TYPE")
JAVA_VERSION=$(get_env_value "JAVA_VERSION")
ENABLE_RCON=$(get_env_value "ENABLE_RCON")
RCON_PASSWORD=$(get_env_value "RCON_PASSWORD")
RCON_PORT=$(get_env_value "RCON_PORT")
OPS_LIST=$(get_env_value "OPS_LIST")
CF_API_KEY=$(get_env_value "CF_API_KEY")
CF_PAGE_URL=$(get_env_value "CF_PAGE_URL")
CF_FILENAME_MATCHER=$(get_env_value "CF_FILENAME_MATCHER")
CPUS=$(get_env_value "CPUS")
FTB_MODPACK_ID=$(get_env_value "FTB_MODPACK_ID")
FTB_MODPACK_VERSION_ID=$(get_env_value "FTB_MODPACK_VERSION_ID")
FTB_FORCE_REINSTALL=$(get_env_value "FTB_FORCE_REINSTALL")

# Only prompt for values that aren't already set
[ -z "$CPUS" ] && read -p "Enter number of CPUs to use (default is 6): " CPUS
CPUS=${CPUS:-"6"}

[ -z "$INIT_MEMORY" ] && read -p "Enter initial memory allocation (default is 8G): " INIT_MEMORY
INIT_MEMORY=${INIT_MEMORY:-"8G"}

[ -z "$MAX_MEMORY" ] && read -p "Enter maximum memory allocation (default is 4G): " MAX_MEMORY
MAX_MEMORY=${MAX_MEMORY:-"10G"}

[ -z "$PORT" ] && read -p "Enter port number (default is 25565): " PORT
PORT=${PORT:-"25565"}

[ -z "$DATADIR" ] && read -p "Enter data directory (default is ~/Minecraft/data): " DATADIR
DATADIR=${DATADIR:-"~/Minecraft/data"}

[ -z "$SERVER_NAME" ] && read -p "Enter server name (default is MinecraftServer): " SERVER_NAME
SERVER_NAME=${SERVER_NAME:-"MinecraftServer"}

[ -z "$VERSION" ] && read -p "Enter Minecraft version (format: x.xx or x.xx.x, default is LATEST): " VERSION
VERSION=${VERSION:-"LATEST"}

if [ -z "$VERSION" ] || [ "$VERSION" != "$(get_env_value "VERSION")" ]; then
    if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ && "$VERSION" != "LATEST" ]]; then
        echo "Invalid version format. Use x.xx or x.xx.x (e.g., 1.19 or 1.19.2) or LATEST"
        exit 1
    fi
fi

# Only prompt for Java version if not already set
if [ -z "$JAVA_VERSION" ]; then
    read -p "Enter Java version (default is 21, or enter version like 8, 11, 17): " JAVA_VERSION
    JAVA_VERSION=${JAVA_VERSION:-"21"}
    JAVA_VERSION=${JAVA_VERSION}
    if ! [[ "$JAVA_VERSION" =~ ^[0-9]+$ ]]; then
        echo "Invalid Java version. Please use a number (e.g., 8, 11, 17, 21)"
        exit 1
    fi
    JAVA_VERSION=:java${JAVA_VERSION}

fi

[ -z "$TYPE" ] && read -p "Enter server type (VANILLA, FORGE, FABRIC, PAPER, NEOFORGE, FTBA, AUTO_CURSEFORGE default is PAPER): " TYPE
TYPE=${TYPE:-"PAPER"}

# Add Bedrock support option
ENABLE_BEDROCK=""
BEDROCK_PORT=""

if [[ "$TYPE" == "PAPER" ]]; then
    read -p "Enable Bedrock support? (yes/no, default: no): " ENABLE_BEDROCK_INPUT
    if [[ "${ENABLE_BEDROCK_INPUT,,}" == "yes" ]]; then
        ENABLE_BEDROCK="true"
        read -p "Enter Bedrock port number (default is 19132): " BEDROCK_PORT
        BEDROCK_PORT=${BEDROCK_PORT:-"19132"}
    fi
fi

# Add FTB-specific handling
FTB_MODPACK_ID=""
FTB_MODPACK_VERSION_ID=""
FTB_FORCE_REINSTALL="false"

if [ "$TYPE" == "FTBA" ]; then
    read -p "Enter FTB Modpack ID (required): " FTB_MODPACK_ID
    while [ -z "$FTB_MODPACK_ID" ] || ! [[ "$FTB_MODPACK_ID" =~ ^[0-9]+$ ]]; do
        echo "FTB Modpack ID is required and must be a number"
        read -p "Enter FTB Modpack ID: " FTB_MODPACK_ID
    done

    read -p "Enter FTB Modpack Version ID (optional, press enter for latest): " FTB_MODPACK_VERSION_ID
    if [ ! -z "$FTB_MODPACK_VERSION_ID" ] && ! [[ "$FTB_MODPACK_VERSION_ID" =~ ^[0-9]+$ ]]; then
        echo "FTB Modpack Version ID must be a number if specified"
        exit 1
    fi

    read -p "Force reinstall FTB? (yes/no, default: no): " FTB_FORCE_REINSTALL_INPUT
    if [[ "${FTB_FORCE_REINSTALL_INPUT,,}" == "yes" ]]; then
        FTB_FORCE_REINSTALL="true"
    fi
fi

if [ "$TYPE" == "AUTO_CURSEFORGE" ]; then
    read -p "Enter CurseForge API Key: " CF_API_KEY
    while [ -z "$CF_API_KEY" ]; do
        echo "CurseForge API Key is required for AUTO_CURSEFORGE"
        read -p "Enter CurseForge API Key: " CF_API_KEY
    done

    read -p "Enter CurseForge modpack URL (direct file URL): " CF_PAGE_URL
    while [ -z "$CF_PAGE_URL" ]; do
        echo "CurseForge modpack URL is required"
        read -p "Enter CurseForge modpack URL: " CF_PAGE_URL
    done
fi

# Add modpack handling
MODPACK_URL=""
MODPACK_NAME=""
MODPACK_PATH=""
if [[ "$TYPE" == "FORGE" || "$TYPE" == "FABRIC" || "$TYPE" == "NEOFORGE" ]]; then
    # Get version for the specific mod loader
    case "$TYPE" in
        "FORGE")
            read -p "Enter Forge version (e.g., 47.1.0): " FORGE_VERSION
            while [ -z "$FORGE_VERSION" ]; do
                echo "Forge version is required"
                read -p "Enter Forge version: " FORGE_VERSION
            done
            echo "FORGE_VERSION=$FORGE_VERSION" >> .env.tmp
            ;;
        "NEOFORGE")
            read -p "Enter NeoForge version (e.g., 20.2.86): " NEOFORGE_VERSION
            while [ -z "$NEOFORGE_VERSION" ]; do
                echo "NeoForge version is required"
                read -p "Enter NeoForge version: " NEOFORGE_VERSION
            done
            echo "NEOFORGE_VERSION=$NEOFORGE_VERSION" >> .env.tmp
            ;;
        "FABRIC")
            read -p "Enter Fabric Launcher version (optional, press enter to skip): " FABRIC_LAUNCHER_VERSION
            read -p "Enter Fabric Loader version (optional, press enter to skip): " FABRIC_LOADER_VERSION
            
            [ ! -z "$FABRIC_LAUNCHER_VERSION" ] && echo "FABRIC_LAUNCHER_VERSION=$FABRIC_LAUNCHER_VERSION" >> .env.tmp
            [ ! -z "$FABRIC_LOADER_VERSION" ] && echo "FABRIC_LOADER_VERSION=$FABRIC_LOADER_VERSION" >> .env.tmp
            ;;
    esac

    read -p "Enter Modpack path (local path) or URL: " MODPACK_INPUT
    if [ ! -z "$MODPACK_INPUT" ]; then
        mkdir -p downloads
        read -p "Enter Modpack name: " MODPACK_NAME
        while [ -z "$MODPACK_NAME" ]; do
            echo "Modpack name is required"
            read -p "Enter Modpack name: " MODPACK_NAME
        done
        MODPACK_NAME="${MODPACK_NAME}.zip"

        # Check if input is a URL or local path
        if [[ "$MODPACK_INPUT" =~ ^https?:// ]]; then
            # Handle URL
            echo "Downloading modpack to downloads/${MODPACK_NAME}"
            curl -L -o "downloads/${MODPACK_NAME}" "$MODPACK_INPUT"
            if file "downloads/${MODPACK_NAME}" | grep -q "HTML"; then
                echo "The downloaded file is not a valid zip file. Please check the URL and try again."
                rm "downloads/${MODPACK_NAME}"
                exit 1
            fi
        else
            # Handle local path - preserve original style but expand for checking
            EXPANDED_PATH="$MODPACK_INPUT"
            if [[ "$MODPACK_INPUT" =~ ^~ ]]; then
                EXPANDED_PATH="${MODPACK_INPUT/#\~/$REAL_HOME}"
            fi
            
            if [ ! -f "$EXPANDED_PATH" ]; then
                echo "Local file does not exist: $MODPACK_INPUT"
                exit 1
            fi
            echo "Copying modpack to downloads/$MODPACK_NAME"
            cp "$EXPANDED_PATH" "downloads/$MODPACK_NAME"
        fi

        if ! zipinfo -t "downloads/${MODPACK_NAME}" > /dev/null; then
            echo "The downloaded file is not a valid zip file. Please check the URL and try again."
            rm "downloads/${MODPACK_NAME}"
            exit 1
        fi
        MODPACK_PATH="downloads/$MODPACK_NAME"
    fi
fi

# Only prompt for RCON if not already configured
if [ -z "$ENABLE_RCON" ]; then
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
fi

[ -z "$OPS_LIST" ] && read -p "Enter operator usernames (comma-separated, press enter to skip): " OPS_LIST

# Create new .env file or update existing one
touch .env.tmp

# Write all variables to temporary file
cat > .env.tmp << EOL
INIT_MEMORY=$INIT_MEMORY
MAX_MEMORY=$MAX_MEMORY
PORT=$PORT
DATADIR=$DATADIR
SERVER_NAME=$SERVER_NAME
VERSION=$VERSION
TYPE=$TYPE
JAVA_VERSION=$JAVA_VERSION
ENABLE_RCON=$ENABLE_RCON
RCON_PASSWORD=$RCON_PASSWORD
RCON_PORT=$RCON_PORT
OPS_LIST=$OPS_LIST
CF_API_KEY=$CF_API_KEY
CF_PAGE_URL=$CF_PAGE_URL
CURSEFORGE_FILES=$CF_PAGE_URL
CPUS=$CPUS
ALLOW_FLIGHT="true"
EOL

# Add any additional variables that might exist in the old .env but weren't processed above
if [ -f .env ]; then
    while IFS= read -r line; do
        var_name=$(echo "$line" | cut -d'=' -f1)
        if ! grep -q "^${var_name}=" .env.tmp; then
            echo "$line" >> .env.tmp
        fi
    done < .env
fi

# Replace old .env with new one
mv .env.tmp .env

# Add Bedrock-specific variables if enabled
if [ "$ENABLE_BEDROCK" == "true" ]; then
    cat >> .env << EOL
BEDROCK_PORT=${BEDROCK_PORT}
PLUGINS=https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot, https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot, https://hangarcdn.papermc.io/plugins/ViaVersion/ViaVersion/versions/5.2.1/PAPER/ViaVersion-5.2.1.jar
EOL
fi

# Add modpack-specific variables only for FORGE, FABRIC, or NEOFORGE
if [[ "$TYPE" == "FORGE" || "$TYPE" == "FABRIC" || "$TYPE" == "NEOFORGE" ]]; then
    cat >> .env << EOL
GENERIC_PACK="/data/downloads/$MODPACK_NAME"
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