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
EXPORTER_TAR_FILE="gl-exporter.tar.gz"
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

# Build Docker image
echo "Building Docker image for gl-exporter..."
cd "$EXPORTER_DIR"
docker build -t gl-exporter:1.7.1 .

# Run the exporter tool
echo "Running GitLab exporter..."
docker run --rm \
  -e GITLAB_API_ENDPOINT="$GITLAB_API_ENDPOINT" \
  -e GITLAB_USERNAME="$GITLAB_USERNAME" \
  -e GITLAB_TOKEN="$GITLAB_TOKEN" \
  -v "$PWD/output:/output" \
  gl-exporter:1.7.1 \
  ./exe/gl-exporter --namespace "$NAMESPACE" --project "$PROJECT_NAME" -o /output/migration_archive.tar.gz

echo "Export completed. Archive stored in ./output/migration_archive.tar.gz."
