param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    $FRONTDOOR = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/frontdoors' }

    if($FRONTDOOR)
        {
            $tmp = @()

            foreach ($1 in $FRONTDOOR) 
                {
                    $ResUCount = 1
                    $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                    $data = $1.PROPERTIES
                    if([string]::IsNullOrEmpty($data.frontendendpoints.properties.webApplicationFirewallPolicyLink.id)){$WAF = $false} else {$WAF = $data.frontendendpoints.properties.webApplicationFirewallPolicyLink.id.split('/')[8]}
                    
                    $obj = @{
                        'ID'             = $1.id;
                        'Subscription'   = $sub1.Name;
                        'Resource Group' = $1.RESOURCEGROUP;
                        'Name'           = $1.NAME;
                        'Location'       = $1.LOCATION;
                        'Friendly Name'  = $data.friendlyName;
                        'cName'          = $data.cName;
                        'State'          = $data.enabledState;
                        'Web Application Firewall' = [string]$WAF;
                        'Frontend'       = [string]$data.frontendEndpoints.name;
                        'Backend'        = [string]$data.backendPools.name;
                        'Health Probe'   = [string]$data.healthProbeSettings.name;
                        'Load Balancing' = [string]$data.loadBalancingSettings.name;
                        'Routing Rules'  = [string]$data.routingRules.name;
                        'Resource U'     = $ResUCount;
                        'Total'          = $Total;
                    }
                    $tmp += $obj
                    if ($ResUCount -eq 1) { $ResUCount = 0 }             
                }
            $tmp
        }
}
Else {
    if ($SmaResources.FRONTDOOR) {

        $TableName = ('FRONTDOORTable_'+($SmaResources.FRONTDOOR.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()
        $condtxt += New-ConditionalText FALSE -Range H:H
        $condtxt += New-ConditionalText FALSO -Range H:H

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Friendly Name')
        $Exc.Add('cName')
        $Exc.Add('State')
        $Exc.Add('Web Application Firewall')
        $Exc.Add('Frontend')
        $Exc.Add('Backend')
        $Exc.Add('Health Probe')
        $Exc.Add('Load Balancing')
        $Exc.Add('Routing Rules')

        $ExcelVar = $SmaResources.FrontDoor 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'FrontDoor' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style
    
    }
}