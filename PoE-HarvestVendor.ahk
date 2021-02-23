#NoEnv

#SingleInstance Force
SetWorkingDir %A_ScriptDir% 
global version := "0.5.2"
global ACounter := 1
global RCounter := 1
global RAcounter := 1
global Ocounter := 1
global outArrayCount := 0
global outArray := []	  
global arr := []
global outstring := ""
global firstGuiOpen := 0
global str := ""
global AMaxLen := 0
global RMaxLen := 0
global RAMaxLen := 0
global OMaxLen := 0
global outStyle
global x_start := 0
global y_start := 0
global x_end := 0
global y_end := 0
global rescan
global seenInstructions


iniRead, seenInstructions,  %A_WorkingDir%/settings.ini, Other, seenInstructions
if (seenInstructions == "ERROR" or seenInstructions == "") {
		IniWrite, 0, %A_WorkingDir%/settings.ini, Other, seenInstructions 	
		;GuiKey := "^+g"	
		IniRead, seenInstructions, %A_WorkingDir%/settings.ini, Other, seenInstructions
	}

IniRead, GuiKey, %A_WorkingDir%/settings.ini, Other, GuiKey
	if (GuiKey == "ERROR" or GuiKey == "") {
		IniWrite, ^+g, %A_WorkingDir%/settings.ini, Other, GuiKey 	
		;GuiKey := "^+g"	
		sleep, 250
		IniRead, GuiKey, %A_WorkingDir%/settings.ini, Other, GuiKey
	}
hotkey, %GuiKey%, OpenGui

IniRead, ScanKey, %A_WorkingDir%/settings.ini, Other, ScanKey
	if (ScanKey == "ERROR" or ScanKey == "") {
		IniWrite, ^g, %A_WorkingDir%/settings.ini, Other, ScanKey 	
		sleep, 250
		IniRead, ScanKey, %A_WorkingDir%/settings.ini, Other, ScanKey
		;ScanKey == "^g"	
	}
hotkey, %ScanKey%, Scan

IniRead, outStyle, %A_WorkingDir%/settings.ini, Other, outStyle
	if (outStyle == "ERROR") {
		IniWrite, 1, %A_WorkingDir%/settings.ini, Other, outStyle 
		outStyle := 1
	}

iniRead tempMon, %A_WorkingDir%/settings.ini, Other, mon
if (tempMon == "ERROR") { 
	tempMon := 1 
	iniWrite, %tempMon%, %A_WorkingDir%/settings.ini, Other, mon
}

if (A_AhkVersion < "1.1.27.00"){
	MsgBox, Please update your AHK `r`nYour version: %A_AhkVersion%`r`nRequired: 1.1.27.00 or more
}
; Message about hotkeys on first run

iniRead, sc, %A_WorkingDir%/settings.ini, Other, scale
if (sc == "ERROR") {
	iniWrite, 1, %A_WorkingDir%/settings.ini, Other, scale
}

checkfiles()
winCheck()
getLeagues()

if (seenInstructions == 0) {
	goto help
}

return

OpenGui: ;ctrl+shift+g opens the gui, yo go from there
	 if (firstGuiOpen == 0) {
    	buildGUI()
		loadLastSession()
	 }
    Gui, HarvestUI:Show, w1225 h380
	OnMessage(0x200, "WM_MOUSEMOVE")
	;clearAll()
Return

Scan: ;ctrl+g launches straight into the capture, opens gui afterwards	
    processCrafts("temp.txt")
    if (firstGuiOpen == 0) {
        buildGUI()
		loadLastSession()
    } 
    Gui, HarvestUI:Show, w1225 h380
	OnMessage(0x200, "WM_MOUSEMOVE") ;activates tooltip function
    craftSort(outArray)
	rememberSession()
	
return

GuiEscape:
    Gui, HarvestUI:Show
GuiClose:	
    ExitApp

Addcrafts:
	GuiControlGet, rescan, FocusV
    processCrafts("temp.txt")
    CraftSort(outArray)	
	rememberSession()
return

Clear_all:
	clearAll()    
	rememberSession()
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

price:
	GuiControlGet, priceField, FocusV
	guiControlGet, craftPrice,, %priceField%, value
	priceFieldArray := strsplit(priceField,"_")
	
	if (priceFieldArray[2] == "price") {	;i'm not quite sure why i did this if, but not gonna fiddle with it for now
		g := priceFieldArray[1] ;group
		r := priceFieldArray[3] ;row	
		
		guiControlGet, craftName,, %g%_craft_%r%, value
		if (craftName != "") {
			craftName := unlevel(craftName)
			iniWrite, %craftPrice%, %A_WorkingDir%/prices.ini, Prices, %craftName%
		}
	}
	sumPrices()
return

clearRow:
	guiControlGet, clearButton, FocusV
	buttonSplit := StrSplit(clearButton,"_")
	g := buttonSplit[1]
	r := buttonSplit[3]

	IniRead selLeague, %A_WorkingDir%/settings.ini, selectedLeague, s

	if GetKeyState("Shift") {
		guiControlGet, c,, %g%_craft_%r%, value
		guiControlGet, p,, %g%_price_%r%, value
		IniRead, l, %A_WorkingDir%/settings.ini, selectedLeague, s
		guiControlGet, cnt,, %g%_count_%r%, value
		
		fileLine := A_YYYY . "-" . A_MM . "-" . A_DD . ";" . A_Hour . ":" . A_Min . ";" . l . ";" . unlevel(c) . ";" . p . "`r`n"

		FileAppend, %fileLine%, log.csv

		if (cnt > 1) {
			cnt -= 1			
			Guicontrol,, %g%_count_%r%, %cnt%
		} else {
			GuiControl,, %g%_craft_%r%
			GuiControl,, %g%_count_%r%, 0
			GuiControl,, %g%_price_%r%
			%g%Counter -= 1
		}

	} else {
		GuiControl,, %g%_craft_%r%
		GuiControl,, %g%_count_%r%, 0
		GuiControl,, %g%_price_%r%
		%g%Counter -= 1
	}
	rememberSession()
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

CustomText:
	guiControlGet, cust,,CustomText, value
	iniWrite, %cust%, %A_WorkingDir%/settings.ini, Other, customText
	guicontrol,, CustomTextCB, 1
			
	if (RegExMatch(cust, "not|remove|aug|add") > 0) {
		guiControl, show, CustomTextWarning
	} else {
		guicontrol, hide, CustomTextWarning
	}
return

CanStream:
	guiControlGet, strim,,canStream, value
	iniWrite, %strim%, %A_WorkingDir%/settings.ini, Other, canStream
