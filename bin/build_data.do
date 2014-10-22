// Stata code to combine, deidentify, and process raw student sleep data from Basis.
//
// By Chris Campos and Jeff Shrader
// Time-stamp: "2014-10-21 11:02:55 jgs"

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



////////////////////////////////
///// Dataset 1: All sleep /////
////////////////////////////////
// Get csv file names
local file_names : dir "`work'/data/raw/new" files "*.csv"

// Loop over files, saving each
foreach i of local file_names {
   // Grab date and ID
   quietly di regexm("`i'", "id_([0-9]+)_basis_sleep_([0-9]+-[0-9]+-[0-9]+)")
   local id = regexs(1) 
   local date = regexs(2)

   // Pull in data
	insheet using "`work'/data/raw/new/id_`id'_basis_sleep_`date'.csv", clear
   // Drop out of loop if there are no observations
   if c(N) == 0 {
      continue
   }
   
	rename type event 
   // Put things in stata datetime
   // The 17:00 is for PST, so I suppose this will require DST offsets at some point
   gen double time_start = start_tstamp*1000 + tc(31dec1969 17:00:00)
   gen double time_end = end_tstamp*1000 + tc(31dec1969 17:00:00)
   format time_start %tc
   format time_end %tc
   // A little testing of correct date
   gen double test_start = clock(start_dt, "20YMD hms")
   gen double test_end = clock(end_dt, "20YMD hms")
   assert test_end == time_end if test_end != .
   assert test_start == time_start if test_end != .

   /* Keep only the variables we are interested in; drop string dates */
   keep event time_start time_end duration

	/* Generates a column of subject_id variables before raw data is merged onto
	   master dataset	*/
	gen subject_id = `id'
	save "`work'/data/raw/new/id_`id'_basis_sleep_`date'.dta", replace 
}
// Make sure to drop the last csv file
clear

// Append files, first checking whether the base dataset exists
// Grab the new file list of .dta files
local file_names : dir "`work'/data/raw/new" files "*.dta"
// We can't make really long local names, so a little kludgy change directory here
cd "`work'/data/raw/new"
capture confirm file "`work'/data/sleep_all.dta"
if _rc==0 {
   //append using "`work'/data/sleep_all.dta" `file_names'
   append using `file_names'   
}
else {
   append using `file_names'
}
// Change back to our original directory
cd "`work'"
// This shouldn't be necessary, but dropping duplicates in case the new folder is
// not cleaned out
duplicates drop
save "`work'/data/sleep_all.dta", replace


//////////////////////////////////
///// Dataset 2: Daily sleep /////
//////////////////////////////////
use "`work'/data/sleep_all.dta", clear

// Debugging for crossing noon
//replace time_start = time_start - 12*60*60*1000 in 1/155
//replace time_end = time_end - 12*60*60*1000 in 1/155

gen double date_start = dofc(time_start)
gen double date_end = dofc(time_end)
format date_start %td
format date_end %td
gen hour_start = hh(time_start)
gen hour_end = hh(time_end)

// Create date
// note that it is day of sleep start, which corresponds to my lay notion that
// "Friday's sleep" is sleep that starts on Friday
sort time_start
gen date_sleep = date_start
format date_sleep %td
replace date_sleep = date_start - 1 if hour_start < 12
gen hour_sleep_start = hour_start
gen hour_sleep_end = hour_end
replace hour_sleep_end = hour_end + 24 if (hour_start < 12) | (hour_start >=12 & hour_end < 12)
replace hour_sleep_start = hour_start + 24 if hour_start < 12

// Handle events that span noon
// We will split these into two events, one on each day
gen span = (hour_sleep_end >= 36)
expand 2 if span == 1, generate(count)
// The second event belongs to the beginning of the next day
replace date_sleep = date_sleep+1 if span==1 & count==1
// Make the second event start at noon
replace time_start = cofd(date_start) + 12*60*60*1000 if span==1 & count==1
// Make the first event end at noon
replace time_end = cofd(date_end) + 12*60*60*1000 if  span==1 & count==0
// Redo hours
replace hour_sleep_start = 12 if span==1 & count==1
replace hour_sleep_end = hour_sleep_end-24 if span==1 & count==1
replace hour_sleep_end = 35 if span==1 & count==0
// Reset duration
replace duration = (time_end - time_start)/(1000*60) if span==1
drop count span

// Some error checking
assert hour_sleep_start <= hour_sleep_end
assert hour_sleep_start <= 35
assert hour_sleep_end <= 35

// Calculate sleep and other variables
bysort date_sleep subject_id: egen sleep = total(duration)
foreach i in "deep" "light" "rem" "unknown" {
   bysort date_sleep subject_id: egen sleep_`i' = total(duration) if event == "`i'"
}
gen tt = (event=="toss_and_turn")
bysort date_sleep subject_id: egen toss_turn = total(tt)
drop if event == "toss_and_turn"

bysort date_sleep subject_id: egen sleep_night = total(duration) if hour_sleep_start >= 12+7

// Incentivized sleep: starts after 7pm, is longest nighttime spell with a <40 minute gap
gen night = (hour_sleep_start >= 12+7)
drop if night == 0
bysort subject_id date_sleep (time_start): gen gap = (time_start != time_end[_n-1])
bysort subject_id date_sleep (time_start): gen gap_length = (time_start - time_end[_n-1])/(1000*60) 
// Sleep can't start on a gap
bysort subject_id date_sleep (time_start): replace gap_length = 0 if _n==1
// A sleep spell is continuous if the disruption is less than 40 minutes
bysort subject_id date_sleep (time_start): gen continuous = ((time_start == time_end[_n-1]) | gap_length <= 300) 
// Generate "spell IDs"
bysort subject_id date_sleep (time_start): gen spell_begin = ((continuous == 1 & continuous[_n-1] == 0) | _n==1)
bysort subject_id date_sleep (time_start): gen spell_id = sum(spell_begin)
// Calculate sleep per spell
bysort subject_id date_sleep spell_id (time_start): egen sleep_spell_start = min(time_start)
bysort subject_id date_sleep spell_id (time_start): egen sleep_spell_end = max(time_end)
gen sleep_spell_length = (sleep_spell_end - sleep_spell_start)/(1000*60)
bysort subject_id date_sleep: egen sleep_incent = max(sleep_spell_length)

collapse (mean) sleep sleep_incent sleep_night sleep_deep sleep_light sleep_rem sleep_unk toss_turn, by(subject_id date_sleep)
gen nap = sleep - sleep_night

sort subject_id
merge m:1 subject_id using "`work'/data/group.dta"
drop _merge
quietly: su date_sleep
replace date_sleep = r(min) if date_sleep == .

// Expand the dataset so we can get correct inference on days when people aren't sleeping
tsset subject_id date_sleep
tsfill, full
// Weekdays are Sunday through Thursday nights
gen dow = dow(date_sleep)
gen weekday = (dow < 5)

save "`work'/data/sleep_daily.dta", replace

// Clean up
cd "`work'/data/raw/new"
foreach i of local file_names {
   rm `i'
}
cd "`work'"

ttest sleep_incent, by(group)
table subject_id dow, c(mean sleep_incent)
table subject_id, c(mean sleep_incent)

log close
