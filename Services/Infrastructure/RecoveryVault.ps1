param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing')
{
    <######### Insert the resource extraction here ########>

        $RECOVAULT = $Resources | Where-Object {$_.TYPE -eq 'microsoft.recoveryservices/vaults'}

    <######### Insert the resource Process here ########>

    if($RECOVAULT)
        {
            $tmp = @()

            foreach ($1 in $RECOVAULT) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                $obj = @{
                    'ID'                                       = $1.id;
                    'Subscription'                             = $sub1.Name;
                    'Resource Group'                           = $1.RESOURCEGROUP;
                    'Name'                                     = $1.NAME;
                    'Location'                                 = $1.LOCATION;
                    'SKU Name'                                 = $1.sku.name;
                    'SKU Tier'                                 = $1.sku.tier;
                    'Private Endpoint State for Backup'        = $data.privateEndpointStateForBackup;
                    'Private Endpoint State for Site Recovery' = $data.privateEndpointStateForSiteRecovery;
                    'Resource U'                               = $ResUCount;
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 }              
            }
            $tmp
        }
}

<######## Resource Excel Reporting Begins Here ########>

Else
{
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if($SmaResources.RecoveryVault)
    {

        $TableName = ('RecoveryVaultTable_'+($SmaResources.RecoveryVault.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $condtxt = @()

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU Name')
        $Exc.Add('SKU Tier')
        $Exc.Add('Private Endpoint State for Backup')
        $Exc.Add('Private Endpoint State for Site Recovery')

        $ExcelVar = $SmaResources.RecoveryVault

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Recovery Vaults' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -ConditionalText $condtxt -TableStyle $tableStyle -Style $Style

        <######## Insert Column comments and documentations here following this model #########>


        #$excel = Open-ExcelPackage -Path $File -KillExcel


        #Close-ExcelPackage $excel 

    }
}