return

CustomTextCB:
	guiControlGet, custCB,,CustomTextCB, value
	iniWrite, %custCB%, %A_WorkingDir%/settings.ini, Other, CustomTextCB
	
return

Monitors:
	guiControlGet, mon,,Monitors_v, value
	iniWrite, %mon%, %A_WorkingDir%/settings.ini, Other, mon
return

help:
	IniWrite, 1, %A_WorkingDir%/settings.ini, Other, seenInstructions 
	gui Help:new

gui, font, s14
	Gui, add, text, x5 y5, Step 1
	gui, add, text, x5 y80, Step 2
	gui, add, text, x5 y380, Step 3
	Gui, add, text, x5 y540, Step 4
gui, font

gui, font, s10
;step 1
	gui, add, text, x15 y30, Default Hotkey to open the UI = Ctrl + Shift + G`r`nDefault Hotkey to start capture = Ctrl + G`r`nHotkeys can be changed in settings

;step 2	
	gui, add, text, x15 y110, Start the capture by either clicking Add Crafts button, `r`nor pressing the Capture hotkey.`r`nSelect the area with crafts:
	Gui, Add, ActiveX, x5 y120 w290 h240 vArea, Shell2.Explorer
	Area.document.body.style.overflow := "hidden"
	Edit := WebPic(Area, "https://github.com/esge/PoE-HarvestVendor/blob/master/examples/snapshotArea_s.png?raw=true", "w250 h233 cFFFFFF")
	gui, add, text, x15 y365, this can be done repeatedly to add crafts to the list

;step 3	
	gui, add, text, x15 y410, Fill in the prices (they will be remembered)`r`nand other info like: Can stream, IGN and so on if you wish to
	Gui, Add, ActiveX, x5 y430 w350 h100 vPricepic, Shell2.Explorer
	Pricepic.document.body.style.overflow := "hidden"
	Edit := WebPic(Pricepic, "https://github.com/esge/PoE-HarvestVendor/blob/master/examples/price.png?raw=true", "w298 h94 cFFFFFF")
	
;step 4
	gui, add, text, x15 y570, click: Create Posting for the section you wish`r`nNow your message is in clipboard
	
	gui, font
	Gui, Help:Show, w400 h610, Help
return
	HelpExit:
	HelpClose:	
	Gui, HarvestUI:Default
return

outStyle:
	guiControlGet, os,,outStyle, value
	iniWrite, %os%, %A_WorkingDir%/settings.ini, Other, outStyle
return

