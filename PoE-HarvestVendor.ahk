#NoEnv
#SingleInstance Force
SetBatchLines -1
SetWorkingDir %A_ScriptDir% 
global version := "0.7.10"

; === some global variables ===
global outArray := {}
global outArrayCount := 0
global rescan
global x_start := 0
global y_start := 0
global x_end := 0
global y_end := 0
global firstGuiOpen := 1
global outString
global outStyle
global MaxLen
global seenInstructions

global PID := DllCall("Kernel32\GetCurrentProcessId")

EnvGet, dir, USERPROFILE
global RoamingDir := dir . "\AppData\Roaming\PoE-HarvestVendor"

if !FileExist(RoamingDir){
    FileCreateDir, %RoamingDir%
}

global SettingsPath := RoamingDir . "\settings.ini"
global PricesPath := RoamingDir . "\prices.ini"
global LogPath := RoamingDir . "\log.csv"
global TempPath := RoamingDir . "\temp.txt"

tooltip, loading... Initializing Settings
sleep, 250
; == init settings ==
iniRead, seenInstructions,  %SettingsPath%, Other, seenInstructions
if (seenInstructions == "ERROR" or seenInstructions == "") {
		IniWrite, 0, %SettingsPath%, Other, seenInstructions 	
		;GuiKey := "^+g"	
		IniRead, seenInstructions, %SettingsPath%, Other, seenInstructions
	}

IniRead, GuiKey, %SettingsPath%, Other, GuiKey
	if (GuiKey == "ERROR" or GuiKey == "") {
		IniWrite, ^+g, %SettingsPath%, Other, GuiKey 	
		;GuiKey := "^+g"	
		sleep, 250
		IniRead, GuiKey, %SettingsPath%, Other, GuiKey
	}
hotkey, %GuiKey%, OpenGui

IniRead, ScanKey, %SettingsPath%, Other, ScanKey
	if (ScanKey == "ERROR" or ScanKey == "") {
		IniWrite, ^g, %SettingsPath%, Other, ScanKey 	
		sleep, 250
		IniRead, ScanKey, %SettingsPath%, Other, ScanKey
		;ScanKey == "^g"	
	}
hotkey, %ScanKey%, Scan

IniRead, outStyle, %SettingsPath%, Other, outStyle
	if (outStyle == "ERROR") {
		IniWrite, 1, %SettingsPath%, Other, outStyle 
		outStyle := 1
	}

iniRead tempMon, %SettingsPath%, Other, mon
if (tempMon == "ERROR") { 
	tempMon := 1 
	iniWrite, %tempMon%, %SettingsPath%, Other, mon
}

iniRead, sc, %SettingsPath%, Other, scale
if (sc == "ERROR") {
	iniWrite, 1, %SettingsPath%, Other, scale
}

checkfiles()
winCheck()

tooltip, loading... Checking AHK version
sleep, 250
; == check for ahk version ==
if (A_AhkVersion < 1.1.27.00){
	MsgBox, Please update your AHK `r`nYour version: %A_AhkVersion%`r`nRequired: 1.1.27.00 or more
}

tooltip, loading... Grabbing active leagues
getLeagues()

menu, Tray, Icon, resources\Vivid_Scalefruit_inventory_icon.png
;Menu, MySubmenu, Add, testLabel
;Menu, Tray, Add, Harvest Vendor, OpenGui
Menu, Tray, NoStandard
Menu, Tray, Add, Harvest Vendor, OpenGui
Menu, Tray, Default, Harvest Vendor
Menu, Tray, Standard

; == preload pictures that are used more than once, for performance
    count_pic := LoadPicture("resources\count.png")
    up_pic := LoadPicture("resources\up.png")
    dn_pic := LoadPicture("resources\dn.png")
    craft_pic := LoadPicture("resources\craft.png")
    lvl_pic := LoadPicture("resources\lvl.png")
    price_pic := LoadPicture("resources\price.png")
    del_pic := LoadPicture("resources\del.png")
; =================================================================

tooltip, loading... building GUI
sleep, 250
newGUI()
tooltip, ready
sleep, 500
Tooltip

if (seenInstructions == 0) {
	goto help
}
return

return

OpenGui: ;ctrl+shift+g opens the gui, yo go from there
	loadLastSession()
	if (version != getVersion()) {
		guicontrol, HarvestUI:Show, versionText
		guicontrol, HarvestUI:Show, versionLink
	}
    Gui, HarvestUI:Show, w650 h585
	OnMessage(0x200, "WM_MOUSEMOVE")
	
Return

Scan: ;ctrl+g launches straight into the capture, opens gui afterwards
    _wasVisible := IsGuiVisible("HarvestUI")
    if (processCrafts(TempPath)) {
 
        Gui, HarvestUI:Show, w650 h585
        OnMessage(0x200, "WM_MOUSEMOVE") ;activates tooltip function		
        craftSort(outArray)
		if (firstGuiOpen == 1) {
			rememberSession()
			firstGuiOpen := 0
		}
        
    } else {
        ; If processCrafts failed (e.g. the user pressed Escape), we should show the
        ; HarvestUI only if it was visible to the user before they pressed Ctrl+G
        if (_wasVisible)
            Gui, HarvestUI:Show, w650 h585
    }
return

HarvestUIGuiEscape:
HarvestUIGuiClose:
	rememberSession()	
    Gui, HarvestUI:Hide
return

