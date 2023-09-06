import argparse
from Bio import SeqIO
import csv

def fasta_to_csv(fasta_file, csv_file):
    with open(fasta_file, 'r') as fasta, open(csv_file, 'w', newline='') as csv_out:
        writer = csv.writer(csv_out)
        writer.writerow(['Header', 'Sequence'])  # Write header
        sequences = SeqIO.parse(fasta, 'fasta')
        for seq in sequences:
            writer.writerow([seq.id, str(seq.seq)])

# argparse setup
parser = argparse.ArgumentParser(description='Convert a FASTA file to CSV.')
parser.add_argument('-i', '--input', help='Input FASTA file', required=True)
parser.add_argument('-o', '--output', help='Output CSV file', required=True)
args = parser.parse_args()

fasta_to_csv(args.input, args.output)
