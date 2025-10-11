#NoEnv
SetWorkingDir %A_ScriptDir%

; Wait for Main.ahk to exit
Sleep, 1000

; Find the extracted folder
newestTime := 0
extractedDir := ""
Loop, Files, %A_ScriptDir%\*.*, D
{
    if InStr(A_LoopFileName, "Scripter-Grow-A-Garden-Macro") {
        if (A_LoopFileTimeCreated > newestTime) {
            newestTime := A_LoopFileTimeCreated
            extractedDir := A_LoopFileFullPath
        }
    }
}



if (extractedDir != "") {
    ; Move all files up one level
    Loop, Files, %extractedDir%\*.*, F
    {
        FileMove, %A_LoopFileFullPath%, %A_ScriptDir%\%A_LoopFileName%, 1
    }
    ; Move all folders up one level
    Loop, Files, %extractedDir%\*.*, F
    {
        if (A_LoopFileName != "update.ahk") {
            FileMove, %A_LoopFileFullPath%, %A_ScriptDir%\%A_LoopFileName%, 1
        }
    }
    FileRemoveDir, %extractedDir%, 1
}
FileDelete, %A_ScriptDir%\update.zip

; Relaunch main macro
Run, %A_ScriptDir%\Main.ahk
ExitApp