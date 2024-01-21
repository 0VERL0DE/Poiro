#Requires AutoHotkey v2 
#SingleInstance Force

#include <App>

; create a new App object for storing versioning and properties
myApp := App("0VERL0DE", "POIRO")   ; refers to https://github.com/0VERL0DE/Poiro

    myApp.SetInstallPath(A_Appdata "\POIRO")

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



