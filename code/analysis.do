/* 
Effects of Medical Marijuana Legalization Laws on Opiods Deaths
Author: Eva Loaeza

*/

set more off

gl user "C:\Users\edloaeza\Documents\GitHub\Marijuana"
gl data "$user\data"

*****************************************************************************
* Import data
 import delimited "$data\pnas.1903434116.sd01.csv", clear
 
** Bring State Fips Code
ren state state_name
merge m:1 state_name using "$data\state_names_codes.dta", keepus(state_abbr state_fips) ///
    keep(match master) nogen
ren state_abbr state

* Bring dates of legalization
merge 1:1 state year using "$user\Medical Marijuana Policy Data\WEB_MJ Policy.dta", ///
    keep(match master) nogen
ren state state_abbr

* Brin state population
merge 1:1 state_fips year using "$data\state_population.dta", keep(match master) nogen

sort state_fips year
xtset state_fips year

* Crete year and state dummies
xi i.year*i.state_fips
drop _IyeaXsta*

** Estimates for the original 1999–2010 time period

** Using Three different commands
reghdfe ln_age_mort_rate medical_cannabis_law unemployment *_original if year<=2010, ///
    a(state_fips year) cluster(state_fips)
	est store reg1
qui: estadd local t "1999-2010", replace
	
reg ln_age_mort_rate medical_cannabis_law unemployment *_original ///
_Iyear_2000 - _Iyear_2010 _Istate_fip* if year<=2010, r

xtreg ln_age_mort_rate medical_cannabis_law unemployment *_original ///
_Iyear_2000 - _Iyear_2010 if year<=2010, fe r

return list
matrix A=r(table)'
mat list A
local b1 A[1,1]
dis (exp(A[1,1])-1)*100
dis (exp(A[1,5])-1)*100
dis (exp(A[1,6])-1)*100

ereturn list
matrix list e(b)

dis (exp(e(b)[1,1])-1)*100

** Using the full 1999–2017 dataset
eststo clear
reghdfe ln_age_mort_rate medical_cannabis_law unemployment *_update, a(state_fips year) cluster(state_fips)
est store reg2
qui: estadd local t "1999-2017", replace

esttab reg1 reg2, label se star(* 0.10 ** 0.05 *** 0.01) ///
title("Age-adjusted opioid overdose death rate per 100,000 population") ///
stats(t N, ///
label("Period ""Observations"))

** Poissson
poisson age_adjusted_rate medical_cannabis_law unemployment *_update _I*, vce(r)

** Event Study
gen timeToTreat = year - year(date_effMML)
sum timeToTreat if year<=2010

eventdd ln_age_mort_rate unemployment *_original i.year i.state_fips [w=totpop] if year<=2010 , ///
timevar(timeToTreat) ci(rcap) cluster(state_fips) ///
graph_op(ytitle("Point Estimate and 95% Confidence Interval") xlabel(-19(4)14))

eventdd age_adjusted_rate unemployment *_update i.year i.state_fips [w=totpop], ///
timevar(timeToTreat) ci(rcap) cluster(state_fips) ///
graph_op(ytitle("Point Estimate and 95% Confidence Interval") xlabel(-20(4)22))

* Average trends
preserve
egen withlaw=max( medical_cannabis_law), by(state_fips)
gen nolaw= withlaw==0
collapse (mean) age_adjusted_rate, by(year nolaw)
reshape wide age_adjusted_rate, i(year) j( nolaw)
tsline age_adjusted_rate0 if year<=2010 || tsline age_adjusted_rate1 if year<=2010
restore