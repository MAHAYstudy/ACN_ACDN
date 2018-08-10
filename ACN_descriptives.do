clear
set more off
version 13


**********************
*ACN/ACDN descriptive analysis
*Ling Hsin    08/2018
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
	global ACN_log "${Mada}analysis/ACN_log/"
	
	* gps folder
	gl GPS "${Mada}gps/"
	gl GPS_do "${Mada}gps/do_files/"
	gl GPS_create "${Mada}gps/created_data/"
	}
	
clear matrix
capture log close

log using "${ACN_log}ACN_descriptives", replace


*Compare ACN ACDN characteristics using the original data
	use  "${All_create}ACN_All", clear
	keep grappe year tacn baseline_* turnover* idacn acn_age acn_marstatus ///
	acn_nokids acn_otheractiv acn_edulevel acn_religion acn_wealth_index ///
	act_curr_agri act_curr_trader act_bef_agri act_bef_trader act_bef_teacher ///
	acn_knowledge_score acn_hygiene_score ///
	acn_mot_* acn_v_tot
	

	for var acn_*: tab X, m
		*acn_v_tot: 419 missing
		*1 ACDN age = 234
	replace acn_age = . if acn_age >=99
	
	
	quietly estpost ttest acn_* if year==2015 | year== 2016, by(tacn)
	
	estout ., c("mu_1(fmt(%9.2f) label(ACN mean)) mu_2(fmt(%9.2f) label(ACDN mean)) b(fmt(%9.3f) star label(mean difference)) p(par fmt(%9.3f))") l
	
	estimate clear

*Compare ACN ACDN characteristics using the paired data
	use "${All_create}ACN_All_wide", clear
	replace Dacn_age = . if Dacn_age == 234
	
		global ACNvar "acn_age acn_marstatus acn_nokids acn_otheractiv acn_edulevel acn_wealth_index acn_knowledge_score acn_hygiene_score acn_mot_score acn_v_tot"
		
		foreach var in $ACNvar {
		quietly ttest `var'==D`var' if year==2015 | year== 2016 
		eststo ACNttest
	}
		estout ACNttest,  c("mu_1(fmt(%9.2f) label(ACN mean)) mu_2(fmt(%9.2f) label(ACDN mean)) b(fmt(%9.3f) star label(mean difference)) p(par fmt(%9.3f))")


*Compare within and between treatment arms
	use "${All_create}ACN_Infant_All", clear
	replace Dacn_age = . if Dacn_age == 234
	
	drop acn_merge
	
	*Within treatment arms
	for var acn_*: bys treatment: ttest X == DX if year == 2015 | year == 2016
	
	*Between treatment arms
	for var acn_*: oneway X treatment if year == 2015 | year == 2016, bonferroni tabulate
	for var Dacn_*: oneway X treatment if year == 2015 | year == 2016, bonferroni tabulate
