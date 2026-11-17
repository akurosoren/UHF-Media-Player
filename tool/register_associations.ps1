# Registers UHF Media as a media player for the current user (HKCU)
# Enables "Ouvrir avec" (Open With) and Default Application support in Windows 10 & 11.
# No administrator privileges required.

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

# Look for uhf_media.exe or portable launcher
$candidates = @(
    "D:\Apps\UHF-Media-1.0.0-win64\uhf_media.exe",
    "$projectRoot\build\windows\x64\runner\Release\uhf_media.exe",
    "$projectRoot\build\release\UHF-Media-1.0.0-portable.exe"
)

$targetExe = $null
foreach ($c in $candidates) {
    if (Test-Path $c) {
        $targetExe = (Resolve-Path $c).Path
        break
    }
}

if (-not $targetExe) {
    Write-Host "uhf_media.exe introuvable dans les emplacements standard." -ForegroundColor Yellow
    $prompt = Read-Host "Entrez le chemin complet vers uhf_media.exe"
    if (Test-Path $prompt) {
        $targetExe = (Resolve-Path $prompt).Path
    } else {
        Write-Error "Chemin invalide : $prompt"
        exit 1
    }
}

Write-Host "Enregistrement de UHF Media : $targetExe" -ForegroundColor Cyan

$appName = "UHF Media"
$progId = "UHFMedia.Video"
$openCommand = "`"$targetExe`" `"%1`""
$iconEntry = "`"$targetExe`",0"
$exeName = [System.IO.Path]::GetFileName($targetExe)

$extensions = @("mp4", "mkv", "mov", "avi", "m4v", "webm", "ts", "mts", "m2ts", "wmv", "flv", "mp3", "flac", "m4a", "wav", "ogg", "opus")

function Set-RegistryValue([string]$keyPath, [string]$valName, [string]$valData) {
    if (-not (Test-Path "Registry::$keyPath")) {
        New-Item -Path "Registry::$keyPath" -Force | Out-Null
    }
    if ([string]::IsNullOrEmpty($valName)) {
        Set-ItemProperty -Path "Registry::$keyPath" -Name '(default)' -Value $valData -Force | Out-Null
    } else {
        Set-ItemProperty -Path "Registry::$keyPath" -Name $valName -Value $valData -Force | Out-Null
    }
}

# 1. Applications\<exe>
Set-RegistryValue "HKEY_CURRENT_USER\Software\Classes\Applications\$exeName" "FriendlyAppName" "$appName"
Set-RegistryValue "HKEY_CURRENT_USER\Software\Classes\Applications\$exeName\shell\open\command" "" "$openCommand"

$suppKey = "HKEY_CURRENT_USER\Software\Classes\Applications\$exeName\SupportedTypes"
foreach ($ext in $extensions) {
    Set-RegistryValue "$suppKey" ".$ext" ""
}

# 2. ProgID: UHFMedia.Video
Set-RegistryValue "HKEY_CURRENT_USER\Software\Classes\$progId" "" "Fichier multimédia UHF Media"
Set-RegistryValue "HKEY_CURRENT_USER\Software\Classes\$progId" "FriendlyTypeName" "Fichier multimédia UHF Media"
Set-RegistryValue "HKEY_CURRENT_USER\Software\Classes\$progId\DefaultIcon" "" "$iconEntry"
Set-RegistryValue "HKEY_CURRENT_USER\Software\Classes\$progId\shell\open\command" "" "$openCommand"

# 3. OpenWithProgids
foreach ($ext in $extensions) {
    Set-RegistryValue "HKEY_CURRENT_USER\Software\Classes\.$ext\OpenWithProgids" "$progId" ""
    Set-RegistryValue "HKEY_CURRENT_USER\Software\Classes\.$ext\OpenWithProgids" "Applications\$exeName" ""
}

# 4. RegisteredApplications
$capSubKey = "Software\Clients\Media\UHFMedia\Capabilities"
Set-RegistryValue "HKEY_CURRENT_USER\Software\RegisteredApplications" "$appName" "$capSubKey"

# 5. Capabilities
$capFullKey = "HKEY_CURRENT_USER\$capSubKey"
Set-RegistryValue "$capFullKey" "ApplicationName" "$appName"
Set-RegistryValue "$capFullKey" "ApplicationDescription" "Lecteur multimédia et studio d'édition UHF Media"
foreach ($ext in $extensions) {
    Set-RegistryValue "$capFullKey\FileAssociations" ".$ext" "$progId"
}

# 6. Notify Windows Shell
try {
    $code = '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);'
    $type = Add-Type -MemberDefinition $code -Name "Shell32Notify" -Namespace "Win32" -PassThru -ErrorAction SilentlyContinue
    if ($type) {
        $type::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
    }
} catch {}

Write-Host "Enregistrement terminé avec succès !" -ForegroundColor Green
Write-Host "UHF Media est maintenant disponible dans 'Ouvrir avec' et les 'Applications par défaut' de Windows." -ForegroundColor Green
