import sys
import csv
from Bio import SeqIO
from Bio.SeqUtils.ProtParam import ProteinAnalysis

valid_amino_acids = set('ACDEFGHIKLMNPQRSTVWY')  # Standard amino acids

if len(sys.argv) != 3:
    print("Usage: python3 aa2csv.py input.fasta output.csv")
    sys.exit(1)

input_fasta_file = sys.argv[1]
output_file = sys.argv[2]
results = []

try:
    with open(input_fasta_file, 'r') as fasta_file:
        for record in SeqIO.parse(fasta_file, 'fasta'):
            protein_sequence = ''.join(aa for aa in str(record.seq) if aa in valid_amino_acids)
            
            if not protein_sequence:
                continue
            
            analysis = ProteinAnalysis(protein_sequence)
            amino_acid_composition = analysis.get_amino_acids_percent()
            count_amino_acids = analysis.count_amino_acids()
            
            results.append({
                'id': record.id,
                'molecular_weight': analysis.molecular_weight(),
                'isoelectric_point': analysis.isoelectric_point(),
                
                'number_of_acidic_amino_acids': count_amino_acids['D'] + count_amino_acids['E'],
                'number_of_basic_amino_acids': count_amino_acids['R'] + count_amino_acids['H'] + count_amino_acids['K'],
                'number_of_polar_r_group': sum(count_amino_acids[aa] for aa in 'STCPNQ'),
                'number_of_nonpolar_aliphilic_r_group': sum(count_amino_acids[aa] for aa in 'GAVLMI'),
                'number_of_nonpolar_aromatic_r_group': sum(count_amino_acids[aa] for aa in 'FYW'),
                
                'frequency_of_r_group_negatively_charged_acids': sum(amino_acid_composition[aa] for aa in 'DE'),
                'frequency_of_r_group_positively_charged_acids': sum(amino_acid_composition[aa] for aa in 'KRH'),
                'frequency_of_polar_r_group': sum(amino_acid_composition[aa] for aa in 'STCPNQ'),
                'frequency_of_nonpolar_aliphilic_r_group': sum(amino_acid_composition[aa] for aa in 'GAVLMI'),
                'frequency_of_nonpolar_aromatic_r_group': sum(amino_acid_composition[aa] for aa in 'FYW'),
                
                **{f'{aa.lower()}_freq': amino_acid_composition.get(aa, 0) for aa in valid_amino_acids}  # Include individual amino acid compositions
            })

except FileNotFoundError:
    sys.exit(f"Error: {input_fasta_file} not found.")
except Exception as e:
    sys.exit(f"Error: {str(e)}")

# Write results for each protein to the output CSV file
try:
    with open(output_file, 'w', newline='') as out_file:
        fieldnames = ['id', 'molecular_weight', 'isoelectric_point', 'number_of_acidic_amino_acids', 'number_of_basic_amino_acids', 
                      'frequency_of_r_group_positively_charged_acids', 'frequency_of_r_group_negatively_charged_acids', 
                      'frequency_of_polar_r_group', 'frequency_of_nonpolar_aliphilic_r_group', 'frequency_of_nonpolar_aromatic_r_group'] \
                    + [f'{aa.lower()}_freq' for aa in valid_amino_acids]
        # uncomment to use, when calculating for different aspects 
        #fieldnames = ['id', 'number_of_acidic_amino_acids', 'number_of_basic_amino_acids', 'number_of_polar_r_group', 'number_of_nonpolar_aliphilic_r_group', 'number_of_nonpolar_aromatic_r$
        writer = csv.DictWriter(out_file, fieldnames=fieldnames)
        
        writer.writeheader()
        writer.writerows(results)
except Exception as e:
    sys.exit(f"Error writing to {output_file}: {str(e)}")
