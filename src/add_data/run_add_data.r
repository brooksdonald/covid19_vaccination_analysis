# Rows 1648 - 1719

run_add_data <- function() {
    source("src/add_data/add_data.r")

    print(" > Starting local environment for base data...")

    datalist <- load_base_data()
    b_smartsheet <- transform_base_data(as.data.frame(datalist[1]))
    b_who_dashboard <- as.data.frame(datalist[2])
    print(" > Done.")

    print(" > Returning to local environment.")

    return(environment())
}