settings:
	hotkey, %GuiKey%, off
	hotkey, %ScanKey%, off
	gui Settings:new
	gui, add, Groupbox, x5 y5 w400 h90, Message formatting
		Gui, add, text, x10 y25, Output message style:
		Gui, add, dropdownList, x120 y20 w30 voutStyle goutStyle, 1|2
		iniRead, tstyle, %A_WorkingDir%/settings.ini, Other, outStyle
		guicontrol, choose, outStyle, %tstyle%
		Gui, add, text, x20 y50, 1 - No Colors, No codeblock = Words are highlighted when using discord search
		Gui, add, text, x20 y70, 2 - Codeblock, Colors = Words aren't highlighetd when using discord search

	gui, add, Groupbox, x5 y110 w400 h100, Monitor Settings
		monitors := getMonCount()
		Gui add, text, x10 y130, Select monitor:
		Gui add, dropdownList, x85 y125 w30 vMonitors_v gMonitors, %monitors%
			global Monitors_v_TT := "For when you aren't running PoE on main monitor"
		guicontrol, choose, Monitors_v, %tempMon%

		gui, add, text, x10 y150, Scale	
		iniRead, tScale,  %A_WorkingDir%/settings.ini, Other, scale
		gui, add, edit, x85 y150 w30 vScale gScale, %tScale% 
		Gui, add, text, x20 y175, - use this when you are using Other than 100`% scale in windows display settings
		Gui, add, text, x20 y195, - 100`% = 1, 150`% = 1.5 and so on

	gui, add, groupbox, x5 y215 w400 h75, Hotkeys		
		Gui, add, text, x10 y235, Open Harvest vendor: 
		iniRead, GuiKey,  %A_WorkingDir%/settings.ini, Other, GuiKey
		gui,add, hotkey, x120 y230 vGuiKey_v gGuiKey_l, %GuiKey%
		
		Gui, add, text, x10 y260, Add crafts: 
		iniRead, ScanKey,  %A_WorkingDir%/settings.ini, Other, ScanKey
		gui, add, hotkey, x120 y255 vScanKey_v gScanKey_l, %ScanKey%

	gui, add, button, x10 y295 h30 w390 gSettingsOK, Save
	gui, Settings:Show, w410 h330
	
return
SettingsExit:
SettingsClose:		
	hotkey, %GuiKey%, on
	hotkey, %ScanKey%, on
	Gui, Settings:Destroy
	Gui, HarvestUI:Default	
return

GuiKey_l:
return

ScanKey_l:
return

SettingsOK:
	iniRead, GuiKey,  %A_WorkingDir%/settings.ini, Other, GuiKey
	iniRead, ScanKey,  %A_WorkingDir%/settings.ini, Other, ScanKey

	guiControlGet, gk,, GuiKey_v, value
	guiControlGet, sk,, ScanKey_v, value

	if (GuiKey != gk and gk != "ERROR" and gk != "") {
		hotkey, %GuiKey%, off
		iniWrite, %gk%, %A_WorkingDir%/settings.ini, Other, GuiKey
		hotkey, %gk%, OpenGui
	} 
			
	if (ScanKey != sk and sk != "ERROR" and sk != ""){
		hotkey, %ScanKey%, off
		iniWrite, %sk%, %A_WorkingDir%/settings.ini, Other, ScanKey
		hotkey, %sk%, Scan
	} 

	if (gk != "ERROR" and gk != "") {
		hotkey, %gk%, on
	} else {
		hotkey, %GuiKey%, on
	}

	if (sk != "ERROR" and sk != "") {
		hotkey, %sk%, on
	} else {
		hotkey, %ScanKey%, on
	}	

	Gui, Settings:Destroy
	Gui, HarvestUI:Default
return

Scale:
	guiControlGet, sc,,Scale, value
	iniWrite, %sc%, %A_WorkingDir%/settings.ini, Other, scale
return

unlevel(craft){
	return regexreplace(craft,"( lv\d{1,2}\+?)")
}

buildGUI() {    
    firstGuiOpen := 1
    Gui HarvestUI:New,, PoE-HarvestVendor v%version%	
    ;== top stuff ==
    Gui Add, DropDownList, x10 y10 w150 vLeague gLeagueDropdown,
    leagueList() ;populate leagues dropdown and select the last used one
    Gui Add, Button, x165 y9 w80 h23 vAddCrafts gAddcrafts, Add crafts
	
	gui, add, button, x250 y9 h23 vrescanButton gAddcrafts, Add from last area
		global rescanButton_TT := "Captures again from the last selected area`r`nResets on HarvestVendor restart`r`nDoesn't have hotkey (yet)"

    Gui Add, Button, x350 y9 w80 h23 gClear_all, Clear

	Gui Add, Button, x435 y9 w80 h23 vpostAll gpostAll, Post all
		global postAll_TT := "Puts all crafts into a single post regardless of sorting - allowed only for Standard leagues"
	allowAll() 
    
	Gui Add, Button, x520 y9 w80 h23 vSettings gSettings, Settings
	
	Gui, add, text, x605 y13, You have:        ex        c in station
	gui, add, text, x655 y13 w20 vsumEx BackgroundTrans Right, 0
	gui, add, text, x690 y13 w20 vsumChaos BackgroundTrans Right, 0
	
	if (version != getVersion()) {
		gui Font, s14
		gui add, Link, x950 y10 vVersionLink, <a href="https://github.com/esge/PoE-HarvestVendor/tree/master">! New Version Available !</a>
		gui font
	}

	Gui font, s26
	Gui Add, Button, x1175 y2 w40 h40 vHelp gHelp, ?
	Gui font

	;== Bottom stuff ==
	;gui add, Text, x15 y345 w150, Custom text added to message: 
	iniRead tempCustomTextCB, %A_WorkingDir%/settings.ini, Other, customTextCB
	if (tempCustomTextCB == "ERROR") { 
		tempCustomTextCB := 0 
	}
	gui add, checkbox, x0 y345 w175 vCustomTextCB gCustomTextCB +Right, Custom text added to message: 
		global CustomTextCB_TT := "If you wish to hide Custom text for now"
	guicontrol,,CustomTextCB, %tempCustomTextCB%

	iniRead tempCustomText, %A_WorkingDir%/settings.ini, Other, customText
	if (tempCustomText == "ERROR") { 
		tempCustomText := "" 
	}
	gui add, Edit, x180 y340 w500 vCustomText gCustomText, %tempCustomText% 
		global CustomText_TT := "If you wish to add extra info to your message, will show under the WTS line"
	
	gui, font, ccda4f49
	gui add, Text, x180 y365 vCustomTextWarning ,Words 'not, remove, aug, add' might get your message removed based on the channel you are posting to. Please consult the Pins in respective channels.
	gui, font
	;
	guicontrol, hide, CustomTextWarning
	iniRead tempStream, %A_WorkingDir%/settings.ini, Other, canStream
	if (tempStream == "ERROR") { 
		tempStream := 0 
	}	
	gui add, CheckBox, x690 y345 vcanStream gCanStream, Can Stream
		global canStream_TT := "Adds: Can stream if requested. under the WTS line"
	guicontrol,,canStream, %tempStream%

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
        yrow1_cbOffset := yrow1 + 1
        Gui Add, Edit, x%Ax_count% y%yrow1% w35 vA_count_%A_Index% 
        Gui Add, UpDown, Range0-20, 0
        Gui Add, Edit, x%Ax_craft% y%yrow1% w%Awidth% vA_craft_%A_Index% 
        Gui Add, Edit, x%Ax_price% y%yrow1% w35 vA_price_%A_Index% gprice
        
		gui add, Button, x%Ax_checkbox% y%yrow1_cbOffset% w19 h19 vA_del_%A_Index% gClearRow, X 
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
        yrow1_cbOffset := yrow1 + 1
        Gui Add, Edit, x%Rx_count% y%yrow1% w35 vR_count_%A_Index%
        Gui Add, UpDown, Range0-20, 0
        Gui Add, Edit, x%Rx_craft% y%yrow1% w%Rwidth% vR_craft_%A_Index% 
        Gui Add, Edit, x%Rx_price% y%yrow1% w35 vR_price_%A_Index% gprice
     
	    gui add, Button, x%Rx_checkbox% y%yrow1_cbOffset% w19 h19 vR_del_%A_Index% gClearRow, X 
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
        yrow1_cbOffset := yrow1 + 1
        Gui Add, Edit, x%RAx_count% y%yrow1% w35 vRA_count_%A_Index%
        Gui Add, UpDown, Range0-20, 0
        Gui Add, Edit, x%RAx_craft% y%yrow1% w%RAwidth% vRA_craft_%A_Index% 
        Gui Add, Edit, x%RAx_price% y%yrow1% w35 vRA_price_%A_Index% gprice
        
		gui add, Button, x%RAx_checkbox% y%yrow1_cbOffset% w19 h19 vRA_del_%A_Index% gClearRow, X 
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
        yrow1_cbOffset := yrow1 + 1
        Gui Add, Edit, x%Ox_count% y%yrow1% w35 vO_count_%A_Index%
        Gui Add, UpDown, Range0-20, 0
        Gui Add, Edit, x%Ox_craft% y%yrow1% w%Owidth% vO_craft_%A_Index% 
        Gui Add, Edit, x%Ox_price% y%yrow1% w35 vO_price_%A_Index% gprice
        
		gui add, Button, x%Ox_checkbox% y%yrow1_cbOffset% w19 h19 vO_del_%A_Index% gClearRow, X 
        yrow1 += 25
    }    
}

; this is the part that goes through the scan and detects crafts and outputs the shortened names and levels
processCrafts(file) {
	Gui, HarvestUI:Hide    
	outArray := []	

    if ((rescan == "rescanButton" and x_start == 0) or rescan != "rescanButton" ) {
		coordTemp := SelectArea("cffc555 t50 ms")
		x_start := coordTemp[1]
		y_start := coordTemp[3]
		x_end := coordTemp[2]
		y_end := coordTemp[4]
    }
	WinActivate, Path of Exile
	sleep, 500

	Tooltip, Please Wait
	command = Capture2Text\Capture2Text.exe -s `"%x_start% %y_start% %x_end% %y_end%`" -o temp.txt -l English --trim-capture 
	RunWait, %command%
    
    sleep, 1000 ;sleep cos if i show the Gui too quick the capture will grab screenshot of gui   	
    Gui, HarvestUI:Show
	WinActivate, ahk_exe AutoHotkey.exe
	Tooltip
	if !FileExist("temp.txt") {
		MsgBox, - We were unable to create temp.txt to store text recognition results.`r`n- The tool most likely doesnt have permission to write where it is.`r`n- Moving it into a location that isnt write protected, or running as admin will fix this.
	}

	FileRead, temp, %file%
	;FileRead, temp, test2.txt

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
						continue
					} 
					else {
						outArrayCount += 1
						outArray[outArrayCount] := "Augment " . augments[a] . " lv" . getLVL(Arrayed[index])
						continue
					}
				}
			}
		}
		;Remove
		else if InStr(Arrayed[index], "Remove") = 1 {
			if InStr(Arrayed[index], "add") > 0 {				
				if InStr(Arrayed[index], "non") > 0 {
					for a in remAddsClean {
						if InStr(Arrayed[index], remAddsClean[a]) > 0  {
							outArrayCount += 1
							outArray[outArrayCount] := "Remove non-" . remAddsClean[a] . " add " . remAddsClean[a] . " lv" . getLVL(Arrayed[index]) 
							continue
						}
					}
				} 
				else if InStr(Arrayed[index], "non") = 0 {
					for a in remAddsClean {
						if InStr(Arrayed[index], remAddsClean[a]) > 0  {
							outArrayCount += 1
							outArray[outArrayCount] := "Remove " . remAddsClean[a] . " add " . remAddsClean[a] . " lv" . getLVL(Arrayed[index]) 
							continue
						}
					}
				}				
			} 
			else {
				for a in augments {
					if InStr(Arrayed[index], augments[a]) > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Remove " . augments[a] . " lv" . getLVL(Arrayed[index]) 
						continue
					}
				}	
			}					
		}
		;Reforge
		else if InStr(Arrayed[index], "Reforge") = 1 {
			;prefixes, suffixes
			if InStr(Arrayed[index], "Prefixes") > 0 {
				if InStr(Arrayed[index], "Lucky") > 0 {
					outArrayCount += 1
					outArray[outArrayCount] := "Reforge keep Prefixes Lucky lv" . getLVL(Arrayed[index])
					continue
				} 
				else {
					outArrayCount += 1
					outArray[outArrayCount] := "Reforge keep Prefixes lv" . getLVL(Arrayed[index])
					continue
				}			
			}
			else if InStr(Arrayed[index], "Suffixes") > 0 {	
				if InStr(Arrayed[index], "Lucky") > 0 {
					outArrayCount += 1
					outArray[outArrayCount] := "Reforge keep Suffixes Lucky lv" . getLVL(Arrayed[index])
					continue
				}
				else {
					outArrayCount += 1
					outArray[outArrayCount] := "Reforge keep Suffixes lv" . getLVL(Arrayed[index])	
					continue
				}
			}			
			;links
			else if (InStr(Arrayed[index], "links") > 0 and InStr(Arrayed[index], "10 times") = 0) {
				if InStr(Arrayed[index],"six") > 0 {
					outArrayCount += 1
					outArray[outArrayCount] := "Six link (6-link) lv" . getLVL(Arrayed[index])
					continue
				}	
			} 
			else if (InStr(Arrayed[index], "colour") > 0 and InStr(Arrayed[index], "10 times") = 0) {		
				for a in reforgeNonColor {
					if InStr(Arrayed[index], reforgeNonColor[a]) > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Reforge " . reforgeNonColor[a] . " into " . StrReplace(reforgeNonColor[a], "non-") . " lv" . getLVL(Arrayed[index])
						continue
					} 
				}
				for b in reforge2color {
					if InStr(Arrayed[index], reforge2color[b]) > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Reforge into " . StrReplace(reforge2color[b],"them ") . " lv" . getLVL(Arrayed[index])
						continue
					}
				}	
			} 
			else if InStr(Arrayed[index], "Influence") > 0 {				
				outArrayCount += 1
				outArray[outArrayCount] := "Reforge with Influence mod more common lv" . getLVL(Arrayed[index])
				continue
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
						continue
					}
				}
			}
			;weapon			
			else if InStr(Arrayed[index], "Weapon") > 0 {			
				for a in weapEnchants {
					if InStr(Arrayed[index], weapEnchants[a]) > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Enchant Weapon: " . weapEnchants[a] . " lv" . getLVL(Arrayed[index])
						continue
					}
				}
			}			
			;body armour
			else if InStr(Arrayed[index], "Armour") > 0 {
				for a in bodyEnchants {
					if InStr(Arrayed[index], bodyEnchants[a]) > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Enchant Body: " . bodyEnchants[a] . " lv" . getLVL(Arrayed[index])
						continue
					}
				}
			}	
			else if InStr(Arrayed[index], "Sextant") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Enchant Map: no Sextant use" . " lv" . getLVL(Arrayed[index])
				continue
			}
		}
		;Attempt
		else if InStr(Arrayed[index], "Attempt") = 1 {
			;awaken
			if InStr(Arrayed[index], "Awaken") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Attempt to Awaken a level 20 Support Gem" . " lv" . getLVL(Arrayed[index])
				continue
			}
			;scarab upgrade
			else if InStr(Arrayed[index], "Scarab") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Attempt to upgrade a Scarab" . " lv" . getLVL(Arrayed[index])
				continue
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
						continue
					}
					else if InStr(Arrayed[index], "Lightning") > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Change Lightning res to Fire res" . " lv" . getLVL(Arrayed[index])
						continue
					}
				}
				else if max(fireVal, coldVal, lightVal) == coldVal {
					if InStr(Arrayed[index], "Fire") > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Change Fire res to Cold res" . " lv" . getLVL(Arrayed[index])
						continue
					}
					else if InStr(Arrayed[index], "Lightning") > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Change Lightning res to Cold res" . " lv" . getLVL(Arrayed[index])
						continue
					}
				}
				else if max(fireVal, coldVal, lightVal) == lightVal {
					if InStr(Arrayed[index], "Fire") > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Change Fire res to Lightning res" . " lv" . getLVL(Arrayed[index])
						continue
					}
					else if InStr(Arrayed[index], "Cold") > 0 {
						outArrayCount += 1
						outArray[outArrayCount] := "Change Cold res to Lightning res" . " lv" . getLVL(Arrayed[index])
						continue
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
							continue
						}
					
						else if InStr(Arrayed[index],"experience") {
							outArrayCount += 1
							outArray[outArrayCount] := "Sacrifice gem, get " . gemPerc[a] . " exp as Lens" . " lv" . getLVL(Arrayed[index])
							continue
						}
					}
				}		
			} 
			;div cards gambling
			else if InStr(Arrayed[index], "Divination") > 1  {
				if InStr(Arrayed[index], "half a stack") > 1 {
					outArrayCount += 1
					outArray[outArrayCount] :=  "Sacrifice Div Cards" . " lv" . getLVL(Arrayed[index])
					continue
				}
				;skipping this:
				;	Sacrifice a stack of Divination Cards for that many different Divination Cards
			} else {
				continue
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
				continue
			}
			else if InStr(Arrayed[index], "Gem") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Improves the Quality of a Gem" . " lv" . getLVL(Arrayed[index])
				continue
			}
		}	
		
		else if InStr(Arrayed[index], "Fracture") = 1 {
			for a in fracture {
				if InStr(Arrayed[index], fracture[a]) > 0 {
					outArrayCount += 1
					outArray[outArrayCount] := "Fracture " . fracture[a] . " lv" . getLVL(Arrayed[index])
					continue
				}
			}
		} 		
		else if InStr(Arrayed[index], "Reroll") = 1 {
			if InStr(Arrayed[index], "Implicit") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Reroll All Lucky lv" . getLVL(Arrayed[index])
				continue
			} 
			else if InStr(Arrayed[index], "Prefix") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Reroll Prefix Lucky lv" . getLVL(Arrayed[index])
				continue
			}
			else if InStr(Arrayed[index], "Suffix") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Reroll Suffix Lucky lv" . getLVL(Arrayed[index])
				continue
			}			
		}
		else if InStr(Arrayed[index], "Randomise") = 1 {
			for a in augments {
				if InStr(Arrayed[index], augments[a]) > 0 {
					outArrayCount += 1
					outArray[outArrayCount]	:= "Randomise values of " . augments[a] . " mods lv" . getLVL(Arrayed[index])
					continue
				}
			}		
		}
		
		else if InStr(Arrayed[index], "Add") = 1 {		
			for a in addInfluence {
				if InStr(Arrayed[index],addInfluence[a]) > 0 {
					outArrayCount += 1
					outArray[outArrayCount] := 	"Add Influence to " . addInfluence[a] . " lv" . getLVL(Arrayed[index])
					continue
				}
			}
		}		
		else if InStr(Arrayed[index], "Set") = 1 {	
			if InStr(Arrayed[index], "Prismatic") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Set Implicit basic Jewel" . " lv" . getLVL(Arrayed[index])
				continue
			}
			else if InStr(Arrayed[index], "Timeless") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Set Implicit Abyss/Timeless Jewel" . " lv" . getLVL(Arrayed[index])
				continue
			}
			else if InStr(Arrayed[index], "Cluster") > 0 {
				outArrayCount += 1
				outArray[outArrayCount] := "Set Implicit Cluster Jewel"	. " lv" . getLVL(Arrayed[index])
				continue
			}				
		}
		;Synthesise
		else if InStr(Arrayed[index], "Synthesise") = 1 {			
			outArrayCount += 1
			outArray[outArrayCount] := "Synthesise an item" . " lv" . getLVL(Arrayed[index])
			continue
		}

		else if InStr(Arrayed[index], "Corrupt") = 1 {	
			continue
			;Corrupt an item 10 times, or until getting a corrupted implicit modifier

			;outArrayCount += 1
			;outArray[outArrayCount] := Arrayed[index]
		}
	 ; ignoring this section of mods
	 ; and i do realize i could put them in a single if, but this way its already neatly split if i might want to add them into processing 	
		;Exchange 
		else if InStr(Arrayed[index], "Exchange") = 1 {
			continue
			;skipping all exchange crafts assuming anybody would just use them for themselfs			
		} 
		;Upgrade
		else if InStr(Arrayed[index], "Upgrade") = 1 {
			continue
			;skipping upgrade crafts			
		}		
		else if InStr(Arrayed[index], "Split") = 1 {
			continue
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
;	for s in outArray {
;		str .= outArray[s] . "`r`n"
;	}
;	Clipboard := str
}

