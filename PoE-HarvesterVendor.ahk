#NoEnv
#Warn, LocalSameAsGlobal, off
#SingleInstance Force
SetWorkingDir %A_ScriptDir% 
global version := "0.3.1"
global augmetnCounter := 1
global removeCounter := 1
global raCounter := 1
global otherCounter := 1
global outArrayCount := 0
global outArray := []		
;global newArray := []    
global arr := []
global outstring := ""
global firstGuiOpen := 0
global str := ""
global AMaxLen := 0
global RMaxLen := 0
global RAMaxLen := 0
global OMaxLen := 0

checkfiles()

getLeagues()

^g:: ;ctrl+g launches straight into the capture, opens gui afterwards
    processCrafts()
    if (firstGuiOpen == 0) {
        buildGUI()
    } 
    Gui, HarvestUI:Show, w1225 h370
	OnMessage(0x200, "WM_MOUSEMOVE") ;activates tooltip function
    craftSort(outArray)
return
^+g:: ;ctrl+shift+g opens the gui, yo go from there
    buildGUI()
    Gui, HarvestUI:Show, w1225 h370
	OnMessage(0x200, "WM_MOUSEMOVE")
	clearAll()
Return

GuiEscape:
    Gui, HarvestUI:Show
GuiClose:
    ExitApp

Addcrafts:
    processCrafts()
    CraftSort(outArray)
return

Clear_all:
	clearAll()    
return

Aug_Post:
    createPost("A")
return

Rem_Post:
    createPost("R")
return

RA_Post:
    createPost("RA")
return

O_Post:
    createPost("O")
return

postAll:
	createPost("All")
return

LeagueDropdown:
    guiControlGet, selectedLeague,,League, value
    iniWrite, %selectedLeague%, %A_WorkingDir%/settings.ini, selectedLeague, s
	allowAll()
return

IGN:
	guiControlGet, lastIGN,,IGN, value
    iniWrite, %lastIGN%, %A_WorkingDir%/settings.ini, IGN, n
return

help:
gui Help:new

gui font, s16
Gui, add, text,, This is the area you want to select
gui, font
Gui, Add, ActiveX, x0 y30 w500 h500 vWB1, Shell.Explorer

; This can be an image from a website, or an image from your computer. Just specify the path based off of the current script directory.
Edit := WebPic(WB1, "https://github.com/esge/PoE-HarvestVendor/blob/master/examples/example3.png?raw=true", "w436 h425 cFFFFFF")
;Gui, Add, Edit, x0 y105 w750 h215 -Wrap +HScroll vEdit TabStop WantReturn t8
Gui, Help:Show, w500 h500, Gui Example


