#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input.csv> <output.fasta>"
  exit 1
fi

csv_file="$1"
fasta_file="$2"
tmp_file=$(mktemp)

# Convert CSV to FASTA format
awk -F, '{ print ">"$1"\n"$2 }' "$csv_file" > "$tmp_file"

# Remove leading/trailing whitespaces from FASTA entries
sed -i -e 's/^[[:blank:]]*//' -e 's/[[:blank:]]*$//' "$tmp_file"

# Move the temporary file to the desired output file
mv "$tmp_file" "$fasta_file"
