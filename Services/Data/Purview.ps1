param($SCPath, $Sub,  $Resources, $Task , $File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    <######### Insert the resource extraction here ########>

    $Purview = $Resources | Where-Object { $_.TYPE -eq 'microsoft.purview/accounts' }

    if($Purview)
        {
            $tmp = @()
            foreach ($1 in $Purview) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $CloudConnectors = $data.cloudConnectors.count
                $pvted = $data.privateEndpointConnections.count
                $timecreated = $data.createdAt
                $timecreated = [datetime]$timecreated
                $timecreated = $timecreated.ToString("yyyy-MM-dd HH:mm")
                $StorageAcc = $data.managedResources.storageAccount.split('/')[8]
                $eventHubNamespace = $data.managedResources.eventHubNamespace.split('/')[8]
                
                $obj = @{
                    'ID'                                = $1.id;
                    'Subscription'                      = $sub1.Name;
                    'Resource Group'                    = $1.RESOURCEGROUP;
                    'Name'                              = $1.NAME;
                    'Location'                          = $1.LOCATION;
                    'SKU'                               = $data.sku.name;
                    'Capacity'                          = $data.sku.capacity;
                    'Friendly Name'                     = $data.friendlyName;
                    'Created By'                        = $data.createdBy;      
                    'Created Time'                      = $timecreated;                      
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 }            
            }
            $tmp
        }
}
<######## Resource Excel Reporting Begins Here ########>

Else {
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if ($SmaResources.Purview) {

        $TableName = ('PurviewATable_'+($SmaResources.Purview.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU')
        $Exc.Add('Capacity')
        $Exc.Add('Friendly Name')
        $Exc.Add('Created By')
        $Exc.Add('Created Time')

        $ExcelVar = $SmaResources.Purview 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Purview' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

    }
    <######## Insert Column comments and documentations here following this model #########>
}
