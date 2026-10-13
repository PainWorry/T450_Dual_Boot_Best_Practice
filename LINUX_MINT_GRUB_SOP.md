# Standard Operating Procedure (SOP): GRUB Dual-Boot Setup & Default OS Switching

## 1. Objective
Establish and maintain a resilient GRUB2 dual-boot bootloader on the ThinkPad T450 primary drive (`/dev/sda`). Provides complete, step-by-step procedures to toggle default boot targets between **Linux Mint** and **Windows 10**, configure countdown timers, or enable the dynamic **"Remember Last Booted OS"** mode.

---

## 2. Accessing This Document From Linux Mint
When booted into Linux Mint:
1. Open the file manager (**Nemo**).
2. Look at the left sidebar under **Devices** for your Windows drive (typically labelled `236 GB Volume` or `Windows`).
3. Click to mount it.
4. Navigate to:
   ```text
   /media/<username>/<UUID>/Users/herre/Desktop/ThinkPad_T450_DualBoot_and_Tuning_Guide/
   ```
5. Open this `LINUX_MINT_GRUB_SOP.md` file in **Xed** (default text editor) or view it in terminal:
   ```bash
   cat "/media/$USER/"*"/Users/herre/Desktop/ThinkPad_T450_DualBoot_and_Tuning_Guide/LINUX_MINT_GRUB_SOP.md"
   ```

---

## 3. Initial Bootloader Installation (Run Once in Linux Mint)
To make GRUB the master bootloader so you never have to press `F12` on startup:

1. Open Terminal (`Ctrl + Alt + T`).
2. Install GRUB to the drive's Master Boot Record (do NOT append a partition number—use `/dev/sda`):
   ```bash
   sudo grub-install /dev/sda
   ```
3. Ensure `os-prober` is enabled to detect Windows 10:
   ```bash
   echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a /etc/default/grub
   ```

---

## 4. Default OS Configuration: The 3 Approaches

Open `/etc/default/grub` with root privileges:
```bash
sudo nano /etc/default/grub
```

Set common parameters:
```text
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
```

Now choose **one** of the three methods below for your default operating system behavior:

---

### Method A: Linux Mint as Default (Your Current Preference)
Every cold boot starts on Linux Mint; if you do nothing for 5 seconds, Linux Mint launches.

In `/etc/default/grub`, set:
```text
GRUB_DEFAULT=0
```
Save and apply:
```bash
sudo update-grub
```

---

### Method B: Windows 10 as Default
Every cold boot highlights Windows 10; if you do nothing for 5 seconds, Windows 10 launches automatically.

1. Query the exact name of the Windows boot entry registered by GRUB:
   ```bash
   grep -i -E "menuentry 'windows" /boot/grub/grub.cfg
   ```
   *(Usually outputs: `menuentry 'Windows Boot Manager (on /dev/sda2)' ...`)*

2. In `/etc/default/grub`, set `GRUB_DEFAULT` using the exact string copied between the single quotes:
   ```text
   GRUB_DEFAULT="Windows Boot Manager (on /dev/sda2)"
   ```
   *(Alternatively, if Windows is entry number 3 in your menu, you can use zero-indexed number: `GRUB_DEFAULT=2`)*

3. Save and apply:
   ```bash
   sudo update-grub
   ```

---

### Method C: Dynamic "Remember Last Selected OS" (Enterprise Best Practice)
The machine automatically boots whichever operating system you used last. 
- If you reboot from Windows 10, it boots Windows 10 automatically.
- If you reboot from Linux Mint, it boots Linux Mint automatically.
- You only need to touch the keyboard when you want to switch systems.

In `/etc/default/grub`, configure:
```text
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
```

Save the file (`Ctrl + O`, `Enter`), exit (`Ctrl + X`), and apply:
```bash
sudo update-grub
```

---

## 5. Instant 1-Line Switching Commands

You do not need to open text editors every time you want to switch the default. You can use these 1-line commands in Linux Mint terminal:

### Switch to Linux Mint Default (1-Line):
```bash
sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub && sudo update-grub
```

### Switch to Windows 10 Default (1-Line):
```bash
WIN_ENTRY=$(grep -i -E "menuentry 'windows" /boot/grub/grub.cfg | head -n1 | cut -d"'" -f2)
sudo sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=\"$WIN_ENTRY\"/" /etc/default/grub && sudo update-grub
```

### Switch to "Remember Last OS" (1-Line):
```bash
sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
grep -q "GRUB_SAVEDEFAULT=true" /etc/default/grub || echo "GRUB_SAVEDEFAULT=true" | sudo tee -a /etc/default/grub
sudo update-grub
```

---

## 6. Verification Checklist
- [ ] Run `sudo update-grub` and verify terminal shows both `Found Linux image` and `Found Windows Boot Manager on /dev/sda2`.
- [ ] Reboot (`sudo reboot`) without pressing `F12`.
- [ ] Confirm GRUB menu displays with a 5-second countdown timer.
- [ ] Confirm that when the timer expires, the configured default OS loads cleanly.
