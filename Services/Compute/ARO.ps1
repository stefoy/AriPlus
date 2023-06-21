param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    $ARO = $Resources | Where-Object { $_.TYPE -eq 'microsoft.redhatopenshift/openshiftclusters' }

    if($ARO)
        {
            $tmp = @()
            foreach ($1 in $ARO) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES

                $obj = @{
                    'ID'                   = $1.id;
                    'Subscription'         = $sub1.Name;
                    'ResourceGroup'       = $1.RESOURCEGROUP;
                    'Clusters'             = $1.NAME;
                    'Location'             = $1.LOCATION;
                    'AROVersion'          = $data.clusterProfile.version;
                    'ARODomain'           = $data.clusterProfile.domain;
                    'OutboundType'        = $data.networkProfile.outboundType;
                    'IngressProfileName' = $data.ingressProfiles.name;
                    'IngressProfileType' = $data.ingressProfiles.visibility;
                    'IngressProfileIP'   = $data.ingressProfiles.ip;
                    'APIServerType'      = $data.apiserverProfile.visibility;
                    'APIServerURL'       = $data.apiserverProfile.url;
                    'APIServerIP'        = $data.apiserverProfile.ip;
                    'DockerPodCidr'      = $data.networkProfile.podCidr;
                    'ServiceCidr'         = $data.networkProfile.serviceCidr;
                    'ConsoleURL'          = $data.consoleProfile.url;                   
                    'MasterSKU'           = $data.masterProfile.vmSize;
                    'MastervNET'          = if($data.masterProfile.subnetId){$data.masterProfile.subnetId.split("/")[8]};
                    'MasterSubnet'        = if($data.masterProfile.subnetId){$data.masterProfile.subnetId.split("/")[10]};                    
                    'WorkerSKU'           = $data.workerProfiles.vmSize | Select-Object -Unique;        
                    'WorkerDiskSize'      = $data.workerProfiles.diskSizeGB | Select-Object -Unique;        
                    'TotalWorkerNodes'   = $data.workerProfiles.count;        
                    'WorkervNET'          = $data.workerProfiles.subnetId | ForEach-Object { $_.split("/")[8] } | Select-Object -Unique; 
                    'WorkerSubnet'        = $data.workerProfiles.subnetId | ForEach-Object { $_.split("/")[10] } | Select-Object -Unique;       
                    'ResourceU'           = $ResUCount;
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 }               
            }
            $tmp
        }
}
Else {
    if ($SmaResources.ARO) {

        $TableName = ('AROTable_'+($SmaResources.ARO.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Clusters')         
        $Exc.Add('Location')             
        $Exc.Add('AROVersion')          
        $Exc.Add('ARODomain')           
        $Exc.Add('OutboundType')        
        $Exc.Add('IngressProfileName')
        $Exc.Add('IngressProfileType') 
        $Exc.Add('IngressProfileIP')   
        $Exc.Add('APIServerType')      
        $Exc.Add('APIServerURL')       
        $Exc.Add('APIServerIP')        
        $Exc.Add('DockerPodCidr')      
        $Exc.Add('ServiceCidr')         
        $Exc.Add('ConsoleURL')                
        $Exc.Add('MasterSKU')           
        $Exc.Add('MastervNET')          
        $Exc.Add('MasterSubnet')                     
        $Exc.Add('WorkerSKU')           
        $Exc.Add('WorkerDiskSize')        
        $Exc.Add('TotalWorkerNodes')   
        $Exc.Add('WorkervNET')          
        $Exc.Add('WorkerSubnet')

        $ExcelVar = $SmaResources.ARO 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'ARO' -AutoSize -TableName $TableName -MaxAutoSizeRows 100 -TableStyle $tableStyle -Numberformat '0' -Style $Style   
    }
}