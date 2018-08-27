clear
set more off
version 13
clear matrix
capture log close


**********************
*Merge ACN DISTANCE - ACN/ACDN information - Female_All
*Ling Hsin    August 2018
**********************

* SET GLOBAL MACROS for path to main directories

global d= 8

	if $d == 8 {
	* 	Ling
	global Mada "/Volumes/Macintosh HD/Users/Ling/Dropbox/Madagascar Mahay Data/"
	*	Baseline folders
	gl BL_orig "${Mada}baseline/raw data2014/latest/"
	gl BL_create "${Mada}baseline/created_data2014/FINAL DATASETS/"
	gl MAJ_orig "${Mada}midline/Data/MAJ/Original/MAJ_Updated June 2016/"
	gl who_z "${Mada}WHO igrowup STATA/"
	
	*	Midline folders
	gl MAJ_create "${Mada}midline/Data/MAJ/"
	gl ML_orig_enf "${Mada}midline/Data/data - original/Data with correct ids/"
    gl ML_orig_men "${Mada}midline/Data/data - original/Data with correct ids/"
    gl ML_orig_vil "${Mada}midline/Data/data - original/Data with correct ids/"
	gl ML_create "${Mada}midline/Data/Created_Data_Midline/FINAL DATASETS/"

	*	Endline folders 
	gl EL_orig_enf "${Mada}endline/original_data/ENFANT/"
	gl EL_orig_men "${Mada}endline/original_data/MENAGE/"
	gl EL_orig_vil "${Mada}endline/original_data/VILLAGE/"
	gl EL_create "${Mada}endline/created_data/"
	gl EL_MAJ "${Mada}endline/MAJ/"
	
	* Admin data
	gl ADMIN_orig "${Mada}admin_data/"
	gl ADMIN_create "${Mada}admin_data/created_data/"		
	
	** ANALYSIS FOLDERS
	global TABLES "${Mada}analysis/tables/" // "/Users/Ling/Desktop/MadaTables/" // "${Mada}analysis/tables/" //
	global GRAPHS "${Mada}analysis/graphs/"
	global All_create "${Mada}analysis/all_create/"
	
	* gps folder
	gl GPS "${Mada}gps/"
	gl GPS_do "${Mada}gps/do_files/"
	gl GPS_create "${Mada}gps/created_data/"
	}
	
/*
****
Structure:
	Female_All
	 merge in idmen_distanceacn
	 merge in ACN_All_wide
****
*/

cd "$Mada"
clear matrix
capture log close

