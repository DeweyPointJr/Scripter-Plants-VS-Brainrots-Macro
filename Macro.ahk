#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.



; GLOBAL VARIABLES

global RobloxWindow
global iniFile := A_ScriptDir "\config.ini"

global AutoCollectMoney

global doubleScrolls := [8, 10, 12, 14]

global itemPositions := [419, 483, 555, 623, 687, 754, 821, 749, 820, 741, 810, 735, 806, 733, 799]

; === Read from INI ===
iniFile := "config.ini"

IniRead, StartHotkey, %iniFile%, Settings, StartHotkey, F1
IniRead, PauseHotkey, %iniFile%, Settings, PauseHotkey, F2
IniRead, StopHotkey, %iniFile%, Settings, StopHotkey, F3

; === Bind Hotkeys Dynamically ===
Hotkey, %StartHotkey%, StartHotkeyLabel
Hotkey, %PauseHotkey%, PauseHotkeyLabel
Hotkey, %StopHotkey%, StopHotkeyLabel

; === Positiniong ===
global backpackBtnX
global backpackBtnY

IniRead, backpackBtnX, %iniFile%, Settings, backpackBtnX, 204
IniRead, backpackBtnY, %iniFile%, Settings, backpackBtnY, 53


; ITEMS
global plants := ["Cactus", "Strawberry", "Pumpkin", "Sunflower", "Dragon Fruit", "Eggplant", "Watermelon", "Grape", "Cocotank", "Carnivorous Plant", "Mr Carrot"
                , "Tomatrio", "Shroombino", "Mango", "King Limone"]

global gears := ["Water Bucket", "Frost Grenade", "Banana Gun", "Frost Blower", "Carrot Launcher"]

; FUNCTIONS
ClickRelative(relX, relY) {
    SendMode Event
    ; Get window position and size
    WinGetPos, X, Y, W, H, Roblox
    if (ErrorLevel) {
        return
    }

    ; Calculate absolute coordinates
    clickX := Round(X +(W * relX))
    clickY := Round(Y + (H * relY))
    clickY += 3

    ; Calculate where to move the mouse to

    ; Perform the click
    MouseMove, %clickX%, %clickY%, 5
    Click ;, %clickX%, %clickY%
    Sleep, 50
    SendMode Input
}

CheckForUpdate() { 
    currentVersion := "Release1.0" ; <-- Set your current version here 
    latestURL := "https://api.github.com/repos/DeweyPointJr/Scripter-Plants-VS-Brainrots-Macro/releases/latest" 
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1") 
    whr.Open("GET", latestURL, false) 
    whr.Send() 
    whr.WaitForResponse() 
    status := whr.Status + 0 
    if (status != 200) { 
        MsgBox, Failed to fetch release info. Status: %status% return 
    } 
    json := whr.ResponseText 
    RegExMatch(json, """tag_name"":\s*""([^""]+)""", m) 
    latestVersion := m1
    if (latestVersion = "") {
        MsgBox, Could not find latest version in response.
        return
    }

    if (latestVersion != currentVersion) {
        MsgBox, 4, Update Available, New version %latestVersion% found! Download and install?
        IfMsgBox, Yes
        {
            RegExMatch(json, """zipball_url"":\s*""([^""]+)""", d)
            downloadURL := d1
            if (downloadURL = "") {
                MsgBox, Could not find zipball_url in release JSON.
                return
            }
            whr2 := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            whr2.Open("GET", downloadURL, false)
            whr2.Send()
            whr2.WaitForResponse()
            status2 := whr2.Status + 0
            if (status2 != 200) {
                MsgBox, Failed to download update file. Status: %status2%
                return
            }
            stream := ComObjCreate("ADODB.Stream")
            stream.Type := 1 ; binary
            stream.Open()
            stream.Write(whr2.ResponseBody)
            stream.SaveToFile(A_ScriptDir "\update.zip", 2)
            stream.Close()
            ; Extract the update
            RunWait, %ComSpec% /c powershell -Command "Expand-Archive -Force '%A_ScriptDir%\update.zip' '%A_ScriptDir%'",, Hide

            ; Show update log
            logFile := A_ScriptDir "\updatelog.txt"
            if FileExist(logFile) {
                FileRead, updateLog, %logFile%
                if (updateLog != "")
                    MsgBox, 64, Update Log, %updateLog%
            }

            ; Run updater and exit
            Run, %A_ScriptDir%\update.ahk
            ExitApp
        }
    }
}

