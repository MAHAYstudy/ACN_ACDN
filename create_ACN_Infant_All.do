clear
set more off
version 13


**********************
*Merge DISTANCE HOUEHOLDS TO ACN/ACDN and ACN/ACDN information to Infant_All
*Ling Hsin    July 2018
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
	global TABLES "/Users/Ling/Desktop/MadaTables/" // "${Mada}analysis/tables/" //
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
	Infant_All
	 merge in idmen_distanceacn
	 merge in ACN_All_wide
****
*/

cd "$Mada"
clear matrix
capture log close

*1. Merge household distance to ACN/ACDN with infant_all
	
		* access the acn distance data
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
		expand 2 if year == 2015
		sort idmen year
		by idmen: replace year = 2014 if _n==1
		save `idmendist', replace
		
		 *Access infant_all data
		use "${All_create}infant_All", clear
		
		*Drop variables not used in ACN analysis
		drop fpc01-a204
		drop fb02fenc-fd16c_s
		drop fpg_demo99-fpc_rawtot
		drop clonefpc01-clonefpc_1pl_sresid
		drop fpc19_rc-fps37_rc
		drop fl09a_0-fd28a_5
		drop fpc19b-q1_5
		
		merge m:m idmen year using `idmendist'
		
			/*
			
				Result                           # of obs.
				-----------------------------------------
				not matched                         2,127
					from master                     1,254  (_merge==1)
					from using                        873  (_merge==2)
			
				matched                            11,250  (_merge==3)
				-----------------------------------------
			*/
		
			drop if _m ==2 // non-existing infant data in 2014
			
		/* no idmen distance data available:
		
				tab year if _m ==1
				
					   year |      Freq.     Percent        Cum.
				------------+-----------------------------------
					   2014 |        590       47.05       47.05
					   2015 |         38        3.03       50.08
					   2016 |        626       49.92      100.00
				------------+-----------------------------------
					  Total |      1,254      100.00
		*/
		
		rename _m idmendist_merge
		
		
		tempfile all
		save `all', replace

		
*2. Merge ACN/ACDN data with infant_all

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


		*call back the infant_all + idmendist data
		use `all', clear

		merge m:1 grappe year using `acn', update replace

			/*
			
				Result                           # of obs.
				-----------------------------------------
				not matched                             0
			
				matched                            12,504
					not updated                    10,168  (_merge==3)
					missing updated                 1,441  (_merge==4)
					nonmissing conflict               895  (_merge==5)
				-----------------------------------------
			
			*/

		rename _m acn_merge

	bys idind: egen all_targeted = max(targeted)
	label var all_targeted "targeted child"
	
	drop if all_targeted == .
	
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
			
			
			tsset, clear
			tsset idind year, y
			
			replace distance_acn = L.distance_acn if year == 2015 & distance_acn == . & L.distance_acn !=.
			replace distance_acn = L.distance_acn if year == 2016 & distance_acn == . & L.distance_acn !=.
			replace distance_acdn = L.distance_acdn if year == 2015 & distance_acdn == . & L.distance_acdn !=.
			replace distance_acdn = L.distance_acdn if year == 2016 & distance_acdn == . & L.distance_acdn !=.


			*input ACDN competency score =0 for control group
			replace Dacn_competency_score = 0 if treatment == 0 & acn_competency_score != .
			
save "${All_create}ACN_Infant_All", replace



/*

*Merge infant_All data

merge m:m idmen year using "${All_create}infant_All"
ta _m if year>2014
* There is a problem for 39/6 households that do not fully merge - need to be checked case by case
g nomatch = (_m != 3 & year > 2014)
label var nomatch "households not fully merge" 
drop _m

merge m:1 grappe year using `dist2014', update replace

			/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         8,739
        from master                     8,739  (_merge==1)
        from using                          0  (_merge==2)

    matched                             3,771
        not updated                         0  (_merge==3)
        missing updated                 3,771  (_merge==4)
        nonmissing conflict                 0  (_merge==5)
    -----------------------------------------
*/
	bys idind: egen all_targeted = max(targeted)
	label var all_targeted "targeted child"
	
/*
			tab year if _m == 4
			
			(mean) year |      Freq.     Percent        Cum.
			------------+-----------------------------------
				   2014 |      3,738       99.12       99.12
				   2015 |         33        0.88      100.00
			------------+-----------------------------------
				  Total |      3,771      100.00
				  
			*33 matched ones in 2015
			
			tab nomatch if _m == 4 & year == 2015
			
			 households |
			  not fully |
				  merge |      Freq.     Percent        Cum.
			------------+-----------------------------------
					  1 |         33      100.00      100.00
			------------+-----------------------------------
				  Total |         33      100.00
				  
			*they are part of the not fully merged households
			
			tab _m if nomatch == 1

							 _merge |      Freq.     Percent        Cum.
			------------------------+-----------------------------------
					master only (1) |         12       26.67       26.67
				missing updated (4) |         33       73.33      100.00
			------------------------+-----------------------------------
							  Total |         45      100.00

			*the 33 households in 2015 are all updated
			
			. tab all_targeted if nomatch ==1 & _m ==1

			   targeted |
				  child |      Freq.     Percent        Cum.
			------------+-----------------------------------
					  1 |          5      100.00      100.00
			------------+-----------------------------------
				  Total |          5      100.00

			* 5 out of the 12 in masteronly are targeted children
			idind:
					573503
					673501
					984604
					984704
					1214802

			*/
			

	
