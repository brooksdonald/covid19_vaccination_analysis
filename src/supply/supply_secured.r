
load_supply_secured_data <- function() {
    print(" >> Load supply secured data...")
    supply_secured <- extract_supply_secured()
    c_sec_cour_lm <- extract_sup_sec_lm()
    datalist <- list("supply_secured" = supply_secured,
        "c_sec_cour_lm" = c_sec_cour_lm)
    return(datalist)
}

transform_supp_secured <- function(supply_secured, sec_date, c_sec_cour_lm) { # nolint
    print(" >> Transform supply secured and c_sec_cour_lm...")
    supply_secured <- transform_supply_secured(
        supply_secured, sec_date, c_sec_cour_lm
    )
    return(supply_secured)
}

extract_supply_secured <- function() {
    print(" >> Reading supply secured data...")
    supply_input <-
        data.frame(read_excel("data/_input/base_supply_secured_summary.xlsx",
            sheet = "supply_tracker",
            skip = 2))

    ## This function can be deleted in the future.
    ## It was added in July 2022 to aid the transition.
    helper_check_if_two_rows_were_deleted(supply_input)

    # pick only relevant columns and rename
    supply_secured <-
        select(
            supply_input,
            c(
                "ISO3",
                "Secured.and.or.Expected.Vaccine..millions.of.doses.",
                "Bilateral.Deals..millions.of.doses.",
                "Bilateral.Donations..millions.of.doses.",
                "COVAX.Total..millions.of.doses.",
                "EU.Deal..millions.of.doses.",
                "Other.sources..millions.of.doses.",
                "Domestic.Supply..millions.of.doses."
            )
        )

    print(" >> Selecting and renaming columns...")
    colnames(supply_secured) <-
        c(
            "a_iso",
            "sec_total_dose",
            "sec_bilat_dose",
            "sec_donat_dose",
            "sec_covax_dose",
            "sec_eu_dose",
            "sec_other_dose",
            "sec_domestic_dose"
        )

    print(" >> Renaming KOS to XKX...")
    supply_secured <- helper_rename_KOS_to_XKX(supply_secured, "a_iso")
    return(supply_secured)
}

extract_sup_sec_lm <- function() {
    print(" >> Reading supply secured summary lastmonth...")
    b_sec_lm <-
        data.frame(
            read_excel("data/_input/base_supply_secured_summary_lastmonth.xlsx",
                sheet = "supply_tracker",
                skip = 2
            )
        )

    ## This function can be deleted in the future.
    ## It was added in July 2022 to aid the transition.
    helper_check_if_two_rows_were_deleted(b_sec_lm)
    
    # Pick only relevant columns and rename them
    c_sec_cour_lm <-
    select(
        b_sec_lm,
        c(
            "ISO3",
            "Secured.and.or.Expected.Vaccine..millions.of.doses."
        )
    )
    print(" >> Selecting and renaming columns...")
    colnames(c_sec_cour_lm) <-
    c(
        "a_iso",
        "sec_total_dose_lm"
    )
    return(c_sec_cour_lm)

}

transform_supply_secured <- function(supply_secured, sec_date, c_sec_cour_lm) { #nolint
    ## supply secured current
    print(" >> Transforming and cleaning supply secured...")
    multiplier <- 1000000
    columns_to_multiply <- list(
        "sec_total_dose",
        "sec_bilat_dose",
        "sec_donat_dose",
        "sec_covax_dose",
        "sec_other_dose",
        "sec_eu_dose",
        "sec_domestic_dose"
    )
    print(" >> Multiplying current supply by a million...")
    for (c in columns_to_multiply) {
        supply_secured <- mutate(supply_secured, UQ(rlang::sym(c)) :=
            UQ(rlang::sym(c)) * multiplier)
    }

    ## Supply secured summary lastmonth
    ## Multiply lastmonth summary by one million
    print(" >> Multiplying last month supply summary by a million...")
    c_sec_cour_lm <- c_sec_cour_lm %>%
        mutate(sec_total_dose_lm = sec_total_dose_lm * 1000000)
    print(" >> Replacing NAs...")
    supply_secured <- supply_secured %>% replace(is.na(.), 0)
    c_sec_cour_lm <- c_sec_cour_lm %>% replace(is.na(.), 0)
    print(" >> Rounding...")
    supply_secured <- supply_secured %>% mutate_if(is.numeric, round)
    c_sec_cour_lm <- c_sec_cour_lm %>% mutate_if(is.numeric, round)
    # consolidate other secured sources for visualization
    print(" >> Summing others...")
    supply_secured <- supply_secured %>%
        mutate(sec_other_sum_dose = sec_eu_dose + sec_other_dose + sec_domestic_dose)

    print(" >> Adding secured supply dataset date...")
    supply_secured$sec_date <- sec_date
    
    # Merge current and last month supply
    supply_secured <- left_join(supply_secured, c_sec_cour_lm, by = "a_iso")
    return(supply_secured)
}
