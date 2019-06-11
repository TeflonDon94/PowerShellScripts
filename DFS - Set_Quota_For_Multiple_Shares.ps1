###   Require "File Server Resource Manager"-role to be installed.   ###
###   Requires the physical location of the share on the Windows Disk.   ###
Param (
    [String]$drivepath
)
###   Imports the CSV which is drawn from the orechestrator and modifies the content to retract relevant variables.  ###
$csv = import-csv 'C:\Temp\Quota.csv'   
$csv | Group name,Username  | Foreach-Object {
###   The above grouping adds spaces and for that we need to split the grouped object.  ###
    $split = $_.name -split ','
    $splittrim = $split.TrimStart()
    New-Object -Type PSObject -Property @{ 
        'Name' = $splittrim[0];'Username' = $splittrim[1]
        'Percentage' = ($_.Group | Measure-Object Percentage -Sum).Sum 
    }
###   Export all this information and create a new CSV.  ###
} | export-csv 'C:\Temp\Quota2.csv'
###   Imports the CSV with the corrected content to throw them into variables.  ###
$csv2 = import-csv 'C:\Temp\Quota2.csv'
$csv2 | ForEach-Object {
    $Customer = $_.Name
    $Username = $_.Username
    $QuotaLimitString = $_.Percentage
###   Converts the decimal number out of the imported CSV, which is in the 0.1MB format to the decimal GB amount.
    $QuotaLimit = ([decimal]::Parse($QuotaLimitString)) * 10.24 * 1024 * 1024
###   Applies the actual quota settings for each share.  ###
    New-FsrmQuota -Path "$drivepath\$customer\$Username" -Size $QuotaLimit
}