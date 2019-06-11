$CustomerMailboxes = Get-DistributionGroup -resultsize unlimited
$CustomerMailboxes | ForEach-Object {
$CustomerMailbox = $_.Name
$members = ''
Get-DistributionGroupMember $CustomerMailbox | ForEach-Object {
        If($members) {
              $members=$members + ";" + $_.Name
           } Else {
              $members=$_.Name
           }
  }
New-Object -TypeName PSObject -Property @{
      DistributionGroupName = $CustomerMailbox
      Members = $members
     }
} | Export-CSV "C:\\Distribution-Group-Members.csv" -NoTypeInformation -Encoding UTF8