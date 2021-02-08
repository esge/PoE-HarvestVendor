 ; ©Esge 2021-
 ; v0.2 - smarter string handling - regex replace and separated by craft types
 ; v0.1 - basic prototype functionality
 
 
    #NoEnv
    #Warn
    #SingleInstance Force
    SetWorkingDir %A_ScriptDir%   

;hotkey to activate OCR
+^q::
	out := ""
		
	getSelectionCoords(x_start, x_end, y_start, y_end)
  
	command = Capture2Text\Capture2Text.exe -s `"%x_start% %y_start% %x_end% %y_end%`" -o temp.txt
	RunWait, %command%

	FileRead, temp, temp.txt

	NewLined := RegExReplace(temp, "(Reforge|Randomise|Remove|Augment|Improves|Upgrades|Upgrade|Set|Change|Exchange|Sacrifice|Attempt|Enchant|Reroll)" , "`r`n$1")
	Arrayed := StrSplit(NewLined, "`r`n")

	for index in Arrayed{	
		if (Arrayed[index] == "") {
			;skip empty fields
		}
		;Augment
		else if InStr(Arrayed[index], "Augment") = 1 {
			if InStr(Arrayed[index], "Influence") > 0 {
				out .= RegExReplace(Arrayed[index],"(an item with a new|ifier|with|values)","") . "`r`n"
			} else {	
			out .= RegExReplace(Arrayed[index],"(a Magic or Rare item with a new|a Rare item with a new modifier, with||an item with a new|modifier|with|values)","") . "`r`n"
			}
		}
		;Remove
		else if InStr(Arrayed[index], "Remove") = 1 {		
			out .= RegExReplace(Arrayed[index],"(a random|modifier|from an item|and|a new)","") . "`r`n"		
		}
		;Reforge
		else if InStr(Arrayed[index], "Reforge") = 1 {		
			if (InStr(Arrayed[index], "Prefixes") > 0 or InStr(Arrayed[index], "Suffixes") > 0 ){
				out .= RegExReplace(Arrayed[index],"(a Rare item, |ing all|a Rare item with|modifier values,)|(Prefixes|Suffixes)","$2") . "`r`n"	
			} else {
				out .= RegExReplace(Arrayed[index],"(as a Rare item|item|random modifiers,|new random modifiers, |including an|including a|ifier|modifiers are)","") . "`r`n"	
			}
			;links
			;socket colour
			;Reforge a Rare item, being much more likely to receive the same modifier types
			;Reforge a Rare item, being much less likely to receive the same modifier types
		}
		;Enchant
			;flask
			;weapon
			;body armour

		;Attempt
			;awaken
			;scarab upgrade

		;Set
			;sockets
			;jewel implicits

		;Change
			; res mods
			; ignore others ?

		;Improves
			;gem quality
			;flask quality


;;== not doing for now, not very sellable afaik==
		;Randomise 
		;Upgrades 
		;Upgrade 
		;Exchange 
		;Sacrifice 
		;Reroll
	}

	msgbox % RegExReplace(out, " +", " ")
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