rememberCraft(g,r){
	guiControlGet, craftName,, %g%_craft_%r%, value
	guiControlGet, crafCount,, %g%_count_%r%, value
	blank := ""
	if (craftName != "") {
		IniWrite, %craftName%|%crafCount%, %A_WorkingDir%/settings.ini, LastSession, %g%_craft_%r%
	} else {
		IniWrite, %blank%, %A_WorkingDir%/settings.ini, LastSession, %g%_craft_%r%
	}
}

rememberSession() {
	loop, 10 {
		rememberCraft("A",A_Index)
		rememberCraft("R",A_Index)
		rememberCraft("RA",A_Index)
		rememberCraft("O",A_Index)
	}
}

loadLastSessionCraft(g,r) {
	IniRead, lastCraft, %A_WorkingDir%/settings.ini, LastSession, %g%_craft_%r%
	if (lastCraft != "" and lastCraft != "ERROR") {
		split := StrSplit(lastCraft, "|")
		craft := split[1]
		ccount := split[2]
		GuiControl, , %g%_craft_%r% , %craft%
		GuiControl, , %g%_count_%r% , %ccount%

		tempP := updatePriceInUI(craft)
		GuiControl, , %g%_price_%r% , %tempP%
	} 
}

loadLastSession(){
	loop,10{
		loadLastSessionCraft("A",A_Index)
		loadLastSessionCraft("R",A_Index)
		loadLastSessionCraft("RA",A_Index)
		loadLastSessionCraft("O",A_Index)
	}

	
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
		GuiControl,, A_price_%A_Index%
        GuiControl,, R_price_%A_Index%
        GuiControl,, RA_price_%A_Index%
        GuiControl,, O_price_%A_Index%
	}
	ACounter := 1
	RCounter := 1
	RAcounter := 1
	Ocounter := 1
	outArray := []
	arr := []
}

