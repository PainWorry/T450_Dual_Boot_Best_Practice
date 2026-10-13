---
name: thinkpad-system-tuning
description: Enterprise hardware performance triage, DRAM-less SSD optimization, Windows Defender CPU mitigation, and MBR dual-boot maintenance for Lenovo ThinkPad workstations.
---

# ThinkPad System Tuning & Dual-Boot Maintenance Skill

## Overview
This skill codifies enterprise operational standards for diagnosing, tuning, and maintaining legacy Lenovo ThinkPad workstations (e.g. ThinkPad T450, Broadwell/Skylake U-series) configured with dual-boot environments (Windows 10 and Linux Mint/Ubuntu) and DRAM-less SATA solid-state drives (e.g. Kingston A400).

---

## 1. Hardware Architecture & Bottleneck Matrix

### 1.1 Dual-Core Mobile CPUs (i5-5200U / i5-5300U)
- **Bottleneck**: 2 physical cores / 4 threads with a 15W TDP limit.
- **Symptom**: 100% CPU lockups whenever background services (`MsMpEng.exe`, `SearchApp.exe`, `OneDrive`, `opera.exe`) initiate parallel tasks.
- **Remediation**:
  - Throttle Windows Defender scan CPU ceiling to 20%:
    ```powershell
    Set-MpPreference -ScanAvgCPUMultithreaded 20
    ```
  - Exclude `MsMpEng.exe` from scanning itself.
  - Exclude high-frequency browser cache folders from real-time inspection.

### 1.2 DRAM-less SATA SSDs (Kingston A400 / Phison S11)
- **Bottleneck**: Lack of onboard DRAM cache. During random 4K write bursts, the SSD controller's internal write buffer saturates, triggering severe I/O queue latency spikes (up to 1000ms+), freezing the desktop GUI.
- **Remediation**:
  - Disable `SysMain` (Superfetch) service:
    ```powershell
    Stop-Service -Name SysMain -Force
    Set-Service -Name SysMain -StartupType Disabled
    ```
  - Disable `WSearch` (Windows Search Indexer) or restrict indexing to non-developer folders:
    ```powershell
    Stop-Service -Name WSearch -Force
    Set-Service -Name WSearch -StartupType Disabled
    ```
  - Verify NTFS TRIM is enabled:
    ```powershell
    fsutil behavior set DisableDeleteNotify 0
    ```

### 1.3 Thermal & BD PROCHOT Throttling (0.79 GHz Lock)
- **Bottleneck**: ThinkPads often lock CPU frequency to 800 MHz (0.79 GHz) when BD PROCHOT (Bi-Directional Processor Hot) trips due to dried thermal paste, lint in the heatsink fin stack, or third-party power adapters.
- **Diagnostic Command**:
  ```powershell
  Get-CimInstance Win32_Processor | Select-Object Name, MaxClockSpeed, CurrentClockSpeed
  ```
- **Remediation**: Clean heatsink fins, reapply thermal compound (Arctic MX-4/MX-6), or use ThrottleStop to disable BD PROCHOT.

---

## 2. Dual-Boot Bootloader Maintenance (Legacy MBR + Linux Mint)

### 2.1 The Problem
On an MBR drive with Windows 10 and Linux Mint, Windows updates or partition flag changes can override MBR boot code, causing the system to bypass the boot countdown and require pressing `F12` to reach the alternate OS.

### 2.2 Standard Operating Procedure: Restore GRUB Primary Bootloader
To restore the native GRUB 5-second countdown menu:

1. Boot into **Linux Mint** (press `F12` on startup if needed).
2. Reinstall GRUB directly to the drive MBR:
   ```bash
   sudo grub-install /dev/sda
   ```
3. Ensure `os-prober` is enabled to detect Windows 10:
   ```bash
   echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a /etc/default/grub
   ```

### 2.3 Setting Default OS: 3 Enterprise Best-Practice Methods

#### Method A: Linux Mint as Default (Fixed)
In `/etc/default/grub`:
```text
GRUB_DEFAULT=0
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
```
Apply: `sudo update-grub`

#### Method B: Windows 10 as Default (Fixed)
Find Windows entry string:
```bash
grep -i -E "menuentry 'windows" /boot/grub/grub.cfg
```
In `/etc/default/grub`:
```text
GRUB_DEFAULT="Windows Boot Manager (on /dev/sda2)"
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
```
Apply: `sudo update-grub`

#### Method C: Dynamic "Remember Last Selected OS" (Recommended)
Automatically reboots into whichever OS was used last:
In `/etc/default/grub`:
```text
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
```
Apply: `sudo update-grub`

---

## 3. Instant 1-Line CLI Toggles (Linux Mint)

- **Switch to Linux Mint Default**:
  ```bash
  sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub && sudo update-grub
  ```
- **Switch to Windows 10 Default**:
  ```bash
  WIN_ENTRY=$(grep -i -E "menuentry 'windows" /boot/grub/grub.cfg | head -n1 | cut -d"'" -f2)
  sudo sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=\"$WIN_ENTRY\"/" /etc/default/grub && sudo update-grub
  ```
- **Switch to Remember Last OS**:
  ```bash
  sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
  grep -q "GRUB_SAVEDEFAULT=true" /etc/default/grub || echo "GRUB_SAVEDEFAULT=true" | sudo tee -a /etc/default/grub
  sudo update-grub
  ```

---

## 4. Automated Verification Checklist

- [ ] CPU clock scales above 2.0 GHz under load (not locked at 0.79 GHz).
- [ ] `SysMain` and `WSearch` services disabled and stopped.
- [ ] Windows Defender `ScanAvgCPUMultithreaded` set to 20.
- [ ] Opera autostart disabled.
- [ ] Machine powers on cleanly into the GRUB countdown menu without pressing F12.
