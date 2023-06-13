#REQUIRES -Version 5.0

<#
.NOTES
    File Name      : Get-AzAdConnectAttributes.ps1
    Author         : Hasan Tan (github@hasantan.com)
    Prerequisite   : PowerShell V5 or PowerShell Core 7.x.x.
.LINK
    Link		 : https://github.com/iamhasantan/AzAdConnectAttributes

.SYNOPSIS
    The script provides a menu-driven PowerShell tool for managing and manipulating the ms-DS-ConsistencyGuid attribute 
    of Active Directory user accounts. It offers various operations, including checking specific user details, 
    retrieving details for all users, retrieving details for populated users, erasing ms-DS-ConsistencyGuids for all users, 
    and reimporting ms-DS-ConsistencyGuids from a backup.

    Use at your own risk.
#>

function Show-Menu {
    Write-Host "=== Menu ==="
    Write-Host "1. Get Specific User Details"
    Write-Host "2. Get All User Details"
    Write-Host "3. Get Populated User Details"
    Write-Host "4. Clear msDSConsistencyGuids"
    Write-Host "5. Import msDSConsistencyGuids"
    Write-Host "Q. Quit"
    Write-Host "=== Menu ==="
}

function Get-SpecificUserDetails {
    $Username = Read-Host "Enter the username to check"
    try {
        $User = Get-ADUser -Identity $Username -Properties ms-DS-ConsistencyGuid, ObjectGUID
        $UserGUIDHex = $User.ObjectGUID.ToString("N").Replace("-", "").ToUpper()
        if ($User."ms-DS-ConsistencyGuid") {
            $msDSGUIDHex = $User."ms-DS-ConsistencyGuid" | ForEach-Object { $_.ToString("X2") }
            Write-Host "ObjectGUID (HEX): $UserGUIDHex"
            Write-Host "ms-DS-ConsistencyGuid (HEX): $msDSGUIDHex"
        } else {
            Write-Host "ms-DS-ConsistencyGuid not found for user $($User.SamAccountName)"
        }
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Host "User not found"
    }
}

function Get-AllUserDetails {
    $Users = Get-ADUser -Filter * -Properties ms-DS-ConsistencyGuid, ObjectGUID
    $Result = foreach ($User in $Users) {
        $UserGUIDHex = $User.ObjectGUID.ToString("N").Replace("-", "").ToUpper()
        if ($User."ms-DS-ConsistencyGuid") {
            $msDSGUID = $User."ms-DS-ConsistencyGuid"
            if ($msDSGUID -is [System.Array]) {
                $msDSGUIDHex = ($msDSGUID | ForEach-Object { $_.ToString("X2") }) -Join ""
            } else {
                $msDSGUIDHex = $msDSGUID.ToString("X2")
            }
        } else {
            $msDSGUIDHex = ""
        }
        [pscustomobject]@{
            Username = $User.SamAccountName
            ObjectGUID = $UserGUIDHex
            msDSConsistencyGuid = $msDSGUIDHex
        }
    }

    $Directory = "C:\temp"
    if (-not (Test-Path $Directory)) {
        New-Item -ItemType Directory -Path $Directory | Out-Null
    }

    $Date = Get-Date -Format "yyyyMMddHHmmss"
    $Filename = Join-Path -Path $Directory -ChildPath "allusers_azadguids_$Date.csv"
    $Result | Export-Csv $Filename -NoTypeInformation
    Write-Host "CSV file exported to $Filename"
}
        
function Get-PopulatedUserDetails {
    $Users = Get-ADUser -Filter {ms-DS-ConsistencyGuid -ne '$null'} -Properties ms-DS-ConsistencyGuid, ObjectGUID

    if (!$Users) {
        Write-Host "No users with ms-DS-ConsistencyGuid property populated."
        return
    }

    $Result = foreach ($User in $Users) {
        $UserGUIDHex = $User.ObjectGUID.ToString("N").Replace("-", "").ToUpper()
        $msDSGUID = $User."ms-DS-ConsistencyGuid"

        if ($msDSGUID -is [System.Array]) {
            $msDSGUIDHex = ($msDSGUID | ForEach-Object { $_.ToString("X2") }) -Join ""
        } else {
            $msDSGUIDHex = $msDSGUID.ToString("X2")
        }

        [pscustomobject]@{
            Username = $User.SamAccountName
            ObjectGUID = $UserGUIDHex
            msDSConsistencyGuid = $msDSGUIDHex
        }
    }

    $Result | Format-Table -AutoSize

    $Directory = "C:\temp"
    if (-not (Test-Path $Directory)) {
        New-Item -ItemType Directory -Path $Directory | Out-Null
    }

    $Date = Get-Date -Format "yyyyMMddHHmmss"
    $Filename = Join-Path -Path $Directory -ChildPath "populatedonly_azadguids$Date.csv"
    $Result | Export-Csv $Filename -NoTypeInformation
    Write-Host "CSV file exported to $Filename"
    
}

