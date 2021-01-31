#include <Color.au3>
#include <AutoItConstants.au3>
#include <Misc.au3>

#include <WinAPIRes.au3>
#include <GDIPlus.au3>

_GDIPlus_Startup() 
Opt("PixelCoordMode", 2)
Opt("MouseCoordMode", 2)
$dll = DllOpen("user32.dll")
Const $PI  = 3.1415
Local $hwnd = 0, $x = 0 , $y = 0, $faceTo = 0, $pitch = 0, $isFlying = False, $isMounted = false,$isFalling = false,  $inCombat = False, $hasTarget = False, $turn = False, $turnAngle = 0, $target[2]
Local $state, $enter_state_time = 0, $prevState = '', $detected = False;
HotKeySet("{F10}", "Kill")
HotKeySet("{F11}", "Pause")


$hwnd = WinGetHandle("World of Warcraft")
WinActivate($hwnd)
WinWaitActive($hwnd)
$clientSize = WinGetClientSize ($hwnd)
$centerX = Floor($clientSize[0] / 2)
$centerY = Floor($clientSize[1] / 2) 
MouseMove($centerX, $centerY)
$errorA = 0.01
$errorD = 0.001


;~ local $miniMapCenter[2] = [1811, 113]


$fullColor = 0xE7B003
local $cursorColor[2] = ['FF241A10', 'FF6C5235']
local $heightRatio = $clientSize[1] / 768
$sizeQ = 0.9 * $heightRatio

local $miniMapCenter[2] = [1287 * $heightRatio, (768 - 689) * $heightRatio]
;~ MouseMove($miniMapCenter[0], $miniMapCenter[1])
;~ Sleep(5000)
;~ Exit
local $indicators[5]
$indSize = 10 * $sizeQ
For $i = 0 To 4
    $indicators[$i] = $indSize * ($i + 0.5)
    ;~ MouseMove($indicators[$i], 5)
    ;~ Sleep(2000)
Next






getData()
Go()

Func Go()
    ;~ enterState('Running')
    ;~ enterState('Idle')
    if (not $isFlying) Then
        enterState('Work')
    Else
        enterState('Running')
    EndIf

    While(True)
        getData()
        Call($state)
    WEnd
EndFunc 

;~  ---

Func Kill()
    stay()
    Exit
EndFunc

;~  ---

Func Pause()
    local $pos = MouseGetPos()
    debug($pos[0] & '   ' & $pos[1])
    ;~ $color = Hex(PixelGetColor($pos[0], $pos[1], $hwnd))
    ;~ debug($pos[0] & '   ' & $pos[1] & '    ' & $color)
    ;~ if not ($state == 'Idle') Then
    ;~     $prevState = $state
    ;~     enterState('Idle')
    ;~ Else
    ;~     enterState($prevState)
    ;~ EndIf
EndFunc 

;~  ---

Func debug($s)
    ToolTip($s, 300, 300)
    ;~ ConsoleWrite($s & @LF)
EndFunc 

;~  ---

Func setTarget()
    Send('3')
    Sleep(2000)

    $color4 = PixelGetColor($indicators[3], 5, $hwnd)
    $color5 = PixelGetColor($indicators[4], 5, $hwnd)

    $rgb = _ColorGetRGB($color4)
    $target[0] = ($rgb[0] + $rgb[1] / 255) / 255

    $rgb = _ColorGetRGB($color5)
    $target[1] = ($rgb[0] + $rgb[1] / 255) / 255
    $detected = False

EndFunc 

;~  ---

Func enterState($s)
    debug('Enter ' & $s)
    getData()
    $enter_state_time = TimerInit()
    Switch $s
        Case 'Running'
            if ($isFlying) Then
                setTarget()
            EndIf
        Case 'Landing'
            Send('{x down}')
        Case 'Work'
            Send('!]')
            Sleep(1000)
        Case 'Combat'
            ;~ Send('+1')   
            Send('{TAB}')
            ;~ Send('+4')
        ;~ Case 'Idle'
        ;~     MouseMove(25 * 1.16, 5)
        Case 'Falling'
            Beep(880, 500)
            Beep(880, 500)
            $prevState = $state
            Send('4')
    EndSwitch
    $state = $s
EndFunc

Func exitState()
    debug('Exit ' & $state)
    stay()
    getData()
    Switch $state
        Case 'Running'
            If $detected Then
                return enterState('Landing')
            Else
                return enterState('Running')
            EndIf
           
        Case 'Walking'
            If($inCombat) Then
                return enterState('Combat')
            else 
                return enterState('Work')
            EndIf
            
        Case 'Landing'
            Send('1')
            Sleep(1000)
            return enterState('Walking')
        Case 'Work'
            If($inCombat) Then
                return enterState('Combat')
            EndIf
            Send('1')
            Sleep(5000)
            ;~ Send('{w down}')
            Sleep(500)
            Send('{SPACE down}')
            Sleep(11000)
            Send('{SPACE up}')
            enterState('Running')
        Case 'Combat'
            ;~ Send('+3')
            enterState($prevState)
        Case 'Idle'
            enterState('Combat')
    EndSwitch 