helpClose:
Gui, HarvestUI:Default
return
;Test_button:
;return
buildGUI() {    
    firstGuiOpen := 1
    Gui HarvestUI:New,, PoE-HarvestVendor v%version%	
    ;== top stuff ==
    Gui Add, DropDownList, x10 y10 w150 vLeague gLeagueDropdown, ;*[PoE-HarvesterVendor]
    leagueList() ;populate leagues dropdown and select the last used one
    Gui Add, Button, x165 y9 w80 h23 vAddCrafts gAddcrafts, Add crafts
		global AddCrafts_TT := "CTRL + G"
    Gui Add, Button, x250 y9 w80 h23 gClear_all, Clear

	Gui Add, Button, x335 y9 w80 h23 vpostAll gpostAll, Post all
		global postAll_TT := "Puts all crafts into a single post regardless of sorting - allowed only for Standard leagues"
	allowAll() ;*[PoE-HarvesterVendor]
    
	if (version != getVersion()) {
		gui Font, s14
		gui add, Link, x950 y10 vVersionLink, <a href="https://github.com/esge/PoE-HarvestVendor/releases">! New Version Available !</a>
		gui font
	}

	Gui font, s26
	Gui Add, Button, x1175 y2 w40 h40 vHelp gHelp, ?
	Gui font

	;== Bottom stuff ==

	gui add, Text, x15 y345 w200, Custom text added to message: 
	gui add, Edit, x170 y340 w500 vCustomText
		global CustomText_TT := "If you wish to add extra info to your message, will show under the WTS line"

	gui add, CheckBox, x680 y345 vcanStream, Can Stream
		global canStream_TT := "Adds: Can stream if requested. under the WTS line"

	Gui Add, Text, x1040 y345 w25 h23, IGN:
	
	IniRead, name, %A_WorkingDir%/settings.ini, IGN, n
	if (name == "ERROR") {
		name:=""
		}
	Gui Add, Edit, x1065 y340 w150 h23 vIGN gIGN, %name%		
		global IGN_TT := "Optional, wont show anything if left empty"

    ;== Section Augment ==
    Awidth := 175
    Ax_groupbox := 10
    Ax_count := Ax_groupbox + 5 ;groupbox x+5
    Ax_craft := Ax_count + 40 ;count + 40
    Ax_price := Awidth + Ax_craft + 5 ; width+craft + 5
    Ax_checkbox := Ax_price + 35 + 5 ; price + 35 + 5

    Gui Add, Button, x190 y50 w80 h23 vApost gAug_Post, Create Posting

    Gui Font, s10
    Gui Add, Groupbox, x%Ax_groupbox% y35 w290 h300, Augment
    Gui Font

    yrow1 := 80
    loop, 10 {
        yrow1_cbOffset := yrow1 + 5
        Gui Add, Edit, x%Ax_count% y%yrow1% w35 vA_count_%A_Index% 
        Gui Add, UpDown, Range0-20, 0
        Gui Add, Edit, x%Ax_craft% y%yrow1% w%Awidth% vA_craft_%A_Index% 
        Gui Add, Edit, x%Ax_price% y%yrow1% w35 vA_price_%A_Index% 
        Gui Add, CheckBox, x%Ax_checkbox% y%yrow1_cbOffset% w23 vA_cb_%A_Index% 
        yrow1 += 25
    }

    ;== Section Remove ==
    Rwidth := 120
    Rx_groupbox := 305
    Rx_count := Rx_groupbox + 5
    Rx_craft := Rx_count + 40
    Rx_price := Rwidth + Rx_craft + 5
    Rx_checkbox := Rx_price + 35 + 5 

    Gui Add, Button, x430 y50 w80 h23 vRpost gRem_Post, Create Posting

    Gui Font, s10
    Gui Add, Groupbox, x%Rx_groupbox% y35 w235 h300, Remove
    Gui Font

    yrow1 := 80
    loop, 10 {
        yrow1_cbOffset := yrow1 + 5
        Gui Add, Edit, x%Rx_count% y%yrow1% w35 vR_count_%A_Index%
        Gui Add, UpDown, Range0-20, 0
        Gui Add, Edit, x%Rx_craft% y%yrow1% w%Rwidth% vR_craft_%A_Index%
        Gui Add, Edit, x%Rx_price% y%yrow1% w35 vR_price_%A_Index%
        Gui Add, CheckBox, x%Rx_checkbox% y%yrow1_cbOffset% w23 vR_cb_%A_Index%
        yrow1 += 25
    }

    ;== Section Rem/Add ==
    RAwidth := 185
    RAx_groupbox := 545
    RAx_count := RAx_groupbox + 5
    RAx_craft := RAx_count + 40
    RAx_price := RAwidth + RAx_craft + 5
    RAx_checkbox :=  RAx_price + 35 + 5 

    Gui Add, Button, x735 y50 w80 h23 vRApost gRA_Post, Create Posting

    Gui Font, s10
    Gui Add, Groupbox, x%RAx_groupbox% y35 w300 h300, Remove/Add
    Gui Font

    yrow1 := 80
    loop, 10 {
        yrow1_cbOffset := yrow1 + 5
        Gui Add, Edit, x%RAx_count% y%yrow1% w35 vRA_count_%A_Index%
        Gui Add, UpDown, Range0-20, 0
        Gui Add, Edit, x%RAx_craft% y%yrow1% w%RAwidth% vRA_craft_%A_Index%
        Gui Add, Edit, x%RAx_price% y%yrow1% w35 vRA_price_%A_Index%
        Gui Add, CheckBox, x%RAx_checkbox% y%yrow1_cbOffset% w23 vRA_cb_%A_Index%
        yrow1 += 25
    }

    ;== Section Other ==
    Owidth := 250
    Ox_groupbox := 850
    Ox_count := Ox_groupbox + 5
    Ox_craft := Ox_count + 40
    Ox_price := Owidth + Ox_craft + 5
    Ox_checkbox := Ox_price + 35 + 5 

    Gui Add, Button, x1105 y50 w80 h23 vOpost gO_Post, Create Posting

    Gui Font, s10
    Gui Add, Groupbox, x%Ox_groupbox% y35 w365 h300, Other
    Gui Font

    yrow1 := 80
    loop, 10 {
        yrow1_cbOffset := yrow1 + 5
        Gui Add, Edit, x%Ox_count% y%yrow1% w35 vO_count_%A_Index%
        Gui Add, UpDown, Range0-20, 0
        Gui Add, Edit, x%Ox_craft% y%yrow1% w%Owidth% vO_craft_%A_Index%
        Gui Add, Edit, x%Ox_price% y%yrow1% w35 vO_price_%A_Index%
        Gui Add, CheckBox, x%Ox_checkbox% y%yrow1_cbOffset% w23 vO_cb_%A_Index%
        yrow1 += 25
    }

    
}
processCrafts() {
	Gui, HarvestUI:Hide    
	
	outArray := []
    ;sleep, 1000   
	getSelectionCoords(x_start, x_end, y_start, y_end)
	Tooltip, Please Wait
	command = Capture2Text\Capture2Text.exe -s `"%x_start% %y_start% %x_end% %y_end%`" -o temp.txt -l English --trim-capture 
	RunWait, %command%
    
    sleep, 1000 ;sleep cos if i show the Gui too quick the capture will grab screenshot of gui    
    Gui, HarvestUI:Show
	Tooltip
	FileRead, temp, temp.txt
	;FileRead, temp, test.txt

	NewLined := RegExReplace(temp, "(Reforge |Randomise |Remove |Augment |Improves |Upgrades |Upgrade |Set |Change |Exchange |Sacrifice a|Sacrifice up|Attempt |Enchant |Reroll |Fracture |Add a random |Synthesise |Split |Corrupt )" , "`r`n$1")
	Arrayed := StrSplit(NewLined, "`r`n")

	
	augments := ["Caster","Physical","Fire","Attack","Life","Cold","Speed","Defence","Lightning","Chaos","Critical","Influence","a new modifier"]
	remAddsClean := ["Caster","Physical","Fire","Attack","Life","Cold","Speed","Defence","Lightning","Chaos","Critical","Influence"]
	remAddsNon := ["non-Caster","non-Physical","non-Fire","non-Attack","non-Life","non-Cold","non-Speed","non-Defence","non-Lightning","non-Chaos","non-Critical","non-Influence"]
	reforgeNonColor := ["non-Red","non-Blue","non-Green"]
	reforge2color := ["Red and Blue","Red and Green","them Blue and Green","Red, Blue and Green","White"]
	flaskEnchants := ["Duration.","Effect.","Maximum Charges.","Charges used."]
	weapEnchants := ["Critical Strike Chance","Accuracy","Attack Speed","+1 Weapon Range","Elemental Damage","Area of Effect"]
	bodyEnchants := ["Maximum Life","Maximum Mana","Strength","Dexterity","Intelligence","Fire Resistance","Cold Resistance","Lightning Resistance"]
	gemPerc := ["20%","30%","40%","50%"]
	fracture := ["modifier","Suffix","Prefix"]	
	addInfluence := ["Weapon", "Armour","Jewellery"]	
	for index in Arrayed {	
		Arrayed[index] := Trim(RegExReplace(Arrayed[index] , " +", " ")) ;remove possible double spaces from ocr
		if (Arrayed[index] == "") {
			;skip empty fields
		}
		;Augment
		else if InStr(Arrayed[index], "Augment") = 1 {
			for a in augments {
				if InStr(Arrayed[index], augments[a]) > 0 {
					if InStr(Arrayed[index], "Lucky") > 0 {											
						outArrayCount += 1
						outArray[outArrayCount] := "Augment " . augments[a] . " Lucky lv" . getLVL(Arrayed[index]) 
					} 
					else {
						outArrayCount += 1
						outArray[outArrayCount] := "Augment " . augments[a] . " lv" . getLVL(Arrayed[index])
					}
				}
			}
		}
		;Remove
		else if InStr(Arrayed[index], "Remove") = 1 { ;*[PoE-HarvesterVendor]
			if InStr(Arrayed[index], "add") > 0 {				
				if InStr(Arrayed[index], "non") > 0 {
					for a in remAddsClean {
						if InStr(Arrayed[index], remAddsClean[a]) > 0  {
							outArrayCount += 1
							outArray[outArrayCount] := "Remove non-" . remAddsClean[a] . " add " . remAddsClean[a] . " lv" . getLVL(Arrayed[index]) 
						}
					}
				} 
				else if InStr(Arrayed[index], "non") = 0 {
					for a in remAddsClean {
						if InStr(Arrayed[index], remAddsClean[a]) > 0  {
							outArrayCount += 1
							outArray[outArrayCount] := "Remove " . remAddsClean[a] . " add " . remAddsClean[a] . " lv" . getLVL(Arrayed[index]) 
						}
					}
				}				
			} 
			else {
				for a in augments {
					if InStr(Arrayed[index], augments[a]) > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Remove " . augments[a] . " lv" . getLVL(Arrayed[index]) 
					}
				}	
			}			
			;outArrayCount += 1
			;outArray[outArrayCount] := RegExReplace(Arrayed[index],"(a random|modifier|from an item|and|a new)","")	
		}
		;Reforge
		else if InStr(Arrayed[index], "Reforge") = 1 {
			;prefixes, suffixes
			if InStr(Arrayed[index], "Prefixes") > 0 {
				if InStr(Arrayed[index], "Lucky") > 0 {
					outArrayCount += 1
					outArray[outArrayCount] := "Reforge keep Prefixes Lucky lv" . getLVL(Arrayed[index])
				} 
				else {
					outArrayCount += 1
					outArray[outArrayCount] := "Reforge keep Prefixes lv" . getLVL(Arrayed[index])
				}			
			}
			else if InStr(Arrayed[index], "Suffixes") > 0 {	
				if InStr(Arrayed[index], "Lucky") > 0 {
					outArrayCount += 1
					outArray[outArrayCount] := "Reforge keep Suffixes Lucky lv" . getLVL(Arrayed[index])
				}
				else {
					outArrayCount += 1
					outArray[outArrayCount] := "Reforge keep Suffixes lv" . getLVL(Arrayed[index])	
				}
			}			
			;links
			else if (InStr(Arrayed[index], "links") > 0 and InStr(Arrayed[index], "10 times") = 0) {
				if InStr(Arrayed[index],"six") > 0 {
					outArrayCount += 1
					outArray[outArrayCount] := "Six link (6-link) lv" . getLVL(Arrayed[index])
				}	
			} 
			else if (InStr(Arrayed[index], "colour") > 0 and InStr(Arrayed[index], "10 times") = 0) {		
				for a in reforgeNonColor {
					if InStr(Arrayed[index], reforgeNonColor[a]) > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Reforge " . reforgeNonColor[a] . " into " . StrReplace(reforgeNonColor[a], "non-") . " lv" . getLVL(Arrayed[index])
					} 
				}
				for b in reforge2color {
					if InStr(Arrayed[index], reforge2color[b]) > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Reforge into " . StrReplace(reforge2color[b],"them ") . " lv" . getLVL(Arrayed[index])
					}
				}	
			} 
			else if InStr(Arrayed[index], "Influence") > 0 {				
				outArrayCount += 1
				outArray[outArrayCount] := "Reforge with Influence mod more common lv" . getLVL(Arrayed[index])
			}
			else {
				;outArrayCount += 1
				;outArray[outArrayCount] := RegExReplace(Arrayed[index],"(as a Rare item|item|random modifiers,|new random modifiers, |including an|including a|ifier|modifiers are)","")	
			}
						
			;Reforge a Rare item, being much more likely to receive the same modifier types
			;Reforge a Rare item, being much less likely to receive the same modifier types
		} 
		;Enchant
		
		else if InStr(Arrayed[index], "Enchant") = 1 { 
			;flask
			if InStr(Arrayed[index], "Flask") > 0 {
				for a in flaskEnchants {
					if InStr(Arrayed[index], flaskEnchants[a]) > 0 {
						tempArray := ["inc","inc","inc","reduced"]
						outArrayCount += 1
						outArray[outArrayCount] := "Enchant Flask: " . tempArray[a] . " " . flaskEnchants[a] . " lv" . getLVL(Arrayed[index])
					}
				}
			}
			;weapon
			
			else if InStr(Arrayed[index], "Weapon") > 0 {			
				for a in weapEnchants {
					if InStr(Arrayed[index], weapEnchants[a]) > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Enchant Weapon: " . weapEnchants[a] . " lv" . getLVL(Arrayed[index])
					}
				}
			}			
			;body armour
			else if InStr(Arrayed[index], "Armour") > 0 {
				for a in bodyEnchants {
					if InStr(Arrayed[index], bodyEnchants[a]) > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Enchant Body: " . bodyEnchants[a] . " lv" . getLVL(Arrayed[index])
					}
				}
			}	
			else if InStr(Arrayed[index], "Sextant") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Enchant Map: no Sextant use" . " lv" . getLVL(Arrayed[index])
			}
		}
		;Attempt
		else if InStr(Arrayed[index], "Attempt") = 1 {
			;awaken
			if InStr(Arrayed[index], "Awaken") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Attempt to Awaken a level 20 Support Gem" . " lv" . getLVL(Arrayed[index])
			}
			;scarab upgrade
			else if InStr(Arrayed[index], "Scarab") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Attempt to upgrade a Scarab" . " lv" . getLVL(Arrayed[index])
			}	
		}
		;Change
		
		else if InStr(Arrayed[index], "Change") = 1 {
			; res mods
			if InStr(Arrayed[index], "Resistance") > 0 {
				fireVal := InStr(Arrayed[index], "Fire")
				coldVal := InStr(Arrayed[index], "Cold")
				lightVal := InStr(Arrayed[index], "Lightning")

				if max(fireVal, coldVal, lightVal) == fireVal {
					if InStr(Arrayed[index], "Cold") > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Change Cold res to Fire res" . " lv" . getLVL(Arrayed[index])
					}
					else if InStr(Arrayed[index], "Lightning") > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Change Lightning res to Fire res" . " lv" . getLVL(Arrayed[index])
					}
				}
				else if max(fireVal, coldVal, lightVal) == coldVal {
					if InStr(Arrayed[index], "Fire") > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Change Fire res to Cold res" . " lv" . getLVL(Arrayed[index])
					}
					else if InStr(Arrayed[index], "Lightning") > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Change Lightning res to Cold res" . " lv" . getLVL(Arrayed[index])
					}
				}
				else if max(fireVal, coldVal, lightVal) == lightVal {
					if InStr(Arrayed[index], "Fire") > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Change Fire res to Lightning res" . " lv" . getLVL(Arrayed[index])
					}
					else if InStr(Arrayed[index], "Cold") > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Change Cold res to Lightning res" . " lv" . getLVL(Arrayed[index])
					}
				}				
			} else {
			; ignore others ?				
			}		
		} 
		;sacrifice 		
		else if InStr(Arrayed[index], "Sacrifice") = 1 {
			;gem for gcp/xp
			if InStr(Arrayed[index], "Gem") > 10 {
				for a in gemPerc {
					if InStr(Arrayed[index], gemPerc[a]) > 0 {
						if InStr(Arrayed[index],"quality")	> 0 {
							outArrayCount += 1
							outArray[outArrayCount] := "Sacrifice gem, get " . gemPerc[a] . " qual as GCP" . " lv" . getLVL(Arrayed[index])
						}
					
						else if InStr(Arrayed[index],"experience") {
							outArrayCount += 1
							outArray[outArrayCount] := "Sacrifice gem, get " . gemPerc[a] . " exp as Lens" . " lv" . getLVL(Arrayed[index])
						}
					}
				}		
			} 

			;div cards gambling
			else if InStr(Arrayed[index], "Divination") > 1  {
				if InStr(Arrayed[index], "half a stack") > 1 {
					outArrayCount += 1
					outArray[outArrayCount] :=  "Sacrifice Div Cards" . " lv" . getLVL(Arrayed[index])
				}
				;skipping this:
				;	Sacrifice a stack of Divination Cards for that many different Divination Cards
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
			}
		} 

		;Improves
		
		else if InStr(Arrayed[index], "Improves") = 1 {	
			if InStr(Arrayed[index], "Flask") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Improves the Quality of a Flask" . " lv" . getLVL(Arrayed[index])
			}
			else if InStr(Arrayed[index], "Gem") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Improves the Quality of a Gem" . " lv" . getLVL(Arrayed[index])
			}
		}	
		
		else if InStr(Arrayed[index], "Fracture") = 1 {
			for a in fracture {
				if InStr(Arrayed[index], fracture[a]) > 0 {
					outArrayCount += 1
					outArray[outArrayCount] := "Fracture " . fracture[a] . " lv" . getLVL(Arrayed[index])
				}
			}
		} 		
		else if InStr(Arrayed[index], "Reroll") = 1 {
			if InStr(Arrayed[index], "Implicit") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Reroll All Lucky lv" . getLVL(Arrayed[index])
			} 
			else if InStr(Arrayed[index], "Prefix") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Reroll Prefix Lucky lv" . getLVL(Arrayed[index])
			}
			else if InStr(Arrayed[index], "Suffix") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Reroll Suffix Lucky lv" . getLVL(Arrayed[index])
			}			
		}
		else if InStr(Arrayed[index], "Randomise") = 1 {
			for a in augments {
				if InStr(Arrayed[index], augments[a]) > 0 {
					outArrayCount += 1
					outArray[outArrayCount]	:= "Randomise values of " . augments[a] . " mods lv" . getLVL(Arrayed[index])
				}
			}		
		}
		
		else if InStr(Arrayed[index], "Add") = 1 {		
			for a in addInfluence {
				if InStr(Arrayed[index],addInfluence[a]) > 0 {
					outArrayCount += 1
					outArray[outArrayCount] := 	"Add Influence to " . addInfluence[a] . " lv" . getLVL(Arrayed[index])
				}
			}
		}		
		else if InStr(Arrayed[index], "Set") = 1 {	
			if InStr(Arrayed[index], "Prismatic") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Set Implicit basic Jewel" . " lv" . getLVL(Arrayed[index])
			}
			else if InStr(Arrayed[index], "Timeless") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Set Implicit Abyss/Timeless Jewel" . " lv" . getLVL(Arrayed[index])
			}
			else if InStr(Arrayed[index], "Cluster") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Set Implicit Cluster Jewel"	. " lv" . getLVL(Arrayed[index])
			}				
		}
		;Synthesise
		else if InStr(Arrayed[index], "Synthesise") = 1 {			
			outArrayCount += 1
			outArray[outArrayCount] := "Synthesise an item" . " lv" . getLVL(Arrayed[index])
		}

		else if InStr(Arrayed[index], "Corrupt") = 1 {	
			;Corrupt an item 10 times, or until getting a corrupted implicit modifier

			;outArrayCount += 1
			;outArray[outArrayCount] := Arrayed[index]
		}
	 ; ignoring this section of mods
	 ; and i do realize i could put them in a single if, but this way its already neatly split if i might want to add them into processing 	
		;Exchange 
		else if InStr(Arrayed[index], "Exchange") = 1 {
			;skipping all exchange crafts assuming anybody would just use them for themselfs
			
		} 
		;Upgrade
		else if InStr(Arrayed[index], "Upgrade") = 1 {
			;skipping upgrade crafts
			
		}	
	
		else if InStr(Arrayed[index], "Split") = 1 {
			;skipping Split scarab craft			
		}	


		;just add unknown stuff as is
		;else {
		;	out .= Arrayed[index] . "`r`n"
		;}		
	}

    for iFinal in outArray {	            
        ;outArray[iFinal] := RegExReplace(outArray[iFinal], "([^\w\s]+|_+)","")
		;outArray[iFinal] := RegExReplace(outArray[iFinal] , "(Level )", "lv")
        ; removes multiple spaces, but all all non chars so it gets rid of stray .,' from OCR, we lose the  dash in non-Tag, but we can lve with that)
        outArray[iFinal] := Trim(RegExReplace(outArray[iFinal] , " +", " ")) 
    }
	
	for s in outArray {
		str .= outArray[s] . "`r`n"
	}
	Clipboard := str

}


