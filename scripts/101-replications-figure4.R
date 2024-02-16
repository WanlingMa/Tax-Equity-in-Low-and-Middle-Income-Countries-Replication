#### Preamble ####
# Purpose: Replicated Figure 4 from The Equity of Tax Systems in Low- and MiddleIncome Countries paper
# Author: Amie Liu, Wanling Ma
# Date: 13 February 2024
# Contact: wanling.ma@mail.utoronto.ca
# License: MIT
# Pre-requisites: [...UPDATE THIS...]


#### Workspace setup ####
library(dplyr)
library(haven)
library(tidyr)
library(readr)
library(labelled)

#### Pre-process data ####

# Define the usual suspects (assuming this is a vector of variable names)
usualsuspects <- c("source", "class_pspr", "oecd", "ctry_year", "ctry_ceq", "year", "ctry", "ctry_code", "class_geo", "class_inc", "class_inc_code", "class_pspr", "class_pspr_code", "class_lend", "class_weo", "decile", "decnum", "ctry_code", "pen_scenario")

# Load the data
data <- read_dta("../data/raw_data/PSPR_incidence_dirtax_2023.dta")

# Keep the usual suspects and variables with 'in_*_dirtax'
data <- data %>%
  select(all_of(usualsuspects), starts_with("in_"), ends_with("_dirtax"))

# Replace class_inc values
data$class_inc <- ifelse(data$class_inc == "lic", "lmic", data$class_inc)


# Further data manipulation
data <- data %>%
  select(matches(".*_pdi.*"), matches(".*_pgt.*"), all_of(usualsuspects)) %>%
  arrange(ctry, year, decnum) %>%
  mutate(across(matches(".*_pdi.*"), ~.x * 100, .names = "pdi_var"),
         across(matches(".*_pgt.*"), ~.x * 100, .names = "pgt_var")) %>%
  mutate(varofint = ifelse(is.na(pdi_var), abs(pgt_var), abs(pdi_var))) %>%
  select(-matches(".*_pdi.*"), -matches(".*_pgt.*"), -matches("^ie_flag_p.*"))

# For countries with more than one project, pick the last one
data <- data %>%
  group_by(ctry) %>%
  mutate(yearmax = max(year, na.rm = TRUE),
         yearmax_av = mean(yearmax, na.rm = TRUE)) %>%
  ungroup() %>%
  filter(year == yearmax) %>%
  select(-yearmax, -yearmax_av)

# Tabulate 'class_inc' for decnum == 5
table(data$class_inc[data$decnum == 5])

# Collapse the dataset to summary statistics
# Assuming 'reportstat' is "median" and 'classificvariable' is "class_inc" as per your context
data_collapsed <- data %>%
  group_by(!!sym("class_inc"), decnum) %>%
  summarise(varofint = median(varofint, na.rm = TRUE), # Calculate median of varofint
            count = n()) %>%
  ungroup()

# Labeling variables (R doesn't use variable labels in the same way as Stata, but for documentation)
# You can store metadata or use attributes in R for a similar purpose
attr(data_collapsed$varofint, "label") <- paste("median", "dirtax", sep = "-")

# Reordering variables (dplyr automatically orders variables based on the group_by and summarise steps)
# If you need to explicitly change the order, you can use select()
data_collapsed <- data_collapsed %>%
  select(class_inc, !!sym("class_inc"), decnum, varofint, count)

# Drop observations where decnum == 11
data_collapsed <- data_collapsed %>%
  filter(decnum != 11)

data <- data_collapsed

#### Draw Figure 4.1 ####
g <- ggplot(data, aes(x = decnum, y = varofint, group = class_inc)) +
  geom_point(aes(color = class_inc)) + # Use geom_point for scatter plot
  facet_wrap(~class_inc, scales = "free", ncol = 1) + # Separate plots for each class_inc
  labs(x = "Income Decile (within country)", y = "Average Tax Rate") +
  theme_minimal() +
  theme(legend.position = "none", # Remove legend
        plot.background = element_blank(), # White background
        panel.background = element_blank()) # White panel background

g

# Connected scatter plot for High Income Countries (HIC)
g_hic <- ggplot(data %>% filter(class_inc == "hic"), aes(x = decnum, y = varofint)) +
  geom_line(color = "forestgreen") + # Use geom_line for connected scatter plot
  geom_point(color = "forestgreen") +
  labs(x = "Income Decile (within country)", y = "Average Tax Rate", subtitle = "High Income Countries") +
  theme_minimal() +
  theme(plot.background = element_blank(),
        panel.background = element_blank())

# Repeat for other income classes as needed, adjusting the filter condition and colors

# Combined scatter plot with annotations
g_combined <- ggplot(data, aes(x = decnum, y = varofint, color = class_inc)) +
  geom_line(aes(linetype = class_inc)) + # Use different linetypes for each class_inc
  geom_point(aes(shape = class_inc)) + # Use different shapes for each class_inc
  scale_color_manual(values = c("hic" = "forestgreen", "lmic" = "sienna", "umic" = "purple")) +
  labs(x = "Income Decile (within country)", y = "Average Tax Rate", subtitle = "De-Facto Distributional Incidence of Direct Taxes") +
  theme_minimal() +
  theme(plot.background = element_blank(),
        panel.background = element_blank(),
        legend.position = "none") +
  annotate("text", x = 7.3, y = 18.5, label = "High Income", color = "forestgreen") +
  annotate("text", x = 7.2, y = 7.8, label = "Upper-Middle Income", color = "purple") +
  annotate("text", x = 8.5, y = 1, label = "Lower Income", color = "sienna")

