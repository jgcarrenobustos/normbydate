*===============================================================================
* Test script for normbydate.ado
* Date: October 8, 2025
* Purpose: Comprehensive testing of the normbydate function
*===============================================================================


clear all
set more off

* Add current directory to adopath for normbydate.ado
adopath ++ .
* Alternative: add explicit path
adopath ++ "c:\Users\jgcar\Mi unidad\Research\__other\StataAdo"





*===============================================================================


clear all

cd "C:\Users\jgcar\Mi unidad\Research\__other\StataAdo\normbydate"
use "GrowthClimateDataset", clear


*1
use "GrowthClimateDataset", clear
keep isocode year gdpCAPppp_wdi
rename gdpCAPppp_wdi gdp_pc
keep if year>1990
keep if year<2010

format year %ty
normbydate gdp_pc , date("2000") datevar(year) by(isocode)


xtset isocode  year
xtline gdp_pc, overlay legend(off) xtitle(" ")
graph export "example1_raw.png" , width(1600)
xtline norm_gdp_pc, overlay legend(off) xtitle(" ") ytitle("Normalized GDP per capita, PPP (WDI)")
graph export "example1_norm.png" , width(1600)



*===============================================================================
* Test 1: Daily data with by() groups
*===============================================================================
di as txt "========================================"
di as txt "Test 1: Daily data with by() groups"
di as txt "========================================"

clear
set obs 50

* Create test data
gen id = mod(_n-1, 5) + 1
gen date_num = td(1jan2020) + _n - 1
format date_num %td
gen value = 100 + 10*sin(_n/5) + rnormal(0,5)

* Test basic functionality
normbydate value, date("10feb2020") datevar(date_num) by(id)
list id date_num value norm_value in 1/10

* Test with custom generate name
normbydate value, date("05jan2020") datevar(date_num) by(id) generate(custom_norm)
list id date_num value custom_norm in 1/10

* Test with scale=100
normbydate value, date("05jan2020") datevar(date_num) by(id) generate(norm100) scale(100)
list id date_num value norm100 in 1/10

*===============================================================================
* Test 2: Monthly data
*===============================================================================
di as txt "========================================"
di as txt "Test 2: Monthly data"
di as txt "========================================"

clear
set obs 36

* Create monthly data
gen company = mod(_n-1, 3) + 1
gen month_num = tm(2020m1) + _n - 1
format month_num %tm
gen sales = 1000 + 100*company + 50*sin(_n/6) + rnormal(0,20)

* Test different date formats
normbydate sales, date("2020-03") datevar(month_num) by(company)
list company month_num sales norm_sales in 1/12

* Test with different date format
normbydate sales, date("2020m6") datevar(month_num) by(company) generate(norm_june) replace
list company month_num sales norm_june in 15/25

*===============================================================================
* Test 3: Yearly data
*===============================================================================
di as txt "========================================"
di as txt "Test 3: Yearly data"
di as txt "========================================"

clear
set obs 20

* Create yearly data
gen country = mod(_n-1, 2) + 1
gen year_num = ty(2010) + _n - 1
format year_num %ty
gen gdp = 10000 + 1000*country + 500*(_n-10) + rnormal(0,100)

* Test yearly normalization
normbydate gdp, date("2015") datevar(year_num) by(country)
list country year_num gdp norm_gdp

*===============================================================================
* Test 4: Single observation case (no by() required)
*===============================================================================
di as txt "========================================"
di as txt "Test 4: Single observation at baseline"
di as txt "========================================"

clear
set obs 10

gen date_num = td(1jan2020) + _n - 1
format date_num %td
gen value = 100 + _n*5

* This should work - only one obs at baseline
normbydate value, date("05jan2020") datevar(date_num)
list date_num value norm_value

*===============================================================================
* Test 5: Error cases
*===============================================================================
di as txt "========================================"
di as txt "Test 5: Error cases"
di as txt "========================================"

clear
set obs 20

gen id = mod(_n-1, 2) + 1
gen date_num = td(1jan2020) + _n - 1
format date_num %td
gen value = 100 + _n*2

