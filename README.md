# Canon EOS M3 CHDK Master Repository

Automated CHDK scripts, installer utilities, and complete field tutorials for the **Canon EOS M3 (DIGIC 6)** mirrorless camera.

---

## 🌐 Online Interactive Website (Free)
Access the complete interactive guide on your iPhone, iPad, or computer:
👉 **[https://84ht84h8ps-bot.github.io/chdk/](https://84ht84h8ps-bot.github.io/chdk/)**

*(To view offline on your iPhone: Open the link above in Safari on your iPhone &rarr; tap the Share button &rarr; tap **"Add to Home Screen"**).*

---

## 📓 Obsidian Markdown Guide
For Obsidian users, a comprehensive offline Markdown guide formatted with callouts and checklists is available at:
👉 [`Canon_EOS_M3_CHDK_Obsidian_Guide.md`](./Canon_EOS_M3_CHDK_Obsidian_Guide.md)

---

## 📜 Included Scripts

| Script | Purpose | Recommended Settings |
|---|---|---|
| **`bracket5_opt.lua`** | 5-Stop HDR exposure bracket (&minus;2 to +2 EV) | Av/M, f/8, ISO 100, Step: 1, Delay: 2s |
| **`fixedint.lua`** | Deep sky astrophotography & star trails | M, f/2-f/3.5, ISO 1600-3200, Shots: 60, Interval: 0, Display: Blt_Off |
| **`pano_helper.lua`** | Panoramic landscape with audio rotation cues & optional HDR | M, f/8, ISO 100, Portrait, Panels: 6, Pause: 4-5s |
| **`focus_stack.lua`** | Macro-to-infinity focus stacker using EF-M stepper motors | Av/M, f/8, ISO 100, Start at 15cm MF, Shots: 12, Step: 15 |
| **`astro_interval.lua`** | Milky Way intervalometer with automated Dark Frame calibration | M, ISO 1600, Exp: 15-20s, Light frames + Dark frames |
| **`rawopint.lua`** | Day-to-night holy grail sunset-to-stars timelapse | M, Continuous raw sensor exposure metering |

---

## 🛠️ Mac Installation Utilities
- **`make_bootable.sh`**: Prepares the FAT32 boot sector (`BOOTDISK` at offset 480) on macOS.
- **`install_to_sdcard.sh`**: Automated installer that extracts CHDK, copies scripts, and sets up boot sectors.
