#### Preamble ####
# Purpose: Simulates the necessary dataset to do the analysis about tax equality across different nations.
# Author: Amie Liu, Wanling Ma
# Date: 19 February 2024
# Contact: wanling.ma@mail.utoronto.ca
# License: MIT

#### Workspace setup ####
# Load necessary library
library(dplyr)

#### Simulate data ####
# Set seed for reproducibility
set.seed(0)

# Simulate data
n <- 1000 # Define the number of observations

pct_tax_noSSC <- runif(n, 0, 100) # Uniform distribution for percentage values
gdp_pc <- rnorm(n, mean = 50000, sd = 15000) # Assume a mean GDP per capita with some standard deviation
self_employed_share <- runif(n, 0, 100) # Uniform distribution for percentage values
employment_rate <- runif(n, 0, 100) # Uniform distribution for percentage values
varofint <- runif(n, 0, 50) # Assuming average tax rate varies
income_decile <- sample(1:10, n, replace = TRUE) # Assuming income deciles from 1 to 10
share_of_tax_revenue <- runif(n, 0, 100) # Uniform distribution for percentage values

# Combine into a dataframe
data_frame <- data.frame(pct_tax_noSSC, gdp_pc, self_employed_share, employment_rate, varofint, income_decile, share_of_tax_revenue)

# Print the first few rows of the dataframe
head(data_frame)

write_csv(data_frame, "data/simulation/simulation.csv")


