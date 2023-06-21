param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    <######### Insert the resource extraction here ########>

    $VM =  $Resources | Where-Object {$_.TYPE -eq 'microsoft.compute/virtualmachines'}
    $AVD = $Resources | Where-Object { $_.TYPE -eq 'microsoft.desktopvirtualization/hostpools' }
    $Hosts = $Resources | Where-Object { $_.TYPE -eq 'microsoft.desktopvirtualization/hostpools/sessionhosts' }

    if($AVD)
        {
            $tmp = @()
            foreach ($1 in $AVD) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES

                $sessionhosts = @()
                foreach ($h in $Hosts){
                    $n = $h.ID -split '/sessionhosts/' 
                    if ($n[0] -eq $1.id ) 
                    {
                        $sessionhosts += $h                    
                    }

                }
                
                if ($1.ZONES) { $Zones = $1.ZONES }else { $Zones = 'Not Configured' }

                foreach ($2 in $sessionhosts)
                {
                    $domain = $2.name.replace(($2.name.split(".")[0]),'')
                    $vmsessionhosts = $VM | Where-Object { $_.ID -eq $2.properties.resourceId}

                    $obj = @{
                        'ID'                 = $1.id;
                        'Subscription'       = $sub1.Name;
                        'ResourceGroup'     = $1.RESOURCEGROUP;
                        'HostpoolName'      = $1.NAME;
                        'Location'           = $1.LOCATION;
                        'Zone'               = $Zones;
                        'HostPoolType'      = $data.hostPoolType;
                        'LoadBalancer'       = $data.loadBalancerType;
                        'maxSessionLimit'    = $data.maxSessionLimit;
                        'PreferredAppGroup' = $data.preferredAppGroupType;
                        'AVDAgentVersion'  = $2.properties.agentVersion;
                        'LastAssignedUser' = $2.properties.assignedUser;
                        'AllowNewSession'  = $2.properties.allowNewSession;
                        'UpdateStatus'      = $2.properties.updateState;
                        'Hostname'           = $vmsessionhosts.name;
                        'Domain'             = $domain;
                        'VMSize'            = $vmsessionhosts.properties.hardwareProfile.vmsize;
                        'OSType'            = $vmsessionhosts.properties.storageProfile.osdisk.ostype;
                        'VMDiskType'       = $vmsessionhosts.properties.storageProfile.osdisk.managedDisk.storageAccountType;
                        'Sessions'           = $2.properties.sessions;
                        'HostStatus'        = $2.properties.status;
                        'OSVersion'         = $2.properties.osVersion;
                        'ResourceU'         = $ResUCount;
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

    if ($SmaResources.AVD) {

        $TableName = ('AVD_'+($SmaResources.AVD.id | Select-Object -Unique).count)
        $condtxtzone = New-ConditionalText "Not Configured" -Range E:E
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('HostpoolName')             
        $Exc.Add('Location')                
        $Exc.Add('Zone')
        $Exc.Add('HostPoolType')
        $Exc.Add('LoadBalancer')
        $Exc.Add('maxSessionLimit')
        $Exc.Add('PreferredAppGroup')
        $Exc.Add('AVDAgentVersion')  
        $Exc.Add('LastAssignedUser') 
        $Exc.Add('AllowNewSession')
        $Exc.Add('UpdateStatus')      
        $Exc.Add('Hostname')           
        $Exc.Add('Domain')             
        $Exc.Add('VMSize')            
        $Exc.Add('OSType')           
        $Exc.Add('VMDiskType')
        $Exc.Add('Sessions')       
        $Exc.Add('HostStatus')        
        $Exc.Add('OSVersion')

        $ExcelVar = $SmaResources.AVD

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'AVD' -AutoSize -TableName $TableName -MaxAutoSizeRows 100 -TableStyle $tableStyle -ConditionalText $condtxtzone -Style $Style    
    }
}