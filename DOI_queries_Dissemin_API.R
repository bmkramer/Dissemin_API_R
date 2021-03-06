#this script uses the Dissemin API to get information on online availability (gold and green Open Access) 
#of academic articles, identified by their DOI, as well as publisher policies on archiving. 
#Dissemin API documentation: http://dev.dissem.in/api.html
#Dissemin documentation: https://media.readthedocs.org/pdf/dissemin/latest/dissemin.pdf

#input and output
#this script uses as input a csv file with a list of doi's in a column labeled "DOI"
#the output is a dataframe (written to a csv file) with for each DOI, the following information from the Dissemin API:
#- original DOI used as input
#- classification = self-archiving policy of the publisher: "OA" (available from the publisher), "OK" (some version can be shared), "UNK" (unknown/unclear sharing policy), "NOK" (restrictive sharing policy).
#- publisher
#- journal title
#- issn
#- journal policy on sharing preprint version
#- journal policy on sharing postprint version
#- journal policy on sharing publisher version
#- date of publication
#- URL where freely available version can be found, if any. 

#caveats / issues
#1) the script uses loops (bad R!), if someone can improve this using an apply-function, you're most welcome! 
#2) the script currently stops executing when it encounters a HTTP status 404 for one of the DOIs checked.
#this could probably be circumvented with try.catch(), but I don't know how (yet);
#in the current setup, the script can be manually rerun from line 40, 
#skipping the offending DOI by resetting the loop counter in line 79.
#3) For some DOis, results obtained through this script are empty while the Dissemin API does return results
#so will need a closer look at the Dissemin API output parameters.

#install packages
install.packages("rjson")
install.packages("httpcache")
require(rjson)
require(httpcache)
#import csv with DOIs; csv should contain list of doi's in column labeled "DOI"
DOI_input <- read.csv(file="xxx.csv", header=TRUE, sep=",")

#create empty dataframe with 10 columns
df <- data.frame(matrix(nrow = 1, ncol = 10))
#set column names of dataframe
colnames(df) = c("DOI", "Classification", "Publisher", "Journal", "ISSN", "Policy_preprint", "Policy_postprint", "Policy_published", "Date", "PDF_URL")

naIfNull <- function(cell){
  if(is.null(cell)) {
    return(NA)
  } else {
    return(cell)
  }
}

#define function to get data from Dissemin API and construct vector with relevant variables;
#this vector will become a row in the final dataframe to be produced;
#define doi.character as character for doi to be included as such in the vector;
#employ naIfNull function because not all values are always present in Dissemin API output.
getData <- function(doi){
  doi_character <- as.character(doi)
  url <- paste("http://dissem.in/api/",doi,sep="")
  raw_data <- GET(url)
  rd <- httr::content(raw_data)
  paper <- rd$paper
  first_record <- paper$records[[1]]
  result <- c(
    doi_character,
    naIfNull(paper$classification),
    naIfNull(first_record$publisher),
    naIfNull(first_record$journal),
    naIfNull(first_record$issn),
    naIfNull(first_record$policy$preprint),
    naIfNull(first_record$policy$postprint),
    naIfNull(first_record$policy$published),
    naIfNull(paper$date),
    naIfNull(paper$pdf_url)
    )
  return(result)
}

#fill dataframe df (from 2nd row onwards) with API results for each DOI from original dataset
#use counter approach to be able to test/run on subsets of data, and to manually jump any rows giving a 404 error
#when jumping rows by changing counter, rerun the script from line 38. This way, results are added to the same dataframe 
#reset counter range to fit number of rows in source file.
for (i in 1:100){
  df <- rbind(df,getData(DOI_input$DOI[i]))
}

#alternatively, to try out the script, block lines 80-82, 
#and run the script with lines 86-88 instead, using 3 example DOIs with different outputs. 
#df <- rbind(df,getData("10.1016/j.paid.2009.02.013"))
#df <- rbind(df,getData("10.1001/archderm.1986.01660130056025"))
#df <- rbind(df,getData("10.1002/0471140856.tx2306s57"))

write.csv(df, file="Dissemin_API_results.csv", row.names=FALSE)
