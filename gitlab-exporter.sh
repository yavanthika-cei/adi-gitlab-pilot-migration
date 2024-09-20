#!/bin/bash

# Exit on error
set -e

# Check if necessary environment variables are set
if [[ -z "$GITLAB_TOKEN" || -z "$PROJECT_NAME" || -z "$NAMESPACE" ]]; then
  echo "Error: Missing environment variables."
  exit 1
fi

# Define variables
EXPORTER_TAR_URL="https://github.com/yavanthika-cei/adi-gitlab-pilot-migration/raw/main/gl-exporter-1.7.1.tar.gz"
EXPORTER_TAR_FILE="gl-exporter-1.7.1.tar.gz"
EXPORTER_DIR="gl-exporter-1.7.1"

# Download the .tar.gz file from GitHub if it doesn't exist
if [[ ! -f "$EXPORTER_TAR_FILE" ]]; then
  echo "Downloading gl-exporter from $EXPORTER_TAR_URL..."
  curl -L -o "$EXPORTER_TAR_FILE" "$EXPORTER_TAR_URL"
else
  echo "Exporter already downloaded."
fi

# Extract the .tar.gz file
if [[ ! -d "$EXPORTER_DIR" ]]; then
  echo "Extracting the gl-exporter..."
  tar -xvzf "$EXPORTER_TAR_FILE"
else
  echo "Exporter already extracted."
fi

# Run the exporter tool
cd "$EXPORTER_DIR"
./gl-exporter --project "$NAMESPACE/$PROJECT_NAME" --token "$GITLAB_TOKEN"

echo "Export completed."
