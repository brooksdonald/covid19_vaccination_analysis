
extract_vxrate_details <- function(c_vxrate_latest) {
  print(" >> Remove duplicative base details from latest vxrate summary...")
  c_vxrate_latest_red <-
    select(
      c_vxrate_latest, -c(
        "a_continent",
        "a_region_who",
        "a_income_group",
        "a_status_covax",
        "a_region_unicef",
        "a_name_short",
        "a_name_long",
        "a_region_sub_who",
        "a_status_who",
        "a_status_csc",
        "a_status_ivb",
        "a_status_gavi",
        "a_continent_sub",
        "pol_jj",
        "pol_old",
        "pol_old_source",
        "a_pop",
        "a_income_group_vis",
        "ss_target",
        "ss_deadline",
        "country_source",
        "date_13jan.x",
        "adm_tar_hcw_wpro",
        "a_pop_hcw",
        "a_pop",
        "pol_boost",
        "ri_dtp1",
        "ri_dtp3",
        "ri_mcv1",
        "ri_mcv2",
        "ri_zero_dose",
        "a_pop_comorb_increased_prop",
        "a_pop_comorb_high_prop",
        "a_pop_comorb_high_young_prop",
        "a_pop_comorb_high_older_prop",
        "min_vx_rollout_date",
        "a_income_group_ind"
      )
    )

    return(c_vxrate_latest_red)
}

merge_dataframes <- function(
  entity_characteristics,
  c_vxrate_latest_red,
  population,
  uptake_gender_data,
  who_dashboard,
  sup_rec,
  b_dp,
  sup_rec_jj,
  fin_del_sum,
  population_pin
  ) {
    # Renaming iso columns to a_iso before merge
    df_list <- list(
      entity_characteristics,
      c_vxrate_latest_red,
      population,
      uptake_gender_data,
      who_dashboard,
      sup_rec,
      b_dp,
      sup_rec_jj,
      fin_del_sum,
      population_pin
    )
    # Merge details
    a_data <- helper_join_dataframe_list(
      df_list,
      join_by = "a_iso"
    )
  return(as.data.frame(a_data))
}

