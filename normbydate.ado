*! normbydate.ado 1.8 — strict normalization by value at a baseline date; by() optional iff unique baseline obs
program define normbydate, rclass
    version 17.0
    // Syntax:
    //   normbydate var, date("literal") datevar(datevar) [ by(varlist) generate(newvar) replace scale(real 1) strictfmt ]
    //
    // Behavior:
    //   • If by() is omitted, this is allowed ONLY when there is exactly ONE observation at the baseline date.
    //     Otherwise the command errors and asks for by().
    //   • date("...") must be a plain string (no td()/tm()/tw()/tq()/th()).
    //   • datevar must be numeric with %td, %tm, or %ty; frequency is inferred from its format.
    //   • No fallbacks: groups lacking the baseline remain missing.
    //   • Default output name: norm_<varname>; use scale(100) for base=100.

    syntax varname(numeric) [if] [in], DATE(string) DATEVAR(varname) ///
        [ BY(varlist) GENerate(name) REPLACE SCALE(real 1) STRICTFMT ]

    marksample touse, novarlist
    quietly count if `touse'
    if (r(N)==0) error 2000

    // ---- Reject td()/tm()/tw()/tq()/th() style inputs; require a literal string
    if (strpos("`date'","(") | strpos("`date'",")")) {
        di as err "Do not use td()/tm()/tw()/tq()/th() in {bf:date()}. Pass a literal like ""19mar2002"", ""2002-03"", or ""2002""."
        exit 198
    }

    // ---- datevar must be numeric and have a %t* display format
    capture confirm numeric variable `datevar'
    if (_rc) {
        di as err "datevar(`datevar') is not numeric. Convert to a Stata time variable and apply a %t* format."
        exit 109
    }
    local fmt : format `datevar'
    if (substr("`fmt'",1,2)!="%t") {
        if ("`strictfmt'"!="") {
            di as err "datevar(`datevar') has format {bf:`fmt'}. Expected {bf:%td}, {bf:%tm}, or {bf:%ty}."
            exit 198
        }
        else di as txt "{bf:Alert:} datevar(`datevar') has format {bf:`fmt'}, not %t*. Set a proper %td/%tm/%ty for consistency."
    }

    // ---- Determine frequency from display format
    local fchar = substr("`fmt'",3,1)   // 'd', 'm', or 'y'
    if !inlist("`fchar'","d","m","y") {
        di as err "Only daily (%td), monthly (%tm), or yearly (%ty) datevars are supported. Found {bf:`fmt'}."
        exit 198
    }

    // ---- Parse baseline date literal into numeric time matching `datevar'
    tempname _t0
    scalar `_t0' = .
    if ("`fchar'"=="d") {
        foreach mask in "DMY" "YMD" "MDY" {
            if (missing(scalar(`_t0'))) scalar `_t0' = date("`date'","`mask'")
        }
        if (missing(scalar(`_t0'))) {
            di as err "Could not parse daily baseline from date(""`date'""). Try ""19mar2002"", ""2002-03-19"", or ""19/03/2002""."
            exit 198
        }
    }
    else if ("`fchar'"=="m") {
        scalar `_t0' = monthly("`date'","YM")
        if (missing(scalar(`_t0'))) scalar `_t0' = monthly("`date'","MY")
        if (missing(scalar(`_t0'))) {
            local d2 = subinstr("`date'","-","m",.)
            local d2 = subinstr("`d2'","/","m",.)
            scalar `_t0' = monthly("`d2'","YM")
        }
        if (missing(scalar(`_t0'))) {
            di as err "Could not parse monthly baseline from date(""`date'""). Examples: ""2002-03"", ""2002m3"", ""Mar 2002""."
            exit 198
        }
    }
    else { // yearly
        scalar `_t0' = yearly("`date'","Y")
        if (missing(scalar(`_t0'))) {
            di as err "Could not parse yearly baseline from date(""`date'""). Example: ""2002""."
            exit 198
        }
    }
    local t0 = scalar(`_t0')

    // ---- If by() omitted, allow ONLY if exactly one baseline observation exists
    if ("`by'"=="") {
        quietly count if `touse' & `datevar'==`t0'
        local nbase = r(N)
        if (`nbase'==0) {
            local fdisp = cond("`fchar'"=="d","%td", cond("`fchar'"=="m","%tm","%ty"))
            local fdate : display `fdisp' `t0'
            di as err "No observation at baseline {bf:`fdate'}. Supply a valid date() or by()."
            exit 2000
        }
        if (`nbase'>1) {
            local fdisp = cond("`fchar'"=="d","%td", cond("`fchar'"=="m","%tm","%ty"))
            local fdate : display `fdisp' `t0'
            di as err "Multiple observations (`nbase') at baseline {bf:`fdate'} with no by(). Specify {bf:by()} to disambiguate."
            exit 198
        }
    }

    // ---- Output var name: default norm_<varname>
    if ("`generate'"=="") local generate = "norm_`varlist'"
    capture confirm new variable `generate'
    if (_rc & "`replace'"=="") {
        di as err "variable `generate' already exists; specify option {bf:replace}"
        exit 110
    }
    if ("`replace'"!="") cap drop `generate'

    // ---- Build grouping variable: either user-specified by() or a single dummy group
    tempvar _grp
    if ("`by'"=="") {
        quietly gen byte `_grp' = 1
        local BY `_grp'
    }
    else {
        local BY `by'
    }

    // ---- Compute strict baseline within groups; normalize (no fallbacks)
    tempvar _base _tag
    quietly bysort `BY': egen double `_base' = ///
        max(cond(`touse' & `datevar'==`t0', `varlist', .))

    quietly gen double `generate' = .
    quietly replace `generate' = `scale' * `varlist' / `_base' if `touse' & `_base'>0

    // ---- Coverage report: were all groups normalized?
    quietly egen byte `_tag' = tag(`BY') if `touse'
    qui count if `_tag'
    scalar _Ng = r(N)
    qui count if `_tag' & missing(`_base')
    scalar _Nmissg = r(N)
    scalar _pcmiss = cond(_Ng>0, _Nmissg/_Ng, .)

    // Pretty baseline display
    local fdisp = cond("`fchar'"=="d","%td", cond("`fchar'"=="m","%tm","%ty"))
    local fdate : display `fdisp' `t0'

    if (_Nmissg==0) {
        di as res "All groups normalized: " as txt _col(25) "{bf:`=string(_Ng)'} group" ///
                  as txt cond(_Ng==1,"","s") " (baseline {bf:`fdate'}; scale=`scale')."
    }
    else {
        local pct : display %5.1f (100*_pcmiss)
        di as err "{bf:Not all groups normalized.} Missing baseline for " ///
                  as err "`=string(_Nmissg)'/" as err "`=string(_Ng)'" ///
                  as err " group" cond(_Ng==1,"","s") " (" as err "`pct'%" ")."
        di as txt  "Baseline: {bf:`fdate'}. Those groups have {it:`generate'} = missing."
    }

    // ---- Label & returns
    label var `generate' "Normalized `varlist' (baseline=`fdate' by `: list retok BY'; scale=`scale')"
    return scalar baseline_val   = `t0'
    return local baseline_disp   = "`fdate'"
    return local freq            = cond("`fchar'"=="d","daily", cond("`fchar'"=="m","monthly","yearly"))
    return local by_used         = "`BY'"
    return scalar N_groups       = _Ng
    return scalar N_groups_miss  = _Nmissg
    return scalar p_groups_miss  = _pcmiss
    quietly count if `touse' & !missing(`generate')
    return scalar N_normalized   = r(N)
    quietly count if `touse' &  missing(`generate')
    return scalar N_norm_missing = r(N)
end
