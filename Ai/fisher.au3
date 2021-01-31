#include <Misc.au3>
Opt("PixelCoordMode", 2)
Opt("MouseCoordMode", 2)
local $hwnd = WinGetHandle("World of Warcraft")
WinActivate($hwnd)
WinWaitActive($hwnd)
local $clientSize = WinGetClientSize ($hwnd)
Local $start_time = TimerInit()
local $wait_time = 30000
local $feather_color = 0x000000
local $Paused = False
$dll = DllOpen("user32.dll")

;~  ---------------------------------------


;~ $bobber_tolerance = 15
;~ $splash_tolerance = 45

$bobber_tolerance = 5
$splash_tolerance = 15

;~  ----------------------------------------

HotKeySet("{F11}", "Pause")
HotKeySet("{F10}", "Kill")

While(True)
    pole()  
WEnd
;~ ---

Func Pause()
	$Paused = NOT $Paused
	While $Paused
		Sleep(100)
	WEnd
EndFunc

;~  ---

Func Kill()
   Exit
EndFunc

;~ ---

Func setup()
    While -1
        $mouse = MouseGetPos()
        $color = PixelGetColor($mouse[0],$mouse[1])
        ToolTip("Find the feather", 0, 0)
        GUISetBkColor("0x" & Hex($color,6), $feather_color) ; 
        If _IsPressed("01", $dll) Then ExitLoop
    WEnd
    ;~ ConsoleWrite("0x" & Hex($color,6) & @LF)
EndFunc    

;~  ---

Func pole()
    send('1')
    ;~ setup()
    find()
EndFunc 

;~  ---

Func find()
    Local $start_time = TimerInit()
    local $bobber_colors[7] = [0x463B4D, 0x283A64, 0xA72C0B, 0x2B3254, 0x6B1F0C, 0xBB9B3D, 0x0B1931]
    ;~ local $bobber_colors[4] = [0x463B4D,  0xA72C0B,  0x6B1F0C, 0xBB9B3D]
    ;~   dark_purple,  dark blue  ,red stormwind daylight,  blue  stormwind daylight,  red  (preffered ?) , color_beige  , color_night_blue
    local $x0 = 300
    local $y0 = 300
    local $x1 = $clientSize[0] - 300
    local $y1 = $clientSize[1] - 300
    local $color_index = 0
    While TimerDiff($start_time) < $wait_time
        local $pos = PixelSearch($x0, $y0, $x1, $y1, $bobber_colors[$color_index], $bobber_tolerance , 2)    
        If not @error Then
            ToolTip('found' & $color_index, 100, 100)
            MouseMove($pos[0], $pos[1])
            return splash($pos[0] , $pos[1])
             
        Else
            if Ubound($bobber_colors) == ($color_index + 1) Then
                $color_index = 0
            Else
                $color_index = $color_index + 1 
            EndIf
            ToolTip('new color index' & $color_index, 100,100)
        EndIf
        Sleep(1000)
    WEnd
EndFunc 

;~  ---

Func splash($mouseX, $mouseY)
    Local $start_time = TimerInit()
    $x0 = $mouseX - 100
    $y0 = $mouseY - 100
    $x1  = $mouseX + 100
    $y1 = $mouseY + 100
    $splash_color = 0xF6F6F6

    $splash_search_step = 2
    while TimerDiff($start_time) < $wait_time
        $pos = PixelSearch($x0, $y0, $x1, $y1, $splash_color, $splash_tolerance, $splash_search_step)
        if not @error then
        ;~     SetError(0)
        ;~ else
            Sleep(Random(100, 1000))
            Send("{SHIFTDOWN}")
            Sleep(100)
            MouseClick("right", $pos[0], $pos[1], 1, 2)
            Sleep(100)
            Send("{SHIFTUP}")
            Sleep(5000)
            ExitLoop
        endif
        Sleep(10)
    wend
    pole()
endfunc 