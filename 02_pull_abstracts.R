# define input and output RIS file paths
input_ris <- here::here("ris_sample.ris")
output_ris <- here::here("ris_sample_with_abstracts.ris")
error_log_file <- here::here("abstract_error_log.csv")

# initialize an empty data frame to log errors
error_log <- data.frame(doi = character(), error = character(), stringsAsFactors = FALSE)

# read in the RIS file as text lines
ris_lines <- readLines(input_ris, encoding = "UTF-8")

# split the RIS file into records
# assume each record ends with a line starting with "ER  -"
record_split <- cumsum(grepl("^ER  -", ris_lines))
records <- split(ris_lines, record_split)

# create a function to process each record
process_record <- function(record) {
  # identify the DOI line; for RIS the DOI is marked "DO  -"
  doi_line <- record[grepl("^DO  -", record)]
  if (length(doi_line) == 0) {
    # no DOI; cannot look up an abstract.
    message("No DOI found in record; skipping enrichment.")
    return(record)
  }
  
  # extract DOI and trim white space (take the first DOI if multiple)
  doi <- sub("^DO  -\\s*", "", doi_line[1])
  doi <- trimws(doi)
  
  # build the Crossref API URL using the DOI.
  crossref_url <- paste0("https://api.crossref.org/works/", doi)
  
  # attempt to get the metadata via GET request using tryCatch
  metadata <- tryCatch({
    resp <- httr::GET(crossref_url)
    if (httr::status_code(resp) != 200) {
      my_error <- paste("HTTP status not 200:", httr::status_code(resp))
      # log the error for this DOI
      error_log <<- rbind(error_log, data.frame(doi = doi, error = my_error, stringsAsFactors = FALSE))
      stop(my_error)
    }
    # parse the JSON response.
    metadata_text <- httr::content(resp, as = "text", encoding = "UTF-8")
    jsonlite::fromJSON(metadata_text, simplifyVector = TRUE)
  }, error = function(e) {
    my_error <- paste("Failed to retrieve metadata:", e$message)
    # log the error for this DOI
    error_log <<- rbind(error_log, data.frame(doi = doi, error = my_error, stringsAsFactors = FALSE))
    message("Failed to retrieve metadata for DOI: ", doi, ". Error: ", e$message)
    return(NULL)
  })
  
  # if metadata retrieval failed, return the record unchanged
  if (is.null(metadata)) {
    return(record)
  }
  
  # check if an abstract exists
  abstract <- metadata$message$abstract
  if (!is.null(abstract)) {
    # remove any simple XML/HTML tags; many abstracts come in JATS format
    abstract_clean <- gsub("<[^>]+>", "", abstract)
    
    # append the abstract as a new RIS field ("AB  -")
    record <- c(record, paste("AB  -", abstract_clean))
    message("Abstract added for DOI: ", doi)
  } else {
    message("No abstract found for DOI: ", doi)
  }
  
  return(record)
}

# process each record to pull in abstracts
records_with_abstracts <- lapply(records, process_record)

# flatten the list of records back into a single character vector
updated_ris <- unlist(lapply(records_with_abstracts, function(rec) c(rec, "")), use.names = FALSE)

# write the updated RIS content to the output file
writeLines(updated_ris, output_ris, useBytes = TRUE)

# write the error log to the CSV file
write.csv(error_log, file = error_log_file, row.names = FALSE)
