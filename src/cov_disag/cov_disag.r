
load_population_uptake <- function(headers, refresh_api) {
    print(" >> Load target groups and gender...")
    uptake_gender <- load_pop_target_gender(headers, refresh_api)
    uptake_groups <- load_pop_target_groups(headers, refresh_api)
    datalist <- list("uptake_gender" = uptake_gender,
        "uptake_groups" = uptake_groups)
    return(datalist)
}

transform_population_uptake <- function(uptake_gender, uptake_groups) {
    print(" >> Transform target groups and gender...")
    uptake_genders <- transform_pop_target_gender(uptake_gender)
    uptake_groupss <- transform_pop_target_groups(uptake_groups)

    df_to_append <- append(uptake_groupss, uptake_genders)

    output <- helper_join_dataframe_list(
        df_to_append,
        join_by = "a_iso",
        ally = TRUE
    ) # full join

    output$adm_date_gender <- output$adm_date_gender.x
    output <- select(output, -c("adm_date_gender.y", "adm_date_gender.x"))

    return(output)
}

load_pop_target_gender <- function(headers, refresh_api) {
    print(">> Loading gender-disaggregated uptake data...")
    uptake_gender <- helper_wiise_api(
        "https://xmart-api-public.who.int/WIISE/V_COV_UPTAKE_GENDER_LAST_MONTH_LONG",
        headers = FALSE, refresh_api)

    print(">> Selecting & renaming relevant gender-dsaggregated uptake data...")
    uptake_gender <- uptake_gender %>%
        select(ISO_3_CODE,
               DATE,
               GENDER,
               N_VACC_DOSE1,
               N_VACC_LAST_DOSE,
               N_VACC_BOOSTER_DOSE
            ) %>%
      rename(
        "a_iso"= ISO_3_CODE,
        "date" = DATE,
        "gender" = GENDER,
        "adm_a1d" = N_VACC_DOSE1,
        "adm_cps" = N_VACC_LAST_DOSE,
        "adm_boost" = N_VACC_BOOSTER_DOSE
      )
    
    print(">>  Done.")
    return(uptake_gender)
}

load_pop_target_groups <- function(headers, refresh_api) {
    print(" >> Loading COV Uptake target group data...")
    uptake_target_group <- helper_wiise_api(
        "https://xmart-api-public.who.int/WIISE/V_COV_UPTAKE_TARGETGROUP_LAST_MONTH_LONG",
        headers = FALSE, refresh_api)
    # Reduce columns & rename
    print(" >> Reducing columns and renaming them...")
    uptake_target_group <-
        select(
            uptake_target_group,
            c(
                "ISO_3_CODE",
                "DATE",
                "TARGET_GROUP",
                "N_VACC_DOSE1",
                "N_VACC_LAST_DOSE",
                "N_VACC_BOOSTER_DOSE",
                "NUMBER_TARGET"
            )
        )

    print(" >> Renaming columns...")
    colnames(uptake_target_group) <- c(
        "a_iso",
        "date",
        "target_group",
        "adm_a1d",
        "adm_cps",
        "adm_boost",
        "adm_target"
    )

    print(" >> Removing duplicates...")
    uptake_target_group <- helper_check_for_duplicates(uptake_target_group)
    return(uptake_target_group)
}

transform_pop_target_gender <- function(uptake_gender) {
    print(" >>> Transforming gender df...")
    data_frames <- list()

    var_columns <- c("adm_a1d", "adm_cps", "adm_boost")
    for (g in c("MALE", "FEMALE")) {
        df <- uptake_gender %>%
            filter(
                gender == g
            )
        df <- df %>% select(-"gender")
        colnames(df) <- c(
            "a_iso", "adm_date_gender",
            helper_tr_add_suffix_to_list(var_columns, paste0("_", tolower(g)))
        )
        data_frames <- append(data_frames, list(df))
    }

    return(data_frames)
}


transform_pop_target_groups <- function(uptake_target_group) {
    print(" >>> Transforming groups df...")
    uptake_df <- list()

    # Sort for healthcare workers, remove target columns
    print(" >> Sorting for healthcare workers and removing target columns...")

    age_group_suffix <- list("HW" = "_hcw", "OLDER_60" = "_60p")
    var_columns <- c("adm_date", "adm_a1d", "adm_cps", "adm_boost","adm_target")

    for (tg in c("HW", "OLDER_60")) {
        df <- uptake_target_group %>%
            filter(target_group == paste(tg) & is.na(adm_cps) == FALSE) %>%
            select(-"target_group")

        colnames(df) <-
            c(
                "a_iso",
                helper_tr_add_suffix_to_list(var_columns, unlist(age_group_suffix[[tg]]))
            )

        uptake_df <- append(uptake_df, list(df))
    }

    return(uptake_df)
}