clearAll() {
    loop, 10 {
        GuiControl,, A_craft_%A_Index%
        GuiControl,, R_craft_%A_Index%
        GuiControl,, RA_craft_%A_Index%
        GuiControl,, O_craft_%A_Index%
        GuiControl,, A_count_%A_Index%, 0
        GuiControl,, R_count_%A_Index%, 0
        GuiControl,, RA_count_%A_Index%, 0
        GuiControl,, O_count_%A_Index%, 0
        GuiControl,, A_cb_%A_Index%, 0
        GuiControl,, R_cb_%A_Index%, 0
        GuiControl,, RA_cb_%A_Index%, 0
        GuiControl,, O_cb_%A_Index%, 0
		GuiControl,, A_price_%A_Index%
        GuiControl,, R_price_%A_Index%
        GuiControl,, RA_price_%A_Index%
        GuiControl,, O_price_%A_Index%
		}
        augmetnCounter := 1
        removeCounter := 1
        raCounter := 1
        otherCounter := 1
        outArray := []
        arr := []
}


allowAll() {
	IniRead selLeague, %A_WorkingDir%/settings.ini, selectedLeague, s
	if (selLeague == "ERROR"){
		GuiControlGet, selLeague,, LeagueDropdown, value
	}
	if InStr(selLeague, "Standard") = 0 {
		guicontrol, Disable, postAll		
	} else {
		guicontrol, Enable, postAll
	}
}

