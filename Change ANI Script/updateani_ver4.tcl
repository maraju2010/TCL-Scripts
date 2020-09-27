#Script Version: 4.0
#Script Name: updateani.tcl
#Script Lock Date: 08/08/2017
#Scipt Author:Manoj Raju

#This tcl script changes the ANI for every  call.#

proc init {} {

      global param
	  
}


proc ani_Lookup {} {
          global dnis
		  global ani
		  set dnis [infotag get leg_dnis]
		  set ani [infotag get leg_ani]
		  puts "dnis:$dnis ani: $ani"
		  leg setupack leg_incoming
		  set handle [infotag get mod_handle_service "data_service"]
		  puts "$handle"
		  if {$handle == "unavailable"} {
		         puts "mod_handle_service data_service is unavailable"
				 act_Abort
		         
	             
	 	  } else {
		      puts "mod_handle_service data_service is available"
		      set r [sendmsg $handle]
			  puts "Status $r"
		  }
		  
		  
		  
		 
}

proc ani_update {}  {
       
	   global ani
	   
	   set src [infotag get evt_msg_source]
	   
	   infotag get evt_msg data
	   
	   if {[info exists data(ani)] == 1} {
	           
			   set val $data(ani)
			   
	   
	   
	   } else {  
	   
	           set val $ani
	   	  	   
		}		      
   
	   return $val
	  	     
}


proc act_Setup {} {

        global dnis
		global ani			
        			
		
		# call another function and get ani returned
		set updateani [ani_update]
		
		# pass that ani to initiate setup of call
		set sip_string $updateani
		puts "updated ANI returned from lookup:$sip_string"		
		
		# parse DNIS 	
		
		regexp {[0-9]+} $dnis destination        
        set dnis $destination
		        
   		
		#update ani to sip outgoing request
		
		set callinfo(destinationNum) $dnis
        set callinfo(originationNum) $sip_string
		
	    leg proceeding leg_incoming
	    leg setup $dnis callinfo leg_incoming
     
}
proc act_CallSetupDone {} {

        global beep
		global ani 
		global dnis 
		
		set status [infotag get evt_status]
		
		puts "Entering act_CallSetupDone"
		
		if {$status == "ls_000"}  {
		         puts "Call from ANI=$ani to DNIS = $dnis got event $status and is successfully placed to destination"
	             
	 	} else {
		      puts "Call from ANI=$ani to DNIS = $dnis got event $status while placing an outgoing call"
		      call close
		}

}
proc act_Cleanup {} {
       puts "Entering act_Cleanup"
	   set status [infotag get evt_status]
	   
	   if {$status == "di_016"}  {
	             #leg disconnect leg_incoming
		         puts "Call is normally disconnected"
	             
	 	} else {
		      puts "Call is abnormally disconnected with $status"
			  #leg disconnect leg_incoming
		      call close
		}
	   call close

}
proc act_Abort {}  {
      puts "Aborting call"
	  leg disconnect leg_incoming
	  call close

}

requiredversion 2.1
init

#------------------------------
#       State Machine
#------------------------------
  set fsm(any_state,ev_disconnected)      "act_Cleanup,same_state"
  set fsm(CALL_INIT,ev_setup_indication)  "ani_Lookup,AWAITMSG"
  set fsm(AWAITMSG,ev_msg_indication)     "act_Setup,PLACECALL"
  set fsm(PLACECALL,ev_setup_done)        "act_CallSetupDone,CALLACTIVE"
  set fsm(CALLACTIVE,ev_disconnect_done)     "act_Abort,CALLDISCONNECTED"
  set fsm(CALLDISCONNECTED,ev_disconnect_done)   "act_Abort,same_state"
  
  fsm define fsm CALL_INIT