;enables Post All button if a Standard league is selected
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

;creates the string of leagues for League dropdown, also sets default league to Temporary SC league if there isn't one selected yet
leagueList() {
    leagueString := ""
    loop, 8 {
        IniRead, tempList, %A_WorkingDir%/settings.ini, Leagues, %A_Index%     
	   
        if InStr(tempList, "Hardcore") = 0 and InStr(tempList, "HC") = 0 {
            tempList .= " Softcore"
        } 
		if (tempList == "Hardcore") {
			tempList := "Standard Hardcore"
		}
		if InStr(tempList,"SSF") = 0 {
        	leagueString .= tempList . "|"
		}
		if (InStr(tempList, "Hardcore", true) = 0 and InStr(tempList,"SSF", true) = 0 and InStr(tempList,"Standard", true) = 0 and InStr(tempList,"HC", true) = 0){
			defaultLeague := templist
		}
    }

	iniRead, leagueCheck, %A_WorkingDir%/settings.ini, selectedLeague, s
	guicontrol,, League, %leagueString%
	if (leagueCheck == "ERROR") {		
		guicontrol, choose, League, %defaultLeague%	
    	iniWrite, %defaultLeague%, %A_WorkingDir%/settings.ini, selectedLeague, s	
	} else {
		guicontrol, choose, League, %leagueCheck%	
	}
}

