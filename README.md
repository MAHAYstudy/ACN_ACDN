# ACN_ACDN

## DATA STRUCTURE

- create_ACN_all.do -> created ACN_ALL.dta & ACN_ALL_wide.dta
  - -> + Infant_all & distance = ACN_Infant_All.dta
  - -> + Female_all & distance = ACN_female_All.dta
  
## GRAPHS

### Heterogeneity graphs

- In folder Madagascar Mahay Data/analysis/tables/ACN_ACDN/ACN_ACDN_Heterogeneity/
   

## dofiles

### ACN_heterogeneity.do

- ACN and ACDN capacity and distance heterogeneity analysis
- outcomes: include ITT outcomes and take-up

- take-up score: using data originally from female.dta
  - route of data: female.dta -> infant_all.dta -> ITT_table2.dta -> ACN_Infant_All.dta

### ACN_descriptives.do
- Compare characteristics of ACNs and ACDNs

### create ACN_Infant_All.do

- Pull in the data of the distance between households and ACN/ACDN and the information of ACN/ACDN to Infant_All dataset
- Data saved to /Madagascar Mahay Data/analysis/all_create/ACN_Infant_All.dta


### create_ACN_all.do

- Clean and reshape ACN data
- created 
  - ACN_ALL.dta : the cleaned dataset
  - ACN_ALL_wide.dta : used to merge with infant_all and female_all
  - ACN_All_site_wide.dta : based on site_id, used for descriptive analysis

## Other notes

##### Scores:
motivation scores - use sum of sub-scales in description
v_tot - error in ACN_BL.do fixed, some scores are 0 --- missing all the subscales, replaced to be missing

#### Log

##### 9/6/18
- Home score: based on FCI, using the sum of all five scales is favorable.
  - problems: 
    - totbook: the number of books can not reflect the family home condition. (Questionaire range was too wide.)
    - no number of playobjects
  - use pca score of the items 
