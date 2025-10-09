# normbydate

![Stata](https://img.shields.io/badge/stata-v17+-blue?logo=stata)
![Platform](https://img.shields.io/badge/platform-windows%20%7C%20macOS%20%7C%20linux-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-1.8-orange)
![GitHub repo size](https://img.shields.io/github/repo-size/jgcarrenobustos/normbydate)
![GitHub last commit](https://img.shields.io/github/last-commit/jgcarrenobustos/normbydate)

A Stata command for normalizing variables by their value at a baseline date.

## Description

`normbydate` divides a variable by its value on a user-specified baseline date, within each group. The baseline is supplied as a literal string and the time frequency is inferred from the display format of the date variable: `%td` (daily), `%tm` (monthly), or `%ty` (yearly).

## Installation

```stata
* Download the files and place them in your adopath
adopath ++ "path/to/normbydate"
```

## Syntax

```stata
normbydate varname , date("literal") datevar(varname) 
    [by(varlist) generate(newvar) replace scale(#) strictfmt]
```

## Options

- `date("literal")`: Baseline period as a plain string (no `td()/tm()/tw()/…`). Examples: `"19mar2002"`, `"2002-03"`, `"2002"`.
- `datevar(varname)`: Time variable. Must be numeric with display format `%td`, `%tm`, or `%ty`.
- `by(varlist)`: Grouping variable(s). Optional only if there is exactly one observation at the baseline date.
- `generate(newvar)`: Name of the normalized variable to create. Default: `norm_varname`.
- `replace`: Allow replacing an existing `generate()` variable.
- `scale(#)`: Scale factor for the index; default `1`. Use `scale(100)` for base=100.
- `strictfmt`: Error out if `datevar` is not formatted `%td`, `%tm`, or `%ty`.

## Examples

```stata
* Daily data normalization
normbydate price, date("01jan2020") datevar(date) by(company)

* Monthly data with base=100
normbydate sales, date("2020-01") datevar(month) by(region) scale(100)

* Yearly data
normbydate gdp, date("2010") datevar(year) by(country)
```

## Files

- `normbydate.ado`: Main command file
- `normbydate.sthlp`: Help file
- `test.do`: Comprehensive test script

## Testing

Run the test script to verify functionality:

```stata
do test.do
```

## Author

**Gabo**  
📧 jgcarren@gmail.com  
🐙 [GitHub](https://github.com/jgcarrenobustos)

## License

MIT License - see LICENSE file for details