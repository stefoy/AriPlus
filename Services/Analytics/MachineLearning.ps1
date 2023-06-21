param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    $AzureML = $Resources | Where-Object { $_.TYPE -eq 'microsoft.machinelearningservices/workspaces' }

    if($AzureML)
        {
            $tmp = @()

            foreach ($1 in $AzureML) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $sku = $1.SKU
                $timecreated = $data.creationTime
                $timecreated = [datetime]$timecreated
                $timecreated = $timecreated.ToString("yyyy-MM-dd HH:mm")
                $StorageAcc = $data.storageAccount.split('/')[8]
                $KeyVault = $data.keyVault.split('/')[8]
                $Insight = $data.applicationInsights.split('/')[8]
                $containerRegistry = $data.containerRegistry.split('/')[8]
                $obj = @{
                    'ID'                        = $1.id;
                    'Subscription'              = $sub1.Name;
                    'Resource Group'            = $1.RESOURCEGROUP;
                    'Name'                      = $1.NAME;
                    'Location'                  = $1.LOCATION;
                    'SKU'                       = $sku.name;
                    'Friendly Name'             = $data.friendlyName;
                    'Description'               = $data.description;
                    'HBI Workspace'             = $data.hbiWorkspace;
                    'Container Registry'        = $containerRegistry;
                    'Storage HNS Enabled'       = $data.storageHnsEnabled;
                    'Private Link Count'        = $data.privateLinkCount;
                    'Public Access Behind Vnet' = $data.allowPublicAccessWhenBehindVnet;
                    'Discovery Url'             = $data.discoveryUrl;
                    'ML Flow Tracking Uri'      = $data.mlFlowTrackingUri;
                    'Storage Account'           = $StorageAcc;
                    'Key Vault'                 = $KeyVault;
                    'Created Time'              = $timecreated;
                    'Application Insight'       = $Insight;
                    'Resource U'                = $ResUCount;
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

    if ($SmaResources.AzureML) {

        $TableName = ('AzureMLTable_'+($SmaResources.AzureML.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()


        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU')
        $Exc.Add('FriendlyName')
        $Exc.Add('Description')
        $Exc.Add('HBIWorkspace')
        $Exc.Add('ContainerRegistry')
        $Exc.Add('StorageHNSEnabled')
        $Exc.Add('PrivateLinkCount')
        $Exc.Add('PublicAccessBehindVnet')
        $Exc.Add('DiscoveryUrl')
        $Exc.Add('MLFlowTrackingUri')
        $Exc.Add('StorageAccount')
        $Exc.Add('KeyVault')
        $Exc.Add('ApplicationInsight')
        $Exc.Add('CreatedTime')  


        $ExcelVar = $SmaResources.AzureML

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Machine Learning' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

    }
    <######## Insert Column comments and documentations here following this model #########>
}