function Clear-msDSConsistencyGuids {
    Write-Host "WARNING: This action will erase ms-ds-consistencyGUIDs for all users in the forest."
    Write-Host "Before proceeding, the script will generate a backup CSV file."
    $Confirmation = Read-Host "Do you want to proceed? (Y/N)"
    if ($Confirmation -eq 'Y' -or $Confirmation -eq 'y') {
        Get-AllUserDetails
        $BackupConfirmation = Read-Host "Are you sure you want to proceed with erasing ms-ds-consistencyGUIDs? (Y/N)"
        if ($BackupConfirmation -eq 'Y' -or $BackupConfirmation -eq 'y') {
            $Users = Get-ADUser -Filter * -Properties ms-DS-ConsistencyGUID
            foreach ($User in $Users) {
                $User | Set-ADUser -Clear ms-DS-ConsistencyGUID
            }
            Write-Host "ms-ds-consistencyGUIDs erased for all users."
        } else {
            Write-Host "Operation cancelled. ms-ds-consistencyGUIDs were not erased."
        }
    } else {
        Write-Host "Operation cancelled. ms-ds-consistencyGUIDs were not erased."
    }
}


function Import-msDSConsistencyGuids {
    $CSVFilePath = Read-Host "Enter the path to the CSV file:"
    $BackupUsers = Import-Csv -Path $CSVFilePath
    
    $Confirmation = Read-Host "Any existing values will be overwritten. Are you sure you want to proceed? (Y/N)"
    
    if ($Confirmation -eq "Y" -or $Confirmation -eq "y") {
        $Errors = 0
        
        foreach ($User in $BackupUsers) {
            $msDSConsistencyGuid = $User.msDSConsistencyGUID -replace "\s"
            
            if (-not [string]::IsNullOrWhiteSpace($msDSConsistencyGuid)) {
                $ADUser = Get-ADUser -Filter "SamAccountName -eq '$($User.Username)'" -Properties ms-DS-ConsistencyGUID

                if ($ADUser) {
                    $existingValue = $ADUser.'ms-DS-ConsistencyGUID'
                    if ($existingValue -eq $msDSConsistencyGuid) {
                        Write-Host "Skipped import for user $($User.Username) due to ms-DS-ConsistencyGuid value from CSV matching existing ms-DS-ConsistencyGuid value."
                        continue
                    }

                    try {
                        $ByteArray = [byte[]]::new($msDSConsistencyGuid.Length / 2)
                        for ($i = 0; $i -lt $msDSConsistencyGuid.Length; $i += 2) {
                            $ByteArray[$i/2] = [convert]::ToByte($msDSConsistencyGuid.Substring($i, 2), 16)
                        }
                        
                        Set-ADUser -Identity $ADUser -Replace @{'ms-DS-ConsistencyGuid' = $ByteArray}
                        Write-Host "Updated ms-DS-ConsistencyGuid for user $($User.Username)."
                        
                    } catch {
                        Write-Host "Failed to update ms-DS-ConsistencyGuid for user $($User.Username). Error: $_"
                        $Errors++
                    }
                } else {
                    Write-Host "User $($User.Username) not found in AD."
                    $Errors++
                }
            } else {
                $ADUser = Get-ADUser -Filter "SamAccountName -eq '$($User.Username)'" -Properties ms-DS-ConsistencyGUID

                if ($ADUser) {
                    $existingValue = $ADUser.'ms-DS-ConsistencyGUID'
                    if (-not [string]::IsNullOrWhiteSpace($existingValue)) {
                        $choice = Read-Host "Do you want to clear ms-DS-ConsistencyGuid value for user $($User.Username)? (Y/N)"
                        if ($choice -eq 'N' -or $choice -eq 'n') {
                            Write-Host "Skipped import for user $($User.Username) due to existing ms-DS-ConsistencyGuid value."
                            continue
                        }
                    }

                    try {
                        if (-not [string]::IsNullOrWhiteSpace($existingValue)) {
                            Set-ADUser -Identity $ADUser -Clear 'ms-DS-ConsistencyGuid'
                            Write-Host "Cleared ms-DS-ConsistencyGuid for user $($User.Username)."
                        } else {
                            Write-Host "Skipped import for user $($User.Username) due to empty ms-DS-ConsistencyGuid value."
                        }
                    } catch {
                        Write-Host "Failed to clear ms-DS-ConsistencyGuid for user $($User.Username). Error: $_"
                        $Errors++
                    }
                } else {
                    Write-Host "User $($User.Username) not found in AD."
                    $Errors++
}
}
}
Write-Host "Import process completed with $Errors error(s)."
} else {
    Write-Host "Operation cancelled."
}
}     

while ($true) {
    Show-Menu
    $Choice = Read-Host "Enter your choice"

    switch ($Choice) {
        '1' { Get-SpecificUserDetails }
        '2' { Get-AllUserDetails }
        '3' { Get-PopulatedUserDetails }
        '4' { Clear-msDSConsistencyGuids }
        '5' { Import-msDSConsistencyGuids }
        'Q' { break }
        default { Write-Host "Invalid choice" }
    }

    if ($Choice -eq 'Q') {
        break
    }
}
