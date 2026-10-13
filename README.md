# ThinkPad T450 Dual-Boot & Windows 10 Performance Tuning Guide

[![Hardware](https://img.shields.io/badge/Hardware-ThinkPad%20T450-red.svg)](https://www.lenovo.com)
[![CPU](https://img.shields.io/badge/CPU-Intel%20Core%20i5--5300U%20(2C%2F4T)-blue.svg)](https://ark.intel.com)
[![OS](https://img.shields.io/badge/Dual%20Boot-Windows%2010%20%7C%20Linux%20Mint-green.svg)](https://linuxmint.com)
[![Storage](https://img.shields.io/badge/SSD-Kingston%20A400%20(DRAM--less%20SATA)-orange.svg)](https://www.kingston.com)
[![Partitioning](https://img.shields.io/badge/Partition-MBR%20(Legacy%20BIOS)-purple.svg)](https://learn.microsoft.com)

A battle-tested operational guide, automation scripts, and Standard Operating Procedures (SOP) for configuring seamless dual-boot (Windows 10 + Linux Mint) on the Lenovo ThinkPad T450 without pressing `F12` on startup, and eliminating 100% CPU lockups and DRAM-less SSD I/O freezes on Windows 10.

---

## 1. Getting Started & Downloading the Repository

If you are setting this up on a new machine or following along:

### Method A: Clone via Git (Recommended)
```bash
git clone https://github.com/PainWorry/T450_Dual_Boot_Best_Practice.git
cd T450_Dual_Boot_Best_Practice
```

### Method B: Download ZIP (No Git Required)
1. Go to [https://github.com/PainWorry/T450_Dual_Boot_Best_Practice](https://github.com/PainWorry/T450_Dual_Boot_Best_Practice)
2. Click the green **Code** button -> **Download ZIP** (or [Direct Download Link](https://github.com/PainWorry/T450_Dual_Boot_Best_Practice/archive/refs/heads/main.zip)).
3. Extract the ZIP file to any folder on your computer (e.g. your Desktop).

---

## 2. Workstation Baseline Architecture

Telemetry captured from `LENOVO 20BUS02F0Z` (ThinkPad T450):

| Component | Specification | Operational Constraint |
| :--- | :--- | :--- |
| **Processor** | Intel Core i5-5300U @ 2.30 GHz (2 Cores / 4 Threads, 15W TDP) | Dual-core CPU easily saturates to 100% if background scanners (`MsMpEng.exe`) or browsers run unchecked. |
| **RAM** | 16 GB DDR3L | Ample memory headroom (RAM starvation is not a factor). |
| **Storage** | Kingston SA400S37480G (480GB SATA SSD) | **DRAM-less SSD** (Phison S11). Severe write latency spikes (up to 1000ms+) occur during background I/O churn. |
| **Firmware Mode** | Legacy BIOS / MBR Partitioning | Single MBR on Disk 0. Partition 2 is Windows NTFS (`C:`), Partition 4 is Linux Mint ext4. |
| **Fast Startup** | Disabled (`HiberbootEnabled = 0`) | Verified disabled; prevents NTFS filesystem locks across reboots. |

---

## 3. Quick Start (The 2-Minute Solution)

### Step 1: Windows 10 Lag Remediation (Run in Windows 10)
Inside the extracted/cloned folder:

#### Option A: 1-Click Launchers (Zero Typing)
- Double-click `run_preview_dryrun.bat` to preview actions safely.
- Right-click `run_apply_optimization.bat` -> **Run as administrator** to apply optimizations.
- If you ever want to revert, right-click `run_rollback.bat` -> **Run as administrator**.

#### Option B: Terminal Command (Elevated PowerShell or Command Prompt)
Navigate into the repository directory and run:
```powershell
# Preview changes without modifying system
powershell -ExecutionPolicy Bypass -File .\optimize_t450_performance.ps1 -DryRun

# Apply optimizations
powershell -ExecutionPolicy Bypass -File .\optimize_t450_performance.ps1
```

---

### Step 2: Dual-Boot Bootloader Setup (Run in Linux Mint)

#### First: Do You Already See the GRUB Black Screen on Boot?
If the GNU GRUB selection screen already appears automatically without pressing `F12`:
1. **Check if Windows 10 is listed**: Press Down Arrow to highlight `Windows Boot Manager` and press Enter. If Windows boots, **you do not need to reinstall GRUB**!
2. **Check if it counts down**: If it counts down and auto-boots your default OS, **you are 100% finished**.
3. If it does not count down automatically, simply run:
   ```bash
   sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub && sudo update-grub
   ```

#### If GRUB Does Not Appear Automatically (Bypasses to Windows / Requires F12):
Boot into Linux Mint (press `F12` during startup if needed), open Terminal (`Ctrl + Alt + T`), and run:

```bash
# 1. Install GRUB to the drive MBR and enable Windows 10 detection
sudo grub-install /dev/sda
echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a /etc/default/grub

# 2. Configure 5-second countdown menu defaulting to Linux Mint
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub

# 3. Apply and reboot
sudo update-grub
sudo reboot
```

---

## 4. Default OS Switching: The 3 Methods (In Linux Mint)

All boot behavior is defined in `/etc/default/grub`:

### Method A: Linux Mint as Default (Fixed)
Every cold boot starts with Linux Mint highlighted. After 5 seconds without user interaction, Linux Mint boots automatically.
```bash
sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub && sudo update-grub
```

---

### Method B: Windows 10 as Default (Fixed)
Every cold boot highlights Windows 10. After 5 seconds without user interaction, Windows 10 boots automatically.
```bash
WIN_ENTRY=$(grep -i -E "menuentry 'windows" /boot/grub/grub.cfg | head -n1 | cut -d"'" -f2)
sudo sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=\"$WIN_ENTRY\"/" /etc/default/grub && sudo update-grub
```

---

### Method C: Dynamic "Remember Last Booted OS" (Enterprise Best Practice)
The computer automatically boots whichever operating system was used last:
- Rebooting from Windows 10 reboots into Windows 10 automatically.
- Rebooting from Linux Mint reboots into Linux Mint automatically.
- You only need to touch the keyboard when you intentionally want to switch OS.
```bash
sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
grep -q "GRUB_SAVEDEFAULT=true" /etc/default/grub || echo "GRUB_SAVEDEFAULT=true" | sudo tee -a /etc/default/grub
sudo update-grub
```

---

## 5. Technical Breakdown of Windows 10 Performance Fixes

### Root Cause Analysis
1. **DRAM-less Kingston A400 SSD Contention**:
   The Phison S11 SSD controller lacks onboard DRAM cache. Windows background services (`SysMain` and `WSearch`) continuously write cache blocks to disk. During sustained random 4K write bursts, the controller's internal write buffer exhausts, spiking disk response times up to 1000ms+ and freezing the Windows GUI thread.
2. **Antimalware Service Executable (`MsMpEng.exe`)**:
   Windows Defender scans file writes in real time. Because Opera autostarts (`--autostart`) and continuously modifies cache files, Defender intercepts and scans these writes, saturating both physical cores of the i5-5300U processor.

### What `optimize_t450_performance.ps1` Does
- **Disables `SysMain` (Superfetch)**: Eliminates continuous background cache writes to the DRAM-less SSD.
- **Disables `WSearch` (Windows Search Indexer)**: Eliminates background disk indexing overhead.
- **Disables `DiagTrack`**: Stops background telemetry and diagnostic tracking.
- **Enforces NTFS TRIM**: Runs `fsutil behavior set DisableDeleteNotify 0` to preserve SSD flash endurance and garbage collection.
- **Caps Windows Defender CPU Ceiling to 20%**: Runs `Set-MpPreference -ScanAvgCPULoadFactor 20` so background scans never dominate the dual-core CPU.
- **Adds Defender Exclusions**: Excludes `MsMpEng.exe` (stops self-scanning) and Opera browser cache directories.
- **Purges Opera Autostart**: Deletes the `Opera Air Stable` startup entry from `HKCU:\Software\Microsoft\Windows\CurrentVersion\Run`.

### Rollback Procedure
To revert all services, Defender preferences, and startup configurations back to factory Windows defaults:
```powershell
powershell -ExecutionPolicy Bypass -File .\rollback_t450_performance.ps1
```

---

## 6. Hardware & Thermal Throttling Triage

A notorious failure mode on the ThinkPad T450 is **BD PROCHOT throttling**, where the CPU locks permanently to **0.79 GHz (800 MHz)**:

### Verification Command (PowerShell)
```powershell
Get-CimInstance Win32_Processor | Select-Object Name, MaxClockSpeed, CurrentClockSpeed
```

- **Normal Behavior**: `CurrentClockSpeed` scales dynamically between ~1200 MHz at idle and 2300–2900 MHz under load.
- **Throttling Lock**: If `CurrentClockSpeed` is frozen at **798 MHz / 800 MHz** even under synthetic load:
  1. Inspect the laptop heatsink fin stack and fan for dust accumulation.
  2. Reapply thermal compound (Arctic MX-4 or MX-6) on the CPU heat spreader.
  3. Verify the Lenovo AC power adapter handshake (an unauthorized or degraded charger can trigger BD PROCHOT).
  4. Use ThrottleStop to uncheck `BD PROCHOT` if hardware sensors are tripping erroneously.

---

## 7. Repository Index

All paths are relative to repository root:
```text
.
├── README.md                          # Master architecture guide and operations manual
├── LINUX_MINT_GRUB_SOP.md             # Dedicated Linux Mint GRUB configuration manual
├── optimize_t450_performance.ps1      # Windows 10 automated debloat & lag remediation script
├── rollback_t450_performance.ps1      # 1-Click rollback script to restore Windows defaults
├── run_preview_dryrun.bat             # 1-Click launcher for dry-run preview
├── run_apply_optimization.bat         # 1-Click launcher for applying optimizations
├── run_rollback.bat                   # 1-Click launcher for reverting changes
└── SKILL.md                           # Antigravity custom skill specification
```

---

## License
MIT License. Open for personal and enterprise deployment.
