param($SCPath, $Sub, $Resources, $Task , $File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    $NSGs = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/networksecuritygroups' }

    if ($NSGs) {
        $tmp = @()

        foreach ($1 in $NSGs) {
            $ResUCount = 1
            $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
            $data = $1.PROPERTIES

            foreach ($2 in $data.securityRules)
            {
                if ($data.networkInterfaces.count -eq 0 -and $data.subnets.count -eq 0) 
                {
                    $Orphaned = $true;
                } else {
                    $Orphaned = $false;
                }

                $obj = @{
                    'ID'                           = $1.id;
                    'Subscription'                 = $sub1.Name;
                    'Resource Group'               = $1.RESOURCEGROUP;
                    'Name'                         = $1.NAME;
                    'Location'                     = $1.LOCATION;
                    'Security Rules'               = [string]$2.name;
                    'Direction'                    = [string]$2.properties.direction;
                    'Access'                       = [string]$2.properties.Access;
                    'Priority'                     = [string]$2.properties.priority;
                    'Protocol'                     = [string]$2.properties.protocol;
                    'Source Address Prefixes'      = [string]$2.properties.sourceAddressPrefixes;
                    'Source Address Prefix'        = [string]$2.properties.sourceAddressPrefix;
                    'Source Port Ranges'           = [string]$2.properties.sourcePortRanges;
                    'Source Port Range'            = [string]$2.properties.sourcePortRange;
                    'Destination Address Prefixes' = [string]$2.properties.destinationAddressPrefixes;
                    'Destination Address Prefix'   = [string]$2.properties.destinationAddressPrefix;
                    'Destination Port Ranges'      = [string]$2.properties.destinationPortRanges;
                    'Destination Port Range'       = [string]$2.properties.destinationPortRange;
                    'NICs'                         = [string]$data.networkInterfaces.id -Join ",";
                    'Subnets'                      = [string]$data.Subnets.id;
                    'Orphaned'                     = $Orphaned;
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 }
            }    
        }
        $tmp
    }
} Else {
    $ExcelVar = $SmaResources.NetworkSecurityGroup
    if ($ExcelVar) {

        $TableName = ('NSGTable_'+($SmaResources.NetworkSecurityGroup.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        #Conditional formats.  Note that this can be $() for none
        $condtxt = $(
            New-ConditionalText true -Range T:T
        )

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Security Rules')
        $Exc.Add('Direction')
        $Exc.Add('Access')
        $Exc.Add('Priority')
        $Exc.Add('Protocol')
        $Exc.Add('Source Address Prefixes')
        $Exc.Add('Source Address Prefix')
        $Exc.Add('Source Port Ranges')
        $Exc.Add('Source Port Range')
        $Exc.Add('Destination Address Prefixes')
        $Exc.Add('Destination Address Prefix')
        $Exc.Add('Destination Port Ranges')
        $Exc.Add('Destination Port Range')
        $Exc.Add('NICs')
        $Exc.Add('Subnets')
        $Exc.Add('Orphaned')

        $ExcelVar |
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc |
        Export-Excel -Path $File -WorksheetName 'Network Security Groups' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style


        <######## Insert Column comments and documentations here following this model.  See StoraceAcc.ps1 for samples #########>


    }
}
