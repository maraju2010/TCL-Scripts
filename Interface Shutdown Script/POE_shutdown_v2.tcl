::cisco::eem::event_register_syslog occurs 1 pattern $_syslog_pattern

#------------------------------------------------------------------
#Author : manoj Raju
#reference: modified cisco's default EEM script to solve business issue.
# EEM policy to monitor for a specified syslog message.
# Designed to be used for syslog POE interface-down messages.  
# When event is triggered, the given config commands will be run.
#
# July 2005, Cisco EEM team
#
# Copyright (c) 2005 by cisco Systems, Inc.
# All rights reserved.
#------------------------------------------------------------------

### The following EEM environment variables are used:
###event manager environment _syslog_pattern .*ILPOWER-5-IEEE_DISCONNECT.*PD removed$ 
###
### _syslog_pattern (mandatory)        - A regular expression pattern match string 
###                                      that is used to compare syslog messages
###                                      to determine when policy runs 
### Example: _syslog_pattern             .*ILPOWER-5-IEEE_DISCONNECT.*PD removed$
###
###_pattern_counter					   -  A counter environment variable to set no of counts 
###
###




namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

# query the information of latest triggered eem event
# Set array for event_reqinfo
# Array is populated with additional event information
#http://www.cisco.com/en/US/docs/ios/netmgmt/configuration/guide/nm_eem_policy_tcl.h
#tml#wp1041216

array set Syslog_info [event_reqinfo]
set msg $Syslog_info(msg)
action_Syslog msg "poe down event received $msg"
set counter 0

if {$_cerrno != 0} {
    set result [format "component=%s; subsys err=%s; posix err=%s;\n%s" \
      $_cerr_sub_num $_cerr_sub_err $_cerr_posix_err $_cerr_str]
    error $result 
}

#fetch interface ID from msg string to validate counter.
set substr1 [regexp -inline -all {Gi(.*?):} $msg]
set ID [lindex $substr1 1]

#verify if no of occurences for the port is greater than environment variable _pattern_counter.
if {[info exists portcounter($ID)]} {		
		set counter $portcounter($ID) 		
		incr counter		
		set portcounter($ID) $counter
		action_Syslog msg "incremented counter for $_config_cmd1 to $counter"
} else {	
	set portcounter($ID) 1
}

if {$counter >= $_pattern_counter} {
	set counter 0
	action_Syslog msg "detected more than $_pattern_counter POE_down counts for interface $_config_cmd1"
	#fetch interface ID from msg string to send command to switch
	set substr [regexp -inline -all {\_DISCONNECT:(.*?):} $msg]
	set _config_cmd1 [lindex $substr 1]
	set _config_cmd2 "shutdown"
	set _config_cmd3 ""
	

#
# ------------------- cli open -------------------
#

if [catch {cli_open} result] {
    error $result $errorInfo
} else {
    array set cli1 $result
} 

#
# ------------------- cli Execute commands -------------------
#

if [catch {cli_exec $cli1(fd) "enable"} result] {
    error $result $errorInfo
} 
if [catch {cli_exec $cli1(fd) "config t"} result] {
    error $result $errorInfo
} 
 
if [catch {cli_exec $cli1(fd) $_config_cmd1} result] {
    error $result $errorInfo
} 
    

if [catch {cli_exec $cli1(fd) $_config_cmd2} result] {
    error $result $errorInfo
} 
 

if [catch {cli_exec $cli1(fd) $_config_cmd3} result] {
    error $result $errorInfo
} 
  
if [catch {cli_exec $cli1(fd) "end"} result] {
    error $result $errorInfo
} 

#
# --------------------- cli close ------------------------
#

if [catch {cli_close $cli1(fd) $cli1(tty_id)} result] {
    error $result $errorInfo
} 

set portcounter($ID) $counter
 
#after 60000
# 3. send the notification email
#set routername [info hostname]
#if {[string match "" $routername]} {
#   error "Host name is not configured"
#}

#if [catch {smtp_subst [file join $tcl_library email_template_cfg.tm]} result] {
#    error $result $errorInfo
#}
#if [catch {smtp_send_email $result} result] {
#    error $result $errorInfo
#}
#The following e-mail template file is used with the EEM sample policy above:
#email_template_cfg.tm
#Mailservername: $_email_server
#From: $_email_from
#To: $_email_to
#Cc: $_email_cc
#Subject: From router $routername: Periodic $_show_cmd Output
#$cmd_output


}
