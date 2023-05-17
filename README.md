# AzAdConnectAttributes

SYNOPSIS

    The script provides a menu-driven PowerShell tool for managing and manipulating the ms-DS-ConsistencyGuid attribute 
    of Active Directory user accounts. It offers various operations, including checking specific user details, 
    retrieving details for all users, retrieving details for populated users, erasing ms-DS-ConsistencyGuids for all users, 
    and reimporting ms-DS-ConsistencyGuids from a backup.

    Use at your own risk.
    
DESCRIPTION

    The script serves as a menu-based PowerShell tool designed to manage the ms-DS-ConsistencyGuid attribute of 
    Active Directory user accounts.  The ms-DS-ConsistencyGuid attribute is a unique identifier used for 
    replication purposes in Active Directory.

    Check-SpecificUser:
    This option allows users to retrieve and display the ms-DS-ConsistencyGuid and ObjectGUID details of a specific user account. 
    Users are prompted to enter the username, and the script retrieves the associated user information from Active Directory, 
    displaying the relevant GUIDs if available.

    Check-AllUsers:
    This option retrieves and exports the ms-DS-ConsistencyGuid and ObjectGUID details for all user accounts in the Active Directory. 
    The script fetches the necessary information and generates a CSV file containing the user details, including the respective GUIDs, 
    which is then saved in a specified directory.

    Check-PopulatedUsers:
    This option retrieves and exports the ms-DS-ConsistencyGuid and ObjectGUID details for user accounts with populated ms-DS-ConsistencyGuid attributes. 
    The script filters out user accounts that do not have a populated ms-DS-ConsistencyGuid attribute and exports the user details, 
    including the respective GUIDs, into a CSV file.

    Erase-msDSConsistencyGuids:
    This option erases the ms-DS-ConsistencyGuids for all user accounts in the Active Directory. 
    Before proceeding, the script generates a backup CSV file containing the user details and their original ms-DS-ConsistencyGuids. 
    Users are prompted for confirmation before the erasure process begins. After completion, the ms-DS-ConsistencyGuids are removed, 
    and a backup CSV file is created.

    Import-msDSConsistencyGuids:
    This option allows users to reimport ms-DS-ConsistencyGuids from a backup CSV file. Users are prompted to provide the path to the 
    backup file containing the user details and their original ms-DS-ConsistencyGuids. The script then verifies the existence of the backup file, 
    prompts for confirmation, and proceeds with overwriting the existing ms-DS-ConsistencyGuids for the corresponding user accounts. 
    After the reimport process, a summary of any encountered errors is displayed.

    The script provides a user-friendly menu interface, allowing users to navigate through the available options and perform desired operations related 
    to the management and manipulation of the ms-DS-ConsistencyGuid attribute in Active Directory.
    
NOTES

    File Name      : Get-AzAdConnectAttributes.ps1
    Author         : Hasan Tan (github@hasantan.com)
    Prerequisite   : PowerShell V5 or PowerShell Core 7.x.x.

LINK

    Link		 : https://github.com/iamhasantan/AzAdConnectAttributes
