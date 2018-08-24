# ACN_ACDN

## DATA STRUCTURE

- create_ACN_all.do -> created ACN_ALL.dta & ACN_ALL_wide.dta
  - -> ACN_Infant_All.dta
  - -> ACN_female_All.dta
  

   

## dofiles

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
