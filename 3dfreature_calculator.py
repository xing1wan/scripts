import argparse
from Bio.PDB import PDBParser
from Bio.PDB.DSSP import DSSP
import MDAnalysis as mda
import numpy as np

def main(pdb_file, output_file):
    # Read the PDB file
    parser = PDBParser()
    structure = parser.get_structure("protein", pdb_file)

    # Calculate principal components
    u = mda.Universe(pdb_file)
    protein = u.select_atoms("protein and name CA")
    coordinates = protein.positions
    mean_coordinates = np.mean(coordinates, axis=0)
    centered_coordinates = coordinates - mean_coordinates
    cov_matrix = np.cov(centered_coordinates.T)
    eigenvalues, eigenvectors = np.linalg.eig(cov_matrix)
    principal_components = eigenvectors[:, :3]  # First three principal components

    # Calculate torsion angles
    model = structure[0]
    dssp = DSSP(model, pdb_file)

    phi_angles = []
    psi_angles = []

    for residue in dssp:
        _, _, _, _, _, phi, psi, *_ = residue
        phi_angles.append(phi)
        psi_angles.append(psi)

    # Save the results to the output file
    with open(output_file, "w") as f:
        f.write("Principal Components:\n")
        f.write(str(principal_components) + "\n\n")
        f.write("Phi angles:\n")
        f.write(str(phi_angles) + "\n\n")
        f.write("Psi angles:\n")
        f.write(str(psi_angles))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate features from a PDB file.")
    parser.add_argument("-i", "--input", required=True, help="Input PDB file.")
    parser.add_argument("-o", "--output", required=True, help="Output file to save the results.")
    args = parser.parse_args()

    main(args.input, args.output)
