#Author:Manoj Raju
#Script Version: 3.0
#Script Name: servicescript.tcl
#Script Lock Date: 08/04/2017

#Date:12/07/2017 Modified Datetime format %d and wordlist with split function "," to allow  reading of comma separated entries 

proc act_Session {} {

          
	   init_data
	   
	   set  r [service register data_service]
	   puts "service register return status $r"
       read_ani 0

}

proc init_data {} {

      
	  global data
	  global call_count
	  set call_count(count) 0 
	  
}


proc read_ani {a} {
    global i
    global currentdt
    global call_count
    global day
    global number 
    global initialized
    global tdate
    global filename	
    set mydate [clock format [clock seconds] -format "%m%d%Y"]	
    puts "$mydate"
		
	
    if {$a == 0} {
	
	        set currentdt 01012079
	        set initialized 0
			
			if {[infotag get cfg_avpair_exists filename]} {	
			
			     set filename  [infotag get cfg_avpair filename]
				 
			} else {
			
			     set filename "flash:filename.txt"
			}
			
	        puts "reading ani from file in process"
			
			if {[catch {set fp [open $filename r]} error ]} {
			
			       puts "file cannot be read"
				   act_Terminate 
			
			} else {
            
                  set file_data [read $fp]
                  set data [split $file_data "\n"]	         
	        
	              foreach line $data {
	                  set wordcount 0
	                  set wordlist [regexp $line ","]
				 
		              foreach item $wordlist {
			               if { $wordcount == 0 } {
						 
			                     set b [regexp -inline -all {[0-9]+} $item]
			                     set m [lindex $b 0]
			                     set d [lindex $b 1]
			                     set y [lindex $b 2]
			                     set day $m$d$y					     
							   
							   
			                } elseif {$wordcount == 1} {
					 
			                      set number $item
			                      puts "$number"
					 
			                } else {
						        
			                      set tdate($day,$number) $item				
						    								
			                }

		                  set wordcount [expr $wordcount+1]

		               }
			
	             }
				 
				 
			  close $fp			
			  set initialized 1
			  puts "loaded ani into array -- process completed" 
			
		    }	
			
			
    } else {
	        
	        
	    if {$currentdt != $mydate} {
	            set i 0
				set currentdt $mydate
                puts "counting ani for current date"				
	            foreach n [array names tdate] {
			         
			         regexp {[0-9]+} $n dt
			         if {$dt == $mydate} {	
				        
			            incr i
					  
			         } 
		        }
	    }
					
	
	     incr call_count(count)
	     set counter $call_count(count)
			
	     puts "counter is $call_count(count)"
	     puts "counter after change is $counter"
			
						
	    if {$counter > $i} {
		        init_data
                incr call_count(count)
                if { [catch { set uani $tdate($mydate,1) } error] }	{			
       	                   set uani 0
                }				
		
	    } else {
		
			  if {[catch { set uani $tdate($mydate,$counter) } error ]} {
	                   set uani 0         				  
			  }  
			
        }
		
	    return $uani
		
     }
}


proc act_Rxmessage {}  {            
			
		global data
        set src [infotag get evt_msg_source]			
		set newani [read_ani 1]
		puts "$newani"
		if {$newani == 0} {
		     set data(noani) $newani
		     set r [sendmsg $src -p data]
			 puts "Status $r with $newani"
			 
		} else {
		
            set data(ani) $newani
		    set r [sendmsg $src -p data]
		    puts "Status $r"
			
        }		
			
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