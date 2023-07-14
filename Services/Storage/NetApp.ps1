param($SCPath, $Sub, $Resources, $Task , $File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    <######### Insert the resource extraction here ########>

    $NetApp = $Resources | Where-Object { $_.TYPE -eq 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes' }

    if($NetApp)
        {
            $tmp = @()
            foreach ($1 in $NetApp) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $VNET = $data.subnetId.split('/')[8]
                $Subnet = $data.subnetId.split('/')[10]
                $ExportPolicy = $data.exportPolicy.rules.count
                $NetApp = $1.Name.split('/')[0]
                $CapacityPool = $1.Name.split('/')[1]
                $Volume = $1.Name.split('/')[2]
                $Quota = ((($data.usageThreshold/1024)/1024)/1024)/1024
                
                $obj = @{
                    'ID'                                = $1.id;
                    'Subscription'                      = $sub1.Name;
                    'Resource Group'                    = $1.RESOURCEGROUP;
                    'Location'                          = $1.LOCATION;
                    'NetApp Account'                    = $NetApp;
                    'Capacity Pool'                     = $CapacityPool;
                    'Volume'                            = $Volume;
                    'Service Level'                     = $data.serviceLevel;
                    'Quota (TB)'                        = [string]$Quota;
                    'Protocol'                          = [string]$data.protocolTypes;
                    'Max Throughput MiB/s'              = [string]$data.throughputMibps;
                    'LDAP'                              = $data.ldapEnabled;
                    'VNET Name'                         = [string]$VNET;
                    'Subnet Name'                       = [string]$Subnet;                            
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 }              
            }
            $tmp
        }
}
<######## Resource Excel Reporting Begins Here ########>

Else {
    <######## $SmaResources.NetApp ##########>

    if ($SmaResources.NetApp) {

        $TableName = ('NetAppATable_'+($SmaResources.NetApp.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Location')
        $Exc.Add('NetApp Account')
        $Exc.Add('Capacity Pool')
        $Exc.Add('Volume')
        $Exc.Add('Service Level')
        $Exc.Add('Quota (TB)')
        $Exc.Add('Protocol')
        $Exc.Add('Max Throughput MiB/s')
        $Exc.Add('LDAP')
        $Exc.Add('VNET Name')
        $Exc.Add('Subnet Name')


        $ExcelVar = $SmaResources.NetApp 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'NetApp' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

    }
    <######## Insert Column comments and documentations here following this model #########>
}
