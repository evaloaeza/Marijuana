set more off

gl data "C:\Users\edloaeza\Documents\GitHub\Marijuana"
* Import data
 import delimited "$data\pnas.1903434116.sd01.csv", clear
 
 ren state state_name
merge m:1 state_name using "$data\state_names_codes.dta", keepus(state_abbr state_fips) ///
    keep(match master) nogen
ren state_abbr state

* Bring dates of legalization
merge 1:1 state year using "$data\Medical Marijuana Policy Data\WEB_MJ Policy.dta", ///
    keep(match master) nogen
ren state state_abbr

sort state_fips year
xtset state_fips year

*** Regressions
eststo clear
reghdfe ln_age_mort_rate medical_cannabis_law unemployment *_original if year<=2010, a(state_fips year) vce(r)
est store reg1
qui: estadd local t "1999-2010", replace

eststo clear
reghdfe ln_age_mort_rate medical_cannabis_law unemployment *_update, a(state_fips year) vce(r)
est store reg2
qui: estadd local t "1999-2017", replace

esttab reg1 reg2, label se star(* 0.10 ** 0.05 *** 0.01) ///
title("Age-adjusted opioid overdose death rate per 100,000 population") ///
stats(t N, ///
label("Period ""Observations"))

** Event Study
gen timeToTreat = year - year(date_effMML)
sum timeToTreat if year<=2010

#delimit ;
eventdd ln_age_mort_rate unemployment *_original i.year i.state_fips if year<=2010 , 
timevar(timeToTreat) ci(rcap) 
cluster(state_fips) 
graph_op(ytitle("Point Estimate and 95% Confidence Interval") xlabel(-19(4)14));
#delimit cr

#delimit ;
eventdd age_adjusted_rate unemployment *_update i.year i.state_fips, 
timevar(timeToTreat) ci(rcap) 
cluster(state_fips) 
graph_op(ytitle("Point Estimate and 95% Confidence Interval") xlabel(-20(4)22));
#delimit cr