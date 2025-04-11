# set up files
input_file <- here::here("doi_sample.txt")
dois <- readLines(input_file)
clean_dois <- sub("^https?://(dx\\.)?doi\\.org/", "", dois)

output_file <- here::here("ris_sample.ris")

# set up the DOI resolver URL and header
base_url <- "https://dx.doi.org/"
hdr <- "application/x-research-info-systems"
names(hdr) <- "Accept"

# create a data frame to log problematic DOIs
error_log <- data.frame(
  doi = character(),
  error = character(),
  stringsAsFactors = FALSE
)

# iterate over each cleaned DOI and try to download the RIS entry
for (doi in clean_dois) {
  doi_url <- paste0(base_url, doi)
  call_url <- url(doi_url, headers = hdr)
  
  # try to open the connection
  o <- try(open(call_url))
  if (inherits(o, "try-error")) {
    err_msg <- paste("Cannot open URL:", doi_url)
    cat("==>>", err_msg, "\n")
    # record the error
    error_log <- rbind(
      error_log,
      data.frame(doi = doi, error = err_msg, stringsAsFactors = FALSE)
    )
    next
  }
  
  # try to read the RIS entry
  x <- try(scan(call_url, what = "", sep = "\n"))
  close(call_url)
  
  if (inherits(x, "try-error")) {
    err_msg <- paste("Download failed for DOI:", doi)
    cat("==>>", err_msg, "\n")
    # record the error
    error_log <- rbind(
      error_log,
      data.frame(doi = doi, error = err_msg, stringsAsFactors = FALSE)
    )
    next
  }
  
  # append the retrieved RIS entry to the output file
  cat(x, sep = "\n", file = output_file, append = TRUE)
  cat("\n", file = output_file, append = TRUE)
}

# write the error log to a csv file for further inspection
error_log_file <- here::here("doi_error_log.csv")
write.csv(error_log, file = error_log_file, row.names = FALSE)