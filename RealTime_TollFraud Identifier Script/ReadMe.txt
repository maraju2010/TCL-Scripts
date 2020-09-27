Business requirement: Toll Fraud was resulting into huge financial losses for the client. 
Requirement was to specifically identify malicious calls which were made from same ANI to same destination concurrently. And once identified block the destination, so that the same destination is not called again from any other phone.

Approach: Required a Real Time toll fraud check logic to identify these types of calls. Therefore a service script was created to keep track of all calls and identify malicious calls from it.

Configuration Steps:
1) checkcaller_v2.tcl script needs to be run under Dial-peer and will be invoked for every call.

2) blockcall_v5.tcl needs to be registered as service in Cisco GW. 
It will keep track of calls and based on logic built will return flag for blocking or allowing to checkcaller_v2.tcl script and  based on the flag call will be routed to service provider.
Please configure the script using below steps:
Config t
Application
Service new-ani flash:checkcaller_v2.tcl

Service data_service flash:blockcall_v5.tcl

# map service new-ani under dial-peer
Dial-peer voice <> voip
Incoming callednumber <>
Service  new-ani

#create session for service data_service   (please keep this name same as this name is reference in checkcaller_v2.tcl script )#
Call application session start <name of instance can be any word>  <data_service>

To stop session use command
Call application session stop name <name of instance to be stopped>