print(g_combined)

#### Draw Figure 4.2 ####
# Load data on breadth of tax base
data_pit_parameters <- read_dta("../data/raw_data/PIT_parameters_AJ.dta")

# Calculate max year by country and filter
data_pit_parameters <- data_pit_parameters %>%
  group_by(country) %>%
  filter(year == max(year)) %>%
  ungroup()

# Rename variables and keep specific columns
data_pit_parameters <- data_pit_parameters %>%
  rename(iso2 = country_code) %>%
  select(iso2, lg_gdppc, size_pit)

# Save the intermediate data frame
threshold <- tempfile()
write_dta(data_pit_parameters, threshold)

# Load data on top Marginal Tax Rates
data_top_rates <- read_csv("../data/raw_data/PIT_Top_Rates_2022.csv")

# Convert top_rate to numeric and handle exceptions
data_top_rates$top_rate <- as.numeric(data_top_rates$top_rate)
data_top_rates <- data_top_rates %>%
  rename(iso2 = alpha_2) %>%
  filter(iso2 != "CI") %>%
  select(iso2, top_rate)

# Save the intermediate data frame
PIT_rates <- tempfile()
write_dta(data_top_rates, PIT_rates)

# Load complete sample data
complete_sample_data <- read_dta("../data/proc/complete_sample_data.dta")
complete_sample_data <- complete_sample_data %>%
  filter(sample_only_informal_csption != 1) %>%
  select(-sample_only_informal_csption)

# Merge with PIT rates
complete_sample_data <- complete_sample_data %>%
  left_join(data_top_rates, by = "iso2") %>%
  filter(!is.na(top_rate))

# Merge with threshold data
complete_sample_data <- complete_sample_data %>%
  left_join(data_pit_parameters, by = "iso2") %>%
  mutate(threshold_only = ifelse(is.na(size_pit), 0, 1))

# Count observations with non-missing top_rate and size_pit
count(complete_sample_data, !is.na(top_rate))
count(complete_sample_data, !is.na(size_pit))

# Generate income_groups based on incomelevelname
complete_sample_data$income_groups <- case_when(
  complete_sample_data$incomelevelname == "Low income" ~ 1,
  complete_sample_data$incomelevelname == "Lower middle income" ~ 2,
  complete_sample_data$incomelevelname == "Upper middle income" ~ 3,
  complete_sample_data$incomelevelname == "High income" ~ 4,
  TRUE ~ NA_integer_
)

# Convert income_groups to a factor with labels for better readability
complete_sample_data$income_groups <- factor(complete_sample_data$income_groups, 
                                             levels = c(1, 2, 3, 4),
                                             labels = c("Low income", "Lower middle income", "Upper middle income", "High income"))

# Now, you can proceed with the rest of the analysis as planned.

# For example, to tabulate income_groups:
table(complete_sample_data$income_groups)

# Summarize top_rate by income_groups
complete_sample_data %>%
  group_by(income_groups) %>%
  summarise(mean_top_rate = mean(top_rate, na.rm = TRUE))

# Calculate mean top_rate for high income and developing countries separately
mean(complete_sample_data$top_rate[complete_sample_data$income_groups == "High income"], na.rm = TRUE) # High income
mean(complete_sample_data$top_rate[complete_sample_data$income_groups != "High income"], na.rm = TRUE) # Developing countries

# Assuming 'data' is your data frame containing 'top_rate', 'gdp_pc', and 'lg_gdppc'
data <- complete_sample_data
# Create a new variable for color coding based on GDP per capita thresholds
data$color_group <- with(data, ifelse(gdp_pc >= 13000, "High GDP",
                                      ifelse(gdp_pc < 13000 & gdp_pc >= 4000, "Medium GDP", "Low GDP")))

# Top MTR Plot
print(ggplot(data, aes(x = gdp_pc, y = top_rate)) +
  geom_point(aes(color = color_group, shape = color_group)) +
  scale_x_log10(labels = scales::comma, breaks = c(500, 1000, 2000, 5000, 10000, 25000, 50000)) +
  scale_color_manual(values = c("High GDP" = "forestgreen", "Medium GDP" = "purple", "Low GDP" = "sienna")) +
  scale_shape_manual(values = c("High GDP" = 15, "Medium GDP" = 18, "Low GDP" = 17)) +
  labs(x = "GDP per capita (Constant 2010 USD, log scale)", y = "Tax Rate",
       subtitle = "Top Statutory Tax Rate of Personal Income Tax") +
  theme_minimal() +
  theme(legend.position = "none",
        plot.background = element_blank(),
        panel.background = element_blank()))

### PIT Exemption Threshold Plot

# Convert lg_gdppc to gdppc
data$gdppc <- exp(data$lg_gdppc)

# PIT Exemption Threshold Plot
print(ggplot(data, aes(x = gdppc, y = size_pit)) +
  geom_point(aes(color = color_group, shape = color_group)) +
  scale_x_log10(labels = scales::comma, breaks = c(500, 1000, 2000, 5000, 10000, 25000, 50000)) +
  scale_color_manual(values = c("High GDP" = "forestgreen", "Medium GDP" = "purple", "Low GDP" = "sienna")) +
  scale_shape_manual(values = c("High GDP" = 15, "Medium GDP" = 18, "Low GDP" = 17)) +
  labs(x = "GDP per capita (Constant 2010 USD, log scale)", y = "Share of Workforce",
       subtitle = "Share of Workforce Legally Subject to Personal Income Tax") +
  theme_minimal() +
  theme(legend.position = "none",
        plot.background = element_blank(),
        panel.background = element_blank()))