* Test 5a: Multiple observations at baseline without by()
di as txt "Test 5a: Multiple observations at baseline without by() (should error)"
capture normbydate value, date("02jan2020") datevar(date_num)
if _rc != 0 {
    di as txt "Expected error occurred: " _rc
}

* Test 5b: Invalid date format with td()
di as txt "Test 5b: Invalid date format with td() (should error)"
capture normbydate value, date("td(02jan2020)") datevar(date_num) by(id)
if _rc != 0 {
    di as txt "Expected error occurred: " _rc
}

* Test 5c: No observations at baseline
di as txt "Test 5c: No observations at baseline (should error)"
capture normbydate value, date("01jan2030") datevar(date_num) by(id)
if _rc != 0 {
    di as txt "Expected error occurred: " _rc
}

*===============================================================================
* Test 6: Replace option
*===============================================================================
di as txt "========================================"
di as txt "Test 6: Replace option"
di as txt "========================================"

clear
set obs 10

gen date_num = td(1jan2020) + _n - 1
format date_num %td
gen value = 100 + _n*5
gen norm_value = 999  // Existing variable

* Test without replace (should error)
di as txt "Test 6a: Without replace option (should error)"
capture normbydate value, date("03jan2020") datevar(date_num)
if _rc != 0 {
    di as txt "Expected error occurred: " _rc
}

* Test with replace (should work)
di as txt "Test 6b: With replace option (should work)"
normbydate value, date("03jan2020") datevar(date_num) replace
list date_num value norm_value

*===============================================================================
* Test 7: Missing baseline in some groups
*===============================================================================
di as txt "========================================"
di as txt "Test 7: Missing baseline in some groups"
di as txt "========================================"

clear
set obs 15

gen group = mod(_n-1, 3) + 1
gen date_num = td(1jan2020) + _n - 1
format date_num %td
gen value = 100 + 10*group + _n*2

* Remove baseline observation from group 2
drop if group == 2 & date_num == td(05jan2020)

normbydate value, date("05jan2020") datevar(date_num) by(group)
list group date_num value norm_value, sepby(group)

*===============================================================================
* Test 8: Different date parsing formats
*===============================================================================
di as txt "========================================"
di as txt "Test 8: Different date parsing formats"
di as txt "========================================"

clear
set obs 10

gen date_num = td(15mar2020) + _n - 1
format date_num %td
gen value = 100 + _n*3

* Test different date formats for the same date
normbydate value, date("19mar2020") datevar(date_num) generate(norm1)
normbydate value, date("2020-03-19") datevar(date_num) generate(norm2)
normbydate value, date("19/03/2020") datevar(date_num) generate(norm3)

list date_num value norm1 norm2 norm3

*===============================================================================
* Test 9: Return values
*===============================================================================
di as txt "========================================"
di as txt "Test 9: Return values"
di as txt "========================================"

clear
set obs 10

gen group = mod(_n-1, 2) + 1
gen date_num = td(1jan2020) + _n - 1
format date_num %td
gen value = 100 + 10*group + _n*2

normbydate value, date("03jan2020") datevar(date_num) by(group)

* Display return values
di as txt "Return values:"
di as txt "  baseline_val: " r(baseline_val)
di as txt "  baseline_disp: " r(baseline_disp)
di as txt "  freq: " r(freq)
di as txt "  by_used: " r(by_used)
di as txt "  N_groups: " r(N_groups)
di as txt "  N_groups_miss: " r(N_groups_miss)
di as txt "  p_groups_miss: " r(p_groups_miss)
di as txt "  N_normalized: " r(N_normalized)
di as txt "  N_norm_missing: " r(N_norm_missing)

*===============================================================================
* Test 10: Large dataset performance
*===============================================================================
di as txt "========================================"
di as txt "Test 10: Large dataset performance"
di as txt "========================================"

clear
set obs 10000

gen group = mod(_n-1, 100) + 1
gen date_num = td(1jan2020) + mod(_n-1, 365)
format date_num %td
gen value = 1000 + 10*group + rnormal(0,50)

timer clear
timer on 1
normbydate value, date("01jul2020") datevar(date_num) by(group)
timer off 1
timer list 1

di as txt "Performance test completed"
summarize norm_value

di as txt "========================================"
di as txt "All tests completed successfully!"
di as txt "========================================"