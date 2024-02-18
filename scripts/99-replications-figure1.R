#### Preamble ####
# Purpose: Replicated Figure 1 from The Equity of Tax Systems in Low- and MiddleIncome Countries paper
# Author: Amie Liu, Wanling Ma
# Date: 13 February 2024
# Contact: wanling.ma@mail.utoronto.ca
# License: MIT


#### Workspace setup ####
library(tidyverse)
library(haven) # for reading .dta files
library(dplyr) # for data manipulation
library(ggplot2)
library(patchwork)

#### Pre-process data ####

target_year <- 2018

# Bring in Population and GDP, World Development Indicators World Bank
pop <- read_dta("../data/raw_data/gdp_population_WDI.dta") %>%
  filter(year == target_year) %>%
  select(-year)

# Bring in Oil and Gas Rich status countries from Ross-Mahdavi (2015)
oil <- read_dta("../data/raw_data/ross_mahdavi.dta") %>%
  filter(year == 2013) %>%
  rename(oil_pct_2013 = oil_pct) %>%
  select(country, oil_pct_2013)

# Bring in tax rates data
tax_rates <- read_dta("../data/raw_data/globalETR_bfjz.dta") %>%
  filter(year == target_year)

# Clean up tax_rates data for merge
tax_rates <- tax_rates %>%
  select(-year)

# Merge with population data
merged_data <- tax_rates %>%
  left_join(pop, by = c("country" = "country"))

# Keep only the rows that successfully merged
merged_data <- filter(merged_data, !is.na(pop))

# Merge with oil data
merged_data <- merged_data %>%
  left_join(oil, by = c("country" = "country"))

# Adding ISO codes
merged_data$iso3 <- merged_data$country

# Add income classification and continents from WB (country_frame)
country_frame <- read_dta("../data/raw_data/country_frame.dta")
merged_data <- left_join(merged_data, country_frame, by = c("iso3" = "iso3"))


# Apply 2 sample conditions: more than 1M inhabitants, less than 33% of GDP arises from oil and gas production
merged_data <- filter(merged_data, pop > 1000000) # Drop countries with <= 1M inhabitants

# Listing and dropping countries where oil and gas production is >= 33%
merged_data <- filter(merged_data, is.na(oil_pct_2013) | oil_pct_2013 < 0.33) # Drop oil and gas producers
merged_data <- rename(merged_data, country_name = "country_name.x", region = "region.x")
merged_data <- merged_data %>% select(-c("region.y", "country_name.y"))

merged_data <- merged_data %>%
  mutate(
    gdp_to_ndp = gdp_currentusd / ndp_usd
  )

# Updating variables from NDP ratios to GDP ratios
vars_to_update <- c("pct_tax", "pct_1100", "pct_1200", "pct_2000", "pct_4000", "pct_5000", "pct_6000")
for(var in vars_to_update) {
  merged_data[[var]] <- 100 * (merged_data[[var]] / merged_data$gdp_to_ndp)
}

merged_data <- merged_data %>%
  mutate(
    gdp_to_ndp = gdp_currentusd / ndp_usd,
    pct_tax_noSSC = pct_tax - pct_2000,
    pct_other_taxes = pct_1200 + pct_4000 + pct_6000,
    gdp_pc = gdp_currentusd / pop,
    ln_gdp_pc = log(gdp_pc),
    ndp_pc = ndp_usd / pop,
    ln_ndp_pc = log(ndp_pc)
  )


#### Draw Figure 1.1 ####

# Generate Gpct_tax_noSSC as pct_tax_noSSC divided by 100
merged_data <- merged_data %>%
  mutate(Gpct_tax_noSSC = pct_tax_noSSC / 100)

# Create the plot
p1 <- ggplot(merged_data, aes(x = gdp_pc, y = Gpct_tax_noSSC)) +
  geom_point(color = "lightgrey") +
  geom_smooth(method = "loess", color = "mediumblue", formula = y ~ x, se = TRUE) + 
  scale_x_log10(labels = scales::label_dollar(), breaks = c(500, 2000, 10000, 50000)) +
  labs(
    x = "GDP per capita (Constant 2010 USD, log scale)",
    y = "Share of GDP",
    subtitle = "Total Tax Revenue (excl. SSC)"
  ) +
  theme_minimal() +
  theme(
    plot.background = element_blank(),
    panel.grid.minor = element_line(color = "grey", linetype = "dotted"),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(color = "grey", linetype = "dotted"),
    plot.subtitle = element_text(size = rel(1.2))
  )

#### Draw Figure 1.2 - 1.4 ####

##### Mutate Data #####
vars <- c("pct_tax_noSSC", "pct_1100", "pct_5000", "pct_other_taxes", "pct_1200", "pct_4000", "pct_6000")

# Generating ratios
for (var in vars) {
  new_var_name <- paste0("r_", var)
  merged_data[[new_var_name]] <- merged_data[[var]] / merged_data$pct_tax_noSSC
}

##### Draw Figure 1.2 #####
p2 <- ggplot(merged_data, aes(x = gdp_pc, y = r_pct_5000)) +
  geom_point(color = "blue") +
  scale_x_log10(labels = scales::label_dollar(), breaks = c(500, 2000, 10000, 50000)) +
  labs(
    x = "GDP per capita (Constant 2010 USD, log scale)",
    y = "Share of Tax Revenue",
    subtitle = "Indirect Taxes"
  ) +
  ylim(0, 1) + 
  theme_minimal() +
  theme(
    plot.background = element_blank(),
    plot.subtitle = element_text(size = rel(1.2))
  )


##### Draw Figure 1.3 #####
p3 <- ggplot(merged_data, aes(x = gdp_pc, y = r_pct_1100)) +
  geom_point(color = "blue") +
  scale_x_log10(labels = scales::label_dollar(), breaks = c(500, 2000, 10000, 50000)) +
  labs(
    x = "GDP per capita (Constant 2010 USD, log scale)",
    y = "Share of Tax Revenue",
    subtitle = "Personal Income Tax"
  ) +
  ylim(0, 1) + 
  theme_minimal() +
  theme(
    plot.background = element_blank(),
    plot.subtitle = element_text(size = rel(1.2))
  )

##### Draw Figure 1.4 #####
p4 <- ggplot(merged_data, aes(x = gdp_pc, y = r_pct_other_taxes)) +
  geom_point(color = "blue") +
  scale_x_log10(labels = scales::label_dollar(), breaks = c(500, 2000, 10000, 50000)) +
  labs(
    x = "GDP per capita (Constant 2010 USD, log scale)",
    y = "Share of Tax Revenue",
    subtitle = "All Other Taxes"
  ) +
  ylim(0, 1) + 
  theme_minimal() +
  theme(
    plot.background = element_blank(),
    plot.subtitle = element_text(size = rel(1.2))
  )


write_dta(merged_data, "../data/proc/tax_sample.dta")


print(p1)
print(p2)
print(p3)
print(p4)