leagueList() {
    leagueString := ""
    loop, 8 {
        IniRead, tempList, %A_WorkingDir%/settings.ini, Leagues, %A_Index%
       ; msgbox % tempList
	   
        if InStr(tempList, "Hardcore") = 0 and InStr(tempList, "HC") = 0 {
            tempList .= " Softcore"
        } 
		if (tempList == "Hardcore") {
			tempList := "Standard Hardcore"
		}
		if InStr(tempList,"SSF") = 0 {
        	leagueString .= tempList . "|"
		}
    }
    guicontrol,, League, %leagueString%
	guicontrol, choose, League, 1
    iniWrite, Standard Softcore, %A_WorkingDir%/settings.ini, selectedLeague, s
	
}
getRowData(group, row) {
	GuiControlGet, tempCount,, %group%_count_%row%, value
	GuiControlGet, tempCraft,, %group%_craft_%row%, value
	GuiControlGet, tempPrice,, %group%_price_%row%, value
	GuiControlGet, tempCheck,, %group%_cb_%row%, value

	return [tempCount, tempCraft, tempPrice, tempCheck]
}

readyTT() {
   ClipWait
   ToolTip, Post Ready
	sleep, 2000
	Tooltip	
}

createPostRow(count,craft,price,group) {
		mySpaces := " "
		spacesCount := 0
		if (group == "All") {
			spacesCount := Max(AMaxLen,RMaxLen,RAMaxLen,OMaxLen) - strlen(craft)
		} 
		else {
			spacesCount := %group%MaxLen - StrLen(craft)
		}			
		loop, %spacesCount% {
			mySpaces .= " "
		}
		
	if regexmatch(craft,"(lv\d\d)") > 0 {
	 	craft := RegExReplace(craft," (lv\d\d)","][$1")
	}
	else {
		craft := craft . "][-"
	}
	outString .= "  (" . count . "x) [" . craft . "]" . mySpaces . "< " . price . " >`r`n"
}
codeblockWrap() {
	return "``````md`r`n" . outString . "``````"
}

