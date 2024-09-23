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

# Debug: Check if output directory exists and list files
if [[ -d "$PWD/../output" ]]; then
  echo "Output directory found:"
  ls -la "$PWD/../output"
else
  echo "Output directory not found, creating..."
  mkdir -p "$PWD/../output"
fi

# Process CSV file and handle errors
echo "Processing CSV file '$CSV_FILE'..."
while IFS=',' read -r namespace project_name; do
  if [[ -z "$namespace" || -z "$project_name" ]]; then
    echo "Skipping invalid entry: '$namespace','$project_name'"
    continue
  fi

  echo "Exporting project: Namespace='$namespace', Project='$project_name'"
  docker run --rm \
    -e GITLAB_API_ENDPOINT="$GITLAB_API_ENDPOINT" \
    -e GITLAB_USERNAME="$GITLAB_USERNAME" \
    -e GITLAB_API_PRIVATE_TOKEN="$GITLAB_API_PRIVATE_TOKEN" \
    -e GITLAB_TOKEN="$GITLAB_TOKEN" \
    -v "$PWD/../output:/output" \
    -w /gl-exporter/exe \
    gl-exporter:1.7.1 \
    ./gl_exporter -n "$namespace" -p "$project_name" -o "/output/$project_name-migration_archive.tar.gz"
done < "$CSV_FILE"

echo "Export completed. Check the output directory for the exported archives."
