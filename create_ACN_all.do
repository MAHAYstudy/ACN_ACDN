clear
set more off
version 13

*EG: v2: added indicators for ACN/ACDN rotation

* SET GLOBAL MACROS for path to main directories

global d= 8
	if $d==1 {
	* "Karl"
	}
	if $d==2 {
	* "Ann" 
	}
	if $d==3 {
	* Emanuela
	global Mada "C:\Users\wb181320\Dropbox\Madagascar Mahay Data\"
	
	*	Baseline folders
	gl BL_orig "${Mada}baseline\raw data2014\latest\"
	gl BL_create "${Mada}baseline\created_data2014\FINAL DATASETS\"
	gl MAJ_orig "${Mada}midline\Data\MAJ\Original\MAJ_Updated June 2016\"
	
	gl who_z "${Mada}WHO igrowup STATA\"
	
	*	Midline folders
	gl MAJ_create "${Mada}midline\Data\MAJ\"
	gl ML_orig_enf "${Mada}midline\Data\data - original\Data with correct ids\"
    gl ML_orig_men "${Mada}midline\Data\data - original\Data with correct ids\"
    gl ML_orig_vil "${Mada}midline\Data\data - original\Data with correct ids\"
	gl ML_create "${Mada}midline\Data\Created_Data_Midline\FINAL DATASETS\"
	
	
	
	
	*gl ML_BLcreate "${Mada}midline\Data\Created_Data_Midline\FINAL DATASETS\Merged BL - ML\"
	*gl TABLES "${Mada}midline\Analysis\tables\"
	*gl GRAPHS "${Mada}midline\Analysis\graphs\"

	*	En dline folders 
	gl EL_orig_enf "${Mada}endline\original_data\ENFANT\"
	gl EL_orig_men "${Mada}endline\original_data\MENAGE\"
	gl EL_orig_vil "${Mada}endline\original_data\VILLAGE"
	gl EL_create "${Mada}endline\created_data\"
	gl EL_MAJ "${Mada}endline\MAJ\"
	
	* Admin data
	gl ADMIN_orig "${Mada}admin_data\"
	gl ADMIN_create "${Mada}admin_data\created_data\"		

	
	** ANALYSIS FOLDERS
	global TABLES "${Mada}analysis\tables\"
	global GRAPHS "${Mada}analysis\graphs\"
	global All_create "${Mada}analysis\all_create\"
	}	 

	if $d==4 {
	* Kara
	global user "/stat"
	global Mada "/Users/$user/Box Sync/Madagascar Mahay Data/"
	global ML_create "${Mada}midline/Data/Created_Data_Midline/"
	global BL_orig "/Users/$user/Box Sync/Madagascar Mahay Data/baseline/raw data2014/"
	global who_z "/Users/$user/Box Sync/Madagascar Mahay Data/WHO igrowup STATA/"
	global reports "/Users/$user/Box Sync/Madagascar Mahay Data/midline/Reports/infant/"
	}
	
	if $d == 5 {
	*	Kodjo
	global Mada "C:\Users\AFLAGAH\Box Sync\Madagascar Mahay Data\"
	}

	global survey_name "Enfant"
	
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
	
	

	

cd "$Mada"
clear matrix
capture log close


* IMPORTANT 1/24/17: NEED TO MAKE SURE THAT MATERNAL INFO IS MERGED THROUGH THE INFANT_IDMERE


********************************************************************************
* BASELINE
********************************************************************************
* get hh wealth quintiles, food security and water/sanitation characteristics
use "${BL_create}ACN_final.dta", clear
g year=2014
sort grappe tacn acn_name year

tempfile bl 
save `bl'

********************************************************************************
* ADD MIDLINE
********************************************************************************
use "${ML_create}ACN_final", clear
g year=2015
sort grappe tacn acn_name year


*	Kodjo: Instead of merging, I append the baseline dataset 
append using `bl'  , force 

tempfile bl_ml 

save `bl_ml'


********************************************************************************
* ADD ENDLINE
********************************************************************************
use "${EL_create}ACN_final", clear
g year=2016
sort grappe tacn acn_name year


append using `bl_ml' , force 

ta year
cap drop group-groups

 sort grappe
* Add in group (control & TX groups along with regions and a few others)
merge m:1 grappe using "${BL_orig}ie_sample w grappe code",	keepusing(group coderg rgion site_id codefar coderg codedistr codecom codesite code_ong code_anim codsite)
	*287 obs without grappe id
	*drop if _m==1
	ta _m
	drop _m
	

* region
encode province, g(region)

* IMPORTANT FIX 6/5/1

cap drop treat1-treat4

* treatment data, encode into a numeric group variable
encode group, gen(groupn)
for num 1/4: gen treatX=(group=="Treatment X") if group!=""
lab var treat1 "T1: intensive counseling"
lab var treat2 "T2: LNS children 6-18"

replace group="Treatment 1" if grappe==99 
replace group="Treatment 4" if grappe==96 
replace group="Treatment 2" if grappe==95 
replace group="Treatment 2" if grappe==100 

lab var treat3 "T3: LNS pregnant/lactating and children"
lab var treat4 "T4: nutrition and early stimulation"

g program=(group!="Control") if group!=""

