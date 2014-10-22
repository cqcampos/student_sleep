// Creating a dataset of weekly values for incentive determination
//
// By Jeff Shrader
// Time-stamp: "2014-10-19 21:10:06 jgs"

/////////////////////////
///// Preliminaries /////
/////////////////////////
clear
if (c(os) == "MacOSX" | c(os) == "Unix") & c(username) == "jgs" {
	local work "~/google_drive/research/projects/active/student_sleep"
   cd `work'
}
else {
	//local work "/home/koren/Dropbox/ATUS_project"
}
capture log close
log using "`work'/logs/build_data.log", replace
set more off

//////////////////////////
///// Weekly dataset /////
//////////////////////////
// Bring in the daily dataset, and generate a report for each week of the study  
use "`work'/data/sleep_daily.dta", clear

// Incentivized days are 0 (Sunday) through 4 (Thursday)
bysort subject_id dow (date_sleep): gen week_id = _n
// Mondays and Sundays werent observed the first week
replace week_id = week_id+1 if dow == 1 | dow == 0

bysort week_id: table subject_id dow, c(mean sleep_incent mean sleep) missing
bysort week_id: table subject_id dow, c(mean sleep_incent) missing

// Incentives for M group are simply for wearing each night
gen temp = (sleep_incent>0 & sleep_incent != .) if inrange(dow,0,4)
replace temp = 0 if temp == .
bysort subject_id week_id: egen incentive_wear = min(temp) if inrange(dow,0,4)
drop temp
bysort week_id: table subject_id if group == "M", c(mean incentive_wear) missing

// For T group, it is based on the value of sleep
gen temp = (sleep_incent>=480 & sleep_incent != .) if inrange(dow,0,4) & group=="M"
replace temp = 0 if temp == .
bysort subject_id week_id: egen incentive_sleep = min(temp) if inrange(dow,0,4)
bysort week_id: table subject_id if group == "T", c(mean incentive_sleep) missing
drop temp
