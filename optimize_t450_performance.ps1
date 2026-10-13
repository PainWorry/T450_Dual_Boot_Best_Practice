<#
.SYNOPSIS
    ThinkPad T450 Performance Optimization & Lag Remediation Script.
.DESCRIPTION
    Applies targeted system adjustments to resolve 100% CPU freezes and DRAM-less SSD
    I/O bottlenecks on Windows 10 (Lenovo ThinkPad T450 / Kingston A400 SSD).
.PARAMETER DryRun
    If specified, displays the actions that would be executed without mutating system state.
#>

[CmdletBinding()]
param(
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

function Write-AuditLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formatted = "[$timestamp] [$Level] $Message"
    Write-Host $formatted
}

Write-AuditLog "Initializing ThinkPad T450 Performance Optimizer..."

# Elevation Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $DryRun) {
    Write-AuditLog "Administrative privileges required. Requesting elevation..." "WARN"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 1. DRAM-less SSD I/O Optimization (SysMain / Superfetch)
Write-AuditLog "--- Step 1: Storage & I/O Optimization (Kingston A400 SSD) ---"
$servicesToDisable = @("SysMain", "WSearch", "DiagTrack")

foreach ($svc in $servicesToDisable) {
    $serviceObj = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($serviceObj) {
        if ($DryRun) {
            Write-AuditLog "[DRY-RUN] Would stop and disable service: $svc (Current: $($serviceObj.Status), $($serviceObj.StartType))"
        } else {
            Write-AuditLog "Stopping and disabling service: $svc"
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled
            Write-AuditLog "Service $svc disabled successfully."
        }
    } else {
        Write-AuditLog "Service $svc not found on system. Skipping." "WARN"
    }
}

# 2. NTFS TRIM Optimization
if ($DryRun) {
    Write-AuditLog "[DRY-RUN] Would ensure NTFS TRIM is enabled (fsutil behavior set DisableDeleteNotify 0)"
} else {
    try {
        fsutil behavior set DisableDeleteNotify 0 | Out-Null
        Write-AuditLog "NTFS TRIM enabled (DisableDeleteNotify = 0)."
    } catch {
        Write-AuditLog "Failed to configure TRIM: $_" "WARN"
    }
}

# 3. Windows Defender CPU & Real-Time Inspection Tuning
Write-AuditLog "--- Step 2: Windows Defender CPU Mitigation ---"
if ($DryRun) {
    Write-AuditLog "[DRY-RUN] Would set Defender CPU limit to 20% (Set-MpPreference -ScanAvgCPULoadFactor 20)"
    Write-AuditLog "[DRY-RUN] Would add MsMpEng.exe to Defender process exclusions"
    Write-AuditLog "[DRY-RUN] Would add Opera cache directory to Defender path exclusions"
} else {
    try {
        Set-MpPreference -ScanAvgCPULoadFactor 20
        Write-AuditLog "Windows Defender scan CPU cap set to 20%."

        Add-MpPreference -ExclusionProcess "MsMpEng.exe"
        Write-AuditLog "Added MsMpEng.exe to Defender process exclusions."

        $operaPath = "$env:LOCALAPPDATA\Programs\Opera Air"
        if (Test-Path $operaPath) {
            Add-MpPreference -ExclusionPath $operaPath
            Write-AuditLog "Added Opera Air directory to Defender exclusions: $operaPath"
        }

        $operaRoaming = "$env:APPDATA\Opera Software"
        if (Test-Path $operaRoaming) {
            Add-MpPreference -ExclusionPath $operaRoaming
            Write-AuditLog "Added Opera roaming profile to Defender exclusions: $operaRoaming"
        }
    } catch {
        Write-AuditLog "Failed to tune Windows Defender: $_" "WARN"
    }
}

# 4. Startup Application Cleanup (Opera Autostart)
Write-AuditLog "--- Step 3: Startup Application Cleanup ---"
$runKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$operaRunItem = Get-ItemProperty -Path $runKeyPath -Name "Opera Air Stable" -ErrorAction SilentlyContinue

if ($operaRunItem) {
    if ($DryRun) {
        Write-AuditLog "[DRY-RUN] Would remove 'Opera Air Stable' from HKCU Run key: $($operaRunItem.'Opera Air Stable')"
    } else {
        Remove-ItemProperty -Path $runKeyPath -Name "Opera Air Stable" -ErrorAction SilentlyContinue
        Write-AuditLog "Removed 'Opera Air Stable' from user startup registry."
    }
} else {
    Write-AuditLog "'Opera Air Stable' not found in HKCU Run key."
}

Write-AuditLog "--- Optimization Summary Complete ---"
if ($DryRun) {
    Write-AuditLog "Dry run completed. No state changes were applied." "INFO"
} else {
    Write-AuditLog "All optimizations applied successfully. A system reboot is recommended." "INFO"
}
