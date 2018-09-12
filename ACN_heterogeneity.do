capture log close
clear
set more off
version 13
clear matrix



**********************
*ACN/ACDN heterogeneity analysis
*Ling Hsin    08/2018
*Updated: LH 9/10/18
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
	
/* INDEX

1. ACN capacity heterogeneity - child outcomes
2. ACDN capacity heterogeneity - child outcomes
A. ACN/ACDN Distance heterogeneity - child outcome
3. ACN capacity - household outcomes
4. ACDN capacity - household outcomes
B. ACN/ACDN Distance heterogeneity - household outcome
*/	
	
************************************************
*Access dataset - ACN INFANT
************************************************
use "${All_create}ACN_Infant_All", clear

		*******************************************************************************
		* GLOBAL LIST OF FAMILY OF OUTCOMES;
		*******************************************************************************
		
		
		*Fam 1 Variables
		global fam1 "hfaz wfaz wflz stunted sevstunted wasting sevwasting"
		
			label var hfaz "Height/Age Zscore"
			label var wfaz "Weight/Age Zscore" 
			label var wflz "Weight/Length Zscore"
			
			label var male "Infant Male"
			label var infant_age_months "Infant Age (Mo.)"
		
			
		*Fam 2: Intermediate indicators
		global fam2 "dairy_24h meat_egg_24h vitA_24h divers_24h home_score_FCI_pca bd_timesate24hr"
		
			lab var dairy_24h "dairy, past 24h" // binary
			lab var meat_egg_24h "proteins, past 24h" // binary
			lab var vitA_24h "vit A, past 24h" // binary
			lab var divers_24h "food diversity, past 24h" //categories 0-6
			
		*Fam 3: child development indicators
		global fam3 "asq_gross_sr asq_fine_sr asq_pres_sr asq_soc_sr asq_comm_sr asq_all_sr"
		
			label var asq_gross_sr "Gross Motor"
			label var asq_fine_sr "Fine Motor"
			label var asq_pres_sr "Problem Solving"
			label var asq_soc_sr  "Socio-Emotional Development"
			label var asq_comm_sr  "Communication Skills"
			
		*Participation
		global parACN "pr_visitACN3monts "
		global parACDN "pr_visitACDN3months pr_nbvisitACDN3months pr_T4visitACDNlast30days pr_T4nbvisitACDNlast30days"
		global parACDNT1T3 "pr_visitACDN3months pr_nbvisitACDN3months "
		global parACDNT4 "pr_T4visitACDNlast30days pr_T4nbvisitACDNlast30days"
			
			
		*Controls	
		global controls "male infant_age_months i.region i.wealth_qui i.birth_order mother_age i.mother_edu "
		
		keep if year == 2016
		*****************************************
		*		ACN Heterogeneity Analysis		*
		*****************************************
		/*
		*Kdensity graphs of ACN capacity
			twoway kdensity acn_competency_score if treatment==0 || ///
				kdensity acn_competency_score if treatment>0 ,  legend(label(1 "ACN Control") label(2 "ACN Treatmet"))
			graph save "${GRAPHS}ACN/ACN_capacity_T0vsT", replace
				
			twoway kdensity Dacn_competency_score if treatment == 1 || kdensity Dacn_competency_score if treatment == 4 ///
				, legend(label(1 "ACDN T1") label(2 "ACDN T4"))
			graph save "${GRAPHS}ACN/ACDN_capacity_T1T4", replace
			
			twoway kdensity acn_competency_score if treatment==1 ||  kdensity acn_competency_score if treatment==2 ///
				||  kdensity acn_competency_score if treatment==3 ||  kdensity acn_competency_score if treatment==4 ///
				, legend(label(1 "ACN T1") label(2 "ACN T2") label(3 "ACN T3") label(4 "ACN T4"))
			graph save "${GRAPHS}ACN/ACN_capacity_T1234", replace
				
			twoway kdensity acn_competency_score if treatment>0 || /// 
				kdensity Dacn_competency_score if treatment>0 ///
				, legend(label(1 "ACN T1-4") label(2 "ACDN T1-4") )
			graph save "${GRAPHS}ACN/ACNvsACDN_capacity", replace
		*/
		
		
	*1. ACN capacity heterogeneity	
		cap erase "${TABLES}ACN_ACDN/ACN_capacity_infant.xml"
		cap erase "${TABLES}ACN_ACDN/ACN_capacity_infant.txt"
		foreach var of varlist $fam1 $fam2 $fam3 {      
				reg `var' i.treatment##c.acn_competency_score $controls ,  robust cl(grappe)
					foreach num of numlist 1/4{
					lincom `num'.treatment + `num'.treatment#c.acn_competency_score
					global r`num' = `r(estimate)'
					global p`num' = `r(p)'
					}
				 outreg2 using "${TABLES}ACN_ACDN/ACN_capacity_infant", keep(i.treatment##c.acn_competency_score ) nocons excel ///
					 alpha(0.001, 0.01, 0.05, 0.15) symbol(***, **, *, †) ///
					 addt(post-interaction, `var' ) ///
					 adds(T1, $r1, T1-p, $p1, T2, $r2, T2-p, $p2, T3, $r3, T3-p, $p3, T4, $r4, T4-p, $p4) 
			
		est clear
		}
		
		
	*2. ACDN capacity heterogeneity	
		
		sum Dacn_competency_score, d
		sum Dacn_competency_score if treatment == 0, d
		*change ACDN competency score for T0 to the minimum
		replace Dacn_competency_score = -2.44 if treatment == 0
		
		cap erase "${TABLES}ACN_ACDN/ACDN_capacity_T0min.xml"
		cap erase "${TABLES}ACN_ACDN/ACDN_capacity_T0min.txt"
		foreach var of varlist $fam1 $fam2 $fam3 {      
				reg `var' i.treatment##c.Dacn_competency_score $controls ,  robust cl(grappe)
					foreach num of numlist 1/4{
					lincom `num'.treatment + `num'.treatment#c.Dacn_competency_score
					global Dr`num' = `r(estimate)'
					global Dp`num' = `r(p)'
					}
				 outreg2 using "${TABLES}ACN_ACDN/ACDN_capacity_T0min", keep(i.treatment##c.Dacn_competency_score ) nocons excel ///
					 alpha(0.001, 0.01, 0.05, 0.15) symbol(***, **, *, †) ///
					 addt(ACDN post-interaction, `var' ) ///
					 adds(T1, $Dr1, T1-p, $Dp1, T2, $Dr2, T2-p, $Dp2, T3, $Dr3, T3-p, $Dp3, T4, $Dr4, T4-p, $Dp4) 
			
		est clear
		}
		
		
	* A. ACN/ACDN Distance heterogeneity _ child outcome
		cap erase "${TABLES}ACN_ACDN/distance_infant.xml"
		cap erase "${TABLES}ACN_ACDN/distance_infant.txt"
		foreach var of varlist $fam1 $fam2 $fam3 {      
				reg `var' i.treatment##c.distance_acn $controls ,  robust cl(grappe)
					foreach num of numlist 1/4{
					lincom `num'.treatment + `num'.treatment#c.distance_acn
					global r`num' = `r(estimate)'
					global p`num' = `r(p)'
					}
				 outreg2 using "${TABLES}ACN_ACDN/distance_infant", keep(i.treatment##c.distance_acn ) nocons excel ///
					 alpha(0.001, 0.01, 0.05, 0.15) symbol(***, **, *, †) ///
					 title("Distance and child outcome") ///
					 addt(post-interaction, `var' ) ///
					 adds(T1, $r1, T1-p, $p1, T2, $r2, T2-p, $p2, T3, $r3, T3-p, $p3, T4, $r4, T4-p, $p4) 
			
		est clear
		}
		
		
************************************************
*TAKE-UP AND HETEROGENEITY
************************************************
	
	* 1. ACN capacity heterogeneity _ take-up
		cap erase "${TABLES}ACN_ACDN/takeup_capacity_ACN.xml"
		cap erase "${TABLES}ACN_ACDN/takeup_capacity_ACN.txt"
		foreach var of varlist $parACN {      
				reg `var' i.treatment##c.acn_competency_score $controls ,  robust cl(grappe)
					foreach num of numlist 1/4{
					lincom `num'.treatment + `num'.treatment#c.acn_competency_score
					global r`num' = `r(estimate)'
					global p`num' = `r(p)'
					}
				 outreg2 using "${TABLES}ACN_ACDN/takeup_capacity_ACN", keep(i.treatment##c.acn_competency_score ) nocons excel ///
					 alpha(0.001, 0.01, 0.05, 0.15) symbol(***, **, *, †) ///
					 addt(post-interaction, `var' ) ///
					 adds(T1, $r1, T1-p, $p1, T2, $r2, T2-p, $p2, T3, $r3, T3-p, $p3, T4, $r4, T4-p, $p4) 
			
		est clear
		}
		
	* 2. ACDN capacity heterogeneity _ take-up
		cap erase "${TABLES}ACN_ACDN/takeup_capacity_ACDN.xml"
		cap erase "${TABLES}ACN_ACDN/takeup_capacity_ACDN.txt"
		foreach var of varlist $parACN {      
				reg `var' i.treatment##c.Dacn_competency_score $controls ,  robust cl(grappe)
					foreach num of numlist 1/4{
					lincom `num'.treatment + `num'.treatment#c.Dacn_competency_score
					global Dr`num' = `r(estimate)'
					global Dp`num' = `r(p)'
					}
				 outreg2 using "${TABLES}ACN_ACDN/takeup_capacity_ACDN", keep(i.treatment##c.Dacn_competency_score ) nocons excel ///
					 alpha(0.001, 0.01, 0.05, 0.15) symbol(***, **, *, †) ///
					 addt(ACDN post-interaction, `var' ) ///
					 adds(T1, $Dr1, T1-p, $Dp1, T2, $Dr2, T2-p, $Dp2, T3, $Dr3, T3-p, $Dp3, T4, $Dr4, T4-p, $Dp4) 
			
		est clear
		}
		
	* 3. ACN/ACDN Distance heterogeneity _ take-up
		cap erase "${TABLES}ACN_ACDN/distance_takeup.xml"
		cap erase "${TABLES}ACN_ACDN/distance_takeup.txt"
		foreach var of varlist $parACN {      
				reg `var' i.treatment##c.distance_acn $controls ,  robust cl(grappe)
					foreach num of numlist 1/4{
					lincom `num'.treatment + `num'.treatment#c.distance_acn
					global r`num' = `r(estimate)'
					global p`num' = `r(p)'
					} 
				 outreg2 using "${TABLES}ACN_ACDN/distance_takeup", keep(i.treatment##c.distance_acn ) nocons excel ///
					 alpha(0.001, 0.01, 0.05, 0.15) symbol(***, **, *, †) ///
					 title("Distance and take-up") ///
					 addt(post-interaction, `var' ) ///
					 adds(T1, $r1, T1-p, $p1, T2, $r2, T2-p, $p2, T3, $r3, T3-p, $p3, T4, $r4, T4-p, $p4) 
			
		est clear
		}
		
		foreach var of varlist $parACDN {
		replace `var' = 0 if treatment == 0
		}
		
		foreach var of varlist $parACDNT1T3 {  
				reg `var' i.treatment##c.distance_acn $controls ,  robust cl(grappe)
					foreach num of numlist 1/3{
					lincom `num'.treatment + `num'.treatment#c.distance_acn
					global r`num' = `r(estimate)'
					global p`num' = `r(p)'
					} 
					outreg2 using "${TABLES}ACN_ACDN/distance_takeup", keep(i.treatment##c.distance_acn ) nocons excel ///
					 alpha(0.001, 0.01, 0.05, 0.15) symbol(***, **, *, †) ///
					 addt(post-interaction, `var' ) ///
					 adds(T1, $r1, T1-p, $p1, T2, $r2, T2-p, $p2, T3, $r3, T3-p, $p3) 
		}
		
		foreach var of varlist $parACDNT4 {  
				reg `var' i.treatment##c.distance_acn $controls ,  robust cl(grappe)
					foreach num of numlist 4{
					lincom `num'.treatment + `num'.treatment#c.distance_acn
					global r`num' = `r(estimate)'
					global p`num' = `r(p)'
					} 
					outreg2 using "${TABLES}ACN_ACDN/distance_takeup", keep(i.treatment##c.distance_acn ) nocons excel ///
					 alpha(0.001, 0.01, 0.05, 0.15) symbol(***, **, *, †) ///
					 addt(post-interaction, `var' ) ///
					 adds(T4, $r4, T4-p, $p4) 
		}
		
		
************************************************
*Access dataset - ACN Female
************************************************
use "${All_create}ACN_Female_All", clear


		*******************************************************************************
		* GLOBAL LIST OF FAMILY OF OUTCOMES;
		*******************************************************************************
		
		
		* hygiene and knowledge;
		global fefam "hhwash knowledge_score mddw foodsecure hygiene_score mealprep"
			
		global fe_controls "infant_sex infant_age_months i.region i.mother_educ i.wealth_qui i.birth_order mother_age"
		
		keep if year == 2016
		
			
	*3. ACN capacity - household outcomes
				cap erase "${TABLES}ACN_ACDN/ACN_capacity_female_all.xml"
				cap erase "${TABLES}ACN_ACDN/ACN_capacity_female_all.txt"
				foreach var of varlist $fefam {      
						reg `var' i.treatment##c.acn_competency_score $fe_controls ,  robust cl(grappe)
							foreach num of numlist 1/4{
							lincom `num'.treatment + `num'.treatment#c.acn_competency_score
							global r`num' = `r(estimate)'
							global p`num' = `r(p)'
							}
						 outreg2 using "${TABLES}ACN_ACDN/ACN_capacity_female_all", keep(i.treatment##c.acn_competency_score ) nocons excel ///
							 alpha(0.001, 0.01, 0.05, 0.15) symbol(***, **, *, †) ///
							 addt(post-interaction, `var' ) ///
							 adds(T1, $r1, T1-p, $p1, T2, $r2, T2-p, $p2, T3, $r3, T3-p, $p3, T4, $r4, T4-p, $p4 ) 
					
				est clear
				}
	
	
	*4. ACDN capacity - household outcomes
				cap erase "${TABLES}ACN_ACDN/ACDN_capacity_female_all.xml"
				cap erase "${TABLES}ACN_ACDN/ACDN_capacity_female_all.txt"
				foreach var of varlist $fefam {      
				reg `var' i.treatment##c.Dacn_competency_score $fe_controls ,  robust cl(grappe)
					foreach num of numlist 1/4{
					lincom `num'.treatment + `num'.treatment#c.Dacn_competency_score
					global Dr`num' = `r(estimate)'
					global Dp`num' = `r(p)'
					}
				 outreg2 using "${TABLES}ACN_ACDN/ACDN_capacity_female_all", keep(i.treatment##c.Dacn_competency_score ) nocons excel ///
					 alpha(0.001, 0.01, 0.05, 0.15) symbol(***, **, *, †) ///
					 addt(ACDN post-interaction, `var' ) ///
					 adds(T1, $Dr1, T1-p, $Dp1, T2, $Dr2, T2-p, $Dp2, T3, $Dr3, T3-p, $Dp3, T4, $Dr4, T4-p, $Dp4 ) 
			
		est clear
		}
		
	
		* B. ACN/ACDN Distance heterogeneity - household outcome
		cap erase "${TABLES}ACN_ACDN/distance_female.xml"
		cap erase "${TABLES}ACN_ACDN/distance_female.txt"
		foreach var of varlist $fefam {      
				reg `var' i.treatment##c.distance_acn $fe_controls ,  robust cl(grappe)
					foreach num of numlist 1/4{
					lincom `num'.treatment + `num'.treatment#c.distance_acn
					global Disr`num' = `r(estimate)'
					global Disp`num' = `r(p)'
					}
				 outreg2 using "${TABLES}ACN_ACDN/distance_female", keep(i.treatment##c.distance_acn ) nocons excel ///
					 alpha(0.001, 0.01, 0.05, 0.15) symbol(***, **, *, †) ///
					 title("Distance and household outcome") ///
					 addt(post-interaction, `var' ) ///
					 adds(T1, $Disr1, T1-p, $Disp1, T2, $Disr2, T2-p, $Disp2, T3, $Disr3, T3-p, $Disp3, T4, $Disr4, T4-p, $Disp4 ) 
			
		est clear
		}

		
		
