
helper_tr_add_suffix_to_list <- function(l, suffix) {
    return(sprintf(paste0("%s", suffix), l))
}


helper_replace_values_with_map <- function(data, values, map, na_fill = "") {
    dict <- data.frame(
        val = values,
        map = map
    )

    data <- dict$map[match(data, dict$val)]

    if (na_fill != "") {
        data[is.na(data)] <- na_fill
    }

    return(data)
}