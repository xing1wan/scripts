import argparse
from Bio.PDB import PDBParser
from Bio.PDB.DSSP import DSSP
import os

def compute_secondary_structure_percentage(pdb_file):
    # Read the PDB file
    parser = PDBParser()
    structure = parser.get_structure("protein", pdb_file)

    # Calculate DSSP
    model = structure[0]
    dssp = DSSP(model, pdb_file)

    # Extract secondary structure elements
    secondary_structures = [residue[2] for residue in dssp]
    total_residues = len(secondary_structures)

    # Count elements
    alpha_helix_count = secondary_structures.count('H')
    beta_strand_count = secondary_structures.count('E')
    coil_count = secondary_structures.count('-')

    # Calculate percentages
    alpha_helix_percent = (alpha_helix_count / total_residues) * 100
    beta_strand_percent = (beta_strand_count / total_residues) * 100
    coil_percent = (coil_count / total_residues) * 100

    return alpha_helix_percent, beta_strand_percent, coil_percent

def main():
    parser = argparse.ArgumentParser(description="Calculate secondary structure percentages from PDB files in a directory.")
    parser.add_argument("directory", help="Directory containing the PDB files.")
    parser.add_argument("output", help="Output CSV file.")
    args = parser.parse_args()

    # Get list of all .pdb files in the directory
    pdb_files = [f for f in os.listdir(args.directory) if f.endswith('.pdb')]

    # Prepare CSV
    with open(args.output, "w") as f:
        f.write("Protein,Alpha-Helix(%),Beta-Strand(%),Coil(%)\n")

        for pdb_file in pdb_files:
            full_path = os.path.join(args.directory, pdb_file)
            alpha_helix_percent, beta_strand_percent, coil_percent = compute_secondary_structure_percentage(full_path)

            f.write(f"{pdb_file},{alpha_helix_percent:.2f},{beta_strand_percent:.2f},{coil_percent:.2f}\n")

if __name__ == "__main__":
    main()
