gustave
=======

Gustave (Gustave: a User-oriented Statistical Toolkit for Analytical Variance Estimation) is an R package that provides a **toolkit for analytical variance estimation in survey sampling**. Apart from the implementation of standard variance estimators (Sen-Yates-Grundy, Deville-Tillé), its main feature is to help the methodologist produce easy-to-use variance estimation "wrappers", where systematic operations (linearization, domain estimation) are handled in a consistent and transparent way for the end user.

## Install

As gustave is not yet available on CRAN, for now the simplest way to install it on your computer is to use `devtools::install_github()`:

```
install.packages("devtools")
devtools::install_github("martinchevalier/gustave")
```

## Example

In this example, we define a variance estimation wrapper adapted to the example data inspired by the Information and communication technology (ICT) survey. The subset of the (simulated) ICT survey has the following features:

- stratified one-stage sampling design of 650 firms;
- 612 responding firms, non-response correction through reweighting in homogeneous response groups based on economic sub-sector and turnover;
- calibration on margins (number of firms and turnover broken down by economic sub-sector).

### Step 1: Define the variance *function*

In this context, the variance estimation *function* can be defined as follows:

```
library(gustave)

# Calibration variables matrix
x <- as.matrix(ict_survey[
  order(ict_survey$firm_id),
  c(paste0("N_", 58:63), paste0("turnover_", 58:63))
])

# Definition of the variance function
variance_function <- function(y){
  
  # Calibration
  y <- rescal(y, x = x)
  
  # Non-response
  y <- add0(y, rownames = ict_sample$firm_id)
  var_nr <- var_pois(y, pik = ict_sample$response_prob_est, w = ict_sample$w_sample)

  # Sampling
  y <- y / ict_sample$response_prob_est
  var_sampling <- var_srs(y, pik = 1 / ict_sample$w_sample, strata = ict_sample$division)

  var_sampling + var_nr
  
}

# Test of the variance function
y <- as.matrix(ict_survey$speed_quanti)
rownames(y) <- ict_survey$firm_id
variance_function(y)
```


### Step 2: Define the variance *wrapper*

The next step is the definition of a variance *wrapper*, which is easier to use than the variance function: 

```
variance_wrapper <- define_variance_wrapper(
  variance_function = variance_function,
  reference_id = ict_survey$firm_id,
  default = list(id = "firm_id", weight = "w_calib"),
  objects_to_include = c("x", "ict_sample")
)
```

**Note** The objects `x` and `ict_sample` are embedded within the function `variance_wrapper()` (`variance_wrapper` is a [closure](http://adv-r.had.co.nz/Functional-programming.html#closures))

### Step 3: Features of the variance wrapper

```
# Better display of results
variance_wrapper(ict_survey, speed_quanti)

# Mean linearization
variance_wrapper(ict_survey, mean(speed_quanti))
# Ratio linearization
variance_wrapper(ict_survey, ratio(turnover, employees))

# Discretization of qualitative variables
variance_wrapper(ict_survey, speed_quali)
# On-the-fly recoding
variance_wrapper(ict_survey, speed_quali == "Between 2 and 10 Mbs")

# 1-domain estimation
variance_wrapper(ict_survey, speed_quanti, where = division == "58")
# Multiple domains estimation
variance_wrapper(ict_survey, speed_quanti, by = division)

# Multiple variables at a time
variance_wrapper(ict_survey, speed_quanti, big_data)
variance_wrapper(ict_survey, speed_quanti, mean(big_data))
# Flexible syntax for where and by arguments
# (similar to the aes() function in ggplot2)
variance_wrapper(ict_survey, where = division == "58", 
 mean(speed_quanti), mean(big_data * 100)
)
variance_wrapper(ict_survey, where = division == "58", 
 mean(speed_quanti), mean(big_data * 100, where = division == "61")
)
variance_wrapper(ict_survey, where = division == "58", 
 mean(speed_quanti), mean(big_data * 100, where = NULL)
)
```


