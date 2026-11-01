--[[
@title Panorama Lock & Stitch Helper
@param n Number of Pano Panels
@default n 6
@param d Initial Delay (sec)
@default d 2
@param p Pause to Rotate Tripod (sec)
@default p 4
@param i Target ISO
@default i 100
@param b Bracket Each Panel? (0=No, 1=3-Stop)
@default b 0
--]]

print("=== PANORAMA HELPER ===")
set_raw(1)
set_iso_real(i)

print("Metering & locking first frame in " .. d .. "s...")
sleep(d * 1000)

-- Half-press shutter to meter and focus on primary frame
press("shoot_half")
repeat
    sleep(50)
until get_shooting() == true

-- Lock Focus and read exact exposure values so all panorama panels match 100%
set_aflock(1)
local locked_tv = get_tv96()
local locked_av = get_av96()
release("shoot_half")
sleep(500)

print("Locked TV96: " .. locked_tv .. " | AV96: " .. locked_av)

for panel = 1, n do
    print("=== PANEL " .. panel .. " of " .. n .. " ===")
    
    if b == 0 then
        set_tv96_direct(locked_tv)
        set_av96_direct(locked_av)
        shoot()
        sleep(800)
    else
        -- 3-stop bracket (-2, 0, +2 EV) per panorama panel for HDR Panorama
        local offsets = {-192, 0, 192}
        for k = 1, 3 do
            set_tv96_direct(locked_tv - offsets[k])
            set_av96_direct(locked_av)
            shoot()
            sleep(800)
        end
    end
    
    if panel < n then
        play_sound(4) -- Audio beep cue: rotate tripod ~30% overlap now!
        print("ROTATE TRIPOD NOW (" .. p .. "s)...")
        sleep(p * 1000)
    end
end

set_tv96_direct(locked_tv)
set_aflock(0)
play_sound(4)
sleep(200)
play_sound(4)
print("Panorama Sequence Complete!")
