# PURPOSE: Preliminary analysis of occurrence of 
# environmentally-relevant keywords on 81 non-profit breast cancer advocacy
# organizations' webpages. Parsed about 14k pages across the 90 organizations. 
# WRITTEN IN R VERSION: R version 3.5.0 (2018-04-23)

### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Setup -----
### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


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
library_careful("ggrepel")

### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Read in data -----
### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

counts <- read_csv("term_count_output-2019_August.csv")

### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Clean up & analysis prep -----
### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Are there any empty cells or NAs in this data?
stopifnot(any(sapply(counts, is_empty)) == FALSE)


# Filter out cases where parsing didn't work? 
counts2 <-
  counts %>% 
  #Drop URLs that didn't parse
  filter(`decoded_url` != "Didn't work") %>%
  #Drop organizations that had issues (for example, not US-based, only one page worked

  filter(!(Organization %in% c("The Pink and Black Project", "We Can, Women's Empowerment Cancer Network", "Michigan Breast Cancer Coalition"))) %>%
  #Drop pages in Spanish
  filter(!grepl("espanol", `url`))

# No longer any espanol pages, because cleaned a new dataset 
check.espanol <-
  counts %>%
  filter(grepl("espanol", `url`))



#subtract occurences for the problematic 12 term plus organization cases (e.g., terms being overrepresented because of menu bar)

counts2 <- 
  counts2 %>%
  mutate(Exercise = ifelse(Organization == "Breast Cancer Network of WNY" &  Exercise > 1, Exercise-2, Exercise),
       Diet = ifelse(Organization == "Tigerlily Foundation" & Diet> 0, Diet -1, Diet),
       Pollutants = ifelse(Organization == "Massachusetts Breast Cancer Coalition" & Pollutants> 0, Pollutants -1, Pollutants),
       Genetics = ifelse(Organization == "SHARE for Women Facing Breast or Ovarian Cancer" & Genetics> 0, Genetics -1, Genetics),
       `Hormone Therapy` = ifelse(Organization == "National Breast Cancer Foundation" & `Hormone Therapy`> 0, `Hormone Therapy` -1, `Hormone Therapy`),
       `Physical activity` = ifelse(Organization == "National Breast Cancer Foundation" & `Physical activity`> 0, `Physical activity` -1, `Physical activity`),
       `Precautionary Principle` = ifelse(Organization == "Huntington Breast Cancer Action Coalition" & `Precautionary Principle` > 0, `Precautionary Principle`-1, `Precautionary Principle`),
       `Air pollution` = ifelse(Organization == "Huntington Breast Cancer Action Coalition" & `Air pollution` > 0, `Air pollution`-1, `Air pollution`),
       `Endocrine Disruptors` = ifelse(Organization == "Huntington Breast Cancer Action Coalition" & `Endocrine Disruptors` > 0, `Endocrine Disruptors`-1, `Endocrine Disruptors`),
      Pesticides = ifelse(Organization == "Huntington Breast Cancer Action Coalition" & Pesticides> 0, Pesticides-1, Pesticides),
      Pollution = ifelse(Organization == "Huntington Breast Cancer Action Coalition" & Pollution > 0, Pollution-1, Pollution),
      Toxins = ifelse(Organization == "Huntington Breast Cancer Action Coalition" & Toxins > 0, Toxins-1, Toxins))
  
#check to see if the manual adjustments worked (note 12/6/2018: worked)
write.csv(counts2, "terms_outputs_after_adjustments", row.names = FALSE)


# Now make data long, such that all terms are in one column, all counts in
# another column. Each row corresponds to a unique URL/term combination.
# Making the data long is useful for analyses and for plotting with ggplot.
counts.long <-
  counts2 %>%
  gather(Term, Count, Environmental:Ethnicity)