; just reads whats in the row and section in the gui
getRowData(group, row) {
	GuiControlGet, tempCount,, %group%_count_%row%, value
	GuiControlGet, tempCraft,, %group%_craft_%row%, value
	GuiControlGet, tempPrice,, %group%_price_%row%, value
	if (tempCount > 0 and tempCraft != ""){
		tempCheck := 1
	}
	return [tempCount, tempCraft, tempPrice, tempCheck]
}

readyTT() {
	ClipWait
    ToolTip, Paste Ready,,,1
	sleep, 2000
	Tooltip,,,,1
}

;returns max lenght of string in selected group, this is for aligning in output message
getMaxLenghts(group){
	if (group == "All") {
		loop, 10 {
			GuiControlGet, AforLen,, A_craft_%A_Index%, value
			if (StrLen(AforLen) > AMaxLen) {
				AMaxLen := StrLen(AforLen)
			}
			GuiControlGet, RforLen,, R_craft_%A_Index%, value
			if (StrLen(RforLen) > RMaxLen) {
				RMaxLen := StrLen(RforLen)
			}
			GuiControlGet, RAforLen,, RA_craft_%A_Index%, value
			if (StrLen(RAforLen) > RAMaxLen) {
				RAMaxLen := StrLen(RAforLen)
			}
			GuiControlGet, OforLen,, O_craft_%A_Index%, value
			if (StrLen(OforLen) > OMaxLen) {
				OMaxLen := StrLen(OforLen)
			}
		}
	} 
	else {
		loop, 10 {
			GuiControlGet, %group%forLen,, %group%_craft_%A_Index%, value
			if (StrLen(%group%forLen) > %group%MaxLen) {
				%group%MaxLen := StrLen(%group%forLen)
			}
		}
	}
}
; assembles the row with craft count, name, lvl, price
createPostRow(count,craft,price,group) {
	;IniRead, outStyle, %A_WorkingDir%/settings.ini, Other, outStyle
	mySpaces := ""
	spacesCount := 0
	if (price == "") {
		price := " "
	}	

	if (group == "All") {
		spacesCount := Max(AMaxLen,RMaxLen,RAMaxLen,OMaxLen) - strlen(craft) + 1
	} 
	else {
		spacesCount := %group%MaxLen - StrLen(craft) + 1
	}

	loop, %spacesCount% {
		mySpaces .= " "
	}

	;craftLvl := RegExReplace(craft,"[^(\d\d)]","") ; this should result in a 2 digit number by deleting everything thas not a 2 digit number	
													; this failed for 1 craft: Six link (6-link) lv83
	craftlvl := SubStr(craft, regexmatch(craft,"lv(\d\d)")+2,2) ;find lvl get the 2 chars there
	
	craftNoLvl := RegExReplace(craft," lv\d\d","") ; this should result in the craft without lvl\d\d

	if (outStyle == 1) { ; no colors, no codeblock, but highlighted
		outString .= "   ``" . count . "x ``**``" . craftNoLvl . "``**``" . mySpaces . "[" . craftLvl . "]" 
		if (price == " ") {
			outString .= "```r`n"
		} else {
			outString .= " <``**``" . price . "``**``>```r`n"
		}
	}

	if (outStyle == 2) { ; message style with colors, in codeblock but text isnt highlighted in discord search
		outString .= "  " . count . "x [" . craftNoLvl . mySpaces . "]" . "[" . craftLvl . "]" 
		if (price == " ") {
			outString .= "`r`n"
		} else {
			outString .= " < " . price . " >`r`n"
		}
	}
}

codeblockWrap() {
	;IniRead, outStyle, %A_WorkingDir%/settings.ini, Other, outStyle
	if (outStyle == 1) {
		return outString
	}
	if (outStyle == 2) {
		return "``````md`r`n" . outString . "``````"
	}
}

;puts together the whole message that ends up in clipboard
createPost(group) {
	IniRead, outStyle, %A_WorkingDir%/settings.ini, Other, outStyle
    tempName := ""
	GuiControlGet, tempLeague,, League, value
	GuiControlGet, tempName,, IGN, value
	GuiControlGet, tempStream,, canStream, value
	GuiControlGet, tempCustomText,, CustomText, value
	GuiControlGet, tempCustomTextCB,, CustomTextCB, value
	
    outString := ""
	getMaxLenghts(group)
    
	if (outStyle == 1) {
		if (tempName != "") {
			outString .= "**WTS " . tempLeague . " - IGN: " . tempName . "**`r`n" 
		} else {
			outString .= "**WTS " . tempLeague . "**`r`n"
		}
		if (tempCustomText != "" and tempCustomTextCB == 1) {
			outString .= "   " . tempCustomText . "`r`n"
		}
		if (tempStream == 1 ) {
			outString .= "   *Can stream if requested*`r`n"
		}
	}
	if (outStyle == 2) {
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
	}
    
	if (group == "A") {	                 
		loop, 10 {
			row:= getRowData("A",A_Index)
			if (row[4] == 1) {
				createPostRow(row[1],row[2],row[3],"A")					
			}
		}
		Clipboard := codeblockWrap()
		readyTT()
    }
	if (group == "R") {	                  
		loop, 10 {                
			row:= getRowData("R",A_Index)
			if (row[4] == 1) {
				createPostRow(row[1],row[2],row[3],"R")
			}   
		}
		Clipboard := codeblockWrap()
		readyTT()
    }
	if (group == "RA") {					
		loop, 10 {
			row:= getRowData("RA",A_Index)
			if (row[4] == 1) {
				createPostRow(row[1],row[2],row[3],"RA")
			}   
		}
		Clipboard := codeblockWrap()
		readyTT()
	}
	if (group == "O") {	     
		loop, 10 {
			row:= getRowData("O",A_Index)
			if (row[4] == 1) {
				createPostRow(row[1],row[2],row[3],"O")
			}    
		}
		Clipboard := codeblockWrap()
		readyTT()
	}
	if (group == "All") {		
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
    }    
}

