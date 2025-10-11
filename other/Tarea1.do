
* TAREA 1: CRECIMIENTO ECONOMICO
*===================================================


clear all

cd "C:\Users\jgcar\Mi unidad\Research\__other\StataAdo\normbydate"
use "GrowthClimateDataset", clear


*1
use "GrowthClimateDataset", clear
keep isocode year gdpCAPppp_wdi
keep if year>1990
keep if year<2010

xtset isocode  year
xtline gdpCAPppp_wdi, overlay legend(off)






*2
*a) 
use "GrowthClimateDataset_tarea1", clear
collapse (mean)  growthWDI, by(year continent_id)
tw (line growthWDI year if continent_id==1 )  (line growthWDI year if continent_id==2 )(line growthWDI year if continent_id==3 )(line growthWDI year if continent_id==4 )(line growthWDI year if continent_id==5 )(line growthWDI year if continent_id==6 )
*b)
use "GrowthClimateDataset_tarea1", clear
collapse (mean)  growthWDI [aw = Pop], by(year continent_id)
tw (line growthWDI year if continent_id==1 ) (line growthWDI year if continent_id==2 ) (line growthWDI year if continent_id==2 )(line growthWDI year if continent_id==4 )(line growthWDI year if continent_id==5 )(line growthWDI year if continent_id==6 )
*3
*a)
use "GrowthClimateDataset_tarea1", clear
collapse (mean)  UDel_temp_popweight, by(year continent_id)
tw (line UDel_temp_popweight year if continent_id==1 ) (line UDel_temp_popweight year if continent_id==2 ) (line UDel_temp_popweight year if continent_id==2 ) (line UDel_temp_popweight year if continent_id==3 ) (line UDel_temp_popweight year if continent_id==4) (line UDel_temp_popweight year if continent_id==5 ) (line UDel_temp_popweight year if continent_id==6 )




*4
*a) y b)
use "GrowthClimateDataset_tarea1", clear
keep if year==1980 | year==2010

*Clasificacion 1980
bysort year: egen p20_1980=pctile(gdpCAP_wdi_1980), p(20)
bysort year: egen p80_1980=pctile(gdpCAP_wdi_1980), p(80)
g pobre_1980 = (gdpCAP_wdi_1980<p20_1980)
g rico_1980 = (gdpCAP_wdi_1980>p80_1980)

*Clasificacion 2010
bysort year: egen p20_2010=pctile(gdpCAP_wdi_2010), p(20)
bysort year: egen p80_2010=pctile(gdpCAP_wdi_2010), p(80)
g pobre_2010 = (gdpCAP_wdi_2010<p20_2010)
g rico_2010 = (gdpCAP_wdi_2010>p80_2010)


keep if year==1980
sum iso_id if pobre_1980==1
sum iso_id if pobre_1980==1 & pobre_2010==1
sum iso_id if rico_1980==1
sum iso_id if rico_1980==1 & rico_2010==1

*c)
use "GrowthClimateDataset_tarea1", clear
bysort year: egen p20=pctile(gdpCAP_wdi), p(20)
bysort year: egen p80=pctile(gdpCAP_wdi), p(80)
g pobre = (gdpCAP_wdi<p20)
g rico = (gdpCAP_wdi>p80)
keep if year ==1980 | year==2010
collapse (sum) pobre, by(continent_id year)
*d)
*Siempre van a haber paises pobres, incluso si dejan de ser pobres. 


*5)
use "GrowthClimateDataset_tarea1", clear
bysort year: egen p20_1980=pctile(gdpCAP_wdi_1980), p(20)
bysort year: egen p80_1980=pctile(gdpCAP_wdi_1980), p(80)
g pobre_1980 = (gdpCAP_wdi_1980<p20_1980)
g rico_1980 = (gdpCAP_wdi_1980>p80_1980)

*eliminamos paises que no eran pobre ni ricos
drop if pobre_1980==0 & rico_1980 ==0

collapse (mean)  growthWDI [aw=Pop], by(year pobre_1980 rico_1980)
tw (line growthWDI year if rico==1 ) (line growthWDI year if pobre==1 ) ,legend( lab(1 "Rico") lab(2 "Pobre"))

*6) 7) 8)
use "GrowthClimateDataset_tarea1", clear
drop if year<1980
*gdpCAP_wdi_1980 es fijo en el tiempo, asi que no pasa nada si sacamos la media
collapse (sum) growthWDI  (mean) gdpCAP_wdi_1980 , by(iso_id continent_id)
g ln_gdppc= ln(gdpCAP_wdi_1980)
reg growthWDI  ln_gdppc
reg growthWDI  c.ln_gdppc##i.continent_id

*9)

use "GrowthClimateDataset_tarea1", clear

gen temp 	= UDel_temp_popweight
gen precip =  UDel_precip_popweight

reg growthWDI  temp  precip  i.year i.iso_id

reg growthWDI  c.temp##c.temp  c.precip##c.precip  i.year i.iso_id


******25-3-2025