#Requires AutoHotkey v2 
#SingleInstance Force

#include <App>

; create a new App object for storing versioning and properties
myApp := App("0VERL0DE", "POIRO")   ; refers to https://github.com/0VERL0DE/Poiro

    myApp.SetInstallPath(A_Appdata "\POIRO")

    ; Pull data from Github and update this app object
    myApp.GetGitInfo()

    ; Check local version (JSON) against remote (latest RELEASE on Github)
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






    ;DetectHiddenWindows(false)
    ;DetectHiddenText(false)
    
    ; If FileExist(tempdir "/config.ini"){
    
    ; }Else{
    
    ; }
    
        Display_ResetWorkArea()
        Display_GetInfo()    
        Display_StartClock(1)
    
    Return
    
    ;#####################################################################################
    ; HOTKEYS
    ;#####################################################################################
    
    
    
    ;#####################################################################################
    ; PRIMARY FUNCTIONS
    ;#####################################################################################
    
    ; START CLOCK CREATION
    ;===================================================
    ; shows or hides the start clock
    Display_StartClock(State := ""){
    
        ; Initialize variables
        global iMonitorCount := MonitorGetCount()
    
        iClockWidth := 55
        iClockHeight := 40
        sStartSize := "11 Bold"
    
        sCPUTime := A_Hour ":" A_Min "`n" A_DD "/" A_MM
    
        ; clock button seems to function regardless of default start button status
        Display_StartButton(0)
    
        ; Create context menu, duplicated on every screen
        oClockMenu := Menu()
        oClockMenu.Add("Task Manager", MenuChoice)
        oClockMenu.Add("Settings", MenuChoice)
        oClockMenu.Add("Reload", MenuChoice)
        oClockMenu.Add("Exit", MenuChoice)
    
    
        oClockMenu.SetIcon("Settings", "imageres.dll" , 64)
        oClockMenu.SetIcon("Reload","Shell32.dll",239)
        oClockMenu.SetIcon("Exit","Shell32.dll",132)
    
        ; create mapping of clock GUIs 
        ; 
        mClocks := Map()        ; mClocks[hwnd] = gui object or gui ctrl object
        mControls := Map()
        mTaskbars := Map()      ; mTaskbars[index] = hwnd
    
    
        ; Create clocks for every monitor
        Loop iMonitorCount {
    
            ; pre-build clock GUI
            oClockGui := Gui()
            oClockGui.Opt("+ToolWindow -Caption")
            oClockGui.Opt("+AlwaysOnTop +LastFound")
            oClockGui.MarginX := 0
            oClockGui.MarginY := 0
            oClockGui.Name := "CLock" A_Index "Gui"
    
            ; Get ID of the taskbar on current monitor
            If (A_Index = 1){
                mTaskbars[A_Index] := WinGetID("ahk_class Shell_TrayWnd")
            }
            Else{
                mTaskbars[A_Index] := WinGetID("ahk_class Shell_SecondaryTrayWnd")
            }
    
            ; Attach GUI to the taskbar on this monitor
            DllCall("SetParent", "uint", oClockGui.Hwnd, "uint", mTaskbars[A_Index])
    
            ; set options
            oClockGui.SetFont("S" . sStartSize, "Arial Narrow")
            oProgressBar := oClockGui.Add("Progress", "x0 y0 w" . iClockWidth . " h" . iClockHeight . " Disabled BackgroundGreen")                              ; ProgressBar ClassNN: msctls_progress321
            cTextControl := oClockGui.Add("Text", "" . A_Index . " Center x0 y0 w" . iClockWidth . " h" . iClockHeight . "  cWhite BackgroundTrans ", sCPUTime)    ; Textfield ClassNN: Static1
            cTextControl.Name := "CLock" A_Index "Text"
            
            ; Click event only applies to control, not GUI
            cTextControl.OnEvent("Click", ClockLeftClick)
            cTextControl.OnEvent("ContextMenu", ClockRightClick)
    
    
            oClockGui.Show("x0 y0 AutoSize")
    
            mControls[cTextControl.Hwnd] := cTextControl
            mClocks[oClockGui.Hwnd] := oClockGui
            
    
        } ; end of loop(iMonitorCount)
    
        For sClockHandle, oClockGui in mClocks {
            {
            Outputdebug "Clock " sClockHandle "," oClockGui.Name
            }
        }
        For sControlHandle, oTextControl in mControls {
            {
            Outputdebug "Control " sControlHandle "," oTextControl.Name
            }
        }
    
        ; Start a timer that updates the clock every second
        SetTimer UpdateButtonTime, 1000
    
    
        ; Enable hover listener
        HoverListenerState(1)
    
        ; Events
        OnExit ExitFunc
    
        return
    
        ; START CLOCK FUNCTIONS
        ;===================================================
        
        ; CLOCK TIME UPDATE
        UpdateButtonTime()
        {
            ;Only do stuff when the clock time is behind real time
            If ! InStr(sCPUTime, A_Hour ":" A_Min) {
    
                sCPUTime := A_Hour ":" A_Min "`n" A_DD "/" A_MM
    
                For sControlHandle, oTextControl in mControls {
                    {
                    oTextControl.Text := sCPUTime
                    }
                }
    
                ; Sleep for 55 seconds, then continue checking every 1 s for about 5 s to compensate for script delay
                Sleep 55000 
            }
        }
    
    
        ; LEFT CLICK EVENT
        ClockLeftClick(CtrlHwnd*){
            Send("^{ESCAPE}") ; activate windows search bar
        return
        }
    
        ; RIGHT CLICK EVENT
        ClockRightClick(CtrlHwnd*){ ; alternative to Clock_GuiContextMenu
            ToolTip()
            oClockMenu.Show()    ; Show context menu
            return
        }
    
        ; CONTEXT MENU SELECTION
        MenuChoice(ItemName, ItemPos, MenuName){
            switch (itemName) {
                case "Reload":
                    Reload()
                case "Exit":
                    ExitApp(0)
                case "Settings":
                    OutputDebug("`"show settings`"")
                return
            }
        }
    
        ; SET HOVER MONITOR STATE
        HoverListenerState(RequestedState:=""){
           Static CurrentState
    
            If (RequestedState =""){
                return CurrentState
            } Else If (RequestedState = 1) {
                CurrentState := 1
                OnMessage(WM_MOUSEMOVE   := 0x0200, CursorOverGui, 1) ; Client area
                ;OnMessage(WM_NCMOUSEMOVE := 0x00A0, CursorOverGui, 1) ; Non-client area
    
            } Else If(RequestedState = 0) {
                CurrentState := 0
                OnMessage(WM_MOUSEMOVE   := 0x0200, CursorOverGui, 0) ; Client area
                ;OnMessage(WM_NCMOUSEMOVE := 0x00A0, CursorOverGui, 0) ; Non-client area
            }
        }
    
        ; TRIGGER FOR CURSOR OVER BUTTON
        CursorOverGui(*) {
    
            ; Stop listening for mousemove on gui - mouse already in gui
            HoverListenerState(0)
    
            ToolTip DateTimeInfo(), , ,1
    
            ; start monitoring when cursor leaves again
            SetTimer(CheckIfHovering,500)
            return
    
            ; subroutine that checks every 500 ms if cursor is over clock
            CheckIfHovering()
            { 
                MouseGetPos(, , &ActiveWindow)
                ; cursor is over one of the registered guis
                If mClocks.Has(ActiveWindow){
                    ToolTip DateTimeInfo(), , , 1
                ; cursor left GUI
                }Else{
                    ToolTip , , ,1
                    SetTimer(CheckIfHovering,0)             ; Disable the subroutine, cursor has left
                    HoverListenerState(1)                   ; Reactivate the GUI hover trigger
                }
            }
    
            ; subroutine that shows the date on hover
            DateTimeInfo(){   
    
                ; Returns current date/time info
                Now := A_Now
                wday := FormatTime("Now", "dddd")
                day := FormatTime("Now", "yDay")
                week := FormatTime("Now", "yWeek")
                week := SubStr(week, (4)+1)
    
                ; Format tooltip
                DT := FormatTime("Now", "yyyy MMMM d, HH:mm:ss tt")
                Return DT "`n" wday ". Day: " day ", Week: " week
            }
    
    
        } ;end of hover functions
    
        ; restore screen work area and unhide any windows
        ExitFunc(ExitReason, ExitCode)
        {
            if ExitReason != "Logoff" and ExitReason != "Shutdown"
            {
                Result := MsgBox("Are you sure you want to exit?",, 4)
                if Result = "No"
                    return 1  ; Callbacks must return non-zero to avoid exit.
            }
            Display_StartButton(1)
            ; Do not call ExitApp -- that would prevent other callbacks from being called.
        }
    
    }
    
    
    ;#####################################################################################
    ; SECONDARY FUNCTIONS
    ;#####################################################################################
    
    
    ; shows, hides or returns the State of the default win start button
    Display_StartButton(State := ""){
    
        ; if no input, return visibility of the default win Start button
        If (State == "") {
            WinButtonText := WinGetText("ahk_class Shell_TrayWnd")
            If (RegExMatch(WinButtonText, "^\p{Z}*Start")) {
                return 1
            } Else {
                return 0 
            }   
        ; State 1 = show the default win startbutton
        }Else If (State = 1) {
    
            ControlShow("Start","ahk_class Shell_TrayWnd")
            Try {
            ControlShow("Start","ahk_class Shell_SecondaryTrayWnd")
            }
            
        ; State 0 = hide the default win startbutton
        }Else If (State = 0) {
    
            ControlHide("Start","ahk_class Shell_TrayWnd")
            Try {
            ControlHide("Start","ahk_class Shell_SecondaryTrayWnd")
            }
        }
    }
    
    
    ; prints info about the current monitors and work area to debug
    Display_GetInfo(){
    
    
        ; BEFORE moving window
        ;originalContext := DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
    
    
        ; AFTER moving window
        ;DllCall("SetThreadDpiAwarenessContext", "ptr", originalContext, "ptr")
    
    
    
    
        iMonitorCount := MonitorGetCount()
        MonitorPrimary := MonitorGetPrimary()
    
        MonitorTable := "   0,0 "
    
        Loop iMonitorCount
        {
            MonitorGet A_Index, &L, &T, &R, &B
            MonitorGetWorkArea A_Index, &WL, &WT, &WR, &WB
    
            L := Format("{:04d}", L)
            T := Format("{:04d}", T)
            R := Format("{:04d}", R)
            B := Format("{:04d}", B)
            WL := Format("{:04d}", WL)
            WT := Format("{:04d}", WT)
            WR := Format("{:04d}", WR)
            WB := Format("{:04d}", WB)
    
            MonitorNum := ( A_Index = MonitorGetPrimary() ) ? "M" A_Index : "+" A_Index
    
            MonitorTable .= 
            (
            "
                ╔═════╦══════ "          T             " ══════╦═════╗
                ║═════╬══════ "          WT            " ══════╬═════║
                ║     ║         "                    "         ║     ║
                " L "  " WL "     "   MonitorNum    "      " WR "  " R "
                ║     ║         "                    "         ║     ║
                ║═════╬══════ "          WB            " ══════╬═════║
                ╚═════╩══════ "          B             " ══════╩═════╝"
            )
        }
    
        MonitorTable .= "`n                                 " SysGet(78) "," SysGet(79) " "
    
        Outputdebug MonitorTable
    
    return
    }
    
    ; reset the work area to the default, with a taskbar of 40px
    Display_ResetWorkArea(){
        Static SPI_SETWORKAREA := 0x2F
            ; create windows RECT object
            Rect := Buffer(16)  ; A RECT is a struct consisting of four 32-bit integers (i.e. 4*4=16).
            NumPut( "Int", 0                   ; left
                    , "Int", 0                  ; top
                    , "Int", A_ScreenWidth         ; right
                    , "Int", A_ScreenHeight - 40      ; bottom
                    , Rect) 
        
            DllCall("SystemParametersInfo", "UInt", SPI_SETWORKAREA, "UInt", 0, "Ptr", RECT, "UInt", 0)
    }
    
    ;#####################################################################################
    ; Work in progress...
    ;#####################################################################################
    
    
    Display_TaskBar(top:=0,bottom:=0,left:=0,right:=0){
        Static SPI_SETWORKAREA := 0x2F
        
            DetectHiddenWindows(true)
        
            ; Get Tray handle and tray height
            TaskBarHandle := 723244 ;WinExist("ahk_class Shell_TrayWnd")
            Outputdebug TaskBarHandle
            BottomBarHeight := 40
            ;WinGetPos(, , , &BottomBarHeight)
    
            ;hWin7Taskbar := WinExist("ahk_class Button ahk_exe Explorer.EXE")  ; for Windows 7
         
            ; Check if taskbar is visible
            TaskbarIsVisible := DllCall("IsWindowVisible", "Ptr", TaskBarHandle)
            bottom := (bottom < BottomBarHeight) ? BottomBarHeight : bottom
    
    
            Outputdebug "Bottom Bar: (" TaskbarIsVisible "): " BottomBarHeight 
            
    
        ; create windows RECT object
        Rect := Buffer(16)  ; A RECT is a struct consisting of four 32-bit integers (i.e. 4*4=16).
        NumPut( "Int", left                   ; left
                , "Int", top                  ; top
                , "Int", A_ScreenWidth - left - right   ; right
                , "Int", A_ScreenHeight - top - bottom  ; bottom
                , Rect)
    
        DllCall("SystemParametersInfo", "UInt", SPI_SETWORKAREA, "UInt", 0, "Ptr", RECT, "UInt", 0)
     
        
        ; loop over all open windows and refresh to fit to screen
        oList := WinGetList(,,,)
        aList := Array()
        List := oList.Length
        For v in oList
        {   aList.Push(v)
        }
        Loop aList.Length {
            res := WinGetMinMax("ahk_id" . aList[A_Index])
            if (res = 1)
                {
                WinMove(left, top, A_ScreenWidth - left - right, A_ScreenHeight - top - bottom, "ahk_id" . aList[A_Index])
            ;    WinMove(0, 0, A_ScreenWidth, A_ScreenHeight - !TaskbarIsVisible * ActiveWindowHeight, "ahk_id" . aList[A_Index])
                }
            } 
    
    
    
        }
    
    
    ; functional ; doesn't work on second tray yet
    ToggleTaskbar() {
       static SW_HIDE := 0, SW_SHOWNA := 8, SPI_SETWORKAREA := 0x2F
       DetectHiddenWindows(true)
    
       ; Get Tray handle and window height
       TaskBarHandle := WinExist("ahk_class Shell_TrayWnd")
       Outputdebug "tray handle: " TaskBarHandle
       WinGetPos(, , , &ActiveWindowHeight)
       ;hWin7Taskbar := WinExist("ahk_class Button ahk_exe Explorer.EXE")  ; for Windows 7
    
       ; Toggle taskbar visibility
       TaskbarIsVisible := DllCall("IsWindowVisible", "Ptr", TaskBarHandle)
    
       ; loops over taskbarhandle and optional win 7 handles and hides
    /*    for k, v in TaskBarHandle { ;  , hWin7Taskbar]{
          ( v && DllCall("ShowWindow", "Ptr", v, "Int", TaskbarIsVisible ? SW_HIDE : SW_SHOWNA) )
       } 
    */
       DllCall("ShowWindow", "Ptr", TaskbarHandle, "Int", TaskbarIsVisible ? SW_HIDE : SW_SHOWNA)
    
        ; create windows RECT object with size 16, leave empty
        RECT := Buffer(16, 0) ; V1toV2: if 'RECT' is a UTF-16 string, use 'VarSetStrCapacity(&RECT, 16)'
        ; Store screen width D in RECT buffer, behind the address A at offset 8: "AAAAAAAAWWWW"
        NumPut("UPtr", A_ScreenWidth, RECT, 8)
        ; Store height of taskbar in RECT buffer, behind address A and width W at offset 12: "AAAAAAAAWWWWHHHH"
        NumPut("UInt", A_ScreenHeight - !TaskbarIsVisible*ActiveWindowHeight, RECT, 12)
    
       ; Set workarea to 
       DllCall("SystemParametersInfo", "UInt", SPI_SETWORKAREA, "UInt", 0, "Ptr", RECT, "UInt", 0)
       
       ; loop over all open windows and refresh to fit to screen
       oList := WinGetList(,,,)
       aList := Array()
       List := oList.Length
       For v in oList
       {   aList.Push(v)
       }
       Loop aList.Length {
          res := WinGetMinMax("ahk_id" . aList[A_Index])
          if (res = 1)
            WinMove(0, 0, A_ScreenWidth, A_ScreenHeight - !TaskbarIsVisible*ActiveWindowHeight, "ahk_id" . aList[A_Index])
       } 
    
       OutputDebug("WorkArea set to " A_ScreenWidth "x" A_ScreenHeight - !TaskbarIsVisible * ActiveWindowHeight ", refreshed " " windows")
    }
    
    
    
    
    
    WinSetOwner(Hwnd, hOwner:=Unset)                           ;  By SKAN for ah2 on D48U/D48U @ autohotkey.com/r?t=94330
    {
        Local GWL_HWNDPARENT := -8,   GW_CHILD := 5,    SW_RESTORE := 9
    
        If ( ! WinExist(Hwnd) )
            Return
    
        Local Class := WinGetClass( Integer(Hwnd) )
        If ( Class="WorkerW" || Class="Progman" )
             Return
    
        If ( IsSet(hOwner) = False )
            Return( A_PtrSize=8 ? DllCall("User32.dll\GetWindowLongPtr", "ptr",Hwnd, "int",GWL_HWNDPARENT, "ptr")
                                : DllCall("User32.dll\GetWindowLong",    "ptr",Hwnd, "int",GWL_HWNDPARENT, "ptr") )
    
        If ! ( DllCall("User32.dll\IsTopLevelWindow", "ptr",Hwnd) || WinSetOwner(Hwnd) )
            Return
    
        If ( hOwner != "SHELLDLL_DefView" )
             hOwner := Format("{:d}", hOwner)
        Else hOwner := DllCall("User32.dll\GetWindow"
                                , "ptr",Max( WinExist("ahk_class WorkerW", "FolderView")
                                           , WinExist("ahk_class Progman", "FolderView") )
                                , "int",GW_CHILD, "ptr")
    
        If DllCall("User32.dll\IsIconic", "ptr",Hwnd)
           DllCall("User32.dll\ShowWindow", "ptr",Hwnd, "int",SW_RESTORE)
    
        hOwner := WinExist( Integer( Format("{:d}", hOwner) ) )
    
        If ( A_PtrSize = 8 )
             DllCall("User32.dll\SetWindowLongPtr", "ptr",Hwnd, "int",GWL_HWNDPARENT, "int",hOwner ? hOwner : Gui().Hwnd)
        Else DllCall("User32.dll\SetWindowLong",    "ptr",Hwnd, "int",GWL_HWNDPARENT, "int",hOwner ? hOwner : Gui().Hwnd)
    
        Return( WinSetOwner(Hwnd) = hOwner )
    }
   
   




;   #Include <INI>