;finds out the level form raw row
getLVL(craft) {
	lvlpos := RegExMatch(craft, "Level \d\d") + 6
	lv := substr(craft, lvlpos, 2)
	if RegExMatch(lv, "\d\d") > 0 {			
		if (lv < 37) { ;ppl wouldn't sell lv 30 crafts, but sometimes OCR mistakes 8 for a 3 this just bumps it up for the 76+ rule
			lv += 50
		}
		;if (lv >= 76) {
		;	return "76+"
		;} 
		;else {
			return lv
		;}
	} 
	else {
		return "00"
	}
}

updatePriceInUI(craft){
	craft := unlevel(craft)
	iniRead, tempP, %A_WorkingDir%/prices.ini, Prices, %craft%
	if (tempP == "ERROR") {
		tempP := ""
	}
	return TempP
}

;inputs stuff into the UI
insertIntoRow(group, rowCounter, craft) {
    GuiControl,, %group%_craft_%rowCounter%, %craft%
    GuiControl,, %group%_count_%rowCounter%, 1
   
	;craft := unlevel(craft)
	;iniRead, tempP, %A_WorkingDir%/prices.ini, Prices, %craft%
	
	;if (tempP == "ERROR") {
	;;	tempP := ""
	;}
	temP := updatePriceInUI(craft)
	GuiControl,, %group%_price_%rowCounter%, %tempP%
}

;sorts crafts into correct groups
CraftSort(ar) {
    tempC := ""
    for k in ar {   
        ;augment
        if InStr(ar[k], "Augment") = 1 { 
			tempC := ar[k]  
			loop, 10 {
				GuiControlGet, isEmpty,, A_craft_%A_Index%, value
				if (isEmpty == "") {
					insertIntoRow("A", A_Index, tempC)	
					break
				} 
				else if (isEmpty == tempC) {
					GuiCOntrolGet, craftCount,, A_count_%A_index%				
					craftCount += 1 
					GuiControl,, A_count_%A_Index%, %craftCount%
					break
				}
			}                
        }        
        ;remove
        else if InStr(ar[k], "Remove") = 1 and InStr(ar[k], "add") = 0 {            
            tempC := ar[k]
			loop, 10 {
				GuiControlGet, isEmpty,, R_craft_%A_Index%, value
				if (isEmpty == "") {
					insertIntoRow("R", A_Index, tempC)	
					break
				} 
				else if (isEmpty == tempC) {
					GuiCOntrolGet, craftCount,, R_count_%A_index%				
					craftCount += 1 
					GuiControl,, R_count_%A_Index%, %craftCount%
					break
				}
			}      
        }
        ;remove/add
        else if InStr(ar[k], "Remove") = 1 and InStr(ar[k], "add") > 0 and InStr(ar[k], "non") = 0 {            
            tempC := ar[k]
            loop, 10 {
				GuiControlGet, isEmpty,, RA_craft_%A_Index%, value
				if (isEmpty == "") {
					insertIntoRow("RA", A_Index, tempC)	
					break
				} 
				else if (isEmpty == tempC) {
					GuiCOntrolGet, craftCount,, RA_count_%A_index%				
					craftCount += 1 
					GuiControl,, RA_count_%A_Index%, %craftCount%
					break
				}
			} 			
        }
        ;other
        else {        
            tempC := ar[k]
			loop, 10 {
				GuiControlGet, isEmpty,, O_craft_%A_Index%, value
				if (isEmpty == "") {
					insertIntoRow("O", A_Index, tempC)	
					break
				} 
				else if (isEmpty == tempC) {
					GuiCOntrolGet, craftCount,, O_count_%A_index%				
					craftCount += 1 
					GuiControl,, O_count_%A_Index%, %craftCount%
					break
				}
			}             
        }
    }	
}

sumPrices(){
	tempSumChaos := 0
	tempSumEx := 0
	loop, 10 {
		guiControlGet, TempA,, A_price_%A_Index%, value
		guiControlGet, TempR,, R_price_%A_Index%, value
		guiControlGet, TempRA,, RA_price_%A_Index%, value
		guiControlGet, TempO,, O_price_%A_Index%, value
		
		if (InStr(TempA, "c") > 0) {				
			tempSumChaos += strReplace(Trim(StrReplace(TempA, "c")),",",".")				
		}
		if (InStr(TempR, "c") > 0) {			
			tempSumChaos += strReplace(trim(StrReplace(TempR, "c")),",",".")			
		}
		if (InStr(TempRA, "c") > 0) {				
			tempSumChaos += strReplace(trim(StrReplace(TempRA, "c")),",",".")			
		}
		if (InStr(TempO, "c") > 0) {				
			tempSumChaos += strReplace(trim(StrReplace(TempO, "c")),",",".")			
		}
		if (InStr(TempA, "ex") > 0) {				
			tempSumEx += strReplace(Trim(StrReplace(TempA, "ex")),",",".")				
		}
		if (InStr(TempR, "ex") > 0) {			
			tempSumEx += strReplace(trim(StrReplace(TempR, "ex")),",",".")			
		}
		if (InStr(TempRA, "ex") > 0) {				
			tempSumEx += strReplace(trim(StrReplace(TempRA, "ex")),",",".")			
		}
		if (InStr(TempO, "ex") > 0) {				
			tempSumEx += strReplace(trim(StrReplace(TempO, "ex")),",",".")			
		}

	}
	tempSumChaos := tempSumChaos
	tempSumEx := round(tempSumEx,1)
	GuiControl,,sumChaos, %tempSumChaos%
	GuiControl,,sumEx, %tempSumEx%
}


winCheck(){
	if (SubStr(A_OSVersion,1,2) != "10" and !FileExist("curl.exe")) {
 		 msgbox, Looks like you aren't running win10. There might be a problem with WinHttpRequest(outdated Certificates).`r`nYou need to download curl, and place the curl.exe (just this 1 file) into the same directory as Harvest Vendor.`r`nLink in the FAQ section in readme on github
	}
}

