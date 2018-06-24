gustave
=======

Gustave (Gustave: a User-oriented Statistical Toolkit for Analytical Variance Estimation) is an R package that provides a **toolkit for analytical variance estimation in survey sampling**. Apart from the implementation of standard variance estimators (Sen-Yates-Grundy, Deville-Tillé), its main feature is to help the methodologist produce easy-to-use variance estimation "wrappers", where systematic operations (linearization, domain estimation) are handled in a consistent and transparent way for the end user.

## Install

gustave is available on CRAN and can therefore be installed with the `install.packages()` function:

```
install.packages("gustave")
```

However, if you wish to install the latest version of gustave, you can use `devtools::install_github()` to install it directly from this repository:

```
install.packages("devtools")
devtools::install_github("martinchevalier/gustave")
```

## Example

In this example, we define a variance estimation wrapper adapted to the example data inspired by the Information and communication technology (ICT) survey. The subset of the (simulated) ICT survey has the following features:

- stratified one-stage sampling design of 650 firms;
- 612 responding firms, non-response correction through reweighting in homogeneous response groups based on economic sub-sector and turnover;
- calibration on margins (number of firms and turnover broken down by economic sub-sector).

The ICT data files are shipped with the gustave package:

```
library(gustave)
data(package = "gustave")
? ict_survey
```

### Step 1: Define the variance *function*

In this context, the variance estimation *function* specific to the ICT survey can be defined as follows:

```
# Definition of the variance function
variance_function_ict <- function(y, x, w, samp){
  
  # Calibration
  y <- rescal(y, x = x, w = w)
  
  # Non-response
  y <- add0(y, rownames = samp$firm_id)
  var_nr <- var_pois(y, pik = samp$response_prob_est, w = samp$w_sample)

  # Sampling
  y <- y / samp$response_prob_est
  var_sampling <- var_srs(y, pik = 1 / samp$w_sample, strata = samp$division)

  var_sampling + var_nr
  
}

# y is the matrix of variables of interest, x, w, and samp are some technical data:
technical_data_ict <- list(
  
  # x: calibration variables matrix
  x = as.matrix(ict_sample[
    ict_survey$firm_id,
    c(paste0("N_", 58:63), paste0("turnover_", 58:63))
  ]),

  # w: calibrated weights
  w = ict_survey$w_calib[order(ict_survey$firm_id)],
  
  # samp: sample file
  samp = ict_sample
  
)

# Test of the variance function
y <- matrix(ict_survey$speed_quanti, dimnames = list(ict_survey$firm_id))
with(technical_data_ict, variance_function_ict(y, samp = samp, x = x, w = w))
```


### Step 2: Define the variance *wrapper*

The next step is the definition of a variance *wrapper*, which is easier to use than the variance function: 

```
# Definition of the variance wrapper
variance_wrapper_ict <- define_variance_wrapper(
  variance_function = variance_function_ict,
  reference_id = ict_survey$firm_id, 
  reference_weight = ict_survey$w_calib, 
  technical_data = technical_data_ict,
  default_id = "firm_id"
)
```

**Note** The object `technical_data_ict` is embedded within the function `variance_wrapper_ict()` (`variance_wrapper_ict()` is a [closure](http://adv-r.had.co.nz/Functional-programming.html#closures)).

```
ls(environment(variance_wrapper_ict))
```

As a consequence, the variance wrapper will work even if `technical_data_ict` is removed from `globalenv()`

```
rm(technical_data_ict)
```

### Step 3: Features of the variance wrapper

```
# Better display of results
variance_wrapper_ict(ict_survey, speed_quanti)

# Mean linearization
variance_wrapper_ict(ict_survey, mean(speed_quanti))
# Ratio linearization
variance_wrapper_ict(ict_survey, ratio(turnover, employees))

# Discretization of qualitative variables
variance_wrapper_ict(ict_survey, speed_quali)
# On-the-fly recoding
variance_wrapper_ict(ict_survey, speed_quali == "Between 2 and 10 Mbs")

# 1-domain estimation
variance_wrapper_ict(ict_survey, speed_quanti, where = division == "58")
# Multiple domains estimation
variance_wrapper_ict(ict_survey, speed_quanti, by = division)

# Multiple variables at a time
variance_wrapper_ict(ict_survey, speed_quanti, big_data)
variance_wrapper_ict(ict_survey, speed_quanti, mean(big_data))
# Flexible syntax for where and by arguments
# (similar to the aes() function in ggplot2)
variance_wrapper_ict(ict_survey, where = division == "58", 
 mean(speed_quanti), mean(big_data * 100)
)
variance_wrapper_ict(ict_survey, where = division == "58", 
 mean(speed_quanti), mean(big_data * 100, where = division == "61")
)
variance_wrapper_ict(ict_survey, where = division == "58", 
 mean(speed_quanti), mean(big_data * 100, where = NULL)
)
```

## Colophon

This software in an [R](https://cran.r-project.org/) package developed with the [RStudio IDE](https://www.rstudio.com/) and the [devtools](https://CRAN.R-project.org/package=devtools), [roxygen2](https://CRAN.R-project.org/package=roxygen2) and [testthat](https://CRAN.R-project.org/package=testthat) packages. MUch help was found in [R packages](http://r-pkgs.had.co.nz/) and [Advanced R](http://adv-r.had.co.nz/) both written by [Hadley Wickham](http://hadley.nz/).

From the methodological point of view, this package is related to the [Poulpe SAS macro (in French)](http://jms-insee.fr/jms1998_programme/#1513415199356-a8a1bdde-becd) developed at the French statistical institute. From the implementation point of view, some inspiration was found in the [ggplot2](https://CRAN.R-project.org/package=ggplot2) package. The idea of developing an R package on this specific topic was stimulated by the [icarus](https://CRAN.R-project.org/package=icarus) package and its author.