#Consider collapsing some terms -- e.g. "Environment" and "Environmental", etc.
# Topic for discussion
counts.long$Group <-
  with(counts.long, 
       #grepl looks for the quoted pattern in the variable "Term" & returns 
       # TRUE if it is present, otherwise FALSE. 
       # Case_when assigns the new variable, Group, to the value specified 
       # after the "~"for any rows where the pattern is present (TRUE) in Term. 
       case_when(grepl("Environ", Term) ~ "Environment",
                 grepl("Disrupt", Term) ~ "EDCs",
                 grepl("Toxin", Term) ~ "Toxin",
                 grepl("Flame", Term) ~ "Flame Retardant", 
                 grepl("Phthal", Term) ~ "Phthalate", 
                 grepl("Pest", Term) ~ "Pesticide", 
                 grepl("Contamina", Term) ~ "Contamination",
                 # ^ matches only cases that start with "Chemical" (i.e. won't match "Perfluorinated chemicals")
                 grepl("^Chemical", Term) ~ "Chemical",
                 grepl("^Pollut", Term) ~ "Pollution",
                 grepl("Exercise|Active|activity", Term) ~ "Physical Activity",
                 grepl("Bisphenol|BPA", Term) ~ "Bisphenol",
                 grepl("Paraben", Term) ~ "Paraben",
                 grepl("Toxic", Term) ~ "Toxic",
                 grepl("Birth control|Oral", Term) ~ "OCP",
                 grepl("Genetics|BRAC1|BRAC2", Term) ~ "Genetics",
                 grepl("PAH", Term) ~ "PAHs",
                 grepl("DES|Diethyl", Term) ~ "DES",
                 grepl("HRT", Term) ~ "HRT",
                 grepl("Obese|Overweight", Term) ~ "Weight",
                 grepl("Breast density|Dense breasts", Term) ~ "Breast Density",
                 grepl("African American|African-American", Term) ~ "African American",
                 grepl("Latin|Hispani", Term) ~ "Latin American",
                 grepl("Disparit", Term) ~ "Disparities",
                 grepl("Native Americ|Native-Americ", Term) ~ "Native American",
                 grepl("Perfluorinated chemicals|PFAS|PFC|PFCs|PFOS|PFOA", Term) ~ "PFAS",
                 #otherwise, if none of the above patterns have been found in
                 # Term, just keep the current value of Term
                 TRUE ~ Term))

# take a look at grouping & make sure they all worked as planned and 
# see if there are any more to collapse
check.groups <- 
  table(counts.long$Term, counts.long$Group) %>% 
  as.data.frame %>%
  filter(Freq != 0)



# Combine Huntington with Prevention is the Cure (latter is the campaign for Huntington)
counts.long$Organization <- with(counts.long, ifelse(grepl("Prevention is the Cure- this is the campaign for Huntington Breast Cancer Action Coalition, so combine these", Organization), "Huntington Breast Cancer Action Coalition", Organization))


counts.long$Organization <- with(counts.long, ifelse(grepl("MyBreastCancerSupport.org", Organization), "My Breast Cancer Support", Organization))

# Collapse across group, make a new variable 'Terms' that captures
# all the individual terms collapsed into a group. 
counts.long2 <-
  counts.long %>%
  group_by(Organization, Group) %>%
  summarize(Count = sum(Count),
            Terms = paste(unique(Term), collapse = ", "),
            TotPages = length(unique(`url`))
            )

#Find the average website size
  
counts.long2 %>%
  select(Organization, TotPages)%>%
  unique %>%
  unique

### make sure each org has one unique # for TotPages
stopifnot(nrow(counts.long2 %>% 
                 ungroup %>% 
                 select(Organization, TotPages) 
               %>% unique) == 
            length(unique(counts.long2$Organization)))

counts.long2_check <- 
  counts.long2 %>% 
  group_by(Organization) %>%
  summarize(N = length(unique(TotPages)))


#Make another broader group that captures the 'type' of terms
counts.long2$Group2 <-
  with(counts.long2,
       case_when(Group %in% c("Contamination", 
                              "Pollution", 
                              "Precautionary Principle") ~ "General Environmental",
                 
                 Group %in% c("Alcohol", "Diet", 
                              "Physical Activity", 
                              "Weight", "Breast Density", 
                              "Family History",
                              "Genetics", "HRT", "OCP", 
                               "DES") ~ "Other Risk Factors",
                 
                 #Chemical might be chemo
                 #Environment to broad might be diet
                 #Lead might be not the chemical but the action
                 Group %in% c("Environment", "Chemical", "Lead") ~ "?",
                 
                 Group == "Prevention" ~ "Prevention",
                 
                 Group %in% c("Bisphenol", "Flame Retardant", 
                              "Oxybenzone", "Paraben",
                              "Pesticide", "PFAS", "PFOA",
                              "PFOS", "Phthalate", "EDCs", "Air pollution", "PAHs") ~ "Specific Environmental"))

table(counts.long2$Group2, useNA = "ifany")
check_NAs <- 
  counts.long2 %>%
  filter(is.na(Group2)) %>%
  pull(Group) %>%
  unique()

