param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    <######### Insert the resource extraction here ########>
    $AzureFirewall = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/azurefirewalls' }

    if($AzureFirewall)
        {
            $tmp = @()

            foreach ($1 in $AzureFirewall) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                if ($1.zones) { $Zones = $1.zones } Else { $Zones = "Not Configured" }
                $Threat = if($data.threatintelmode -eq 'deny'){'Alert and deny'}elseif($data.threatintelmode -eq 'alert'){'Alert only'}else{'Off'}
                
                Foreach($2 in $data.ipConfigurations)
                    {
                        $obj = @{
                            'ID'                                = $1.id;
                            'Subscription'                      = $sub1.Name;
                            'Resource Group'                    = $1.RESOURCEGROUP;
                            'Name'                              = $1.NAME;
                            'Location'                          = $1.LOCATION;
                            'SKU'                               = $data.sku.tier;
                            'Threat Intel Mode'                 = $Threat;
                            'Zone'                              = $Zones;
                            'NAT Rules'                         = [int]$data.natRuleCollections.Count;
                            'Application Rules'                 = [int]$data.applicationRuleCollections.Count;
                            'Network Rules'                     = [int]$data.networkRuleCollections.Count;
                            'Public IP Name'                    = $2.name;
                            'Firewall VNET'                     = $2.properties.subnet.id.split('/')[8];
                            'Firewall Private IP'               = $2.properties.privateIPAddress;
                            'Resource U'                        = $ResUCount;
                        }
                        $tmp += $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 } 
                }               
            }
            $tmp
        }
}
Else {
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if ($SmaResources.AzureFirewall) {

        $TableName = ('AzFirewallTable_'+($SmaResources.AzureFirewall.id | Select-Object -Unique).count)
        $condtxt = @()
        $condtxt += New-ConditionalText Off -Range F:F

        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU')
        $Exc.Add('Threat Intel Mode')
        $Exc.Add('Zone')
        $Exc.Add('NAT Rules')
        $Exc.Add('Application Rules')
        $Exc.Add('Network Rules')
        $Exc.Add('Public IP Name')
        $Exc.Add('Firewall VNET')
        $Exc.Add('Firewall Private IP')

        $ExcelVar = $SmaResources.AzureFirewall 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Azure Firewall' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

    }
    <######## Insert Column comments and documentations here following this model #########>
}