CheckForUpdate()

BuyFromShop(shop) {
    global doubleScrolls, itemPositions, plants, gears, iniFile

    ; Accept either array directly or a string name
    if IsObject(shop) {
        shopItems := shop
        section := (shop = plants) ? "Plants" : "Gears"
        prefix := (shop = plants) ? "Plant" : "Gear"
    } else if (shop = "plants" || shop = "Plants") {
        shopItems := plants
        section := "Plants"
        prefix := "Plant"
    } else if (shop = "gears" || shop = "Gears") {
        shopItems := gears
        section := "Gears"
        prefix := "Gear"
    } else {
        shopItems := []
        section := ""
        prefix := ""
    }

    ; Find all selected items (read directly from config.ini)
    selectedItems := []
    for i, item in shopItems {
        IniRead, checked, %iniFile%, %section%, %prefix%%i%, 0
        if (checked = "1" || checked = 1) {
            selectedItems.Push(item)
        }
    }

    ; Build fast lookup maps
    selectedIndexMap := {}
    selectedNameMap := {}
    for k, v in selectedItems {
        selectedIndexMap[k] := true
        selectedIndexMap[v] := true
        selectedNameMap[k] := true
        selectedNameMap[v] := true
    }

    ; Build a set for double scroll indices
    doubleSet := {}
    if IsObject(doubleScrolls) {
        for _, v in doubleScrolls {
            doubleSet[v] := true
        }
    }

    ; Loop through shop items
    for index, item in shopItems {
        idx := index + 0

        ; Skip scrolling for the first item
        if (idx != 1) {
            Send, {WheelDown}
            Sleep, 500
            if (doubleSet.HasKey(idx)) {
                Send, {WheelDown}
                Sleep, 500
            }
        }

        ; If selected, click its position
        if (selectedIndexMap.HasKey(index) || selectedIndexMap.HasKey(idx) || selectedNameMap.HasKey(item)) {
            if (shop = gears && index = 5) {
                y := 721
            } else {
                y := itemPositions[index]
            }

            if (y) {
                ToolTip, Buying %item%
                Loop, 25 {
                    ClickRelative(0.48, (y/1056))
                    Sleep, 60
                }
            }
        }
        Sleep, 150
    }
    ClickRelative(0.5, 0.15)
}



; Show Gui
Gosub, MainGui
return

; MAIN LOOP

MainLoop:
    Gui, Submit

    WinGet, RobloxWindow, ID, Roblox 
    if (RobloxWindow) {
        WinActivate, ahk_id %RobloxWindow%

        ; Roblox is active. Start main macro actions.
        
        ; Check if any plants are selected (by reading config.ini where SavePlants writes them)
        anyPlantsSelected := false
        for i, item in plants {
            IniRead, checked, %iniFile%, Plants, Plant%i%, 0
            if (checked = "1" || checked = 1) {
                anyPlantsSelected := true
                break
            }
        }
        if (anyPlantsSelected) {
            Gosub, PlantShopLabel
        }

        ; Check if any gears are selected (by reading config.ini where SaveGears writes them)
        anyGearsSelected := false
        for i, item in gears {
            IniRead, checked, %iniFile%, Gears, Gear%i%, 0
            if (checked = "1" || checked = 1) {
                anyGearsSelected := true
                break
            }
        }
        if (anyGearsSelected) {
            Gosub, GearShopLabel
        }


        ; Collect Money
        IniRead, AutoCollectMoney, config.ini, Settings, AutoCollectMoney, 0
        if (AutoCollectMoney) {
            Gosub, AutoCollectMoneyLabel
            Sleep, 1000
        }
    } else {
        MsgBox, Roblox window not found!
    }

    SetTimer, MainLoop, -1000
