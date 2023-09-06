# To use at puhti, unhashtag the following line, and make sure the packages are installed
.libPaths(c("/<your_path>", .libPaths()))

library(ape)
library(tidyverse)


# Check if the correct number of command-line arguments is provided
if (length(commandArgs(trailingOnly = TRUE)) != 4) {
  stop("Please provide the input file, output file, tree file, and threshold as command-line arguments.")
}

# Read the input file and assign the data to new_data
input_file <- commandArgs(trailingOnly = TRUE)[1]
new_data <- readLines(input_file)

# Parse the threshold from the command-line argument
threshold <- as.numeric(commandArgs(trailingOnly = TRUE)[4])

# Read the tree file
tree_file <- commandArgs(trailingOnly = TRUE)[3]
tree <- read.tree(tree_file)

# List of species to check
species_list <- c("Amath1_9610", "CbLac", "Ccinerea_lcc9", "CcLac3", "CcLac4", "CcLcc1", "Cerrena_LacA", "CerrenaWR1_lcc3", "Cersu1_88089", "Copmar1_511451", "Copph3_744923", "CotA", "Crula1_378411", "Crula1_765906", "Earsca1_643866", "Fibsp1_910643", "Ganoderma0814_lcc1", "GlLac", "Jaaar1_175905", "Lac1", "LacA", "Lcc3", "Lcc4", "LccA", "LeLcc4A", "LeLcc5", "LeLcc7", "MaL", "MaL_M1", "MrLac", "OrLac1", "OrLac2", "Panru1_1594824", "Panru1_1686772", "Panru1_1700279", "PeL3", "Phlcen1_10631", "PIE5", "PM1_lcc", "Pox2", "PoxA1b", "PsLac2", "Pycci1_4273", "ScLac", "SgfSL", "SmL", "TcLac4", "TpLap2", "Traci1_1498596", "Tramey1_100135", "TsLac1", "TsLac2", "TvLac1", "TvLac2", "TvLacIIIb")

# Filter out species that are not in the tree
species_list <- species_list[species_list %in% tree$tip.label]

# Create an empty data frame
result_df <- data.frame(items = character(), distance = numeric(), stringsAsFactors = FALSE)

# Set threshold
# threshold = 0.01

# Compute the cophenetic distances
distances <- cophenetic(tree)

# Loop through the new_data
for (item in new_data) {
  # Check if the item is in the tree
  if (item %in% tree$tip.label) {
    # Compute the distances between the item and each species in the list
    distances_to_species_list <- distances[item, species_list]

    # Find the minimum distance and the species associated with it
    min_distance <- min(distances_to_species_list)

    # Create a new row for the result data frame
    new_row <- data.frame(items = item, distance = ifelse(min_distance < threshold, min_distance, NA), stringsAsFactors = FALSE)

    # Add the new row to the result data frame
    result_df <- rbind(result_df, new_row)
  }
}

# for (item in new_data) {
  # # Check if the item is in the tree
  # if (item %in% tree$tip.label) {
    # # Compute the distances between the item and each species in the list
    # distances_to_species_list <- ape::dist.nodes(item, tree, method = "patristic")

    # # Find the minimum distance and the species associated with it
    # min_distance <- min(distances_to_species_list)

    # # Create a new row for the result data frame
    # new_row <- data.frame(items = item, distance = ifelse(min_distance >= 0 && min_distance <= threshold, min_distance, NA), stringsAsFactors = FALSE)

    # # Add the new row to the result data frame
    # result_df <- rbind(result_df, new_row)
  # }
# }
# Write the result data frame to the output file
output_file <- commandArgs(trailingOnly = TRUE)[2]
write.csv(result_df, file = output_file, row.names = FALSE)
