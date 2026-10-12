{smcl}
{* *! version 1.9 12oct2026}
{title:Title}
{phang}
{bf:normbydate} — Normalize a variable by its value at a baseline date (daily / monthly / yearly)

{title:Syntax}
{p 8 15 2}
{cmd:normbydate} {it:varname} , {opt date("literal")} {opt datevar(varname)}
[{opt by(varlist)} {opt generate(newvar)} {opt replace} {opt scale(#)} {opt strictfmt}]

{synoptset 26 tabbed}
{synopthdr:Options}
{synoptline}
{synopt:{opt date("literal")}}Baseline period as a plain string (no {cmd:td()/tm()/tw()/…}). Examples: {it:"19mar2002"}, {it:"2002-03"}, {it:"2002"}.{p_end}
{synopt:{opt datevar(varname)}}Time variable. Must be numeric with display format {cmd:%td}, {cmd:%tm}, or {cmd:%ty}. Frequency is inferred from this {it:format}.{p_end}
{synopt:{opt by(varlist)}}Grouping variable(s). Optional {it:only if} there is exactly {bf:one} observation at the baseline date in the estimation sample. Otherwise, {bf:required}.{p_end}
{synopt:{opt generate(newvar)}}Name of the normalized variable to create. Default: {cmd:norm_}{it:varname}.{p_end}
{synopt:{opt replace}}Allow replacing an existing {cmd:generate()} variable.{p_end}
{synopt:{opt scale(#)}}Scale factor for the index; default {cmd:1}. Use {cmd:scale(100)} for base=100.{p_end}
{synopt:{opt strictfmt}}Kept for backward compatibility; {cmd:datevar} must always be formatted {cmd:%td}, {cmd:%tm}, or {cmd:%ty}.{p_end}
{synoptline}

{title:Description}
{pstd}
{cmd:normbydate} divides {it:varname} by its value on a user-specified baseline date, within each group given by {cmd:by()}. The baseline is supplied as a {it:literal string} via {cmd:date("...")}, and the time frequency is inferred from the display format of {cmd:datevar}: {cmd:%td} (daily), {cmd:%tm} (monthly), or {cmd:%ty} (yearly).

{pstd}
The command is {it:strict}: groups with no observation at the baseline period get missing normalized values (no fallbacks). After running, it prints a coverage report stating whether {it:all groups} were normalized and, if not, how many groups lacked the baseline.

{pstd}
If {cmd:by()} is omitted, this is allowed {bf:only} when the estimation sample contains exactly {bf:one} observation at the baseline period. If there are zero or multiple observations at baseline and {cmd:by()} is not supplied, {cmd:normbydate} errors and asks you to specify {cmd:by()}.

{title:Accepted {cmd:date("...")} literals (examples)}
{p2colset 12 28 28 2}
{p2col:Daily (%td)}"19mar2002", "2002-03-19", "19/03/2002"{p_end}
{p2col:Monthly (%tm)}"2002-03", "2002m3", "Mar 2002"{p_end}
{p2col:Yearly (%ty)}"2002"{p_end}
{p2colreset}

{title:Remarks}
{pstd}
• {bf:Default name}. Output variable defaults to {cmd:norm_}{it:varname}.{break}
• {bf:Format matters}. Frequency is inferred from {cmd:datevar}'s display format. Set it with {cmd:format} (e.g., {cmd:format mdate %tm}).{break}
• {bf:Duplicates at baseline}. If multiple rows exist for the same group & baseline period, a warning is shown and the baseline used is the maximum of {it:varname} on that date.{break}
• {bf:Zero/negative baselines}. Observations with baseline ≤ 0 are left missing to avoid invalid ratios.{break}
• {bf:No fallbacks}. Groups missing the baseline remain missing by design—pre-process if you want nearest/mean windows, etc.{break}
• {bf:One-shot global normalization}. If you omit {cmd:by()}, ensure there is exactly one observation at the baseline in your sample.

{title:Examples}

{bf:Quick test}
{cmd:. sysuse xtline1, clear}
{cmd:. normbydate calories, by(person) date("19mar2002") datevar(day)}

{bf:Daily data (with return values)}
{cmd:. sysuse xtline1, clear}
{cmd:. format day %td}
{cmd:. normbydate calories, by(person) date("19mar2002") datevar(day)}
{cmd:. return list}

{bf:Monthly data}
{cmd:. sysuse xtline1, clear}
{cmd:. gen mdate = mofd(day)}
{cmd:. format mdate %tm}
{cmd:. collapse (mean) calories, by(person mdate)}
{cmd:. normbydate calories, by(person) date("2002-03") datevar(mdate)}
{cmd:. * also works: date("Mar 2002") or date("2002m3")}

{bf:Yearly data}
{cmd:. clear}
{cmd:. set obs 6}
{cmd:. gen firm = ceil(_n/3)}
{cmd:. gen year = 2001 + mod(_n-1,3)}
{cmd:. gen y = year}
{cmd:. format y %ty}
{cmd:. gen sales = 100 + year*runiform()}
{cmd:. normbydate sales, by(firm) date("2002") datevar(y)}

{bf:No {it:by()} (only if a single baseline obs exists)}
{cmd:. clear}
{cmd:. set obs 12}
{cmd:. gen mdate = ym(2002,1) + _n-1}
{cmd:. format mdate %tm}
{cmd:. gen sales = 100 + 2*_n}
{cmd:. * ensure exactly one row at baseline 2002m3}
{cmd:. keep if inlist(mdate, ym(2002,1), ym(2002,2), ym(2002,3), ym(2002,4))}
{cmd:. normbydate sales, date("2002-03") datevar(mdate)}

{bf:Scale to 100}
{cmd:. normbydate calories, by(person) date("19mar2002") datevar(day) generate(idx_cal) replace scale(100)}

{bf:Strict format check}
{cmd:. normbydate calories, by(person) date("19mar2002") datevar(day) strictfmt}

{title:Troubleshooting}
{pstd}
{bf:Error:} {it:"2002m3 invalid name"} — You passed an unquoted token and the ado tried to evaluate it. Call with a quoted literal, e.g., {cmd:date("2002m3")} or {cmd:date("2002-03")}.{p_end}
{pstd}
{bf:Error:} {it:"Multiple observations ... Specify by()"} — You omitted {cmd:by()} but there are several observations at the baseline date. Add {cmd:by()} so the baseline is defined within groups.{p_end}
{pstd}
{bf:Error:} {it:"datevar(...) has format ..."} — Set the correct format, e.g., {cmd:format day %td}, {cmd:format mdate %tm}, {cmd:format y %ty}.{p_end}
{pstd}
{bf:Some groups not normalized} — The coverage report tells you how many groups lacked the baseline; those groups' normalized values are missing by design.{p_end}

{title:Installation}
{pstd}
{cmd:. net install normbydate, from("https://raw.githubusercontent.com/jgcarrenobustos/normbydate/main/") replace}

{title:Stored results}
{pstd}
{cmd:normbydate} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(baseline_val)}}baseline date as a Stata number{p_end}
{synopt:{cmd:r(N_groups)}}number of groups{p_end}
{synopt:{cmd:r(N_groups_miss)}}groups without a usable baseline{p_end}
{synopt:{cmd:r(p_groups_miss)}}share of groups without a usable baseline{p_end}
{synopt:{cmd:r(N_normalized)}}observations with a normalized value{p_end}
{synopt:{cmd:r(N_norm_missing)}}observations left missing{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(baseline_disp)}}baseline date as text{p_end}
{synopt:{cmd:r(freq)}}{cmd:daily}, {cmd:monthly}, or {cmd:yearly}{p_end}
{synopt:{cmd:r(by_used)}}variables in {cmd:by()}{p_end}
{synopt:{cmd:r(generate)}}name of the created variable{p_end}

{title:Author}
{pstd}
José Gabito Carreño — {browse "mailto:jgcarren@gmail.com":jgcarren@gmail.com}{p_end}

