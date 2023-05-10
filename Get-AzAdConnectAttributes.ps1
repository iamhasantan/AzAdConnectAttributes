#REQUIRES -Version 5.0

<#
.SYNOPSIS
    This script is being built out to help navigate tenant mergers and demergers by identifying
    objectGUID & ms-ds-consistencyGUID attributes for your domain users and outputting the data 
    as required. Later iterations will include the ability to wipe ms-ds-consistencyGUID, set it etc.
.DESCRIPTION
    This script currently provides the following functionality
    Check objectGUID & ms-ds-consistencyGUID attributes for:
	- Specific User
	- All Users in a domain (including those who do not have the attributes set).
	- All users with the attributes populated.
    
.NOTES
    File Name      : Get-AzAdConnectAttributes.ps1
    Author         : Hasan Tan (github@hasantan.com)
    Prerequisite   : PowerShell V5 or PowerShell Core 7.x.x.
.LINK
    Link		 : https://github.com/iamhasantan/AzAdConnectAttributes
#>


function Show-Menu {
    Write-Host "1: Check a specific user"
    Write-Host "2: Check all users and export to CSV"
    Write-Host "3: Check all users with both ObjectGUID and ms-DS-ConsistencyGUID populated"
    Write-Host "4: Exit"
}

function Check-SpecificUser {
    $Username = Read-Host "Enter the username to check"
    try {
        $User = Get-ADUser -Identity $Username -Properties ms-DS-ConsistencyGUID,ObjectGUID
        $UserGUIDHex = $User.ObjectGUID.ToString("N").Replace("-", "").ToUpper()
        if ($User."ms-DS-ConsistencyGUID") {
            $msDSGUIDHex = $User."ms-DS-ConsistencyGUID" | %{ $_.ToString("X2") }
            Write-Host "ObjectGUID (HEX): $UserGUIDHex"
            Write-Host "ms-DS-ConsistencyGUID (HEX): $msDSGUIDHex"
        } else {
            Write-Host "ms-DS-ConsistencyGUID not found for user $($User.SamAccountName)"
        }
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Host "User not found"
    }
}


function Check-AllUsers {
    $Users = Get-ADUser -Filter * -Properties ms-DS-ConsistencyGUID,ObjectGUID
    $Result = foreach ($User in $Users) {
        $UserGUIDHex = $User.ObjectGUID.ToString("N").Replace("-", "").ToUpper()
        if ($User."ms-DS-ConsistencyGUID") {
            $msDSGUID = $User."ms-DS-ConsistencyGUID"
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
            msDSConsistencyGUID = $msDSGUIDHex
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


function Check-PopulatedUsers {
    $Users = Get-ADUser -Filter {ms-DS-ConsistencyGUID -ne '$null'} -Properties ms-DS-ConsistencyGUID,ObjectGUID
    if (!$Users) {
        Write-Host "No users with ms-DS-ConsistencyGUID property populated."
        return
    }
    $Result = foreach ($User in $Users) {
        $UserGUIDHex = $User.ObjectGUID.ToString("N").Replace("-", "").ToUpper()
        $msDSGUID = $User."ms-DS-ConsistencyGUID"
        if ($msDSGUID -is [System.Array]) {
            $msDSGUIDHex = ($msDSGUID | ForEach-Object { $_.ToString("X2") }) -Join ""
        } else {
            $msDSGUIDHex = $msDSGUID.ToString("X2")
        }
        [pscustomobject]@{
            Username = $User.SamAccountName
            ObjectGUID = $UserGUIDHex
            msDSConsistencyGUID = $msDSGUIDHex
        }
    }
    $Directory = "C:\temp"
    if (-not (Test-Path $Directory)) {
        New-Item -ItemType Directory -Path $Directory | Out-Null
    }
    $Date = Get-Date -Format "yyyyMMddHHmmss"
    $Filename = Join-Path -Path $Directory -ChildPath "populatedonly_azadguids_$Date.csv"
    $Result | Export-Csv $Filename -NoTypeInformation
    Write-Host "CSV file exported to $Filename"
    $Result
}

while ($true) {
    Show-Menu
    $Choice = Read-Host "Enter your choice"
    switch ($Choice) {
        '1' { Check-SpecificUser }
        '2' { Check-AllUsers }
        '3' { Check-PopulatedUsers }
        '4' { break }
        default { Write-Host "Invalid choice" }
    }
    if ($Choice -eq '4') {
        Write-Host "You are the weakest link"
        Write-Host "Goodbye."
        break
    }
    $Confirmation = Read-Host "Press Enter to return to the main menu"
}

