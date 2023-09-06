import sys
from Bio import SeqIO
from Bio.SeqUtils.ProtParam import ProteinAnalysis

if len(sys.argv) != 3:
    print("Usage: python3 aa_composition.py input.fasta output.txt")
    sys.exit(1)

input_fasta_file = sys.argv[1]
output_file = sys.argv[2]
results = []

# Read protein sequences from the FASTA file
with open(input_fasta_file, 'r') as fasta_file:
    for record in SeqIO.parse(fasta_file, 'fasta'):
        protein_sequence = str(record.seq)
        protein_sequence = protein_sequence.replace('X', '')  # remove 'X'

        analysis = ProteinAnalysis(protein_sequence)

        molecular_weight = analysis.molecular_weight()
        amino_acid_composition = analysis.get_amino_acids_percent()
        isoelectric_point = analysis.isoelectric_point()

        acidic_aa_count = analysis.count_amino_acids()['D'] + analysis.count_amino_acids()['E']
        basic_aa_count = analysis.count_amino_acids()['R'] + analysis.count_amino_acids()['H'] + analysis.count_amino_acids()['K']

        results.append({
            'id': record.id,
            'molecular_weight': molecular_weight,
            'amino_acid_composition': amino_acid_composition,
            'isoelectric_point': isoelectric_point,
            'acidic_aa_count': acidic_aa_count,
            'basic_aa_count': basic_aa_count
        })

# Write results for each protein to the output file
with open(output_file, 'w') as out_file:
    for result in results:
        out_file.write(f"ID: {result['id']}\n")
        out_file.write(f"Molecular weight: {result['molecular_weight']}\n")
        out_file.write(f"Amino acid composition: {result['amino_acid_composition']}\n")
        out_file.write(f"Isoelectric point: {result['isoelectric_point']}\n")
        out_file.write(f"Number of acidic amino acids: {result['acidic_aa_count']}\n")
        out_file.write(f"Number of basic amino acids: {result['basic_aa_count']}\n")
        out_file.write('\n')
