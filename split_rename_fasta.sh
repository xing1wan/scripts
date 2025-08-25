#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -i <input_file>"
    exit 1
}

# Parse command-line argument for input FASTA file
while getopts "i:" opt; do
    case $opt in
        i)
            input_fasta="$OPTARG"
            ;;
        \?)
            echo "Usage: $0 -i <input_fasta_file>"
            exit 1
            ;;
    esac
done

# Check if input_fasta is provided
if [ -z "$input_fasta" ]; then
    echo "Error: Input FASTA file must be specified with -i"
    echo "Usage: $0 -i <input_fasta_file>"
    exit 1
fi

# Check if input file exists
if [ ! -f "$input_fasta" ]; then
    echo "Error: Input file $input_fasta does not exist"
    exit 1
fi

output_dir="split_fasta"  # Directory for split FASTA files

# Create output directory if it doesn't exist
mkdir -p "${output_dir}"

# Split multifasta into individual files using seqkit
module load seqkit
seqkit split -i "${input_fasta}" -O "${output_dir}" --quiet

# Rename each split FASTA file based on its sequence header
for file in ${output_dir}/*.fasta; do
    # Extract the header (first line starting with '>')
    header=$(grep "^>" "${file}" | head -n 1 | sed 's/>//')
    # Clean the header to make it filesystem-friendly (replace spaces and special characters)
    clean_header=$(echo "${header}" | tr -d '\n' | tr ' ' '_' | tr -c '[:alnum:]_.-' '_')
    # Rename the file to the cleaned header
    mv "${file}" "${output_dir}/${clean_header}.fa"
done

echo "Job done!"