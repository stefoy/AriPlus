param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

If ($Task -eq 'Processing') {

    $DataBricks = $Resources | Where-Object { $_.TYPE -eq 'microsoft.databricks/workspaces' }

    if($DataBricks)
        {
            $tmp = @()

            foreach ($1 in $DataBricks) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $sku = $1.SKU
                $timecreated = $data.createdDateTime
                $timecreated = [datetime]$timecreated
                $timecreated = $timecreated.ToString("yyyy-MM-dd HH:mm")
                $PIP = if($data.parameters.enableNoPublicIp.value -eq 'False'){$true}else{$false}
                $VNET = $data.parameters.customVirtualNetworkId.value.split('/')[8]
                
                $obj = @{
                    'ID'                        = $1.id;
                    'Subscription'              = $sub1.Name;
                    'ResourceGroup'            = $1.RESOURCEGROUP;
                    'Name'                      = $1.NAME;
                    'Location'                  = $1.LOCATION;
                    'PricingTier'              = $sku.name;
                    'ManagedResourceGroup'    = $data.managedResourceGroupId.split('/')[4];
                    'StorageAccount'           = $data.parameters.storageAccountName.value;
                    'StorageAccountSKU'       = $data.parameters.storageAccountSkuName.value;
                    'CustomVirtualNetwork'    = $VNET;
                    'CreatedTime'              = $timecreated;
                    'ResourceU'                = $ResUCount;
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

    if ($SmaResources.Databricks) {

        $TableName = ('DBricksTable_'+($SmaResources.Databricks.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()



        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('PricingTier')
        $Exc.Add('ManagedResourceGroup')
        $Exc.Add('StorageAccount')
        $Exc.Add('StorageAccountSKU')
        $Exc.Add('CustomVirtualNetwork')
        $Exc.Add('CreatedTime')  

        $ExcelVar = $SmaResources.Databricks

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Databricks' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

    }
    <######## Insert Column comments and documentations here following this model #########>
}
