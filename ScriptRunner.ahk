/*
This script is intended as a framework to run components and does not have any
stand alone function. The components should have a .part extension, they should
have an autoexecute subroutine called %componentName%_Auto and an exit routine
called %componentName%_Exit. Use of global variables and unprefixed function/subroutine
names should be kept to a minumum to avoid conflicts. If a component must save data
in the global namespace, it should initilaze the A_Properties.%componentName% obect.
*/

;------------------------
;DIRECTIVES
;------------------------

#InstallKeybdHook
#InstallMouseHook
#UseHook
#SingleInstance, Off
#Persistent
#NoEnv
#Warn, all, StdOut

;-------------------------------
;AUTO-EXECUTE SECTION
;-------------------------------

SetBatchLines, -1

;object that contains properties that can be read and modified by any component
A_Properties := {}

;single instance - get a handle to a mutex and try to get ownership 10
; times with a three second timeout
A_Properties.mutex := DllCall("CreateMutex", "UPtr", 0, "Ptr", 1, "Str", A_ScriptName)
loop
{
	if (DllCall("WaitForSingleObject", "UInt", A_Properties.mutex, "UInt", 3000))
	{
		if (A_Index <=10)
		{
			A_Properties.mutex := DllCall("CreateMutex", "UPtr", 0, "Ptr", 1, "Str", A_ScriptName)
			TrayTip, Loading %A_ScriptName%, Attempt %A_Index% of 10 failed.
		}
		else
		{
			MsgBox,21,Error, % A_ScriptName " failed to load.`nThat may be because it is already running.`nIf that's the case, don't retry."
			IfMsgBox, Retry
				Run, % A_ScriptFullPath
			ExitApp
		}
	}
	else
	{
		if (A_Index > 1)
			TrayTip, Loading %A_ScriptName%, Attempt %A_Index% of 10 succeeded.
		break
	}
}

;check the command line parameters
loop, %0%
{
	;if there is a command line parameter called 'noreload'...
	if (%A_Index% = "\noreload")
	{
		; ...then the components have already been verified
		A_Properties.Verified := 1
		A_Properties.RunExits := 1
		
		break
	}
}

A_Properties.instance_count := %2%?%2%:1

OnExit, ExitSub

;the file included below this comment is edited by the script to contain
;the name of each component, Component names are derived from the PART files
;contained in the components' file
#Include, *i Object.dat

;get the name of the script without the extension in order to recognize
; the components' folder
A_Properties.Name := SubStr(A_ScriptName, 1, InStr(A_ScriptName, ".")-1)

;if the componentes have not been verified then we need to verify them
if (!A_Properties.Verified)
	ComponentCheck()

;the next function runs the auto-execute sections of each component
RunAutos()

RunAutos()
{
	global
	local key
	local component
	
	for key, component in A_properties.components
		gosub, % component . "_Auto"
}

FileDelete, Object.dat
FileDelete, Includes.dat

return

;-------------------------------
;EXIT SUBROUTINE
;-------------------------------
ExitSub:
Critical, on

;close single instance, release the mutex so that the next instance of the script can get it
DllCall("ReleaseMutex", "Uptr", A_Properties.mutex)


;suspend all hotkeys so that the script will stop having an effect immediately
; this is necesary becuase the components can have long Exit subroutines
Suspend


;if 'reload' is 1 then start another instance of the script
if (A_Properties.Reload)
{
	;if the current instance of the scipt is verified then the new isntance
	; will not have to be verified again so start it without the 'norelaod' switch
	Run, % A_AhkPath . " " . A_ScriptName . (A_Properties.Verified=1?"":" \noreload " (A_Properties.instance_count + 1) )
}
else
{
	Loop ;delete the DAT files, use a loop to make sure that there are no errors
	{
		IfNotExist, Includes.dat
		{
			IfNotExist, Object.dat
				break
		}
		FileDelete, Object.dat
		FileDelete, Includes.dat
	}
}

;close each component by running their exit subroutines
if (A_Properties.RunExits)
	RunExits()

RunExits()
	{
		global
		local key
		local component
		
		for key, component in A_properties.components
			gosub, % component . "_Exit"
	}

;if the user clicked Reload, delete the DAT files
if (A_ExitReason = "Reload")
{
	Loop
	{
		FileDelete, Object.dat
		FileDelete, Includes.dat
		IfNotExist, Includes.dat
		{
			IfNotExist, Object.dat
				break
		}
	}
}

ExitApp



;-------------------------------
;LOOP THROUGH THE COMPONENTS DIRECTORY AND CREATE THE FILES TO BE INCLUDED IN THE NEXT INSTANCE
;-------------------------------

ComponentCheck() ; verify and update components
{

	global A_Properties

	;put in the object name and the opening bracket
	FileAppend, A_Properties.Components := [, % "Object.dat"

	;get the names of the components
	loop, % A_Properties.Name "\*.part"
	{
		;if this is not the first element in the array, we need to append a comma
		;and a space
		if (A_Index != 1)
			FileAppend, % ", ", % "Object.dat"
		
		;append the name of the component without the file extension
		FileAppend, % """" SubStr(A_LoopFileName, 1, StrLen(A_LoopFileName) - 5) """", % "Object.dat"
		
		;append an include statement for each PART file
		FileAppend, % "#Include " . A_Properties.Name . "\" . A_LoopFileName . "`n", % "Includes.dat"
	}

	;append the closing bracket
	FileAppend, % "]", % "Object.dat"
	
	;protects against double write errors
	FileRead, ObjectFile, Object.dat
	if ( (InStr(ObjectFile, ":=",0,1,2)) )
	{
		A_Properties.reload := 1
		ExitApp
	}

	;now that we've edited the include files to include all of the components, we
	;need to start another instance of the script and close the first instance
	A_Properties.reload := 1
	ExitApp
}

;-------------------------------
;COMPONENTS
;-------------------------------
#Include, *i Includes.dat