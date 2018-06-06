##
# Add Active Directory Group to Local Administrators.
# 
# This script will search for all the computers that are domain joined with a specific naming abbreviation, resolve the DNS names and add a specified Domain Group to the local
# administrator group of the object.
# 
# @author       Stijn Vandezande <svandezande@thinfactory.com>
##

##
# Prerequisites: 
#       - Active Directory Powershell Module Installed
#       - PSLogging Module Installed
#       - PowerShell Execution Policy Enabled
##

##
#                                                   Script Parameters
##

Param (
    [String]$Member,
    [String]$Domain = $env:userdomain,
    [String]$OrgAbbreviation
)

##
#                                                   Initialisations.
##

Import-Module PSLogging

##
#                                                   Declarations.
##

#Script Version
$sScriptVersion = '1.0'

#Log File Info
$sLogPath = 'C:\Windows\Temp'
$sLogName = 'Add_Member_To_Local_Server_Admin_Multiple_Servers.log'
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

##
#                                                   Start log.
##

Start-Log -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion

##
#                                                   Function to grab the server from Active Directory which you wish to manipulate whilst logging.
##

function Get-AllOrganizationalServers {
    Begin {
        Write-LogInfo -LogPath $sLogFile -Message '#### Retrieving Server-List according to the provided Organizational Abbreviation... ####'
        Write-LogInfo -LogPath $sLogFile -Message ' '
    }
    Process {
        Try {
            Get-ADComputer -Filter * | Where-Object {$_.Name -like "$OrgAbbreviation*"} | Select-Object -ExpandProperty Name
        }
        Catch {
            Write-LogError -LogPath $sLogFile -Message $_.Exception -ExitGracefully
            Break
        }
    }
    End {
        If ($?) {
            $GetADComputer = Get-ADComputer -Filter * | Where-Object {$_.Name -like "$OrgAbbreviation*"} | Select-Object -ExpandProperty Name
            Write-LogInfo -LogPath $sLogFile -Message "#### Found the following computers: $GetADComputer ####"
            Write-LogInfo -LogPath $sLogFile -Message ' '
            Write-LogInfo -LogPath $sLogFile -Message '#### Retrievement of the Server-List Completed Successfully. ####'
            Write-LogInfo -LogPath $sLogFile -Message ' '
        }
    }
}

##
# Resolve the hostname and add the specified group to the local administrators group.
##

foreach ($Server in Get-AllOrganizationalServers) {
# Check PS version and bail.
    if (Invoke-Command -ComputerName $Server -ScriptBlock {$PSVersionTable.PSVersion.Major -lt 2}) {
        Write-Host "IMPORTANT: Powershell version of <<$Server>> is too low, upgrade it and retry!" -ForegroundColor Red
        Write-LogInfo -LogPath $sLogFile -Message "IMPORTANT: Powershell version of <<$Server>> is too low, upgrade it and retry!"
        Throw
    }
# Else verify whether the group is already member of Local Administrators Group.
    $ServerIP = [System.Net.Dns]::GetHostByName($Server)
    $Groupmember = $([ADSI]"WinNT://$($ServerIP.AddressList[0].IPAddressToString)/Administrators,group").psbase.Invoke('Members') | ForEach-Object { $_.GetType().InvokeMember('ADspath', 'GetProperty', $null, $_, $null).Replace('WinNT://', '') } | Where-Object {$_ -like "*$Member*" }
        if ($Groupmember -like "*$Member*") {
            Write-Host "<<$Member>> is already part of the Local Administrators Group on <<$Server>>!!" -ForegroundColor Yellow
            Write-LogInfo -LogPath $sLogFile -Message "<<$Member>> is already part of the Local Administrators Group on <<$Server>>!!"
        }
# Else add the member.
        else {
            Write-Host "Powershell version for <<$Server>> verified and deemed OK! Attempting to add <<$Member>> to Local Administrators Group!" -ForegroundColor Green
            Write-LogInfo -LogPath $sLogFile -Message "Powershell version for <<$Server>> verified and deemed OK! Attempting to add <<$Member>> to Local Administrators Group!!!"
            $ServerIP = [System.Net.Dns]::GetHostByName($Server)
            $adminGroup = $([ADSI]"WinNT://$($ServerIP.AddressList[0].IPAddressToString)/Administrators,group")
            $adminGroup.psbase.Invoke("Add",([ADSI]"WinNT://$Domain/$Member").path)
            $Groupmember = $([ADSI]"WinNT://$($ServerIP.AddressList[0].IPAddressToString)/Administrators,group").psbase.Invoke('Members') | ForEach-Object { $_.GetType().InvokeMember('ADspath', 'GetProperty', $null, $_, $null).Replace('WinNT://', '') } | Where-Object {$_ -like "*$Member*" }
            if ($Groupmember -like "*$Member*") {
                Write-Host "Succesfully added <<$Member>> to the Local Administrators Group for <<$Server>>!!" -ForegroundColor Green
                Write-LogInfo -LogPath $sLogFile -Message "Succesfully added <<$Member>> to the Local Administrators Group for <<$Server>>!!"
            }
            else {
                Write-Host "Failed to add <<$Member>> to the Local Administrators Group for <<$Server>>!!" -ForegroundColor Red
                Write-LogInfo -LogPath $sLogFile -Message "Failed to add <<$Member>> to the Local Administrators Group for <<$Server>>!!"
            }
        }
}
Stop-Log -LogPath $sLogFile