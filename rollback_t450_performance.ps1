<#
.SYNOPSIS
    ThinkPad T450 Performance Rollback Script.
.DESCRIPTION
    Reverts all modifications made by optimize_t450_performance.ps1 to default Windows 10 settings.
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

Write-AuditLog "Initializing ThinkPad T450 Performance Rollback..."

# Elevation Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $DryRun) {
    Write-AuditLog "Administrative privileges required. Requesting elevation..." "WARN"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 1. Restore Windows Services
Write-AuditLog "--- Step 1: Reverting Windows Services ---"
$servicesToRestore = @(
    @{ Name = "SysMain"; Startup = "Automatic" },
    @{ Name = "WSearch"; Startup = "Automatic" },
    @{ Name = "DiagTrack"; Startup = "Automatic" }
)

foreach ($svc in $servicesToRestore) {
    $serviceObj = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($serviceObj) {
        if ($DryRun) {
            Write-AuditLog "[DRY-RUN] Would re-enable and start service: $($svc.Name)"
        } else {
            Write-AuditLog "Re-enabling and starting service: $($svc.Name)"
            Set-Service -Name $svc.Name -StartupType $svc.Startup
            Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
            Write-AuditLog "Service $($svc.Name) restored to $($svc.Startup)."
        }
    }
}

# 2. Restore Windows Defender Preferences
Write-AuditLog "--- Step 2: Reverting Windows Defender Settings ---"
if ($DryRun) {
    Write-AuditLog "[DRY-RUN] Would reset Defender CPU limit to default 50%"
    Write-AuditLog "[DRY-RUN] Would remove Defender exclusions for MsMpEng.exe and Opera"
} else {
    try {
        Set-MpPreference -ScanAvgCPUMultithreaded 50
        Write-AuditLog "Reset Defender scan CPU cap to 50% (default)."

        Remove-MpPreference -ExclusionProcess "MsMpEng.exe" -ErrorAction SilentlyContinue
        Write-AuditLog "Removed MsMpEng.exe from Defender exclusions."

        $operaPath = "$env:LOCALAPPDATA\Programs\Opera Air"
        Remove-MpPreference -ExclusionPath $operaPath -ErrorAction SilentlyContinue

        $operaRoaming = "$env:APPDATA\Opera Software"
        Remove-MpPreference -ExclusionPath $operaRoaming -ErrorAction SilentlyContinue
        Write-AuditLog "Removed Opera directories from Defender exclusions."
    } catch {
        Write-AuditLog "Failed to revert Windows Defender preferences: $_" "WARN"
    }
}

Write-AuditLog "--- Rollback Complete ---"
