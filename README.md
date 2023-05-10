# AzAdConnectAttributes

SYNOPSIS
    This script is being built out to help navigate tenant mergers and demergers by identifying
    objectGUID & ms-ds-consistencyGUID attributes for your domain users and outputting the data 
    as required. Later iterations will include the ability to wipe ms-ds-consistencyGUID, set it etc.
    
DESCRIPTION

    This script currently checks objectGUID & ms-ds-consistencyGUID attributes for:
	    - Specific User
	    - All Users in a domain (including those who do not have the attributes set).
	    - All users with the attributes populated.
    
NOTES

    File Name      : Get-AzAdConnectAttributes.ps1
    Author         : Hasan Tan (github@hasantan.com)
    Prerequisite   : PowerShell V5 or PowerShell Core 7.x.x.

LINK

    Link		 : https://github.com/iamhasantan/AzAdConnectAttributes