EndFunc 

;~  ---

Func Idle()
    if ($inCombat) Then
        return exitState()
    EndIf
EndFunc

;~  ---

Func Falling()
    if not $isFalling Then
        return enterState($prevState)
    EndIf

EndFunc


;~  ---

Func Combat()
    Send('2')
    Sleep(2500)
    if ($turn) Then
        $turn = false
        Send('{a down}')
        Sleep(450)
        Send('{a up}')
        Sleep(500)
    EndIf
    if(not $inCombat) Then
        return exitState()
    EndIf    
EndFunc

;~  ---

Func Work()
    if ($inCombat) Then
        $prevState = 'Work'
        return  exitState()        
    EndIf

    if (TimerDiff($enter_state_time) > 2000) Then
        return exitState()
    EndIf
    for $j = $centerY - 350 To $centerY + 350 Step 100
        for $i = $centerX - 450 To $centerX + 450 Step  100
            MouseMove($i , $j, 2)

            $aCursor = _WinAPI_GetCursorInfo()
            
            $hImage = _GDIPlus_BitmapCreateFromHICON32($aCursor[2])
            $iX = _GDIPlus_ImageGetWidth($hImage)
            $iY = _GDIPlus_ImageGetHeight($hImage)
            $color = Hex(_GDIPlus_BitmapGetPixel($hImage, 20, 20), 8)

            If ($color == $cursorColor[0]) or ($color == $cursorColor[1]) Then
                if ( _IsPressed("02", $dll)) Then
                    MouseUp($MOUSE_CLICK_RIGHT)
                EndIf
                Sleep(2000)
                Sleep(Random(500, 1000))
                Send("{SHIFTDOWN}")
                Sleep(100)
                MouseClick("right")
                Sleep(100)
                Send("{SHIFTUP}")
                Sleep(5000)
                return  exitState()
            EndIf
        Next
    Next
EndFunc 

;~  ---

Func Landing()
    if (TimerDiff($enter_state_time) > 60000) Then
        return enterState('Running')
    EndIf
    if (not $isFlying) Then 
        return  exitState()
    EndIf
EndFunc 

;~  ---

Func Running()

    if (TimerDiff($enter_state_time) > 30000) Then
        return exitState()
    EndIf

    if not $isMounted Then
        If (_IsPressed("57", $dll)) Then
            Send('{w up}')
        EndIf
        Send('1')
        Sleep(2000)
    EndIf
    local $toPoint = direction()
    ;~ debug($toPoint)

    if (not $isFlying) Then
        Send('{SPACE down}')
        Sleep(4000)
        Send('{SPACE up}')
        return
    EndIf
    $elevation = 0    
    $devSin = sin($faceTo - $toPoint)
    $elSin = sin($pitch - $elevation)
    
    if (abs($elSin) > 0.01) Then
        if (not _IsPressed("02", $dll)) Then
            MouseDown($MOUSE_CLICK_RIGHT)
        EndIf
        Level($elSin)
        ;~ if (abs($elSin) > 0.1) Then
        ;~     return
        ;~ EndIf    
    EndIf
    
    

    if (abs($devSin) > $errorA * 10) Then
        if (not _IsPressed("02", $dll)) Then
            MouseDown($MOUSE_CLICK_RIGHT)
        EndIf
        Turn($devSin)
    Else
        if ( _IsPressed("02", $dll)) Then
            MouseUp($MOUSE_CLICK_RIGHT)
        EndIf
    EndIf
    
    If abs($devSin) > 0.2 Then
        If (_IsPressed("57", $dll)) Then
            Send('{w up}')
        EndIf
    Else
        If (not _IsPressed("57", $dll)) Then
            Send('{w down}')
        EndIf
    EndIf
    local $range = getRange()

    debug('pitch ' & Round($pitch, 4)  & ' Running to ' & Round($target[0], 4) & ' / ' & Round($target[1], 4) & ' devSin ' & Round($devSin, 4) & ' range '  & Round($range, 2))

    If ( $range < $errorD) Then
        return exitState()
    EndIf
    If ($range <  0.01) and not $detected Then
            local $pos = PixelSearch($miniMapCenter[0] - 15, $miniMapCenter[1] - 15, $miniMapCenter[0] + 15, $miniMapCenter[1] + 15, $fullColor , 20, 2, $hwnd)
            If @error Then
                $detected = False
            else
                Beep()
                $detected = True
            EndIf    
    EndIf
