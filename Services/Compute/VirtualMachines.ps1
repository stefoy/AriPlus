param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing')
{
    $virtualMachines =  $Resources | Where-Object {$_.TYPE -eq 'microsoft.compute/virtualmachines'}
    $nic = $Resources | Where-Object {$_.TYPE -eq 'microsoft.network/networkinterfaces'}
    $vmexp = $Resources | Where-Object {$_.TYPE -eq 'microsoft.compute/virtualmachines/extensions'}
    $disk = $Resources | Where-Object {$_.TYPE -eq 'microsoft.compute/disks'}        
    $vmsizemap = @{}

    foreach($location in ($virtualMachines | Select-Object -ExpandProperty location -Unique))
    {
        foreach ($vmsize in ( az vm list-sizes -l $location | ConvertFrom-Json))
        {
            $vmsizemap[$vmsize.name] = @{
                CPU = $vmSize.numberOfCores
                RAM = [math]::Round($vmSize.memoryInMB / 1024, 0) 
            }
        }
    }

    if($virtualMachines)
    {    
        $tmp = @()

        foreach ($1 in $virtualMachines) 
        {
            $ResUCount = 1
            $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
            $data = $1.PROPERTIES 
            $timecreated = $data.timeCreated
            $timecreated = [datetime]$timecreated
            $timecreated = $timecreated.ToString("yyyy-MM-dd HH:mm")
            $AVSET = ''
            $dataSize = ''
            $StorAcc = ''

            $ext = @()
            $AzDiag = ''
            $Azinsights = ''

            $Lic = $data.licenseType
            
            switch ($data.licenseType) 
            {
                'Windows_Server' { $Lic = 'AHUB for Windows' }
                'Windows_Client' { $Lic = 'Windows Client Multi-Tenant' }
                'RHEL_BYOS'      { $Lic = 'AHUB for Redhat' }
                'SLES_BYOS'      { $Lic = 'AHUB for SUSE' }
            }

            $Lic = if($Lic) { $Lic } else { 'License Included' }

            $ext = ($vmexp | Where-Object { ($_.id -split "/")[8] -eq $1.name }).properties.Publisher
            if ($null -ne $ext) 
            {
                $ext = foreach ($ex in $ext) 
                    {
                        if ($ex | Where-Object { $_ -eq 'Microsoft.Azure.Performance.Diagnostics' }) { $AzDiag = $true }
                        if ($ex | Where-Object { $_ -eq 'Microsoft.EnterpriseCloud.Monitoring' }) { $Azinsights = $true }
                        $ex + ', '
                    }
                $ext = [string]$ext
                $ext = $ext.Substring(0, $ext.Length - 2)
            }

            if ($null -ne $data.availabilitySet) { $AVSET = 'True' }else { $AVSET = 'False' }
            if ($data.diagnosticsProfile.bootDiagnostics.enabled -eq $true) { $bootdg = $true }else { $bootdg = $false }

            if($data.storageProfile.osDisk.managedDisk.id) 
            {
                $OSDisk = ($disk | Where-Object {$_.id -eq $data.storageProfile.osDisk.managedDisk.id} | Select-Object -Unique).sku.name
                $OSDiskSize = ($disk | Where-Object {$_.id -eq $data.storageProfile.osDisk.managedDisk.id} | Select-Object -Unique).Properties.diskSizeGB
            }
            else
            {
                $OSDisk = if($data.storageProfile.osDisk.vhd.uri){'Custom VHD'}else{''}
                $OSDiskSize = $data.storageProfile.osDisk.diskSizeGB
            }

            $StorAcc = if ($data.storageProfile.dataDisks.managedDisk.id.count -ge 2) 
                        { 
                            ($data.storageProfile.dataDisks.managedDisk.id.count.ToString() + ' Disks found.') 
                        }
                        else 
                        { 
                            ($disk | Where-Object {$_.id -eq $data.storageProfile.dataDisks.managedDisk.id} | Select-Object -Unique).sku.name
                        }
            $dataSize = if ($data.storageProfile.dataDisks.managedDisk.storageAccountType.count -ge 2) 
                        { 
                            (($disk | Where-Object {$_.id -in $data.storageProfile.dataDisks.managedDisk.id}).properties.diskSizeGB | Measure-Object -Sum).Sum
                        }
                        else 
                        { 
                            ($disk | Where-Object {$_.id -eq $data.storageProfile.dataDisks.managedDisk.id}).properties.diskSizeGB
                        }                    

            $VMNICS = if(![string]::IsNullOrEmpty($data.networkProfile.networkInterfaces.id)){$data.networkProfile.networkInterfaces.id}else{'0'}
  
            foreach ($2 in $VMNICS) 
            {
                $vmnic = $nic | Where-Object { $_.ID -eq $2 } | Select-Object -Unique
                $networkSecurityGroup = if($vmnic.properties.networkSecurityGroup.id){$vmnic.properties.networkSecurityGroup.id.split('/')[8]}else{'None'}
                $virtualNetwork = $vmnic.properties.ipConfigurations.properties.subnet.id.split('/')[8]
                $subnet = $vmnic.properties.ipConfigurations.properties.subnet.id.split('/')[10]

                $obj = @{
                    'ID'                            = $1.id;
                    'Subscription'                  = $sub1.Name;
                    'ResourceGroup'                 = $1.RESOURCEGROUP;
                    'Name'                          = $1.NAME;
                    'Location'                      = $1.LOCATION;
                    'Zone'                          = [string]$1.ZONES;
                    'AvailabilitySet'               = $AVSET;
                    'Size'                          = $data.hardwareProfile.vmSize;
                    'vCPUs'                         = $vmsizemap[$data.hardwareProfile.vmSize].CPU;
                    'RAM'                           = $vmsizemap[$data.hardwareProfile.vmSize].RAM;
                    'ImageReference'                = $data.storageProfile.imageReference.publisher;
                    'ImageVersion'                  = $data.storageProfile.imageReference.exactVersion;
                    'HybridBenefit'                 = $Lic;
                    'OSType'                        = $data.storageProfile.osDisk.osType;
                    'OSName'                        = $data.extended.instanceView.osname;
                    'OSVersion'                     = $data.extended.instanceView.osversion;
                    'OSDiskStorageType'             = $OSDisk;
                    'OSDiskSize'                    = $OSDiskSize;
                    'DataDiskStorageType'           = $StorAcc;
                    'DataDiskSize'                  = $dataSize;
                    'PowerState'                    = $data.extended.instanceView.powerState.displayStatus;
                    'NICName'                       = [string]$vmnic.name;
                    'VirtualNetwork'                = $virtualNetwork;
                    'Subnet'                        = $subnet;
                    'NSG'                           = $networkSecurityGroup;
                    'CreatedTime'                   = $timecreated;
                    'PerformanceAgent'              = if ($azDiag -ne '') { $true }else { $false };
                    'AzureMonitor'                  = if ($Azinsights -ne '') { $true }else { $false };
                    'Extensions'                    = $ext;
                    'ResourceU'                     = $ResUCount;
                }

                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 } 

                Remove-Variable vmnic, networkSecurityGroup, virtualNetwork, Subnet                        
            }
        }
                
        $tmp
    }            
}
else
{
    If($SmaResources.VirtualMachines)
    {
        $TableName = ('VMTable_'+($SmaResources.VirtualMachines.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0' -VerticalAlignment Center
        $StyleExt = New-ExcelStyle -HorizontalAlignment Left -Range AK:AK -Width 60 -WrapText 

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Name')
        $Exc.Add('Size')
        $Exc.Add('vCPUs')
        $Exc.Add('RAM')
        $Exc.Add('Location')
        $Exc.Add('OSType')
        $Exc.Add('OSName')
        $Exc.Add('OSVersion')
        $Exc.Add('ImageReference')
        $Exc.Add('ImageVersion')
        $Exc.Add('HybridBenefit')
        $Exc.Add('OSDiskStorageType')
        $Exc.Add('OSDiskSize')
        $Exc.Add('DataDiskStorageType')
        $Exc.Add('DataDiskSize')
        $Exc.Add('PowerState')
        $Exc.Add('AvailabilitySet')
        $Exc.Add('Zone')    
        $Exc.Add('VirtualNetwork')
        $Exc.Add('Subnet')
        $Exc.Add('NSG')
        $Exc.Add('NICName')
        $Exc.Add('CreatedTime')     
        $Exc.Add('AzureMonitor')        
        $Exc.Add('PerformanceAgent')     
        $Exc.Add('Extensions')
        $Exc.Add('ResourceU')

        $ExcelVar = $SmaResources.VirtualMachines
                    
        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Virtual Machines' -TableName $TableName -MaxAutoSizeRows 100 -TableStyle $tableStyle -Style $Style, $StyleExt
    }             
}