;get list of active leagues from ggg
getLeagues() {
	leagueAPIurl := "http://api.pathofexile.com/leagues?type=main&compact=1" 
	if FileExist("curl.exe") {
		; Hack for people with outdated certificates
		shell := ComObjCreate("WScript.Shell")
		exec := shell.Exec("curl.exe -k " . leagueAPIurl)
		response := exec.StdOut.ReadAll()
	} else {
		oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    	oWhr.Open("GET", "http://api.pathofexile.com/leagues?type=main&compact=1", false)
    	oWhr.SetRequestHeader("Content-Type", "application/json")    
    	oWhr.Send()
		response := oWhr.ResponseText
	}
	parsed := Jxon_load(response) 
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

;check harvestVendor version against github
getVersion() {
	versionUrl :=  "https://raw.githubusercontent.com/esge/PoE-HarvestVendor/master/version.txt"
    if FileExist("curl.exe") {
        ; Hack for people with outdated certificates
        shell := ComObjCreate("WScript.Shell")
        exec := shell.Exec("curl.exe -k " . versionUrl)
        response := exec.StdOut.ReadAll()
    } else {
        ver := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        ver.Open("GET", "https://raw.githubusercontent.com/esge/PoE-HarvestVendor/master/version.txt", false)
        ver.SetRequestHeader("Content-Type", "application/json")
        ver.Send()
        response := ver.ResponseText
    }
    return StrReplace(StrReplace(response,"`r"),"`n")
}
; checks if capture2text exists and is in the right palce
checkFiles() {
	if !FileExist("Capture2Text") {
		if FileExist("Capture2Text.exe")	{
			msgbox, Looks like you put PoE-HarvestVendor.ahk into the Capture2Text folder `r`nThis is wrong `r`nTake the file out of this folder
			ExitApp
		} else {
			msgbox, I don't see the Capture2Text folder, did you download the tool ? `r`nLink is in the GitHub readme under Getting started section
			ExitApp
		}
	}
}
;find out monitor #
getMonCount(){
   monOut :=""
   sysGet, monCount, MonitorCount
   loop, %monCount% {
      monOut .= A_Index . "|"
   }
   return monOut
}

; find out resolution of specified monitor
monitorInfo(num){
   SysGet, Mon2, monitor, %num%
  
   x := Mon2Left
   y := Mon2Top
   height := abs(Mon2Top-Mon2Bottom)
   width := abs(Mon2Left-Mon2Right)

   return [x,y,height,width]
}




; ========================================================================
; ======================== stuff i copied from internet ==================
; ========================================================================

SelectArea(Options="") { ; by Learning one
/*
Returns selected area. Return example: 22|13|243|543
Options: (White space separated)
- c color. Default: Blue.
- t transparency. Default: 50.
- g GUI number. Default: 99.
- m CoordMode. Default: s. s = Screen, r = Relative
*/
;full screen overlay
iniRead tempMon, %A_WorkingDir%/settings.ini, Other, mon
iniRead, scale, %A_WorkingDir%/settings.ini, Other, scale
;scale := 1
cover := monitorInfo(tempMon)
coverX := cover[1]
coverY := cover[2]
coverH := cover[3] / scale
coverW := cover[4] / scale
	Gui, Select:New
	Gui, Color, 141414
	Gui +LastFound
	gui +ToolWindow
	WinSet, Transparent, 120
	Gui, -Caption 
	Gui, +AlwaysOnTop
	Gui, Select:Show, x%coverX% y%coverY% h%coverH% w%coverW%,"AutoHotkeySnapshotApp"     
	
	KeyWait, LButton, D 
	CoordMode, Mouse, Screen
	MouseGetPos, MX, MY
	CoordMode, Mouse, Relative
	MouseGetPos, rMX, rMY
	CoordMode, Mouse, Screen

	loop, parse, Options, %A_Space%	
	{
		Field := A_LoopField
		FirstChar := SubStr(Field,1,1)
		if FirstChar contains c,t,g,m
		{
			StringTrimLeft, Field, Field, 1
			%FirstChar% := Field
		}
	}
	c := (c = "") ? "Blue" : c, t := (t = "") ? "50" : t, g := (g = "") ? "99" : g , m := (m = "") ? "s" : m
	Gui %g%: Destroy
	Gui %g%: +AlwaysOnTop -caption +Border +ToolWindow +LastFound
	WinSet, Transparent, %t%
	Gui %g%: Color, %c%
	;Hotkey := RegExReplace(A_ThisHotkey,"^(\w* & |\W*)")
	While, (GetKeyState("LButton"))
	{
		Sleep, 10
		MouseGetPos, MXend, MYend		
		w := abs((MX / scale) - (MXend / scale)), h := abs((MY / scale) - (MYend / scale))
		X := (MX < MXend) ? MX : MXend
		Y := (MY < MYend) ? MY : MYend
		Gui %g%: Show, x%X% y%Y% w%w% h%h% NA
	}
	Gui %g%: Destroy
	Gui Select:Destroy
	Gui, HarvestUI:Default
	if m = s ; Screen
	{
		MouseGetPos, MXend, MYend
		If ( MX > MXend )
			temp := MX, MX := MXend, MXend := temp ;* scale
		If ( MY > MYend )
			temp := MY, MY := MYend, MYend := temp ;* scale
		Return [MX,MXend,MY,MYend]
	}
	else ; Relative
	{
		CoordMode, Mouse, Relative
		MouseGetPos, rMXend, rMYend
		If ( rMX > rMXend )
			temp := rMX, rMX := rMXend, rMXend := temp
		If ( rMY > rMYend )
			temp := rMY, rMY := rMYend, rMYend := temp
		Return [rMX,rMXend,rMY,rMYend]
	}
}

;this is for tooltips to work, got it from examples from an AHK webinar
WM_MOUSEMOVE()
{
    static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
    CurrControl := A_GuiControl
    
    If (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
        ToolTip,,,,2  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, 500
        PrevControl := CurrControl
    }
    return

    DisplayToolTip:
    SetTimer, DisplayToolTip, Off
    ToolTip % %CurrControl%_TT,,,2  ; The leading percent sign tell it to use an expression.
    SetTimer, RemoveToolTip, 7000
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip,,,,2
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
global Monitors_v
global CustomTextCB
global Settings
global outStyle
global rescanButton
global CustomTextWarning
global sumChaos
global sumEx
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
global A_del_1
global A_del_2
global A_del_3
global A_del_4
global A_del_5
global A_del_6
global A_del_7
global A_del_8
global A_del_9
global A_del_10
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
global R_del_1
global R_del_2
global R_del_3
global R_del_4
global R_del_5
global R_del_6
global R_del_7
global R_del_8
global R_del_9
global R_del_10
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
global RA_del_1
global RA_del_2
global RA_del_3
global RA_del_4
global RA_del_5
global RA_del_6
global RA_del_7
global RA_del_8
global RA_del_9
global RA_del_10
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
global O_del_1
global O_del_2
global O_del_3
global O_del_4
global O_del_5
global O_del_6
global O_del_7
global O_del_8
global O_del_9
global O_del_10
