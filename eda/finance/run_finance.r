run_financing <- function(a_data) {
  source("eda/finance/finance_consolidate.r")
  
  print(" > Starting local environment for financing summary")
  print(" > Calculating financing overview...")
  a_data <- financing_overview(a_data)
  print(" > Done.")
  
  print(" > Filtering AMC covax status...")
  a_data_amc <- amc_covax_status(a_data)
  print(" > Done.")
  
  print(" > Filtering HIC income group...")
  a_data_hic <- hic_income_group(a_data)
  print(" > Done.")
  
  print(" > Filtering CoVDP csc status...")
  a_data_csc <- covdp_csc_status(a_data)
  print(" > Done.")
  
  print(" > Filtering African continent...")
  a_data_africa <- africa_continent(a_data)
  print(" > Done.")

  return(environment())
}
