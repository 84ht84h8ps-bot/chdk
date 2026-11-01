--[[
@title Astro Intervalometer (EOS M3)
@param n Number of Light Frames
@default n 20
@param e Exposure Time (sec)
@default e 15
@param i Target ISO
@default i 1600
@param d Initial Delay (sec)
@default d 5
@param b Between Shots Pause (sec)
@default b 3
@param k Take Dark Frames? (0=No, 1=Yes)
@default k 0
@param m Dark Frame Count
@default m 5
--]]

print("=== ASTRO INTERVALOMETER ===")

-- 1. Enable CHDK RAW/DNG and lock settings
set_raw(1)
set_iso_real(i)
set_aflock(1)

-- Lock focus to infinity (-1 / 65535 in CHDK)
set_focus(65535)

-- Convert seconds to APEX96 shutter speed units: tv96 = -96 * log2(seconds)
-- Pre-computed lookup table for common astro exposure times (seconds -> tv96)
function sec_to_tv96(sec)
    if sec <= 1 then return 0 end
    if sec == 2 then return -96 end
    if sec == 4 then return -192 end
    if sec == 6 then return -248 end
    if sec == 8 then return -288 end
    if sec == 10 then return -319 end
    if sec == 13 then return -355 end
    if sec == 15 then return -375 end
    if sec == 20 then return -415 end
    if sec == 25 then return -446 end
    if sec == 30 then return -471 end
    -- Approximate fallback for other values
    return -375
end

local tv_astro = sec_to_tv96(e)
local original_tv = get_tv96()

print("ISO: " .. i .. " | Exp: " .. e .. "s")
print("Starting in " .. d .. "s...")
sleep(d * 1000)

-- Turn off display backlight after first setup to reduce thermal noise & save battery
set_lcd_display(0)

for frame = 1, n do
    print("Light Frame " .. frame .. " of " .. n)
    set_tv96_direct(tv_astro)
    shoot()
    sleep(b * 1000)
end

set_lcd_display(1)
play_sound(4) -- Beep to notify light frames finished
print("Light frames complete!")

if k == 1 then
    print("PUT LENS CAP ON NOW!")
    print("Dark frames start in 15s...")
    sleep(15000)
    set_lcd_display(0)
    for dark = 1, m do
        print("Dark Frame " .. dark .. " of " .. m)
        set_tv96_direct(tv_astro)
        shoot()
        sleep(b * 1000)
    end
    set_lcd_display(1)
    play_sound(4)
    print("Dark frames complete!")
end

-- Restore state
set_tv96_direct(original_tv)
set_aflock(0)
print("Astro Session Finished!")
