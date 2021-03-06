rm(list = ls(all.names = TRUE))

variance_function_ict <- function(y, x, w, samp){
  
  # Calibration
  y <- res_cal(y, x = x, w = w)
  
  # Non-response
  y <- add_zero(y, rownames = samp$id)
  var_nr <- var_pois(y, pik = samp$response_prob_est, w = samp$w_sample)
  
  # Sampling
  y <- y / samp$response_prob_est
  var_sampling <- var_srs(y, pik = 1 / samp$w_sample, strata = samp$strata)
  
  list(var = var_sampling + var_nr, samp = samp)
  
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
  samp = list(
    id = ict_sample$firm_id, 
    w_sample = ict_sample$w_sample,
    response_prob_est = ict_sample$w_sample / ict_sample$w_nrc,
    strata = ict_sample$strata
  )
  
)

# Test of the variance function
y <- matrix(ict_survey$speed_quanti, dimnames = list(ict_survey$firm_id))
with(technical_data_ict, variance_function_ict(y, samp = samp, x = x, w = w))

# Step 2 : Definition of a variance wrapper

variance_wrapper_ict <- define_variance_wrapper(
  variance_function = variance_function_ict,
  reference_id = ict_survey$firm_id, 
  reference_weight = ict_survey$w_calib, 
  default_id = "firm_id",
  technical_data = technical_data_ict
)

total3 <- define_statistic_wrapper(
  statistic_function = function(y, w){
    na <- is.na(y)
    y[na] <- 0
    point <- sum(y * w)
    list(point = point, lin = list(y, y), metadata = list(n = sum(!na)))
  }, 
  arg_type = list(data = "y" , weight = "w")
)


ict_survey <- ict_survey[sample.int(NROW(ict_survey)), ]

variance_wrapper_ict(ict_survey, 
                     total(speed_quanti, where = division == "59"), 
                     total3(speed_quanti, where = division == "60")
)

var <- c("speed_quanti", "speed_quali")
variance_wrapper_ict(
  ict_survey, 
  "blabla" = mean(speed_quanti), 
  "blibli" = mean(speed_quali)
  # not functional yet: "bloblo" = lapply(var, total)
)

speed_quanti2 <- ict_survey$speed_quanti
variance_wrapper_ict(ict_survey, speed_quanti2)






variance_wrapper_ict(ict_survey, speed_quanti, by = "division")
variance_wrapper_ict(ict_survey, speed_quanti, by = division)


num <- c("turnover", "employees")
denom <- c("employees", "turnover")
variance_wrapper_ict(ict_survey, ratio(num, denom), by = division)


variance_wrapper_ict(ict_survey, total(speed_quanti))
variance_wrapper_ict(ict_survey, mean(speed_quanti))

var <- c("speed_quanti", "speed_quali")
variance_wrapper_ict(ict_survey, mean(var))




variance_wrapper_ict <- define_simple_wrapper(
  data = ict_sample, id = "firm_id",
  samp_weight = "w_sample", strata = "strata",
  nrc_weight = "w_nrc", resp = "resp",
  calib_weight = "w_calib", calib_var =  c("division", "turnover_58", "turnover_59")
)

qvar(ict_sample, mean(turnover),
        id = "firm_id", samp_weight = "w_sample", strata = "division",
        nrc_weight = "w_nrc", resp_dummy = "resp",
        calib_weight = "w_calib", calib_var =  c("division", "turnover_58", "turnover_59")
)

qvar_ict <- qvar(ict_sample, define = TRUE,
                       id = "firm_id", samp_weight = "w_sample", strata = "division",
                       nrc_weight = "w_nrc", resp_dummy = "resp",
                       calib_weight = "w_calib", calib_var =  c("division", "turnover_58", "turnover_59")
)

qvar_ict(ict_survey, mean(turnover))
qvar_ict(ict_survey)


