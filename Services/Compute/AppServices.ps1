param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing')
{
    $AppSvc = $Resources | Where-Object {$_.TYPE -eq 'microsoft.web/sites'}

    if($AppSvc)
    {
        $tmp = @()

        foreach ($1 in $AppSvc) 
        {
            $ResUCount = 1
            $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
            $data = $1.PROPERTIES
            if([string]::IsNullOrEmpty($data.siteConfig.ftpsState)){$FTPS = $false}else{$FTPS = $data.siteConfig.ftpsState}
            if([string]::IsNullOrEmpty($data.Properties.SiteConfig.acrUseManagedIdentityCreds)){$MGMID = $false}else{$MGMID = $true}

            if (![string]::IsNullOrEmpty($data.virtualNetworkSubnetId)) { $VNET = $data.virtualNetworkSubnetId.split("/")[8] } else { $VNET = "None"}
            if (![string]::IsNullOrEmpty($data.virtualNetworkSubnetId)) { $SUBNET = $data.virtualNetworkSubnetId.split("/")[10] } else { $SUBNET = "None"}
            # $VNET = $data.virtualNetworkSubnetId.split("/")[8]
            # $SUBNET = $data.virtualNetworkSubnetId.split("/")[10]

            $obj = @{
                'ID'                            = $1.id;
                'Subscription'                  = $sub1.Name;
                'ResourceGroup'                 = $1.RESOURCEGROUP;
                'Name'                          = $1.NAME;
                'AppType'                       = $1.KIND;
                'Location'                      = $1.LOCATION;
                'Enabled'                       = $data.enabled;
                'State'                         = $data.state;
                'SKU'                           = $data.sku;
                'ClientCertEnabled'             = $data.clientCertEnabled;
                'ClientCertMode'                = $data.clientCertMode;
                'ContentAvailabilityState'      = $data.contentAvailabilityState;
                'RuntimeAvailabilityState'      = $data.runtimeAvailabilityState;
                'HTTPSOnly'                     = $data.httpsOnly;
                'FTPSOnly'                      = $FTPS;
                'PossibleInboundIPAddresses'    = $data.possibleInboundIpAddresses;
                'RepositorySiteName'            = $data.repositorySiteName;
                'ManagedIdentity'               = $MGMID;
                'AvailabilityState'             = $data.availabilityState;
                'Stack'                         = $data.SiteConfig.linuxFxVersion;
                'VirtualNetwork'                = $VNET;
                'Subnet'                        = $SUBNET;
                'DefaultHostname'               = $data.defaultHostName;                        
                'ContainerSize'                 = $data.containerSize;
                'AdminEnabled'                  = $data.adminEnabled;                        
                'FTPsHostName'                  = $data.ftpsHostName;                        
                'ResourceU'                     = $ResUCount;
                'ExctendedProperties'   = $1;
            }

            $tmp += $obj
            if ($ResUCount -eq 1) { $ResUCount = 0 } 
        }
        
        $tmp
    }
}
Else
{
    if($SmaResources.AppServices)
    {

        $TableName = ('AppSvcsTable_'+($SmaResources.AppServices.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Name')
        $Exc.Add('AppType')
        $Exc.Add('Location')
        $Exc.Add('Enabled')
        $Exc.Add('State')
        $Exc.Add('SKU')
        $Exc.Add('ClientCertEnabled')
        $Exc.Add('ClientCertMode')
        $Exc.Add('ContentAvailabilityState')
        $Exc.Add('RuntimeAvailabilityState')
        $Exc.Add('HTTPSOnly')
        $Exc.Add('FTPSOnly')
        $Exc.Add('PossibleInboundIPAddresses')
        $Exc.Add('RepositorySiteName')
        $Exc.Add('ManagedIdentity')
        $Exc.Add('AvailabilityState')
        $Exc.Add('Stack')
        $Exc.Add('VirtualNetwork')
        $Exc.Add('Subnet')
        $Exc.Add('DefaultHostname')                      
        $Exc.Add('ContainerSize')
        $Exc.Add('AdminEnabled')                       
        $Exc.Add('FTPsHostName')

        $ExcelVar = $SmaResources.AppServices 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'App Services' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style
    }
}