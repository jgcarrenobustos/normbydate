*! normbydate 1.9 12oct2026 - strict normalization by value at a baseline date; by() optional iff unique baseline obs
program define normbydate, rclass sortpreserve
    version 14.0
    // Syntax:
    //   normbydate var [if] [in], date("literal") datevar(datevar) [ by(varlist) generate(newvar) replace scale(real 1) strictfmt ]
    //
    // Behavior:
    //   - If by() is omitted, this is allowed ONLY when there is exactly ONE observation at the baseline date.
    //     Otherwise the command errors and asks for by().
    //   - date("...") must be a plain string (no td()/tm()/ty() functions).
    //   - datevar must be numeric with %td, %tm, or %ty; frequency is inferred from its format.
    //   - No fallbacks: groups lacking the baseline remain missing.
    //   - Default output name: norm_<varname>; use scale(100) for base=100.

    syntax varname(numeric) [if] [in], DATE(string) DATEVAR(varname) ///
        [ BY(varlist) GENerate(name) REPLACE SCALE(real 1) STRICTFMT ]

    marksample touse, novarlist
    quietly count if `touse'
    if (r(N)==0) error 2000

    // ---- Reject td()/tm()/ty() style inputs; require a literal string
    local date = strtrim(`"`date'"')
    if (strpos(`"`date'"',"(") | strpos(`"`date'"',")")) {
        di as err `"Do not use td()/tm()/ty() in {bf:date()}. Pass a literal like "19mar2002", "2002-03", or "2002"."'
        exit 198
    }

    // ---- datevar must be numeric and have a %td/%tm/%ty display format
    capture confirm numeric variable `datevar'
    if (_rc) {
        di as err "datevar(`datevar') is not numeric. Convert it to a Stata date variable and apply a %td, %tm, or %ty format."
        exit 109
    }
    local fmt : format `datevar'
    local fmtc = subinstr("`fmt'","-","",1)    // %-td -> %td
    local fchar = substr("`fmtc'",3,1)          // 'd', 'm', or 'y'
    if (substr("`fmtc'",1,2)!="%t" | !inlist("`fchar'","d","m","y")) {
        di as err "datevar(`datevar') has format {bf:`fmt'}. Expected {bf:%td} (daily), {bf:%tm} (monthly), or {bf:%ty} (yearly)."
        di as err "Set it first, e.g. {cmd:format `datevar' %td}."
        exit 198
    }
    local fdisp = cond("`fchar'"=="d","%td", cond("`fchar'"=="m","%tm","%ty"))

    // ---- Parse baseline date literal into numeric time matching `datevar'
    local t0 = .
    if ("`fchar'"=="d") {
        foreach mask in DMY YMD MDY {
            if missing(`t0') local t0 = date(`"`date'"',"`mask'")
        }
        if missing(`t0') {
            di as err `"Could not parse a daily baseline from date("`date'"). Try "19mar2002", "2002-03-19", or "19/03/2002"."'
            exit 198
        }
    }
    else if ("`fchar'"=="m") {
        local t0 = monthly(`"`date'"',"YM")
        if missing(`t0') local t0 = monthly(`"`date'"',"MY")
        if missing(`t0') {
            di as err `"Could not parse a monthly baseline from date("`date'"). Examples: "2002-03", "2002m3", "Mar 2002"."'
            exit 198
        }
    }
    else {
        local t0 = yearly(`"`date'"',"Y")
        if missing(`t0') {
            di as err `"Could not parse a yearly baseline from date("`date'"). Example: "2002"."'
            exit 198
        }
    }
    local fdate = strtrim(string(`t0',"`fdisp'"))

    // ---- Baseline must exist in the sample
    quietly count if `touse' & `datevar'==`t0'
    local nbase = r(N)
    if (`nbase'==0) {
        di as err "No observation at baseline {bf:`fdate'} in the sample. Check date() and datevar()."
        exit 2000
    }

    // ---- If by() omitted, allow ONLY if exactly one baseline observation exists
    if ("`by'"=="" & `nbase'>1) {
        di as err "Multiple observations (`nbase') at baseline {bf:`fdate'} with no by(). Specify {bf:by()} to disambiguate."
        exit 198
    }

    // ---- Output var name: default norm_<varname>
    if ("`generate'"=="") local generate "norm_`varlist'"
    capture confirm new variable `generate'
    if (_rc) {
        if ("`replace'"=="") {
            di as err "variable {bf:`generate'} already exists; specify option {bf:replace}"
            exit 110
        }
        if ("`generate'"=="`varlist'") {
            di as err "generate() cannot be the variable being normalized"
            exit 198
        }
    }

    // ---- Grouping variable: either user-specified by() or a single dummy group
    tempvar _grp _base _nb _tag _new
    if ("`by'"=="") {
        quietly gen byte `_grp' = 1
        local BY `_grp'
    }
    else local BY `by'

    // ---- Strict baseline within groups (no fallbacks)
    quietly bysort `BY': egen double `_base' = max(cond(`touse' & `datevar'==`t0', `varlist', .))
    quietly bysort `BY': egen long `_nb' = total(`touse' & `datevar'==`t0')
    quietly count if `_nb'>1
    if (r(N)>0) {
        di as txt "{bf:Warning:} some groups have more than one observation at baseline `fdate'; the maximum is used as baseline."
    }

    quietly gen double `_new' = `scale' * `varlist' / `_base' ///
        if `touse' & !missing(`_base') & `_base'>0

    // ---- Coverage report: were all groups normalized?
    quietly egen byte `_tag' = tag(`BY') if `touse'
    quietly count if `_tag'==1
    local Ng = r(N)
    quietly count if `_tag'==1 & (missing(`_base') | `_base'<=0)
    local Nmissg = r(N)
    local pcmiss = cond(`Ng'>0, `Nmissg'/`Ng', .)

    if (`Nmissg'==0) {
        di as res "All groups normalized: " as txt "{bf:`Ng'} group" ///
            cond(`Ng'==1,"","s") " (baseline {bf:`fdate'}; scale=`scale')."
    }
    else {
        local pct : display %5.1f (100*`pcmiss')
        di as err "{bf:Not all groups normalized.} Missing or non-positive baseline for " ///
            "`Nmissg'/`Ng' group" cond(`Ng'==1,"","s") " (" strtrim("`pct'") "%)."
        di as txt "Baseline: {bf:`fdate'}. Those groups have {it:`generate'} = missing."
    }

    // ---- Store result
    if ("`replace'"!="") capture drop `generate'
    rename `_new' `generate'
    local bylab = cond("`by'"=="", "", " by `by'")
    label var `generate' "`varlist' / value at `fdate'`bylab' (x`scale')"

    // ---- Returns
    return scalar baseline_val   = `t0'
    return local  baseline_disp  "`fdate'"
    return local  freq           = cond("`fchar'"=="d","daily", cond("`fchar'"=="m","monthly","yearly"))
    return local  by_used        "`by'"
    return local  generate       "`generate'"
    return scalar N_groups       = `Ng'
    return scalar N_groups_miss  = `Nmissg'
    return scalar p_groups_miss  = `pcmiss'
    quietly count if `touse' & !missing(`generate')
    return scalar N_normalized   = r(N)
    quietly count if `touse' &  missing(`generate')
    return scalar N_norm_missing = r(N)
end
