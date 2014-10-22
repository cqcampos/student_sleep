/*** append1.do
	 
	 References data from raw data directory (which I will download to my 
	 laptop?), and merges with test.dta in Master folder. 
	 
	 Note: Not the cleanest code I have ever written, but this is what I 
	 managed to do by playing around with Stata for a little over an hour. 
	 I will clean it up as I go along. 
***/

capture program drop append1
program define append1
	import delimited C:\Users\Chris\Desktop\Sleep_Data\id_`1'_basis_sleep_2014-`2'-`3'.csv, clear
	save "C:\Users\Chris\Desktop\Sleep_Data\id_`1'_basis_sleep_2014-`2'-`3'.dta", replace
	
	/* Keep only the variables we are interested in; drop string dates 
	   Rename variables to desired names	
	 */
	keep start_tstamp end_tstamp duration type
	rename type event 
	rename start_tstamp start_time
	rename end_tstamp end_time
	
	/* Generates a column of subject_id variables before raw data is merged onto
	   master dataset
	*/
	gen subject_id = `1'
	save "C:\Users\Chris\Desktop\Sleep_Data\id_`1'_basis_sleep_2014-`2'-`3'.dta", replace 
	
	/* Appends raw dta to master */
	use "C:\Users\Chris\Desktop\Sleep_Data\Master\test_master.dta"
	append using C:\Users\Chris\Desktop\Sleep_Data\id_`1'_basis_sleep_2014-`2'-`3'.dta
	save "C:\Users\Chris\Desktop\Sleep_Data\Master\test_master.dta", replace
end

/* This is what I used to test the code. I will most likely change the way it 
   the function is ran. 
*/
append1 31 08 28
append1 31 08 29
append1 31 08 30
append1 31 08 31
append1 31 09 01
append1 31 09 02
append1 31 09 03
append1 34 09 23
append1 34 09 24
append1 34 09 25

