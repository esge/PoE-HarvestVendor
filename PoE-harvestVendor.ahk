 ; ©Esge 2021-
 ; v0.1 - basic prototype functionality
 
 
    #NoEnv
    #Warn
    #SingleInstance Force
    SetWorkingDir %A_ScriptDir%   

;hotkey to activate OCR
+^q::
	getSelectionCoords(x_start, x_end, y_start, y_end)
  ; msgbox,  %x_start% %y_start% %x_end% %y_end%
;RunWait, C:\Users\stani\Dropbox\ahk\scripts\Capture2Text\Capture2Text_CLI.exe %x_start% %y_start% %x_end% %y_end% --clipboard	
command = Capture2Text\Capture2Text.exe -s `"%x_start% %y_start% %x_end% %y_end%`" -o temp.txt
;msgbox, %command%
RunWait, %command%

;temp:= ComObjCreate("WScript.Shell").Exec(command).StdOut.ReadAll()
;msgbox, %temp%
FileRead, temp, temp.txt
input := StrReplace(temp,"`r`n")
;remove new lines from ocr grab   

;input := StrReplace(clipboard, "`r`n")

;remove all the not needed extra words
out := StrReplace(input, "a random")
out := StrReplace(out, "modifier")
out := StrReplace(out, "from")
out := StrReplace(out, "an item")
out := StrReplace(out, "with")
out := StrReplace(out, "and")
out := StrReplace(out, "a new")
out := StrReplace(out, "a Rare item")
out := StrReplace(out, "values,")
out := StrReplace(out, "Quality does notincrease its Defences, grants ")

;divide into rows based on keywords that are always first in line
out := StrReplace(out, "Augment", "`r`nAugment")
out := StrReplace(out, "Remove", "`r`nRemove")
out := StrReplace(out, "Reforge", "`r`nReforge")
out := StrReplace(out, "Enchant", "`r`nEnchant")
out := StrReplace(out, "Sacrifice", "`r`nSacrifice")

;remove double and tripple spaces created by text replaces
out := strreplace(out, "   ", " ")
out := strreplace(out, "  ", " ")

Clipboard = %out%
msgbox, %out%
return

; creates a click-and-drag selection box to specify an area
getSelectionCoords(ByRef x_start, ByRef x_end, ByRef y_start, ByRef y_end) {
	;Mask Screen
	Gui, Color, FFFFFF
	Gui +LastFound
	WinSet, Transparent, 50
	Gui, -Caption 
	Gui, +AlwaysOnTop
	Gui, Show, x0 y0 h%A_ScreenHeight% w%A_ScreenWidth%,"AutoHotkeySnapshotApp"     

	;Drag Mouse
	CoordMode, Mouse, Screen
	CoordMode, Tooltip, Screen
	WinGet, hw_frame_m,ID,"AutoHotkeySnapshotApp"
	hdc_frame_m := DllCall( "GetDC", "uint", hw_frame_m)
	KeyWait, LButton, D 
	MouseGetPos, scan_x_start, scan_y_start 
	Loop
	{
		Sleep, 10   
		KeyIsDown := GetKeyState("LButton")
		if (KeyIsDown = 1)
		{
			MouseGetPos, scan_x, scan_y 
			DllCall( "gdi32.dll\Rectangle", "uint", hdc_frame_m, "int", 0,"int",0,"int", A_ScreenWidth,"int",A_ScreenWidth)
			DllCall( "gdi32.dll\Rectangle", "uint", hdc_frame_m, "int", scan_x_start,"int",scan_y_start,"int", scan_x,"int",scan_y)
		} else {
			break
		}
	}

	;KeyWait, LButton, U
	MouseGetPos, scan_x_end, scan_y_end
	Gui Destroy
	
	if (scan_x_start < scan_x_end)
	{
		x_start := scan_x_start
		x_end := scan_x_end
	} else {
		x_start := scan_x_end
		x_end := scan_x_start
	}
	
	if (scan_y_start < scan_y_end)
	{
		y_start := scan_y_start
		y_end := scan_y_end
	} else {
		y_start := scan_y_end
		y_end := scan_y_start
	}
}



