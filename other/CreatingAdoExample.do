



/* Example*/


 sysuse xtline1.dta, clear
 
 *This is normalization
* 1) Compute each person's baseline (value on 19mar2002), without temporary vars
bysort person: egen base = max(cond(day==td(19mar2002), calories, .))
 *We then extend this number to each group, in this case, person
gen norm_calories = calories / base
drop base


/* Example*/

* Daily (%td)
cls
sysuse xtline1, clear
normbydate calories, by(person) date("19mar2002") datevar(day)


tw (line calories day if person==1)  (line calories day if person==2) (line calories day if person==3), legend(ring(1) position(6))

tw (line norm_calories day if person==1)  (line norm_calories day if person==2) (line norm_calories day if person==3), legend(ring(1) position(6))






* --- Build monthly panel from Stata's example ---
cls
sysuse xtline1, clear              // has daily %td date var 'day'
gen mdate = mofd(day)              // month-of-date (numeric)
format mdate %tm                   // <-- monthly format required
collapse (mean) calories, by(person mdate)
normbydate calories, by(person) date("2002m3") datevar(mdate)

* --- Build monthly panel from Stata's example ---
cls
sysuse xtline1, clear              // has daily %td date var 'day'
gen mdate = mofd(day)              // month-of-date (numeric)
format mdate %tm                   // <-- monthly format required
collapse (mean) calories, by(person mdate)
keep if person==1
normbydate calories, date("2002m3") datevar(mdate)



