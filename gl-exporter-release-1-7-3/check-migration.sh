#!/bin/bash

# GitHub API token
GITHUB_TOKEN=$(gh auth token)
GITHUB_API_URL="https://api.github.com"
ORG_NAME="adi-innersource"

# Input CSV file
input_file="projects.csv"

# Function to check if a GitHub repository exists
check_repo_exists() {
  local repo_name=$1
  gh repo view "$ORG_NAME/$repo_name" --json name --jq .name > /dev/null 2>&1
  return $?
}

# Function to rename a GitHub repository
rename_repo() {
  local old_name=$1
  local new_name=$2
  gh repo rename --repo "$ORG_NAME/$old_name" "$new_name" --yes
}

# Function to add topics to a GitHub repository
add_topics() {
  local repo_name=$1
  local topics=$2
  gh repo edit "$ORG_NAME/$repo_name" --add-topic "$topics"
}

# Read the input file line by line
while IFS=, read -r namespace repo_path; do
  # Extract the repository name
  repo_name=$(echo "$repo_path" | awk -F'/' '{print $NF}' | tr -d '"')

  echo $repo_name

  # Check if the repository exists on GitHub
  if ! check_repo_exists "$repo_name"; then
    echo "Repository $repo_name does not exist on GitHub."
  else
    echo "Repository $repo_name exists on GitHub."
    # Rename the repository by prefixing with cai-
    new_repo_name="cai-$repo_name"
    rename_repo "$repo_name" "$new_repo_name"
    echo "Renamed $repo_name to $new_repo_name."

    # Add topics to the repository
    topics="ai-solutions,infrastructure"  # Replace with actual topics
    add_topics "$new_repo_name" "$topics"
    echo "Added topics to $new_repo_name."
  fi
done < "$input_file"

echo "Processing completed."