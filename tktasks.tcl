#!/usr/local/bin/wish

#package require -exact Tk $tcl_version
package require Tk 8.4

puts ""
puts ""
puts "---------------------------------------"
puts "Released under GPLv3.0"
puts "Copyrights © 2022-2026 Daniele Bonini"
puts "This software is supplied AS-IS, without WARRENTY."
puts "Welcome in TKTASKS!!"
puts "---------------------------------------"
puts ""
puts ""

cd /home/user/util/tkbin

# Variable and Proc declarations

variable taskdate 
variable taskfile
variable lbcursel
array set cmdslbl {}
array set cmds {}

proc setLabel { idx } {

    global lbltext
    global cmdslbl
    global cmds
    global lbcursel

    set lbcursel $idx

    set val ""
    if {$idx >= 0 && $idx < [array size cmds] && [array size cmds] > 0} {
      set val $cmds($idx)
      set lbltext $val  
    } else {
      if {[array size cmds] > 0} {
        set lbltext ""
      } else {
        set lbltext "taks description"
      }  
    }
          
    if {"[string range $val 0 2]"!=""} { 
      #place .fr.bexec -x 20 -y 237
      #place .fr.bclose -x 120 -y 237
      #tk_messageBox -message "Really? [string range $val 0 2]"
            
      if {"[string range $cmdslbl($idx) 0 0]" == "#"} {
        .fr.bexec configure -width 7 -text "ToDo" -command { reTask "" }    
      } else {
        .fr.bexec configure -width 7 -text "Complete" -command { reTask "#" }
      }
      grid configure .fr.bexec -column 1 -columnspan 2 -row 5 -rowspan 1
      grid .fr.bexec -sticky sw -ipadx 0 -padx 0 -pady 40
      grid .fr.bclose -sticky sw -ipadx 20 -padx 90 -pady 40
      
    } else {  
      place forget .fr.bexec
      #grid .fr.bexec -sticky e -padx 1000
      grid .fr.bclose -sticky sw -ipadx 20 -padx 0 -pady 40
      #place .fr.bclose -y 20
    }
}

proc scanDate {} {

    global datepattern
    global taskdate
    global taskfile
    global cmdslbl
    global cmds
    
    #tk_messageBox -message "Really? [clock format [clock scan $datepattern] -format '%d/%m/%Y']"

    if {$datepattern == ""} {
      return
    } 

    set dateresult 0
    catch {set dateresult [catch [clock format [clock scan $datepattern] -format '%d/%m/%Y']]}
    if {$dateresult != 0 } {
      #tk_messageBox -message "[clock format [clock scan $datepattern] -format '%d/%m/%Y']"
      set taskdate "[clock format [clock scan $datepattern] -format %Y-%m-%d]"
    } else {
      tk_messageBox -message "Error!"
      return
    }

    # Resetting arrays and listbox
    if {[array size cmdslbl] > 0} { 
      array set cmdslbl {}
    }  
    if {[array size cmds] > 0} { 
      array set cmds {}
    }  
    if {[.fr.lb size] > 0} {
      .fr.lb delete 0 [ .fr.lb size ]
    }  

    if { [file exists "tktasks_$taskdate.ini"] == 0 } {
      .fr.lb insert end "No scheduled task for that date."
      tk_messageBox -message "No scheduled task for that date."
      return
    }

    set taskfile "tktasks_$taskdate.ini"

		# Reading tasks list
		set fh [open $taskfile "r"]

		set intli 0
		set li 0
		while {[gets $fh str] >= 0} {

			#if {"[string range $str 0 0]" == "\#"} {
			#  continue
			#}
			
			set i [string first "=" $str 0]
			set newcmd [string range $str 0 $i-1]
			set newcmdpath [string range $str $i+1 [string length $str]]

			set cmdslbl($intli) $newcmd
			set cmds($intli) $newcmdpath
			
			.fr.lb insert end $cmdslbl($intli)
			
			incr intli
			
		}
		close $fh

		# DEBUG
		#foreach {cmd cmdpath} [array get cmds "0"] {
		#  tk_messageBox -message "Command: $cmd Path: $cmdpath" -type ok
		#}
		#foreach {cmd cmdpath} [array get cmds] {
		#  tk_messageBox -message "Command: $cmd Path: $cmdpath" -type ok
		#}

}

