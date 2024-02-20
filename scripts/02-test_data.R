#### Preamble ####
# Purpose: Tests the simulated dataset to do the analysis about tax equality across different nations.
# Author: Amie Liu, Wanling Ma
# Date: 19 February 2024
# Contact: wanling.ma@mail.utoronto.ca
# License: MIT


#### Workspace setup ####
library(tidyverse)

#### Test data ####
df <- read.csv("data/simulation/simulation.csv")
# Test for missing values
if(any(is.na(df))) {
  stop("There are missing values in the dataframe.")
} else {
  print("No missing values in the dataframe.")
}

# Check ranges - Example for pct_tax_noSSC
if(any(df$pct_tax_noSSC < 0 | df$pct_tax_noSSC > 100)) {
  stop("pct_tax_noSSC has values outside the 0-100 range.")
} else {
  print("pct_tax_noSSC values are within the expected range.")
}

# Confirm the dimensions of the dataframe
expected_n <- 1000
actual_n <- nrow(df)
if(actual_n != expected_n) {
  stop(paste("Dataframe row count mismatch. Expected:", expected_n, "Got:", actual_n))
} else {
  print(paste("Dataframe has the correct number of rows:", actual_n))
}