Return

; GUI Code

MainGui:
    Gui, Destroy
    Gui, New, +Resize, Scripter Macro

    ; Title label at the top
    Gui, Add, Text, w180 h30 Center vTitleText, Scripter Plants VS Brainrots Macro [RELASE]

    ; Buttons stacked vertically
    Gui, Add, Button, w180 h40 gPlantsGui, Plants
    Gui, Add, Button, w180 h40 gGearsGui, Gears
    Gui, Add, Button, w180 h40 gSettingsGui, Settings
    Gui, Add, Button, w180 h40 gMainLoop, Start (%StartHotkey%)

    ; Show GUI
    Gui, Show, w200 h240, Scripter Macro
return

PlantsGui:
    global plants
    Gui, Destroy
    Gui, New, +Resize, Plants Selection

    yOffset := 10

    for i, plant in plants {
        ; Read saved value from config.ini
        IniRead, checked, config.ini, Plants, Plant%i%, 0
        Gui, Add, Checkbox, vPlant_%i%, %plant%
        GuiControl,, Plant_%i%, %checked%
        GuiControl, Move, Plant_%i%, x10 y%yOffset% w220 h25
        yOffset += 30
    }

    Gui, Add, Button, gSavePlants x10 y%yOffset% w100 h30, Done
    totalHeight := yOffset + 50
    Gui, Show, w250 h%totalHeight%, Plants Selection
return

SavePlants:
    global plants
    selected := []

    ; Loop through all plants and get checkbox state
    for i, plant in plants {
        GuiControlGet, checked,, Plant_%i%
        IniWrite, % checked ? 1 : 0, config.ini, Plants, Plant%i%
    }

    ; Return to Main GUI
    Gosub, MainGui
return

GearsGui:
    global gears
    Gui, Destroy
    Gui, New, +Resize, Gears Selection

    yOffset := 10

    for i, gear in gears {
        ; Read saved value from config.ini
        IniRead, checked, config.ini, Gears, Gear%i%, 0
        Gui, Add, Checkbox, vGear_%i%, %gear%
        GuiControl,, Gear_%i%, %checked%
        GuiControl, Move, Gear_%i%, x10 y%yOffset% w220 h25
        yOffset += 30
    }

    Gui, Add, Button, gSaveGears x10 y%yOffset% w100 h30, Done
    totalHeight := yOffset + 50
    Gui, Show, w250 h%totalHeight%, Gears Selection
return

SaveGears:
    global gears
    selected := []

    ; Loop through all plants and get checkbox state
    for i, gear in gears {
        GuiControlGet, checked,, Gear_%i%
        IniWrite, % checked ? 1 : 0, config.ini, Gears, Gear%i%
    }

    ; Return to Main GUI
    Gosub, MainGui
return

SettingsGui:
    Gui, Destroy
    Gui, New, +Resize, Settings

    ; Create tab control
    Gui, Add, Tab2, x10 y10 w280 h200, General|Hotkeys|Positioning

    ; === General Tab ===
    Gui, Tab, 1
    Gui, Add, Text, x20 y50, Auto Collect Money:
    IniRead, AutoCollectMoney, config.ini, Settings, AutoCollectMoney, 0
    Gui, Add, Checkbox, vAutoCollectMoney x150 y48
    GuiControl,, AutoCollectMoney, %AutoCollectMoney%

    ; === Hotkeys Tab ===
    Gui, Tab, 2
    Gui, Add, Text, x20 y50, Start Hotkey:
    Gui, Add, Edit, vStartHotkeyEdit x150 y48 w100
    GuiControl,, StartHotkeyEdit, %StartHotkey%

    Gui, Add, Text, x20 y80, Pause Hotkey:
    Gui, Add, Edit, vPauseHotkeyEdit x150 y78 w100
    GuiControl,, PauseHotkeyEdit, %PauseHotkey%

    Gui, Add, Text, x20 y110, Stop Hotkey:
    Gui, Add, Edit, vStopHotkeyEdit x150 y108 w100
    GuiControl,, StopHotkeyEdit, %StopHotkey%


    ; === Positioning Tab ===
    Gui, Tab, 3
    Gui, Add, Button, x20 y50 w100 h35 gSetBackpackPos, Set Backpack Button Position

    ; === Save Button ===
    Gui, Tab  ; Ends tab section
    Gui, Add, Button, gSaveSettings x100 y220 w100 h30, Save

    Gui, Show, w300 h260, Settings
