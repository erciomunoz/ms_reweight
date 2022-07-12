{smcl}
{* *! version 1.0 June 2022}{...}
{cmd: help ms_reweight}
{hline}

{title:Title}

{phang}
{bf:A Reweighting-Based Tool to Link a Microsimulation Model to a Macroeconomic Model}

{title:Syntax}

{p 8 17 2}
{cmd:ms_reweight}
{cmd:,}
{cmd:age(}{it:varname}{cmd:)}
{cmd:education(}{it:varname}{cmd:)}
{cmd:gender(}{it:varname}{cmd:)}
{cmd:hhsize(}{it:varname}{cmd:)}
{cmd:id(}{it:varname}{cmd:)}
{cmd:iweights(}{it:varname}{cmd:)}
{cmd:country(}{it:varname}{cmd:)}
{cmd:iyear(}{it:varname}{cmd:)}
{cmd:tyear(}{it:varname}{cmd:)}
{cmd:generate(}{it:varname}{cmd:)}
{cmd:match(}{it:varname}{cmd:)}
{cmd:popdata(}{it:varname}{cmd:)}
{cmd:industry(}{it:varname}{cmd:)}
{cmd:shares(}{it:varname}{cmd:)}
{cmd:variant(}{it:varname}{cmd:)}
{cmd:growth(}{it:varname}{cmd:)}
{cmd:laborincome(}{it:varname}{cmd:)}
{cmd:simlaborincome(}{it:varname}{cmd:)}
[
{cmd:skill(}{it:varname}{cmd:)}
]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt age()}}specifies the name of the variable containing the age of each individual.{p_end}

{synopt:{opt education()}}specifies the name of the variable containing the education level of each individual.{p_end}

{synopt:{opt gender()}}specifies the name of the variable containing the gender of each individual.{p_end}

{synopt:{opt skill():}}specifies the name of the variable containing the skill level of each individual.{p_end}


{title:Description}


{cmd:ms_reweight} is a wrapper function that calls wentropy command to reweight micro-data to match population targets by age, gender, education, and industry shares.


{title:Saved results}

{pstd}
{cmd:ms_reweight} saves the following files: 

- The command generates a variable containing a new set of weights and an update variable with labor income.

{title:Examples}

{cmd:. ms_reweight, age(age) edu(calif) gender(gender) hhsize(hsize) hid(hhid) iw(weight) country("VNM") iyear(2002) /// }
{cmd: tyear(2016) generate(wgtsim) match(HH) popdata("$popdata") industry(industry) shares(sectoral_targets) skill(skilled) /// }
{cmd: variant("Medium-variant") growth(growth_laborincome) laborincome(labor_income) simlaborincome(sim_labor_income) targets(shares)}

{title:Authors}
{p}
{p_end}

{pstd}
Ercio Munoz, Poverty and Equity GP, the World Bank.

{pstd}
Email: {browse "mailto:emunozsaavedra@worldbank.org":emunozsaavedra@worldbank.org}

{title:Notes}




