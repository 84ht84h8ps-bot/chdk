--[[
@title Focus Stack to Infinity (EOS M3)
@param n Number of Shots
@default n 12
@param s Step Size (EF-M Motor Steps)
@default s 15
@param d Initial Delay (sec)
@default d 2
@param i Target ISO
@default i 100
--]]

-- NOTE FOR CANON EOS M3 (DIGIC 6):
-- Standard CHDK set_focus() does not move interchangeable EF-M lenses.
-- On the EOS M3, focus stacking uses Canon's native EFLensCom.MoveFocus EventProc
-- (requires Enable Lua Native Calls in CHDK Miscellaneous Menu) with fallback to set_focus.

print("Starting M3 Focus Stack in " .. d .. "s...")
set_raw(1)
set_iso_real(i)
sleep(d * 1000)

local original_tv = get_tv96()

-- Try initializing Canon EF-M Lens EventProc (if Lua Native Calls enabled)
local has_native = (type(call_event_proc) == "function")
if has_native then
    call_event_proc("System.Create")
    call_event_proc("Driver_EnableEventProc")
    print("EF-M Native Lens Motor: Ready")
else
    print("Note: Enable Lua Native Calls")
    print("in Misc Menu for EF-M motor!")
    set_aflock(1)
end

for shot = 1, n do
    print("Shooting frame " .. shot .. " of " .. n)
    set_tv96_direct(original_tv)
    shoot()
    sleep(800)
    
    if shot < n then
        if has_native then
            -- Step EF-M lens focus motor towards infinity (step size s, speed 1)
            call_event_proc("EFLensCom.MoveFocus", s, 1)
            sleep(400)
        else
            -- Fallback if native calls not yet enabled
            local dist = get_focus()
            if dist > 0 and dist < 60000 then
                set_focus(dist + (dist * 2) / 10 + 10)
            end
            sleep(300)
        end
    end
end

set_aflock(0)
play_sound(4)
print("Focus Stack Complete!")
