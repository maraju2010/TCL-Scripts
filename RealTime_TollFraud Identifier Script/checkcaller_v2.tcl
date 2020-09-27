#Author: Manoj Raju
#Script Version: 1.0
#Script Name: Check_Caller_v1.tcl
#Script Lock Date: 11/23/2017


proc init {} {

      global param
	  global sigdigits
	  
	  # Check if param sigdigits is set
	  if {[infotag get cfg_avpair_exists sigdigits]} {
		set  sigdigits [infotag get cfg_avpair sigdigits]		
      } else {
		set  sigdigits "0"
	  }
	  
}

proc dcall_Lookup {} {

      global index
      global dnis
      global ani
      regexp {[0-9]+} $ani cani
      set did(decr) $index
	  set did(dani) $cani
	  set handle [infotag get mod_handle_service "data_service"]
	  set r [sendmsg $handle -p did]
}

proc caller_Lookup {} {
      
	  # based on setup event this procedure is called.
	  #the procedure extracts dnis and ani ,inserts into array pid and send this to blockcall script.
	  
	  global dnis
      global ani
	  global sigdigits
      global start	  
	  set dnis [infotag get leg_dnis]
	  set ani [infotag get leg_ani]
	  puts "dnis:$dnis ani: $ani"
	  
	  if {$sigdigits > 0} {
	       set start 0
	       regexp {[0-9]+} $dnis sigdnis
	       set strlen [string length $sigdnis]
		   incr start $sigdigits
		   set dnis [string range $sigdnis $start $strlen]
	  }	
	  
	  regexp {[0-9]+} $dnis dn1
	  regexp {[0-9]+} $ani  an1
	  set pid(dn) $dn1
	  set pid(an) $an1
	  leg setupack leg_incoming
	  set handle [infotag get mod_handle_service "data_service"]
	  
	  puts "$handle"
	  if {$handle == "unavailable"} {
		      puts "mod_handle_service data_service is unavailable"
			  act_Abort
		         
	             
	  } else {
		      puts "mod_handle_service data_service is available"
		      set r [sendmsg $handle -p pid]
			  puts "Status $r"
	  }	  
		 
}

proc caller_update {}  {
      
	  #this procedure checks value returned from block script.
	  
	  global ani
	  global index 
	   
	  set src [infotag get evt_msg_source]
	   
	  infotag get evt_msg data
	   
	  if {[info exists data(nomal)] == 1} {
	   
	         set val $data(nomal)
			 set index $data(count)
			   
	  } else {  
	   
	         set val 0	                
	   	  	   
	  }		      
   
	  return $val	     
}


proc act_Setup {} {

    
	  # After control returns this proc is called, caller is either blocked or proceeds based on return value from block script.
	  global dnis
	  global ani	
	  
	  set doblock [caller_update]
	  if {$doblock == 1} {
		
		   puts "suspect malicious call"
		   dcall_Lookup		   
		   leg disconnect leg_incoming	-c 1
	       fsm setstate CALLDISCONNECTED
		   set curdate [clock format [clock seconds] -format "%m-%d-%y--%H:%M:%S"]
		   log -s INFO "Malicious Calls found from ANI=$ani going to Destination=$dnis at time=$curdate"
		   call close		   
		   
	  } else {
           set dnis [infotag get leg_dnis]	  
           puts "good call - proceeding"
           regexp {[0-9]+} $dnis destination           		   
	       leg proceeding leg_incoming
	       leg setup $destination callinfo leg_incoming
	  }
     
}
proc act_CallSetupDone {} {

      global beep
	  global ani 
	  global dnis 
		
	  set status [infotag get evt_status]
		
	  puts "Entering act_CallSetupDone"
		
	  if {$status == "ls_000"} {
		     puts "Call from ANI=$ani to DNIS = $dnis got event $status and is successfully placed to destination"
	             
	  } else {
	  
		     puts "Call from ANI=$ani to DNIS = $dnis got event $status while placing an outgoing call"
			 
			 # dcall_Lookup is called to remove entry from array in blockcall script.
			 
			 dcall_Lookup
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
		      
	   }
	    # dcall_Lookup is called to remove entry from array in blockcall script.
	   dcall_Lookup
	   call close

}
proc act_Abort {}  {

      puts "Aborting call"
	  #leg disconnect leg_incoming	  
	  call close

}


init

#------------------------------
#       State Machine
#------------------------------
  set fsm(any_state,ev_disconnected)      "act_Cleanup,same_state"
  set fsm(CALL_INIT,ev_setup_indication)  "caller_Lookup,AWAITMSG"
  set fsm(AWAITMSG,ev_msg_indication)     "act_Setup,PLACECALL"
  set fsm(PLACECALL,ev_setup_done)        "act_CallSetupDone,CALLACTIVE"
  set fsm(CALLACTIVE,ev_disconnect_done)     "act_Abort,CALLDISCONNECTED"
  set fsm(CALLDISCONNECTED,ev_disconnect_done)   "act_Abort,same_state"
  
  fsm define fsm CALL_INIT