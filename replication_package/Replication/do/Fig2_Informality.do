
					*************************************************
					* 		Tax Ratios, JEP paper 					*
					*		Authors: Pierre Bachas, Lucie Gadenne	*
					*		Date: June 2023							*
					*		Fig2_Informality.do						*
					*************************************************
						
	set more off
				
************************************************************************	
* 1. Self-employment Shares 
************************************************************************
		
	** Bring in Population and GDP, World Development Indicators World Bank 
	use "data/gdp_population_WDI.dta", replace 
	keep if year == 2018 
	drop year
	tempfile pop
	save `pop'
		
	// https://data.worldbank.org/indicator/SL.EMP.SELF.ZS	
	import delimited using "data/API_SL.EMP.SELF.ZS_DS2_en_csv_v2_5560396.csv" , clear varnames(4)
	count if v65 != . 		
	keep countryname countrycode v62
	rename countrycode country 
	rename v62 self_employed_share
	
	merge 1:1  country using `pop'
	keep if _m ==3
	drop _m 
	
	count
	keep if self_employed_share!= .
	count                     				// (234 -> Should we bring it more inline to tax sample or no need to?) 
	
	// Merge with Tax sample to have comparable countries  
	merge 1:1 country using "proc/tax_sample.dta" // Created as part of Fig1
	keep if _m == 3
	drop _m
	
	save  "proc/tax_employment_sample.dta", replace
	
	replace self_employed_share = self_employed_share/100
	
	niceloglabels gdp_pc , local(xlab) style(125)
	display "`xlab'"
	local xlab "500 1000 2000 5000 10000 25000 50000"			
			
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("GDP per capita (Constant 2010 USD, log scale)", margin(medsmall) size(`size'))"
	local xaxis "xscale(log) xlabel(`xlab', ang(h) labsize(`size'))"
	local yaxis "ylabel(0(0.2)1, nogrid labsize(`size')) yscale(range(0 1)) yline(0(0.2)1, lstyle(minor_grid) lcolor(gs1))" 

		#delim ;			
		
		twoway (scatter self_employed_share gdp_pc,  color(emidblue)) (lpoly self_employed_share gdp_pc,  color(emidblue)  bwidth(0.5)),	
		`xaxis' 
		`yaxis' 
		`xtitle' 
		ytitle("Share of Employment", margin(medsmall) size(`size'))
		legend(off) 	 
		`graph_region_options'
		subtitle(Self-Employment, size(large))	
		name(inf_labor, replace) ; 
		
		// graph export "graphs/informality_labor.pdf", replace	;
		
		#delim cr		
	
	
************************************************************************	
* 2. Informality: Consumption
************************************************************************

{	
	* Obtain GDP_pc for the country
	import excel using "data/Country_information.xlsx" , clear firstrow	
	
	rename Year year
	
	rename CountryCode country_code
	keep CountryName country_code GDP_pc_currentUS GDP_pc_constantUS2010 PPP_current year	
	tempfile gdp_data		
	save `gdp_data'
	
	use "data/country_frame.dta" 	, replace		// to bring countries income groups
	rename iso2 country_code
	tempfile frame			
	save `frame'
	
	* Load Data of regression Output 
	use "data/regressions_output_central.dta", replace 
	
	merge m:1 country_code year using `gdp_data'
	keep if _merge == 3 
	drop _m
	
	merge m:1 country_code using `frame'
	keep if _merge == 3
	drop _m

// 	* Basic Data prep
//
// 	* Make the slope coefficients "positive" for readability in tables
// 	*replace b = -b	if iteration > 5		
//	
// 	** Generate p-values and confidence intervals (p-value probability that null hypothesis beta = 0 is true) 
// 	local df_r = 1000000	
// 	gen p_value_2s = (2 * ttail(`df_r', abs(b/se))) / 2
//	
// 	** Note: we want to test the one-sided hypothesis: H0 beta = 0 vs Ha beta < 0 
// 	gen p_value_1s = p_value_2s / 2 if b >0
// 	replace p_value_1s = 1 - p_value_2s/2 if b < 0 
// 	drop p_value_2s
//	
// 	gen ci_low = b - 1.96*se
// 	gen ci_high = b + 1.96*se
//	
	
	**************************************************************************	
	* Reshape the data for the iterations: this will give b`x' and se`x' 
	**************************************************************************
	drop se r2_adj 
	
	reshape wide b, i(country_code year) j(iteration)
	
	merge 1:1 country_code year using `gdp_data'
	
	keep if _merge == 3
	drop _merge

	** Gen GDP_pc measures
	gen log_GDP = log(GDP_pc_constantUS2010) 	
	gen log_GDP_pc_currentUS = log(GDP_pc_currentUS)	 
	gen log_PPP_current 	 = log(PPP_current)				
				
*********************************************	
* Graphs
*********************************************	
	
	replace b1 = b1/100
	
	local xlab "500 1000 2000 5000 10000 25000 50000"				
	
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("GDP per capita (Constant 2010 USD, log scale)", margin(medsmall) size(`size'))"
	local xaxis "xscale(log) xlabel(`xlab', ang(h) labsize(`size'))"
	local yaxis "ylabel(0(0.2)1, nogrid labsize(`size')) yscale(range(0 1)) yline(0(0.2)1, lstyle(minor_grid) lcolor(gs1))" 

		#delim ;			
		
		twoway (scatter b1 GDP_pc_constantUS2010, color(emidblue)) (lpoly b1 GDP_pc_constantUS2010, color(emidblue) bwidth(0.5)),    //  mlabel(country_code) mlabsize(2.5) mlabcolor(gs10*1.5)
		`xaxis' 
		`yaxis' 
		`xtitle' 
		ytitle("Share of Total Consumption", margin(medsmall) size(`size'))
		legend(off) 	
		`graph_region_options'
		subtitle(Consumption in Traditional Stores, size(large))	
		name(inf_consumption, replace) ; 
		
		// graph export "graphs/informality_consumption.pdf", replace	;
		
		#delim cr	
		}
	
************************************************************************	
* 3. Combine both figures  
************************************************************************
	
	graph combine inf_labor inf_consumption ,  iscale(0.5) rows(2) xsize(6) xcommon ysize(6) graphregion(color(white)) 
	graph export "graphs/Figure2.pdf", replace						
	
************************************************************************
** Save  Data to construct table 
************************************************************************

	keep b1 country_code log_GDP incomelevelname
	rename country_code iso2 
	rename b1 informal_consumption
	
	merge 1:1 iso2 using "proc/tax_employment_sample.dta"
	
	replace ln_gdp_pc = log_GDP  if ln_gdp_pc == . & _merge == 1
	
	gen sample_only_informal_csption = 0
	replace sample_only_informal_csption = 1 if _m == 1
	drop _m		
	
	save "proc/complete_sample_data.dta", replace 		// Used to construct the Table 
			
			
