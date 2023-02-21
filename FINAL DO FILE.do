* 1.1. Checking for heaping/manipulation (Question 1)

gen dui = 0
//Creating dummy variable for DUI. DUI = 1 if past 0.08 threshold, 0 otherwise. Include "." for missing values
replace dui = 1 if bac1>=0.08 & bac1~=.

* Quadratic bac1
gen bac1_sq = bac1^2 //creating bac1_sq value for future use

histogram bac1, discrete width(0.001) ytitle(Frequency) xtitle(Blood Alcohol Content) xline(0.08) title(BAC histogram) subtitle(Density of stops for DUI across BAC) note(Discrete histogram) color(gray) graphregion(color(white)) // Making discrete histogram with a white background to check for visible heaping

histogram bac1, width(0.001) ytitle(Frequency) xtitle(Blood Alcohol Content) xline(0.08) title(BAC histogram) subtitle(Density of stops for DUI across BAC) note(Continuous histogram) color(gray) graphregion(color(white)) // Making continuous histogram as well

// In order to check for heaping, we can run two histograms, one using bac1 as a discrete variable, whereby it takes on a fixed number of potential values, and one using bac1 as a continuous variable, whereby it can take an infinite numbe of values. Using bac1 as the continuous variable, we can observe heaping shown by the spikes in the graph.

// The reason this heaping is only visible on the continuous graph is because the continuous graph assumes the data can take an infinite values. This means each bar in the histogram represents a range of possible values (in this case in increments of 0.001, as we have stated in the width). 

histogram bac1 if bac1>=0.152 & bac1<=0.161, discrete width(0.001) ytitle(Frequency) xtitle(Blood Alcohol Content) xline(0.08) title(BAC histogram) subtitle(Density of stops for DUI across BAC) note(Discrete histogram and bandwidth of 0.152 - 0.161) color(gray) lcolor(white) graphregion(color(white)) //Zoomed in verison of discrete histogram

histogram bac1 if bac1>=0.152 & bac1<=0.161, width(0.001) ytitle(Frequency) xtitle(Blood Alcohol Content) xline(0.08) title(BAC histogram) subtitle(Density of stops for DUI across BAC) note(Continuous histogram and bandwidth of 0.152 - 0.161) color(gray) lcolor(white) graphregion(color(white)) // Zoomed in version of continuous histogram 

rddensity bac1, c(0.08) graph_opt(graphregion(color(white))title(Rddensity graph) subtitle("Density Discontinuity Testing") xtitle("Blood Alcohol Content") ytitle(Density) leg(off)) plot
// rddensity results in p value < 0.05 (significance level), meaning there is no manipulation near the threshold. rddensity uses data-driven bandwidths to check for heaping by comparing values of left and right of cutoff

* 1.2. Checking for covariance / continuity assumption (Question 2)

// RDD works under the continuity assumption (assumption that lines would continue smoothly on either side of the threshold if the cutoff didnt exist) 
// In order for the continuity assumption to be true, its inmportant to check that no other variables jump at the cutoff point, as this would violate the continuity assumption
// To check for this, you can run regression with the potential covariants and the interaction term dui*bac1. If any of these regressions have a significant P-value, the continuity assumption is being violated. 

eststo clear 

reg white dui##c.bac1 if bac1>=0.03 & bac1<=0.13, robust //results in p value higher than significance level for T-test
eststo
reg male dui##c.bac1 if bac1>=0.03 & bac1<=0.13, robust //results in p value higher than significance level for T-test
eststo
reg acc dui##c.bac1 if bac1>=0.03 & bac1<=0.13, robust //results in p value lower than significance level for T-test, means significance co-variant
eststo
reg aged dui##c.bac1 if bac1>=0.03 & bac1<=0.13, robust //results in p value lower than significance level for T-test, means significance co-variant
eststo

esttab using "table_covariance.rtf"

gen acc_sq = acc^2
reg acc_sq dui##c.bac1 if bac1>=0.06 & bac1<=0.10, robust //results in p value lower than significance level for T-test, means significance co-variant
reg aged dui##c.bac1_sq if bac1 

//Given there is covariance between accidents on scene and dui, as well as age and dui, in the rdd we must control for both of these variables. 

*1.3 Main results - Punishment and recividism (Question 3)

//Replicating main results:

//Using standard local polynomial with predetermined bandwidths
//Here we are running a regression with controls to check the main relationship Hansen draws between punbishment and recividism. We first check for a linear relationship using bac1 and then a quadratic regression using bac1_sq
//I run these regressions first with the larger bandwidth Hansen uses of 0.05, and then with the smaller bandwidth of 0.025

eststo clear
//running linear regression with large bandwidth 
reg recidivism white male aged acc dui##c.bac1 if bac1>=0.03 & bac1<=0.13, robust
eststo
//running quadratic regression with large bandwidth
reg recidivism white male aged acc dui##c.(bac1 bac1_sq) if bac1>=0.03 & bac1<=0.13, robust
eststo

esttab using "main_results_large_bandwidth.rtf"

eststo clear

* Slightly smaller bandwidth of 0.055 to 0.105
//running linear regression with small bandwidth
reg recidivism white male aged acc dui##c.bac1 if bac1>=0.055 & bac1<=0.105, robust
eststo
//running quadratic regression with large bandwidth
reg recidivism white male aged acc dui##c.(bac1 bac1_sq) if bac1>=0.055 & bac1<=0.105, robust
eststo

