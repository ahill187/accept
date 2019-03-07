gamma	               <- 0.9694
b0                   <-	0.05689
b_male               <-	-0.08636
b_age10	             <- -0.02341
b_smoker             <-	-0.2002
b_oxygen             <-	0.03565
b_fev1               <-	-0.206
b_sgrq10             <-	0.1056
b_cardiovascular     <-	0.1135
b_azithromycin       <-	-0.1637
b_LAMA               <-	0.1546
b_LABA               <-	0.09876
b_ICS                <-	0.1486
b_BMI10              <-	-0.1107


c0                  <-   -3.4448
c_male              <- 0.5553
c_age10             <- 0.06462
c_smoker            <- 0.4077
c_oxygen            <- 0.5163
c_fev1              <- -0.5279
c_sgrq10            <- 0.2058
c_cardiovascular    <- 0.3316
c_azithromycin      <- -0.08741
c_LAMA              <- -0.2168
c_LABA              <- -0.03896
c_ICS               <- 0.1933
c_BMI10             <- -0.09053

v1  <-  0.6162
v2  <- 2.4016
cov <- 0.1558

covMat <- matrix(
  c(v1, cov, cov, v2),
  nrow = 2,
  ncol = 2
)

#' Initializes a model. Allocates memory to the C engine.
#' @param patientData patient data matrix. Can have one or many patients in it
#' @param random_sampling_N number of random sampling. Default is 1000.
#' @return patientData with prediction
#' @export
predictACCEPT <- function (patientData, random_sampling_N = 1000){

  predicted_exac_rate <- matrix(0, random_sampling_N, nrow(patientData))
  predicted_exac_count <- matrix(0, random_sampling_N, nrow(patientData))
  predicted_severe_exac_count <- matrix(0, random_sampling_N, nrow(patientData))


  predicted_exac_probability <- matrix(0, random_sampling_N, nrow(patientData))
  predicted_severe_exac_probability <- matrix(0, random_sampling_N, nrow(patientData))

  conditionalZ <- densityLastYrExac(patientData)

  for (i in 1:(nrow(patientData)))

  {
    log_alpha <-   b0 +
      b_male * patientData[i, "male"] +
      b_age10 * patientData[i, "age10"] +
      b_smoker * patientData[i, "smoker"] +
      b_oxygen * patientData[i, "oxygen"] +
      b_fev1 * patientData[i, "FEV1"] +
      b_sgrq10 * patientData[i, "sgrq10"] +
      b_cardiovascular * patientData[i, "statin"] +
      b_azithromycin * patientData[i, "azithromycin"] +
      b_LAMA * patientData[i, "LAMA"] +
      b_LABA * patientData[i, "LABA"] +
      b_ICS * patientData[i, "ICS"] +
      b_BMI10 * patientData[i, "BMI10"]

    ID <- as.character(patientData[i, "ID"])
    z <- sample_n(conditionalZ[[ID]], random_sampling_N, replace = TRUE, weight = weight)


    alpha <- exp (as.numeric(log_alpha) + z[, "z1"])
    lambda <- alpha ^ gamma
    predicted_exac_rate[, i] <- lambda
    predicted_exac_probability[, i] <- 1 - exp(-lambda)
    predicted_exac_count[, i] <-  as.numeric(lapply(lambda, rpois, n=1))


    patientData [i, "predicted_exac_probability"] <- mean(predicted_exac_probability[,i])
    patientData [i, "predicted_exac_rate"] <- mean(predicted_exac_rate[,i])

    # patientData [i, "predicted_exac_count"] <- mean(predicted_exac_count[,i])
    # patientData [i, "predicted_exac_count_low"]  <- quantile(predicted_exac_count[,i], 0.025)
    # patientData [i, "predicted_exac_count_high"] <- quantile(predicted_exac_count[, i], 0.975)


    #severity
    c_lin <-   c0 +
      c_male * patientData[i, "male"] +
      c_age10 * patientData[i, "age10"] +
      c_smoker * patientData[i, "smoker"] +
      c_oxygen * patientData[i, "oxygen"] +
      c_fev1 * patientData[i, "FEV1"] +
      c_sgrq10 * patientData[i, "sgrq10"] +
      c_cardiovascular * patientData[i, "statin"] +
      c_azithromycin * patientData[i, "azithromycin"] +
      c_LAMA * patientData[i, "LAMA"] +
      c_LABA * patientData[i, "LABA"] +
      c_ICS * patientData[i, "ICS"] +
      c_BMI10 * patientData[i, "BMI10"]

    OR <- exp (as.numeric(c_lin) + z[, "z2"])
    predicted_severe_exac_probability[, i] <- (OR/(1+OR))
    patientData [i, "predicted_severe_exac_probability"] <- mean(predicted_severe_exac_probability[,i])
    patientData [i, "predicted_severe_exac_rate"] <- patientData [i, "predicted_exac_rate"] * patientData [i, "predicted_severe_exac_probability"]

    # predicted_severe_exac_count[, i] <-  as.numeric(lapply(patientData [i, "predicted_severe_exac_rate"], rpois, n=1))
    # patientData [i, "predicted_severe_exac_count"] <- mean(predicted_severe_exac_count[,i])
    # patientData [i, "predicted_severe_exac_count_low"]  <- quantile(predicted_severe_exac_count[,i], 0.025)
    # patientData [i, "predicted_severe_exac_count_high"] <- quantile(predicted_severe_exac_count[, i], 0.975)

  }

  return(patientData)

}
