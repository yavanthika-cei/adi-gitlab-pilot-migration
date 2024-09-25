#!/bin/bash

# Exit on error
set -e

# Check if the input CSV file exists
CSV_FILE="output/export_list.csv"
if [[ ! -f "$CSV_FILE" ]]; then
  echo "Error: CSV file '$CSV_FILE' does not exist."
  exit 1
fi

# Define variables
EXPORTER_DIR="gl-exporter-release-1-7-3"

# Check if the gl-exporter directory exists
if [[ ! -d "$EXPORTER_DIR" ]]; then
  echo "Error: Directory $EXPORTER_DIR does not exist."
  exit 1
fi

# Build Docker image
echo "Building Docker image for gl-exporter..."
cd "$EXPORTER_DIR"
docker build -t gl-exporter:1.7.3 .

# Debug: Check if output directory exists and list files
if [[ -d "$PWD/../output" ]]; then
  echo "Output directory found:"
  ls -la "$PWD/../output"
else
  echo "Output directory not found, creating..."
  mkdir -p "$PWD/../output"
fi

# Run the exporter tool using the CSV file
echo "Exporting projects listed in '$CSV_FILE'..."
docker run --rm \
  -e GITLAB_API_ENDPOINT="$GITLAB_API_ENDPOINT" \
  -e GITLAB_USERNAME="$GITLAB_USERNAME" \
  -e GITLAB_API_PRIVATE_TOKEN="$GITLAB_API_PRIVATE_TOKEN" \
  -e GITLAB_TOKEN="$GITLAB_TOKEN" \
  -v "$PWD/../output:/output" \
  -w /gl-exporter/exe \
  gl-exporter:1.7.3 \
  ./gl_exporter -f /output/export_list.csv -o /output/migration_archive.tar.gz

echo "Export completed. Archive stored in ./output/migration_archive.tar.gz."
