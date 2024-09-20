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

# Build the Docker image from the Dockerfile
echo "Building Docker image for gl-exporter..."
docker build -t gl-exporter:1.7.1 "$EXPORTER_DIR"

# Run the exporter tool in Docker
echo "Running GitLab exporter..."
docker run --rm \
  -e GITLAB_TOKEN="$GITLAB_TOKEN" \
  -e PROJECT_NAME="$PROJECT_NAME" \
  -e NAMESPACE="$NAMESPACE" \
  -v "$(pwd)/output:/output" \
  gl-exporter:1.7.1 \
  ./gl-exporter --namespace "$NAMESPACE" --project "$PROJECT_NAME" -o /output/migration_archive.tar.gz

echo "Export completed."
