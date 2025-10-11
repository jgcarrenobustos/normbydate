
clear all

cd "C:\Users\jgcar\Mi unidad\Research\__other\StataAdo\normbydate"
use "data\GrowthClimateDataset", clear


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