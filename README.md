# DWR Publication Classification Preparation

This repo contains code used to prepare DWR manuscript data for classification
by discipline and subject matter. Specifically, this repo houses R scripts for
processing publication DOIs and generating RIS citation files that include
abstracts. It includes two main workflows:

1. **Generate RIS File:**  
   A script that reads a text file containing DOIs and creates a basic RIS file
   with minimal citation fields. It also logs any errors that indicate that the
   DOI is invalid.

2. **Enrich RIS with Abstracts:**  
   A script that reads the previously generated RIS file, retrieves publication
   abstracts from the Crossref API, and appends them to the RIS records. It also
   logs any errors or cases where no abstract is available.

## Requirements

The scripts use R and the following packages (called explicitly with the `::` operator):
- [here](https://cran.r-project.org/package=here)
- [httr](https://cran.r-project.org/package=httr)
- [jsonlite](https://cran.r-project.org/package=jsonlite)

Make sure these packages are installed. You can install them by running:

```r
install.packages(c("here", "httr", "jsonlite"))
```