/* 
Example 1: Reweighting-based microsimulation linked to a CGE
*/
net install github, from("https://haghish.github.io/github/")
github install erciomunoz/ms_reweight

use Example1.dta,clear

mat gen_edu_age_shares = .0758835\.0230117\.0127541\.0322489\.033622\.0316504\.024508 ///
\.0322303\0\.0309548\.0148538\.0163911\.0231916\.022489\.0104595\.0027001\0\.0216652\ ///
.0430452\.0226705\.0146583\.0154868\.0066576\.0013731\.0819804\.0263535\.0153777 ///
\.0289435\.029335\.0232391\.0125791\.0136433\0\.0323096\.0188657\.0153483\.021913  ///
\.0242922\.0116992 \.0048066 \0 \.0191356 \.0354902 \.0257726 \.0164802 \.0170445 ///
\.0082729 \.0046124 

mat growth_laborincome = 157.66,131.62 \ 112.93,59.93 \ 99.19,76.11 \ 74.17,97.37 ///
 \ 82.15,90.63 \ 97.61,74.16 \ 90.63,66.22 \ 88.99,88.59 

mat sectoral_targets = .2164053 , .029479 \ .0015971 , .0011561 \ .0608484 , .0350391 \ ///
.0001848 , .0013321 \ .0331996 , .0086027 \ .0633268 , .0346651 \ .009947 , .0096049 \ ///
.019996 , .0538296 

ms_reweight, age(age) edu(calif) gender(gender) hhsize(hsize) hid(hhid) iw(weight) ///
 iyear(2002) tyear(2016) generate(wgtsim) match(HH) ///
 country("Example") popdata("population - Example1") variant("Medium-variant") ///
 industry(industry) industryshares(sectoral_targets) skill(skilled) ///
 targets(gen_edu_age_shares) ///
 laborincome(labor_income) simlaborincome(sim_labor_income) growth(growth_laborincome)
  

* github uninstall ms_reweight