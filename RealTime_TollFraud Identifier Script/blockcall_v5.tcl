#Manoj Raju
#Script Version: 1.0
#Script Name: blockcall_v3.tcl
#Script Lock Date: 11/23/2017


proc act_Session {} {
    
	#this procedure is called at "call application session start command"
	init_data	   
	set  r [service register data_service]
	puts "service register return status $r"	   
   
}

proc init_data {} { 

    # this proc initializes global variables.
	global data
	global call_count
	global counter
	global listdnis
	global dncount
	global currentdt
	global mydate
	global patterndig
	global rdndig
	global rcdndig
	set currentdt 01012079
	set mydate [clock format [clock seconds] -format "%m%d%Y"]
	set counter  0
	set dncount 0	
	set listdnis("NA","NA") 0
	load_file
	
	if {[infotag get cfg_avpair_exists pattern]} {	
			
			  set patterndig  [infotag get cfg_avpair pattern]
			  set rdndig [expr $patterndig - 1]
			  set rcdndig [expr $patterndig + 1]
				 
	  } else {
			
			 set patterndig 0
	  }
	  
}

proc act_Rxmessage {}  {
    
	# this proc is called from "Check_Caller" script. This script retrieves dnis and ani and inserts into array in format (index,ani dnis).
	#The index item from array is deleted when calls gets disconnected.
	#This proc detects malicious caller based on ANI and DNIS with Active state combination.Once detected ,DNIS is inserted into permanent block list for future calls.
	
    global blockdnis
    global i	
    global callid
	global leg_count
	global counter
	global listdnis
    global noloop
    global dncount
	global cct
	global val1 
	global val2
	global whitelistid    
			
	set src [infotag get evt_msg_source]
	    infotag get evt_msg pid
	    infotag get evt_msg did			
			
	if {[info exists pid(an)] == 1} {
	    
		set noloop 0
	    set uani 0
        set i 0			   
	    set mydate [clock format [clock seconds] -format "%m%d%Y"]
	    puts "this is mydate $mydate"
	    set val1    $pid(an)
		set val2    $pid(dn)		
			  		   
		foreach {destno destct} [array get blockdnis] {
			   
			    if {$destno == $val2 } {				
					  set uani 1
					  set noloop 1					
			    }			   
		}
	           		    
		if {$noloop == 1} {
			  
			 puts "forloop skipped"
			   
	    } else {
			   
			 incr counter
			 #set listdnis($mydate,$val1) $val2
			 set listdnis($counter,$val1) $val2
			 puts "this is dnislist listdnis"  
			 set cct 0                 		 
  			 foreach n [array names listdnis] {
			         
			    set b [regexp -inline -all {[0-9]+} $n]
				if {[llength $b]== 0} {
					 
					    puts "no items left in b"
					 
				} else {
					   puts "this is b $b"
					   # set dt [lindex $b 0]
					   set ct [lindex $b 0]
			           set orignum [lindex $b 1]
	                   set dest $listdnis($ct,$orignum)
			           puts "this is count $ct"
					   puts "this is dest $dest "
					   puts "this is orignum $orignum"
					   puts "this is val1 $val1 "
					   puts "this is val2 $val2"
					   #comment out destination number check-customer email Mar 5 2018
			           #if {$val2 == $dest} {
        				    if {$val1 == $orignum} {
				               #set dtdiff [expr $mydate - $dt]							   
			                   if {$cct >= 1 } {
							          puts "i::$i"
							          incr i										
							    }						  
                                incr cct
								puts "cct::$cct"
					        }				   
						   
                        #}
					   
                    } 					  
					 
			    }
        }

		        			
	    if {$i >= 1} {
			
			 set uani 1					 
		     incr dncount
		     set blockdnis($val2) $dncount			
	    }
			
		if {$uani == 0} {
			       
			 set data(nomal)  $uani
		     set data(count) $counter
			 set r [sendmsg $src -p data]
			 puts "Status $r"
					
	    } else {		
			 
             set rwhitelistid [whitelist]
			 if {$rwhitelistid == 1} {			 
			        set uani 0
					if {[catch {unset blockdnis($val2)} error ]} {
				           puts "catched error while removing item from blockdnis"
			        }                    					
			 }		 
			 set data(nomal) $uani
		     set data(count) $counter
			 set r [sendmsg $src -p data]
		     puts "Status $r"
			 
	    } 			
 
	} elseif {[info exists did(decr)] == 1} {
	        puts ""
	        set decrct $did(decr)
		    set decani $did(dani)
		    if {[catch {unset listdnis($decrct,$decani)} error ]} {
				puts "catched error while removing item from listdnis"
			}
	   	  	   
	}  else {
	
		    puts "no data received"	
			
	}
	
		
}


