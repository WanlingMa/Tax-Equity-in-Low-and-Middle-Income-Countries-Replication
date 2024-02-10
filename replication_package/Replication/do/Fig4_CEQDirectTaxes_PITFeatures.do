					*****************************************************************
					* 		JEP paper 												*
					*	Authors: Pierre Bachas, thanks to Mariano Sosa				*
					*		Date: July 2023											*
					*		Fig4_CEQDirectTaxes_PITFeatures.do						*
					*****************************************************************

	** Produces figure of Tax incidence of the PIT : Figure 4		

	************************************************************************	
	* 0. Prep CEQ
	************************************************************************	
	
	local usualsuspects source class_pspr oecd ctry_year ctry_ceq year ctry ctry_code class_geo class_inc class_inc_code class_pspr class_pspr_code class_lend class_weo decile decnum ctry_code pen_scenario

	use "data/PSPR_incidence_dirtax_2023.dta" , replace		 // Data from PSPR, sent by Mariano Sosa (World Bank 2022)
	
 	keep `usualsuspects'  in_*_dirtax
	
	// UNCLEAR IF WE WANT TO DO THIS:
	replace class_inc = "lmic" if class_inc == "lic"			// We onlhy have 6 countries in LICs so maybe better to merge

	*save "C:\Users\wb569502\OneDrive - WBG\PSPR_2022\PSPR_background_paper_2023\data\PSPR_incidence_dirtax.dta", replace
	
		*--------------------------------------------
		local 	varname 	= 	  "dirtax" //change this manually. Export file name
		local	graphvariable	  in_*_dirtax
		local	datatype		  incidence
		local	classificvariable class_inc //class_pspr_code for direct tax and transf, clas_inc_code for the rest
		local   reportstat        "median"
		
		*--------------------------------------------
	
	keep 		`graphvariable' `indirflag' `usualsuspects' 	//keep only indicator to reduce the database sameple and speed up the process
	sort 		ctry year decnum
	rename  	*_pdi_* pdi_var
	cap rename 	*_pgt_* pgt_var

	*select pdi scenario if available, otherwise select pgt if available.
	generate 	varofint=abs(pdi_var)*100 
	cap replace varofint=abs(pgt_var)*100 if pdi_var==.

	cap drop 	pdi_* pgt_* ie_flag_p*

	* for countries with more than one project, pick the last one
	bysort 		ctry: egen yearmax=max(year) if varofint!=.		//this one generates a variable with a constant equal to the latest year for each country, only for those observations where there is a datapoint. 
				egen yearmax_av= mean(yearmax), by(ctry)  		//some countries may have a missing in 1 decile (but observations for the remaining deciles). This is an auxiliary variable to later fill in those gaps.
				replace yearmax=yearmax_av if year==yearmax_av	//this line fills in any gap in a particular decile. Like D1 for south africa. or D10 for USAs energy subsidies.
	keep if 	year==yearmax
	drop 		yearmax yearmax_av
	tab			ctry source if decnum==5 &varofint!=.
	
	tab class_inc if decnum==5 
	
	collapse (`reportstat') varofint (count) count=varofint , by(`classificvariable' decnum)	
	
	la var   varofint "`reportstat'-`varname'"

	order  class_inc `classificvariable' decnum

	drop if decnum==11

	************************************************************************	
	* 1. Figure CEQ : panel A
	************************************************************************
	
	twoway scatter varofint decnum , by(class_inc)	
	
	** Scatter plot one by one 
	
	** Load Locals
	local size med
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Income Decile (within country)", margin(medsmall) size(`size'))"
	local yaxis "ylabel(0(5)20, nogrid labsize(`size')) yscale(range(0 22)) yline(0(5)20, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(1(1)10, labsize(`size')) xscale(range(1 10))"	
	local ytitle "ytitle("Average Tax Rate", margin(medsmall) size(`size'))"
	
		#delim ;			
		
		twoway (connected varofint decnum if class_inc == "hic", color(emidblue)),  
		`xaxis' 
		`yaxis' 
		`xtitle' 
		`ytitle'
		legend(off) 	
		`graph_region_options'
		subtitle(High Income Countries)	
		name(G_hic, replace) ; 		
		
		#delim ;			
		
		twoway (scatter varofint decnum if class_inc == "lmic", color(emidblue)),  
		`xaxis' 
		`yaxis' 
		`xtitle' 
		`ytitle'
		legend(off) 	
		`graph_region_options'
		subtitle(Upper Middle Income Countries)	
		name(G_umic, replace) ; 				
		
		#delim ;			
		
		twoway (scatter varofint decnum if class_inc == "lmic", color(emidblue)),  
		`xaxis' 
		`yaxis' 
		`xtitle' 
		`ytitle'
		legend(off) 	
		`graph_region_options'
		subtitle(Low and Lower Middle Income Countries)	
		name(G_lmic, replace) ; 	
			
		#delim cr	
	
	** Combined scatter plot  
	local size medsmall
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("Income Decile (within country)", margin(medsmall) size(`size'))"
	local yaxis "ylabel(0(5)20, nogrid labsize(`size')) yscale(range(0 22)) yline(0(5)20, lstyle(minor_grid) lcolor(gs1))" 
	local xaxis "xlabel(1(1)10, labsize(`size')) xscale(range(1 10))"	
	local ytitle "ytitle("Average Tax Rate", margin(medsmall) size(`size'))"
	
		#delim ;			
		
		twoway (connected varofint decnum if class_inc == "hic", color(forest_green) ms(square)) 
		(connected varofint decnum if class_inc == "lmic", color(sienna))
		(connected varofint decnum if class_inc == "umic", color(purple) ms(diamond)),  
		text(18.5 7.3 "High Income", place(e) color(forest_green))	
		text(7.8 7.2 "Upper-Middle Income", place(e) color(purple))	
		text(1 8.5 "Lower Income", place(e) color(sienna))	// text(41 2040 "VW Diesel", place(e)) 	text(41 2040 "VW Diesel", place(e))	
		`xaxis' 
		`yaxis' 
		`xtitle' 
		`ytitle'
		legend(off) 	
		`graph_region_options'
		subtitle("De-Facto Distributional Incidence of Direct Taxes" , size(medlarge))		
		name(incidence, replace) ; 		
		
		#delim cr	
	
************************************************************************	
* 2. Data prep Statutory Features of PIT: Panel B and C
************************************************************************
	
	use "data/PIT_parameters_AJ.dta", clear	// Data on breadth of tax base (threshold exemption)
	
	bysort country: egen max_year = max(year)
	keep if year == max_year
	
	rename country_code iso2
	
	keep iso2 lg_gdppc size_pit

	tempfile threshold
	save `threshold'		
	
	insheet using "data/PIT_Top_Rates_2022.csv", clear names		// Data on top Marginal Tax Rates, collected by authors as of 2022
	
	destring top_rate, force replace
	rename alpha_2 iso2
	
	drop if iso2 == "CI".  // Cote D'Ivoire has a distinct system 
	
	keep iso2 top_rate
	tempfile PIT_rates
	save `PIT_rates'	
	
	// Collate on same sample as in Figure 1 earlier in the paper ? (Or same as the redistribution panel?)
	
	use "proc/complete_sample_data.dta" , clear
	drop if sample_only_informal_csption == 1		
	drop sample_only_informal_csption

	merge 1:1 iso2  using `PIT_rates'
	keep if _m == 3
	drop _m 	
	
	merge 1:1 iso2  using `threshold'	
	gen threshold_only = 0
	replace threshold_only  = 1 if _m == 2
	drop _m
	
	// Size of samples used cited in papers 
	count if top_rate!= . 
	count if size_pit!= . 
	
	gen income_groups = 1 if incomelevelname == "Low income"
 	replace income_groups = 2 if incomelevelname == "Lower middle income"	
 	replace income_groups = 3 if incomelevelname == "Upper middle income"		
 	replace income_groups = 4 if incomelevelname == "High income"			
	
	label define income_group 1 "Low income"  2 "Lower middle income"  3 "Upper middle income"  4 "High income" , replace 
	label values income_groups income_group	
	
	tab income_groups	, m
	
	bysort income_groups: sum top_rate, d
	sum top_rate if income_groups == 4 , d	 	// Rich countries 36% average 
	sum top_rate if income_groups != 4 , d		// Dev countries 29% average 
	
************************************************************************	
* 3. Figures Statutory figures
************************************************************************
		
	** Top MTR 
	
	local xlab "500 1000 2000 5000 10000 25000 50000"			
	
	local size medsmall
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("GDP per capita (Constant 2010 USD, log scale)", margin(medsmall) size(`size'))"
	local xaxis "xscale(log) xlabel(`xlab', ang(h) labsize(`size'))"
	local yaxis "ylabel(0(10)60, nogrid labsize(`size')) yscale(range(0 60)) yline(0(10)60, lstyle(minor_grid) lcolor(gs1))" 
	local color1 forest_green
	local color2 purple
	local color3 sienna	
	
		#delim ;			
		
		twoway (scatter top_rate gdp_pc if gdp_pc >= 13000, color(`color1') ms(square)) 
		(scatter top_rate gdp_pc if  gdp_pc < 13000 & gdp_pc>=4000, color(`color2') ms(diamond))  
		(scatter top_rate gdp_pc if  gdp_pc < 4000, color(`color3'))  
		(lpoly top_rate gdp_pc, color(`color') bwidth(0.5)),  
		`xaxis' 
		`yaxis' 
		`xtitle' 
		ytitle("Tax Rate", margin(medsmall) size(`size'))
		legend(off) 	
		`graph_region_options'
		subtitle(Top Statutory Tax Rate of Personal Income Tax, size(medlarge))	
		name(top_mtr, replace) ; 			
		
		#delim cr
	
	** PIT Exemption threshold 
	// Note we will use the lg_gdppc measure directly from the Jensen data as the data is older and years dont correspond
	cap drop gdppc
	gen gdppc = exp(lg_gdppc)
	local xlab "500 1000 2000 5000 10000 25000 50000"			
			
	local size medsmall
	local graph_region_options "graphregion(color(white)) bgcolor(white) plotregion(color(white))"
	local xtitle "xtitle("GDP per capita (Constant 2010 USD, log scale)", margin(medsmall) size(`size'))"
	local xaxis "xscale(log) xlabel(`xlab', ang(h) labsize(`size'))"
	local yaxis "ylabel(0(20)100, nogrid labsize(`size')) yscale(range(0 100)) yline(0(20)100, lstyle(minor_grid) lcolor(gs1))" 
	// local color ebblue
	local color1 forest_green
	local color2 purple
	local color3 sienna	
	
		#delim ;			
		
		twoway (scatter size_pit gdppc if  gdppc >= 13000, color(`color1') ms(square)) 
		(scatter size_pit gdppc if  gdppc < 13000 & gdppc>=4000, color(`color2') ms(diamond)) 
		(scatter size_pit gdppc if gdppc < 4000, color(`color3')) 
		(lpoly size_pit gdppc, color(`color') bwidth(0.5)),  
		`xaxis' 
		`yaxis' 
		`xtitle' 
		ytitle("Share of Workforce", margin(medsmall) size(`size'))
		legend(off) 	
		`graph_region_options'
		subtitle("Share of Workforce Legally Subject to Personal income Tax", size(medlarge))
		name(size_pit, replace) ; 		
		
			#delim cr

	
************************************************************************	
* 4. Combine All three figures into 1 
************************************************************************
		
	graph combine incidence size_pit top_mtr  ,  iscale(0.6) rows(3) xsize(5) ysize(8) graphregion(color(white)) 
	graph export "graphs/Figure4.pdf", replace				
	
	
	
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	


	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	