newGUI() {
    Global
    Gui, HarvestUI:New,, PoE-HarvestVendor v%version% 
	;Gui -DPIScale  	;this will turn off scaling on big screens, which is nice for keeping layout but doesn't solve the font size, and fact that it would be tiny on big screens
    Gui, Color, 0x0d0d0d, 0x1A1B1B
    gui, Font, s11 cFFC555

    xColumn1 := 10
    xColumn2 := xColumn1 + 65
    xColumn3 := xColumn2 + 33 + 5
    xColumn4 := xColumn3 + 300 + 5
    xColumn5 := xColumn4 + 25 + 5
    xColumn6 := xColumn5 + 50 + 5
    xColumn7 := xColumn6 + 15 + 5
    xcolumn8 := xColumn7 + 111 + 5

    xColumnUpDn := xColumn2 + 23

    xEditOffset2 := xColumn2+1
    xEditOffset3 := xColumn3+3
    xEditOffset4 := xColumn4+1
    xEditOffset5 := xColumn5+1
    xEditOffset6 := xColumn6+1
    xEditOffset7 := xColumn7+1
    row := 90

; === Title and icon ===
    gui add, picture, x10 y10, resources\Vivid_Scalefruit_inventory_icon.png
    gui add, picture, x%xColumn3% y10, resources\title.png
    gui add, text, x380 y15, v%version%
; ======================
; === Text stuff ===
    gui, Font, s11 cA38D6D
        gui add, text, x%xColumn3% y40 vValue, You have:          ex            c in station   
        gui add, text, x%xColumn3% y63 vStored, Augs:  `t`tRems:   `tRem/Adds:  `t`tOther: 
		gui add, text, x412 y40 w100 vcrafts, Total Crafts: 
    gui, Font, s11 cFFC555
        gui add, text, x170 y40 w30 right vsumEx, 0
        gui add, text, x220 y40 w30 right vsumChaos, 0
		gui add, text, x485 y40 w30 vCraftsSum, 0
		gui add, text, x150 y64 w20 vAcount,0
		gui add, text, x250 y64 w20 vRcount,0
		gui add, text, x375 y64 w20 vRAcount,0
		gui add, text, x485 y64 w20 vOcount,0
; ==================
    gui Font, s12
		gui add, text, x460 y10 cGreen vversionText, ! New Version Available !
	;gui, Font, s11 cFFC555
		gui add, Link, x550 y30 vversionLink c0x0d0d0d, <a href="http://github.com/esge/PoE-HarvestVendor/releases/latest">Github Link</a>
		
	GuiControl, Hide, versionText
	GuiControl, Hide, versionLink
	 gui Font, s11
; === Right side ===
   ;y math: row + (23*rowNum)
    
	gui add, checkbox, x%xColumn7% y90 valwaysOnTop gAlwaysOnTop, Always on top
		iniRead tempOnTop, %SettingsPath%, Other, alwaysOnTop
		if (tempOnTop == "ERROR") { 
			tempOnTop := 0 
		}
	guicontrol,,alwaysOnTop, %tempOnTop%

    gui add, picture, x%xColumn7% y114 gAdd_crafts vaddCrafts, resources\addCrafts.png
    gui add, picture, x%xColumn7% y136 gLast_Area vrescanButton, resources\lastArea.png
    gui add, picture, x%xColumn7% y159 gClear_All vclearAll, resources\clear.png
    gui add, picture, x%xColumn7% y182 gSettings vsettings, resources\settings.png
    gui add, picture, x%xColumn7% y205 gHelp vhelp, resources\help.png

	; === Post buttons ===
	gui add, picture, x%xColumn7% y251 vpostAll gPost_all, resources\createPost.png

    ;gui add, picture, x%xColumn7% y251 gAug_post vaugPost, resources\postA.png
    ;gui add, picture, x%xColumn7% y274 gRem_post vremPost, resources\postR.png
    ;gui add, picture, x%xColumn7% y297 gRemAdd_post vremAddPost, resources\postRA.png
    ;gui add, picture, x%xColumn7% y320 gOther_post votherPost, resources\postO.png
    ;gui add, picture, x%xColumn7% y343 vpostAll gPost_all, resources\postAll.png
	;	postAll_TT := "WARNING: Don't use this for Temporary SC league on TFT Discord"

	; === League dropdown ===
    gui add, text, x%xColumn7% y370, League:
    gui add, dropdownList, x%xColumn7% y389 w115 -E0x200 +BackgroundTrans vleague gLeague_dropdown
		leagueList()

	; === can stream ===
	iniRead tempStream, %SettingsPath%, Other, canStream
	if (tempStream == "ERROR") { 
		tempStream := 0 
	}	
    gui add, checkbox, x%xColumn7% y419 vcanStream gCan_stream, Can stream
	guicontrol,,canStream, %tempStream%

	; === IGN ===
	IniRead, name, %SettingsPath%, IGN, n
	if (name == "ERROR") {
		name:=""
	}
    gui add, text, x%xColumn7% y440, IGN: 
        gui add, picture, x%xColumn7% y458, resources\ign.png
        gui, Font, s11 cA38D6D
            Gui Add, Edit, x%xEditOffset7% y459 w113 h18 -E0x200 +BackgroundTrans vign gIGN, %name%
        gui, Font, s11 cFFC555

	; === custom text checkbox ===
	iniRead tempCustomTextCB, %SettingsPath%, Other, customTextCB
	if (tempCustomTextCB == "ERROR") { 
		tempCustomTextCB := 0 
	}
    gui add, checkbox, x%xColumn7% y485 vcustomText_cb gCustom_text_cb, Custom Text: 
		guicontrol,,customText_cb, %tempCustomTextCB%
	; ============================
	; === custom text input ===
        gui add, picture,  x%xColumn7% y504, resources\text.png
		iniRead tempCustomText, %SettingsPath%, Other, customText
		if (tempCustomText == "ERROR") { 
			tempCustomText := "" 
		}
        gui, Font, s11 cA38D6D
            Gui Add, Edit, x%xEditOffset7% y505 w113 h65 -E0x200 +BackgroundTrans vcustomText gCustom_text -VScroll -WantReturn, %tempCustomText%
        gui, Font, s11 cFFC555
            custom_TT := "This will be a single line in the message"
	; ============================
    ;gui add, picture, x%xColumn7% y366, resources\leagueHeader.png
; ===============================================================================
    
; === table headers ===
    gui add, text, x%xColumn1% y%row% w60 +Right, Type
    count_beautyOffset := xColumn2 + 5
    gui add, text, x%count_beautyOffset% y%row%, #
    gui add, text, x%xColumn3% y%row%, Crafts
    gui add, text, x%xColumn4% y%row%, LvL
    gui add, text, x%xColumn5% y%row%, Price

; === table ===
    loop, 20 {
        row2 := row + 23 * A_Index
        row2p := row2+1
        row2dn := row2+10
        row2del := row2+5
        ;gui add, picture, x%xColumn1% y%row2%, resources\type.png
        gui, Font, s11 cA38D6D
            gui add, text, x%xColumn1% y%row2% vtype_%A_Index% gType w60 Right,
        gui, Font, s11 cFFC555
        
        gui add, picture, x%xColumn2% y%row2% AltSubmit , % "HBITMAP:*" count_pic ;resources\count.png
            Gui Add, Edit, x%xEditOffset2% y%row2p% w35 h18 vcount_%A_Index% gPrice -E0x200 +BackgroundTrans Center
                Gui Add, UpDown, Range0-20 vupDown_%A_Index%, 0
                guicontrol, hide, upDown_%A_Index%
            gui add, picture, x%xColumnUpDn% y%row2p% gUp vUp_%A_Index%, % "HBITMAP:*" up_pic
            gui add, picture, x%xColumnUpDn% y%row2dn% gDn vDn_%A_Index%, % "HBITMAP:*" dn_pic

        gui add, picture, x%xColumn3% y%row2% AltSubmit , % "HBITMAP:*" craft_pic ;resources\craft.png
            gui add, edit, x%xEditOffset3% y%row2p% w295 h18 -E0x200 +BackgroundTrans vcraft_%A_Index% gcraft

        gui add, picture, x%xColumn4% y%row2% AltSubmit , % "HBITMAP:*" lvl_pic ;resources\lvl.png
            gui add, edit, x%xEditOffset4% y%row2p% w23 h18 -E0x200 +BackgroundTrans Center vlvl_%A_Index% glvl

        gui add, picture, x%xColumn5% y%row2% AltSubmit , % "HBITMAP:*" price_pic ; resources\price.png
            gui add, edit, x%xEditOffset5% y%row2p% w44 h18 -E0x200 +BackgroundTrans Center vprice_%A_Index% gPrice

        gui add, picture, x%xColumn6% y%row2del% vdel_%A_Index% gclearRow AltSubmit , % "HBITMAP:*" del_pic ;resources\del.png 
            
    }
    gui, font    
    gui temp:hide
}

; === Button actions ===
Up:
    GuiControlGet, cntrl, name, %A_GuiControl%
    tempRow := getRow(cntrl)
    GuiControlget, tempCount,, count_%tempRow%
    tempCount += 1
    GuiControl,, count_%tempRow%, %tempCount%
return
Dn:
    GuiControlGet, cntrl, name, %A_GuiControl%
    tempRow := getRow(cntrl)
    GuiControlget, tempCount,, count_%tempRow%
    if (tempCount > 0) {
        tempCount -= 1
        GuiControl,, count_%tempRow%, %tempCount%
    }

return

Add_crafts: 
	buttonHold("addCrafts", "resources\addCrafts")
	GuiControlGet, rescan, name, %A_GuiControl%	
    if (processCrafts(TempPath)) {
        Gui, HarvestUI:Show, w650 h585
        CraftSort(outArray)			
        rememberSession()
    } else {
        Gui, HarvestUI:Show, w650 h585
    }
return

Last_area:
	buttonHold("rescanButton", "resources\lastArea")
	goto Add_crafts
return

Clear_all:
	buttonHold("clearAll", "resources\clear")
	clearAll()    
	rememberSession()
return

count:

return

craft:	
 	GuiControlGet, cntrl, name, %A_GuiControl%
    tempRow := getRow(cntrl)
	guiControlGet, tempCraft,, craft_%tempRow%, value
	detectType(tempCraft, tempRow)
	sumTypes()
	rememberSession()
return

lvl:

return

type:
sumTypes()
return

Price:
	GuiControlGet, priceField, name, %A_GuiControl%
	guiControlGet, craftPrice,, %priceField%, value
	priceFieldArray := strsplit(priceField,"_")
	
	if (priceFieldArray[1] == "price") {	
		
		r := priceFieldArray[2] ;row	
		
		guiControlGet, craftName,, craft_%r%, value
		if (craftName != "") {
			
			iniWrite, %craftPrice%, %PricesPath%, Prices, %craftName%
		}
	}
	if (craftPrice != "") {
		sumPrices()
		
	}
	;rememberSession()
return

Can_stream:
	guiControlGet, strim,,canStream, value
	iniWrite, %strim%, %SettingsPath%, Other, canStream
return

IGN:
	guiControlGet, lastIGN,,IGN, value
    iniWrite, %lastIGN%, %SettingsPath%, IGN, n
return

Custom_text:
	guiControlGet, cust,,customText, value
	iniWrite, %cust%, %SettingsPath%, Other, customText
	guicontrol,, customText_cb, 1
			
	;if (RegExMatch(cust, "not|remove|aug|add") > 0) {
	;	gui, Font, cRed Bold
	;	guiControl, font, customText
	;	tooltip, This message might get blocked by the discord bot because it containts not|remove|aug|add
	;} else {
	;	gui, Font, s11 cA38D6D norm	
	;	guicontrol, font, customText
	;	tooltip
	;}
return

Custom_text_cb:
	guiControlGet, custCB,,customText_cb, value
	iniWrite, %custCB%, %SettingsPath%, Other, CustomTextCB	
return

ClearRow:
    GuiControlGet, cntrl, name, %A_GuiControl%
    tempRow := getRow(cntrl)

    IniRead selLeague, %SettingsPath%, selectedLeague, s

	if GetKeyState("Shift") {
		guiControlGet, craft,, craft_%tempRow%, value
		guiControlGet, price,, price_%tempRow%, value
		IniRead, league, %SettingsPath%, selectedLeague, s
		guiControlGet, cnt,, count_%tempRow%, value
		
		fileLine := A_YYYY . "-" . A_MM . "-" . A_DD . ";" . A_Hour . ":" . A_Min . ";" . league . ";" . craft . ";" . price . "`r`n"

		FileAppend, %fileLine%, %LogPath%

		if (cnt > 1) {
			cnt -= 1			
			Guicontrol,, count_%tempRow%, %cnt%
		} else {
			GuiControl,, craft_%tempRow%
			GuiControl,, count_%tempRow%, 0
			GuiControl,, price_%tempRow%	
			GuiControl,, type_%tempRow%	
			guiControl,, lvl_%tempRow%	
		}
	} else {
		GuiControl,, craft_%tempRow%
		GuiControl,, count_%tempRow%, 0
		GuiControl,, price_%tempRow%	
		GuiControl,, type_%tempRow%	
		guiControl,, lvl_%tempRow%
	}
	rememberSession()
	
return

Aug_Post:
	buttonHold("augPost", "resources\postA")
	createPost("Aug")
return
Rem_post:
	buttonHold("remPost", "resources\postR")
	createPost("Rem")
return

RemAdd_post:
	buttonHold("remAddPost", "resources\postRA")
	createPost("Rem/Add")
return

Other_post:
	buttonHold("otherPost", "resources\postO")
	createPost("Other")
return

Post_all:
	;buttonHold("postAll", "resources\postAll")
	buttonHold("postAll", "resources\createPost")

	;guiControlGet, selectedLeague,, League, value
	;if !(InStr(selectedLeague, "HC") > 0 or InStr(selectedLeague, "Hardcore") > 0 or InStr(selectedLeague, "Standard") > 0){
	;	msgbox, You are posting All for Temporary SC league `r`nTFT has split channels based on craft types`r`nThis message will get you timed out
	;}

	createPost("All")
return

League_dropdown:
    guiControlGet, selectedLeague,,League, value
    iniWrite, %selectedLeague%, %SettingsPath%, selectedLeague, s
	;allowAll()
return

alwaysOnTop:
	guiControlGet, onTop,,alwaysOnTop, value
	iniWrite, %onTop%, %SettingsPath%, Other, alwaysOnTop
	if (onTop = 1){
		Gui, HarvestUI:+AlwaysOnTop
	}
	if (onTop = 0){
		Gui, HarvestUI:-AlwaysOnTop
	}
return
;====================================================
; === Settings UI ===================================
settings:
	iniRead tempMon, %SettingsPath%, Other, mon	
	buttonHold("settings", "resources\settings")
	hotkey, %GuiKey%, off
	hotkey, %ScanKey%, off
	gui Settings:new,, PoE-HarvestVendor - Settings
	gui, add, Groupbox, x5 y5 w400 h90, Message formatting
		Gui, add, text, x10 y25, Output message style:
		Gui, add, dropdownList, x120 y20 w30 voutStyle goutStyle, 1|2
		iniRead, tstyle, %SettingsPath%, Other, outStyle
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
		iniRead, tScale,  %SettingsPath%, Other, scale
		gui, add, edit, x85 y150 w30 vScale gScale, %tScale% 
		Gui, add, text, x20 y175, - use this when you are using Other than 100`% scale in windows display settings
		Gui, add, text, x20 y195, - 100`% = 1, 150`% = 1.5 and so on

	gui, add, groupbox, x5 y215 w400 h75, Hotkeys		
		Gui, add, text, x10 y235, Open Harvest vendor: 
		iniRead, GuiKey,  %SettingsPath%, Other, GuiKey
		gui,add, hotkey, x120 y230 vGuiKey_v gGuiKey_l, %GuiKey%
		
		Gui, add, text, x10 y260, Add crafts: 
		iniRead, ScanKey,  %SettingsPath%, Other, ScanKey
		gui, add, hotkey, x120 y255 vScanKey_v gScanKey_l, %ScanKey%

	
	gui, add, button, x10 y295 h30 w390 gOpenRoaming vSettingsFolder, Open Settings Folder
	gui, add, button, x10 y335 h30 w390 gSettingsOK, Save
	gui, Settings:Show, w410 h370
	
return
SettingsGuiClose:
	hotkey, %GuiKey%, on
	hotkey, %ScanKey%, on
	Gui, Settings:Destroy
	Gui, HarvestUI:Default	
return

GuiKey_l:
return

ScanKey_l:
return

OpenRoaming:
	explorerpath := "explorer " RoamingDir
	Run, %explorerpath%
return

outStyle:
	guiControlGet, os,,outStyle, value
	iniWrite, %os%, %SettingsPath%, Other, outStyle
return

Monitors:
	guiControlGet, mon,,Monitors_v, value
	iniWrite, %mon%, %SettingsPath%, Other, mon
return

Scale:
	guiControlGet, sc,,Scale, value
	iniWrite, %sc%, %SettingsPath%, Other, scale
return

SettingsOK:
	iniRead, GuiKey,  %SettingsPath%, Other, GuiKey
	iniRead, ScanKey,  %SettingsPath%, Other, ScanKey

	guiControlGet, gk,, GuiKey_v, value
	guiControlGet, sk,, ScanKey_v, value

	if (GuiKey != gk and gk != "ERROR" and gk != "") {
		hotkey, %GuiKey%, off
		iniWrite, %gk%, %SettingsPath%, Other, GuiKey
		hotkey, %gk%, OpenGui
	} 
			
	if (ScanKey != sk and sk != "ERROR" and sk != ""){
		hotkey, %ScanKey%, off
		iniWrite, %sk%, %SettingsPath%, Other, ScanKey
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
;====================================================
; === Help UI =======================================
help:
	buttonHold("help", "resources\help")
	IniWrite, 1, %SettingsPath%, Other, seenInstructions 
	gui Help:new,, PoE-HarvestVendor Help

gui, font, s14
	Gui, add, text, x5 y5, Step 1
	gui, add, text, x5 y80, Step 2
	gui, add, text, x5 y380, Step 3
	Gui, add, text, x5 y450, Step 4
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
	;Gui, Add, ActiveX, x5 y430 w350 h100 vPricepic, Shell2.Explorer
	;Pricepic.document.body.style.overflow := "hidden"
	;Edit := WebPic(Pricepic, "https://github.com/esge/PoE-HarvestVendor/blob/master/examples/price.png?raw=true", "w298 h94 cFFFFFF")
	
;step 4
	gui, add, text, x15 y480 w390, click: Post Augments/Removes... for the set you want to post`r`nNow your message is in clipboard`r`nCareful about Post All on TFT discord, it has separate channels for different craft types.
	

	gui, add, text, x400 y10 h590 0x11  ;Vertical Line > Etched Gray

	gui, font, s14 cRed
	Gui, Add, text, x410 y10 w380, Important:
	
	gui, font, s10
	gui, add, text, x420 y30 w370, If you are using Big resolution (more than 1080p) and have scaling for display set in windows to more than 100`% (in Display settings)`r`nYou need to go into Settings in HarvestVendor and set Scale to match whats set in windows
	gui, font, s14 cBlack

	gui, add, text, x410 y110 w380, Hidden features
	gui, font, s10
	gui, add, text, x420 y130 w370, - Holding shift while clicking the X in a row will reduce the count by 1 and also write the craft and price into log.csv (you can find it through the Settings folder button in Settings)
	gui, font
	Gui, Help:Show, w800 h610
return
HelpGuiClose:
	Gui, Help:Destroy
	Gui, HarvestUI:Default
return

; === my functions ===
processCrafts(file) {
	; the file parameter is just for the purpose of running a test script with different input files of crafts instead of doing scans
	Gui, HarvestUI:Hide    
	outArray := {}	

    if ((rescan == "rescanButton" and x_start == 0) or rescan != "rescanButton" ) {
		coordTemp := SelectArea("cffc555 t50 ms")
        if (!coordTemp OR coordTemp.Length() == 0)
            return false

        x_start := coordTemp[1]
        y_start := coordTemp[3]
        x_end := coordTemp[2]
        y_end := coordTemp[4]
    }
	WinActivate, Path of Exile
	sleep, 500

	Tooltip, Please Wait
	command = Capture2Text\Capture2Text.exe -s `"%x_start% %y_start% %x_end% %y_end%`" -o `"%TempPath%`" -l English --trim-capture
	RunWait, %command%
    
    sleep, 1000 ;sleep cos if i show the Gui too quick the capture will grab screenshot of gui   	
	WinActivate, ahk_pid %PID%
	Tooltip

	if !FileExist(TempPath) {
		MsgBox, - We were unable to create temp.txt to store text recognition results.`r`n- The tool most likely doesnt have permission to write where it is.`r`n- Moving it into a location that isnt write protected, or running as admin will fix this.
        return false
	}

	FileRead, temp, %file%
	;FileRead, temp, test2.txt

	NewLined := RegExReplace(temp, "(Reforge |Randomise |Remove |Augment |Improves |Upgrades |Upgrade |Set |Change |Exchange |Sacrifice a|Sacrifice up|Attempt |Enchant |Reroll |Fracture |Add a random |Synthesise |Split |Corrupt |Set. )" , "`r`n$1")
	Arrayed := StrSplit(NewLined, "`r`n")
	
	augments := ["Caster","Physical","Fire","Attack","Life","Cold","Speed","Defence","Lightning","Chaos","Critical","a new modifier"]
	remAddsClean := ["Caster","Physical","Fire","Attack","Life","Cold","Speed","Defence","Lightning","Chaos","Critical","Influence"]
	removes := ["Caster","Physical","Fire","Attack","Life","Cold","Speed","Defence","Lightning","Chaos","Critical"]
	;remAddsNon := ["non-Caster","non-Physical","non-Fire","non-Attack","non-Life","non-Cold","non-Speed","non-Defence","non-Lightning","non-Chaos","non-Critical"]
	reforgeNonColor := ["non-Red","non-Blue","non-Green"]
	reforge2color := ["Red and Blue","Red and Green","them Blue and Green","Red, Blue and Green","White"]
	flaskEnchants := ["Duration.","Effect.","Maximum Charges.","Charges used."]
	weapEnchants := ["Critical Strike Chance","Accuracy","Attack Speed","+1 Weapon Range","Elemental","Area of Effect"]
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
			if (inStr(Arrayed[index], "Influenced") > 0) {
				for a in augments {								
					if (InStr(Arrayed[index], augments[a]) > 0) {
						if (InStr(Arrayed[index], "Lucky") > 0) {											
							outArrayCount += 1 						 
							outArray[outArrayCount, 0] := "Augment non-influenced - " . augments[a] . " Lucky"
							outArray[outArrayCount, 1] := getLVL(Arrayed[index])
							outArray[outArrayCount, 2] := "Aug" 						
							continue
						} 
						else {
							outArrayCount += 1
							outArray[outArrayCount, 0] := "Augment non-influenced - " . augments[a]
							outArray[outArrayCount, 1] := getLVL(Arrayed[index])
							outArray[outArrayCount, 2] := "Aug" 
							continue
						}
					}
				}
			} else {
				if (InStr(Arrayed[index], "Lucky") > 0) {											
					outArrayCount += 1 						 
					outArray[outArrayCount, 0] := "Augment Influence Lucky"
					outArray[outArrayCount, 1] := getLVL(Arrayed[index])
					outArray[outArrayCount, 2] := "Aug" 						
					continue
				} 
				else {
					outArrayCount += 1
					outArray[outArrayCount, 0] := "Augment Influence"
					outArray[outArrayCount, 1] := getLVL(Arrayed[index])
					outArray[outArrayCount, 2] := "Aug" 
					continue
				}
			}
			
		}
		;Remove
		else if InStr(Arrayed[index], "Remove") = 1 {
			if (inStr(Arrayed[index], "Influenced") > 0 or inStr(Arrayed[index], "influenced") > 0) {
				if InStr(Arrayed[index], "add") > 0 {				
					if InStr(Arrayed[index], "non") > 0 {
						for a in removes {
							if InStr(Arrayed[index], removes[a]) > 0  {
								outArrayCount += 1							
								outArray[outArrayCount, 0] := "Remove non-" . removes[a] . " add " . removes[a]
								outArray[outArrayCount, 1] := getLVL(Arrayed[index])
								outArray[outArrayCount, 2] := "Other" 
								continue
							}
						}
					} 
					else if InStr(Arrayed[index], "non") = 0 {
						for a in removes {
							if InStr(Arrayed[index], removes[a]) > 0  {
								outArrayCount += 1						
								outArray[outArrayCount, 0] := "Remove " . removes[a] . " add " . removes[a]
								outArray[outArrayCount, 1] := getLVL(Arrayed[index])
								outArray[outArrayCount, 2] := "Rem/Add"
								continue
							}
						}
					}				
				} 			
				else {
					for a in augments {
						if InStr(Arrayed[index], augments[a]) > 0 {
							outArrayCount += 1						
							outArray[outArrayCount, 0] := "Remove " . augments[a]
							outArray[outArrayCount, 1] := getLVL(Arrayed[index])
							outArray[outArrayCount, 2] := "Rem"
							continue
						}
					}	
				}	
			} else {				
				if (instr(Arrayed[index], "add") > 0) {
					if InStr(Arrayed[index], "non") > 0 {
						outArrayCount += 1						
						outArray[outArrayCount, 0] := "Remove non-Influence add Influence"
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Rem"
						continue		
					}
					else if (InStr(Arrayed[index], "non") = 0) {
						outArrayCount += 1						
						outArray[outArrayCount, 0] := "Remove Influence add Influence"
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Rem"
						continue
					}
				}
				else {
					outArrayCount += 1						
					outArray[outArrayCount, 0] := "Remove Influence"
					outArray[outArrayCount, 1] := getLVL(Arrayed[index])
					outArray[outArrayCount, 2] := "Rem"
					continue	
				}				
			}				
		}
		;Reforge
		else if InStr(Arrayed[index], "Reforge") = 1 {
			;prefixes, suffixes
			if InStr(Arrayed[index], "Prefixes") > 0 {
				if InStr(Arrayed[index], "Lucky") > 0 {
					outArrayCount += 1					
					outArray[outArrayCount, 0] := "Reforge keep Prefixes Lucky"
					outArray[outArrayCount, 1] := getLVL(Arrayed[index])
					outArray[outArrayCount, 2] := "Other"
					continue
				} 
				else {
					outArrayCount += 1					
					outArray[outArrayCount, 0] := "Reforge keep Prefixes"
					outArray[outArrayCount, 1] := getLVL(Arrayed[index])
					outArray[outArrayCount, 2] := "Other"
					continue
				}			
			}
			else if InStr(Arrayed[index], "Suffixes") > 0 {	
				if InStr(Arrayed[index], "Lucky") > 0 {
					outArrayCount += 1
					outArray[outArrayCount, 0] := "Reforge keep Suffixes Lucky"
					outArray[outArrayCount, 1] := getLVL(Arrayed[index])
					outArray[outArrayCount, 2] := "Other"
					continue
				}
				else {
					outArrayCount += 1						
					outArray[outArrayCount, 0] := "Reforge keep Suffixes"
					outArray[outArrayCount, 1] := getLVL(Arrayed[index])
					outArray[outArrayCount, 2] := "Other"
					continue
				}
			; reforge rares
			} else if (InStr(Arrayed[index], "new random") > 0) { ; 'new random' text appears only in reforge rares
				for a in remAddsClean {
					if (InStr(Arrayed[index], remAddsClean[a]) > 0) {
						if (InStr(Arrayed[index], "more") > 0 ) {
							outArrayCount += 1						
							outArray[outArrayCount, 0] := "Reforge Rare - " . remAddsClean[a] . " more common"
							outArray[outArrayCount, 1] := getLVL(Arrayed[index])
							outArray[outArrayCount, 2] := "Other"
							continue
						} else {
							outArrayCount += 1						
							outArray[outArrayCount, 0] := "Reforge Rare - " . remAddsClean[a]
							outArray[outArrayCount, 1] := getLVL(Arrayed[index])
							outArray[outArrayCount, 2] := "Other"
							continue
						}
					}
				}			
			} 
			; reforge white/magic
			else if (InStr(Arrayed[index], "Normal or Magic") > 0) {
				for a in remAddsClean {
					if (InStr(Arrayed[index], remAddsClean[a]) > 0) {
						outArrayCount += 1						
						outArray[outArrayCount, 0] := "Reforge Norm/Magic - " . remAddsClean[a]
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
				}				
			} 
			;reforge same mod
			else if (InStr(Arrayed[index], "less likely") > 0){
				outArrayCount += 1						
				outArray[outArrayCount, 0] := "Reforge Rare - Same mods LESS likely"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			
			} 
			else if (InStr(Arrayed[index], "more likely") > 0){
				outArrayCount += 1						
				outArray[outArrayCount, 0] := "Reforge Rare - Same mods MORE likely"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			}
			;links
			else if (InStr(Arrayed[index], "links") > 0 and InStr(Arrayed[index], "10 times") = 0) {
				if InStr(Arrayed[index],"six") > 0 {
					outArrayCount += 1	
					outArray[outArrayCount, 0] := "Six link (6-link)"
					outArray[outArrayCount, 1] := getLVL(Arrayed[index])
					outArray[outArrayCount, 2] := "Other"
					continue
				}	
				else if InStr(Arrayed[index],"five") > 0 {
					outArrayCount += 1	
					outArray[outArrayCount, 0] := "Five link (5-link)"
					outArray[outArrayCount, 1] := getLVL(Arrayed[index])
					outArray[outArrayCount, 2] := "Other"
					continue
				}	
			} 
			else if (InStr(Arrayed[index], "colour") > 0 and InStr(Arrayed[index], "10 times") = 0) {		
				for a in reforgeNonColor {
					if InStr(Arrayed[index], reforgeNonColor[a]) > 0 {
						outArrayCount += 1
						outArray[outArrayCount, 0] := "Reforge " . reforgeNonColor[a] . " into " . StrReplace(reforgeNonColor[a], "non-")
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					} 
				}
				for b in reforge2color {
					if InStr(Arrayed[index], reforge2color[b]) > 0 {
						outArrayCount += 1						
						outArray[outArrayCount, 0] := "Reforge into " . StrReplace(reforge2color[b],"them ")
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
				}	
			} 
			else if InStr(Arrayed[index], "Influence") > 0 {				
				outArrayCount += 1				
				outArray[outArrayCount, 0] := "Reforge with Influence mod more common"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			}			
		} 
		;Enchant		
		else if InStr(Arrayed[index], "Enchant") = 1 { 
			;flask
			if InStr(Arrayed[index], "Flask") > 0 {
				for a in flaskEnchants {
					if InStr(Arrayed[index], flaskEnchants[a]) > 0 {
						tempArray := ["inc","inc","inc","reduced"]
						outArrayCount += 1						
						outArray[outArrayCount, 0] := "Enchant Flask: " . tempArray[a] . " " . flaskEnchants[a]
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
				}
			}
			;weapon			
			else if InStr(Arrayed[index], "Weapon") > 0 {			
				for a in weapEnchants {
					if InStr(Arrayed[index], weapEnchants[a]) > 0 {
						if (weapEnchants[a] == "Elemental") { ; OCR was failing to detect "Elemental Damage" properly, but "Elemental" is unique enough for detection, just gotta add "damage" for the output
							tempEnch := "Elemental Damage"
						} else {
							tempEnch := weapEnchants[a]
						}
						outArrayCount += 1						
						outArray[outArrayCount, 0] := "Enchant Weapon: " . tempEnch
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
				}
			}			
			;body armour
			else if InStr(Arrayed[index], "Armour") > 0 {
				for a in bodyEnchants {
					if InStr(Arrayed[index], bodyEnchants[a]) > 0 {
						outArrayCount += 1
						outArray[outArrayCount, 0] := "Enchant Body: " . bodyEnchants[a]
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
				}
			}	
			else if InStr(Arrayed[index], "Sextant") > 0 {
				outArrayCount += 1				
				outArray[outArrayCount, 0] := "Enchant Map: no Sextant use"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			}
		}
		;Attempt
		else if InStr(Arrayed[index], "Attempt") = 1 {
			;awaken
			if InStr(Arrayed[index], "Awaken") > 0 {
				outArrayCount += 1				
				outArray[outArrayCount, 0] := "Attempt to Awaken a level 20 Support Gem"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			}
			;scarab upgrade
			else if InStr(Arrayed[index], "Scarab") > 0 {
				outArrayCount += 1				
				outArray[outArrayCount, 0] := "Attempt to upgrade a Scarab"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
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
						outArray[outArrayCount, 0] := "Change Cold res to Fire res"
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
					else if InStr(Arrayed[index], "Lightning") > 0 {
						outArrayCount += 1						
						outArray[outArrayCount, 0] := "Change Lightning res to Fire res"
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
				}
				else if max(fireVal, coldVal, lightVal) == coldVal {
					if InStr(Arrayed[index], "Fire") > 0 {
						outArrayCount += 1						
						outArray[outArrayCount, 0] := "Change Fire res to Cold res"
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
					else if InStr(Arrayed[index], "Lightning") > 0 {
						outArrayCount += 1						
						outArray[outArrayCount, 0] := "Change Lightning res to Cold res"
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
				}
				else if max(fireVal, coldVal, lightVal) == lightVal {
					if InStr(Arrayed[index], "Fire") > 0 {
						outArrayCount += 1						
						outArray[outArrayCount, 0] := "Change Fire res to Lightning res"
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
					else if InStr(Arrayed[index], "Cold") > 0 {
						outArrayCount += 1						
						outArray[outArrayCount, 0] := "Change Cold res to Lightning res"
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
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
							outArray[outArrayCount, 0] := "Sacrifice gem, get " . gemPerc[a] . " qual as GCP"
							outArray[outArrayCount, 1] := getLVL(Arrayed[index])
							outArray[outArrayCount, 2] := "Other"
							continue
						}
					
						else if InStr(Arrayed[index],"experience") {
							outArrayCount += 1							
							outArray[outArrayCount, 0] := "Sacrifice gem, get " . gemPerc[a] . " exp as Lens"
							outArray[outArrayCount, 1] := getLVL(Arrayed[index])
							outArray[outArrayCount, 2] := "Other"
							continue
						}
					}
				}		
			} 
			;div cards gambling
			else if InStr(Arrayed[index], "Divination") > 1  {
				if InStr(Arrayed[index], "half a stack") > 1 {
					outArrayCount += 1					
					outArray[outArrayCount, 0] := "Sacrifice half stack for 0-2x return"
					outArray[outArrayCount, 1] := getLVL(Arrayed[index])
					outArray[outArrayCount, 2] := "Other"
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
				outArray[outArrayCount, 0] := "Improves the Quality of a Flask"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			}
			else if InStr(Arrayed[index], "Gem") > 0 {
				outArrayCount += 1				
				outArray[outArrayCount, 0] := "Improves the Quality of a Gem"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			}
		}	
		
		else if InStr(Arrayed[index], "Fracture") = 1 {
			for a in fracture {
				if InStr(Arrayed[index], fracture[a]) > 0 {
					outArrayCount += 1
					if (fracture[a] == "modifier") {						
						outArray[outArrayCount, 0] := "Fracture 1/5 " . fracture[a]
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])	
						outArray[outArrayCount, 2] := "Other"
					} else {						
						outArray[outArrayCount, 0] := "Fracture " . fracture[a]
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
				}
			}
		} 		
		else if InStr(Arrayed[index], "Reroll") = 1 {
			if InStr(Arrayed[index], "Implicit") > 0 {
				outArrayCount += 1				
				outArray[outArrayCount, 0] := "Reroll All Lucky"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			} 
			else if InStr(Arrayed[index], "Prefix") > 0 {
				outArrayCount += 1				
				outArray[outArrayCount, 0] := "Reroll Prefix Lucky"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			}
			else if InStr(Arrayed[index], "Suffix") > 0 {
				outArrayCount += 1				
				outArray[outArrayCount, 0] := "Reroll Suffix Lucky"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			}			
		}
		else if InStr(Arrayed[index], "Randomise") = 1 {
			if InStr(Arrayed[index], "Influence") > 0 {	
			for a in addInfluence {
					if InStr(Arrayed[index], addInfluence[a]) > 0 {
						outArrayCount += 1					
						outArray[outArrayCount, 0] := "Randomise Influence - " . addInfluence[a]
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
				}				
			}	
			else {	
				for a in augments {
					if InStr(Arrayed[index], augments[a]) > 0 {
						outArrayCount += 1					
						outArray[outArrayCount, 0] := "Randomise values of " . augments[a] . " mods"
						outArray[outArrayCount, 1] := getLVL(Arrayed[index])
						outArray[outArrayCount, 2] := "Other"
						continue
					}
				}
			}		
		}
		
		else if InStr(Arrayed[index], "Add") = 1 {		
			for a in addInfluence {
				if InStr(Arrayed[index],addInfluence[a]) > 0 {
					outArrayCount += 1					
					outArray[outArrayCount, 0] := "Add Influence to " . addInfluence[a]
					outArray[outArrayCount, 1] := getLVL(Arrayed[index])
					outArray[outArrayCount, 2] := "Other"
					continue
				}
			}
		}		
		else if InStr(Arrayed[index], "Set") = 1 {	
			if InStr(Arrayed[index], "Prismatic") > 0 {
				outArrayCount += 1				
				outArray[outArrayCount, 0] := "Set Implicit basic Jewel"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			}
			else if InStr(Arrayed[index], "Timeless") > 0 {
				outArrayCount += 1				
				outArray[outArrayCount, 0] := "Set Implicit Abyss/Timeless Jewel"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			}
			else if InStr(Arrayed[index], "Cluster") > 0 {
				outArrayCount += 1				
				outArray[outArrayCount, 0] := "Set Implicit Cluster Jewel"
				outArray[outArrayCount, 1] := getLVL(Arrayed[index])
				outArray[outArrayCount, 2] := "Other"
				continue
			}				
		}
		;Synthesise
		else if InStr(Arrayed[index], "Synthesise") = 1 {			
			outArrayCount += 1			
			outArray[outArrayCount, 0] := "Synthesise an item"
			outArray[outArrayCount, 1] := getLVL(Arrayed[index])
			outArray[outArrayCount, 2] := "Other"
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
	}
    for iFinal in outArray {
        outArray[iFinal, 0] := Trim(RegExReplace(outArray[iFinal, 0] , " +", " ")) 
    }	
	;this bit is for testing purposes, it should never trigger for normal user cos processCrafts is always run with temp.txt 
	if (file != TempPath) {
		for s in outArray {
			str .= outArray[s, 0] . "`r`n"
		}
		path := "results\out-" . file
		FileAppend, %str%, %path%
	}
    return true
}

CraftSort(ar) {	
    tempC := ""

    for k in ar {   
		tempC := ar[k, 0]
		tempLvl := ar[k, 1] 
		tempType := ar[k, 2]   

		loop, 20 {
			GuiControlGet, craftInGui,, craft_%A_Index%, value
			GuiControlGet, lvlInGui,, lvl_%A_Index%, value
			if (craftInGui == ""){
				insertIntoRow(A_Index, tempC, tempLvl, tempType)
				break
			} else if (craftInGui == tempC and lvlInGui == tempLvl) {
				GuiControlGet, craftCount,, count_%A_index%				
				craftCount += 1 
				GuiControl,, count_%A_Index%, %craftCount%
				break
			}					
        }
    }	
}

firstEmptyRow(){
	loop, 20{
		GuiControlGet, craftInGui,, craft_%A_Index%, value
		if (craftInGui == ""){
			return %A_Index%
			break
		}
	}
}

detectType(craft, row){
	if (craft = "") {
		guicontrol,, type_%row%,
	} 
	else if (inStr(craft, "Augment") = 1 ){
		guicontrol,, type_%row%, Aug
	} 
	else if (InStr(craft, "Remove") = 1 and instr(craft, "add") = 0) {
		guicontrol,, type_%row%, Rem
	} 
	else if (inStr(craft, "Remove") = 1 and instr(craft, "add") > 0 and instr(craft, "non") = 0) {
 		guicontrol,, type_%row%, Rem/Add
	}
	else {
		guicontrol,, type_%row%, Other
	}
}

insertIntoRow(rowCounter, craft, lvl, type) {    
   
    GuiControl,, craft_%rowCounter%, %craft%
    GuiControl,, count_%rowCounter%, 1
    guicontrol,, lvl_%rowCounter%, %lvl%
	guicontrol,, type_%rowCounter%, %type%
   
	tempP := updatePriceInUI(craft)
	GuiControl,, price_%rowCounter%, %tempP%
}

; === Discord message creation ===
createPostRow(count,craft,price,group,lvl) {
	;IniRead, outStyle, %SettingsPath%, Other, outStyle
	mySpaces := ""
	spacesCount := 0
	if (price == "") {
		price := " "
	}	
	spacesCount := MaxLen - StrLen(craft) + 1

	loop, %spacesCount% {
		mySpaces .= " "
	}

	if (outStyle == 1) { ; no colors, no codeblock, but highlighted
		outString .= "   ``" . count . "x ``**``" . craft . "``**``" . mySpaces . "[" . lvl . "]" 
		if (price == " ") {
			outString .= "```r`n"
		} else {
			outString .= " <``**``" . price . "``**``>```r`n"
		}
	}

	if (outStyle == 2) { ; message style with colors, in codeblock but text isnt highlighted in discord search
		outString .= "  " . count . "x [" . craft . mySpaces . "]" . "[" . lvl . "]" 
		if (price == " ") {
			outString .= "`r`n"
		} else {
			outString .= " < " . price . " >`r`n"
		}
	}
}

codeblockWrap() {
	if (outStyle == 1) {
		return outString
	}
	if (outStyle == 2) {
		return "``````md`r`n" . outString . "``````"
	}
}

;puts together the whole message that ends up in clipboard
createPost(type) {
	IniRead, outStyle, %SettingsPath%, Other, outStyle
    tempName := ""
	GuiControlGet, tempLeague,, League, value
	GuiControlGet, tempName,, IGN, value
	GuiControlGet, tempStream,, canStream, value
	GuiControlGet, tempCustomText,, customText, value
	GuiControlGet, tempCustomTextCB,, customText_cb, value
	
	tempLeague := RegExReplace(tempLeague, "SC", "Softcore")
	tempLeague := RegExReplace(tempLeague, "HC", "Hardcore")
    outString := ""
	getMaxLenghts(type)
    
	if (outStyle == 1) {
		if (tempName != "") {
			outString .= "**WTS " . tempLeague . " - IGN: " . tempName . "** ``|  generated by HarvestVendor```r`n" 
		} else {
			outString .= "**WTS " . tempLeague . "** ``|  generated by HarvestVendor```r`n"
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
			outString .= "#WTS " . tempLeague . " - IGN: " . tempName . " |  generated by HarvestVendor`r`n" 
		} else {
			outString .= "#WTS " . tempLeague . " |  generated by HarvestVendor`r`n"
		}
		if (tempCustomText != "") {
			outString .= "  " . tempCustomText . "`r`n"
		}
		if (tempStream == 1 ) {
			outString .= "  Can stream if requested `r`n"
		}
	}
    
	loop, 20 {
		row := getRowData(type,A_Index)
		if (row[4] == 1 and row[5] == type) {
			createPostRow(row[1],row[2],row[3],row[4],row[6])
		} else if (row[4] == 1 and type == "All") {
			createPostRow(row[1],row[2],row[3],row[4],row[6])
		}
	}
	Clipboard := codeblockWrap()
	readyTT()	
}

readyTT() {
	ClipWait
    ToolTip, Paste Ready,,,1
	sleep, 2000
	Tooltip,,,,1
}

getRowData(group, row) {
	GuiControlGet, tempType,, type_%row%, value
	GuiControlGet, tempCount,, count_%row%, value
	GuiControlGet, tempCraft,, craft_%row%, value
	GuiControlGet, tempPrice,, price_%row%, value
	GuiControlGet, tempLvl,, lvl_%row%, value
	if (tempCount > 0 and tempCraft != ""){
		tempCheck := 1
	}
	return [tempCount, tempCraft, tempPrice, tempCheck, tempType, tempLvl]
}

getMaxLenghts(group){
	loop, 20{
		GuiControlGet, craftForLen,, craft_%A_Index%, value
		guiControlGet, type,, type_%A_Index%, value
		if (group == "All"){
			if (StrLen(craftForLen) > MaxLen) {
				MaxLen := StrLen(craftForLen)
			}
		} else
		if (type==group) {
			if (StrLen(craftForLen) > MaxLen) {
				MaxLen := StrLen(craftForLen)
			}
		}
	}
}
;============================================================

updatePriceInUI(craft){	
	iniRead, tempP, %PricesPath%, Prices, %craft%
	if (tempP == "ERROR") {
		tempP := ""
	}
	return TempP
}

getRow(elementVariable) {
    temp := StrSplit(elementVariable, "_")
    return temp[temp.Length()]
}

getLVL(craft) {
	lvlpos := RegExMatch(craft, "Level \d\d") + 6    
	lv := substr(craft, lvlpos, 2)
	if RegExMatch(lv, "\d\d") > 0 {			
		if (lv < 37) { ;ppl wouldn't sell lv 30 crafts, but sometimes OCR mistakes 8 for a 3 this just bumps it up for the 76+ rule
			lv += 50
		}		
		return lv		
	} 
	else if (lvlpos == 6) {
		lvlpos := RegExMatch(craft, "lv\d\d") + 2    
	    lv := substr(craft, lvlpos, 2)
        if RegExMatch(lv, "\d\d") > 0 {			
            if (lv < 37) { ;ppl wouldn't sell lv 30 crafts, but sometimes OCR mistakes 8 for a 3 this just bumps it up for the 76+ rule
                lv += 50
            }		
            return lv		
	    } 
	} else {
        return "00"
    }
}

sumPrices() {
	tempSumChaos := 0
	tempSumEx := 0
	loop, 20 {
		guiControlGet, TempCraft,, price_%A_Index%, value
		guiControlGet, countCraft,, count_%A_Index%, value		
		
		if (InStr(TempCraft, "c") > 0) {				
			tempSumChaos += strReplace(Trim(StrReplace(TempCraft, "c")),",",".") * countCraft				
		}
		
		if (InStr(TempCraft, "ex") > 0) {				
			tempSumEx += strReplace(Trim(StrReplace(TempCraft, "ex")),",",".") * countCraft			
		}		
	}
	;tempSumChaos := tempSumChaos
	tempSumEx := round(tempSumEx,1)
	GuiControl,,sumChaos, %tempSumChaos%
	GuiControl,,sumEx, %tempSumEx%
}

sumTypes() {
	Acounter := 0
	Rcounter := 0
	RAcounter := 0
	Ocounter := 0
	Allcounter := 0
	loop, 20 {
		GuiControlget, tempType,, type_%A_Index%, value
		;msgBox %tempType%
		if (tempType == "Aug") {
			Acounter += 1			
		}
		if (tempType == "Rem") {
			Rcounter += 1
		}
		if (tempType == "Rem/Add") {
			RAcounter += 1
		}
		if (tempType == "Other") {
			Ocounter += 1
		} 		
	}
	Allcounter := Acounter + Rcounter + RAcounter + Ocounter
	Guicontrol,, Acount, %Acounter%
	Guicontrol,, Rcount, %Rcounter%
	Guicontrol,, RAcount, %RAcounter%
	Guicontrol,, Ocount, %Ocounter%
	Guicontrol,, CraftsSum, %Allcounter%
	;sleep, 50
	;if (Acounter = 0) {
	;	guicontrol,, augPost, resources/postA_d.png
	;} else {
	;	guicontrol,, augPost, resources/postA.png
	;}
	;if (Rcounter = 0) {
	;	guicontrol,, remPost, resources/postR_d.png
	;} else {
	;	guicontrol,, remPost, resources/postR.png
	;}
	;if (RAcounter = 0) {
	;	guicontrol,, remAddPost, resources/postRA_d.png
	;} else {
	;	guicontrol,, remAddPost, resources/postRA.png
	;}
	;if (Ocounter = 0) {
	;	guicontrol,, otherPost, resources/postO_d.png
	;} else {
	;	guicontrol,, otherPost, resources/postO.png
	;}
}

buttonHold(buttonV, picture) {
	while GetKeyState("LButton", "P") {
		guiControl,, %buttonV%, %picture%_i.png	
		sleep, 25
	}
	guiControl,, %buttonV%, %picture%.png
}

allowAll() {
	IniRead selLeague, %SettingsPath%, selectedLeague, s
	if (selLeague == "ERROR"){
		GuiControlGet, selLeague,, LeagueDropdown, value
	}
	if (InStr(selLeague, "Standard") = 0 and InStr(selLeague, "Hardcore") = 0 ){
		guicontrol, Disable, postAll		
	} else {
		guicontrol, Enable, postAll
	}
}

rememberCraft(row) {
	guiControlGet, craftName,, craft_%row%, value
	guiControlGet, craftLvl,, lvl_%row%, value
	guiControlGet, crafCount,, count_%row%, value
	guiControlGet, craftType,, type_%row%, value	
	blank := ""
	if (craftName != "") {
		IniWrite, %craftName%|%craftLvl%|%crafCount%|%craftType%, %SettingsPath%, LastSession, craft_%row%
	} else {
		IniWrite, %blank%, %SettingsPath%, LastSession, craft_%row%
	}
}

rememberSession() {
	loop, 20 {
		rememberCraft(A_Index)	
	}
}

loadLastSessionCraft(row) {
	IniRead, lastCraft, %SettingsPath%, LastSession, craft_%row%
	if (lastCraft != "" and lastCraft != "ERROR") {
		split := StrSplit(lastCraft, "|")
		craft := split[1]
		lvl := split[2]
		ccount := split[3]
		type := split[4]
		;msgbox,  %row% `r`n %craft% `r`n %lvl% `r`n %ccount% `r`n %type%
		GuiControl,harvestUI:, craft_%row%, %craft%
		GuiControl,harvestUI:, count_%row%, %ccount%
		GuiControl,harvestUI:, lvl_%row%, %lvl%
		GuiControl,harvestUI:, type_%row%, %type%
		
		tempP := updatePriceInUI(craft)
		GuiControl, harvestUI: , price_%row% , %tempP%
	} 
}

loadLastSession(){
	loop,20{
		loadLastSessionCraft(A_Index)		
	}	
}

clearAll() {
    loop, 20 {
        GuiControl,, craft_%A_Index%      
        GuiControl,, count_%A_Index%, 0        
		GuiControl,, price_%A_Index%
		GuiControl,, type_%A_Index%    
		guiControl,, lvl_%A_Index%    
	}
	outArray := []
	arr := []
}
; === technical stuff i guess ===
getLeagues() {
	leagueAPIurl := "http://api.pathofexile.com/leagues?type=main&compact=1" 
	
	if FileExist("curl.exe") {
		; Hack for people with outdated certificates
		shell := ComObjCreate("WScript.Shell")
		exec := shell.Exec("curl.exe -k " . leagueAPIurl)
		response := exec.StdOut.ReadAll()		
	} else {
		oWhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    	oWhr.Open("GET", leagueAPIurl, false)
    	oWhr.SetRequestHeader("Content-Type", "application/json")    
    	oWhr.Send()
		response := oWhr.ResponseText
	}
    if (oWhr.Status == "200" or FileExist("curl.exe")) {
        if InStr(response, "Standard") > 0 {
            parsed := Jxon_load(response) 
        ;couldnt figure out how to make the number in parsed.1.id work as paramter, it doesnt like %% in there between the dots
            tempParse := parsed.1.id          
            iniWrite, %tempParse%, %SettingsPath%, Leagues, 1
            tempParse := parsed.2.id          
            iniWrite, %tempParse%, %SettingsPath%, Leagues, 2
            tempParse := parsed.3.id          
            iniWrite, %tempParse%, %SettingsPath%, Leagues, 3
            tempParse := parsed.4.id          
            iniWrite, %tempParse%, %SettingsPath%, Leagues, 4
            tempParse := parsed.5.id          
            iniWrite, %tempParse%, %SettingsPath%, Leagues, 5
            tempParse := parsed.6.id          
            iniWrite, %tempParse%, %SettingsPath%, Leagues, 6
            tempParse := parsed.7.id          
            iniWrite, %tempParse%, %SettingsPath%, Leagues, 7
            tempParse := parsed.8.id          
            iniWrite, %tempParse%, %SettingsPath%, Leagues, 8
        } else {
            IniRead, lc, %SettingsPath%, Leagues, 1
            if (lc == "ERROR" or lc == "") {
                msgbox, Unable to get list of leagues from GGG API`r`nYou will need to copy [Leagues] and [selectedLeague] sections from the example settings.ini on github
            }
        }

        if !FileExist(SettingsPath){
            MsgBox, Looks like AHK was unable to create settings.ini`r`nThis might be because the place you have the script is write protected by Windows`r`nYou will need to place this somewhere else
        }
    } else  {
        Msgbox, Unable to get active leagues from GGG API, using placeholder names
        iniWrite, Temp, %SettingsPath%, Leagues, 1
        iniWrite, Hardcore Temp, %SettingsPath%, Leagues, 2
        iniWrite, Standard, %SettingsPath%, Leagues, 3
        iniWrite, Hardcore, %SettingsPath%, Leagues, 4
    }
}

leagueList() {
    leagueString := ""
    loop, 8 {
        IniRead, tempList, %SettingsPath%, Leagues, %A_Index%     
        if (templist != "") { 	   
			if InStr(tempList, "Hardcore") = 0 and InStr(tempList, "HC") = 0 {
				tempList .= " SC"
			} 
			if (tempList == "Hardcore") {
				tempList := "Standard HC"
			}
			if InStr(tempList,"SSF") = 0 {
				leagueString .= tempList . "|"
			}
			if (InStr(tempList, "Hardcore", true) = 0 and InStr(tempList,"SSF", true) = 0 and InStr(tempList,"Standard", true) = 0 and InStr(tempList,"HC", true) = 0){
				defaultLeague := templist
			}
		}
    }

	iniRead, leagueCheck, %SettingsPath%, selectedLeague, s
	guicontrol,, League, %leagueString%
	if (leagueCheck == "ERROR") {		
		guicontrol, choose, League, %defaultLeague%	
    	iniWrite, %defaultLeague%, %SettingsPath%, selectedLeague, s	
	} else {
		guicontrol, choose, League, %leagueCheck%	
	}
}

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

IsGuiVisible(guiName) {
    Gui, %guiName%: +HwndguiHwnd
    return DllCall("User32\IsWindowVisible", "Ptr", guiHwnd)
}

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
	
	if !FileExist(SettingsPath) {
		msgbox, Looks like you put PoE-HarvestVendor in a write protected place on your PC.`r`nIt needs to be able to create and write into a few text files in its directory.
		ExitApp
	}
}

winCheck(){
	if (SubStr(A_OSVersion,1,2) != "10" and !FileExist("curl.exe")) {
 		 msgbox, Looks like you aren't running win10. There might be a problem with WinHttpRequest(outdated Certificates).`r`nYou need to download curl, and place the curl.exe (just this 1 file) into the same directory as Harvest Vendor.`r`nLink in the FAQ section in readme on github
	}
}

monitorInfo(num){
   SysGet, Mon2, monitor, %num%
  
   x := Mon2Left
   y := Mon2Top
   height := abs(Mon2Top-Mon2Bottom)
   width := abs(Mon2Left-Mon2Right)

   return [x,y,height,width]
}
getMonCount(){
   monOut := ""
   sysGet, monCount, MonitorCount
   loop, %monCount% {
      monOut .= A_Index . "|"
   }
   return monOut
}
; ========================================================================
; ======================== stuff i copied from internet ==================
; ========================================================================

global SelectAreaEscapePressed := false
SelectAreaEscape:
    SelectAreaEscapePressed := true
return

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
;press Escape to cancel

    iniRead tempMon, %SettingsPath%, Other, mon
    iniRead, scale, %SettingsPath%, Other, scale
    ;scale := 1
    cover := monitorInfo(tempMon)
    coverX := cover[1]
    coverY := cover[2]
    coverH := cover[3] / scale
    coverW := cover[4] / scale
    Gui, Select:New
    Gui, Color, 141414
    Gui, +LastFound +ToolWindow -Caption +AlwaysOnTop
    WinSet, Transparent, 120
    Gui, Select:Show, x%coverX% y%coverY% h%coverH% w%coverW%,"AutoHotkeySnapshotApp"
    
    isLButtonDown := false
    SelectAreaEscapePressed := false
    Hotkey, Escape, SelectAreaEscape, On
    while (!isLButtonDown AND !SelectAreaEscapePressed)
    {
        ; Per documentation new hotkey threads can be launched while KeyWait-ing, so SelectAreaEscapePressed
        ; will eventually be set in the SelectAreaEscape hotkey thread above when the user presses ESC.

        KeyWait, LButton, D T0.1  ; 100ms timeout
        isLButtonDown := (ErrorLevel == 0)
    }

    areaRect := []
    if (!SelectAreaEscapePressed)
    {
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
        c := (c = "") ? "Blue" : c
        t := (t = "") ? "50" : t
        g := (g = "") ? "99" : g
        m := (m = "") ? "s" : m

        Gui %g%: Destroy
        Gui %g%: +AlwaysOnTop -Caption +Border +ToolWindow +LastFound
        WinSet, Transparent, %t%
        Gui %g%: Color, %c%
        ;Hotkey := RegExReplace(A_ThisHotkey,"^(\w* & |\W*)")

        While (GetKeyState("LButton") AND !SelectAreaEscapePressed)
        {
            Sleep, 10
            MouseGetPos, MXend, MYend        
            w := abs((MX / scale) - (MXend / scale)), h := abs((MY / scale) - (MYend / scale))
            X := (MX < MXend) ? MX : MXend
            Y := (MY < MYend) ? MY : MYend
            Gui %g%: Show, x%X% y%Y% w%w% h%h% NA
        }

        Gui %g%: Destroy

        if (!SelectAreaEscapePressed)
        {
            if m = s ; Screen
            {
                MouseGetPos, MXend, MYend
                If ( MX > MXend )
                    temp := MX, MX := MXend, MXend := temp ;* scale
                If ( MY > MYend )
                    temp := MY, MY := MYend, MYend := temp ;* scale
                areaRect := [MX,MXend,MY,MYend]
            }
            else ; Relative
            {
                CoordMode, Mouse, Relative
                MouseGetPos, rMXend, rMYend
                If ( rMX > rMXend )
                    temp := rMX, rMX := rMXend, rMXend := temp
                If ( rMY > rMYend )
                    temp := rMY, rMY := rMYend, rMYend := temp
                areaRect := [rMX,rMXend,rMY,rMYend]
            }
        }
    }

    Hotkey, Escape, SelectAreaEscape, Off

    Gui, Select:Destroy
    Gui, HarvestUI:Default
    return areaRect
}




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

