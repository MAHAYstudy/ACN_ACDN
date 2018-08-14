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
	global TABLES "${Mada}analysis/tables/" // "/Users/Ling/Desktop/MadaTables/" //
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
	

	for var acn_*: quietly tab X, m
		*acn_v_tot: 419 missing
		*1 ACDN age = 234
	replace acn_age = . if acn_age >=99
	
	
	quietly estpost ttest acn_* if year==2015 | year== 2016, by(tacn)
	
	estout ., c("mu_1(fmt(%9.2f) label(ACN mean)) mu_2(fmt(%9.2f) label(ACDN mean)) b(fmt(%9.3f) star label(mean difference)) p(par fmt(%9.3f))") l
	
	estimate clear

*Compare ACN ACDN characteristics using the paired data
	use "${All_create}ACN_All_wide", clear
	replace Dacn_age = . if Dacn_age == 234
	
		global ACNvar "acn_age acn_marstatus acn_nokids acn_otheractiv acn_edulevel acn_wealth_index acn_knowledge_score acn_hygiene_score acn_mot_* acn_v_tot"
		
	*programs for paired t test
									capture program drop _estpost_markout2
									program _estpost_markout2 // marks out obs that are missing on *all* variables
								gettoken touse varlist: 0
								if `:list sizeof varlist'>0 {
									tempname touse2
									gen byte `touse2' = 0
									foreach var of local varlist {
										qui replace `touse2' = 1 if !missing(`var')
									}
									qui replace `touse' = 0 if `touse2'==0
								}
							end
									
									capture program drop pairttest
							
									* 5. pairttest: wrapper for -ttest- 
									prog pairttest, eclass
    version 8.2
    local caller : di _caller() // not used

    // syntax
    syntax varlist(numeric) [if] [in] , [by(varname)] [ ESample Quietly ///
         LISTwise CASEwise UNEqual Welch ]
    if "`casewise'"!="" local listwise listwise

    // sample
    if "`listwise'"!="" marksample touse
    else {
        marksample touse, nov
        _estpost_markout2 `touse' `varlist'
    }
    markout `touse' `by', strok
    qui count if `touse'
    local N = r(N)
    if `N'==0 error 2000

	
    // gather results
    local nvars: list sizeof varlist
    tempname diff count
    mat `diff' = J(1, `nvars', .)
    mat coln `diff' = `varlist'
    mat `count' = `diff'
    local mnames se /*sd*/ t df_t p_l p p_u N_1 mu_1 /*sd_1*/ N_2 mu_2 /*sd_2*/
    foreach m of local mnames {
        tempname `m'
        mat ``m'' = `diff'
    }
    local i 0
    foreach v of local varlist {
        local ++i
        qui ttest `v' == D`v' if `touse', `unequal' `welch'
        mat `diff'[1,`i'] = r(mu_1) - r(mu_2)
        mat `count'[1,`i'] = r(N_1) + r(N_2)
        foreach m of local mnames {
            mat ``m''[1,`i'] = r(`m')
        }
    }

    // display
    if "`quietly'"=="" {
        tempname res
        mat `res' = `diff'', `count''
        local rescoln "e(b) e(count)"
        foreach m of local mnames {
            mat `res' = `res', ``m'''
            local rescoln `rescoln' e(`m')
        }
        mat coln `res' = `rescoln'
        if c(stata_version)<9 {
            mat list `res', noheader nohalf format(%9.0g)
        }
        else {
            matlist `res', nohalf lines(oneline)
        }
        mat drop `res'
    }

    // post results
    local V
    if c(stata_version)<9 { // V required in Stata 8
        tempname V
        mat `V' = diag(vecdiag(`se'' * `se'))
    }
    if "`esample'"!="" local esample esample(`touse')
    eret post `diff' `V', obs(`N') `esample'

    eret scalar k = `nvars'

    eret local wexp `"`exp'"'
    eret local wtype `"`weight'"'
    eret local welch "`welch'"
    eret local unequal "`unequal'"
    eret local byvar "`by'"
    eret local subcmd "ttest"
    eret local cmd "estpost"

    local nmat: list sizeof mnames
    forv i=`nmat'(-1)1 {
        local m: word `i' of `mnames'
        eret matrix `m' = ``m''
    }
    eret matrix count = `count'
end
		
		

		pairttest $ACNvar if year==2015 | year== 2016 

		estout . using "${TABLES}ACN_ACDN/ACN_ACDN_Characteristics.txt", r ///
		title("ACN ACDN characteristics comparison - paired") ///
		c("mu_1(fmt(%9.2f) label(ACN mean)) mu_2(fmt(%9.2f) label(ACDN mean)) b(fmt(%9.3f) star label(mean difference)) p(par fmt(%9.3f))")


*Compare within and between treatment arms
	use "${All_create}ACN_Infant_All", clear
	replace Dacn_age = . if Dacn_age == 234
	
	drop acn_merge
	
	*Within treatment arms
	for var acn_*: bys treatment: ttest X == DX if year == 2015 | year == 2016
	
	*Between treatment arms
	for var acn_*: oneway X treatment if year == 2015 | year == 2016, bonferroni tabulate
	for var Dacn_*: oneway X treatment if year == 2015 | year == 2016, bonferroni tabulate
