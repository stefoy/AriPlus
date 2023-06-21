param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)


If ($Task -eq 'Processing') {

    $APPGTW = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/applicationgateways' }

    if($APPGTW)
        {
            $tmp = @()

            foreach ($1 in $APPGTW) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                if([string]::IsNullOrEmpty($data.autoscaleConfiguration.maxCapacity)){$MaxCap = 'Autoscale Disabled'}else{$MaxCap = $data.autoscaleConfiguration.maxCapacity}
                if([string]::IsNullOrEmpty($data.autoscaleConfiguration.minCapacity)){$MinCap = 'Autoscale Disabled'}else{$MinCap = $data.autoscaleConfiguration.minCapacity}
                if([string]::IsNullOrEmpty($data.sslPolicy.minProtocolVersion)){$PROT = 'Default'}else{$PROT = $data.sslPolicy.minProtocolVersion}
                if([string]::IsNullOrEmpty($data.webApplicationFirewallConfiguration.enabled)){$WAF = $false}else{$WAF = $data.webApplicationFirewallConfiguration.enabled}
                
                $obj = @{
                    'ID'                    = $1.id;
                    'Subscription'          = $sub1.Name;
                    'Resource Group'        = $1.RESOURCEGROUP;
                    'Name'                  = $1.NAME;
                    'Location'              = $1.LOCATION;
                    'State'                 = $data.OperationalState;
                    'WAF Enabled'           = $WAF;
                    'Minimum TLS Version'   = "$($PROT -Replace '_', '.' -Replace 'v', ' ' -Replace 'tls', 'TLS')";
                    'Autoscale Min Capacity'= $MinCap;
                    'Autoscale Max Capacity'= $MaxCap;
                    'SKU Name'              = $data.sku.tier;
                    'Current Instances'     = $data.sku.capacity;
                    'Backend'               = [string]$data.backendAddressPools.name;
                    'Frontend'              = [string]$data.frontendIPConfigurations.name;
                    'Frontend Ports'        = [string]$data.frontendports.properties.port;
                    'Gateways'              = [string]$data.gatewayIPConfigurations.name;
                    'HTTP Listeners'        = [string]$data.httpListeners.name;
                    'Request Routing Rules' = [string]$data.RequestRoutingRules.Name;
                    'Resource U'            = $ResUCount;
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 }             
            }
            $tmp
        }
}
Else {
    if ($SmaResources.APPGW) {

        $TableName = ('APPGWTable_'+($SmaResources.APPGW.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()
        $condtxt += New-ConditionalText FALSE -Range F:F
        $condtxt += New-ConditionalText FALSO -Range F:F
        $condtxt += New-ConditionalText Default -Range G:G
        $condtxt += New-ConditionalText 'Autoscale Disabled' -Range H:H
        $condtxt += New-ConditionalText 'Autoscale Disabled' -Range I:I

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('State')
        $Exc.Add('WAF Enabled')
        $Exc.Add('Minimum TLS Version')
        $Exc.Add('Autoscale Min Capacity')
        $Exc.Add('Autoscale Max Capacity')
        $Exc.Add('SKU Name')
        $Exc.Add('Current Instances')
        $Exc.Add('Backend')
        $Exc.Add('Frontend')
        $Exc.Add('Frontend Ports')
        $Exc.Add('Gateways')
        $Exc.Add('HTTP Listeners')
        $Exc.Add('Request Routing Rules')

        $ExcelVar = $SmaResources.APPGW 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'App Gateway' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style
    }
}
