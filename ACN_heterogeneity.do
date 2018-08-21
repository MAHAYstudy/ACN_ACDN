clear
set more off
version 13
clear matrix
capture log close


**********************
*ACN/ACDN heterogeneity analysis
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
	global TABLES "${Mada}analysis/tables/" // "/Users/Ling/Desktop/MadaTables/" //
	global GRAPHS "${Mada}analysis/graphs/"
	global All_create "${Mada}analysis/all_create/"
	global ACN_log "${Mada}analysis/ACN_log/"
	
	* gps folder
	gl GPS "${Mada}gps/"
	gl GPS_do "${Mada}gps/do_files/"
	gl GPS_create "${Mada}gps/created_data/"
	}
	

*Access dataset
use "${All_create}ACN_Infant_All", clear

*******************************************************************************
* GLOBAL LIST OF FAMILY OF OUTCOMES;
*******************************************************************************


*Fam 1 Variables
global fam1 "hfaz wfaz wflz asq_all_sr stunted sevstunted wasting sevwasting"

	label var hfaz "Height/Age Zscore"
	label var wfaz "Weight/Age Zscore" 
	label var wflz "Weight/Length Zscore"
	
	label var male "Infant Male"
	label var infant_age_months "Infant Age (Mo.)"

	
*Fam 2: Intermediate indicators
global fam2 "dairy_24h meat_egg_24h vitA_24h divers_24h home_score2 bd_timesate24hr"

	lab var dairy_24h "dairy, past 24h" // binary
	lab var meat_egg_24h "proteins, past 24h" // binary
	lab var vitA_24h "vit A, past 24h" // binary
	lab var divers_24h "food diversity, past 24h" //categories 0-6
	label var home_score2 "Home Play"
	
*Fam 3: child development indicators
global fam3 "asq_gross_sr asq_fine_sr asq_pres_sr asq_soc_sr asq_comm_sr asq_all_sr"

	label var asq_gross_sr "Gross Motor"
	label var asq_fine_sr "Fine Motor"
	label var asq_pres_sr "Problem Solving"
	label var asq_soc_sr  "Socio-Emotional Development"
	label var asq_comm_sr  "Communication Skills"
	
	
*Controls	
global controls "i.wealth_qui i.birth_order mother_age male i.region i.mother_educ"


keep if year == 2016
*****************************************
*		ACN Heterogeneity Analysis		*
*****************************************

*Kdensity graphs of ACN capacity
	twoway kdensity acn_competency_score if treatment==0 || ///
		kdensity acn_competency_score if treatment>0 ,  legend(label(1 "ACN Control") label(2 "ACN Treatmet"))
		
	twoway kdensity Dacn_competency_score if treatment == 1 || kdensity Dacn_competency_score if treatment == 4 ///
		, legend(label(1 "ACDN T1") label(2 "ACDN T4"))
	
	twoway kdensity acn_competency_score if treatment==1 ||  kdensity acn_competency_score if treatment==2 ///
		||  kdensity acn_competency_score if treatment==3 ||  kdensity acn_competency_score if treatment==4 ///
		, legend(label(1 "ACN T1") label(2 "ACN T2") label(3 "ACN T3") label(4 "ACN T4"))
		
		
	twoway kdensity acn_competency_score if treatment>0 || /// 
		kdensity Dacn_competency_score if treatment>0 ///
		, legend(label(1 "ACN T1-4") label(2 "ACDN T1-4") 


	
cap erase "${TABLES}ACN_ACDN/capacity.xml"
cap erase "${TABLES}ACN_ACDN/capacity.txt"

foreach var of varlist $fam1 {
	reg `var' i.treatment##c.acn_competency_score $controls ,  robust cl(grappe)
		
}
