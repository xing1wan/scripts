import sys
import os
import csv

if len(sys.argv) != 3:
    print("Usage: python ss2csv.py <input_directory> <output.csv>")
    sys.exit(1)

input_dir = sys.argv[1]  # Input directory containing only .ss2 files
output_file = sys.argv[2]  # Output .csv file

# Open output CSV file
with open(output_file, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(['laccase', 'coil', 'helix', 'strand'])  # Write header

    # Loop through all files in the input directory
    for filename in os.listdir(input_dir):
        if filename.endswith(".ss2"):
            filepath = os.path.join(input_dir, filename)

            # Initialize counts for each file
            total_count = 0
            coil_count = 0
            helix_count = 0
            strand_count = 0
            fasta_prompt = ""

            # Open and read the .ss2 file
            with open(filepath, 'r') as f:
                for line in f:
                    if line.startswith("# PSIPRED VFORMAT"):
                        fasta_prompt = next(f).strip()
                        continue
                    elif line.startswith("#"):
                        continue

                    total_count += 1
                    tokens = line.split()
                    ss_type = tokens[2]

                    if ss_type == 'C':
                        coil_count += 1
                    elif ss_type == 'H':
                        helix_count += 1
                    elif ss_type == 'E':
                        strand_count += 1

            # Calculate the percentages and write to the CSV file
            coil_percent = (coil_count / total_count) * 100
            helix_percent = (helix_count / total_count) * 100
            strand_percent = (strand_count / total_count) * 100
            fasta_prompt = os.path.basename(filename).replace('.ss2', '')

            writer.writerow([fasta_prompt, f"{coil_percent:.2f}%", f"{helix_percent:.2f}%", f"{strand_percent:.2f}%"])

#print(f"Results written to {output_file}")