return

SaveSettings:
    Gui, Submit, NoHide

    ; Save general to INI
    IniWrite, %AutoCollectMoney%, config.ini, Settings, AutoCollectMoney

    ; Save hotkeys to INI
    IniWrite, %StartHotkeyEdit%, config.ini, Settings, StartHotkey
    IniWrite, %PauseHotkeyEdit%, config.ini, Settings, PauseHotkey
    IniWrite, %StopHotkeyEdit%, config.ini, Settings, StopHotkey

    Reload ; hotkey changes take effect
Return

; Closing GUI exits macro
GuiClose:
    ExitApp
Return

; Hotkey Labels
StartHotkeyLabel() {
    Gosub, MainLoop
}

PauseHotkeyLabel() {
    Pause
}

StopHotkeyLabel() {
    Reload
}

; Positioning Labels
SetBackpackPos:
    MsgBox, 64, Backpack Setup, Click where your backpack button is located.
    Gui, Hide
    ; Wait for left click
    KeyWait, LButton, D
    MouseGetPos, backpackBtnX, backpackBtnY
    MsgBox, 64, Backpack Setup, Backpack button set at X %backpackBtnX% Y %backpackBtnY%

    ; Save the location
    IniWrite, %backpackBtnX%, %iniFile%, Settings, backpackBtnX
    IniWrite, %backpackBtnY%, %iniFile%, Settings, backpackBtnY
    Gui, Show
Return

; Action Labels

ClearTooltip:
    Tooltip,
Return

AutoCollectMoneyLabel:
    Sleep, 1000
    Tooltip, Collecting Money
    Click, %backpackBtnX%, %backpackBtnY%
    Sleep, 1000
    ClickRelative(0.541322, 0.58713)
    Sleep, 1000
    Click, %backpackBtnX%, %backpackBtnY%
    Tooltip, Money Collected
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Gosub, ClearTooltip
Return

PlantShopLabel:
    Tooltip, Buying Plants
    ClickRelative((1836/1936), (456/1056))
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Loop, 25 {
        Send, {WheelDown}
        Sleep, 30
    }
    Send, {e}
    Sleep, 5000
    ToolTip, Plant Shop Opened
    SetTimer, ClearTooltip, -1500
    Sleep, 200
    Loop, 25 {
        Send, {WheelUp}
        Sleep, 20
    }
    Sleep, 1000
    BuyFromShop(plants)
    Tooltip, Plants Completed
    Sleep, 1000
    Gosub, ClearTooltip

Return

GearShopLabel:
    Tooltip, Buying Gears
    ClickRelative((1836/1936), (529/1056))
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Send, {s down}
    Sleep, 800
    Send, {s up}
    Sleep, 250
    Send, {d down}
    Sleep, 1100
    Send, {d up}
    Sleep, 1000
    Loop, 25 {
        Send, {WheelDown}
        Sleep, 30
    }
    Send, {e}
    Sleep, 5000
    ToolTip, Gear Shop Opened
    SetTimer, ClearTooltip, -1500
    Sleep, 200
    Loop, 25 {
        Send, {WheelUp}
        Sleep, 20
    }
    Sleep, 1000
    BuyFromShop(gears)
    Tooltip, Gears Completed
    Sleep, 1000
    Gosub, ClearTooltip

Return