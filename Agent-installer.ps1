#Requires -RunAsAdministrator

if([Environment]::Is64BitOperatingSystem -eq "True") {
    Write-Host "[+] Detected 64-bit operating system"
    $winlogbeat = "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-7.6.0-windows-x86_64.zip"
    $sysmon = "https://download.sysinternals.com/files/Sysmon.zip"
    $velociraptor = ""

} else {
    Write-Host "[+] Detected 32-bit operating system"
    $winlogbeat = "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-7.6.0-windows-x86.zip"
    $sysmon = "https://download.sysinternals.com/files/Sysmon.zip"
    $velociraptor = "" 
}

function clearfiles () {
    Write-Host "Clearing files.."
    Remove-Item -path C:\Temp\* -Filter *.zip
}

function winlogbeat{
    # Delete and stop the service if it already exists.
    if (Get-Service winlogbeat -ErrorAction SilentlyContinue) {
    $service = Get-WmiObject -Class Win32_Service -Filter "name='winlogbeat'"
    $service.StopService()
    Start-Sleep -s 1
    $service.delete()
    }

    $workdir = Get-Location

    Write-Host "[+] Running winlogbeat"
    # Create the new service.
    New-Service -name winlogbeat `
    -displayName Winlogbeat `
    -binaryPathName "`"$workdir\winlogbeat.exe`" -c `"$workdir\winlogbeat.yml`" -path.home `"$workdir`" -path.data `"C:\ProgramData\winlogbeat`" -path.logs `"C:\ProgramData\winlogbeat\logs`" -E logging.files.redirect_stderr=true"

    # Attempt to set the service to delayed start using sc config.
    Try {
    Start-Process -FilePath sc.exe -ArgumentList 'config winlogbeat start= delayed-auto'
    }
    Catch { Write-Host -f red "An error occured setting the service to delayed start." }
}

function velociraptor {

#No code yet

}

function sysmon {
    Write-Host "[+] Running sysmon"
    Start-Process Sysmon64.exe
}

function installer ($winlogfolder, $sysmonfolder) {
    $location = $winlogfolder + "\winlogbeat-7.6.0-windows-x86_64"
    cd $location
    Write-Host "[+] Initialising services"
    winlogbeat
    $location2 = $sysmonfolder
    cd $location2
    sysmon
    velociraptor
    
}

function zipextractor ([string]$winloglocation, [string]$sysmonlocation) {
    $num = get-random -maximum 1000
    $winlogfolder = "C:\Temp\file" + $num
    Expand-Archive -LiteralPath $winloglocation -DestinationPath $winlogfolder 
    if ($?) {
        Write-Host "[+] Extracted successfully"
    } else {
        Write-Host "FAILED: file to extract zip file"
    }
    $num = get-random -maximum 1000
    $sysmonfolder = "C:\Temp\file" + $num
    Expand-Archive -LiteralPath $sysmonlocation -DestinationPath $sysmonfolder 
    if ($?) {
        Write-Host "[+] Extracted successfully"
    } else {
        Write-Host "FAILED: file to extract zip file"
    }
    installer $winlogfolder $sysmonfolder
}

function Downloader ([string]$winlogbeat, [string]$sysmon) {
    $num = get-random -maximum 1000
    $filename = "file" + $num + ".zip"
    $Winloglocation = "C:\Temp\" + $filename
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($winlogbeat, $winloglocation)
    if ($?) {
        Write-Host "[+] Winlogbeat download successfully"
    } else {
        Write-Host "FAILED: file to download winlogbeat"
        exit
    }
    $num = get-random -maximum 1000
    $filename = "file" + $num + ".zip"
    $sysmonlocation = "C:\Temp\" + $filename
    $wc.DownloadFile($sysmon, $sysmonlocation)
    if ($?) {
        Write-Host "[+] sysmon download successfully"
    } else {
        Write-Host "FAILED: file to download sysmon"
        exit
    }
    zipextractor $winloglocation $sysmonlocation
}

Downloader $winlogbeat $sysmon
clearfiles


