--[[
@title Focus Stack to Infinity (EOS M3)
@chdk_version 1.6
@param m Start Position (0=Current, 1=Near/MFD)
@default m 0
@range m 0 1
@param n Max Shots (Safety Cap)
@default n 15
@range n 2 50
@param s Initial Step Size (Motor Steps)
@default s 25
@range s 1 200
@param g Step Growth % per Shot
@default g 40
@range g 0 100
@param f Final True-Infinity Shot (0=No, 1=Yes)
@default f 1
@range f 0 1
@param d Initial Delay (sec)
@default d 2
@range d 0 10
--]]

-- ============================================================================
-- CANON EOS M3 (DIGIC 6) FOCUS STACK TO INFINITY
-- ============================================================================
-- Why standard CHDK focus scripts fail on the EOS M3:
-- 1. Standard CHDK set_focus() is NOT IMPLEMENTED on the EOS M3.
-- 2. Moving EF-M lenses requires Canon's internal EventProcs:
--      FA.Create -> InitializeAdjustmentSystem -> EFLensCom.MoveFocus
--    which ONLY work when "Enable Lua Native Calls" is ON in CHDK Misc Menu.
-- 3. The camera MUST be in Manual Focus (set_mf(1) / Canon MF mode) with
--    Continuous AF = OFF, otherwise half-pressing the shutter re-autofocuses!
-- ============================================================================

local bi = get_buildinfo()
set_console_layout(0, 0, 45, 5)
set_console_autoredraw(1)

-- 1. Verify Lua Native Calls are enabled
if type(call_event_proc) ~= "function" then
    play_sound(6)
    print("ERROR: Native Calls DISABLED!")
    print("Go to: CHDK Menu ->")
    print("Miscellaneous stuff ->")
    print("Enable Lua Native Calls [*]")
    sleep(6000)
    return
end

-- 2. Initialize Canon DIGIC 6 EF-M Lens EventProcs
call_event_proc("System.Create")
call_event_proc("FA.Create")
call_event_proc("InitializeAdjustmentSystem")
sleep(100)

-- Helper: Read EF-M stepper motor encoder position
local function get_lens_pos()
    local p = call_event_proc("GetEFLensFocusPositionWithLensCom")
    if type(p) ~= "number" then return -1 end
    return p
end

-- Helper: Read Canon reported lower focus distance in mm on EOS M3
local function get_m3_dist_mm()
    if type(peek) ~= "function" or bi.platform ~= "m3" then
        return -1
    end
    local cm = -1
    if bi.platsub == "101a" then
        cm = peek(0x00244918, 2)
    elseif bi.platsub == "120f" or bi.platsub == "121a" then
        cm = peek(0x0024495C, 2)
    end
    if not cm or cm <= 0 then return -1 end
    return cm * 10
end

-- Helper: Format mm distance for console display
local function fmt_dist(mm)
    if mm < 0 then return "N/A" end
    if mm >= 81000 then return "INF" end
    if mm >= 1000 then
        local m_int = mm / 1000
        local m_dec = (mm % 1000) / 100
        return tostring(m_int) .. "." .. tostring(m_dec) .. "m"
    end
    return tostring(mm / 10) .. "cm"
end

-- 3. Force Manual Focus (MF) so Canon never re-autofocuses on half-press
local orig_mf = get_focus_mode()
if orig_mf ~= 1 then
    set_mf(1)
    sleep(300)
end

if get_focus_mode() ~= 1 then
    print("WARN: Set Canon Focus to MF")
    print("(Q Menu -> MF, Cont.AF Off)")
    sleep(2000)
end

-- Clean restore if user aborts script with shutter button
function restore()
    if get_shooting() then
        release("shoot_full_only")
        release("shoot_half")
    end
    if orig_mf ~= 1 then
        set_mf(0)
    end
end

set_raw(1)
print("M3 Focus Stack starting in " .. d .. "s")
sleep(d * 1000)

-- 4. Lock exposure (Tv & Av) from current metering
press("shoot_half")
local wait_ms = 0
while not get_shooting() and wait_ms < 3000 do
    sleep(20)
    wait_ms = wait_ms + 20
end
local locked_tv = get_tv96()
local locked_av = get_av96()
release("shoot_half")
while get_shooting() do sleep(20) end
sleep(200)

-- 5. Optional: Drive lens to Minimum Focus Distance (MFD) first
if m == 1 then
    print("Driving lens to Near/MFD...")
    local prev_p = get_lens_pos()
    for _ = 1, 10 do
        call_event_proc("EFLensCom.FocusSearchNear")
        sleep(150)
        local cur_p = get_lens_pos()
        if cur_p == prev_p then break end
        prev_p = cur_p
    end
    sleep(200)
end

-- Helper: Shoot a single frame without triggering Canon AF
local function take_shot()
    if get_focus_mode() ~= 1 then
        set_mf(1)
        sleep(100)
    end
    press("shoot_half")
    local w = 0
    while not get_shooting() and w < 3000 do
        sleep(10)
        w = w + 10
    end
    set_tv96_direct(locked_tv)
    set_av96_direct(locked_av)

    if type(hook_shoot) == "table" and type(hook_shoot.count) == "function" then
        local prevcnt = hook_shoot.count()
        press("shoot_full_only")
        local sw = 0
        while prevcnt == hook_shoot.count() and sw < 15000 do
            sleep(10)
            sw = sw + 10
        end
        release("shoot_full_only")
    else
        press("shoot_full_only")
        sleep(200)
        release("shoot_full_only")
    end

    release("shoot_half")
    while get_shooting() do sleep(20) end
    sleep(400)
end

-- 6. Step through focus stack from foreground to Infinity
local cur_step = s
local reached_inf = false
local shots_taken = 0

for shot = 1, n do
    local pos_before = get_lens_pos()
    local dist_mm = get_m3_dist_mm()
    print(string.format("Shot %d/%d | Step:%d | %s", shot, n, pos_before, fmt_dist(dist_mm)))

    take_shot()
    shots_taken = shots_taken + 1

    if dist_mm >= 81000 then
        print("Optical infinity (81m+) reached!")
        reached_inf = true
        break
    end

    if shot < n then
        call_event_proc("EFLensCom.MoveFocus", cur_step, 1)
        sleep(200)
        local pos_after = get_lens_pos()

        -- Verify motor actually moved
        if pos_before ~= -1 and pos_after == pos_before then
            if shot == 1 then
                print("WARN: Lens motor did not move!")
                print("Check EF-M lens & MF mode.")
            else
                print("Lens reached infinity stop.")
            end
            reached_inf = true
            break
        end

        -- Progressively widen step size as DoF deepens with distance
        cur_step = cur_step + (cur_step * g) / 100
        if cur_step < 1 then cur_step = 1 end
    end
end

-- 7. Optional Final True-Infinity Frame (FocusSearchFar)
if f == 1 then
    local pos_pre_inf = get_lens_pos()
    print("Driving to True Infinity...")
    call_event_proc("EFLensCom.FocusSearchFar")
    sleep(350)
    local pos_inf = get_lens_pos()
    if pos_inf ~= pos_pre_inf or not reached_inf then
        shots_taken = shots_taken + 1
        print(string.format("Final INF Shot (#%d) | Step:%d", shots_taken, pos_inf))
        take_shot()
    end
end

restore()
play_sound(4)
print("Focus Stack Done! (" .. shots_taken .. " shots)")
sleep(2000)
