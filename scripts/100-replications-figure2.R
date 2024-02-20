#### Preamble ####
# Purpose: Replicated Figure 3 from The Equity of Tax Systems in Low- and MiddleIncome Countries paper
# Author: Amie Liu, Wanling Ma
# Date: 13 February 2024
# Contact: wanling.ma@mail.utoronto.ca
# License: MIT


#### Workspace setup ####
library(dplyr)
library(haven)
library(readr)
library(stringr)
library(patchwork)
library(readxl)

#### Pre-process data ####

clean_columns_conflict <- function(result_df) {
  # Assuming result_df is your data frame resulting from a join operation
  # First, identify all columns that end with .x or .y
  suffix_columns <- names(result_df)[grepl("\\.x$|\\.y$", names(result_df))]
  
  # Find unique column names without the .x or .y suffix
  base_columns <- unique(sub("\\.x$|\\.y$", "", suffix_columns))
  
  # Iterate over the base column names, coalesce .x and .y versions, and update the data frame
  for (col in base_columns) {
    x_col <- paste0(col, ".x")
    y_col <- paste0(col, ".y")
    
    # Only attempt to coalesce if both .x and .y columns exist
    if(x_col %in% names(result_df) && y_col %in% names(result_df)) {
      result_df[[col]] <- coalesce(result_df[[x_col]], result_df[[y_col]])
    } else if(x_col %in% names(result_df)) {
      result_df[[col]] <- result_df[[x_col]]
    } else if(y_col %in% names(result_df)) {
      result_df[[col]] <- result_df[[y_col]]
    }
    
    # Drop the .x and .y columns if they exist
    result_df[[x_col]] <- NULL
    result_df[[y_col]] <- NULL
  }
  return(result_df)
}

# Bring in Population and GDP, World Development Indicators World Bank
gdp_population_WDI <- read_dta("../data/raw_data/gdp_population_WDI.dta") %>%
  filter(year == 2018) %>%
  select(-year)

# Save the intermediate data for later use
tempfile_pop <- tempfile(fileext = ".dta")
write_dta(gdp_population_WDI, path = tempfile_pop)

# Import self-employment data
self_employment_data <- read_csv("../data/raw_data/API_SL.EMP.SELF.ZS_DS2_en_csv_v2_5560396.csv", skip = 3) %>%
  rename(countryname = "Country Name", country = "Country Code", v62 = "2018") %>%
  select(countryname, country, v62) %>%
  rename(self_employed_share = v62)


# Merge with the Population and GDP data
merged_data <- self_employment_data %>%
  left_join(read_dta(tempfile_pop), by = "country") %>%
  filter(!is.na(self_employed_share))

# Merge with Tax sample to have comparable countries
tax_sample <- read_dta("../data/proc/tax_sample.dta")

final_sample <- merged_data %>%
  inner_join(tax_sample, by = "country") %>%
  mutate(self_employed_share = self_employed_share / 100)
final_sample <- clean_columns_conflict(final_sample)

# Save the final dataset
write_dta(final_sample, "../data/proc/tax_employment_sample.dta")

#### Draw Figure 2.1 ####

# Prepare the data by creating a log-transformed version of `gdp_pc` for plotting
final_sample$gdp_pc_log <- log(final_sample$gdp_pc)

# Create the plot
plot1 <- ggplot(data = final_sample, aes(x = gdp_pc_log, y = self_employed_share)) +
  geom_point(color = "mediumblue") +
  scale_x_continuous(name = "GDP per capita (Constant 2010 USD, log scale)",
                     breaks = log(c(500, 1000, 2000, 5000, 10000, 25000, 50000)),
                     labels = c("500", "1000", "2000", "5000", "10000", "25000", "50000")) +
  scale_y_continuous(name = "Share of Employment",
                     limits = c(0, 1),
                     breaks = seq(0, 1, 0.2),
                     minor_breaks = seq(0, 1, 0.2)) +
  theme_minimal() +  # White background
  theme(plot.background = element_blank(), 
        panel.background = element_blank(),
        panel.grid.major.x = element_line(color = "grey90"),
        panel.grid.minor.y = element_line(color = "grey90", linetype = "dotted")) +
  ggtitle("Self-Employment") +
  theme(legend.position = "none")  # Remove legend

#### Draw Figure 2.2 ####

# Read Excel file
gdp_data <- read_excel("../data/raw_data/Country_information.xlsx")

# Rename columns
gdp_data <- gdp_data %>%
  rename(
    year = Year,
    country_code = "Country Code",
    CountryName = "Country Name"
  ) %>%
  select(CountryName, country_code, GDP_pc_currentUS, GDP_pc_constantUS2010, PPP_current, year)

# Save the temporary data as a Stata file
write_dta(gdp_data, "../data/proc/gdp_data.dta")

# Load country frame data
country_frame <- read_dta("../data/raw_data/country_frame.dta") %>%
  rename(country_code = iso2)

# Save the temporary data as a Stata file
write_dta(country_frame, "../data/proc/country_frame.dta")

# Load Data of regression Output
regression_output <- read_dta("../data/raw_data/regressions_output_central.dta")

# Merge gdp_data with regression_output
merged_data <- merge(regression_output, gdp_data, by = c("country_code", "year"), all.x = TRUE)


# Merge merged_data with country_frame
final_data <- merge(merged_data, country_frame, by = "country_code", all.x = TRUE)


data <- select(final_data, -c(se, r2_adj))

# Reshape data from long to wide format
data_wide <- pivot_wider(data, names_from = iteration, values_from = b, 
                         names_prefix = "b", id_cols = c(country_code, year))

# Merge with gdp_data
merged_data <- inner_join(data_wide, gdp_data, by = c("country_code", "year"))


# Generate GDP_pc measures
merged_data <- mutate(merged_data,
                      log_GDP = log(GDP_pc_constantUS2010),
                      log_GDP_pc_currentUS = log(GDP_pc_currentUS),
                      log_PPP_current = log(PPP_current))
merged_data$b1 <- merged_data$b1 / 100


# Create the plot
plot2 <- ggplot(data = merged_data, aes(x = log_GDP, y = b1)) +
  geom_point(color = "mediumblue") +
  scale_x_continuous(name = "GDP per capita (Constant 2010 USD, log scale)",
                     breaks = log(c(500, 1000, 2000, 5000, 10000, 25000, 50000)),
                     labels = c("500", "1000", "2000", "5000", "10000", "25000", "50000")) +
  scale_y_continuous(name = "Share of Employment",
                     limits = c(0, 1),
                     breaks = seq(0, 1, 0.2),
                     minor_breaks = seq(0, 1, 0.2)) +
  labs(x = "GDP per capita (Constant 2010 USD, log scale)",
       y = "Share of Total Consumption",
       subtitle = "Consumption in Traditional Stores") +
  theme_minimal() +
  theme(plot.background = element_blank(), 
        panel.background = element_blank(),
        panel.grid.major.x = element_line(color = "grey90"),
        panel.grid.minor.y = element_line(color = "grey90", linetype = "dotted"))

