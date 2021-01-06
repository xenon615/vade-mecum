#include <Color.au3>
#include <AutoItConstants.au3>
#include <Misc.au3>
Opt("PixelCoordMode", 2)
Opt("MouseCoordMode", 2)

$dll = DllOpen("user32.dll")

$paused = false
$hwnd = 0
$PI = 3.1415926
$x = 0 
$y = 0
$faceTo = 0

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

$hwnd = WinGetHandle("World of Warcraft")
WinActivate($hwnd)
WinWaitActive($hwnd)
$clientSize = WinGetClientSize ($hwnd)
$centerX = Floor($clientSize[0] / 2)
$centerY = Floor($clientSize[1] / 2) 
MouseMove($centerX, $centerY)

local $way[4][2] = [[34.31, 86.79], [39.41, 79.88], [46.16, 80.64], [46.38, 82.4]]

$errorA = 0.1
$errorD = 1

local $wayIndex = 0
While(True)
    Move()
    if (Ubound($way) - 1) == $wayIndex Then
        $wayIndex = 0
    Else 
        $wayIndex = $wayIndex + 1
    EndIf
WEnd


Func Move()
    if (_IsPressed("57", $dll)) Then
        Send('{w up}')
    EndIf
    if (_IsPressed("02", $dll)) Then
        MouseUp($MOUSE_CLICK_RIGHT)
    EndIf

    Send('{w down}')
    While(True)
        getData()
        ;~ ToolTip('x=' & $x & ' y=' & $y, 300, 300)
        ;~ ConsoleWrite('x=' & $x & ' y=' & $y & @LF)
        
        local $toPoint = direction()
        ;~ ConsoleWrite('faceTo=' & $faceTo & ' toPoint=' & $toPoint & @LF)
        if (abs($faceTo - $toPoint) > $errorA) Then
            MouseDown($MOUSE_CLICK_RIGHT)
            Turn($toPoint)
        Else
            MouseUp($MOUSE_CLICK_RIGHT)
        EndIf

        local $rangeX = abs($way[$wayIndex][0] - $x)
        local $rangeY = abs($way[$wayIndex][1] - $y)
        local $range = Sqrt($rangeX * $rangeX + $rangeY * $rangeY)
        ToolTip('range=' & $range, 300, 300)
        If ( $range < $errorD) Then
            Send('{w up}')
            ExitLoop
        EndIf

    WEnd
EndFunc
;~  ---

Func atan2($y, $x)
    Return (2 * ATan($y / ($x + Sqrt($x * $x + $y * $y))))
EndFunc                   

;~  ---


Func direction()
    return atan2($way[$wayIndex][0] - $x,  $way[$wayIndex][1] - $y) + $PI
EndFunc

;~  ---

Func getData()
    $color = PixelGetColor(0, 0, $hwnd)
    if @error Then
        Exit 1
    EndIf
    $rgb = _ColorGetRGB($color)
    $x = ($rgb[0] / 255) * 100
    $y = ($rgb[1] / 255) * 100
    $faceTo = ($rgb[2] / 255) * 10
EndFunc

;~  ---

Func Turn($angle)
    local $mouseX = MouseGetPos(0)
    local $mouseY = MouseGetPos(1)
    if (($mouseX > ($centerX + 200 )) or ($mouseX <  ($centerX - 200))) Then
        MouseMove($centerX, $centerY)
    EndIf
    $sin = sin($faceTo - $angle)
    MouseMove($mouseX + 10 * $sin, $mouseY, 0)
EndFunc

;~  ---

