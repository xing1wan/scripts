import argparse
from Bio import AlignIO
import csv

def extract_specified_amino_acids(alignment_file, positions):
    # Read the alignment
    alignment = AlignIO.read(alignment_file, "fasta")

    # Dictionary to store the extracted amino acids for each sequence
    extracted_amino_acids = {}

    # For each record in the alignment
    for record in alignment:
        residues = "".join([record.seq[pos] for pos in positions])
        extracted_amino_acids[record.id] = residues

    return extracted_amino_acids

def save_to_fasta(data_dict, output_filename):
    with open(output_filename, 'w') as out_file:
        # Write the data
        for key, value in data_dict.items():
            out_file.write(f">{key}\n")
            out_file.write(f"{value}\n")

if __name__ == "__main__":
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Extract specified amino acids from a multi FASTA alignment(MSA) and save to CSV")
    parser.add_argument("-i", "--input", required=True, help="Path to the input FASTA alignment file")
    parser.add_argument("-o", "--output", required=True, help="Path to the output CSV file")
    args = parser.parse_args()

def input_sbs_positions():
    positions = []
    print("Enter the SBS positions (0-based indexing). Type 'end' to finish:")

    while True:
        position = input("Position (or type 'end' to finish): ")

        if position.isdigit():
            positions.append(int(position))
        elif position.lower() == 'end':
            break
        else:
            print("Invalid input. Please enter a numeric position or type 'end' to finish.")

    return positions

def input_multiple_sbs_positions():
    positions = []
    print("Enter the SBS positions (0-based indexing). Separate multiple positions with commas. End with 'x' or 'end' to finish:")

    while True:
        position_input = input("Positions (e.g., '162, 311, 481, 487x' where x to end current input or type 'end' to finish): ")

        if 'end' in position_input.lower():
            break

        # Split the positions based on commas
        individual_positions = position_input.strip('x').split(',')

        for pos in individual_positions:
            if pos.strip().isdigit():
                positions.append(int(pos.strip()))
            else:
                print(f"Invalid input '{pos.strip()}'. Please enter only numeric positions.")

        if position_input.endswith('x'):
            break

    return sorted(list(set(positions)))


# Ask the user if they want to manually input the positions
choice = input("Do you want to manually input SBS positions? (yes/no): ")

if choice.lower() == 'yes' or choice.lower() == 'y':
    positions = input_multiple_sbs_positions()
    print(f"Using positions '{positions}'")
    if not positions:  # Check if positions is empty
        print("No valid positions were inputted. Using default positions.")
        positions = [685,691,694,708,840,841,856,1157,1173,1180,1998,2063,2065,2083,2090,2207,2210,2273,2550,2618,2619,2629,2630,26$
else:
    # Use default positions
    positions = [685,691,694,708,840,841,856,1157,1173,1180,1998,2063,2065,2083,2090,2207,2210,2273,2550,2618,2619,2629,2630,2639,2$

# Extract amino acids
amino_acids_dict = extract_specified_amino_acids(args.input, positions)

# Save to fasta
save_to_fasta(amino_acids_dict, args.output)
