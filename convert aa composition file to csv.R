# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# The first argument is the input file, the second argument is the output file
input_file <- args[1]
output_file <- args[2]

# You can then use these variables in your script
# For example, to read a CSV file into a data frame:
# data <- read.csv(input_file)

# And to write a data frame to a CSV file:
# write.csv(data, output_file)


#read aa composition calculation result file in R
content <- readLines(input_file)

# Initialize empty vectors to store the parsed data
IDs <- c()
Ala_freq <- Arg_freq <- Asn_freq <- Asp_freq <- Cys_freq <- Gln_freq <- Glu_freq <- Gly_freq <- His_freq <- Ile_freq <- Leu_freq <- Lys_freq <- Met_freq <- Phe_freq <- Pro_freq <- Ser_freq <- Thr_freq <- Trp_freq <- Tyr_freq <- Val_freq <- c()
mol_weight <- c()
pI <- c()
num_acidic_residues <- c()
num_basic_residues <- c()

# Iterate through the lines and parse the values
for (i in seq_along(content)) {
  line <- content[i]
  
  if (startsWith(line, "ID: ")) {
    IDs <- append(IDs, sub("ID: ", "", line))
  } else if (startsWith(line, "Molecular weight: ")) {
    mol_weight <- append(mol_weight, as.numeric(sub("Molecular weight: ", "", line)))
  } else if (startsWith(line, "Amino acid composition: ")) {
    composition_str <- gsub("['{}]", "", sub("Amino acid composition: ", "", line))
    composition <- strsplit(composition_str, ", ")[[1]]
    composition <- setNames(as.numeric(sub(".*: ", "", composition)), sub(":.*", "", composition))
    Ala_freq <- append(Ala_freq, composition["A"])
    Arg_freq <- append(Arg_freq, composition["R"])
    Asn_freq <- append(Asn_freq, composition["N"])
    Asp_freq <- append(Asp_freq, composition["D"])
    Cys_freq <- append(Cys_freq, composition["C"])
    Gln_freq <- append(Gln_freq, composition["Q"])
    Glu_freq <- append(Glu_freq, composition["E"])
    Gly_freq <- append(Gly_freq, composition["G"])
    His_freq <- append(His_freq, composition["H"])
    Ile_freq <- append(Ile_freq, composition["I"])
    Leu_freq <- append(Leu_freq, composition["L"])
    Lys_freq <- append(Lys_freq, composition["K"])
    Met_freq <- append(Met_freq, composition["M"])
    Phe_freq <- append(Phe_freq, composition["F"])
    Pro_freq <- append(Pro_freq, composition["P"])
    Ser_freq <- append(Ser_freq, composition["S"])
    Thr_freq <- append(Thr_freq, composition["T"])
    Trp_freq <- append(Trp_freq, composition["W"])
    Tyr_freq <- append(Tyr_freq, composition["Y"])
    Val_freq <- append(Val_freq, composition["V"])
  } else if (startsWith(line, "Isoelectric point: ")) {
    pI <- append(pI, as.numeric(sub("Isoelectric point: ", "", line)))
  } else if (startsWith(line, "Number of acidic amino acids: ")) {
    num_acidic_residues <- append(num_acidic_residues, as.integer(sub("Number of acidic amino acids: ", "", line)))
  } else if (startsWith(line, "Number of basic amino acids: ")) {
    num_basic_residues <- append(num_basic_residues, as.integer(sub("Number of basic amino acids: ", "", line)))
  }
}

# Create the data frame
data <- data.frame(
  ID = IDs,
  Ala_freq = Ala_freq, Arg_freq = Arg_freq, Asn_freq = Asn_freq, Asp_freq = Asp_freq, Cys_freq = Cys_freq,
  Gln_freq = Gln_freq, Glu_freq = Glu_freq, Gly_freq = Gly_freq, His_freq = His_freq, Ile_freq = Ile_freq,
  Leu_freq = Leu_freq, Lys_freq = Lys_freq, Met_freq = Met_freq, Phe_freq = Phe_freq, Pro_freq = Pro_freq,
  Ser_freq = Ser_freq, Thr_freq = Thr_freq, Trp_freq = Trp_freq, Tyr_freq = Tyr_freq, Val_freq = Val_freq,
  mol_weight = mol_weight,
  pI = pI,
  num_acidic_residues = num_acidic_residues,
  num_basic_residues = num_basic_residues
)

# Sort the data frame by 'ID'
data <- data[order(data$ID), ]

# Write the data frame to a csv for your convenience
write.csv(data, file = output_file)