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

# Loop through each line in the CSV file
echo "Exporting projects listed in '$CSV_FILE'..."
while IFS=',' read -r namespace project_name; do
  echo "Exporting $namespace/$project_name..."
  
  docker run --rm \
    -e GITLAB_API_ENDPOINT="$GITLAB_API_ENDPOINT" \
    -e GITLAB_USERNAME="$GITLAB_USERNAME" \
    -e GITLAB_API_PRIVATE_TOKEN="$GITLAB_API_PRIVATE_TOKEN" \
    -e GITLAB_TOKEN="$GITLAB_TOKEN" \
    -v "$PWD/../output:/output" \
    -w /gl-exporter/exe \
    gl-exporter:1.7.1 \
    ./gl_exporter -n "$namespace" -p "$project_name" -o /output/"${namespace}_${project_name}_archive.tar.gz"
done < "$CSV_FILE"

echo "Export completed. Archives stored in the ./output/ directory."