esttab using "main_results_small_bandwidth.rtf"


eststo clear

//I use local polynomials with rdrobust to re-run these regressions using data-driven bandwidths and smoothing functions of rdrobust. Rdrobust offers a more robust way to look at relationships in regression discontinuity design, and is the gold standard in the field. I use rdrobust with uniform kernels

//Using local polynomial with data-driven bandwidth choosing and uniform kernel
rdrobust recidivism bac1 white male aged, kernel(uniform) masspoints(off) p(1) c(0.08)
eststo
rdrobust recidivism bac1 white male aged, kernel(uniform) masspoints(off) p(2) c(0.08)
eststo

esttab using "main_results_rdrobust.rtf"

//To depict the results, running cmograms with linear and quadratic lines of best fit
cmogram recidivism bac1 if bac1>0.03 & bac1<0.13, cut(0.08) scatter line(0.08) graphopts(bgcolor(white) title(Cmogram) subtitle(Binned Scatter Graph of Means) note(linear line of best fit)) lfitci
cmogram recidivism bac1 if bac1>0.03 & bac1<0.13, cut(0.08) scatter line(0.08) graphopts(bgcolor(white) title(Cmogram) subtitle(Binned Scatter Graph of Means) note(quadratic line of best fit)) qfitci


* 1.4. Robustness testing with donut holes (Question 4)

//Question 4, Implementing donut hole with standard regresison

gen 	donut = 0 //creating dummy variable for donut hole kernel
replace donut = 1 if bac1>=0.079 & bac1<=0.081 //making dummy variable equal 1 if values lie inside bandwidth we want to drop 

reg recidivism white male aged acc dui##c.bac1 if bac1>=0.03 & bac1<=0.13 & donut==0, robust //conditional if statement to not include values inside donut hole
reg recidivism white male aged acc dui##c.bac1 if bac1>=0.03 & bac1<0.13, robust //comparing without donut hole kernel

// Donut nonparameteric presentation
cmogram recidivism bac1 if bac1>0.03 & bac1<0.13 & donut==0, cut(0.08) scatter line(0.08) graphopts(bgcolor(white)) lfitci
// without donut nonparameteric presentation
cmogram recidivism bac1 if bac1>0.055 & bac1<0.105, cut(0.08) scatter line(0.08) graphopts(bgcolor(white)) lfitci

** Question 5 - Local polynomials with donut holes

//Running donut hole robustness check with local polynomials
//Using rdrobust because of its data-driven bandwidth selection which optimises the bias-variance tradeoff. rdrobust also has further smoothing functions included in the documentation

**Comparing with and without donut hole with 1st order local polynomials with data-driven bandwidths**

eststo clear 

//Triangular Kernel
rdrobust recidivism bac1, kernel(triangular) masspoints(off) p(1) c(0.08) //Controls make no difference
eststo
rdrobust recidivism bac1 if donut == 0, kernel(triangular) masspoints(off) p(1) c(0.08)
eststo


//Uniform Kernel
rdrobust recidivism bac1, kernel(uniform) masspoints(off) p(1) c(0.08)
eststo
rdrobust recidivism bac1 if donut == 0, kernel(uniform) masspoints(off) p(1) c(0.08)
eststo


//Epanechnikov Kernel
rdrobust recidivism bac1, kernel(epanechnikov) masspoints(off) p(1) c(0.08)
eststo
rdrobust recidivism bac1 if donut == 0, kernel(epanechnikov) masspoints(off) p(1) c(0.08)
eststo

esttab using "first_order_kernel_rdrobust.rtf"

eststo clear 

**Comparing with and without donut hole with 2nd order local polynomials with data-driven bandwidths**

//Triangular Kernel
rdrobust recidivism bac1, kernel(triangular) masspoints(off) p(2) c(0.08)
eststo
rdrobust recidivism bac1 if donut == 0, kernel(triangular) masspoints(off) p(2) c(0.08)
eststo

//Uniform Kernel
rdrobust recidivism bac1, kernel(uniform) masspoints(off) p(2) c(0.08)
eststo
rdrobust recidivism bac1 if donut == 0, kernel(uniform) masspoints(off) p(2) c(0.08)
eststo

//Epanechnikov Kernel
rdrobust recidivism bac1, kernel(epanechnikov) masspoints(off) p(2) c(0.08)
eststo
rdrobust recidivism bac1 if donut == 0 , kernel(epanechnikov) masspoints(off) p(2) c(0.08)
eststo

esttab using "second_order_kernel_rdrobust.rtf"

//Could include rddensity here as well!!!

** Question 6 - Cmogram and rdplot with asymmetric bandwidths

rdplot recidivism bac1 if bac1>=0.06 & bac1<=0.11, p(1) masspoints(off) c(0.08) ci(95) shade graph_options(title(RD Plot Recidivism and BAC)subtitle(Local Polynomial with Data-Driven Bandwidth Selection)graphregion(color(white)))  //rdplot uses local polynomials and data-driven bandwidth selection 

cmogram recidivism bac1 if bac1>=0.06 & bac1<=0.11, cut(0.08) scatter line(0.08) graphopts(title(Cmogram) subtitle(Binned Scatter Graph of Means) note(Bandwidths 0.06 - 0.11) bgcolor(white)) lfitci //cmograms nonparametric representaiton. We decide to employ 

