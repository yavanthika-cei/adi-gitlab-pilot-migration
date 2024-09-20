#!/bin/bash

# Exit on error
set -e

# Check if necessary environment variables are set
if [[ -z "$GITLAB_TOKEN" || -z "$PROJECT_NAME" || -z "$NAMESPACE" ]]; then
  echo "Error: Missing environment variables."
  exit 1
fi

# Define variables
EXPORTER_DIR="gl-exporter-1.7.1"

# Check if the gl-exporter directory exists
if [[ ! -d "$EXPORTER_DIR" ]]; then
  echo "Error: Directory $EXPORTER_DIR does not exist."
  exit 1
fi

# Build Docker image
echo "Building Docker image for gl-exporter..."
cd "$EXPORTER_DIR"
docker build -t gl-exporter:1.7.1 .

# Run the exporter tool
echo "Running GitLab exporter..."
echo "Running command: docker run ... (complete command here)"
docker run --rm \
  -e GITLAB_API_ENDPOINT="$GITLAB_API_ENDPOINT" \
  -e GITLAB_USERNAME="$GITLAB_USERNAME" \
  -e GITLAB_API_PRIVATE_TOKEN="$GITLAB_API_PRIVATE_TOKEN" \
  -e GITLAB_TOKEN="$GITLAB_TOKEN" \
  -v "$PWD/../output:/output" \  # Ensure to go back one directory to access output
  -w /gl-exporter/exe \
  gl-exporter:1.7.1 \
  ./gl_exporter --namespace "$NAMESPACE" --project "$PROJECT_NAME" -o /output/migration_archive.tar.gz

echo "Export completed. Archive stored in ./output/migration_archive.tar.gz."
