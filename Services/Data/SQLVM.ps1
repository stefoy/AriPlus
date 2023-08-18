param($SCPath, $Sub, $Resources, $Task , $File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    <######### Insert the resource extraction here ########>

    $SQLVM = $Resources | Where-Object { $_.TYPE -eq 'microsoft.sqlvirtualmachine/sqlvirtualmachines' }

    if($SQLVM)
        {
            $tmp = @()

            foreach ($1 in $SQLVM) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                $obj = @{
                    'ID'                      = $1.id;
                    'Subscription'            = $sub1.Name;
                    'ResourceGroup'          = $1.RESOURCEGROUP;
                    'Name'                    = $1.NAME;
                    'Location'                = $1.LOCATION;
                    'Zone'                    = if ($null -ne $1.ZONES) { $1.ZONES } else { 'None' }
                    'SQLServerLicenseType' = $data.sqlServerLicenseType;
                    'SQLImage'               = $data.sqlImageOffer;
                    'SQLManagement'          = $data.sqlManagement;
                    'SQLImageSku'           = $data.sqlImageSku;
                }
                
                $tmp += $obj      
            }
            $tmp
        }
}
<######## Resource Excel Reporting Begins Here ########>

Else {
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if ($SmaResources.SQLVM) {

        $TableName = ('SQLVMTable_'+($SmaResources.SQLVM.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Zone')
        $Exc.Add('SQLServerLicenseType')
        $Exc.Add('SQLImage')
        $Exc.Add('SQLManagement')
        $Exc.Add('SQLImageSku')

        $ExcelVar = $SmaResources.SQLVM 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'SQL VMs' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

    }
    <######## Insert Column comments and documentations here following this model #########>
}