createPost(group) {
    tempName := ""
	GuiControlGet, tempLeague,, League, value
	GuiControlGet, tempName,, IGN, value
	GuiControlGet, tempStream,, canStream, value
	GuiControlGet, tempCustomText,, CustomText, value
    outString := ""

	if (tempName != "") {
    	outString .= "#WTS " . tempLeague . " - IGN: " . tempName . "`r`n" 
	} else {
		outString .= "#WTS " . tempLeague . "`r`n"
	}
	if (tempCustomText != "") {
		outString .= "  " . tempCustomText . "`r`n"
	}
	if (tempStream == 1 ) {
		outString .= "  Can stream if requested `r`n"
	}
    switch group {
        case "A":            
            loop, 10 {
				row:= getRowData("A",A_Index)
				if (row[4] == 1) {
					createPostRow(row[1],row[2],row[3],"A")
					;outString .= "  " . row[1] . "x " . row[2] . " - " . row[3] . "`r`n"
				}
            }
            Clipboard := codeblockWrap()
            readyTT()
        return
        case "R":            
            loop, 10 {                
				row:= getRowData("R",A_Index)
                if (row[4] == 1) {
					createPostRow(row[1],row[2],row[3],"R")
				}   
            }
            Clipboard := codeblockWrap()
            readyTT()
        return
        case "RA":            
            loop, 10 {
                row:= getRowData("RA",A_Index)
                if (row[4] == 1) {
					createPostRow(row[1],row[2],row[3],"RA")
				}   
            }
            Clipboard := codeblockWrap()
            readyTT()
        return
        case "O":      
            loop, 10 {
                row:= getRowData("O",A_Index)
                if (row[4] == 1) {
					createPostRow(row[1],row[2],row[3],"O")
				}    
            }
            Clipboard := codeblockWrap()
            readyTT()
        return 
		case "All":
		 	loop, 10 {
               row:= getRowData("A",A_Index)
                if (row[4] == 1) {
					createPostRow(row[1],row[2],row[3],"All")
				}     
            }
			loop, 10 {
                row:= getRowData("R",A_Index)
                if (row[4] == 1) {
					createPostRow(row[1],row[2],row[3],"All")
				}   
            }
			loop, 10 {
                row:= getRowData("RA",A_Index)
                if (row[4] == 1) {
					createPostRow(row[1],row[2],row[3],"All")
				}   
            }
			loop, 10 {
                row:= getRowData("O",A_Index)
                if (row[4] == 1) {
					createPostRow(row[1],row[2],row[3],"All")
				}    
            }
			Clipboard := codeblockWrap()
            readyTT()
		return   
    }    
}

