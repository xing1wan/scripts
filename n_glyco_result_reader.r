.libPaths(c("/scratch/project_2002833/softwares/R", .libPaths()))

library(stringr)

# Extract command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if the correct number of command-line arguments is provided
if (length(args) != 2) {
  cat("Usage: Rscript script.R input_file output_file\n")
  quit("no", 1)
}

# Read the input text file
input_file <- args[1]

text <- readLines(input_file)

# Initialize variables
start_index <- 0
end_index <- 0
extracted_text <- character()
seqname_index <- 0

# Get line numbers of which are the start point of result for each laccase, the start and the end of the table from the result
seqname_index <- grep("Output", text) 

start_index <- grep("(Threshold=0.5)", text) + 1

end_index <- grep("Graphics in PostScript", text) - 4

# Create an empty result data frame with column names
result_table <- data.frame(seqname = character(), n_glyco = numeric(), stringsAsFactors = FALSE)

# Loop through each start and end index
for (i in 1:length(start_index)) {
  # Extract the desired text between the start and end indices
  extracted_text <- text[start_index[i]:end_index[i]]
  
  # Find the lines containing "9/9"
  lines <- grep("9/9", extracted_text)
  
  # Initialize results variable
  results <- 0
  
  # Loop through each line containing "9/9"
  for (j in lines) {
    # Check if any Jury agreement 9/9 has at least one + in the N-glyco result
    if (grepl("\\+", extracted_text[j])) {
      results <- 1
      break
    }
  }
  
  # Generate results for each iteration
  seqname <- gsub("'", "", str_extract(text[seqname_index[i]], "'(.*?)'"))
  
  # Create a data frame for the current iteration
  data <- data.frame(seqname = seqname, n_glyco = results, stringsAsFactors = FALSE)
  
  # Append the data to the result data frame
  result_table <- rbind(result_table, data)
}

output_file <- args[2]
write.csv(result_table, file = output_file, row.names = FALSE)