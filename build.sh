#!/bin/bash

# Initialize variables
MEMORY=""
CPUS=""
NAME=""
PORT=""
DATADIR=""

# Get user inputs with validation
while [ -z "$MEMORY" ]; do
    read -p "Enter memory allocation (e.g., 2G): " MEMORY
    [[ ! $MEMORY =~ ^[0-9]+[GM]$ ]] && echo "Invalid format. Use number followed by G or M" && MEMORY=""
done

while [ -z "$CPUS" ]; do
    read -p "Enter number of CPUs: " CPUS
    [[ ! $CPUS =~ ^[0-9]+$ ]] && echo "Please enter a valid number" && CPUS=""
done

while [ -z "$NAME" ]; do
    read -p "Enter container name: " NAME
done

while [ -z "$PORT" ]; do
    read -p "Enter port number (default is 25565): " PORT
    [[ ! $PORT =~ ^[0-9]+$ ]] && echo "Please enter a valid port number" && PORT=""
done

while [ -z "$DATADIR" ]; do
    read -p "Enter data directory: " DATADIR
done

# Save to .env file
cat > .env << EOL
MEMORY=$MEMORY
CPUS=$CPUS
NAME=$NAME
PORT=$PORT
DATADIR=$DATADIR
EOL

docker compose up --build -d