proc load_file {} {
      
	  global whitelist
	  global currentdt
	  global mydate
	  
	  
	  if {[infotag get cfg_avpair_exists filename]} {	
			
			  set filename  [infotag get cfg_avpair filename]
				 
	  } else {
			
			 set filename "flash:filename.txt"
	  }
	  
	  if {[catch {set fp [open $filename r]} error ]} {
			
			 puts "file cannot be read"
			
	  } else {
      
             set file_data [read $fp]
			 puts "loading from file ------>$file_data"			 
			 set data [split $file_data "\n"]
			 set number 0
			 foreach line $data {

				puts $number
				set $line [string trimleft $line]
				set whitelist($line) $number   
				incr number
				
             }
			 
			 set currentdt $mydate
			 close $fp
	  }	   
      
    
}

proc whitelist {} {

      global currentdt
	  global mydate
	  global val1 
	  global val2
      global whitelistid	  
	  global whitelist
	  global rdndig
	  global rcdndig
	  global patterndig
	  
	  set mydate [clock format [clock seconds] -format "%m%d%Y"]	  
	  if {$currentdt != $mydate} {
	  	    
			load_file			
	  } 
	  
	  set whitelistid 0
      set whdnis $val2	  
	  regexp {[0-9]+} $whdnis  ndnis
	  set idn [string trimleft $ndnis 0]
      set strlen [string length $idn]
	  
	  puts  "parsed dnis----->$idn"
      puts "length of dnis---->$strlen" 
   
      if {$patterndig > 0} {       
         set rdn [string range $idn 0 $rdndig]  
	  } else {
	       set rdn 0
	  }  
	  if {[info exists whitelist($rdn)] == 1} {
	          puts "check for pattern------------->$rdn"
			  set whitelistid 1
	    	  puts "pattern match $rdn"		  
					
	  } elseif  {[info exists whitelist($idn)] == 1}  {			 
			  set whitelistid 1
			  puts "pattern check returned null---> check for full DN match"	
			  puts "full DN match $whitelist($idn)"			        
			  
	  } else {
 	          
			  if {$strlen >10} {
			      puts "full DN match failed--->strip country code and check"
			      if {$strlen==11} {
				      set ccdn [string range $idn 1 $strlen]
				  } else {
				      set ccdn [string range $idn 2 $strlen]
				  }	  
				  
			      if {[info exists whitelist($ccdn)] == 1} {
                      set whitelistid 1
                      puts "full DN match w/o CC $whitelist($ccdn)"			
	              } else {
			          puts "Full DN w/o cc failed---->check Pattern w/o cc"
					  if {$patterndig > 0} {
                            if {$strlen==11} {
                                 set rcdn [string range $idn 1 $rcdndig]
                            } else {							
				                 set rcdn [string range $idn 2 $rcdndig]
						    }		 
				            if {[info exists whitelist($rcdn)] == 1} {				   
				               set whitelistid 1
						   	   puts "Pattern match w/o cc $whitelist($rcdn)"
				            }
					  }
				   
			      }
              } 			  
	  }	
	  
	  return $whitelistid

}


proc act_Terminate {}  {
           
		   puts "closing the session"
		   call close

}





#------------------------------
#       State Machine
#------------------------------
  
  set fsm(any_state,ev_session_indication)  "act_Session  same_state"
  set fsm(any_state,ev_session_terminate)   "act_Terminate same_state"
  set fsm(any_state,ev_msg_indication)      "act_Rxmessage  same_state"
  
  
  fsm define fsm start_state