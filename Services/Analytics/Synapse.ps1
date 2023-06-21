param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

if ($Task -eq 'Processing') 
{
    $Synapse = $Resources | Where-Object { $_.TYPE -eq 'microsoft.synapse/workspaces' }

    if($Synapse)
    {
        $tmp = @()
        foreach ($1 in $Synapse) 
        {
            $ResUCount = 1
            $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
            $data = $1.PROPERTIES
            $pvt = $data.privateEndpointConnections.count

            $obj = @{
                'ID'                           = $1.id;
                'Subscription'                 = $sub1.Name;
                'ResourceGroup'                = $1.RESOURCEGROUP;
                'Name'                         = $1.NAME;
                'Location'                     = $1.LOCATION;
                'PublicNetworkAccess'          = $data.publicNetworkAccess;
                'PrivateEndpoints'             = [string]$pvt;
                'DoubleEncryptionEnabled'      = [string]$data.encryption.doubleEncryptionEnabled;
                'TrustedServiceBypassEnabled'  = $data.trustedServiceBypassEnabled;
                'SQLAdministratorLogin'        = $data.sqlAdministratorLogin;
                'ScopeEnabled'                 = [string]$data.extraProperties.IsScopeEnabled;
                'WorkspaceType'                = [string]$data.extraProperties.WorkspaceType;
                'PreventDataExfiltration'      = [string]$data.managedVirtualNetworkSettings.preventDataExfiltration;
                'ManagedVirtualNetwork'        = $data.managedVirtualNetwork;                            
                'ManagedResourceGroup'         = $data.managedResourceGroupName;
            }

            $tmp += $obj
            if ($ResUCount -eq 1) { $ResUCount = 0 }            
        }

        $tmp
    }
}
else 
{
    if ($SmaResources.Synapse) 
    {

        $TableName = ('SynapseTable_'+($SmaResources.Synapse.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('PublicNetworkAccess')
        $Exc.Add('PrivateEndpoints')
        $Exc.Add('DoubleEncryptionEnabled')
        $Exc.Add('TrustedServiceBypassEnabled')
        $Exc.Add('SQLAdministratorLogin')
        $Exc.Add('ScopeEnabled')
        $Exc.Add('WorkspaceType')
        $Exc.Add('PreventDataExfiltration')
        $Exc.Add('ManagedVirtualNetwork')
        $Exc.Add('ManagedResourceGroup')

        $ExcelVar = $SmaResources.Synapse 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Synapse' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

    }
}