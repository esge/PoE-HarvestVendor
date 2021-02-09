 ; ©Esge 2021-
; notes
; will ignore all sacrifice crafts for the purpose of this tool because they arent sellable effects

 
    #NoEnv
    #Warn
    #SingleInstance Force
    SetWorkingDir %A_ScriptDir%   

;hotkey to activate OCR
+^q::
	out := ""
		
	getSelectionCoords(x_start, x_end, y_start, y_end)
  
	command = Capture2Text\Capture2Text.exe -s `"%x_start% %y_start% %x_end% %y_end%`" -o temp.txt --trim-capture
	RunWait, %command%

	FileRead, temp, temp.txt

	;FileRead, temp, test.txt

	NewLined := RegExReplace(temp, "(Reforge |Randomise |Remove |Augment |Improves |Upgrades |Upgrade |Set |Change |Exchange |Sacrifice a|Sacrifice up|Attempt |Enchant |Reroll |Fracture |Add a random |Synthesise |Split )" , "`r`n$1")
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
			;prefixes, suffixes
			if (InStr(Arrayed[index], "Prefixes") > 0 or InStr(Arrayed[index], "Suffixes") > 0 ){
				out .= RegExReplace(Arrayed[index],"(a Rare item, |ing all|a Rare item with|modifier values,)|(Prefixes|Suffixes)","$2") . "`r`n"	
			}
			;links
			else if InStr(Arrayed[index], "links") > 0 {
				out .= RegExReplace(Arrayed[index],"( between sockets on an item,)","") . "`r`n"	
			} 
			else if InStr(Arrayed[index], "colour") > 0 {
				out .= RegExReplace(Arrayed[index],"(the colour of|on an item,)","") . "`r`n"	
			} 
			else {
				out .= RegExReplace(Arrayed[index],"(as a Rare item|item|random modifiers,|new random modifiers, |including an|including a|ifier|modifiers are)","") . "`r`n"	
			}
			
			;socket colour
			;Reforge a Rare item, being much more likely to receive the same modifier types
			;Reforge a Rare item, being much less likely to receive the same modifier types
		} 
		;Enchant
		else if InStr(Arrayed[index], "Enchant") = 1 {
			;flask
			if InStr(Arrayed[index], "Flask") > 1 {
				out .= RegExReplace(Arrayed[index],"(a modifier that grants|The magnitude of this effect decreases with each use)","") . "`r`n"
			}
			;weapon
			else if InStr(Arrayed[index], "Weapon") > 1 {
				out .= RegExReplace(Arrayed[index],"( Quality does not increase its Physical Damage,)","") . "`r`n"
			}			
			;body armour
			else if InStr(Arrayed[index], "Armour") > 1 {
				out .= RegExReplace(Arrayed[index],"( Quality does not increase its Defences,)","") . "`r`n"
			}	
		}
		;Attempt
		else if InStr(Arrayed[index], "Attempt") = 1 {
			;awaken
			if InStr(Arrayed[index], "Awaken") > 1 {
				out .= RegExReplace(Arrayed[index],"(that can be Awakened with a 5% chance. If it does not Awaken, it is destroyed.)","") . "`r`n"
			}
			;scarab upgrade
			else if InStr(Arrayed[index], "Scarab") > 1 {
				out .= RegExReplace(Arrayed[index],"(, with a chance for it to become Winged)","") . "`r`n"
			}	
		}
		;Change
		else if InStr(Arrayed[index], "Change") = 1 {
			; res mods
			if InStr(Arrayed[index], "Resistance") > 0 {
				out .= RegExReplace(Arrayed[index],"(a modifier that grants| a similar-tier modifier that grants|istance)","") . "`r`n"
			} else {
			; ignore others ?
				out .= "" ;Arrayed[index] . "`r`n"
			}		
		} 
		;sacrifice 
		else if InStr(Arrayed[index], "Sacrifice") = 1 {
			;gem for gcp/xp
			if InStr(Arrayed[index], "Gem") > 1 {
				out .= RegExReplace(Arrayed[index],"(gain|of the gem's|total|erience stored)","") . "`r`n"
			} 
			;div cards gambling
			else if InStr(Arrayed[index], "Divination") > 1  {
				out .= RegExReplace(Arrayed[index],"(up to half a stack of|ination)","") . "`r`n"
			} else {
				;ignores the rest of sacrifice crafts:
					;Sacrifice or Mortal Fragment into another random Fragment of that type
					;Sacrificie Maps for same or lower tier stuff
					;Sacrifice maps for missions
					;Sacrifice maps for map device infusions
					;Sacrifice maps for fragments
					;Sacrifice maps for map currency
					;Sacrifice maps for scarabs
					;sacrifice t14+ map for elder/shaper/synth map
					;sacrifice weap/ar to make similiar belt/ring/amulet/jewel
				out .= ""
			}
		} 

		;Improves
		else if InStr(Arrayed[index], "Improves") = 1 {			
			out .= RegExReplace(Arrayed[index],"( by at least 10%. Has greater effect on lower rarity flasks. The maximum quality is 20%| by at least 10%. The maximum quality is 20%)","") . "`r`n"
		}	
		else if InStr(Arrayed[index], "Fracture") = 1 {			
			out .= RegExReplace(Arrayed[index],"(a random|on an item with at least 5 modifiers, locking it in place. This can't be used on Influenced, Synthesised, or Fractured items| on an item with at least 3 Suffixes. This can't be used on Influenced, Synthesised, or Fractured items| on an item with at least 3 Prefixes. This can't be used on Influenced, Synthesised, or Fractured items)","") . "`r`n"
		} 		
		else if InStr(Arrayed[index], "Reroll") = 1 {		
			out .= RegExReplace(Arrayed[index],"(ifier|s on a Rare item, with| modifier values|on a Magic or Rare item, with )","") . "`r`n"
		}
		else if InStr(Arrayed[index], "Randomise") = 1 {		
			out .= RegExReplace(Arrayed[index],"(the numeric|the random|ifier|on a Magic or Rare item)","") . "`r`n"
		}
		else if InStr(Arrayed[index], "Add") = 1 {		
			out .= RegExReplace(Arrayed[index],"(a random|a Normal, Magic or Rare|Normal, Magic or Rare|that isn't influenced)","") . "`r`n"
		}
	; ignoring this section of mods
	; and i do realize i could put them in a single if, but this way its already neatly split if i might want to add them into processing 	
		;Exchange 
		else if InStr(Arrayed[index], "Exchange") = 1 {
			;skipping all exchange crafts assuming anybody would just use them for themselfs
			out .= ""
		} 
		;Upgrade
		else if InStr(Arrayed[index], "Upgrade") = 1 {
			;skipping upgrade crafts
			out .= ""
		}	
		;Synthesise
		else if InStr(Arrayed[index], "Synthesise") = 1 {
			;skipping Synthesise craft
			out .= ""
		}	
		else if InStr(Arrayed[index], "Split") = 1 {
			;skipping Split scarab craft
			out .= ""
		}	


		;just add unknown stuff as is
		;else {
		;	out .= Arrayed[index] . "`r`n"
		;}		
	}
	Clipboard := RegExReplace(out, " +", " ")
	clipwait
	Tooltip, List of crafts ready
	sleep, 2000
	Tooltip
	;msgbox % RegExReplace(out, " +", " ")
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



