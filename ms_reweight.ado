*! version 1.0   Ercio Munoz & Israel Osorio-Rodarte 8/2/2022 
	
/* 
Program to re-weight the population given demographic projections (age, 10-year cohorts & education) and sector shares.
Note that observations with missing values for education are dropped
Note that calif must have 3 categories (1=unskilled, 2=semi-skilled, and 3=skilled)
*/

cap program drop ms_reweight
program define ms_reweight
version 12.0

syntax [anything], AGE(string) EDUcation(string) GENDER(string) HHSIZE(string) HID(string) IWeights(string) /* 
 */  COUNTRY(string) IYEAR(string) TYEAR(string) Generate(string) MATCH(string) POPDATA(string) /* 
 */  VARIANT(string) /*
 */ [ PID(string) SKILL(string) INDUSTRY(string) INDUSTRYSHARES(string) TARGETS(string) /*
 */ GROWTH(string) LABORINCOME(string) SIMLABORINCOME(string) FOODPRICES(string) FOODSHARES(string) ] 
	
********************************************************************************
	** Bringing UN population projections and aggregating cohorts ** 
********************************************************************************
quietly	{
		preserve
			
			use "`popdata'" if country=="`country'" & Variant=="`variant'", clear

				sort country cohort
				replace cohort="P0009" if inlist(cohort,"P0004","P0509") /* 1st cohort */
				replace cohort="P1019" if inlist(cohort,"P1014","P1519") /* 2nd cohort */
				replace cohort="P2029" if inlist(cohort,"P2024","P2529") /* 3rd cohort */
				replace cohort="P3039" if inlist(cohort,"P3034","P3539") /* 4th cohort */
				replace cohort="P4049" if inlist(cohort,"P4044","P4549") /* 5th cohort */
				replace cohort="P5059" if inlist(cohort,"P5054","P5559") /* 6th cohort */
				replace cohort="P6069" if inlist(cohort,"P6064","P6569") /* 7th cohort */				
				replace cohort="P70up" if inlist(cohort,"P7074","P7579","P8084","P8589","P9094","P9599","P100up") /* 8th cohort, 70 and up */
				gcollapse (sum) yf* ym*, by(country cohort)
			
				gen cohort_merge = _n
				drop country cohort
				sort cohort_merge
				tempfile popdata
				save `popdata', replace
			/* `popdata' has 8 cohorts and one column for each year/gender */		
				
				gen country_merge = "`country'"
					collapse (sum) y*, by(country_merge)
					
					forval p = 2011/2100 {
						gen double y`p'1 = yf`p' + ym`p'
					}
				
					drop ym* yf*
					
					sort country_merge
					tempfile popdatatot
					save `popdatatot', replace
			/* `popdatatot' has total population by year */
		restore
}

********************************************************************************		
	** Verifying data and checking for errors in the options provided **
