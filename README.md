# The Impact of Tax Policy Evolution on Economic Development and Income Inequality

## Overview

This repo contains all scripts, sources, and codes to reproduce ["Tax Equity in Low- and Middle-Income Countries" by Pierre Bachas, Anders Jensen, and Lucie Gadenne](https://www.aeaweb.org/articles?id=10.1257/jep.38.1.55&ArticleSearch%5Bwithin%5D%5Barticletitle%5D=1&ArticleSearch%5Bwithin%5D%5Barticleabstract%5D=1&ArticleSearch%5Bwithin%5D%5Bauthorlast%5D=1&ArticleSearch%5Bq%5D=&JelClass%5Bvalue%5D=0&journal=3&from=j). The dataset was retrieved from the original paper's replication package at [openICPSR](https://www.openicpsr.org/openicpsr/project/194851/version/V1/view). Further findings from the original paper, including the evolution of tax policy and its impact on income inequality and economic development, are all extended in this analysis. 


## File Structure

The repo is structured as:

-   `data/raw_data` contains the raw data as obtained from the replication package of the original paper.
-   `other` contains details about LLM chat interactions, and sketches.
-   `paper` contains the files used to generate the paper, including the Quarto document and reference bibliography file, as well as the PDF of the paper. 
-   `scripts` contains the R scripts used to simulate, download, process and produce the figures.


## Statement on LLM usage

We use ChatGPT to translate the original Stata code into R. It is also used for brainstorming ideas, proofreading, and writing certain parts of the paper. The entire chat history is available in inputs/llms/usage.txt.
