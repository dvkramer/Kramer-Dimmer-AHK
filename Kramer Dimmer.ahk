#Requires AutoHotkey v2.0
#SingleInstance Force

; --- Config ---
Global CurrentBrightness := 100
Global StepSize := 5
Global osdGui := "" ; Handle for the GUI

; Restore gamma on exit so your screen doesn't stay dark
OnExit(RestoreGamma)

; ==============================================================================
; HOTKEYS
; ==============================================================================

; Right Shift + [  -> Decrease
>+[::
{
    ChangeBrightness(-StepSize)
}

; Right Shift + ]  -> Increase
>+]::
{
    ChangeBrightness(StepSize)
}

; ==============================================================================
; LOGIC
; ==============================================================================

ChangeBrightness(amount) {
    Global CurrentBrightness
    CurrentBrightness := CurrentBrightness + amount
    
    if (CurrentBrightness > 100)
        CurrentBrightness := 100
    if (CurrentBrightness < 10) ; Minimum brightness
        CurrentBrightness := 10
    
    SetGamma(CurrentBrightness)
    ShowOSD(CurrentBrightness)
}

ShowOSD(pct) {
    Global osdGui
    
    ; Reset the destroy timer so it stays open if you keep pressing keys
    SetTimer DestroyOSD, 0
    
    ; Destroy previous GUI to redraw (matches your reference style)
    if (IsSet(osdGui) && Type(osdGui) = "Gui")
        osdGui.Destroy()

    ; Create GUI
    osdGui := Gui("-Caption +AlwaysOnTop +ToolWindow")
    osdGui.BackColor := "1A1A1A"
    osdGui.SetFont("s10 cWhite w600", "Segoe UI Variable")
    
    osdGui.MarginX := 20
    osdGui.MarginY := 15
    
    DisplayText := "Gamma: " . pct . "%"
    
    osdGui.Add("Text", "Center w200", DisplayText)
    ; Progress Bar: w200 width, h6 height, color 3B82F6 (Blue), Background Dark Gray
    osdGui.Add("Progress", "w200 h6 c3B82F6 Background333333", pct)

    ; Calculate Position (Bottom Center)
    MonitorGetWorkArea(1, &L, &T, &R, &B)
    GuiWidth := 240 
    GuiHeight := 65 
    
    PosX := (R - L - GuiWidth) / 2
    PosY := B - GuiHeight - 220 
    
    ; Show without stealing focus
    osdGui.Show("x" . PosX . " y" . PosY . " NoActivate")
    
    ; Auto-hide after 3 seconds
    SetTimer DestroyOSD, -3000
}

DestroyOSD() {
    Global osdGui
    if (IsSet(osdGui) && Type(osdGui) = "Gui")
        osdGui.Destroy()
}

SetGamma(pct) {
    ; Gamma Ramp = 3 arrays of 256 16-bit integers (Red, Green, Blue)
    ; Total size = 256 * 2 bytes * 3 channels = 1536 bytes
    Ramp := Buffer(1536, 0)
    
    ; Calculate multiplier (0.0 to 1.0)
    gammaVal := pct / 100.0
    
    Loop 256 {
        ; Calculate value for this index (0-65535)
        val := Integer((A_Index - 1) * 256 * gammaVal)
        if (val > 65535)
            val := 65535
        
        ; Write to buffer at specific offsets
        ; Offset 0    = Red
        ; Offset 512  = Green (256 * 2)
        ; Offset 1024 = Blue  (512 * 2)
        
        NumPut("UShort", val, Ramp, (A_Index - 1) * 2)
        NumPut("UShort", val, Ramp, 512 + (A_Index - 1) * 2)
        NumPut("UShort", val, Ramp, 1024 + (A_Index - 1) * 2)
    }
    
    ; Apply to the entire screen context (Hardware Level)
    hDC := DllCall("GetDC", "Ptr", 0, "Ptr")
    DllCall("gdi32.dll\SetDeviceGammaRamp", "Ptr", hDC, "Ptr", Ramp)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)
}

RestoreGamma(*) {
    SetGamma(100)
}