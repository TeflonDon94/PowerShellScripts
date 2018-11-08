###
#   Make sure you have added the destination as a Trusted Host on the machine ****where you are initiating from****,
#   by running 'Set-Item WSMan:\localhost\Client\TrustedHosts -Value ""'
###

##
#                                                   Script Parameters
##

Param (
    [String]$Computername,
    [String]$Credential
)

Enter-PSSession -ComputerName $Computername -Credential $Credential