* motivation scale from ADE 2011
for var cn*: recode X 9=.

egen motmiss = rowmiss(cn*)
egen motscale = rowtotal(cn*)
replace motscale=. if motmiss > 2
hist  motscale, discrete /* looks like there is a group that may have been coded wrong? */
alpha cn*, asis /* 0.90 - pretty good */
factor cn*
egen mot_external = rowtotal(cn09 cn11 cn12) 
egen mot_introject= rowtotal(cn06 cn08 cn07)
egen mot_intrinsic= rowtotal(cn01 cn02 cn03)
egen mot_identif= rowtotal(cn04 cn05)
egen mot_social = rowtotal(cn13 cn14)


* fixing ACN IDs. missing for a few ACN/ACNs  
replace idacn=idacn_old if idacn==. & idacn_old!=.
g idacn2=idacn
replace idacn2=grappe*10+3 if idacn==. & tacn==1
replace idacn2=grappe*10+4 if idacn==. & tacn==2

* same acn/acdn as in baseline
for num 26 27 29 34 37 38 41 78: replace idacn2=grappe*10+2 if tacn==2 & grappe==X

* different acdn between 2015 and 2016
for num 107 112 120 121: replace idacn2=grappe*10+5 if tacn==2 & grappe==X

rename idacn idacn_orig
rename idacn2 idacn
cap drop d
gen d=1
egen numd=sum(d), by(idacn)
ta numd
ta numd year
ta numd year if tacn==1
ta numd year if tacn==2
drop d numd

tsset idacn year


ta group year


* there was 1 ACDN identified in the control group at baseline (grappe 39). to check 
* use "${BL_orig}ie_sample w grappe code"
* ta group if grappe==39
replace group="Control" if year==2014 & grappe==39
* number of times that a CHW is present in the data

bys idacn: gen num=_n

****** ROTATION ACN ************************************************

ta num year if tacn==1

/*
          |               year
       num |      2014       2015       2016 |     Total
-----------+---------------------------------+----------
         1 |       125          7          0 |       132 
         2 |         0        118          7 |       125 
         3 |         0          0        118 |       118 
-----------+---------------------------------+----------
     Total |       125        125        125 |       375 

*/

g d_acn=1 		if num==1 & year==2015 & tacn==1
replace d_acn=1 if num==2 & year==2016 & tacn==1
recode d_acn .=0 if tacn==1

egen turnover_acn=max(d_acn), by(grappe)
drop d_acn

lab var turnover_acn "=1 if site had change in ACN between baseline and endline"


****** ROTATION ACDN ************************************************

ta num year if tacn==2

gen d=idacn if tacn==2
egen md=mean(d), by(grappe)
g diff=md!=idacn if tacn==2
ta diff
drop d diff md

recode idacn 64=62   if grappe==6  & tacn==2
recode idacn 154=152 if grappe==15 & tacn==2
recode idacn 184=182 if grappe==18 & tacn==2
recode idacn 454=452 if grappe==45 & tacn==2

recode idacn 802=804 if year==2016 & tacn==2 & grappe==80
recode idacn 944=946 if year==2016 & tacn==2 & grappe==94



gen d=idacn if tacn==2
egen md=mean(d), by(grappe)
g diff=(md!=idacn) if tacn==2
egen turnover_acdn=max(diff), by(grappe)
drop d md
lab var turnover_acdn "=1 if site had change in ACDN between baseline and endline"


ta diff group if year==2016

g yeard=year if tacn==2
egen dd=min(yeard), by(grappe)
g baseline_acdn=(yeard==2014) 
drop dd yeard
lab var baseline_acdn "=1 if ACDN was interviewed at baseline"

* higher turnover T4 (5/25)
ta group turnover_acdn if year==2016 & tacn==2, row

drop diff num 
sort idacn year

rename ca01 acn_age
rename ca07 acn_marstatus
rename ca10 acn_nokids
rename cc03 acn_otheractivity
rename ca03a acn_edulevel

save "${All_create}ACN_All", replace

use  "${All_create}ACN_All", clear
keep grappe year tacn baseline_* turnover* idacn acn_age acn_marstatus ///
acn_nokids acn_otheractiv acn_edulevel acn_religion acn_wealth_index ///
act_curr_agri act_curr_trader act_bef_agri act_bef_trader act_bef_teacher ///
acn_knowledge_score acn_hygiene_score

* keep one observation per grappe (reshaped wide)
for var idacn acn_age acn_marstatus acn_nokids acn_otheractiv acn_edulevel ///
 acn_religion acn_wealth_index act_curr_agri act_curr_trader act_bef_agri ///
 act_bef_trader act_bef_teacher acn_knowledge_score acn_hygiene_score: g DX=X if tacn==2
 
for var idacn acn_age acn_marstatus acn_nokids acn_otheractiv acn_edulevel ///
acn_religion acn_wealth_index act_curr_agri act_curr_trader act_bef_agri ///
act_bef_trader act_bef_teacher acn_knowledge_score acn_hygiene_score: replace X=. if tacn==2

collapse idacn* acn* turnover_* baseline* D*, by(grappe year)
drop if grappe==.

sort grappe year
save  "${All_create}ACN_All_wide", replace



