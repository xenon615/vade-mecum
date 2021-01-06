#include <Color.au3>
#include <AutoItConstants.au3>
Opt("PixelCoordMode", 2)
Opt("MouseCoordMode", 2)

$paused = false
$hwnd = 0
$PI = 3.1415926
HotKeySet("{F11}", "Pause")
HotKeySet("{F10}", "Kill")

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

;~  ---

local $hwnd = WinGetHandle("World of Warcraft")
WinActivate($hwnd)
WinWaitActive($hwnd)
local $clientSize = WinGetClientSize ($hwnd)
$centerX = Floor($clientSize[0] / 2)
$centerY = Floor($clientSize[1] / 2) 
MouseMove($centerX, $centerY)
local $angle = 270 * $PI / 180



;~ Turn($angle)
;~ Move(31.55, 63.34)

;~ Move(32.74, 57.1)
Move(42.42, 53.81)

Func getData()
    local $color = PixelGetColor(0, 0, $hwnd)
    if @error Then
        Exit 1
    EndIf
    local $rgb = _ColorGetRGB($color)
    local $data[3] = [0,0,0]
    $data[0] = ($rgb[0] / 255) * 100
    $data[1] = ($rgb[1] / 255) * 100
    $data[2] = ($rgb[2] / 255) * 10
    ;~ ConsoleWrite('x = ' & $data[0] & ' y = ' & $data[1] & ' azimuth = ' &  $data[2] & @CRLF)
    return $data
EndFunc

;~  ---

Func Turn($angle)
    local $treshold = 0.5
    MouseDown($MOUSE_CLICK_RIGHT)
    While(True) 
        local $data = getData()
        local $mouseX = MouseGetPos(0)
        local $mouseY = MouseGetPos(1)
        if (($mouseX > ($centerX + 200 )) or ($mouseX <  ($centerX - 200))) Then
            MouseMove($centerX, $centerY)
        EndIf
        $sin = sin($data[2] - $angle)
        MouseMove($mouseX + 10 * $sin, $mouseY, 0)
        
        if (abs($data[2] - $angle) < $treshold) Then
            ExitLoop
        EndIf
    WEnd
    MouseUp($MOUSE_CLICK_RIGHT)
EndFunc

;~  ---
Func atan2($y, $x)
    Return (2 * ATan($y / ($x + Sqrt($x * $x + $y * $y))))
EndFunc                   

;~  ---

Func Move($x, $y)
    local $data = getData()
    ;~ local $angle = atan(($x - $data[0]) / ($y - $data[1]))
    local $angle = atan2(($x - $data[0]),  ($y - $data[1]))
    ;~ If ($angle < 0) Then
    ;~     $angle = 2 * $PI + $angle
    ;~ EndIf
    $angle = $angle + $PI    
    local $angleDeg = $angle * 180 / $PI
    ToolTip('Turn to ' & $angleDeg, 300, 300)
    ConsoleWrite('Turn to ' & $angleDeg & @LF)
    Turn($angle)
    Walk($x, $y)
EndFunc 


;~  ---


Func Walk($x, $y)
    local $treshold = 0.5
    local $data = getData()
    local $rangeX = abs($data[0] - $x)
    local $rangeY = abs($data[1] - $y)
    local $range0 = Sqrt($rangeX * $rangeX + $rangeY * $rangeY)
    Send('{w down}')
    While(True)
        $data = getData()
        $rangeX = abs($data[0] - $x)
        $rangeY = abs($data[1] - $y)
    
        local $range = Sqrt($rangeX * $rangeX + $rangeY * $rangeY)
        If ( $range < $treshold) Then
            ExitLoop
        EndIf

        if ($range < ($range0 / 2)) Then
            ToolTip('correction ' & ' range is ' & $range, 300, 300)
            Send('{w up}')
            return Move($x, $y)
        endif

    WEnd
    Send('{w up}')
EndFunc

