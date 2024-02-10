					*************************************************
					* 		Tax Ratios, JEP paper 					*
					*		Authors: Pierre Bachas, Lucie Gadenne	*
					*		Date: June 2023							*
					*		Tab1.do									*
					*************************************************
							
	set more off
				
*********************************************************************************************************	
* 1. Table for Paper 
*********************************************************************************************************		

**** LIC, LMIC, UMIC, HIC.  

	use "proc/complete_sample_data.dta" , clear

	tab incomelevelname, m			 // ok fairly well balanced, keep 4 categories
	
	foreach var in r_pct_1100 r_pct_5000  r_pct_other_taxes r_pct_1200  r_pct_4000  r_pct_6000  informal_consumption {
		replace `var ' = 100*`var'
		}
		
	gen income_groups = 1 if incomelevelname == "Low income"
 	replace income_groups = 2 if incomelevelname == "Lower middle income"	
 	replace income_groups = 3 if incomelevelname == "Upper middle income"		
 	replace income_groups = 4 if incomelevelname == "High income"			
	
	tab income_groups
	
	label define income_group 1 "Low income"  2 "Lower middle income"  3 "Upper middle income"  4 "High income" , replace 
	label values income_groups income_group

	label variable pct_tax_noSSC "Tax Revenue (excl. SSC)"  
	label variable r_pct_1100 "PIT share"	
	label variable r_pct_5000 "Indirect tax share"
	label variable r_pct_other_taxes "Other taxes share"
	label variable self_employed_share "Self-employment"
	label variable informal_consumption "Informal consumption"	
	
	* Data for the paper, corresponding to the figure 
 	tabstat  pct_tax_noSSC  r_pct_1100 r_pct_5000  r_pct_other_taxes self_employed_share informal_consumption, by(income_groups) format(%5.3g)  labelwidth(20)   // change to incomelevelname if want 4 categories
	
	#delim ; 
	
	asdoc tabstat pct_tax_noSSC  r_pct_1100 r_pct_5000  r_pct_other_taxes self_employed_share informal_consumption, by(income_groups) stat(mean) dec(1) label
	 replace  save(table1.doc) ; 

	#delim cr			// Note: there is a problem with this asdoc, the labels of the by are not correct
	
	** Extra stats if needed (break down corporate tax 1200, taxes on property and wealth 4000 , remaining taxes 6000)
 	tabstat pct_tax pct_tax_noSSC r_pct_5000 r_pct_1100  r_pct_1200  r_pct_4000  r_pct_6000, by(wb_inc) format(%9.3g)  // change to incomelevelname if want 4 categories
	
 
*********************************************************************************************************	
* 2. Quoted Statistics in Paper 
*********************************************************************************************************		
  
 	use "proc/complete_sample_data.dta" , clear
	drop if sample_only_informal_csption == 1 	// Few countries where we dont have revenue but do have informal consumption
	
	total pop
	matrix row1=r(table)
	local sample_pop=row1[1,1]	
	display `sample_pop'	
	
	local world_pop = 7662000000  	// https://data.worldbank.org/indicator/SP.POP.TOTL?end=2018&start=2018
	
	local share_pop = `sample_pop' / `world_pop'
	display `share_pop' 
	display "Share of World Population " %3.2f `share_pop'	
	
	
	
	