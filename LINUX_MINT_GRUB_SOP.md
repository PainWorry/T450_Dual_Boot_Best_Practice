# Standard Operating Procedure (SOP): GRUB Dual-Boot Setup & Default OS Switching

## 1. Objective
Establish and maintain a resilient GRUB2 dual-boot bootloader on the primary drive (`/dev/sda`). Provides complete, step-by-step procedures to toggle default boot targets between **Linux Mint** and **Windows 10**, configure countdown timers, or enable the dynamic **"Remember Last Booted OS"** mode.

---

## 2. Accessing This Repository & Documentation

### Option A: Direct Clone in Linux Mint (Recommended - Zero Windows Dependency)
In Linux Mint Terminal (`Ctrl + Alt + T`), clone this repository directly:
```bash
git clone https://github.com/PainWorry/T450_Dual_Boot_Best_Practice.git
cd T450_Dual_Boot_Best_Practice
```
All SOPs and scripts are now available locally in your Linux home directory.

### Option B: Accessing From Mounted Windows NTFS Drive
If the repository was already cloned/downloaded to Windows:
1. Open the file manager (**Nemo**).
2. Look at the left sidebar under **Devices** for your Windows partition (e.g. `Windows` or `Volume`).
3. Click to mount it.
4. Navigate to your cloned or downloaded folder:
   ```text
   /media/<username>/<UUID>/Users/<your-windows-username>/.../T450_Dual_Boot_Best_Practice/
   ```

---

## 3. Diagnostic: Do You Already See the GRUB Black Screen on Boot?

If you already see the GNU GRUB menu (black screen with white text) on startup without pressing `F12`:

### Test 1: Does it have an automatic countdown timer?
- Look at the bottom of the screen.
- **If it shows a countdown** (e.g. *"The highlighted entry will be executed automatically in X seconds"*), and boots into your default OS automatically:
  👉 **Your bootloader is already fully operational.** You do not need to reinstall GRUB.
- **If it stays on that screen indefinitely** until you manually press Enter:
  👉 Run the 1-line timer update in Section 5 below to add a 5-second countdown.

### Test 2: Does it list Windows 10?
- Use the **Down Arrow** to highlight **Windows Boot Manager (on /dev/sda2)** and press **Enter**.
- **If Windows 10 boots up normally**:
  👉 **You never need to press F12 again.** You can use this menu to boot Windows or Linux anytime.
- **If Windows 10 is missing from the menu**:
  👉 Run `echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a /etc/default/grub && sudo update-grub`.

---

## 4. Initial Bootloader Installation (Run Once if GRUB Does Not Appear)

If your machine bypasses GRUB entirely on cold boot and boots straight into Windows or requires `F12`:

1. Open Terminal (`Ctrl + Alt + T`).
2. Install GRUB to the drive's Master Boot Record (use the whole disk device `/dev/sda`, not a partition like `sda4`):
   ```bash
   sudo grub-install /dev/sda
   ```
3. Ensure `os-prober` is enabled to detect Windows 10:
   ```bash
   echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a /etc/default/grub
   ```

---

## 5. Setting Default OS: 3 Best-Practice Methods

All boot behavior is defined in `/etc/default/grub`:

### Method A: Linux Mint as Default (Fixed)
Every cold boot highlights Linux Mint. After 5 seconds, Linux Mint launches automatically:
```bash
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub
sudo update-grub
```

---

### Method B: Windows 10 as Default (Fixed)
Every cold boot highlights Windows 10. After 5 seconds, Windows 10 launches automatically:
```bash
WIN_ENTRY=$(grep -i -E "menuentry 'windows" /boot/grub/grub.cfg | head -n1 | cut -d"'" -f2)
sudo sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=\"$WIN_ENTRY\"/" /etc/default/grub
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
sudo update-grub
```

---

### Method C: Dynamic "Remember Last Selected OS" (Enterprise Best Practice)
The machine automatically boots whichever operating system was used last:
- Rebooting from Windows 10 reboots into Windows 10 automatically.
- Rebooting from Linux Mint reboots into Linux Mint automatically.
- You only need to touch the keyboard when you want to switch systems.
```bash
sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
grep -q "GRUB_SAVEDEFAULT=true" /etc/default/grub || echo "GRUB_SAVEDEFAULT=true" | sudo tee -a /etc/default/grub
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
sudo update-grub
```

---

## 6. Verification Checklist
- [ ] Run `sudo update-grub` and confirm output includes `Found Windows Boot Manager on /dev/sda2`.
- [ ] Reboot (`sudo reboot`) without pressing `F12`.
- [ ] Verify the GRUB menu appears with a 5-second countdown.
- [ ] Verify that the configured default OS loads automatically when the timer reaches 0.
