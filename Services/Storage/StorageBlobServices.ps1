param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

If ($Task -eq 'Processing') {
    <######### Insert the resource extraction here ########>

    $storageacc = $Resources | Where-Object { $_.TYPE -eq 'microsoft.storage/storageaccounts' }

    <######### Insert the resource Process here ########>

    if($storageacc)
    {
        $tmp = @()

        foreach ($1 in $storageacc) 
        {
            $ResUCount = 1
            $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }

            $blobSvcs = (az storage account blob-service-properties show --resource-group $1.ResourceGroup --account-name $1.name) | ConvertFrom-Json

            if($blobSvcs)
            {
                    $obj = @{
                        'ID'                                     = $blobSvcs.id;
                        'Subscription'                           = $sub1.name;
                        'Resource Group'                         = $1.RESOURCEGROUP;
                        'Name'                                   = $blobSvcs.name;
                        'Location'                               = $1.LOCATION;
                        'Storage Account'                        = $1.name;
                        'Sku Name'                               = $blobSvcs.sku.name;
                        'Sku Tier'                               = $blobSvcs.sku.tier;
                        'Versioning Enabled'                     = if ($null -ne $blobSvcs.isVersioningEnabled) { $blobSvcs.isVersioningEnabled } else { $false };
                        'Restore Policy Enabled'                 = if ($null -ne $blobSvcs.restorePolicy.enabled) { $blobSvcs.restorePolicy.enabled } else { $false };
                        'Restore Policy Days'                    = if ($null -ne $blobSvcs.restorePolicy.days) { $blobSvcs.restorePolicy.days }else { 0 };
                        'Restore Policy Min Restore Time'        = if ($null -ne $blobSvcs.restorePolicy.minRestoreTime) { $blobSvcs.restorePolicy.minRestoreTime }else { 0 };
                        'Delete Policy Enabled'                  = if ($null -ne $blobSvcs.deleteRetentionPolicy.enabled) { $blobSvcs.deleteRetentionPolicy.enabled } else { $false };
                        'Delete Policy Days'                     = if ($null -ne $blobSvcs.deleteRetentionPolicy.days) { $blobSvcs.deleteRetentionPolicy.days }else { 0 };
                        'Delete Policy Allow Perm Del'           = if ($null -ne $blobSvcs.deleteRetentionPolicy.allowPermanentDelete) { $blobSvcs.deleteRetentionPolicy.allowPermanentDelete } else { $false };
                        'Change Feed Enabled'                    = if ($null -ne $blobSvcs.changeFeed.enabled) { $blobSvcs.changeFeed.enabled } else { $false };
                        'Change Feed Days'                       = if ($null -ne $blobSvcs.changeFeed.retentionInDays) { $blobSvcs.changeFeed.retentionInDays } else { 0 };
                        'Container Del Retention Enabled'        = if ($null -ne $blobSvcs.containerDeleteRetentionPolicy.enabled) { $blobSvcs.containerDeleteRetentionPolicy.enabled } else { $false };
                        'Container Del Retention Days'           = if ($null -ne $blobSvcs.containerDeleteRetentionPolicy.days) { $blobSvcs.containerDeleteRetentionPolicy.days } else { 0 };
                        'Container Del Retention Allow Perm Del' = if ($null -ne $blobSvcs.containerDeleteRetentionPolicy.allowPermanentDelete) { $blobSvcs.containerDeleteRetentionPolicy.allowPermanentDelete } else { $false };
                    }
                
                    $tmp += $obj
                    if ($ResUCount -eq 1) { $ResUCount = 0 }
            }
        }
            
        $tmp
    }
}

<######## Resource Excel Reporting Begins Here ########>

Else {
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if ($SmaResources.StorageBlobServices) 
    {

        $TableName = ('StorageBlobServicesTable_'+($SmaResources.StorageBlobServices.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Storage Account')
        $Exc.Add('Sku Name')
        $Exc.Add('Sku Tier')
        $Exc.Add('Versioning Enabled')
        $Exc.Add('Restore Policy Enabled')
        $Exc.Add('Restore Policy Days')
        $Exc.Add('Restore Policy Min Restore Time')
        $Exc.Add('Delete Policy Enabled')
        $Exc.Add('Delete Policy Days')
        $Exc.Add('Delete Policy Allow Perm Del')
        $Exc.Add('Change Feed Enabled')
        $Exc.Add('Change Feed Days')
        $Exc.Add('Container Del Retention Enabled')
        $Exc.Add('Container Del Retention Days')
        $Exc.Add('Container Del Retention Allow Perm Del')

        $ExcelVar = $SmaResources.StorageBlobServices

        $ExcelVar |
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc |
        Export-Excel -Path $File -WorksheetName 'Storage Blob Services' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

        <######## Insert Column comments and documentations here following this model #########>

        $excel = Open-ExcelPackage -Path $File -KillExcel

        Close-ExcelPackage $excel
    }
}