global root "vip_analysis"


********************************analysis and tables*****************************
use $root\analysis.dta, clear

global depvar "hasClaim"
global basevar1 "BtwithVip_rate irrigationratio PJUN PJUL PAUG PSEP tAvg"
global basevar2 "Btshare_rate vtshare_rate irrigationratio PJUN PJUL PAUG PSEP tAvg"


glm  $depvar $basevar1, family(binomial) link(logit) offset(lnins_acres) 
est store m1
margins, dydx(*) post
est store e1

glm  $depvar $basevar2, family(binomial) link(logit) offset(lnins_acres) 
est store m2
margins, dydx(*) post
est store e2

reg $depvar $basevar1 lnins_acres 
est store e3

reg $depvar $basevar2 lnins_acres 
est store e4

//produce Table 2
esttab m1 e1 m2 e2 e3 e4 using results.rtf, ///
	keep(BtwithVip_rate Btshare_rate vtshare_rate irrigationratio tAvg PJUN PJUL PAUG PSEP lnins_acres _cons ) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	se b(%9.3f) ///
	replace
	
keep if e(sample)
save datatemp.dta, replace


//produce Table 1

use datatemp.dta, clear
asdoc summarize $depvar BtwithVip_rate $basevar2 lnins_acres, tzok format(%9.2f) replace



********************************figures**************************************
*****Fig 1
use bt_scrd.dta, clear //the underlying data cannot be publicaly shared as explained in the manuscript.
keep if year>=2011&year<=2016
collapse (mean) vip_rate_scrd, by(scrd)
merge 1:1 county using "C:\ado\personal\maptile_geographies\county2010_database.dta", nogen
format (vip_rate_scrd) %12.2f

spmap vip_rate_scrd using "C:\ado\personal\maptile_geographies\county2010_coords.dta", ///
	osize(vvthin ..) ndsize(vvthin ..) id(id) clm(c) clb(0 0.05 0.1 0.15 0.20 0.25 0.30 0.35)  ///
	fcolor(Greens) ///
	polygon(data("C:\ado\personal\maptile_geographies\state_coords_dataset.dta") ///
	ocolor(black) osize(vthin)) ///
	legend(title("{bf:Adoption rate (0-1)}",size(medlarge) justification(left)) margin(t=1 b=1) pos(4) ring(1) size(medlarge)) ///
	legend(lab(2 "0.00 - 0.05") lab(3 "0.05 - 0.10") lab(4 "0.10 - 0.15") lab(5 "0.15 - 0.20") lab(6 "0.20 - 0.25") lab(7 "0.25 - 0.30") lab(8 "0.30 - 0.35"))  ///
	saving(Vipadoption, replace)
graph export "Vipadoption.tif", wid(2000) replace  
graph export "Vipadoption.png", wid(2000) replace  


*****Fig 2
use $root\analysis.dta, clear
preserve
collapse (mean) hasClaim Btshare_rate vtshare_rate, by(year)
gen totalBt=Btshare_rate+vtshare_rate
gen zero=0

