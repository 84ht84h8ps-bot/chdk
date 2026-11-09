# Canon EOS M3 + CHDK: The Complete Master Guide
*A comprehensive field manual and post-processing guide for Astrophotography, Exposure Bracketing, Panoramas, HDR Panoramas, and Focus Stacking.*

---

## 📑 Table of Contents
1. [[#01. Hardware Architecture & Pre-Flight Checklist]]
2. [[#02. 5-Stop HDR Bracketing (bracket5_opt.lua) + Lightroom]]
3. [[#03. 60-Shot Astrophotography (fixedint.lua) + Siril Stacking]]
4. [[#04. Panoramic Landscape (pano_helper.lua) + Lightroom]]
5. [[#05. Masterclass: HDR Panorama (The Holy Grail)]]
6. [[#06. Infinite Focus Stacking (focus_stack.lua) + Photoshop]]
7. [[#07. Field Pocket Reference (Cheatsheet)]]

---

## 01. Hardware Architecture & Pre-Flight Checklist

### Understanding the EOS M3 + CHDK Boot
The Canon EOS M3 uses a **DIGIC 6 processor** running Canon's **DryOS** operating system. Although branded as an "EOS", its internal software architecture mirrors high-end PowerShot compacts rather than traditional DSLRs. Because of this, it cannot run Magic Lantern. 

Instead, it runs **CHDK (Canon Hack Development Kit)** via a bootable SD card:
- CHDK is **non-volatile**: it lives only in volatile RAM. It never overwrites camera ROM.
- When the SD card's physical lock switch is **DOWN (LOCKED)**, Canon's bootloader scans sector 0 at offset `0x1E0` (480 decimal) on FAT32 for the string `BOOTDISK`.
- If found, it loads `DISKBOOT.BIN` into RAM address `0x00008000` and displays the CHDK splash screen.

> [!IMPORTANT]
> ### Mandatory Native Canon Settings (Before Opening CHDK)
> Before attaching the camera to a tripod or launching scripts, configure these physical settings in the native Canon menu:
> - [ ] **Lens Image Stabilization (IS) &rarr; OFF:** Switch physical lens switch to OFF, or set in Canon Menu &rarr; Shoot Tab 1 &rarr; IS Settings &rarr; Off. *(Crucial: on a tripod, gyros create micro-vibrations causing blurry stars and soft seams).*
> - [ ] **White Balance &rarr; LOCKED (Manual):** Set to **Daylight (5200K)** for daytime/panoramas or **Tungsten (4000K)** for astrophotography. **Never leave on AWB (Auto)** or colors will shift between frames.
> - [ ] **Image Quality &rarr; RAW (CR2):** Set in native Canon menu. Produces 14-bit uncompressed `.CR2` sensor files.
> - [ ] **Image Review &rarr; OFF:** Canon Menu &rarr; Shoot Tab 1 &rarr; Image Review &rarr; Off. Prevents LCD preview pauses from stalling script timing.
> - [ ] **Long Exposure Noise Reduction &rarr; OFF:** Custom Functions (C.Fn) &rarr; Long Exp. Noise Reduction &rarr; Off. Prevents the camera from taking a 15-second black frame after every shot.

### Camera Button Mapping in CHDK
- **`M-Fn` Button** (beside shutter): Toggles **`<ALT>` mode** ON and OFF.
- **`MENU` Button** (while in `<ALT>` mode): Opens the **CHDK Main Menu**.
- **`SET` Button** (center of D-pad): Selects an item or enters a submenu.
- **`Shutter Button`** (while in `<ALT>` mode): Starts the loaded script. Pressing again safely aborts the script.

> [!TIP]
> ### One-Time Prerequisite: Enable Lua Native Calls
> In CHDK Menu &rarr; **Miscellaneous stuff** &rarr; scroll to **Enable Lua Native Calls** &rarr; press SET to check `[ * ]`. This grants CHDK permission to execute low-level DryOS `EFLensCom` motor calls to drive EF-M autofocus stepper motors.

---

## 02. 5-Stop HDR Bracketing (bracket5_opt.lua) + Lightroom

### Why Use 5-Stop Bracketing?
The human eye perceives 20+ stops of light, while the EOS M3 sensor captures ~11.8 stops. High-contrast scenes (sunsets, caves, bright skies over dark landscapes) will either blow out highlights or crush shadows.

`bracket5_opt.lua` locks the aperture at **f/8** and programmatically shifts only the shutter speed across 5 exposures spaced 1 stop apart:
$$\mathbf{-2\text{ EV}} \longrightarrow \mathbf{-1\text{ EV}} \longrightarrow \mathbf{0\text{ EV}} \longrightarrow \mathbf{+1\text{ EV}} \longrightarrow \mathbf{+2\text{ EV}}$$

### Step-by-Step Field Execution
1. Mount the camera on a solid tripod.
2. Turn the main dial to **Av (Aperture Priority)** or **M (Manual)**. Set aperture to **f/8** and ISO to **100**.
3. Half-press the shutter button once to meter the scene's baseline (`0 EV`) exposure.
4. Press **`M-Fn`** to enter `<ALT>` mode.
5. Press **`MENU`** &rarr; **Script** &rarr; **Load Script from File...** &rarr; select `bracket5_opt.lua`.
6. Verify parameters:
   - `Step size (EV)`: `1`
   - `Timer Delay (sec)`: `2` (eliminates hand shake)
   - `Target ISO`: `100`
7. Press **`MENU`** to close. Press the **Shutter button**.
8. The camera waits 2 seconds, locks autofocus, fires 5 rapid exposures, and restores your initial settings.

### Step-by-Step Lightroom HDR Merge Workflow
1. Import the 5 `.CR2` RAW files into **Adobe Lightroom Classic** or **Lightroom CC**.
2. In the Library Grid view (`G`), Shift-click the 5 bracketed photos.
3. Press **`Cmd + H`** (Mac) or **`Ctrl + H`** (Win), or right-click &rarr; **Photo Merge &rarr; HDR**.
4. In the HDR Preview window:
   - Check **Auto Align** (aligns micro-movements caused by wind).
   - Check **Auto Settings** (gives an even, neutral starting tone map).
   - Set **Deghost Amount** to **Low** (or None; use Medium if tree leaves or waves moved).
5. Click **Merge**. Lightroom generates a new 32-bit floating-point `[filename]-HDR.dng` file.
6. Open the Develop Module (`D`):
   - **Highlights:** Pull down to **-60 to -80** to reveal full cloud color and solar detail.
   - **Shadows:** Push up to **+30 to +60** to recover noise-free shadow detail.
   - **Whites / Blacks:** Hold `Option` (Mac) / `Alt` (Win) while dragging sliders to set clean white/black clipping points.

---

## 03. 60-Shot Astrophotography (fixedint.lua) + Siril Stacking

### The Physics: Why Stacking 60 Frames Beats a Single Exposure
Leaving the shutter open for 15 minutes on a tripod results in:
1. Long star trails caused by Earth's rotation.
2. Severe sensor heat (amp glow) and hot red/green pixels.

When you stack 60 short frames, the astronomical signal adds up linearly while random thermal noise adds only by the square root:
$$\text{SNR Improvement} = \sqrt{N} = \sqrt{60} \approx \mathbf{7.75\times\text{ Cleaner Signal!}}$$

### The 500 Rule Table (EOS M3 1.6x APS-C Crop)
$$\text{Max Shutter Speed (sec)} = \frac{500}{\text{Focal Length (mm)} \times 1.6}$$

| Lens | Focal Length | Calculated Limit | Recommended Setting |
|---|---|---|---|
| EF-M 11-22mm f/4-5.6 | 11mm | $500 / (11 \times 1.6) = 28.4\text{s}$ | **20s to 25s** |
| EF-M 15-45mm f/3.5-6.3 | 15mm | $500 / (15 \times 1.6) = 20.8\text{s}$ | **15s to 20s** |
| EF-M 22mm f/2 STM | 22mm | $500 / (22 \times 1.6) = 14.2\text{s}$ | **13s to 15s** |

### Step-by-Step Field Focusing (10x Live View Trick)
1. Switch your lens to **MF (Manual Focus)**.
2. Set camera to **M mode**: Aperture wide open (`f/2` or `f/3.5`), ISO **1600** or **3200**.
3. Aim at the brightest star in the sky (e.g. Sirius, Vega) or a distant light on the horizon.
4. Press the blue **Magnify button** on the camera back twice for **10x zoom**.
5. Slowly rotate the focus ring until the star shrinks into the smallest, sharpest pinpoint.
6. Apply a strip of painter's tape across the focus ring so it cannot slip.

### Configuring fixedint.lua in CHDK
1. Press **`M-Fn`** (&lt;ALT&gt;) &rarr; **`MENU`** &rarr; **Script** &rarr; **Load Script from File...** &rarr; select `fixedint.lua`.
2. Configure parameters:
   - `Shots (0=unlimited)`: `60`
   - `Interval Sec/10 (0=max)`: `0` *(Captures continuously with zero dead-time!)*
   - `Tv`: Select `15` or `20` (matching your 500-rule shutter speed)
   - `Disable Canon Dark Frame`: `true` *(CRUCIAL: Prevents 15s freeze between shots)*
   - `Display`: `Blt_Off` *(Shuts off LCD backlight: cuts sensor heat & extends battery)*
   - `Start delay (ms)`: `3000` *(3 seconds for tripod vibrations to settle)*
   - `Shutdown on low battery`: `true`
3. Press **`MENU`** to close. Press the **Shutter button**.
4. Step back! The LCD turns black, and the camera captures 60 frames smoothly (~15-20 min).

### Step-by-Step Siril Stacking Tutorial (macOS)
1. Open **Siril**.
2. Click the **Home icon** (top-left) and select the directory containing your 60 `.CR2` files.
3. In the top menu, go to **Scripts &rarr; OSC_Preprocessing_WithoutDBF**.
   - Siril automatically converts the CR2s, debayers them, registers star positions with sub-pixel accuracy, and stacks them using **Winsorized Sigma Clipping** rejection.
   - *Result:* Satellite streaks, airplanes, and hot pixels are mathematically erased!
4. When finished, open the newly created `result.fit`.
5. **Background Extraction:**
   - Go to **Image Processing &rarr; Background Extraction**.
   - Click *Generate* to create a grid of background samples (avoiding bright stars).
   - Click *Apply*. Light pollution and city sky glow gradients are subtracted.
6. **Photometric Color Calibration (PCC):**
   - Go to **Image Processing &rarr; Photometric Color Calibration**.
   - Enter your celestial target (e.g. "Milky Way", "M31", or RA/Dec coordinates).
   - Click *Find* &rarr; *Apply*. Siril queries the Gaia/NOMAD star catalog and calibrates true astronomical white balance based on the physical spectrum of real stars.
7. **Asinh Stretch:**
   - Go to **Image Processing &rarr; Asinh Transformation**.
   - Adjust the stretch slider to reveal faint galactic dust clouds without blowing out star cores.
8. Click the Save button and export as a **16-bit TIFF**.

### Step-by-Step Lightroom Final Polish
1. Import the 16-bit TIFF into Lightroom.
2. In the Develop module:
   - **Dehaze (+10 to +15):** Cuts lingering atmospheric haze and boosts nebula contrast.
   - **Clarity (+10) & Texture (+10):** Enhances cosmic dust lanes.
   - **Noise Reduction &rarr; Luminance:** Leave at **0**! Noise was already mathematically eliminated in Siril.
   - **Radial Mask:** Place over the Milky Way core, boost Exposure +0.3 and Warmth +5.

---

## 04. Panoramic Landscape (pano_helper.lua) + Lightroom

### The 4 Fatal Flaws of Handheld Panoramas
1. **Exposure Drift:** Auto-shutter shifts as you pan from sun to shadow, creating visible vertical stripes.
2. **White Balance Shift:** Auto White Balance shifts Kelvin temperature frame-to-frame.
3. **Focus Hunting:** AF focuses near in panel 1 and far in panel 2, creating blurry seams.
4. **Insufficient Overlap:** Less than 30% overlap causes feature detection failure.

### Physical Setup
- **Mount Vertically (Portrait Mode):** Use an L-bracket or tilted tripod head. Vertical frames provide **6000 vertical pixels** of resolution, producing natural landscape proportions instead of a narrow ribbon.
- **Level the Tripod Head:** Ensure the panning base is level with the horizon.
- **Camera Settings:** Dial to **M mode**, **f/8, ISO 100**, White Balance set to **Daylight (5200K)**.

### Shooting with pano_helper.lua
1. Aim at the **primary midtone region** of your landscape.
2. Press **`M-Fn`** (&lt;ALT&gt;) &rarr; **`MENU`** &rarr; **Script** &rarr; **Load Script from File...** &rarr; select `pano_helper.lua`.
3. Configure parameters:
   - `Number of Pano Panels`: `6` (or desired panel count)
   - `Pause to Rotate Tripod (sec)`: `4`
   - `Bracket Each Panel?`: `0` (standard single-exposure mode)
4. Press **`MENU`** to exit. Aim at your **starting frame (far left)**.
5. Press the **Shutter button**:
   - The camera half-presses to meter, locks shutter, aperture, ISO, and autofocus, then shoots Panel 1.
   - **BEEP!** You will hear an audio chime.
   - Smoothly turn your tripod head to the right by ~30% overlap during the 4-second pause.
   - Take your hands off. Panel 2 fires automatically.
   - Repeat until the camera double-beeps to signal the sweep is complete.

### Lightroom Stitching Workflow
1. In Lightroom Library grid (`G`), select all 6 panels.
2. Press **`Cmd + M`** (Mac) or **`Ctrl + M`** (Win), or right-click &rarr; **Photo Merge &rarr; Panorama**.
3. In the Panorama Preview:
   - Select **Cylindrical Projection** *(keeps horizons straight across wide vistas)*.
   - Set **Boundary Warp** to **80-90** to expand edges into frame corners.
   - Check **Fill Edges** to synthesize missing sky/ground corners.
4. Click **Merge**. Lightroom creates an 80+ megapixel `[filename]-Pano.dng` RAW file.

---

## 05. Masterclass: HDR Panorama (The Holy Grail)

### What is an HDR Panorama?
When photographing a sunrise or sunset spanning 160°, the setting sun is +4 EV above ambient, while shaded foreground trees are -3 EV below ambient. Single-shot panoramas blow out the sun or plunge the foreground into black noise.

An **HDR Panorama** captures an exposure bracket at *every single rotation angle*:
$$\mathbf{6\text{ Pano Panels}} \times \mathbf{3\text{ Bracketed Exposures } (-2, 0, +2\text{ EV})} = \mathbf{18\text{ RAW Frames Total}}$$

### Step-by-Step Field Execution with pano_helper.lua
1. Mount camera vertically on your tripod. Dial to **M mode at f/8, ISO 100, WB Daylight (5200K)**.
2. Press **`M-Fn`** (&lt;ALT&gt;) &rarr; **`MENU`** &rarr; **Script** &rarr; **Load Script from File...** &rarr; select `pano_helper.lua`.
3. Configure parameters:
   - `Number of Pano Panels`: `6`
   - `Pause to Rotate Tripod (sec)`: `5` (extra second to rotate smoothly)
   - `Bracket Each Panel?`: `1` &larr; **CRUCIAL: Enables 3-stop HDR bracketing at each angle!**
4. Press **`MENU`** to exit. Aim at your starting frame (far left) and press the **Shutter button**:
   - Camera locks exposure baseline and fires 3 rapid bracketed shots: -2 EV (sky), 0 EV (midtones), and +2 EV (shadows).
   - **BEEP!** Rotate your tripod head to the right by ~30% overlap during the 5-second pause.
   - Take your hands off. Camera fires the next 3 bracketed shots!
   - Repeat across all 6 panels until all 18 frames are captured.

### Lightroom's 1-Click "HDR Panorama" Merge
> [!TIP]
> Do NOT waste time merging each bracket into an HDR file first! Lightroom has a unified engine that merges brackets and stitches the panorama simultaneously.

1. In Lightroom Library grid (`G`), select all **18 RAW files** simultaneously.
2. Press **`Cmd + Shift + M`** (Mac) or **`Ctrl + Shift + M`** (Win), or right-click &rarr; **Photo Merge &rarr; HDR Panorama**.
3. Lightroom's AI engine automatically groups the 18 frames into 6 brackets, creates 32-bit HDRs in memory, and stitches the panoramic projection in a single pass.
4. Set Projection to **Cylindrical**, set **Boundary Warp** to **80-90**, and check **Fill Edges**.
5. Click **Merge**. Lightroom creates a colossal **100+ Megapixel, 32-bit Floating-Point `.DNG`** file!

### Developing the Masterpiece in Lightroom Develop Module (D)
- **Highlights (-70 to -90):** The blazing sun and sunset clouds reveal rich orange/purple textures without gray muddy clipping.
- **Shadows (+30 to +50):** Deep foreground trees and canyon rocks emerge with crystal clarity and **zero noise** because they were captured at +2 EV in the bracket!
- **Texture (+15) & Clarity (+10):** Accentuates micro-contrast across the entire 100-megapixel vista.
- **Zoom to 100%:** Pan across your image to inspect tack-sharp foliage, distant peaks, and rock textures miles away.

---

## 06. Infinite Focus Stacking (focus_stack.lua) + Photoshop

### Why Focus Stacking Beats f/22 (Diffraction Physics)
On the EOS M3's 24MP APS-C sensor, pixels measure just **3.72 microns**. When light passes through an f/22 pinhole, light waves bend and create an interference pattern (*Airy disc*) spanning multiple pixels, physically smearing fine details.

By shooting at **f/8** (the lens's peak optical resolving power) and stepping the focus motor incrementally from foreground to infinity, you achieve **infinite depth of field with 3x higher sharpness**!

### Mandatory EOS M3 Settings Before Focus Stacking
> [!IMPORTANT]
> Standard CHDK `set_focus()` is **not implemented** on the Canon EOS M3. To move electronic EF-M lenses, `focus_stack.lua` uses Canon's internal `FA.Create`, `InitializeAdjustmentSystem`, and `EFLensCom.MoveFocus` firmware procedures. Check these **3 settings** before shooting:
> 1. **CHDK Lua Native Calls ON:** Press **`M-Fn`** (&lt;ALT&gt;) &rarr; **`MENU`** &rarr; **Miscellaneous stuff** &rarr; enable **`Enable Lua Native Calls [*]`** (confirm *"Are you sure?"* with `SET`).
> 2. **Canon Focus Mode = MF & Continuous AF = Off:** Because EF-M lenses lack a physical AF/MF switch on the barrel, exit &lt;ALT&gt; mode, press **`Q / SET`** &rarr; switch Focus Mode to **`MF` (Manual Focus)**, and set **Continuous AF: Off** in the Canon menu so half-pressing the shutter never re-autofocuses.
> 3. **Electronic EF-M (or Adapted EF/EF-S) Lens:** Fully manual third-party lenses (TTArtisan/7Artisans) have no internal focus motor.

### Field Setup & Shooting with focus_stack.lua
1. Mount camera on a steady tripod. Set mode dial to **M or Av at f/8, ISO 100**.
2. In Canon **MF** mode, turn the focus ring to focus sharply on the **closest object in your foreground** (or set `Start Position = 1` in the script to drive to Minimum Focus Distance automatically).
3. Press **`M-Fn`** (&lt;ALT&gt;) &rarr; **`MENU`** &rarr; **Script** &rarr; **Load Script from File...** &rarr; select `focus_stack.lua`.
4. Configure parameters:
   - `Start Position (0=Current, 1=Near/MFD)`: `0`
   - `Max Shots (Safety Cap)`: `15`
   - `Initial Step Size (Motor Steps)`: `25`
   - `Step Growth % per Shot`: `40` *(progressively widens steps as Depth of Field grows with distance)*
   - `Final True-Infinity Shot`: `1 (Yes)` *(drives lens to optical infinity via `EFLensCom.FocusSearchFar`)*
   - `Initial Delay`: `2` (seconds)
5. Press **`MENU`** to exit. Press the **Shutter button**:
   - The script initializes `FA.Create` + `InitializeAdjustmentSystem`, enforces `set_mf(1)`, locks exposure (Tv/Av), and fires the foreground shot.
   - Between shots, it steps the EF-M motor outward via `EFLensCom.MoveFocus` with progressive step growth (`+40%` per frame), displaying live motor step and Canon distance (`cm` / `m` / `INF`) on screen.
   - Stops automatically once optical infinity (`81m+`) is reached and takes a guaranteed final **True Infinity** frame via `EFLensCom.FocusSearchFar`.

### Photoshop Depth-of-Field Blending Tutorial
1. Open **Adobe Photoshop**. Go to **File &rarr; Scripts &rarr; Load Files into Stack**.
2. Select your 12 frames.
3. Check **Attempt to Automatically Align Source Images** &rarr; click **OK**. *(Crucial: counteracts focus breathing, where focusing alters optical focal length).*
4. In the Layers panel, select all 12 layers (`Cmd + Option + A` on Mac / `Ctrl + Alt + A` on Win).
5. Go to **Edit &rarr; Auto-Blend Layers**.
6. Select **Stack Images** and check **Seamless Tones and Colors**. Click **OK**.
7. Photoshop calculates sharpness contrast at every pixel, automatically masking blurry areas and blending the tack-sharp pixels into a single master image sharp from 15cm to infinity!

---

## 07. Field Pocket Reference (Cheatsheet)

### Quick Settings Matrix

| Mode | Script | Camera Settings | Key CHDK Parameters | Software Workflow |
|---|---|---|---|---|
| **5-Stop HDR** | `bracket5_opt.lua` | Av/M, f/8, ISO 100, WB Daylight | `Step size: 1`, `Delay: 2s` | Lightroom: `Cmd + H` &rarr; 32-bit DNG |
| **Astrophotography** | `fixedint.lua` | M, f/2-f/3.5, ISO 1600-3200, WB 4000K | `Shots: 60`, `Interval: 0`, `Tv: 15s`, `Display: Blt_Off` | Siril: `OSC_Preprocessing` &rarr; PCC &rarr; Asinh |
| **Standard Panorama** | `pano_helper.lua` | M, f/8, ISO 100, WB Daylight, Portrait | `Panels: 6`, `Pause: 4s`, `Bracket: 0` | Lightroom: `Cmd + M` &rarr; Cylindrical Pano |
| **HDR Panorama** | `pano_helper.lua` | M, f/8, ISO 100, WB Daylight, Portrait | `Panels: 6`, `Pause: 5s`, `Bracket: 1` | Lightroom: `Cmd + Shift + M` &rarr; 100MP DNG |
| **Focus Stacking** | `focus_stack.lua` | Av/M, f/8, ISO 100, Start at 15cm MF | `Shots: 12`, `Step size: 15` | Photoshop: *Load Stack (Align)* &rarr; *Auto-Blend* |

### Emergency Field Controls
- **Toggle CHDK Mode:** Tap **`M-Fn`** (next to shutter).
- **Abort Running Script:** Press the **Shutter button** once while script is executing.
- **Camera Freeze Recovery:** If an experimental call ever locks the camera, open battery door for 5 seconds. Nothing is permanently damaged.
