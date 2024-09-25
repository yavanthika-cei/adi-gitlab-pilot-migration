#!/bin/bash

# Usage: ./script.sh group_path

group_path=$1
ACCESS_TOKEN=$GITLAB_API_PRIVATE_TOKEN
GITLAB_API_URL="https://gitlab.analog.com/api/v4"

rm -Rf projects.csv

# Ensure group path is provided
if [ -z "$group_path" ]; then
  echo "Error: No group path provided."
  exit 1
fi

# URL encode the group path to handle slashes and special characters
encoded_group=$(echo "$group_path" | sed 's/\//%2f/g')

echo "Encoded Group Path: $encoded_group"

# Get group information to retrieve the group ID
group_info=$(curl --silent --header "Authorization: Bearer $ACCESS_TOKEN" "$GITLAB_API_URL/groups/$encoded_group")

# Extract the group ID from the response
group_id=$(echo $group_info | jq -r '.id')

# Extract the full namespace, root namespace, and subgroup path
full_namespace=$(echo $group_info | jq -r '.full_path')
root_namespace=$(echo $full_namespace | cut -d'/' -f1)
subgroup_path=$(echo $full_namespace | cut -d'/' -f2-)

# Check if the group ID was retrieved
if [ -z "$group_id" ] || [ "$group_id" == "null" ]; then
  echo "Error: Group not found or unauthorized."
  exit 1
fi

# Initialize pagination variables
page=1
per_page=100
total_pages=1

# Fetch projects under the given group or subgroup
while [ $page -le $total_pages ]; do
  projects=$(curl --silent --header "Authorization: Bearer $ACCESS_TOKEN" "$GITLAB_API_URL/groups/$group_id/projects?include_subgroups=true&per_page=$per_page&page=$page")

  # Check if projects are available
  if [ -z "$projects" ]; then
    echo "No projects found."
    exit 1
  fi

  # Iterate over the projects and append the project name and URL to the CSV
  echo "$projects" | jq -r --arg root "$root_namespace" --arg subgroup "$subgroup_path" '.[] | [$root, (.path_with_namespace | sub("^" + $root + "/"; ""))] | @csv' >> projects.csv

  # Get the total number of pages from the response headers
  total_pages=$(curl --head --silent --header "Authorization: Bearer $ACCESS_TOKEN" "$GITLAB_API_URL/groups/$group_id/projects?include_subgroups=true&per_page=$per_page&page=$page" | grep -i "x-total-pages" | awk '{print $2}' | tr -d '\r')

  # Increment the page counter
  page=$((page + 1))
done

echo "CSV output generated: projects.csv"