*1. access the acn distance data

		use "${GPS_create}idmen_distanceacn", clear
		sort idmen year
		tempfile idmendist
		save `idmendist', replace
		
		*some idmen missing idacn, idacdn in 2016
		bys idmen: egen newid_acn = max(id_acn)
		bys idmen: egen newid_acdn = max(id_acdn)
		drop id_acn id_acdn
		rename newid_acn id_acn
		rename newid_acdn id_acdn
		
		reshape wide distance_acn distance_acdn, i(idmen) j(year)
		pwcorr distance_acn2015 distance_acn2016, sig star(.05)
		*r > 0.99
		pwcorr distance_acdn2015 distance_acdn2016, sig star(.05)
		*r > 0.99
		
		use `idmendist', clear
			bys idmen: egen newid_acn = max(id_acn)
			bys idmen: egen newid_acdn = max(id_acdn)
			drop id_acn id_acdn
			rename newid_acn id_acn
			rename newid_acdn id_acdn
		expand 2 if year == 2015
		sort idmen year
		by idmen: replace year = 2014 if _n==1
		save `idmendist', replace
		
*========================================================		

*2. Clean Female_All to the same criteria as ITT analysis
use "${All_create}female_All", clear

			* Generating target groups based on exposure time (Program start date: October 1, 2014)
			cap drop age_pgst age_target
			
			* String/datetime variable for program start date
			gen program_start = date("10/1/2014", "MDY")
			format program_start %tdDD/NN/CCYY
			
			* String/datetime variable for DOB
			foreach var in infant_birth_day infant_birth_month {
				tostring `var', replace
			}
			forvalues i=1/9 {
				replace infant_birth_day = "0`i'" if infant_birth_day=="`i'"
				replace infant_birth_month = "0`i'" if infant_birth_month=="`i'"
			}
			egen dob = concat(infant_birth_year infant_birth_month infant_birth_day), punct(-)
			replace dob = "" if dob==".-.-."
			foreach var in infant_birth_day infant_birth_month {
				destring `var', replace
			}
			count if missing(dob) // 1248 missing values here
			
			gen clock_dob = date(dob, "YMD")
			format clock_dob %tdDD/NN/CCYY
			
			* Calculating age at start of program
			replace program_start = . if missing(clock_dob)
			gen age_pgst = floor((program_start - clock_dob)/30.4375)
			
			* Generating age_target based on age at start of program
			gen age_target = .
			replace age_target = 1 if age_pgst <0 & !missing(age_pgst)
			replace age_target = 2 if age_pgst>=0 & age_pgst<6 & !missing(age_pgst)
			replace age_target = 3 if age_pgst>6 & !missing(age_pgst)
			
			
			* Nov 8 2017: add temporary fam4 to create foodsecure binary variable (1-high food security) for intermediate outcomes table: (checked worked, have same # missings)
			recode foodSecurityIHS (1=1) (2=0) (3=0) (4=0) , gen(foodsecure)
			lab var foodsecure "foodsecurity binary"
			
			* hygiene practices (need to add sanitation);
			g hhwash=(hhandwashing_obs ==1) if hhandwashing_obs !=.
			
			
			* food diversity;
			egen protein=rsum(fanta4 fanta5 fanta6)
			
			
			/*http://www.fantaproject.org/monitoring-and-evaluation/minimum-dietary-diversity-women-indicator-mddw*/
			lab var fanta1 "grains"
			lab var fanta2 "pulses"
			lab var fanta4 "dairy"
			lab var fanta5 "fish/meat/poultry"
			lab var fanta6 "eggs"
			lab var fanta7 "dark green veg"
			lab var fanta8 "vitA fruit/veg"
			lab var fanta9 "other veg"
			lab var fanta10 "other fruit"
			lab var protein "dairy, fish/meat/poultry, eggs"
			lab var mddw_score "minimum diet diversity score"
			
			* there is no idmen missing info;
				bys idmen year: keep if _n==1
				tsset idmen year
				
			drop _merge
				
*============================================================

*3. Merge Female_All with Distance

		merge m:m idmen year using `idmendist'
		
		/*
			 Result                           # of obs.
		-----------------------------------------
		not matched                         1,996
			from master                     1,128  (_merge==1)
			from using                        868  (_merge==2)
	
		matched                             9,804  (_merge==3)
		-----------------------------------------
		
		*/
	
		drop if _m ==2 // non-existing household data in 2014
	
	
		*Distance data not available for households:
		tab year if _m == 1
		/*
			   year |      Freq.     Percent        Cum.
		------------+-----------------------------------
			   2014 |        590       52.30       52.30
			   2015 |         34        3.01       55.32
			   2016 |        504       44.68      100.00
		------------+-----------------------------------
			  Total |      1,128      100.00
		*/
		
		rename _m idmendist_merge
		
		tempfile all
		save `all', replace
		
*============================================================

*4.	merge ACN/ACDN data with female_all

	* access ACN ALL
		use "${All_create}/ACN_All_wide.dta", clear
		
			/*
			* Abount ACN & ACDN id between ACN_All and idmen_distanceacn 
			
			Identifier:
			ACN_All.dta - idacn, Didacn
			idmen_distanceacn.dta - id_acn, id_acdn
			
				*ACN
					* some are missing id_acn but have idacn
				
				*ACDN
					* the non-matching ones: id_acdn ends in 4 or 6, Didacn ends in 2
			*/
			

			rename idacn id_acn
			rename Didacn id_acdn
			
		tempfile acn
		save `acn', replace


	* call back the Femal_All + idmendist data
		use `all', clear
		
		merge m:1 grappe year using `acn', update replace
		
		
			/*
			 Result                           # of obs.
			-----------------------------------------
			not matched                             0
		
			matched                            10,932
				not updated                     8,945  (_merge==3)
				missing updated                 1,171  (_merge==4)
				nonmissing conflict               816  (_merge==5)
			-----------------------------------------
			*/
			
		rename _m acn_merge
	

	
	sort idmen idind year
	
	*update missing distance_data using data from previous years
			tab year if distance_acn == .
		/*
			   year |      Freq.     Percent        Cum.
		------------+-----------------------------------
			   2014 |          1        0.15        0.15
			   2015 |         33        4.98        5.14
			   2016 |        628       94.86      100.00
		------------+-----------------------------------
			  Total |        662      100.00
		*/
			tab year if distance_acdn == .
		/*
			   year |      Freq.     Percent        Cum.
		------------+-----------------------------------
			   2014 |          1        0.15        0.15
			   2015 |         33        4.98        5.14
			   2016 |        628       94.86      100.00
		------------+-----------------------------------
			  Total |        662      100.00
		*/
			
					*check data with repeated year
					bys idind year: gen year_repeated = _n 
					tab year_repeated
					browse idmen idind year year_* treatment id_acn id_acdn distance_acn distance_acdn idmendist_merge acn_merge
						*>1 = missing idind and household data
					tab treatment
					/*
						  type: |
					  treatment |
						  group |      Freq.     Percent        Cum.
					------------+-----------------------------------
							 T0 |      2,176       19.90       19.90
							 T1 |      2,213       20.24       40.15
							 T2 |      2,188       20.01       60.16
							 T3 |      2,181       19.95       80.11
							 T4 |      2,174       19.89      100.00
					------------+-----------------------------------
						  Total |     10,932      100.00
					*/
					drop if idind == . //(330 deleted)
					
					/*
						  type: |
					  treatment |
						  group |      Freq.     Percent        Cum.
					------------+-----------------------------------
							 T0 |      2,114       19.94       19.94
							 T1 |      2,141       20.19       40.13
							 T2 |      2,121       20.01       60.14
							 T3 |      2,124       20.03       80.17
							 T4 |      2,102       19.83      100.00
					------------+-----------------------------------
						  Total |     10,602      100.00
		
					*/
				
			tsset, clear
			tsset idind year, y 
			
			
			replace distance_acn = L.distance_acn if year == 2015 & distance_acn == . & L.distance_acn !=.
			replace distance_acn = L.distance_acn if year == 2016 & distance_acn == . & L.distance_acn !=.
			replace distance_acdn = L.distance_acdn if year == 2015 & distance_acdn == . & L.distance_acdn !=.
			replace distance_acdn = L.distance_acdn if year == 2016 & distance_acdn == . & L.distance_acdn !=.


			*input ACDN competency score =0 for control group
			replace Dacn_competency_score = 0 if treatment == 0 & acn_competency_score != .
			
save "${All_create}ACN_Female_All", replace
