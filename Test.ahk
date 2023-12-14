
; original: https://github.com/samfisherirl/Auto-Update.ahk-AHK-v2-easily-update-ahk-apps-remotely
#requires Autohotkey v2

#include <App>
;#Include <CSV_v2>
#SingleInstance Force


; create a new App object for storing versioning info and properties
myApp := App("0VERL0DE", "Poiro")   ; refers to https://github.com/0VERL0DE/Poiro, 


;register function for error handling
;OnError(myApp.PrintCallStack)

; set target path for App installation
myApp.SetInstallPath(A_Appdata "\Poiro")

; set target path for Log file
myApp.setLogPath(A_Appdata "\Poiro")

; Update app object with latest info from Github
myApp.GetGitInfo()


; Check local version
oUpdateInfo := myApp.VersionCheck()

; update
if (oUpdateInfo) {
    sUpdateNotification := oUpdateInfo["repo"] . oUpdateInfo["localversion"] . " needs an update.`nRelease notes: " . oUpdateInfo["releaseNotes"]
    ; Option to update/cancel
    Msgbox(sUpdateNotification)

    ; update this app
    myApp.update()
} Else {

    Msgbox "no update needed"
}


return

