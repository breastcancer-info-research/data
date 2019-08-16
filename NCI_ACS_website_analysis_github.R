# PURPOSE: analysis of occurrence of 
#  keywords for risk factors on NCI and ACS 
# Date: 07/03/19
# WRITTEN IN R VERSION: R version 3.5.0 (2018-04-23)

### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Setup -----
### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#first working directory is what I need when pulling up in the conference room
#setwd("//aristotle/shared/Central_Files/Articles_Abstracts/SSI-Articles/BC_Organizations_Env_Factors_2018/Website_Analysis/Term_outputs/")

setwd("S://Central_Files/Articles_Abstracts/SSI-Articles/BC_Organizations_Env_Factors_2018/Website_Analysis/Term_outputs/")

options(stringsAsFactors = FALSE)

### some helpful functions from Janet Ackerman!

# function to install packages if necessary, then load
# differs from normal library function in that the package name should be quoted
# option to suppress messages makes this more complicated than it would be otherwise
library_careful <- function (packname, silent = TRUE) {
  # packname is name of package (quoted)
  # silent is boolean - suppress warning and other messages?
  do_it <- function () {
    if (!require (packname, character.only = TRUE)){
      install.packages (packname)
      library (packname, character.only = TRUE)
    }
  }  
  if (silent)
    suppressWarnings (suppressPackageStartupMessages (do_it()))
  else 
    do_it()
}

# function to find blanks and NAs
is_empty <- function (x, pattern ="^ *$") {
   is.na( x) | grepl (pattern, x)
    }

# Load packages
library_careful("tidyverse")
library_careful("stringr") 

### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Read in data -----
### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

counts <- read_csv("ACS-NCI_2019_05_19_v2_term_outputs.csv")



### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Clean up & analysis prep -----
### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Are there any empty cells or NAs in this data?
stopifnot(any(sapply(counts, is_empty)) == FALSE)
# No, there are not. Put a stopifnot check so this will throw an error if the
# data change and NAs / empty cells appear. 


# No longer any espanol pages, because cleaned a new dataset 
check.espanol <-
  counts %>%
  filter(grepl("espanol", `url`))


## Filter out urls that do not have "breast" in them

urlsbreast <-
  counts %>%
  filter(grepl("breast", url, ignore.case = TRUE))

#Check which urls were filtered out (it was 21). All don't have "breast"
checknonbreast <- 
  counts%>%
  filter(!grepl("breast", url, ignore.case= TRUE))

#Filter out "ourstory" urls since seem to be duplicating other ones. Make sure not the case for additional urls
deleteduplicates <-
  urlsbreast %>%
  filter(!grepl("ourstory", url, ignore.case =TRUE))
  
#check the ones that remain don't have ourstory

checkdeletedduplicates <- 
  urlsbreast%>%
  filter(grepl("ourstory", url, ignore.case= TRUE))

# Now make data long, such that all terms are in one column, all counts in
# another column. Each row corresponds to a unique URL/term combination.
# Making the data long is useful for analyses and for plotting with ggplot.
counts.long <-
  deleteduplicates %>%
  gather(Term, Count, environmental:ethnicity)

#Consider collapsing some terms -- e.g. "Environment" and "Environmental", etc.
# Topic for discussion
counts.long$Group <-
  with(counts.long, 
       #grepl looks for the quoted pattern in the variable "Term" & returns 
       # TRUE if it is present, otherwise FALSE. 
       # Case_when assigns the new variable, Group, to the value specified 
       # after the "~"for any rows where the pattern is present (TRUE) in Term. 
       case_when(grepl("environ", Term) ~ "Environment",
                 grepl("disrupt", Term) ~ "EDCs",
                 grepl("toxin", Term) ~ "Toxin",
                 grepl("flame", Term) ~ "Flame Retardant", 
                 grepl("phthal", Term) ~ "Phthalate", 
                 grepl("pest", Term) ~ "Pesticide", 
                 grepl("contamina", Term) ~ "Contamination",
                 # ^ matches only cases that start with "Chemical" (i.e. won't match "Perfluorinated chemicals")
                 grepl("^chemical", Term) ~ "Chemical",
                 grepl("^pollut", Term) ~ "Pollution",
                 grepl("exercise|active|activity", Term) ~ "Physical Activity",
                 grepl("bisphenol|bpa", Term) ~ "Bisphenol",
                 grepl("paraben", Term) ~ "Paraben",
                 grepl("toxic", Term) ~ "Toxic",
                 grepl("birth control|oral", Term) ~ "OCP",
                 grepl("genetics|brac|brac2", Term) ~ "Genetics",
                 grepl("pah", Term) ~ "PAHs",
                 grepl("des|diethyl", Term) ~ "DES",
                 grepl("hrt", Term) ~ "HRT",
                 grepl("obese|overweight", Term) ~ "Weight",
                 grepl("breast density|dense breasts", Term) ~ "Breast Density",
                 grepl("african american|african-american", Term) ~ "African American",
                 grepl("latin|hispani", Term) ~ "Latin American",
                 grepl("disparit", Term) ~ "Disparities",
                 grepl("native americ|native-americ", Term) ~ "Native American",
                 grepl("perfluorinated chemicals|pfas|pfc|pfcs|pfos|pfoa", Term) ~ "PFAS",
                 #otherwise, if none of the above patterns have been found in
                 # Term, just keep the current value of Term
                 TRUE ~ Term))

# take a look at grouping & make sure they all worked as planned and 
# see if there are any more to collapse
check.groups <- 
  table(counts.long$Term, counts.long$Group) %>% 
  as.data.frame %>%
  filter(Freq != 0)


# Collapse across group, make a new variable 'Terms' that captures
# all the individual terms collapsed into a group. 
counts.long2 <-
  counts.long %>%
  group_by(organization, Group) %>%
  summarize(Count = sum(Count),
            Terms = paste(unique(Term), collapse = ", "),
            TotPages = length(unique(`url`))
            )

### use mutate rather than summarize, and give the collapsed
# count variable a new name so can manually spot check that we are
# properly summing counts
counts.long2.check <-
  counts.long %>%
  group_by(organization, Group) %>%
  mutate(sumCount = sum(Count),
            Terms = paste(unique(Term), collapse = ", "),
            TotPages = length(unique(`url`))
  ) %>%
  arrange(organization, Group) %>%
  select(organization, url, Group, Term, Terms, Count, sumCount, TotPages)

write.csv(counts.long2, "times terms show up for ACS and NCI", row.names=FALSE)




#counts of terms mentioned across both ACS and NCI
counts.across.orgs <-
  counts.long2 %>%
  group_by(Group) %>%
  summarize(
    sumGroup = sum(Count)
  )

write.csv(counts.across.orgs, "frequency of terms July 3 run ACS and NCI", row.names = FALSE)
#


