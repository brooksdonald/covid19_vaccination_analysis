# rows 1723 - 1972

run_eda_adm_cov <- function(
    c_vxrate_latest,
    entity_characteristics,
    population_data,
    uptake_gender_data,
    b_who_dashboard,
    b_smartsheet,
    supply_secured,
    delivery_courses_doses,
    b_dp,
    c_delivery_product,
    b_fin_fund_del_sum,
    refresh_date,
    t70_deadline
) {
    source("eda/adm_cov/adm_consolidate.r")

    print(" > Starting local environment for vxrate...")

    print(" >  Extracting consolidated vxrate summary...")
    c_vxrate_latest_red <- extract_vxrate_details(c_vxrate_latest)
    print(" > Done.")

    print(" > Obtaining WHO Dashboard...")
    b_who_dashboard <- load_who_dashboard()
    print(" > Done.")

    print(" > Merging dataframes...")
    a_data <- merge_dataframes(
        entity_characteristics,
        c_vxrate_latest_red,
        population_data,
        uptake_gender_data,
        b_who_dashboard,
        b_smartsheet,
        supply_secured,
        delivery_courses_doses,
        b_dp,
        c_delivery_product,
        b_fin_fund_del_sum
    )
    print(" > Done.")

    print(" > Calculating merged data")
    datalist <- transform_vxrate_merge(a_data, refresh_date, t70_deadline)
    a_data <- datalist$a_data
    timeto_t70 <- datalist$timeto_t70
    print(" > Done.")
    return(environment())
}