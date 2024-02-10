
					*************************************************
					* 		Tax Ratios, JEP paper 					*
					*		Authors: Pierre Bachas, Lucie Gadenne	*
					*		Date: June 2023							*
					*		Fig1_Tax_ratios.do						*
					*************************************************
							
	set more off
				
	// ssc install asdoc
	// ssc install niceloglabels
	
************************************************************************	
* 1. Tax revenue 
************************************************************************

	** Bring in Population and GDP, World Development Indicators World Bank 
	use "data/gdp_population_WDI.dta", replace 
	keep if year == 2018 
	drop year
	tempfile pop
	save `pop'
	
	*Bring in Oil and Gas Rich status countries from Ross-Mahdavi (2015) 
	use "data/ross_mahdavi.dta" , replace
	keep if year == 2013 // max number of countries available
	rename oil_pct oil_pct_2013
	keep country oil_pct_2013
	tempfile oil
	save `oil'	
	
	* merge with tax rates data
	use "data/globalETR_bfjz.dta" , replace
	
	count if year == 2018
	count if year == 2018 & pct_tax != . 		// 150 countries (all countries with more than 1 Million inhabitant)
	sum pct_tax if year == 2018  , d
	keep if year == 2018 	
	
	merge 1:1 country using `pop' 
	keep if _m ==3 			// Taiwan didnt merge 
	drop _m 
	
	merge 1:1 country using `oil' 
	drop if _m == 2	
	drop _m 	
	
	gen  iso3 = country 
	
	*** Add income classification and continents from WB (country_frame)
	merge 1:1 iso3 using "data/country_frame.dta" 
	drop if _m != 3
	drop _m 
	
	** Apply 2 sample conditions: (1) more than 1M inhabitants, (2) less than 33% of GDP arises from oil and gas production
	
	list country_name if pop<= 1000000
	drop if pop<= 1000000 									// 10 small countries dropped
	list country_name oil_pct if oil_pct_2013>= 0.33
	drop if 	oil_pct_2013>= 0.33 & oil_pct_2013!= . 		// 7 oil and gas producers dropped
		
	******************************************************  
	* SAMPLE SIZE for Figures 
	******************************************************
	count 		// 131 countries 
	
	* Translate from NDP ratios to GDP ratios
	gen gdp_to_ndp = gdp_currentusd / ndp_usd
	
	foreach var in pct_tax pct_1100 pct_1200 pct_2000 pct_4000 pct_5000 pct_6000{
		replace `var ' = 100*(`var' / gdp_to_ndp)
		format %10.0g `var'
		}
	
	gen pct_tax_noSSC = pct_tax - pct_2000
	gen pct_other_taxes = pct_1200 + pct_4000 + pct_6000
	
	gen gdp_pc = gdp_currentusd / pop
	gen ln_gdp_pc = ln(gdp_pc)
	
	gen ndp_pc = ndp_usd / pop
	gen ln_ndp_pc = ln(ndp_pc)
		
	
	** Total tax revenue + social security contributions (% of Gross Domestic Product) 
	niceloglabels gdp_pc , local(xlab) style(125)
	display "`xlab'"
	local xlab "500 1000 2000 5000 10000 25000 50000"			
	
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("GDP per capita (Constant 2010 USD, log scale)", margin(medsmall) size(`size'))"
	local xaxis "xscale(log) xlabel(`xlab', ang(h) labsize(`size'))"
	local yaxis "ylabel(0(10)60, nogrid labsize(`size')) yscale(range(0 60)) yline(0(10)60, lstyle(minor_grid) lcolor(gs1))" 

		#delim ;		
		
		twoway (scatter pct_tax gdp_pc, color(gs1)),			// add country labels:  mlabel(country)  mlabsize(2.5) mlabcolor(gs10*1.5))
		`xaxis' 
		`yaxis' 
		`xtitle' 
		ytitle("Share of GDP (%)", margin(medsmall) size(`size'))
		legend(off) 	
		`graph_region_options'	; 
		
		 // graph export "graphs/gdp_ratio_total_tax.pdf", replace	;
		
		#delim cr	

	** Total tax revenue (No social security contributions) (% of Gross Domestic Product) 
	gen Gpct_tax_noSSC = pct_tax_noSSC / 100
	
	niceloglabels gdp_pc , local(xlab) style(125)		
	display "`xlab'"
	local xlab "500 1000 2000 5000 10000 25000 50000"	
				
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("GDP per capita (Constant 2010 USD, log scale)", margin(medsmall) size(`size'))"
	local xaxis "xscale(log) xlabel(`xlab', ang(h) labsize(`size'))"
	local yaxis "ylabel(0(0.1)0.4, nogrid labsize(`size')) yscale(range(0 0.45)) yline(0(0.1)0.4, lstyle(minor_grid) lcolor(gs1))" 
	
		#delim ;		
		
		twoway (scatter Gpct_tax_noSSC gdp_pc, color(gs1)) (lpoly Gpct_tax_noSSC gdp_pc, color(gs1) bwidth(0.5)) ,	
		`xaxis' 
		`yaxis' 
		// `xtitle' 
		ytitle("Share of GDP", margin(medsmall) size(`size'))
		legend(off) 
		subtitle("Total Tax Revenue (excl. SSC)", size(large))
		`graph_region_options'	
		name(G1, replace) ; 
		
	 // graph export "graphs/Total_tax_noSSC.pdf", replace	;
		
	#delim cr
	drop Gpct_tax_noSSC
		
	** Indirect tax revenue  (% of Gross Domestic Product) 	
	local yaxis "ylabel(0(5)25, nogrid labsize(`size')) yscale(range(0 25)) yline(0(5)25, lstyle(minor_grid) lcolor(gs1))" 
						
		#delim ;		
		
		twoway (scatter pct_5000 gdp_pc, color(gs1)) (lpoly pct_5000 gdp_pc, color(gs1) bwidth(0.5)) ,	
		`xaxis' 
		`yaxis' 
		`xtitle' 
		ytitle("Share of GDP (%)", margin(medsmall) size(`size'))
		legend(off) 	
		subtitle(Indirect Taxes)	
		`graph_region_options'	
		name(G2, replace) ; 
		
		// graph export "graphs/gdp_ratio_indirect.pdf", replace	;
		
		#delim cr	
		
	** Total PIT  (% of Gross Domestic Product) 
	local yaxis "ylabel(0(5)25, nogrid labsize(`size')) yscale(range(0 25)) yline(0(5)25, lstyle(minor_grid) lcolor(gs1))" 

		#delim ;		
		
		twoway (scatter pct_1100 gdp_pc, color(gs1)) (lpoly pct_1100 gdp_pc, color(gs1) bwidth(0.5)) ,		//  mlabel(country)  mlabsize(2.5) mlabcolor(gs10*1.5)
		`xaxis' 
		`yaxis' 
		`xtitle' 
		ytitle("Share of GDP (%)", margin(medsmall) size(`size'))
		legend(off) 	
		subtitle(Personal Income Tax)		
		`graph_region_options'	
		name(G3, replace) ; 
		
		// graph export "graphs/gdp_ratio_PIT.pdf", replace	;
		
		#delim cr			
		
	** All other taxes (but not SSC) = CIT, property and wealth, other taxes
	local yaxis "ylabel(0(5)25, nogrid labsize(`size')) yscale(range(0 25)) yline(0(5)25, lstyle(minor_grid) lcolor(gs1))" 

		#delim ;		
		
		twoway (scatter pct_other_taxes gdp_pc, color(gs1)) (lpoly pct_other_taxes gdp_pc, color(gs1) bwidth(0.5))  ,		//  mlabel(country)  mlabsize(2.5) mlabcolor(gs10*1.5)
		`xaxis' 
		`yaxis' 
		`xtitle' 
		ytitle("Share of GDP (%)", margin(medsmall) size(`size'))
		legend(off) 	
		subtitle("All Other Taxes (CIT, property, etc.)")		
		`graph_region_options'	
		name(G4, replace) ; 
		
		 // graph export "graphs/gdp_ratio_other_taxes.pdf", replace	;
		#delim cr		
		
************************************************************************	
* 2. Tax Ratios: Share of a given tax in total tax revenue
************************************************************************
	
	foreach var in pct_tax_noSSC pct_1100 pct_5000 pct_other_taxes pct_1200  pct_4000  pct_6000 {
		gen r_`var ' = `var' / pct_tax_noSSC
	}
	
	** PIT Ratio of all taxes (no SSC)	
	niceloglabels gdp_pc , local(xlab) style(125)
	display "`xlab'"
	local xlab "500 1000 2000 5000 10000 25000 50000"	
		
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("GDP per capita (Constant 2010 USD, log scale)", margin(medsmall) size(`size'))"
	local xaxis "xscale(log) xlabel(`xlab', ang(h) labsize(`size'))"
	local yaxis "ylabel(0(0.2)1, nogrid labsize(`size')) yscale(range(0 1)) yline(0(0.2)1, lstyle(minor_grid) lcolor(gs1))" 
	local ytitle "ytitle("Share of Tax Revenue", margin(medsmall) size(`size'))"
	
	#delim ;	
		
		twoway (scatter r_pct_5000 gdp_pc, color(gs6)) (lpoly r_pct_5000 gdp_pc, color(gs8) bwidth(0.5)) , 
		`xaxis' 
		`yaxis'  
		// `xtitle' 
		`ytitle'
		legend(off) 	
		subtitle(Indirect Taxes, size(large))			
		`graph_region_options'	
		name(R1, replace) ;  
		// graph export "graphs/tax_ratio_indirect.pdf", replace	;		
	
		#delim ;	
		twoway (scatter r_pct_1100 gdp_pc, color(gs6)) (lpoly r_pct_1100 gdp_pc, color(gs8) bwidth(0.5)) , 
		`xaxis' 
		`yaxis'  
		`xtitle' 
		`ytitle'		
		legend(off) 	
		subtitle(Personal Income Tax, size(large))	
		`graph_region_options'	
		name(R2, replace) ;  
		// graph export "graphs/tax_ratio_PIT.pdf", replace	;
				
		
		#delim ;	
		twoway (scatter r_pct_other_taxes gdp_pc, color(gs6)) (lpoly r_pct_other_taxes gdp_pc, color(gs8) bwidth(0.5)) , 
		`xaxis' 
		`yaxis'  
		`xtitle' 
		`ytitle'
		legend(off) 	
		subtitle(All Other Taxes, size(large))	
		`graph_region_options'	
		name(R3, replace) ;  			
		// graph export "graphs/tax_ratio_other.pdf", replace	;
		
		#delim cr		
		
		
	************************************************************************	
	* 3. Figure 1: Combine all four panels
	************************************************************************		
		
	graph combine G1 R1 R2 R3 ,  iscale(0.35) rows(2) xsize(6) ysize(6) graphregion(color(white)) 
	graph export "graphs/Figure1.pdf", replace							
		
	** Save data: to make the informality of labor sample comparable later in Figure 2
	save "proc/tax_sample.dta", replace
			
		

		
		
		
		

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
	
