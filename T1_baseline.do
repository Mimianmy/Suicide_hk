* HK to 18-district level
clear
local yh 0
local yhw 0
local ay 1
if `yh' == 1{
	global dir " "	
}
global map "$dir/maps"
global raw "$dir/raw"
global data "$dir/data"
global figures "$dir/figures"

if `yhw' == 1{
	global dir ""	
}
global map "$dir/maps"
global raw "$dir/raw"
global data "$dir/data"
global figures "$dir/figures"
global results "$dir/results"

if `ay' == 1{
	global dir ""
}

****************************************
use "$data/suicide_district_panel_gender_age.dta", clear

merge m:1 district using "$data/region_district.dta", nogenerate

collapse (sum) total_suicide (mean) pop_size2021_total, by(year month district_id region)

gen suicide_rate = 100000* total_suicide/pop_size2021_total
egen yearmonth = group(year month)
sort district_id year month
tab yearmonth, gen(yearmonth_)

* Chinese New Year fixed effects
gen nym = 0
replace nym = 1 if year == 2019 & month == 2
replace nym = 1 if year == 2020 & month == 1
replace nym = 1 if year == 2021 & month == 2
replace nym = 1 if year == 2022 & month == 2


* season fixed effects
gen season = 0
replace season = 1 if month <= 5 & month >= 3
replace season = 2 if month <= 8 & month >= 6
replace season = 3 if month <= 11 & month >= 9
replace season = 4 if month == 12 | month == 1 | month == 2


* label
forvalues i = 13/48{
	local year = 2019+int(`i'/12)
	local month = mod(`i',12)
	label var yearmonth_`i' "`year'-`month'"
}

cap erase "$results/T1/T.txt"
cap erase "$results/T1/T.xml"
	
	
*****************************
* with district control - Weight by Pop
*****************************
ppmlhdfe suicide_rate yearmonth_13-yearmonth_48 [w=pop_size2021_total],  a(district_id)  vce(cl district_id) eform
parmest, saving("$results/T_baseline/omit2019/2-Dis.dta", replace)  idstr(sr) idnum(1) eform

local absvars = e(absvars)
local clustvar = e(clustvar)
local model = e(cmd)

outreg2 using "$results/T1/T.xml", append eform pvalue dec(3) nor2 label ///
	addstat(Obs., e(N), R-Square, e(r2_p)) ///
	addtext(Fixed Effect, `absvars', Cluster, `clustvar', Model, `model') 
outreg2 using "$results/T1/T.xml", append eform stats(ci) dec(3) nor2 label ///
	addstat(Obs., e(N), R-Square, e(r2_p)) ///
	addtext(Fixed Effect, `absvars', Cluster, `clustvar', Model, `model') 	

		
