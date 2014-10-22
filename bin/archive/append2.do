/**	append2.do
	INCOMPLETE
**/


capture program drop append2
program define append2
	use C:\Users\Chris\Desktop\Sleep_Data\master\test_master.dta, clear

	/*	Convert time from seconds after 01-01-1970 to seconds after 
		01-01-1960, and create variables for day of week, and hour */
	gen double stata_start_time = start_time*1000 + mdyhms(1,1,1970,0,0,0)
	gen double stata_end_time = end_time*1000 + mdyhms(1,1,1970,0,0,0)
	gen double date = dofc(stata_start_time)
	
	
	/* Create a dummy variable for incentivized sleep days */
	gen weekday = 1 if  0 <= dow & dow <= 4 
	replace weekday = 0 if dow > 4
	
	/* Total sleep broken down by REM, deep and light. Also total number of
		turns
		Needs correct date to be passed through 'by' statement
	*/
	egen sleep_REM = total(duration), by (event subject_id ) 
	egen sleep_deep = total(duration), by (event subjectt_id)
	egen sleep_light = total(duration), by (event subject_id)
	egen toss_turn = count(event), by(event subject_id)
	
	/*	Missing logic required to correctly aggregate incentivized sleep and 
		total sleep (in hours)
	*/
	//Code here
	
	/*	From here I would have use reshape command to correctly format
		data.
	*/
	//Code here
	
	save "C:\Users\Chris\Desktop\Sleep_Data\Master\test_master.dta",
	
end

	
	