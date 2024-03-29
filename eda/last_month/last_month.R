
transform_last_month <- function(a_data, a_data_lm) {
  print(" >> Loading current output data...")
  print(" >> Selecting relevant columns...")
  a_data <- select(
    a_data, c(
      "a_iso",
      "a_status_who",
      "adm_status_intro",
      "adm_tot_a1d_homo",
      "adm_tot_cps_homo",
      "adm_tot_boost_homo",
      "adm_tot_td",
      "cov_total_fv",
      "cov_total_a1d",
      "adm_fv_hcw_repstat",
      "adm_fv_hcw_adjust",
      "cov_hcw_fv",
      "adm_a1d_hcw_homo",
      "adm_fv_60p_repstat",
      "adm_fv_60p_homo",
      "cov_60p_fv",
      "adm_a1d_60p_homo",
      "a_pop_hcw",
      "a_pop_60p",
      "a_pop_older",
      "a_pop",
      "dvr_4wk_td_per",
      "fund_percapita",
      "del_cour_total_per",
      "adm_fv_hcw_homo",
      "t10_status",
      "t40_status",
      "t70_status",
      "adm_status_boost",
      "adm_tot_cps",
      "adm_cps_hcw",
      "adm_cps_60p"
    )
  )
  
  print(" >> Loading last month output data...")
  print(" >> Selecting relevant columns...")
  a_data_lm <- select(
    a_data_lm,
    c(
      "a_iso",
      "a_status_who",
      "adm_status_intro",
      "adm_a1d_homo",
      "adm_fv_homo",
      "adm_booster",
      "adm_td",
      "cov_total_fv",
      "cov_total_a1d",
      "adm_fv_hcw_repstat",
      "adm_fv_hcw_adjust",
      "cov_hcw_fv",
      "adm_a1d_hcw_homo",
      "adm_fv_60p_repstat",
      "adm_fv_60p_homo",
      "cov_60p_fv",
      "adm_a1d_60p_homo",
      "a_pop_hcw",
      "a_pop_60p",
      "a_pop_older",
      "a_pop",
      "dvr_4wk_td_per",
      "fund_percapita",
      "del_cour_total_per",
      "adm_fv_hcw_homo",
      "t10_status",
      "t40_status",
      "t70_status",
      "adm_status_boost",
      "adm_fv",
      "adm_fv_hcw",
      "adm_fv_60p"
    )
  )
  
  print(" >> Renaming columns...")
  colnames(a_data_lm) <- c(
    "a_iso",
    "a_status_who_lm",
    "adm_status_intro_lm",
    "adm_a1d_homo_lm",
    "adm_tot_cps_homo_lm",
    "adm_tot_boost_homo_lm",
    "adm_tot_td_lm",
    "cov_total_fv_lm",
    "cov_total_a1d_lm",
    "adm_fv_hcw_repstat_lm",
    "adm_fv_hcw_adjust_lm",
    "cov_hcw_fv_lm",
    "adm_a1d_hcw_homo_lm",
    "adm_fv_60p_repstat_lm",
    "adm_fv_60p_homo_lm",
    "cov_60p_fv_lm",
    "adm_a1d_60p_homo_lm",
    "a_pop_hcw_lm",
    "a_pop_60p_lm",
    "a_pop_older_lm",
    "a_pop_lm",
    "dvr_4wk_td_per_lm",
    "fund_percapita_lm",
    "del_cour_total_per_lm",
    "adm_fv_hcw_homo_lm",
    "t10_status_lm",
    "t40_status_lm",
    "t70_status_lm",
    "adm_status_boost_lm",
    "adm_tot_cps_lm",
    "adm_cps_hcw_lm",
    "adm_cps_60p_lm"
  )
  
  print(" >> Joining last month output data with current output data...")
  a_data_lm_change <- left_join(a_data, a_data_lm, by = c("a_iso" = "a_iso"))
  
  print(" >> Function 'transform_last_month' done")
  return(a_data_lm_change)
}
