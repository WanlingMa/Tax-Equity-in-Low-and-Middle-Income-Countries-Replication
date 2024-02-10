
*****************************************************************
* 		JEP: Tax equity											*
*		Authors: Pierre Bachas, Lucie Gadenne, Anders Jensen	*
*		Date: June 2023											*
*		Master.do												*
* 		Data Sources detailed in readme files					* 
*****************************************************************

	** Configuration
	** STATA/MP 18.0 run on MAC OS 

***************
* DIRECTORIES *
***************
	
	global cdpath "/Users/bachas/Dropbox/JEP/Replication"
	cd $cdpath
	
***********************
* INSTALL PACKAGES *
***********************	

	do "$cdpath/do/config.do" 

*********************************************************
* SCRIPT NAMES, OBJECTIVES AND DATA SOURCES	*
*********************************************************
		
	*************
	* Figure 1 
	*************
	
	do "$cdpath/do/Fig1_Tax_ratios.do"			
	
	/*
	Inputs:
	- gdp_population_WDI.dta  			// GDP and population. World Bank WDI, year 2018
	- ross_mahdavi.dta 					// Oil and Gas Rich status countries from Ross-Mahdavi (2015)
	- globalETR_bfjz.dta 				// Downloaded from "name website" 
	- country_frame.dta					// Country frame: all existing countries and their World Bank income levels
		
	Output: 
	 - graphs/Figure1.pdf				
	 - proc/tax_sample.dta								// Intermediary file with countries covered 	
														*/
	***************************
	* Figure 2
	***************************	
	
	do "$cdpath/do/Fig2_Informality.do"
		
	/*
	Inputs:
	- data/API_SL.EMP.SELF.ZS_DS2_en_csv_v2_5560396.csv		
	
	- data/regressions_output_central.dta 			// From Bachas, Gadenne, Jensen (Restud 2023)
	- data/Country_information.xlsx					// From Bachas, Gadenne, Jensen (Restud 2023)
	
	proc/tax_sample.dta	
	
	Output: 
	graphs/Figure2.pdf	
	proc/complete_sample_data.dta				
														*/	
	
	*************
	* Table 1 
	*************	
	
	do "$cdpath/do/Tab1.do" 
	
	/*
	Inputs:
	- proc/complete_sample_data.dta
	
	Output: 
	- tables/table1.doc			
														*/	
	
	***************************
	* Figure 3
	***************************		
	
	// This figure is figure 1 from Bachas, Gadenne, Jensen "Informality, Consumption Taxes, and Redistribution" The Review of Economic Studies, 2023; 
	// rdad095, https://doi.org/10.1093/restud/rdad095
	// replication files available at: https://doi.org/10.5281/zenodo.8284123
	
	// "graphs/RW_Engel_informal_exp_noh_axis.pdf"		 // Rwanda
	// "graphs/MX_Engel_informal_exp_noh_axis.pdf"		// Mexico 
	
		
 	***************************
	* Figure 4
	***************************	
  
	do "$cdpath/do/Fig4_CEQDirectTaxes_PITFeatures.do"
	
	/*
	Inputs:
	- data/PIT_parameters_AJ.dta					// Anders Jensen data 			
	- data/PIT_Top_Rates_2022.csv					// Assembled by authors
	- data/PSPR_incidence_dirtax_2023.dta  			// Data from PSPR, sent by Mariano Sosa (World Bank)
	
	Output: 
	- table1.doc		
	- graphs/Figure4.pdf
														*/		
	
	

	
	
	 
  