incCraftCount(group, craft) {	
	craftCheck := ""
	switch group {
		case "A":
		loop, 10 {
			GuiControlGet, craftCheck,, A_craft_%A_Index%, value
			if (craftCheck == craft) {    				
				GuiCOntrolGet, craftCount,, A_count_%A_index%				
				craftCount += 1 
				GuiControl,, A_count_%A_Index%, %craftCount% 
				return true 
			}			
		}		
		return
		case "R":
		loop, 10 {
			GuiControlGet, craftCheck,, R_craft_%A_Index%, value
			if (craftCheck == craft) {				
				GuiCOntrolGet, craftCount,, R_count_%A_index%				
				craftCount += 1
				GuiControl,, R_count_%A_Index%, %craftCount%
				return true
			}	
		}
		return
		case "RA":
		loop, 10 { 
			GuiControlGet, craftCheck,, RA_craft_%A_Index%, value
			if (craftCheck == craft) {				
				GuiCOntrolGet, craftCount,, RA_count_%A_index%				
				craftCount += 1
				GuiControl,, RA_count_%A_Index%, %craftCount%
				return true
			}
		}
		return
		case "O":
		loop, 10 {
			GuiControlGet, craftCheck,, O_craft_%A_Index%, value
			if (craftCheck == craft) {				
				GuiCOntrolGet, craftCount,, O_count_%A_index%				
				craftCount += 1
				GuiControl,, O_count_%A_Index%, %craftCount%
				return true
			}
		}
		return
	}
}

getLVL(craft) {
	lvlpos := RegExMatch(craft, "Level \d\d") + 6
	lv := substr(craft, lvlpos, 2)
	if RegExMatch(lv, "\d\d") > 0 {	
		return lv
	} 
	else {
		return 0
	}
}

insertIntoRow(group, rowCounter, craft) {
    GuiControl,, %group%_craft_%rowCounter%, %craft%
    GuiControl,, %group%_count_%rowCounter%, 1
    GuiControl,, %group%_cb_%rowCounter%, 1
}

