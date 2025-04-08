#!/bin/bash

# Simple script to generate temporary SSH keys

# Set temporary directory for keys
TEMP_DIR="./temp_ssh_keys"

# Create the directory if it doesn't exist
mkdir -p $TEMP_DIR

# Generate a timestamp for unique naming
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Generate the key (Ed25519, no passphrase)
ssh-keygen -t ed25519 -N "" -f "$TEMP_DIR/temp_key_$TIMESTAMP"

echo "Temporary SSH keys generated:"
echo "  Private key: $TEMP_DIR/temp_key_$TIMESTAMP"
echo "  Public key:  $TEMP_DIR/temp_key_$TIMESTAMP.pub"