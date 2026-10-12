*-------------------------------------------------------------------------------
* test.do - self-contained tests for normbydate (built-in datasets only)
* Run from the repository folder:  do test.do
* Every check uses -assert-, so the script stops at the first failure.
*-------------------------------------------------------------------------------

clear all
set more off

* Use the .ado in this folder, ahead of any installed copy
adopath ++ "`c(pwd)'"
capture program drop normbydate

* Test 1: daily data, by() groups
sysuse xtline1, clear
normbydate calories, date("19mar2002") datevar(day) by(person)
assert r(freq) == "daily"
assert r(baseline_val) == td(19mar2002)
assert r(N_groups_miss) == 0
assert abs(norm_calories - 1) < 1e-12 if day == td(19mar2002)
bysort person (day): egen double chk = max(cond(day == td(19mar2002), calories, .))
assert reldif(norm_calories, calories/chk) < 1e-12
drop chk

* Test 2: other daily literals give the same baseline
foreach d in "2002-03-19" "19/03/2002" {
    normbydate calories, date("`d'") datevar(day) by(person) replace
    assert r(baseline_val) == td(19mar2002)
}

* Test 3: monthly data, several literal styles
sysuse xtline1, clear
gen mdate = mofd(day)
format mdate %tm
collapse (mean) calories, by(person mdate)
foreach d in "2002-03" "2002m3" "Mar 2002" {
    normbydate calories, date("`d'") datevar(mdate) by(person) replace
    assert r(freq) == "monthly"
    assert r(baseline_val) == tm(2002m3)
    assert abs(norm_calories - 1) < 1e-12 if mdate == tm(2002m3)
}

* Test 4: yearly data, generate() and scale()
clear
set obs 40
gen id = mod(_n-1, 5) + 1
gen year = 2000 + floor((_n-1)/5)
format year %ty
gen value = 100 + 5*_n
normbydate value, date("2001") datevar(year) by(id) generate(val_norm) scale(100)
assert r(freq) == "yearly"
assert abs(val_norm - 100) < 1e-10 if year == 2001
confirm variable val_norm

* Test 5: no by() with a single baseline observation
clear
set obs 4
gen mdate = ym(2002,1) + _n - 1
format mdate %tm
gen sales = 100 + 2*_n
normbydate sales, date("2002-03") datevar(mdate)
assert abs(norm_sales - sales/106) < 1e-12

* Test 6: replace option
sysuse xtline1, clear
gen norm_calories = 999
capture normbydate calories, date("19mar2002") datevar(day) by(person)
assert _rc == 110
normbydate calories, date("19mar2002") datevar(day) by(person) replace
assert norm_calories != 999

* Test 7: expected errors
sysuse xtline1, clear
capture normbydate calories, date("td(19mar2002)") datevar(day) by(person)
assert _rc == 198
capture normbydate calories, date("01jan2030") datevar(day) by(person)
assert _rc == 2000
capture normbydate calories, date("19mar2002") datevar(day)
assert _rc == 198
gen double rawday = day
format rawday %9.0g
capture normbydate calories, date("19mar2002") datevar(rawday) by(person)
assert _rc == 198

* Test 8: groups without baseline stay missing, sort order preserved
sysuse xtline1, clear
gen long order = _n
drop if person == 1 & day == td(19mar2002)
normbydate calories, date("19mar2002") datevar(day) by(person)
assert r(N_groups_miss) == 1
assert missing(norm_calories) if person == 1
assert order[_n] > order[_n-1] if _n > 1

display as result "All normbydate tests passed."
