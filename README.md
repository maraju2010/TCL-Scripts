# Change ANI TCL Script

Business requirement: To determine correct ANI to apply for the call based on the 
ANI used by last call.Typically useful for tele-marketing cases.

Limitation: Cisco dialer does not provide options to change ANI based on last ANI condition.
Tcl scripts running on dial peer level also does not have API to track the last ANI used for a call.

Approach: Create a service Tcl script to keep track of ANI's used and therefore it can determine the correct ANI for the call. The dial peer tcl script will call service tcl script to get the correct ANI.

Configuration Steps:
1) Updateani.tcl script needs to be run under Dial-peer and will be invoked for every call.

2) servicescript3.tcl needs to be registered as service in Cisco GW. 
It will keep track of calls and based on counter will return distinct ANI for every call to updateani.tcl script which will be further utilized and insertedinto sip headers.

Please configure the script using below steps:
Config t
Application
Service new-ani flash:updateani.tcl

Service data_service flash:servicescript3.tcl

# map service new-ani under dial-peer
Dial-peer voice <> voip
Incoming callednumber <>
Service  new-ani

#create session for service data_service   (please keep this name same as this name is reference in updateani.tcl script )#
Call application session start <name of instance can be any word>  <data_service>

To stop session use command
Call application session stop name <name of instance to be stopped>
  
  
  
 #Interface Shutdown TCL Script
 Business requirement: To identify poe down event and shutdown interfaces on which poe event was received.This was required to solve a switch issue wherein after poe failures on multiple interfaces cisco catalyst switch use to crash triggering complete downtime.
