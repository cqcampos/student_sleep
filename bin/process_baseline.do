// Stata code to process the baseline survey
//
// By Jeff Shrader
// Time-stamp: "2014-10-13 10:30:34 jgs"

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
log using "`work'/logs/process_baseline.log", replace
set more off

insheet using "`work'/data/raw/baseline_survey.csv", clear
rename pleaseenteryouruserid subject_id
rename duringthepastmonthhowmanyhoursof sleep_base
replace sleep_base = "9.5" if sleep_base == "more than 8, 9-10 hours"
replace sleep_base = "10.5" if sleep_base == "10 1\2 hours"
replace sleep_base = "6.5" if sleep_base == "6-7" | sleep_base == "6.5 hours" | sleep_base == "6.5hours" | sleep_base == "6hr30min"
replace sleep_base = "7" if sleep_base == "7 hr"
replace sleep_base = "8.25" if sleep_base == "8 - 8.5 hrs"
replace sleep_base = "8.5" if sleep_base == "8-9"
replace sleep_base = "9" if sleep_base == "9 hours" | sleep_base == "9 hrs"
replace sleep_base = "10" if sleep_base == "10 hours"
replace sleep_base = "6" if sleep_base == "6hrs"
destring sleep_base, replace
replace sleep_base = sleep_base/60 if sleep_base == 480

sort subject_id
save "`work'/data/baseline_survey.dta", replace
