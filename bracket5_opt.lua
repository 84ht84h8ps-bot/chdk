--[[
@title Optimized 5-Stop Bracket (-2 to +2)
@param s Step size (EV)
@default s 1
@param d Timer Delay (sec)
@default d 2
@param i Target ISO
@default i 100
--]]

print("Initializing Optimized Bracket...")

-- 1. Force RAW capture via CHDK
set_raw(1)
print("CHDK RAW: Enabled")

-- 2. Lock ISO to prevent Auto-ISO compensation
set_iso_real(i)
print("ISO Locked to: " .. i)

-- 3. Initial delay to prevent camera shake
print("Timer: " .. d .. "s...")
sleep(d * 1000)

-- Lock autofocus to prevent focus hunting between frames
set_aflock(1)

-- Retrieve original shutter speed
local original_tv = get_tv96()

-- Calculate step size (96 CHDK units = 1 stop)
local step = s * 96
local exposures = {-2, -1, 0, 1, 2}

for idx = 1, 5 do
    local offset = exposures[idx] * step
    print("Shooting frame " .. idx .. " (" .. exposures[idx] .. " EV)")
    
    -- Note: In APEX96, LOWER tv96 = LONGER exposure (+EV), HIGHER tv96 = FASTER shutter (-EV)
    -- Therefore, subtracting offset shifts exposure properly (-2 EV = +192 tv96, +2 EV = -192 tv96)
    set_tv96_direct(original_tv - offset)
    
    -- Trigger shutter
    shoot()
    
    -- Buffer pause (also helps bypass brief Image Review interruptions)
    sleep(800) 
end

-- Restore original settings
set_tv96_direct(original_tv)
set_aflock(0)
play_sound(4)
print("Bracket Complete!")