//red to blue pallette
loc barw=0.8
loc lw=0.2
loc r1 "219 049 036"
loc r2 "252 140 090"
loc r3 "255 223 146"
loc b3 "230 241 243"
loc b2 "144 190 224"
loc b1 "075 116 178"
twoway (rbar totalBt vtshare_rate year, color("`b2'") barw(`barw') lw(`lw')) ///
	(rbar  vtshare_rate zero year, color("`b1'") barw(`barw') lw(`lw')) ///
	(connected hasClaim year , ///
	msymbol(O) lw(1) lpattern(dash) msize(large) mfcolor(white) color("`r1'")) ///
	,xlabel(2011 (1) 2016)  ///
	yscale(range(0 1.3))  ///
	ylabel(0 (0.2) 1, axis(1) format(%03.1f)) ///
	legend(ring(0) position(11) region(lwidth(none)) size(medium) col(1) ///
	order( 1 "Non-vip adoption rate" 2 "Vip adoption rate" 3 "Aflatoxin risk")) ///
	xtitle("Year",size(medium) margin(t=3))  ///	
	ytitle("Bt adoption rate/Aflatoxin risk", axis(1) margin(r=3) size(medium)) ///
	title("{bf:A}",size(medlarge) margin(b=3 r=-3) pos(10)) ///
	saving(trend.gph, replace) 
	
graph display, xsize(4) ysize(5) scale(1)
graph export trend.tif, replace width(2000)
graph export trend.png, replace width(2000)
restore

preserve
collapse (mean) hasClaim Btshare_rate vtshare_rate, by(county_code state_abb)

loc r1 "219 049 036"
loc r2 "252 140 090"
loc r3 "255 223 146"
loc b3 "230 241 243"
loc b2 "144 190 224"
loc b1 "075 116 178"
graph box Btshare_rate vtshare_rate hasClaim,over(state_abb) ///
	box(1,lcolor("`b2'") color("`b3'") ) ///
	box(2,lcolor("`b1'") color("`b2'") ) ///
	box(3,lcolor("`r1'") color("`r2'") ) ///
	marker(1,mlcolor("`b2'") mfcolor("`b3'") ) ///
	marker(2,mlcolor("`b1'") mfcolor("`b2'") ) ///
	marker(3,mlcolor("`r1'") mfcolor("`r2'") ) ///
	yscale(range(0 1.3))  ///
	ylabel(0 (0.2) 1, format(%03.1f)) ///
	legend(ring(0) position(11) region(lwidth(none)) size(medium) col(1) ///
	order( 1 "Non-vip adoption rate" 2 "Vip adoption rate" 3 "Aflatoxin risk")) ///
	b1title("State",size(medium) margin(t=3))  ///	
	ytitle("Bt adoption rate/Aflatoxin risk", axis(1) margin(r=3) size(medium)) ///
	title("{bf:B}",size(medlarge)  margin(b=3 r=-3) pos(10)) ///
	saving(spatial.gph, replace) 

restore

graph combine trend.gph  spatial.gph
graph export desp.tif, wid(2000) replace  
graph export desp.png, wid(2000) replace  


******Fig 3
forv i=2011/2016{
use temp.dta, clear
est restore m2
keep if year==`i'
predict y`i', mu
gen vtshare_rate`i'=vtshare_rate
replace vtshare_rate=0 
gen Btshare_rate`i'=Btshare_rate
replace Btshare_rate=BtwithVip_rate
predict yhat`i', mu
gen ydif`i'=yhat`i'-y`i'
collapse (mean) vtshare_rate`i' Btshare_rate`i' y`i' yhat`i' ydif`i', by(state_abb state_code)
save sim_`i'.dta, replace
}

use sim_2011.dta, clear
merge 1:1 state_abb using  sim_2012.dta, nogen
merge 1:1 state_abb using  sim_2013.dta, nogen
merge 1:1 state_abb using  sim_2014.dta, nogen
merge 1:1 state_abb using  sim_2015.dta, nogen
merge 1:1 state_abb using  sim_2016.dta, nogen

reshape long vtshare_rate Btshare_rate y yhat ydif, i(state_code state_abb) j(year)
gen yratio1=ydif/yhat
egen yratiocut1 = cut(yratio1), at(0(0.1)0.5) icodes label

gen state_axis=0
replace state_axis=1 if state_abb=="AR"
replace state_axis=2 if state_abb=="KS"
replace state_axis=3 if state_abb=="LA"
replace state_axis=4 if state_abb=="MS"
replace state_axis=5 if state_abb=="OK"
replace state_axis=6 if state_abb=="TX"

loc g1 "237 248 233"
loc g2 "199 233 192"
loc g3 "115 192 117"
loc g4 "29 136 63"
loc g5 "0 90 50"

twoway 	(scatter year state_axis if yratiocut1==0, msymbol(square) msize(vhuge) mcolor("`g1'") legend(label(1 "0%-10%"))) ///
		(scatter year state_axis if yratiocut1==1, msymbol(square) msize(vhuge) mcolor("`g2'") legend(label(2 "10%-20%"))) ///
		(scatter year state_axis if yratiocut1==2, msymbol(square) msize(vhuge) mcolor("`g3'") legend(label(3 "20%-30%"))) ///
		(scatter year state_axis if yratiocut1==3, msymbol(square) msize(vhuge) mcolor("`g4'") legend(label(4 "30%-40%"))) ///
		(scatter year state_axis if yratiocut1==4, msymbol(square) msize(vhuge) mcolor("`g5'") legend(label(5 "40%-50%"))) ///
		,ylabel(,angle(0)) yscale(range(2010 2017)) ///
		xlabel(1 "AR" 2 "KS" 3 "LA" 4 "MS" 5 "OK" 6 "TX") xscale(range(0 7)) ///
		ytitle("Year", size(medium) margin(r=2)) xtitle("State",size(medium) margin(t=2)) ///
		legend(region(lw(0)) col(1) ring(1) position(3))
graph dis, xsize(1.5) ysize(1) scale(1.4) 
graph save ysim1.gph, replace
graph export ysim1.tif, wid(2000) replace  
graph export ysim1.png, wid(2000) replace  























