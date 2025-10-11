* Minimal packaged test.do copy
clear all
set more off
adopath ++ .
sysuse xtline1, clear
capture noisily normbydate calories, date("19mar2002") datevar(day) by(person)
set more on
