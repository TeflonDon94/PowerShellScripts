##
# Exchange 2010 Script to retrieve all mailboxes with a specific domain and export them to a CSV.
#
# @author       Stijn Vandezande <svandezande@thinfactory.com>
#
##

##
#                                                   Prerequisites: 
#                                                       - Exchange 2010 addin loaded
##

##
#                                                   Script Parameters
##

Param (
    [String]$SaveLocation,
    [String]$Domain
)

##
#                                                   Declarations
##

##
#                                                   Script Version
##
$ScriptVersion = '1.0'

##
#                                                   Execution
##
Get-Mailbox -resultsize unlimited | Select-Object displayname -expandproperty emailaddresses| Where-Object {$_.smtpaddress -like "*$domain*"}| Select-Object displayName,SmtpAddress,IsPrimaryAddress  | Export-csv "$SaveLocation" -nti