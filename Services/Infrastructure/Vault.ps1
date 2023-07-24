param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

If ($Task -eq 'Processing')
{
    <######### Insert the resource extraction here ########>

        $VAULT = $Resources | Where-Object {$_.TYPE -eq 'microsoft.keyvault/vaults'}

    <######### Insert the resource Process here ########>

    if($VAULT)
        {
            $tmp = @()

            foreach ($1 in $VAULT) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                if([string]::IsNullOrEmpty($Data.enableSoftDelete)){$Soft = $false}else{$Soft = $Data.enableSoftDelete}
                
                Foreach($2 in $data.accessPolicies)
                    {
                        $obj = @{
                            'ID'                         = $1.id;
                            'Subscription'               = $sub1.Name;
                            'Resource Group'             = $1.RESOURCEGROUP;
                            'Name'                       = $1.NAME;
                            'Location'                   = $1.LOCATION;
                            'SKU Family'                 = $data.sku.family;
                            'SKU'                        = $data.sku.name;
                            'Enable RBAC'                = $data.enableRbacAuthorization;
                            'Enable Soft Delete'         = $Soft;
                            'Enable for Disk Encryption' = $data.enabledForDiskEncryption;
                            'Enable for Template Deploy' = $data.enabledForTemplateDeployment;
                            'Soft Delete Retention Days' = $data.softDeleteRetentionInDays;
                            'Resource U'                 = $ResUCount;
                        }
                        $tmp += $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 } 
                    }               
            }
            $tmp
        }
}

<######## Resource Excel Reporting Begins Here ########>

Else
{
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if($SmaResources.Vault)
    {

        $TableName = ('VaultTable_'+($SmaResources.Vault.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $condtxt = @()
        $condtxt += New-ConditionalText false -Range I:I
        $condtxt += New-ConditionalText falso -Range I:I

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU Family')
        $Exc.Add('SKU')
        $Exc.Add('Enable RBAC')
        $Exc.Add('Enable Soft Delete')
        $Exc.Add('Enable for Disk Encryption')
        $Exc.Add('Enable for Template Deploy')
        $Exc.Add('Soft Delete Retention Days')

        $ExcelVar = $SmaResources.Vault 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Key Vaults' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

        <######## Insert Column comments and documentations here following this model #########>


        #$excel = Open-ExcelPackage -Path $File -KillExcel


        #Close-ExcelPackage $excel 

    }
}
