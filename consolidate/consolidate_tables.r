# Create values table

values_table <- function(a_data_amc) {
    z_values <- data.frame(c("Text"))

    z_values$pop_amc <- sum(a_data_amc$a_pop, na.rm = TRUE)
    z_values$pop_amc_hcw <- sum(a_data_amc$a_pop_hcw, na.rm = TRUE)
    z_values$pop_africa <- sum(a_data_africa$a_pop, na.rm = TRUE)
    z_values$pop_csc <- sum(a_data_csc$a_pop, na.rm = TRUE)
    z_values$pop_ifc <- sum(a_data_ifc$a_pop, na.rm = TRUE)

    z_values$pop_amc_10 <- z_values$pop_amc * 0.1
    z_values$pop_amc_20 <- z_values$pop_amc * 0.2
    z_values$pop_amc_40 <- z_values$pop_amc * 0.4
    z_values$pop_amc_70 <- z_values$pop_amc * 0.7
    
    z_values$refresh_date_value <- refresh_date

    return(z_values)

}

# Change count tables

## Daily vaccination rate percent change category
vxrate_change_cat <- function(a_data, b_vxrate_change_lw) {
    # Select data
    c_data_dvr_lm_cat <-
    select(
        a_data,
        c(
            "a_iso",
            "dvr_4wk_td_change_lm_per_cat",
            "a_covax_status",
            "intro_status",
            "a_continent"
        )
    )
    f_dvr_change_count <- left_join(c_data_dvr_lm_cat, b_vxrate_change_lw, by = "a_iso")
    f_dvr_change_count_af <<- filter(
        f_dvr_change_count,
        a_continent == "Africa" &
        intro_status == "Product introduced"
    )
    f_dvr_change_count <- filter(
        f_dvr_change_count,
        a_covax_status == "AMC" &
        intro_status == "Product introduced"
    )
    f_dvr_change_count <-
        select(
            f_dvr_change_count,
            c(
                "a_iso",
                "dvr_4wk_td_change_lm_per_cat",
                "dvr_4wk_td_change_lw_lm_per_cat"
            )
        )
        colnames(f_dvr_change_count) <- c(
            "a_iso",
            "dvr_change_cat_lm_cur",
            "dvr_change_cat_lm_lw"
        )

    f_dvr_change_count_cur <- f_dvr_change_count %>%
        group_by(dvr_change_cat_lm_cur) %>%
        summarise(count_cur = n())
        colnames(f_dvr_change_count_cur) <- c(
            "cat",
            "count_cur"
        )
    f_dvr_change_count_lw <- f_dvr_change_count %>%
        group_by(dvr_change_cat_lm_lw) %>%
        summarise(count_lw = n())
        colnames(f_dvr_change_count_lw) <- c(
            "cat",
            "count_lw"
        )
    f_dvr_change_count <- left_join(f_dvr_change_count_cur, f_dvr_change_count_lw, by = "cat")
    f_dvr_change_count <- f_dvr_change_count %>%
        mutate(count_change = count_cur - count_lw)

    return(f_dvr_change_count)

}

# New add
## DVR change: Africa
dvr_change_af <- function() {
    f_dvr_change_count_af <-
    select(
        f_dvr_change_count_af,
        c(
            "a_iso",
            "dvr_4wk_td_change_lm_per_cat",
            "dvr_4wk_td_change_lw_lm_per_cat"
        )
    )
    colnames(f_dvr_change_count_af) <- c(
        "a_iso",
        "dvr_change_cat_lm_cur",
        "dvr_change_cat_lm_lw"
    )
    f_dvr_change_count_cur_af <- f_dvr_change_count_af %>%
    group_by(dvr_change_cat_lm_cur) %>%
    summarise(count_cur = n())
    colnames(f_dvr_change_count_cur_af) <- c("cat", "count_cur")

    f_dvr_change_count_lw_af <- f_dvr_change_count_af %>%
    group_by(dvr_change_cat_lm_lw) %>%
    summarise(count_lw = n())
    colnames(f_dvr_change_count_lw_af) <- c("cat", "count_lw")

    f_dvr_change_count_af <-
    left_join(f_dvr_change_count_cur_af, f_dvr_change_count_lw_af, by = "cat")

    f_dvr_change_count_af <- f_dvr_change_count_af %>%
    mutate(count_change = count_cur - count_lw)
    return(f_dvr_change_count_af)
}

## Coverage category change
cov_cat_change <- function(a_data) {
    f_cov_change_count <-
    filter(
        a_data,
        a_covax_status == "AMC" &
        intro_status == "Product introduced"
    )

    f_cov_change_count <- select(
        f_cov_change_count,
        c(
            "a_iso",
            "cov_total_fv_cat",
            "cov_total_fv_lw_cat"
            )
        )

    f_cov_change_count_cur <- f_cov_change_count %>%
        group_by(cov_total_fv_cat) %>%
        summarise(count_cur = n())
        colnames(f_cov_change_count_cur) <- c(
            "cat",
            "count_cur"
        )

    f_cov_change_count_lw <- f_cov_change_count %>%
        group_by(cov_total_fv_lw_cat) %>%
        summarise(count_lw = n())
        colnames(f_cov_change_count_lw) <- c("cat", "count_lw")

    f_cov_change_count <-
    left_join(f_cov_change_count_cur, f_cov_change_count_lw, by = "cat")

    f_cov_change_count <- f_cov_change_count %>%
    mutate(count_change = count_cur - count_lw)

    return(f_cov_change_count)
}

##Coverage category change: Africa
cov_cat_af <- function(a_data) {
    f_cov_change_count_af <-
    filter(
        a_data,
        a_continent == "Africa" &
        intro_status == "Product introduced"
    )
    f_cov_change_count_af <-
    select(
        f_cov_change_count_af,
        c(
            "a_iso",
            "cov_total_fv_cat",
            "cov_total_fv_lw_cat"
        )
    )
    f_cov_change_count_cur_af <- f_cov_change_count_af %>%
    group_by(cov_total_fv_cat) %>%
    summarise(count_cur = n())
    colnames(f_cov_change_count_cur_af) <- c("cat", "count_cur")

    f_cov_change_count_lw_af <- f_cov_change_count_af %>%
    group_by(cov_total_fv_lw_cat) %>%
    summarise(count_lw = n())
    colnames(f_cov_change_count_lw_af) <- c("cat", "count_lw")

    f_cov_change_count_af <-
    left_join(f_cov_change_count_cur_af, f_cov_change_count_lw_af, by = "cat")

    f_cov_change_count_af <- f_cov_change_count_af %>%
    mutate(count_change = count_cur - count_lw)
    return(f_cov_change_count_af)
}