transform_vxrate_merge <- function(a_data, date_refresh) {
  # Set static dates
  print(" >>> Setting static dates")
  a_data$a_date_refresh <- date_refresh

  a_data <- a_data %>%
    mutate(
      adm_target_hcw = ifelse(
        is.na(adm_tar_hcw_wpro),
        adm_target_hcw,
        adm_tar_hcw_wpro
      ))
  
  
  #Calculate JJ proportion
  print(" >>> Computing JJ doses KPIs")
  a_data <- a_data %>%
      mutate(del_dose_minjj = del_dose_total  - del_dose_jj) %>% 
      mutate(del_dose_jj_prop = if_else(
        is.na(del_dose_jj),
        0,
        del_dose_jj / del_dose_total))

  # Calculate introduction status
  print(" >>> Computing introduction status...")
  a_data <- a_data %>%
    mutate(adm_status_intro = if_else(
      is.na(adm_tot_td) | adm_tot_td == 0,
      "No product introduced",
      "Product introduced"
    )
  )

  # Assign population size category
  breaks <- c(0, 1000000, 10000000, 100000000,
    max(a_data$a_pop, na.rm = TRUE) + 1)
  tags <- c("1) <1M", "2) 1-10M", "3) 10-100M", "4) 100M+")
  a_data$a_pop_cat <- cut(
    a_data$a_pop,
    breaks = breaks,
    include.lowest = TRUE,
    right = FALSE,
    labels = tags
  )

  print(">>> Calculating total population percentages and proportions...")
  a_data <- a_data %>%
    mutate(a_pop_10 = a_pop * 0.1,
           a_pop_20 = a_pop * 0.2,
           a_pop_40 = a_pop * 0.4,
           a_pop_70 = a_pop * 0.7,
           a_pop_18p_prop = a_pop_18p / a_pop_2021,
           a_pop_18u_prop = a_pop_18u / a_pop_2021,
           a_pop_hcw_prop = a_pop_hcw / a_pop_2021,
           a_pop_60p_prop = a_pop_60p / a_pop_2021,
           a_pop_12p_prop = a_pop_12p / a_pop_2021,
           a_pop_12u_prop = a_pop_12u / a_pop_2021)
  
  print(">>> Assinging older adult population based on policy...")
  a_data <- a_data %>%
    mutate(
      a_pop_old = case_when(
        pol_old == "45 and older" ~ a_pop_45p,
        pol_old == "50 and older" ~ a_pop_50p,
        pol_old == "55 and older" ~ a_pop_55p,
        pol_old == "60 and older" ~ a_pop_60p,
        pol_old == "65 and older" ~ a_pop_65p,
        pol_old == "70 and older" ~ a_pop_70p,
        pol_old == "75 and older" ~ a_pop_75p,
        TRUE ~ a_pop_60p
      )
    )

  # Calculate theoretical fully vaccinated for non-reporters for current, lm, and 2m
  print(" >>> Computing theoretically fully vaxxed for non reporters...")
  a_data <- a_data %>%
  mutate(adm_tot_cps_homo = if_else(
    adm_tot_a1d == 0 & adm_tot_cps == 0 & adm_tot_boost == 0,
    adm_tot_td / 2,
      if_else(
        adm_tot_a1d == 0 & adm_tot_cps == 0 & adm_tot_boost != 0,
        (adm_tot_td - adm_tot_boost)/ 2,
        if_else(
          adm_tot_a1d != 0 & adm_tot_cps == 0 & adm_tot_boost == 0,
          adm_tot_td - adm_tot_a1d,
          if_else(
            adm_tot_a1d != 0 & adm_tot_cps == 0 & adm_tot_boost != 0,
            adm_tot_td - adm_tot_a1d - adm_tot_boost,
            adm_tot_cps))))) %>%
  mutate(adm_tot_cps_lm_homo = if_else(
    adm_tot_a1d_lm == 0 & adm_tot_cps_lm == 0 & adm_tot_boost_lm == 0,
    adm_tot_td_lm / 2,
    if_else(
      adm_tot_a1d_lm == 0 & adm_tot_cps_lm == 0 & adm_tot_boost_lm != 0,
      (adm_tot_td_lm - adm_tot_boost_lm)/ 2,
      if_else(
        adm_tot_a1d_lm != 0 & adm_tot_cps_lm == 0 & adm_tot_boost_lm == 0,
        adm_tot_td_lm - adm_tot_a1d_lm,
        if_else(
          adm_tot_a1d_lm != 0 & adm_tot_cps_lm == 0 & adm_tot_boost_lm != 0,
          adm_tot_td_lm - adm_tot_a1d_lm - adm_tot_boost_lm,
          adm_tot_cps_lm))))) %>%
  mutate(adm_tot_cps_2m_homo = if_else(
    adm_tot_a1d_2m == 0 & adm_tot_cps_2m == 0,
    adm_tot_td_2m / 2,
    if_else(
      adm_tot_a1d_2m != 0 & adm_tot_cps_2m == 0,
      adm_tot_td_2m - adm_tot_a1d_2m,
      adm_tot_cps_2m))) %>%
  mutate(adm_tot_cps_13jan_homo = if_else(
      adm_tot_a1d_13jan == 0 & adm_tot_cps_13jan == 0 & adm_tot_boost_13jan == 0,
      adm_tot_td_13jan / 2,
      if_else(
        adm_tot_a1d_13jan == 0 & adm_tot_cps_13jan == 0 & adm_tot_boost_13jan != 0,
        (adm_tot_td_13jan - adm_tot_boost_13jan)/ 2,
        if_else(
          adm_tot_a1d_13jan != 0 & adm_tot_cps_13jan == 0 & adm_tot_boost_13jan == 0,
          adm_tot_td_13jan - adm_tot_a1d_13jan,
          if_else(
            adm_tot_a1d_13jan != 0 & adm_tot_cps_13jan == 0 & adm_tot_boost_13jan != 0,
            adm_tot_td_13jan - adm_tot_a1d_13jan - adm_tot_boost_13jan,
            adm_tot_cps_13jan))))) %>%
  mutate(adm_tot_a1d_homo = if_else(
    adm_tot_a1d == 0 & adm_tot_cps == 0, adm_tot_td / 2,
    if_else(adm_tot_a1d < adm_tot_cps_homo, adm_tot_cps_homo,
            adm_tot_a1d))) %>%
  mutate(adm_tot_td_per = adm_tot_td / a_pop) %>%
  mutate(adm_pv = pmax(0, adm_tot_a1d_homo - adm_tot_cps_homo)) %>%
  mutate(adm_tot_boost_homo = pmin(adm_tot_boost, adm_tot_cps_homo, a_pop))
  
  # Calculate td and fv change from lm and 2m
  print(" >>> Computing td and fv change from lm and 2m...")
  a_data <- a_data %>%
    mutate(adm_tot_td_less_1m = adm_tot_td - adm_tot_td_lm) %>%
    mutate(adm_tot_td_1m_2m = adm_tot_td_lm - adm_tot_td_2m) %>%
    mutate(adm_tot_td_1m_13jan = adm_tot_td_lm - adm_tot_td_13jan) %>%
    mutate(adm_tot_cps_less_1m = adm_tot_cps_homo - adm_tot_cps_lm_homo) %>%
    mutate(adm_tot_cps_1m_2m = adm_tot_cps_lm_homo - adm_tot_cps_2m_homo)

  # Calculate adm_tot_a1d and adm_tot_cps coverage for current, lm, and 2m, including change
  print(" >>> Computing adm_tot_a1d and adm_tot_cps coverage...")
  a_data <- a_data %>%
    mutate(cov_total_a1d = adm_tot_a1d / a_pop) %>%
    mutate(cov_total_a1d_adjust = if_else(
      adm_tot_a1d <= adm_tot_cps,
      NA_real_,
      adm_tot_a1d / a_pop)) %>%
    mutate(cov_total_a1d_13jan = adm_tot_a1d_13jan / a_pop) %>%
    mutate(cov_total_fv = pmin(1, adm_tot_cps_homo / a_pop)) %>%
    mutate(cov_total_fv_theo = (adm_tot_td / 2) / a_pop) %>%
    mutate(cov_total_fv_lw = adm_tot_cps_lw / a_pop) %>%
    mutate(cov_total_fv_13jan = adm_tot_cps_13jan_homo / a_pop) %>%
    mutate(cov_total_fv_lm = pmin(1, adm_tot_cps_lm_homo / a_pop)) %>%
    mutate(cov_total_fv_2m = pmin(1, adm_tot_cps_2m_homo / a_pop)) %>%
    mutate(cov_total_fv_less_1m = pmax(0, cov_total_fv - cov_total_fv_lm))  %>%
    mutate(cov_total_fv_1m_2m = pmax(0, cov_total_fv_lm - cov_total_fv_2m)) %>%
    mutate(cov_total_fv_cur_13jan = pmax(0, cov_total_fv - cov_total_fv_13jan)) %>%
    mutate(cov_total_fv_less_1m_prop = cov_total_fv_less_1m / cov_total_fv) %>%
    mutate(cov_total_fv_1m_13jan = pmax(cov_total_fv_lm - cov_total_fv_13jan, 0))
  
  # Correct GRL and SJM
  a_data$cov_total_fv[a_data$a_iso == "GRL"] <-
    a_data$cov_total_fv[a_data$a_iso == "DNK"]
  
  a_data$cov_total_fv[a_data$a_iso == "SJM"] <-
    a_data$cov_total_fv[a_data$a_iso == "NOR"]


  # Assign coverage category for current and lw
  print(" >>> Assigning coverage category for current and lw...")
  breaks <- c(0, 0.1, 0.2, 0.4, 0.7, Inf)
  tags <- c("1) 0-10%", "2) 10-20%",
    "3) 20-40%", "4) 40-70%", "5) 70%+")
  a_data$cov_total_fv_cat <- cut(
    a_data$cov_total_fv,
    breaks = breaks,
    include.lowest = TRUE,
    right = FALSE,
    labels = tags
  )

  breaks <- c(0, 0.1, 0.2, 0.4, 0.7, Inf)
  tags <- c("1) 0-10%", "2) 10-20%",
    "3) 20-40%", "4) 40-70%", "5) 70%+")
  a_data$cov_total_fv_lw_cat <- cut(
    a_data$cov_total_fv_lw,
    breaks = breaks,
    include.lowest = TRUE,
    right = FALSE,
    labels = tags
  )

  # # Calculate linear population coverage projection by 30 June 2022
  # print(" >>> Computing linear population coverage projection by 30 June 2022...")
  # a_data <- a_data %>%
  #   mutate(cov_total_fv_atpace_31dec = pmin(
  #     1,
  #     (adm_tot_cps_homo + (dvr_4wk_fv * timeto_t70)) / a_pop))


  # Indicator reporting status for target group-specific uptake data
  print(" >>> Indicator reporting status for target group-specific uptake data...")
  a_data <- a_data %>%
    mutate(adm_fv_hcw_repstat = if_else(
      is.na(adm_cps_hcw),
      "Not reporting",
      if_else(
        adm_cps_hcw > 0,
        "Reporting",
        "Not reporting"))) %>%
    mutate(adm_fv_60p_repstat = if_else(
      is.na(adm_cps_60p),
      "Not reporting",
      if_else(
        adm_cps_60p > 0,
        "Reporting",
        "Not reporting"))) %>%
    mutate(adm_fv_gen_repstat = if_else(
      is.na(adm_cps_female) | is.na(adm_cps_male),
      "Not reporting",
      if_else(
        adm_cps_female > 0,
        "Reporting",
        "Not reporting")))

  # Converting Ingested data from API to numeric values
  a_data$adm_cps_male <- as.numeric(a_data$adm_cps_male)
  a_data$adm_cps_female <- as.numeric(a_data$adm_cps_female)
  a_data$adm_a1d_hcw <- as.numeric(a_data$adm_a1d_hcw)
  a_data$adm_cps_hcw <- as.numeric(a_data$adm_cps_hcw)
  
  a_data$adm_fv_hcw_repstat[a_data$a_iso == "GRL"] <-
    a_data$adm_fv_hcw_repstat[a_data$a_iso == "DNK"]
  a_data$adm_fv_hcw_repstat[a_data$a_iso == "SJM"] <-
    a_data$adm_fv_hcw_repstat[a_data$a_iso == "NOR"]
  
  a_data$adm_fv_60p_repstat[a_data$a_iso == "GRL"] <-
    a_data$adm_fv_60p_repstat[a_data$a_iso == "DNK"]
  a_data$adm_fv_60p_repstat[a_data$a_iso == "SJM"] <-
    a_data$adm_fv_60p_repstat[a_data$a_iso == "NOR"]
  
  a_data$adm_fv_gen_repstat[a_data$a_iso == "GRL"] <-
    a_data$adm_fv_gen_repstat[a_data$a_iso == "DNK"]
  a_data$adm_fv_gen_repstat[a_data$a_iso == "SJM"] <-
    a_data$adm_fv_gen_repstat[a_data$a_iso == "NOR"]
  
  # Healthcare worker
  a_data <- a_data %>%
    mutate(hcw_flag = if_else(
      a_pop_hcw > adm_target_hcw,
      "Yes",
      NA_character_)) %>%
    mutate(hcw_diff = pmax(a_pop_hcw - adm_target_hcw, 0, na.rm = TRUE))

  # Calculate target group coverage figures
  print(" >>> Computing target group coverage figures...")
  a_data$adm_cps_male <- as.double(a_data$adm_cps_male)
  a_data <- a_data %>%
    mutate(adm_fv_male_homo = pmin(
      adm_cps_male,
      a_pop_male)) %>%
    mutate(cov_total_male_fv = adm_cps_male / a_pop_male) %>%
    mutate(adm_fv_fem_homo = pmin(
      adm_cps_female,
      a_pop_female)) %>%
    mutate(cov_total_fem_fv = adm_cps_female / a_pop_female) %>%
    mutate(adm_fv_gen = adm_fv_male_homo + adm_fv_fem_homo) %>%
    mutate(adm_booster_fem_homo = pmin(a_pop_female, adm_boost_female)) %>%
    mutate(adm_booster_male_homo = pmin(a_pop_male, adm_boost_male)) %>%
    mutate(cov_total_booster_fem = adm_booster_fem_homo / a_pop_female) %>%
    mutate(cov_total_booster_male = adm_booster_male_homo / a_pop_male) %>%
    mutate(adm_booster_gen_status = if_else(
      is.na(adm_cps_male) | is.na(adm_cps_female) | adm_cps_male == 0 | adm_cps_female == 0,
      "Not reporting on gender-disaggregated uptake",
      if_else(
        is.na(cov_total_booster_fem) & (is.na(adm_cps_female) == FALSE | is.na(adm_cps_male) == FALSE),
        "Reporting on gender-disaggregated uptake, but not boosters",
        if_else(
          adm_boost_female > 0,
          "Reporting on gender-disaggregated boosters",
          "Reporting on gender-disaggregated uptake, but not boosters"))))

  # Calculate healthcare workers coverage
  a_data <- a_data %>%
    mutate(adm_fv_hcw_homo = pmin(
      adm_cps_hcw,
      a_pop_hcw)) %>%
    mutate(adm_fv_hcw_adjust =
      pmin(adm_cps_hcw + (hcw_diff * cov_total_fv), a_pop_hcw)) %>%
    mutate(adm_a1d_hcw_homo = if_else(
      pmin(adm_a1d_hcw, a_pop_hcw) < adm_fv_hcw_adjust, 
      adm_fv_hcw_adjust,
      pmin(adm_a1d_hcw, a_pop_hcw))) %>%
    mutate(adm_booster_hcw_homo = pmin(
      a_pop_hcw,
      adm_boost_hcw,
      adm_fv_hcw_adjust)) %>%
    mutate(cov_hcw_a1d = if_else(
      is.na(hcw_flag),
      pmin(adm_a1d_hcw_homo / a_pop_hcw, 1),
      pmin((adm_a1d_hcw_homo + (hcw_diff * cov_total_a1d)) / a_pop_hcw, 1)
    )) %>%
    mutate(cov_hcw_a1d_adjust = if_else(
      adm_a1d_hcw <= adm_cps_hcw,
      NA_real_,
      cov_hcw_a1d)) %>%
    mutate(cov_hcw_fv =
      pmin(
        adm_fv_hcw_adjust/ a_pop_hcw,
        1
      )
    ) %>%
    mutate(cov_hcw_booster =
      pmin(
        1,
        adm_booster_hcw_homo / a_pop_hcw)) %>%
    mutate(adm_booster_hcw_status = if_else(
      is.na(adm_cps_hcw) | adm_cps_hcw== 0,
      "3) Not reporting on HCW uptake",
      if_else(
        is.na(cov_hcw_booster) & is.na(adm_cps_hcw) == FALSE,
        "2) Reporting on HCW uptake, but not boosters",
        if_else(
          adm_boost_hcw> 0,
          "1) Reporting on HCW boosters",
          "2) Reporting on HCW uptake, but not boosters")))) %>%
    mutate(cov_hcw_booster_cat = if_else(
      is.na(adm_cps_hcw) | adm_cps_hcw== 0,
      "0) Not reporting on HCW uptake",
      if_else(
        is.na(cov_hcw_booster) & is.na(adm_cps_hcw) == FALSE,
        "1) Not reporting on HCW boosters",
        if_else(
          cov_hcw_booster > .5,
          "5) >50%",
          if_else(
            cov_hcw_booster > .25,
            "4) 25-49.9%",
            if_else(
              cov_hcw_booster > .1,
              "3) 10-24.9%",
              if_else(
                cov_hcw_booster > 0,
                "2) 0-9.9%",
                if_else(
                  cov_hcw_booster == 0,
                  "1) Not reporting on HCW boosters",
                  NA_character_)))))))) %>%
    
    mutate(cov_hcw_a1d_fv = if_else(cov_hcw_fv == 0 | is.na(cov_hcw_fv),
                                    cov_hcw_a1d,
                                    cov_hcw_a1d - cov_hcw_fv),
           cov_hcw_fv_booster = if_else(cov_hcw_booster == 0 | is.na(cov_hcw_booster),
                                        cov_hcw_fv,
                                        cov_hcw_fv - cov_hcw_booster))

  # Calculating older adults coverage groups
  a_data <- a_data %>%
    mutate(adm_fv_60p_homo = pmin(a_pop_old, adm_cps_60p),
           adm_a1d_60p_homo = if_else(pmin(a_pop_old, adm_a1d_60p) < adm_fv_60p_homo,
                                      adm_fv_60p_homo,
                                      pmin(a_pop_old, adm_a1d_60p)),
           adm_booster_60p_homo = pmin(adm_boost_60p, a_pop_old)) %>%
    mutate(cov_60p_a1d = pmin(
      adm_a1d_60p_homo / a_pop_old, 1)) %>%
    mutate(cov_60p_a1d_adjust = if_else(
      adm_a1d_60p <= adm_cps_60p,
      NA_real_,
      cov_60p_a1d)) %>%
    mutate(cov_60p_fv = pmin(
      adm_fv_60p_homo / a_pop_old, 1)) %>%
    mutate(cov_60p_booster = pmin(
      1, adm_booster_60p_homo / a_pop_old)) %>%
    mutate(adm_booster_60p_status = if_else(
      is.na(adm_cps_60p) | adm_cps_60p == 0,
      "3) Not reporting on 60+ uptake",
      if_else(is.na(cov_60p_booster) & is.na(adm_cps_60p) == FALSE, 
        "2) Reporting on 60+ uptake, but not boosters",
        if_else(
          adm_boost_60p> 0,
          "1) Reporting on 60+ boosters",
          "2) Reporting on 60+ uptake, but not boosters")))) %>%
    mutate(cov_60p_booster_cat = if_else(
      is.na(adm_cps_60p) | adm_cps_60p == 0,
      "0) Not reporting on older adult uptake",
      if_else(
        is.na(cov_60p_booster) & is.na(adm_cps_60p) == FALSE,
        "1) Not reporting on older adult boosters",
        # TODO add cut() function here
        if_else(
          cov_60p_booster > .5,
          "5) >50%",
          if_else(
            cov_60p_booster > .25,
            "4) 25-49.9%",
            if_else(
              cov_60p_booster > .1,
              "3) 10-24.9%",
              if_else(
                cov_60p_booster > 0,
                "2) 0-9.9%",
                if_else(
                  cov_60p_booster == 0,
                  "1) Not reporting on older adult boosters",
                  NA_character_)))))))) %>%
    
    mutate(cov_60p_a1d_fv = if_else(cov_60p_fv == 0 | is.na(cov_60p_fv),
                                    cov_60p_a1d,
                                    cov_60p_a1d - cov_60p_fv),
           cov_60p_fv_booster = if_else(cov_60p_booster == 0 | is.na(cov_60p_booster),
                                        cov_60p_fv,
                                        cov_60p_fv - cov_60p_booster))

  a_data$cov_hcw_fv[a_data$a_iso == "GRL"] <-
    a_data$cov_hcw_fv[a_data$a_iso == "DNK"]
  a_data$cov_hcw_fv[a_data$a_iso == "SJM"] <-
    a_data$cov_hcw_fv[a_data$a_iso == "NOR"]

  a_data$cov_60p_fv[a_data$a_iso == "GRL"] <-
    a_data$cov_60p_fv[a_data$a_iso == "DNK"]
  a_data$cov_60p_fv[a_data$a_iso == "SJM"] <-
    a_data$cov_60p_fv[a_data$a_iso == "NOR"]

  # Calculate gender coverage difference in reporting countries
  print(" >>> Computing gender coverage difference in reporting countries...")
  a_data <- a_data %>%
    mutate(cov_total_gen_diff = cov_total_fem_fv - cov_total_male_fv)
  
  # Coverage categories in target groups

  a_data$cov_hcw_fv_cat <- cut(
    a_data$cov_hcw_fv,
    breaks = c(-Inf, 0.1, 0.2, 0.4, 0.7, Inf),
    labels = c("1) 0-10%", "2) 10-20%", "3) 20-40%", "4) 40-70%", "5) 70%+"),
    include.lowest = TRUE,
    right = FALSE
  )

  a_data$cov_60p_fv_cat <- cut(
    a_data$cov_60p_fv,
    breaks = c(-Inf, 0.1, 0.2, 0.4, 0.7, Inf),
    labels = c("1) 0-10%", "2) 10-20%", "3) 20-40%", "4) 40-70%", "5) 70%+"),
    include.lowest = TRUE,
    right = FALSE
  )

  # Calculate 4-week average daily rates as % of pop.
  print(" >>> Computing 4-week average daily rates as % of pop...")
  a_data <- a_data %>%
    mutate(dvr_4wk_fv = pmax(0, dvr_4wk_fv)) %>%
    mutate(dvr_4wk_td_per = dvr_4wk_td / a_pop) %>%
    mutate(dvr_4wk_fv_per = dvr_4wk_fv / a_pop) %>%
    mutate(dvr_4wk_td_max_per = dvr_4wk_td_max / a_pop)

  # Assign vaccination rate category
  print(" >>> Assigning vaccination rate category...")
  breaks <- c(0, 0.0015, 0.0035, 0.0065, 1)
  tags <- c("1) Low (< 0.15%*)", "2) Medium (< 0.35%)", "3) High (< 0.65%)", "4) Very high (> 0.65%)") #nolint 
  a_data$dvr_4wk_td_per_cat <- cut(
    a_data$dvr_4wk_td_per,
    breaks = breaks,
    include.lowest = TRUE,
    right = FALSE,
    labels = tags
  )

  # Calculate (percent) change in 4-week average daily vaccination rate & assign category
  print(" >>> Computing % change in 4-week average daily vxrate & assign category...")
  a_data <- a_data %>%
    mutate(dvr_4wk_td_change_lm = dvr_4wk_td - dvr_4wk_td_lm) %>%
    mutate(dvr_4wk_td_change_lm_per = if_else(
      is.infinite(dvr_4wk_td_change_lm / dvr_4wk_td_lm),
      1,
      dvr_4wk_td_change_lm / dvr_4wk_td_lm))

  breaks <- c(-Inf, -0.25, 0, 0.25, Inf)
  tags <- c("1) < (-25)%", "2) (-25)-0%", "3) 0-25%", "4) > 25%")
  a_data$dvr_4wk_td_change_lm_per_cat <- cut(
    a_data$dvr_4wk_td_change_lm_per,
    breaks = breaks,
    labels = tags,
    include.lowest = TRUE,
    right = TRUE
  )

  a_data <- a_data %>%
    mutate(dvr_4wk_td_change_lm_per_cat = replace_na(
      dvr_4wk_td_change_lm_per_cat,
      tags[2]
    ))

  # Calculate coverage difference between HCWs and total in reporting countries
  print(" >>> Computing coverage difference between HCWs and total in reporting countries...")
  a_data <- a_data %>%
    mutate(
      cov_total_hcw_diff = ifelse(
      adm_fv_hcw_repstat == "Reporting",
      cov_hcw_fv - cov_total_fv,
      NA
      ))
  
  # Calculate coverage difference between 60 plus and total in reporting countries
  print(" >>> Computing coverage difference between HCWs and total in reporting countries...")
  a_data <- a_data %>%
    mutate(
      cov_total_60p_diff = ifelse(
        adm_fv_60p_repstat == "Reporting",
        cov_60p_fv - cov_total_fv,
        NA
      ))
  
  # Categorize comparison of coverage between HCWs and total
  breaks <- c(-Inf, 0, Inf)
  tags <- c("AMC participants with complete primary series coverage of healthcare workers lesser than total", "AMC participants with complete primary series coverage of healthcare workers greater than total")
  a_data$cov_total_hcw_com <- cut(
    a_data$cov_total_hcw_diff,
    breaks = breaks,
    labels = tags,
    include.lowest = FALSE,
    right = TRUE
  )
  a_data$cov_total_hcw_com[a_data$adm_fv_hcw_repstat != "Reporting" ] <- NA  
  
  # Categorize comparison of coverage between 60 plus and total
  breaks <- c(-Inf, 0, Inf)
  tags <- c("AMC participants with complete primary series coverage of older adults lesser than total", "AMC participants with complete primary series coverage of older adults greater than total")
  a_data$cov_total_60p_com <- cut(
    a_data$cov_total_60p_diff,
    breaks = breaks,
    labels = tags,
    include.lowest = FALSE,
    right = TRUE
  )
  a_data$cov_total_60p_com[a_data$adm_fv_60p_repstat != "Reporting" ] <- NA  
  
  # Categorize comparison of coverage between HCWs and total for CSC countries
  a_data$cov_total_hcw_com_csc <- gsub("AMC participants", "CSC countries", a_data$cov_total_hcw_com)
  a_data$cov_total_hcw_com_csc[a_data$a_status_csc != "Concerted support country" ] <- NA  
  
  # Categorize comparison of coverage between 60 plus and total for CSC countries
  a_data$cov_total_60p_com_csc <- gsub("AMC participants", "CSC countries", a_data$cov_total_60p_com)
  a_data$cov_total_60p_com_csc[a_data$a_status_csc != "Concerted support country" ] <- NA  

  breaks <- c(-Inf, -0.25, 0.25, Inf)
  tags <- c("Downward", "Stable", "Upward")
  a_data$dvr_4wk_td_change_lm_trend <- cut(
    a_data$dvr_4wk_td_change_lm_per,
    breaks = breaks,
    labels = tags,
    include.lowest = FALSE,
    right = TRUE
  )

  a_data <- a_data %>%
    mutate(dvr_4wk_td_change_lm_trend = replace_na(
      dvr_4wk_td_change_lm_trend,
      tags[2]
    )) %>%
    mutate(adm_tot_td_adj  = adm_tot_td / a_pop)


  datalist <- list("a_data" = a_data)
  return(datalist)
}