#Get list of organizations
#orgs <-
 # counts %>%
  #select(Organization) %>%
  #unique

#write.csv(orgs, "July 7", row.names = FALSE)

#Get list of organizations
orgs <-
  counts.long2 %>%
  select(Organization) %>%
  unique

write.csv(orgs, "list of orgs July 7", row.names = FALSE)




### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Analyses -----
### ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

###++++++++++++++++
### 1. What percent of organizations mention the environment? ----

counts.summary <-
  counts.long2 %>%
  select(Organization, Group2, Count) %>%
  group_by(Organization, Group2) %>%
  summarize(
    sumGroup2 = sum(Count)
  ) %>%
  ungroup %>%
  group_by(Group2) %>%
  summarize(
    Percent_org = sum(sumGroup2 > 0)/sum(!is.na(Organization))
  )



write.csv(counts.summary.explore, "summary of organizations and terms_July 7", row.names = FALSE)


#percent orgs mentioning each individual term
counts.summary.terms <-
  counts.long2 %>%
  select(Organization, Group, Count) %>%
  group_by(Organization, Group) %>%
  summarize(
    sumGroup = sum(Count)
  ) %>%
  ungroup %>%
  group_by(Group) %>%
  summarize(
    Percent_org = sum(sumGroup > 0)/sum(!is.na(Organization))
  )

write.csv(counts.summary.terms, "percent orgs mentioning terms July 7 run", row.names = FALSE)

#counts of terms mentioned across organizations
counts.across.orgs <-
  counts.long2 %>%
  group_by(Group) %>%
  summarize(
    sumGroup = sum(Count)
  )

write.csv(counts.across.orgs, "frequency of terms July 7 run", row.names = FALSE)

write.csv(counts2, "how much terms show up on each url", row.names = FALSE)

###++++++++++++++++



###++++++++++++++++
### Prevalance of two groups of risk factors (env versus other) plotted against each other ----

#library(ggplot2)
# library(ggrepel)

org_categories <- read_csv("list of orgs August7_withcategories.csv")

counts.otherRisk<-subset(counts.summary2, Group2b=='Other Risk Factors')
counts.envRisk<-subset(counts.summary2, Group2b=='Environmental')
counts.merged<-merge(counts.otherRisk, counts.envRisk, by='Organization')

counts.merged2 <- merge(counts.merged, org_categories, by = "Organization")

stopifnot(nrow(counts.merged2) == nrow(counts.merged))

p<-ggplot(counts.merged2,aes(x = sumGroup2.STD.x, y = sumGroup2.STD.y, color=OrganizationType, shape=OrganizationType))+ 
  geom_point(aes(x = sumGroup2.STD.x,y = sumGroup2.STD.y), size=2) + 
  # geom_text(aes(label=ifelse(sumGroup2.STD.x>2 | sumGroup2.STD.y>2,as.character(Organization),'')),hjust=0,vjust=0,size=8,colour='dark grey') +
  geom_text_repel(aes(label=ifelse(sumGroup2.STD.x>2 | sumGroup2.STD.y>2,as.character(Organization),'')),hjust=0,vjust=0,size=4,colour='dark grey', force = 2, nudge_y = .2) +
  scale_y_continuous(limits=c(0,10), expand = c(0,0)) +
  scale_x_continuous(limits=c(0,5),expand = c(0,0)) + 
  scale_color_manual(values = c("darkorchid3", "deepskyblue1"), name="Type of Organization") +
  scale_shape_manual(values=c(15, 16), name="Type of Organization")+

  labs(x="Average mentions per page of other risk factors", y="Average mentions per page of environmental factors") +
  geom_abline(intercept=0, slope=1, colour="grey", linetype=2, size=.2) + 
  theme(text=element_text(size=12), panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black", size=.1),
        legend.position = c(.8, .8), legend.margin=margin(.5, .5, .5, .5, "cm"), legend.box.background = element_rect(), legend.key=element_blank())
p
#p+ labs(fill="Type of Organization") #THIS DOESN"T WORK EITHER 
#p + theme(legend.position="right")
#p + theme(legend.margin=margin(.5, .5, .5, .5, "cm"), legend.box.background = element_rect())
#p + theme(legend.background=element_rect(fill="grey85", size=2, linetype="solid"))
# https://ggplot2.tidyverse.org/reference/theme.html
# for changing legend look

ggsave(p, filename = "risk factors graphed8.png", device = "png", width = 10, height = 7)