CraftSort(ar) {
    tempC := ""
    for k in ar {        
        ;augment
        if InStr(ar[k], "Augment") = 1 {       
            tempC := ar[k]
            if not incCraftCount("A", tempC) {
				insertIntoRow("A",augmetnCounter,tempC)                
                augmetnCounter += 1
            }
			if (strLen(tempC) > AMaxLen) {
				AMaxLen := strLen(tempC)
			}

        }        
        ;remove
        else if InStr(ar[k], "Remove") = 1 and InStr(ar[k], "add") = 0 {
            ;msgbox, Remove %removeCounter%
            tempC := ar[k]
            if not incCraftCount("R", tempC) {
                insertIntoRow("R",removeCounter,tempC)  
                removeCounter += 1
            }
			if (strLen(tempC) > RMaxLen) {
				RMaxLen := strLen(tempC)
			}
        }
        ;remove/add
        else if InStr(ar[k], "Remove") = 1 and InStr(ar[k], "add") > 0 and InStr(ar[k], "non") = 0 {
            ;msgbox, RA %raCounter%
            tempC := ar[k]
            if not incCraftCount("RA", tempC) {
                insertIntoRow("RA",raCounter,tempC)
                raCounter += 1
            }
			if (strLen(tempC) > RAMaxLen) {
				RAMaxLen := strLen(tempC)
			}
        }
        ;other
        else {
        ;if InStr(ar[index], "Augment") = 0 and InStr(ar[index], "add") > 0 and InStr(ar[index], "non") = 0 {
            ;msgbox, O %otherCounter%
            tempC := ar[k]
            if not incCraftCount("O", tempC) {
                insertIntoRow("O",otherCounter,tempC)
                otherCounter += 1
            }
			if (strLen(tempC) > OMaxLen) {
				OMaxLen := strLen(tempC)
			}
        }
    }
}

getLeagues() {
    oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    oWhr.Open("GET", "http://api.pathofexile.com/leagues?type=main&compact=1", false)
    oWhr.SetRequestHeader("Content-Type", "application/json")
    ;oWhr.SetRequestHeader("Authorization", "Bearer 80b44ea9c302237f9178a137d9e86deb-20083fb12d9579469f24afa80816066b")
    oWhr.Send()
    parsed := Jxon_load(oWhr.ResponseText) 
    ;couldnt figure out how to make the number in parsed.1.id work as paramter, it doesnt like %% in there between the dots
        tempParse := parsed.1.id          
        iniWrite, %tempParse%, %A_WorkingDir%/settings.ini, Leagues, 1
        tempParse := parsed.2.id          
        iniWrite, %tempParse%, %A_WorkingDir%/settings.ini, Leagues, 2
        tempParse := parsed.3.id          
        iniWrite, %tempParse%, %A_WorkingDir%/settings.ini, Leagues, 3
        tempParse := parsed.4.id          
        iniWrite, %tempParse%, %A_WorkingDir%/settings.ini, Leagues, 4
        tempParse := parsed.5.id          
        iniWrite, %tempParse%, %A_WorkingDir%/settings.ini, Leagues, 5
        tempParse := parsed.6.id          
        iniWrite, %tempParse%, %A_WorkingDir%/settings.ini, Leagues, 6
        tempParse := parsed.7.id          
        iniWrite, %tempParse%, %A_WorkingDir%/settings.ini, Leagues, 7
        tempParse := parsed.8.id          
        iniWrite, %tempParse%, %A_WorkingDir%/settings.ini, Leagues, 8
	
	if !FileExist("settings.ini"){
		MsgBox, Looks like AHK was unable to create settings.ini`r`nThis might be because the place you have the script is write protected by Windows`r`nYou will need to place this somewhere else
	}
}

getVersion() {
	ver := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    ver.Open("GET", "https://raw.githubusercontent.com/esge/PoE-HarvestVendor/master/version.txt", false)
    ver.SetRequestHeader("Content-Type", "application/json")
    ;oWhr.SetRequestHeader("Authorization", "Bearer 80b44ea9c302237f9178a137d9e86deb-20083fb12d9579469f24afa80816066b")
    ver.Send()
    return StrReplace(StrReplace(ver.ResponseText,"`r"),"`n")
}



checkFiles() {	
	if !FileExist("Capture2Text") {
		if FileExist("Capture2Text.exe")	{
			msgbox, Looks like you put PoE-HarvestVendor.ahk into the Capture2Text folder `r`nThis is wrong `r`nTake the file out of this folder
			ExitApp
		} else {
			msgbox, I don't see the Capture2Text folder, did you download the tool ? `r`nLink is in the GitHub readme under Installation instructions
			ExitApp
		}
	}	

}


; ========================================================================
; ======================== stuff i copied from internet ==================
; ========================================================================
getSelectionCoords(ByRef x_start, ByRef x_end, ByRef y_start, ByRef y_end) {
	;Mask Screen
    Gui, Select:New
	Gui, Color, FFFFFF
	Gui +LastFound
	WinSet, Transparent, 50
    Gui, -Caption 
	Gui, +AlwaysOnTop
	Gui, Select:Show, x0 y0 h%A_ScreenHeight% w%A_ScreenWidth%,"AutoHotkeySnapshotApp"     

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
	Gui Select:Destroy
	Gui, HarvestUI:Default
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
;this is for tooltips to work, got it from examples from an AHK webinar
WM_MOUSEMOVE()
{
    static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
    CurrControl := A_GuiControl
    
    If (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
        ToolTip  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, 500
        PrevControl := CurrControl
    }
    return

    DisplayToolTip:
    SetTimer, DisplayToolTip, Off
    ToolTip % %CurrControl%_TT  ; The leading percent sign tell it to use an expression.
    SetTimer, RemoveToolTip, 7000
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
}

;==== JSON PARSER FROM https://github.com/cocobelgica/AutoHotkey-JSON ====
Jxon_Load(ByRef src, args*)
{
	static q := Chr(34)

	key := "", is_key := false
	stack := [ tree := [] ]
	is_arr := { (tree): 1 }
	next := q . "{[01234567890-tfn"
	pos := 0
    value := ""
	while ( (ch := SubStr(src, ++pos, 1)) != "" )
	{
		if InStr(" `t`n`r", ch)
			continue
		if !InStr(next, ch, true)
		{
			ln := ObjLength(StrSplit(SubStr(src, 1, pos), "`n"))
			col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))

			msg := Format("{}: line {} col {} (char {})"
			,   (next == "")      ? ["Extra data", ch := SubStr(src, pos)][1]
			  : (next == "'")     ? "Unterminated string starting at"
			  : (next == "\")     ? "Invalid \escape"
			  : (next == ":")     ? "Expecting ':' delimiter"
			  : (next == q)       ? "Expecting object key enclosed in double quotes"
			  : (next == q . "}") ? "Expecting object key enclosed in double quotes or object closing '}'"
			  : (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
			  : (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
			  : [ "Expecting JSON value(string, number, [true, false, null], object or array)"
			    , ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1) ][1]
			, ln, col, pos)

			throw Exception(msg, -1, ch)
		}

		is_array := is_arr[obj := stack[1]]

		if i := InStr("{[", ch)
		{
			val := (proto := args[i]) ? new proto : {}
			is_array? ObjPush(obj, val) : obj[key] := val
			ObjInsertAt(stack, 1, val)
			
			is_arr[val] := !(is_key := ch == "{")
			next := q . (is_key ? "}" : "{[]0123456789-tfn")
		}

		else if InStr("}]", ch)
		{
			ObjRemoveAt(stack, 1)
			next := stack[1]==tree ? "" : is_arr[stack[1]] ? ",]" : ",}"
		}

		else if InStr(",:", ch)
		{
			is_key := (!is_array && ch == ",")
			next := is_key ? q : q . "{[0123456789-tfn"
		}

		else ; string | number | true | false | null
		{
			if (ch == q) ; string
			{
				i := pos
				while i := InStr(src, q,, i+1)
				{
					val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
					static end := A_AhkVersion<"2" ? 0 : -1
					if (SubStr(val, end) != "\")
						break
				}
				if !i ? (pos--, next := "'") : 0
					continue

				pos := i ; update pos

				  val := StrReplace(val,    "\/",  "/")
				, val := StrReplace(val, "\" . q,    q)
				, val := StrReplace(val,    "\b", "`b")
				, val := StrReplace(val,    "\f", "`f")
				, val := StrReplace(val,    "\n", "`n")
				, val := StrReplace(val,    "\r", "`r")
				, val := StrReplace(val,    "\t", "`t")

				i := 0
				while i := InStr(val, "\",, i+1)
				{
					if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
						continue 2

					; \uXXXX - JSON unicode escape sequence
					xxxx := Abs("0x" . SubStr(val, i+2, 4))
					if (A_IsUnicode || xxxx < 0x100)
						val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
				}

				if is_key
				{
					key := val, next := ":"
					continue
				}
			}

			else ; number | true | false | null
			{
				val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
			
			; For numerical values, numerify integers and keep floats as is.
			; I'm not yet sure if I should numerify floats in v2.0-a ...
				static number := "number", integer := "integer"
				if val is %number%
				{
					if val is %integer%
						val += 0
				}
			; in v1.1, true,false,A_PtrSize,A_IsUnicode,A_Index,A_EventInfo,
			; SOMETIMES return strings due to certain optimizations. Since it
			; is just 'SOMETIMES', numerify to be consistent w/ v2.0-a
				else if (val == "true" || val == "false")
					val := %value% + 0
			; AHK_H has built-in null, can't do 'val := %value%' where value == "null"
			; as it would raise an exception in AHK_H(overriding built-in var)
				else if (val == "null")
					val := ""
			; any other values are invalid, continue to trigger error
				else if (pos--, next := "#")
					continue
				
				pos += i-1
			}
			
			is_array? ObjPush(obj, val) : obj[key] := val
			next := obj==tree ? "" : is_array ? ",]" : ",}"
		}
	}

	return tree[1]
}

Jxon_Dump(obj, indent:="", lvl:=1)
{
	static q := Chr(34)

	if IsObject(obj)
	{
		static Type := Func("Type")
		if Type ? (Type.Call(obj) != "Object") : (ObjGetCapacity(obj) == "")
			throw Exception("Object type not supported.", -1, Format("<Object at 0x{:p}>", &obj))

		is_array := 0
		for k in obj
			is_array := k == A_Index
		until !is_array

		static integer := "integer"
		if indent is %integer%
		{
			if (indent < 0)
				throw Exception("Indent parameter must be a postive integer.", -1, indent)
			spaces := indent, indent := ""
			Loop % spaces
				indent .= " "
		}
		indt := ""
		Loop, % indent ? lvl : 0
			indt .= indent

		lvl += 1, out := "" ; Make #Warn happy
		for k, v in obj
		{
			if IsObject(k) || (k == "")
				throw Exception("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", &obj) : "<blank>")
			
			if !is_array
				out .= ( ObjGetCapacity([k], 1) ? Jxon_Dump(k) : q . k . q ) ;// key
				    .  ( indent ? ": " : ":" ) ; token + padding
			out .= Jxon_Dump(v, indent, lvl) ; value
			    .  ( indent ? ",`n" . indt : "," ) ; token + indent
		}

		if (out != "")
		{
			out := Trim(out, ",`n" . indent)
			if (indent != "")
				out := "`n" . indt . out . "`n" . SubStr(indt, StrLen(indent)+1)
		}
		
		return is_array ? "[" . out . "]" : "{" . out . "}"
	}

	; Number
	else if (ObjGetCapacity([obj], 1) == "")
		return obj

	; String (null -> not supported by AHK)
	if (obj != "")
	{
		  obj := StrReplace(obj,  "\",    "\\")
		, obj := StrReplace(obj,  "/",    "\/")
		, obj := StrReplace(obj,    q, "\" . q)
		, obj := StrReplace(obj, "`b",    "\b")
		, obj := StrReplace(obj, "`f",    "\f")
		, obj := StrReplace(obj, "`n",    "\n")
		, obj := StrReplace(obj, "`r",    "\r")
		, obj := StrReplace(obj, "`t",    "\t")

		static needle := (A_AhkVersion<"2" ? "O)" : "") . "[^\x20-\x7e]"
		while RegExMatch(obj, needle, m)
			obj := StrReplace(obj, m[0], Format("\u{:04X}", Ord(m[0])))
	}
	
	return q . obj . q
}

WebPic(WB, Website, Options := "") {
	RegExMatch(Options, "i)w\K\d+", W), (W = "") ? W := 50 :
	RegExMatch(Options, "i)h\K\d+", H), (H = "") ? H := 50 :
	RegExMatch(Options, "i)c\K\d+", C), (C = "") ? C := "EEEEEE" :
	WB.Silent := True
	HTML_Page :=
	(RTRIM
	"<!DOCTYPE html>
		<html>
			<head>
				<style>
					body {
						background-color: #" C ";
					}
					img {
						top: 0px;
						left: 0px;
					}
				</style>
			</head>
			<body>
				<img src=""" Website """ alt=""Picture"" style=""width:" W "px;height:" H "px;"" />
			</body>
		</html>"
	)
	While (WB.Busy)
		Sleep 10
	WB.Navigate("about:" HTML_Page)
	Return HTML_Page
}

; === all variables for GUI elements have to be global if i wanna run it from a function, so here we go ===
global League
global IGN
global postAll
global canStream
global VersionLink
global CustomText
global AddCrafts
global Help
global Apost
global Rpost
global RApost
global Opost
global A_count_1
global A_count_2
global A_count_3
global A_count_4
global A_count_5
global A_count_6
global A_count_7
global A_count_8
global A_count_9
global A_count_10
global A_craft_1
global A_craft_2
global A_craft_3
global A_craft_4
global A_craft_5
global A_craft_6
global A_craft_7
global A_craft_8
global A_craft_9
global A_craft_10
global A_price_1
global A_price_2
global A_price_3
global A_price_4
global A_price_5
global A_price_6
global A_price_7
global A_price_8
global A_price_9
global A_price_10
global A_cb_1
global A_cb_2
global A_cb_3
global A_cb_4
global A_cb_5
global A_cb_6
global A_cb_7
global A_cb_8
global A_cb_9
global A_cb_10
global R_count_1
global R_count_2
global R_count_3
global R_count_4
global R_count_5
global R_count_6
global R_count_7
global R_count_8
global R_count_9
global R_count_10
global R_craft_1
global R_craft_2
global R_craft_3
global R_craft_4
global R_craft_5
global R_craft_6
global R_craft_7
global R_craft_8
global R_craft_9
global R_craft_10
global R_price_1
global R_price_2
global R_price_3
global R_price_4
global R_price_5
global R_price_6
global R_price_7
global R_price_8
global R_price_9
global R_price_10
global R_cb_1
global R_cb_2
global R_cb_3
global R_cb_4
global R_cb_5
global R_cb_6
global R_cb_7
global R_cb_8
global R_cb_9
global R_cb_10
global RA_count_1
global RA_count_2
global RA_count_3
global RA_count_4
global RA_count_5
global RA_count_6
global RA_count_7
global RA_count_8
global RA_count_9
global RA_count_10
global RA_craft_1
global RA_craft_2
global RA_craft_3
global RA_craft_4
global RA_craft_5
global RA_craft_6
global RA_craft_7
global RA_craft_8
global RA_craft_9
global RA_craft_10
global RA_price_1
global RA_price_2
global RA_price_3
global RA_price_4
global RA_price_5
global RA_price_6
global RA_price_7
global RA_price_8
global RA_price_9
global RA_price_10
global RA_cb_1
global RA_cb_2
global RA_cb_3
global RA_cb_4
global RA_cb_5
global RA_cb_6
global RA_cb_7
global RA_cb_8
global RA_cb_9
global RA_cb_10
global O_count_1
global O_count_2
global O_count_3
global O_count_4
global O_count_5
global O_count_6
global O_count_7
global O_count_8
global O_count_9
global O_count_10
global O_craft_1
global O_craft_2
global O_craft_3
global O_craft_4
global O_craft_5
global O_craft_6
global O_craft_7
global O_craft_8
global O_craft_9
global O_craft_10
global O_price_1
global O_price_2
global O_price_3
global O_price_4
global O_price_5
global O_price_6
global O_price_7
global O_price_8
global O_price_9
global O_price_10
global O_cb_1
global O_cb_2
global O_cb_3
global O_cb_4
global O_cb_5
global O_cb_6
global O_cb_7
global O_cb_8
global O_cb_9
global O_cb_10