EndFunc 

;~  ---

Func Walking()
    if $isFalling Then
        enterState('Falling')
    EndIf

    if ($inCombat) Then
        $prevState = 'Walking'
        return  exitState()        
    EndIf
    if (TimerDiff($enter_state_time) > 20000) Then
        return exitState()
    EndIf

    local $toPoint = direction()
    $devSin = sin($faceTo - $toPoint)

    if (abs($devSin) > $errorA) Then
        if (not _IsPressed("02", $dll)) Then
            MouseDown($MOUSE_CLICK_RIGHT)
        EndIf
        Turn($devSin)
    Else
        if ( _IsPressed("02", $dll)) Then
            MouseUp($MOUSE_CLICK_RIGHT)
        EndIf
    EndIf
    
    If abs($devSin) > 0.1 Then
        If (_IsPressed("57", $dll)) Then
            Send('{w up}')
        EndIf
    Else
        If (not _IsPressed("57", $dll)) Then
            Send('{w down}')
        EndIf
    EndIf
    local $range = getRange()

    debug('pitch ' & Round($pitch, 4)  & ' Walking to ' & Round($target[0], 4) & ' / ' & Round($target[1], 4) & ' devSin ' & Round($devSin, 4) & ' range '  & Round($range, 4))

    If ( $range < ($errorD / 10)) Then
        return exitState()
    EndIf
EndFunc

;~  ---

Func getRange()
    local $rangeX = abs($target[0] - $x)
    local $rangeY = abs($target[1] - $y)
    return Sqrt($rangeX * $rangeX + $rangeY * $rangeY)
EndFunc

;~  ---

Func stay()
    ;~ Sleep(1000)
    if (_IsPressed("57", $dll)) Then
        Send('{w up}')
    EndIf
    if (_IsPressed("02", $dll)) Then
        MouseUp($MOUSE_CLICK_RIGHT)
    EndIf

    If (_IsPressed("58", $dll)) Then
        Send('{x up}')
    EndIf

    If (_IsPressed("20", $dll)) Then
        Send('{SPACE up}')
    EndIf
    MouseMove($centerX, $centerY)
    Sleep(500)
EndFunc

;~  ---

Func atan2($y, $x)
    Return (2 * ATan($y / ($x + Sqrt($x * $x + $y * $y))))
EndFunc                   

;~  ---

Func direction()
    return atan2($target[0] - $x,  $target[1] - $y) + $PI
EndFunc

;~  ---

Func getData()
    $color1 = PixelGetColor($indicators[0], 5, $hwnd)
    $color2 = PixelGetColor($indicators[1], 5, $hwnd)
    $color3 = PixelGetColor($indicators[2], 5, $hwnd)
    if @error Then
        Exit 1
    EndIf
    $rgb = _ColorGetRGB($color1)
    $x = ($rgb[0] + $rgb[1] / 255) / 255
    $faceTo = ($rgb[2] / 255) * 7

    $rgb = _ColorGetRGB($color2)
    $y = ($rgb[0] + $rgb[1] / 255) / 255
    $pitch = (($rgb[2] / 255) - 0.5) * 4
    
    $rgb = _ColorGetRGB($color3)
    ;~ $turn =  $rgb[0] == 0 ? False : True
    $turn = $rgb[0] >= 204 ? True : False
    $isFalling = ($rgb[0] == 51) or  ($rgb[0] == 255)  ? True : False
    $isMounted = $rgb[1] >= 204 ? True : False
    $isFlying = ($rgb[1] == 51) or  ($rgb[1] == 255)  ? True : False
    $inCombat = $rgb[2] >= 204 ? True : False
    $hasTarget = ($rgb[2] == 51) or  ($rgb[2] == 255)  ? True : False
    ;~ debug('mounted ' & $isMounted & '       flying ' & $isFlying & '          combat ' & $inCombat & '           target '  & $hasTarget & '          turn ' &  $turn)
EndFunc

;~  ---

Func Turn($sin)
    local $mouseX = MouseGetPos(0)
    local $mouseY = MouseGetPos(1)
    if (abs($mouseX -  $centerX ) > 200 ) Then
        MouseMove($centerX, $centerY)
    EndIf
    MouseMove($mouseX + 10 * $sin, $mouseY, 0)

EndFunc

;~  ---

Func Level($sin)
    local $mouseX = MouseGetPos(0)
    local $mouseY = MouseGetPos(1)
    if (abs($mouseY -  $centerY ) > 200 ) Then
        MouseMove($centerX, $centerY)
    EndIf
    MouseMove($mouseX, $mouseY + 10 * $sin, 0)
    ;~ Sleep(1000)
EndFunc