proc reTask { flag } {

    global cmdslbl
    global cmds
    global lbcursel
    global taskfile
    
    set curtask $cmdslbl($lbcursel)
    
    #if {"[string range $curtask 0 0]"!="#"} {
    
      if {$flag == "#"} { 
        set newcmd "$flag$curtask"
      } else {
        set newcmd [string range $curtask 1 [string length $curtask]]
      }  
      set cmdslbl($lbcursel) $newcmd
      
      # Writing the new tasks list
      set fh [open $taskfile.new {WRONLY CREAT EXCL} "0777"]
      
      for {set i 0} {$i<[array size cmdslbl]} {incr i} {
        set newline "$cmdslbl($i)=$cmds($i)"
        
        puts $fh $newline
      }
      
      close $fh      
            
      file rename -force $taskfile.new $taskfile

      .fr.lb delete $lbcursel
      .fr.lb insert $lbcursel $newcmd
            
    #}  
}

proc shutdown {} {
    # perform necessary housework for ensuring that application files
    # are in proper state, lock files are removed, etc.
    
    puts stdout "Good Bye, from TKTASKS.."
    
    exit
}

# Main Frame
frame .fr
pack .fr -fill both -expand 1

set today [clock seconds]
set datepattern [clock format $today -format "%d %B %Y"]
entry .fr.txt -width 65 -textvariable datepattern
button .fr.bscan -height 1 -text "Scan Tasks" -command { scanDate }

listbox .fr.lb -yscrollcommand { .fr.sb set }
place .fr.lb -height 120
scrollbar .fr.sb -command {.fr.lb yview} -orient vertical

# ListBox
bind .fr.lb <<ListboxSelect>> { setLabel [%W curselection]}

# Label
set lbltext "task description"

label .fr.lbl -justify left -wraplength 575 -textvariable lbltext

# Exec Button
button .fr.bexec -width 7 -text "Complete" -command { completeTask }

# Close Button
button .fr.bclose -text "Exit" -command { shutdown }
grid .fr.bclose -sticky sw -ipadx 20 -padx 0 -pady 40 

# Set frame and controls position
grid configure .fr -row 0 -rowspan 6 -column 0 -columnspan 4
grid configure .fr.txt -column 1 -columnspan 2 -row 0 -rowspan 1
grid configure .fr.bscan -column 2 -columnspan 1 -row 0 -rowspan 1
grid configure .fr.lb -column 1 -columnspan 2 -row 1 -rowspan 1
grid configure .fr.sb -column 2 -columnspan 1 -row 1 -rowspan 1
grid configure .fr.lbl -column 1 -columnspan 2 -row 2 -rowspan 3
#grid configure .fr.bexec -column 1 -columnspan 2 -row 5 -rowspan 1
grid configure .fr.bclose -column 1 -columnspan 2 -row 5 -rowspan 1
grid .fr.txt -sticky w
grid .fr.txt -ipadx 20 -pady 10 -ipady 5
grid .fr.bscan -sticky e
grid .fr.lb -sticky nsew
place .fr.sb -width 5
grid .fr.sb -sticky nes
grid .fr.lb -ipadx 20 -pady 20 -columnspan 2
grid .fr.sb -ipadx 5 -padx 1 -pady 20 
#grid .fr.bexec -sticky sw -pady 40
grid .fr.bclose -sticky sw -ipadx 20 -padx 0 -pady 40
grid .fr.lbl -sticky w
grid .fr -sticky w -padx 20
#grid columnconfigure .fr 0 -weight 1

# Window
wm title . "Tasks"
image create photo imgobj -file tktasks.png
wm iconphoto . imgobj
wm resizable . 0 0
wm attributes . -fullscreen 0
wm geometry . 600x420
wm protocol . WM_DELETE_WINDOW { shutdown }

