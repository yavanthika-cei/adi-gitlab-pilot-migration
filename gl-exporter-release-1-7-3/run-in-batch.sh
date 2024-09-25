#!/bin/bash

input_file="projects-csv.csv"
batch_size=2
counter=0
batch_counter=1

# Create a temporary directory for batch files
temp_dir=$(mktemp -d)

# Read the input file line by line
while IFS= read -r line; do
  # Add the line to the current batch file
  echo "$line" >> "$temp_dir/batch_$batch_counter.csv"
  counter=$((counter + 1))

  # If the batch size is reached, run the command and reset the counter
  if [ $counter -eq $batch_size ]; then
    ./exe/gl_exporter --out-file "infrastructure$batch_counter.tar.gz" -f "$temp_dir/batch_$batch_counter.csv" --lock-projects=false
    counter=0
    batch_counter=$((batch_counter + 1))
  fi
done < "$input_file"

# Run the command for the last batch if it has fewer than 5 projects
if [ $counter -ne 0 ]; then
  ./exe/gl_exporter --out-file "infrastructure$batch_counter.tar.gz" -f "$temp_dir/batch_$batch_counter.csv" --lock-projects=false
fi

# Clean up the temporary directory
rm -r "$temp_dir"

echo "Commands executed for all batches."