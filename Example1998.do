/* 
Example 1: Reweighting-based microsimulation 
*/
net install github, from("https://haghish.github.io/github/")
cap github uninstall ms_reweight
github install erciomunoz/ms_reweight

mat gen_edu_age_shares = ///
 .0687158 \ .0201254 \ .0012683 \ .0024893 \ .0055047 \ .0094925 \ .0129582 \ .020409 \ ///
 0 \ .0000199 \ .0316699 \ .0059426 \ .0090615 \ .0153785 \ .0192458 \ .0154524 \ ///
 0 \ .0147977 \ .023008 \ .0755668 \ .053372 \ .051573 \ .0386678 \ .0194587 \ ///
 .0122997 \ .0691335 \ .0220542 \ .0016508 \ .0024284 \ .0052396 \ .0068572 \ .0090823 \ ///  
 0 \ .0127094 \ .0000378 \ .0336497 \ .006714 \ .0083865 \ .0132019 \ .0156242 \ ///
 0 \ .0125731 \ .0106471 \ .0221617 \ .071369 \ .0472987 \ .0431383 \ .033415 

mat growth_laborincome = 1922.653 , 1379.8 \ 4071.278 , 2105.882 \ 2320.895 , 1399.573 \ ///
 3405.491 , 3915.768 \ 2480.845 , 1430.888 \ 2120.925 , 1242.761 \ 2812.062 , 1473.955 \ ///
 3669.261 , 1442.874 

mat sectoral_targets = .0338954 , .0015263 \ .0106397 , .0001518 \ .0443509 , .0005247 \ ///
 .0022176 , 4.12e-06 \ .0369428 , .0007995 \.0904014 , .0011197 \ .0309018 , .0002764 \ ///
 .1374343 , .0011761 
  
use Example_1998.dta,clear

ms_reweight, age(age) edu(calif) gender(gender) hhsize(hsize) hid(hhid) iw(weight) ///
 iyear(1998) tyear(2013) generate(wgtsim) match(HH) ///
 country("CHL") popdata("Population_Example_1998") variant("Medium") ///
 industry(industry) industryshares(sectoral_targets) skill(skilled) ///
 targets(gen_edu_age_shares) ///
 laborincome(labor_income) simlaborincome(sim_labor_income) growth(growth_laborincome)
 
ta industry [aw=wgtsim/hsize] ,m 
ta industry [aw=weight/hsize] ,m 

sgini labor_income [aw=weight/hsize]
sgini labor_income [aw=wgtsim/hsize]