********************************************************************************
quietly	{		
		* Pre-defined option		
		local adjust_missing = 1 

		local stp = (`tyear' - `iyear')
				
		* Verifying that EDUcation has not missing values
		keep if `education'!=.
		levelsof `education', local(alledus)
		
		cap ta `industry'
		if (_rc==0) local nindustries = r(r) 
		
		if ("`skill'"=="") {
			tempvar skill 
			gen `skill'=1
		}
		levelsof `skill', local(levels)
	
		* Verifying that the survey year selected is within range
		if `iyear' < 2011 | `iyear' > 2100 {
			noi di " "
			noi di in red "Survey year is out of range (2011-2100)"
			exit
		}		
	
		* Verifying that the target year selected is within range
		if `tyear' < 2011 | `tyear' > 2100 {
			noi di " "
			noi di in red "Target year is out of range (1950-2100)"
			exit
		}	
		
		* Verifying that targets for each skill group are provided	
		if (("`industry'"!="" & "`industryshares'"=="") | ("`industry'"=="" & "`industryshares'"!="")) {
			noi di " "
			noi di in red "An industry variable must be provided with a matrix of employment shares."
			exit	
		}
		
		qui ta `skill'
		local nskills = r(r)	
		if ("`industry'"!="") {
			if (`nskills' != colsof(`industryshares')) {
			noi di " "
			noi di in red "Number of skill groups does not match number of columns in target matrix for industry shares."
			exit
			}
		}
		
		if ("`targets'"!="" & "`industry'"=="" & "`industryshares'"=="" & 48 != rowsof(`targets') & 1 != colsof(`targets')) {
			noi di " "
			noi di in red "Target matrix needs to be 48 x 1."
			exit
		}
		if ("`targets'"!="" & 48 != rowsof(`targets') & 1 != colsof(`targets')) {
			noi di " "
			noi di in red "Targets matrix needs to be 48 x 1 (8 age groups X 2 genders x 3 education groups)."
			exit
		}

		* Options for updating labor income. Users provides them all or none.
		if !(("`laborincome'"!="" & "`simlaborincome'"!="" & "`growth'"!="") | ("`laborincome'"=="" & "`simlaborincome'"=="" & "`growth'"=="")) {
			noi di " "
			noi di in red "User must provide all laborincome(), simlaborincome(), and growth() options or none of them."
			exit
		}
		
		* Saving original data 
			tempfile base
			save "`base'"
	}

********************************************************************************
	** Generating target matrix based on education and cohorts **
********************************************************************************
quietly {
	* Generate age - cohorts
	tempvar cohort
	tempvar pop
	gen `cohort'=8
	label var `cohort' "Age Group"
	
	* Generate Age Groups
	forval x = 1/8 {
		replace `cohort' = `x' if `age' >=(`x'-1)*10 & `age' <= ((`x'-1)*10)+9
	}
			
	gen double `pop'=1
	
	collapse (sum) `pop'  [fw=round(`iweights')], by(`cohort' `education' `gender')

	bys `education': table `cohort' `gender', c(sum `pop')

	reshape wide `pop' , i(`cohort' `gender') j(`education') 
	reshape wide `pop'*, i(`cohort') j(`gender') 
		
	sort `cohort'
	mvencode _all, mv(0) // Change missing values to numeric values

		tempvar pop1	// Population for Males (gender=1)
		tempvar pop2    // Population for Women (gender=2)

		egen double `pop1' = rsum(`pop'*1) 
		egen double `pop2' = rsum(`pop'*2)
		
		replace `pop1'=. if `pop1'==0
		replace `pop2'=. if `pop2'==0
		
		* Calculate Shares
		
		foreach j of local alledus {
			gen double sh`j'1 = `pop'`j'1/`pop1'
			gen double sh`j'2 = `pop'`j'2/`pop2'
		}
			
		list `cohort' `pop1' `pop2' sh11 sh21 sh31 sh12 sh22 sh32
		sort `cohort'

		local steps = round((`tyear' - `iyear')/10)+2

		forval step = 1/`steps' {
		
			local yyyy = `iyear' + 10*(`step'-1)
			local yyy0 = `yyyy' - 10
		
			gen sh11_`yyyy'=. 
			gen sh21_`yyyy'=.
			gen sh31_`yyyy'=.

			gen sh12_`yyyy'=. 
			gen sh22_`yyyy'=.
			gen sh32_`yyyy'=.
			
			if `iyear'==`yyyy' {

				replace sh11_`yyyy' = sh11
				replace sh21_`yyyy' = sh21
				replace sh31_`yyyy' = sh31
				
				replace sh12_`yyyy' = sh12
				replace sh22_`yyyy' = sh22
				replace sh32_`yyyy' = sh32
			
			}
			
			/* Here we use the same shares from baseline to 3 youngest cohorts */
			if `iyear'!=`yyyy' {
				replace sh11_`yyyy'=sh11 if `cohort'<=3
				replace sh21_`yyyy'=sh21 if `cohort'<=3
				replace sh31_`yyyy'=sh31 if `cohort'<=3

				replace sh12_`yyyy'=sh12 if `cohort'<=3
				replace sh22_`yyyy'=sh22 if `cohort'<=3
				replace sh32_`yyyy'=sh32 if `cohort'<=3
		
				local count1 = ((`yyyy' - `iyear')/10)
				di `count1'
			
			/* Replacing share for cohort i with share of previous cohort getting older */
				forval i = 1/`count1' {
					replace sh11_`yyyy'=sh11_`yyy0'[_n-1] if `cohort'==3+`i'
					replace sh21_`yyyy'=sh21_`yyy0'[_n-1] if `cohort'==3+`i'
					replace sh31_`yyyy'=sh31_`yyy0'[_n-1] if `cohort'==3+`i'

					replace sh12_`yyyy'=sh12_`yyy0'[_n-1] if `cohort'==3+`i'
					replace sh22_`yyyy'=sh22_`yyy0'[_n-1] if `cohort'==3+`i'
					replace sh32_`yyyy'=sh32_`yyy0'[_n-1] if `cohort'==3+`i'
				}	
		
				
				local count2 = 8 - ((`yyyy' - `iyear')/10) + 3	
				local count3 =      ((`yyyy' - `iyear')/10)		
		
				forval i = 1/`count2' {
		
					replace sh11_`yyyy'=sh11_`iyear'[_n-`count3'] if `cohort'==3+`count3'+`i'
					replace sh21_`yyyy'=sh21_`iyear'[_n-`count3'] if `cohort'==3+`count3'+`i'
					replace sh31_`yyyy'=sh31_`iyear'[_n-`count3'] if `cohort'==3+`count3'+`i'

					replace sh12_`yyyy'=sh12_`iyear'[_n-`count3'] if `cohort'==3+`count3'+`i'
					replace sh22_`yyyy'=sh22_`iyear'[_n-`count3'] if `cohort'==3+`count3'+`i'
					replace sh32_`yyyy'=sh32_`iyear'[_n-`count3'] if `cohort'==3+`count3'+`i'

				}
				
			}
		}
		
		if `adjust_missing' == 1 {
			gen R1m = sh11==0|sh21==0|sh31==0
			gen R1f = sh12==0|sh22==0|sh32==0			
			
			forval step = 1/`steps' {
			
				local yyyy = `iyear' + 10*(`step'-1)

		 		replace sh11_`yyyy' = 0 if R1m==1 & sh11==0
				replace sh21_`yyyy' = 0 if R1m==1 & sh21==0
		 		replace sh31_`yyyy' = 0 if R1m==1 & sh31==0

			 	replace sh12_`yyyy' = 0 if R1f==1 & sh12==0
				replace sh22_`yyyy' = 0 if R1f==1 & sh22==0
			 	replace sh32_`yyyy' = 0 if R1f==1 & sh32==0

				egen _Tsh1_`yyyy' = rsum(sh*1_`yyyy')
				egen _Tsh2_`yyyy' = rsum(sh*2_`yyyy')

		 		replace sh11_`yyyy' = sh11_`yyyy'/_Tsh1_`yyyy'
	 			replace sh21_`yyyy' = sh21_`yyyy'/_Tsh1_`yyyy'
	 			replace sh31_`yyyy' = sh31_`yyyy'/_Tsh1_`yyyy'

		 		replace sh12_`yyyy' = sh12_`yyyy'/_Tsh2_`yyyy'
		 		replace sh22_`yyyy' = sh22_`yyyy'/_Tsh2_`yyyy'
	 			replace sh32_`yyyy' = sh32_`yyyy'/_Tsh2_`yyyy'

		 		drop _T*
		 	
		 		}	
		 	
			 drop R1m R1f
		 
		 }
		
		
		* Interpolation 
		
		tempvar last
		gen `last' = 1
		
		keep `pop1' `pop2' `cohort' sh11_`iyear' - `last'
					
		reshape long sh11_ sh21_ sh31_ sh12_ sh22_ sh32_, i(`cohort')
		rename _j year
		levelsof year, local(yrs)
		
		foreach var of local yrs {
			expand 10 if year==`var'
		}
		
		foreach var of varlist sh11_ - sh32_ {
		bys `cohort' year: replace `var'=. if _n>1
		}
		
		bys `cohort' year: replace year = year[_n-1]+1 if _n>=2
			drop if year>2100
		
	
		foreach var of varlist sh11_ - sh32_ {
			bys `cohort': ipolate `var' year, gen (e_`var')
			replace `var' = e_`var' if `var'==.
			drop e_`var'
		}

		
		levelsof year, local(allyears)
		
		reshape wide sh*, i(`cohort') j(year)
		
		gen cohort_merge = `cohort'
		sort cohort_merge
		
		merge cohort_merge using "`popdata'"
			
		tab _merge
		keep if _merge==3
		drop _merge 
				
	foreach y of local allyears {
	 
		tempvar sumpop`y'
		tempvar UNsumpop`y'
			
		if "`match'" == "UN" {
			egen double `sumpop`y'' = sum(yf`y' + ym`y')
			sum `sumpop`y''
			local lsumpop`y' = r(mean)
		}
			
		if "`match'" == "HH" {
		
			if `y'==`iyear' {
				egen double `sumpop`y'' = sum(`pop1' + `pop2')
				sum `sumpop`y''
				local lsumpop`y' = r(mean)
*				noi di "Population in year: `y': `lsumpop`y''" 
			}
			
			if `y'> `iyear' {
				local z = `y' - 1	// Option for all years
				
				
				replace `pop1' = (`pop1')*(ym`y'/ym`z')		// pop1 is for males
				replace `pop2' = (`pop2')*(yf`y'/yf`z')		// pop2 is for females
			
				egen double `sumpop`y'' = sum(`pop1' + `pop2')
				sum `sumpop`y''
				local lsumpop`y' = r(mean)
*				noi di "Population in year: `y': `lsumpop`y''" 
			}
		}			
		
		if "`match'" == "UN" {	
			replace sh11_`y' = (sh11_`y' * ym`y')/`lsumpop`y''
			replace sh21_`y' = (sh21_`y' * ym`y')/`lsumpop`y''
			replace sh31_`y' = (sh31_`y' * ym`y')/`lsumpop`y''
				
			replace sh12_`y' = (sh12_`y' * yf`y')/`lsumpop`y''
			replace sh22_`y' = (sh22_`y' * yf`y')/`lsumpop`y''
			replace sh32_`y' = (sh32_`y' * yf`y')/`lsumpop`y''
		}
			
		if "`match'" == "HH" {
			replace sh11_`y' = (sh11_`y' * `pop1')/`lsumpop`y''
			replace sh21_`y' = (sh21_`y' * `pop1')/`lsumpop`y''
			replace sh31_`y' = (sh31_`y' * `pop1')/`lsumpop`y''
				
			replace sh12_`y' = (sh12_`y'* `pop2')/`lsumpop`y''
			replace sh22_`y' = (sh22_`y'* `pop2')/`lsumpop`y''
			replace sh32_`y' = (sh32_`y'* `pop2')/`lsumpop`y''
		}
		
	}
		
	drop yf* ym* 
	
		forval a = `iyear'/`tyear' {	
		mkmat sh12_`a'                 	, matrix(A`a') 
		mkmat sh22_`a'   				, matrix(B`a')
		mkmat sh32_`a' if `cohort' <=8	, matrix(C`a')
		mkmat sh11_`a'                 	, matrix(D`a')
		mkmat sh21_`a' 					, matrix(E`a')
		mkmat sh31_`a' if `cohort' <=8 , matrix(F`a')
		}
		
		
		forval a = `iyear'/`tyear' {
			matrix define const`a' = [ A`a' \ B`a' \ C`a' \ D`a' \ E`a' \ F`a' ]
		}

if ("`targets'" != "") mat const`tyear' = `targets'
}				
	
********************************************************************************
	**  Applying the calibration command **
********************************************************************************	
	use `base', clear
		
		foreach g in 2 1 {
			foreach e of local alledus {
				forval i = 1/8 {
					
					if `g' == 2 local gm = "f"	// Females
					if `g' == 1 local gm = "m"	// Males
				
					local j = (`i'-1)*10
				
					if `i'==1 {	
						gen double c`e'`gm'0`j' = (age >= (`i'-1)*10 & age<= ((`i'-1)*10)+9 & `gender'==`g' & calif==`e')
					}

					else {
						gen double c`e'`gm'`j' = (age >= (`i'-1)*10 & age<= ((`i'-1)*10)+9 & `gender'==`g' & calif==`e')
					}
				}
			}
		}
		
	if ("`industry'"!="") {
		local skillgroup = 1
		foreach s of local levels {
			forval i = 1/`nindustries' {
				gen double i`i's`skillgroup' = (`skill' == `s' & `industry' == `i')
			}	
			local skillgroup = `skillgroup'+1	
		}
	
		forval s = 1/`nskills' {	
			matrix const`tyear' = const`tyear' \ `industryshares'[1...,`s']
		}
	}
	
	* This is to generate the constrains for the reweighting, first, at the household level. 
if ("`pid'" == "" & "`industry'"!="") gcollapse (mean) c1f00-c3m70 i1s1-i`nindustries's`nskills', by(`hid' `hhsize' `iweights')
if ("`pid'" == "" & "`industry'"=="") gcollapse (mean) c1f00-c3m70								, by(`hid' `hhsize' `iweights')
		
	noi di "Wentropy for country `country' in year `tyear'"
	noi di "The constraint matrix is"
	matrix list const`tyear'
	noi di "Total population is `lsumpop`tyear''"
	noi di "wentropy c1f00-c3m70 industry1_skill1-industry`nindustries'_skill`nskills', old(`iweights') new(`generate') constraints(const`tyear') pop(`lsumpop`tyear'')"		
		
if ("`industry'"=="") wentropy c1f00-c3m70							    , old(`iweights') new(newwgt) constraints(const`tyear') pop(`lsumpop`tyear'')
else 				  wentropy c1f00-c3m70 i1s1-i`nindustries's`nskills', old(`iweights') new(newwgt) constraints(const`tyear') pop(`lsumpop`tyear'')
		
	if ("`pid'" == "") qui gen newiwgt = newwgt/`hhsize'
	else qui clonevar newiwgt = newwgt
	if ("`pid'" == "") keep `hid' newiwgt
	else keep `hid' `pid' newiwgt
	qui clonevar idh_merge = `hid'
	if ("`pid'" != "") qui clonevar idp_merge = `pid'
	if ("`pid'" == "") sort idh_merge
	else sort idh_merge idp_merge
	tempfile max`tyear'
	qui save `max`tyear'', replace
	
use `base', clear
	
	qui clonevar idh_merge = `hid'
	if ("`pid'" != "") qui clonevar idp_merge = `pid' 
	if ("`pid'" == "") sort idh_merge
	else sort idh_merge idp_merge
	if ("`pid'" == "") qui merge m:1 idh_merge using `max`tyear''
	else qui merge m:1 idh_merge idp_merge using `max`tyear''
	drop _merge
	if ("`pid'" == "") sort idh_merge
	else sort idh_merge idp_merge 
	drop idh_merge
	cap drop idp_merge
	qui gen double `generate' = round(newiwgt)
	drop newiwgt

	* Updating labor income
	if ("`simlaborincome'"!="") {	
		qui g double `simlaborincome' = .
		local skillgroup = 1
		foreach s of local levels {
			forval i = 1/`nindustries' {
				tempname mean1 mean2
				qui sum `laborincome' [w=`generate'] if (`skill' == `s' & `industry' == `i')
				scalar `mean1' = r(mean)
				qui sum `laborincome' [w=`iweights'] if (`skill' == `s' & `industry' == `i')
				scalar `mean2' = r(mean)
				qui replace `simlaborincome' = `laborincome' * (`mean2'/`mean1') * `growth'[`i',`skillgroup'] if (`skill' == `s' & `industry' == `i')
			}	
			local skillgroup = `skillgroup'+1	
		}
	}
	
	/*
	* Impact of prices
	if ("`foodprices'"!="") {
	    
		tempname _yinitial _yfood
		
		sum Yini`simyear' [w=`generate']
		scalar `_yinitial' = r(mean)
		
		gen double foodadjust`simyear' = (( foodshare) * ${rfcpi_t`simyear'_sc`sc'}) + (( 1-foodshare ) * ${rocpi_t`simyear'_sc`sc'})	
		replace Ysim_food`simyear' = Ysim_food`simyear' * (_ysim_ini`simyear'/_ysim_food`simyear')	
		
		sum Yini`simyear' [w=wgtsim`simyear']
		scalar _ysim_food`simyear' = r(mean)
		
	}
	*/

end











