param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing')
{
    <######### Insert the resource extraction here ########>

        $vmss = $Resources | Where-Object {$_.TYPE -eq 'microsoft.compute/virtualmachinescalesets'}
        $AutoScale = $Resources | Where-Object {$_.TYPE -eq "microsoft.insights/autoscalesettings" -and $_.Properties.enabled -eq 'true'} 
        $AKS = $Resources | Where-Object {$_.TYPE -eq 'microsoft.containerservice/managedclusters'}
        $SFC = $Resources | Where-Object {$_.TYPE -eq 'microsoft.servicefabric/clusters'}

    $vmsizemap = @{}

    foreach($location in ($vmss | Select-Object -ExpandProperty location -Unique))
    {
        foreach ($vmsize in (az vm list-sizes -l $location | ConvertFrom-Json))
        {
            $vmsizemap[$vmsize.name] = @{
                CPU = $vmSize.numberOfCores
                RAM = [math]::Round($vmSize.memoryInMB / 1024, 0) 
            }
        }
    }

    <######### Insert the resource Process here ########>

    if($vmss)
        {
            $tmp = @()

            foreach ($1 in $vmss) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $OS = $data.virtualMachineProfile.storageProfile.osDisk.osType
                $RelatedAKS = ($AKS | Where-Object {$_.properties.nodeResourceGroup -eq $1.resourceGroup}).Name
                if([string]::IsNullOrEmpty($RelatedAKS)){$Related = ($SFC | Where-Object {$_.Properties.clusterEndpoint -in $1.properties.virtualMachineProfile.extensionProfile.extensions.properties.settings.clusterEndpoint}).Name}else{$Related = $RelatedAKS}
                $Scaling = ($AutoScale | Where-Object {$_.Properties.targetResourceUri -eq $1.id})
                if([string]::IsNullOrEmpty($Scaling)){$AutoSc = $false}else{$AutoSc = $true}
                $Diag = if($data.virtualMachineProfile.diagnosticsProfile){'Enabled'}else{'Disabled'}
                if($OS -eq 'Linux'){$disablePwd = $data.virtualMachineProfile.osProfile.linuxConfiguration.disablePasswordAuthentication}Else{$disablePwd = 'N/A'}
                $timecreated = $data.timeCreated
                $timecreated = [datetime]$timecreated
                $timecreated = $timecreated.ToString("yyyy-MM-dd HH:mm")
                $Subnet = $data.virtualMachineProfile.networkProfile.networkInterfaceConfigurations.properties.ipConfigurations.properties.subnet.id | Select-Object -Unique
                $VNET = $subnet.split('/')[8]
                $Subnet = $Subnet.split('/')[10]
                $ext = @()
                $ext = foreach ($ex in $1.Properties.virtualMachineProfile.extensionProfile.extensions.name) 
                                {
                                    $ex + ', '
                                }
                $NSG = $data.virtualMachineProfile.networkProfile.networkInterfaceConfigurations.properties.networkSecurityGroup.id.split('/')[8] 
                
                $obj = @{
                    'ID'                            = $1.id;
                    'Subscription'                  = $sub1.Name;
                    'Resource Group'                = $1.RESOURCEGROUP;
                    'AKS'                     = $Related;
                    'Name'                          = $1.NAME;
                    'Location'                      = $1.LOCATION;
                    'SKU Tier'                      = $1.sku.tier;
                    'VM Size'                       = $1.sku.name;
                    'Instances'                     = $1.sku.capacity;
                    'Autoscale Enabled'             = $AutoSc;
                    'vCPUs'                         = $vmsizemap[$data.hardwareProfile.vmSize].CPU;
                    'RAM'                           = $vmsizemap[$data.hardwareProfile.vmSize].RAM;
                    'VM OS'                         = $OS;
                    'OS Image'                      = $data.virtualMachineProfile.storageProfile.imageReference.offer;
                    'Image Version'                 = $data.virtualMachineProfile.storageProfile.imageReference.sku;                            
                    'VM OS Disk Size (GB)'          = $data.virtualMachineProfile.storageProfile.osDisk.diskSizeGB;
                    'Disk Storage Account Type'     = $data.virtualMachineProfile.storageProfile.osDisk.managedDisk.storageAccountType;
                    'Virtual Network'               = $VNET;
                    'Subnet'                        = $Subnet;
                    'Accelerated Networking Enabled'= $data.virtualMachineProfile.networkProfile.networkInterfaceConfigurations.properties.enableAcceleratedNetworking; 
                    'Network Security Group'        = $NSG;
                    'Extensions'                    = [string]$ext;
                    'VM Name Prefix'                = $data.virtualMachineProfile.osProfile.computerNamePrefix;
                    'Created Time'                  = $timecreated;
                    'Resource U'                    = $ResUCount;
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 } 
            }
            $tmp
        }
}

<######## Resource Excel Reporting Begins Here ########>

Else
{
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if($SmaResources.VMSS)
    {

        $TableName = ('VMSSTable_'+($SmaResources.VMSS.id | Select-Object -Unique).count)
        $Style = @()        

        $condtxt = @()

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('AKS')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU Tier')
        $Exc.Add('VM Size')
        $Exc.Add('vCPUs')
        $Exc.Add('RAM')
        $Exc.Add('Instances')
        $Exc.Add('Autoscale Enabled')
        $Exc.Add('VM OS')
        $Exc.Add('OS Image')
        $Exc.Add('Image Version')                        
        $Exc.Add('VM OS Disk Size (GB)')
        $Exc.Add('Disk Storage Account Type')
        $Exc.Add('Virtual Network')
        $Exc.Add('Subnet')
        $Exc.Add('Accelerated Networking Enabled')
        $Exc.Add('Network Security Group')
        $Exc.Add('VM Name Prefix')
        $Exc.Add('Created Time')

        $ExcelVar = $SmaResources.VMSS 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'VM Scale Sets' -AutoSize -MaxAutoSizeRows 50 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

    }
}
