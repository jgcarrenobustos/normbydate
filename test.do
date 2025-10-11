*-------------------------------------------------------------------------------
* test_clean.do - clean, self-contained tests for normbydate (no di/display)
* Created: 2025-10-11
* Purpose: Run a set of small, isolated tests using only Stata built-in datasets.
* Notes: Uses only comment headers and standard Stata output (no 'di', 'di as' or 'display').
*-------------------------------------------------------------------------------

clear all
set more off

* Ensure Stata can find the .ado in this folder
adopath ++ .


***********************************************************
* Test 1: Basic daily data using xtline1 (built-in)
***********************************************************

* Test 1 header
sysuse xtline1, clear

* xtline1 has day, calories, person
describe day calories person

* Basic call: normalize calories at baseline date 19mar2002 by person
capture noisily normbydate calories, date("19mar2002") datevar(day) by(person)
if _rc != 0 {
    * ERROR: normbydate failed in Test 1
}
else {
    * OK: Test 1 completed
    list person day calories norm_calories in 1/10
}


***********************************************************
* Test 2: Monthly aggregation and monthly normalization
***********************************************************

* Test 2 header
sysuse xtline1, clear

* create monthly date from daily date
gen mdate = mofd(day)
format mdate %tm

* aggregate by person and month (mean calories)
preserve
collapse (mean) calories, by(person mdate)

describe mdate calories person

capture noisily normbydate calories, date("2002-03") datevar(mdate) by(person)
if _rc != 0 {
    * ERROR: normbydate failed in Test 2
}
else {
    * OK: Test 2 completed
    list person mdate calories norm_calories in 1/10
}

restore


***********************************************************
* Test 3: Yearly-like data (synthetic) and custom generate
***********************************************************

* Test 3 header
clear
set obs 40

* Create group id and yearly variable
gen id = mod(_n-1, 5) + 1
gen year = ty(2000) + floor((_n-1)/4)
format year %ty

* Create a value to normalize
gen value = 100 + 5*_n + rnormal(0,3)

list id year value in 1/12

capture noisily normbydate value, date("2001") datevar(year) by(id) generate(val_norm)
if _rc != 0 {
    * ERROR: normbydate failed in Test 3
}
else {
    * OK: Test 3 completed
    list id year value val_norm in 1/12
}


***********************************************************
* Test 4: Replace option behavior
***********************************************************

* Test 4 header
sysuse xtline1, clear

* First create a fake existing variable norm_calories to test replace
gen norm_calories = 999

* Running without replace should return nonzero rc (capture)
capture normbydate calories, date("19mar2002") datevar(day) by(person)
if _rc == 0 {
    * ERROR: Expected failure when generating existing variable without replace
} 
else {
    * OK: normbydate correctly refused to overwrite existing var without replace
}

* Now run with replace
capture noisily normbydate calories, date("19mar2002") datevar(day) by(person) replace
if _rc != 0 {
    * ERROR: normbydate failed with replace in Test 4
} 
else {
    * OK: Test 4 (replace) completed
    list person day calories norm_calories in 1/10
}


***********************************************************
* Test 5: Error cases - invalid date format and no baseline
***********************************************************

* Test 5 header
sysuse xtline1, clear

* Invalid date format using td() literal (should error)
capture normbydate calories, date("td(19mar2002)") datevar(day) by(person)
if _rc != 0 {
    * OK: Expected error on invalid date literal
} 
else {
    * ERROR: Expected normbydate to reject td(...) literal
}

* No observations at baseline (future date) should error
capture normbydate calories, date("01jan2030") datevar(day) by(person)
if _rc != 0 {
    * OK: Expected error when no baseline observations exist
} 
else {
    * ERROR: Expected failure when no baseline obs exist
}


***********************************************************
* Test 6: Return values check
***********************************************************

* Test 6 header
sysuse xtline1, clear
capture noisily normbydate calories, date("19mar2002") datevar(day) by(person)

* Display r-class returns if command succeeded
if _rc == 0 {
    capture confirm scalar r(baseline_val)
    if _rc == 0 scalar baseline_val_exists = 1
    capture confirm scalar r(freq)
    if _rc == 0 scalar freq_exists = 1
    capture confirm scalar r(N_groups)
    if _rc == 0 scalar N_groups_exists = 1
}

* End of tests
set more on
* End of test_clean.do
