param ($TenantID,
        $Appid,
        $SubscriptionID,
        $Secret, 
        $ResourceGroup, 
        [switch]$Online, 
        [switch]$Debug, 
        [switch]$SkipMetrics, 
        [switch]$Help,
        [switch]$Consumption,
        [switch]$DeviceLogin,
        $ConcurrencyLimit = 2,
        $AzureEnvironment,
        $ReportName = 'ResourcesReport', 
        $OutputDirectory)


if ($Debug.IsPresent) {$DebugPreference = 'Continue'}

if ($Debug.IsPresent) {$ErrorActionPreference = "Continue" }Else {$ErrorActionPreference = "silentlycontinue" }

Write-Debug ('Debbuging Mode: On. ErrorActionPreference was set to "Continue", every error will be presented.')

function Variables 
{
    $Global:ResourceContainers = @()
    $Global:Resources = @()
    $Global:Subscriptions = ''
    $Global:ReportName = $ReportName   

    if ($Online.IsPresent) { $Global:RunOnline = $true }else { $Global:RunOnline = $false }

    $Global:Repo = 'https://api.github.com/repos/stefoy/AriPlus/git/trees/main?recursive=1'
    $Global:RawRepo = 'https://raw.githubusercontent.com/stefoy/AriPlus/main'

    $Global:TableStyle = "Medium15"

    Write-Debug ('Checking if -Online parameter will have to be forced.')

    if(!$Online.IsPresent)
    {
        if($PSScriptRoot -like '*\*')
        {
            $LocalFilesValidation = New-Object System.IO.StreamReader($PSScriptRoot + '\Extension\Metrics.ps1')
        }
        else
        {
            $LocalFilesValidation = New-Object System.IO.StreamReader($PSScriptRoot + '/Extension/Metrics.ps1')
        } 

        if([string]::IsNullOrEmpty($LocalFilesValidation))
        {
            Write-Debug ('Using -Online by force.')
            $Global:RunOnline = $true
        }
        else
        {
            $Global:RunOnline = $false
        }
    }
}

Function RunInventorySetup()
{
    function CheckCliRequirements() 
    {
        Write-Host "Checking Cli Installed..."
        $azCliVersion = az --version
        Write-Host ('CLI Version: {0}' -f $azCliVersion[0]) -ForegroundColor Green
    
        if ($null -eq $azCliVersion) 
        {
            Read-Host "Azure CLI Not Found. Please install to and run the script again, press <Enter> to exit." -ForegroundColor Red
            Exit
        }
    
        Write-Host "Checking Cli Extension..."
        $azCliExtension = az extension list --output json | ConvertFrom-Json
        $azCliExtension = $azCliExtension | Where-Object {$_.name -eq 'resource-graph'}
    
        Write-Host ('Current Resource-Graph Extension Version: {0}' -f $azCliExtension.Version) -ForegroundColor Green
    
        $azCliExtensionVersion = $azcliExt | Where-Object {$_.name -eq 'resource-graph'}
    
        if (!$azCliExtensionVersion) 
        {
            Write-Host "Installng Az Cli Extension..."
            az extension add --name resource-graph
        }
        
        Write-Host "Checking ImportExcel Module..."
    
        $VarExcel = Get-InstalledModule -Name ImportExcel -ErrorAction silentlycontinue
    
        Write-Host ('ImportExcel Module Version: {0}.{1}.{2}' -f ([string]$VarExcel.Version.Major,  [string]$VarExcel.Version.Minor, [string]$VarExcel.Version.Build)) -ForegroundColor Green
    
        if ($null -eq $VarExcel) 
        {
            Write-Host "Trying to install ImportExcel Module.." -ForegroundColor Yellow
            Install-Module -Name ImportExcel -Force
        }
    
        $VarExcel = Get-InstalledModule -Name ImportExcel -ErrorAction silentlycontinue
    
        if ($null -eq $VarExcel) 
        {
            Read-Host 'Admininstrator rights required to install ImportExcel Module. Press <Enter> to finish script'
            Exit
        }
    }
    
    function CheckPowerShell() 
    {
        Write-Host 'Checking PowerShell...'
    
        $Global:PlatformOS = 'PowerShell Desktop'
        $cloudShell = try{Get-CloudDrive}catch{}

        $Global:CurrentDateTime = (get-date -Format "yyyyMMddHHmm")
        $Global:FolderName = $Global:ReportName + $CurrentDateTime
        
        if ($cloudShell) 
        {
            Write-Host 'Identified Environment as Azure CloudShell' -ForegroundColor Green
            $Global:PlatformOS = 'Azure CloudShell'
            $defaultOutputDir = "$HOME/AriPlusReports/" + $Global:FolderName + "/"
        }
        elseif ($PSVersionTable.Platform -eq 'Unix') 
        {
            Write-Host 'Identified Environment as PowerShell Unix.' -ForegroundColor Green
            $Global:PlatformOS = 'PowerShell Unix'
            $defaultOutputDir = "$HOME/AriPlusReports/" + $Global:FolderName + "/"
        }
        else 
        {
            Write-Host 'Identified Environment as PowerShell Desktop.' -ForegroundColor Green
            $Global:PlatformOS= 'PowerShell Desktop'
            $defaultOutputDir = "C:\AriPlusReports\" + $Global:FolderName + "\"
        }
    
        if ($OutputDirectory) 
        {
            try 
            {
                $OutputDirectory = Join-Path (Resolve-Path $OutputDirectory -ErrorAction Stop) ('/' -or '\')
            }
            catch 
            {
                Write-Host "ERROR: Wrong OutputDirectory Path! OutputDirectory Parameter must contain the full path." -NoNewline -ForegroundColor Red
                Exit
            }
        }
    
        $Global:DefaultPath = if($OutputDirectory) {$OutputDirectory} else {$defaultOutputDir}
    
        if ($platformOS -eq 'Azure CloudShell') 
        {
            $Global:Subscriptions = @(az account list --output json --only-show-errors | ConvertFrom-Json)
        }
        elseif ($platformOS -eq 'PowerShell Unix' -or $platformOS -eq 'PowerShell Desktop') 
        {
            LoginSession
        }
    }
    
    function LoginSession() 
    {
        Write-Debug ('Checking Login Session')
    
        if(![string]::IsNullOrEmpty($AzureEnvironment))
        {
            az cloud set --name $AzureEnvironment
        }
    
        $CloudEnv = az cloud list | ConvertFrom-Json
        Write-Host "Azure Cloud Environment: " -NoNewline
    
        $CurrentCloudEnvName = $CloudEnv | Where-Object {$_.isActive -eq 'True'}
        Write-Host $CurrentCloudEnvName.name -ForegroundColor Green
    
        if (!$TenantID) 
        {
            Write-Host "Tenant ID not specified. Use -TenantID parameter if you want to specify directly." -ForegroundColor Yellow
            Write-Host "Authenticating Azure"
    
            Write-Debug ('Cleaning az account cache')
            az account clear | Out-Null
            Write-Debug ('Calling az login')
    
            if($DeviceLogin.IsPresent)
            {
                az login --use-device-code
            }
            else 
            {
                az login --only-show-errors | Out-Null
            }
    
            $Tenants = az account list --query [].homeTenantId -o tsv --only-show-errors | Sort-Object -Unique
            Write-Debug ('Checking number of Tenants')
            Write-Host ("")
            Write-Host ("")
    
            if ($Tenants.Count -eq 1) 
            {
                Write-Host "You have privileges only in One Tenant " -ForegroundColor Green
                $TenantID = $Tenants
            }
            else 
            {
                Write-Host "Select the the Azure Tenant ID that you want to connect: "
    
                $SequenceID = 1
                foreach ($TenantID in $Tenants) 
                {
                    write-host "$SequenceID)  $TenantID"
                    $SequenceID ++
                }
    
                [int]$SelectTenant = read-host "Select Tenant (Default 1)"
                $defaultTenant = --$SelectTenant
                $TenantID = $Tenants[$defaultTenant]
    
                if($DeviceLogin.IsPresent)
                {
                    az login --use-device-code -t $TenantID
                }
                else 
                {
                    az login -t $TenantID --only-show-errors | Out-Null
                }
            }
    
            Write-Host "Extracting from Tenant $TenantID" -ForegroundColor Yellow
            Write-Debug ('Extracting Subscription details') 
    
            $Global:Subscriptions = @(az account list --output json --only-show-errors | ConvertFrom-Json)
            $Global:Subscriptions = @($Subscriptions | Where-Object { $_.tenantID -eq $TenantID })
        }
        else 
        {
            az account clear | Out-Null
    
            if (!$Appid) 
            {
                if($DeviceLogin.IsPresent)
                {
                    az login --use-device-code -t $TenantID
                }
                else 
                {
                    az login -t $TenantID --only-show-errors | Out-Null
                }
            }
            elseif ($Appid -and $Secret -and $tenantid) 
            {
                Write-Host "Using Service Principal Authentication Method" -ForegroundColor Green
                az login --service-principal -u $appid -p $secret -t $TenantID | Out-Null
            }
            else
            {
                Write-Host "You are trying to use Service Principal Authentication Method in a wrong way." -ForegroundColor Red
                Write-Host "It's Mandatory to specify Application ID, Secret and Tenant ID in Azure Resource Inventory" -ForegroundColor Red
                Write-Host ".\ResourceInventory.ps1 -appid <SP AppID> -secret <SP Secret> -tenant <TenantID>" -ForegroundColor Red
                Exit
            }
    
            $Global:Subscriptions = @(az account list --output json --only-show-errors | ConvertFrom-Json)
            $Global:Subscriptions = @($Subscriptions | Where-Object { $_.tenantID -eq $TenantID })
        }
    }
    
    function GetSubscriptionsData()
    {
        Write-Progress -activity 'Azure Inventory' -Status "1% Complete." -PercentComplete 2 -CurrentOperation 'Discovering Subscriptions..'
    
        $SubscriptionCount = $Subscriptions.Count
        
        Write-Debug ("Number of Subscriptions Found: {0}" -f $SubscriptionCount)
        Write-Progress -activity 'Azure Inventory' -Status "3% Complete." -PercentComplete 3 -CurrentOperation "$SubscriptionCount Subscriptions found.."
        
        Write-Debug ('Checking report folder: ' + $DefaultPath )
        
        if ((Test-Path -Path $DefaultPath -PathType Container) -eq $false) 
        {
            New-Item -Type Directory -Force -Path $DefaultPath | Out-Null
        }
    }
    
    function ResourceInventoryLoop()
    {
        Write-Progress -activity 'Azure Inventory' -Status "4% Complete." -PercentComplete 4 -CurrentOperation "Starting Resources extraction jobs.."        

        if(![string]::IsNullOrEmpty($ResourceGroup) -and [string]::IsNullOrEmpty($SubscriptionID))
        {
            Write-Debug ('Resource Group Name present, but missing Subscription ID.')
            Write-Host ''
            Write-Host 'If Using the -ResourceGroup Parameter, the Subscription ID must be informed'
            Write-Host ''
            Exit
        }

        if(![string]::IsNullOrEmpty($ResourceGroup) -and ![string]::IsNullOrEmpty($SubscriptionID))
        {
            Write-Debug ('Extracting Resources from Subscription: '+$SubscriptionID+'. And from Resource Group: '+$ResourceGroup)

            $Subscri = $SubscriptionID

            $GraphQuery = "resources | where resourceGroup == '$ResourceGroup' and strlen(properties.definition.actions) < 123000 | summarize count()"
            $EnvSize = az graph query -q $GraphQuery --subscriptions $Subscri --output json --only-show-errors | ConvertFrom-Json
            $EnvSizeNum = $EnvSize.data.'count_'

            if ($EnvSizeNum -ge 1) {
                $Loop = $EnvSizeNum / 1000
                $Loop = [math]::ceiling($Loop)
                $Looper = 0
                $Limit = 0

                while ($Looper -lt $Loop) {
                    $GraphQuery = "resources | where resourceGroup == '$ResourceGroup' and strlen(properties.definition.actions) < 123000 | project id,name,type,tenantId,kind,location,resourceGroup,subscriptionId,managedBy,sku,plan,properties,identity,zones,extendedLocation$($GraphQueryTags) | order by id asc"
                    $Resource = (az graph query -q $GraphQuery --subscriptions $Subscri --skip $Limit --first 1000 --output json --only-show-errors).tolower() | ConvertFrom-Json

                    $Global:Resources += $Resource.data
                    Start-Sleep 2
                    $Looper ++
                    Write-Progress -Id 1 -activity "Running Resource Inventory Job" -Status "$Looper / $Loop of Inventory Jobs" -PercentComplete (($Looper / $Loop) * 100)
                    $Limit = $Limit + 1000
                }
            }
            Write-Progress -Id 1 -activity "Running Resource Inventory Job" -Status "$Looper / $Loop of Inventory Jobs" -Completed
        }
        elseif([string]::IsNullOrEmpty($ResourceGroup) -and ![string]::IsNullOrEmpty($SubscriptionID))
        {
            Write-Debug ('Extracting Resources from Subscription: '+$SubscriptionID+'.')
            $GraphQuery = "resources | where strlen(properties.definition.actions) < 123000 | summarize count()"
            $EnvSize = az graph query -q $GraphQuery  --output json --subscriptions $SubscriptionID --only-show-errors | ConvertFrom-Json
            $EnvSizeNum = $EnvSize.data.'count_'

            if ($EnvSizeNum -ge 1) {
                $Loop = $EnvSizeNum / 1000
                $Loop = [math]::ceiling($Loop)
                $Looper = 0
                $Limit = 0

                while ($Looper -lt $Loop) {
                    $GraphQuery = "resources | where strlen(properties.definition.actions) < 123000 | project id,name,type,tenantId,kind,location,resourceGroup,subscriptionId,managedBy,sku,plan,properties,identity,zones,extendedLocation$($GraphQueryTags) | order by id asc"
                    $Resource = (az graph query -q $GraphQuery --subscriptions $SubscriptionID --skip $Limit --first 1000 --output json --only-show-errors).tolower() | ConvertFrom-Json

                    $Global:Resources += $Resource.data
                    Start-Sleep 2
                    $Looper ++
                    Write-Progress -Id 1 -activity "Running Resource Inventory Job" -Status "$Looper / $Loop of Inventory Jobs" -PercentComplete (($Looper / $Loop) * 100)
                    $Limit = $Limit + 1000
                }
            }
            Write-Progress -Id 1 -activity "Running Resource Inventory Job" -Status "$Looper / $Loop of Inventory Jobs" -Completed
        } 
        else 
        {
            $GraphQuery = "resources | where strlen(properties.definition.actions) < 123000 | summarize count()"
            $EnvSize = az graph query -q  $GraphQuery --output json --only-show-errors | ConvertFrom-Json
            $EnvSizeCount = $EnvSize.Data.'count_'
            
            Write-Host ("Resources Output: {0} Resources Identified" -f $EnvSizeCount) -BackgroundColor Black -ForegroundColor Green
            
            if ($EnvSizeCount -ge 1) 
            {
                $Loop = $EnvSizeCount / 1000
                $Loop = [math]::Ceiling($Loop)
                $Looper = 0
                $Limit = 0
            
                while ($Looper -lt $Loop) 
                {
                    $GraphQuery = "resources | where strlen(properties.definition.actions) < 123000 | project id,name,type,tenantId,kind,location,resourceGroup,subscriptionId,managedBy,sku,plan,properties,identity,zones,extendedLocation | order by id asc"
                    $Resource = (az graph query -q $GraphQuery --skip $Limit --first 1000 --output json --only-show-errors).tolower() | ConvertFrom-Json
                    
                    $Global:Resources += $Resource.Data
                    Start-Sleep 2
                    $Looper++
                    Write-Progress -Id 1 -activity "Running Resource Inventory Job" -Status "$Looper / $Loop of Inventory Jobs" -PercentComplete (($Looper / $Loop) * 100)
                    $Limit = $Limit + 1000
                }
            }

            Write-Progress -Id 1 -activity "Running Resource Inventory Job" -Status "$Looper / $Loop of Inventory Jobs" -Completed
        }
    }
    
    function ResourceInventoryAvd()
    {
        Write-Progress -activity 'Azure Inventory' -Status "4% Complete." -PercentComplete 4 -CurrentOperation "Starting AVD Resources extraction jobs.."       
    
        $AVDSize = az graph query -q "desktopvirtualizationresources | summarize count()" --output json --only-show-errors | ConvertFrom-Json
        $AVDSizeCount = $AVDSize.data.'count_'
    
        Write-Host ("AVD Resources Output: {0} AVD Resources Identified" -f $AVDSizeCount) -BackgroundColor Black -ForegroundColor Green
    
        if ($AVDSizeCount -ge 1) 
        {
            $Loop = $AVDSizeCount / 1000
            $Loop = [math]::ceiling($Loop)
            $Looper = 0
            $Limit = 0
    
            while ($Looper -lt $Loop) 
            {
                $GraphQuery = "desktopvirtualizationresources | project id,name,type,tenantId,kind,location,resourceGroup,subscriptionId,managedBy,sku,plan,properties,identity,zones,extendedLocation$($GraphQueryTags) | order by id asc"
                $AVD = (az graph query -q $GraphQuery --skip $Limit --first 1000 --output json --only-show-errors).tolower() | ConvertFrom-Json
    
                $Global:Resources += $AVD.data
                Start-Sleep 2
                $Looper++
                Write-Progress -Id 1 -activity "Running AVD Resource Inventory Job" -Status "$Looper / $Loop of Inventory Jobs" -PercentComplete (($Looper / $Loop) * 100)
                $Limit = $Limit + 1000
            }
        }
    
        Write-Progress -Id 1 -activity "Running AVD Resource Inventory Job" -Status "$Looper / $Loop of Inventory Jobs" -Completed
    }

    CheckCliRequirements
    CheckPowerShell
    GetSubscriptionsData
    ResourceInventoryLoop
    ResourceInventoryAvd
}

function ExecuteInventoryProcessing()
{
    function InitializeInventoryProcessing()
    {   
        $Global:ZipOutputFile = ($DefaultPath + $Global:ReportName + "_" + $CurrentDateTime + ".zip")
        $Global:File = ($DefaultPath + $Global:ReportName + "_" + $CurrentDateTime + ".xlsx")
        $Global:AllResourceFile = ($DefaultPath + "Full_" + $Global:ReportName + "_" + $CurrentDateTime + ".json")
        $Global:JsonFile = ($DefaultPath + "Inventory_"+ $Global:ReportName + "_" + $CurrentDateTime + ".json")
        $Global:MetricsJsonFile = ($DefaultPath + "Metrics_"+ $Global:ReportName + "_" + $CurrentDateTime + ".json")
                
        Write-Debug ('Report Excel File: {0}' -f $File)
        Write-Progress -activity 'Inventory' -Status "21% Complete." -PercentComplete 21 -CurrentOperation "Starting to process extraction data.."
    }

    function CreateMetricsJob()
    {
        Write-Debug ('Checking if Metrics Job Should be Run.')

        if (!$SkipMetrics.IsPresent) 
        {
            Write-Debug ('Starting Metrics Processing Job.')

            If ($RunOnline -eq $true) 
            {
                Write-Debug ('Looking for the following file: '+$RawRepo + '/Extension/Metrics.ps1')
                $ModuSeq = (New-Object System.Net.WebClient).DownloadString($RawRepo + '/Extension/Metrics.ps1')

                Write-Debug(($PSScriptRoot + '\Extension\Metrics.ps1'))

                if($PSScriptRoot -like '*\*')
                {
                    if (!(Test-Path -Path ($PSScriptRoot + '\Extension\')))
                    {
                        New-Item -Path ($PSScriptRoot + '\Extension\') -ItemType Directory
                    }
                    
                    $ModuSeq | Out-File ($PSScriptRoot + '\Extension\Metrics.ps1') 
                }
                else
                {
                    if (!(Test-Path -Path ($PSScriptRoot + '/Extension/')))
                    {
                        New-Item -Path ($PSScriptRoot + '/Extension/') -ItemType Directory
                    }
                    
                    $ModuSeq | Out-File ($PSScriptRoot + '/Extension/Metrics.ps1')
                }
            }

            if($PSScriptRoot -like '*\*')
            {
                $MetricPath = Get-ChildItem -Path ($PSScriptRoot + '\Extension\Metrics.ps1') -Recurse
            }
            else
            {
                $MetricPath = Get-ChildItem -Path ($PSScriptRoot + '/Extension/Metrics.ps1') -Recurse
            }
            
            $Global:AzMetrics = New-Object PSObject
            $Global:AzMetrics | Add-Member -MemberType NoteProperty -Name Metrics -Value NotSet
            $Global:AzMetrics.Metrics = & $MetricPath -Subscriptions $Subscriptions -Resources $Resources -Task "Processing" -File $file -Metrics $null -TableStyle $null -ConcurrencyLimit $ConcurrencyLimit
        }
    }

    function ProcessMetricsResult()
    {
        if (!$SkipMetrics.IsPresent) 
        {
            Write-Debug ('Generating Subscription Metrics Outputs.')
            Write-Progress -activity 'Resource Inventory Metrics' -Status "50% Complete." -PercentComplete 50 -CurrentOperation "Building Metrics Outputs"

            $Global:AzMetrics | ConvertTo-Json -depth 100 -compress | Out-File $Global:MetricsJsonFile
    
            if($PSScriptRoot -like '*\*')
            {
                $MetricPath = Get-ChildItem -Path ($PSScriptRoot + '\Extension\Metrics.ps1') -Recurse
            }
            else
            {
                $MetricPath = Get-ChildItem -Path ($PSScriptRoot + '/Extension/Metrics.ps1') -Recurse
            }

            $ProcessResults = & $MetricPath -Subscriptions $null -Resources $null -Task "Reporting" -File $file -Metrics $Global:AzMetrics -TableStyle $Global:TableStyle
        }
    }

    function CreateResourceJobs()
    {
        $Global:SmaResources = New-Object PSObject

        Write-Debug ('Starting Service Processing Jobs.')

        If ($RunOnline -eq $true) 
        {
            Write-Debug ('Running Online Checking for Services Modules at: ' + $RawRepo)

            $OnlineRepo = Invoke-WebRequest -Uri $Repo
            $RepoContent = $OnlineRepo | ConvertFrom-Json
            $ModuleUrls = ($RepoContent.tree | Where-Object {$_.path -like '*.ps1' -and $_.path -notlike 'Extension/*' -and $_.path -ne 'ResourceInventory.ps1'}).path

            if($PSScriptRoot -like '*\*')
            {
                if (!(Test-Path -Path ($PSScriptRoot + '\Services\')))
                {
                    New-Item -Path ($PSScriptRoot + '\Services\') -ItemType Directory
                }
            }
            else
            {
                if (!(Test-Path -Path ($PSScriptRoot + '/Services/')))
                {
                    New-Item -Path ($PSScriptRoot + '/Services/') -ItemType Directory
                }
            }

            foreach ($moduleUrl in $moduleUrls)
            {
                $ModuleContent = (New-Object System.Net.WebClient).DownloadString($RawRepo + '/' + $moduleUrl)
                $ModuleFileName = [System.IO.Path]::GetFileName($moduleUrl)

                if($PSScriptRoot -like '*\*')
                {
                    $ModuleContent | Out-File ($PSScriptRoot + '\Services\' + $ModuleFileName) 
                }
                else
                {
                    $ModuleContent | Out-File ($PSScriptRoot + '/Services/' + $ModuleFileName) 
                }
            }
        }

        if($PSScriptRoot -like '*\*')
        {
            $Modules = Get-ChildItem -Path ($PSScriptRoot +  '\Services\*.ps1') -Recurse
        }
        else
        {
            $Modules = Get-ChildItem -Path ($PSScriptRoot +  '/Services/*.ps1') -Recurse
        }

        $Resource = $Resources | Select-Object -First $Resources.count
        $Resource = ($Resource | ConvertTo-Json -Depth 50)

        foreach ($Module in $Modules) 
        {
            $ModName = $Module.Name.Substring(0, $Module.Name.length - ".ps1".length)
            
            Write-Host ("Service Processing: {0} {1}" -f $Module, $ModName) -ForegroundColor Green
            $result = & $Module -SCPath $SCPath -Sub $Subscriptions -Resources ($Resource | ConvertFrom-Json) -Task "Processing" -File $file -SmaResources $null -TableStyle $null -Metrics $Global:AzMetrics
            $Global:SmaResources | Add-Member -MemberType NoteProperty -Name $ModName -Value NotSet
            $Global:SmaResources.$ModName = $result

            $result = $null
            [System.GC]::Collect()
        }
    }

    function ProcessResourceResult()
    {
        Write-Debug ('Starting Reporting Phase.')
        $DataActive = ('Azure Resource Inventory Reporting (' + ($resources.count) + ') Resources')
        Write-Progress -activity $DataActive -Status "Processing Inventory" -PercentComplete 50

        $Services = @()

        if($PSScriptRoot -like '*\*')
        {
            $Services = Get-ChildItem -Path ($PSScriptRoot + '\Services\*.ps1') -Recurse
        }
        else
        {
            $Services = Get-ChildItem -Path ($PSScriptRoot + '/Services/*.ps1') -Recurse
        }

        Write-Debug ('Services Found: ' + $Services.Count)
        $Lops = $Services.count
        $ReportCounter = 0

        foreach ($Service in $Services) 
        {
            $c = (($ReportCounter / $Lops) * 100)
            $c = [math]::Round($c)
            Write-Progress -Id 1 -activity "Building Report" -Status "$c% Complete." -PercentComplete $c

            Write-Debug "Running Services: '$Service'"
            
            $ProcessResults = & $Service.FullName -SCPath $PSScriptRoot -Sub $null -Resources $null -Task "Reporting" -File $file -SmaResources $Global:SmaResources -TableStyle $Global:TableStyle -Metrics $null

            $ReportCounter++
        }

        $Global:SmaResources | ConvertTo-Json -depth 100 -compress | Out-File $Global:JsonFile
        #$Global:Resources | ConvertTo-Json -depth 100 -compress | Out-File $Global:AllResourceFile
        
        Write-Debug ('Resource Reporting Phase Done.')
    }

    function ProcessSummary()
    {
        Write-Debug ('Creating Summary Report')

        if (!$SkipMetrics.IsPresent) 
        {
            Write-Debug ('Starting Summary Report Processing Job.')

            If ($RunOnline -eq $true) 
            {
                Write-Debug ('Looking for the following file: '+$RawRepo + '/Extension/Summary.ps1')
                $ModuSeq = (New-Object System.Net.WebClient).DownloadString($RawRepo + '/Extension/Summary.ps1')

                Write-Debug(($PSScriptRoot + '\Extension\Summary.ps1'))

                if($PSScriptRoot -like '*\*')
                {
                    $ModuSeq | Out-File ($PSScriptRoot + '\Extension\Summary.ps1') 
                }
                else
                {
                    $ModuSeq | Out-File ($PSScriptRoot + '/Extension/Summary.ps1')
                }
            }

            if($PSScriptRoot -like '*\*')
            {
                $MetricPath = Get-ChildItem -Path ($PSScriptRoot + '\Extension\Summary.ps1') -Recurse
            }
            else
            {
                $MetricPath = Get-ChildItem -Path ($PSScriptRoot + '/Extension/Summary.ps1') -Recurse
            }

            $ChartsRun = & $MetricPath -File $file -TableStyle $TableStyle -PlatOS $PlatformOS -Subscriptions $Subscriptions -Resources $Resources -ExtractionRunTime $Runtime -ReportingRunTime $ReportingRunTime -RunLite $false
        }
    }

    function ProcessConsumption()
    {
        if ($Consumption.IsPresent)
        {
            $Global:ConsumptionData = New-Object PSObject
            $Global:ConsumptionData | Add-Member -MemberType NoteProperty -Name Consumption -Value NotSet

            Write-Host ("Gathering Consumption Data") -BackgroundColor Black -ForegroundColor Green

            $Consumption = (az consumption usage list --include-meter-details --only-show-errors --output json --query "[].{id: instanceId, service: meterDetails.serviceName, meter: meterId, product: product, quantity: usageQuantity, cost: pretaxCost}") | ConvertFrom-Json

            $tmpConsumption = [System.Collections.Generic.List[psobject]]::new()

            $Consumption = $Consumption | Group-Object -Property id | ForEach-Object {
                $Id = $_.Name
                $Service = $_.Group[0].service
                $GroupedByMeter = $_.Group | Group-Object -Property meter

                $tmpMeters = [System.Collections.Generic.List[psobject]]::new()

                $GroupedByMeter | ForEach-Object {
                    $MeterId = $_.Name
                    $TotalQuantity = ($_.Group | Measure-Object -Property quantity -Sum).Sum
                    $TotalCost = ($_.Group | Measure-Object -Property cost -Sum).Sum

                    $MeterObject = [PSCustomObject]@{
                        MeterId = $MeterId
                        Product = $_.Group[0].product
                        Quantity = $TotalQuantity.ToString("0.#########")
                        Cost = $TotalCost.ToString("0.#########")
                    }

                    $tmpMeters.Add($MeterObject)
                }

                $InstanceObject = [PSCustomObject]@{
                    InstanceId = $Id
                    Service = $Service
                    Meters = $tmpMeters
                }

                $tmpConsumption.Add($InstanceObject)
            }

            $ConsumptionData.Consumption = $tmpConsumption

            $ConsumptionFile = ($DefaultPath + "Consumption_" + $Global:ReportName + "_" + $CurrentDateTime + ".json")
            $ConsumptionData | ConvertTo-Json -depth 100 -compress | Out-File $ConsumptionFile
            
            Write-Host ("Exported Consumption Data to {0}" -f $ConsumptionFile) -BackgroundColor Black -ForegroundColor Green
        }
    }

    InitializeInventoryProcessing
    CreateMetricsJob
    CreateResourceJobs   
    ProcessMetricsResult
    ProcessResourceResult
    ProcessConsumption
}


$Global:Runtime = Measure-Command -Expression {
    Variables
    RunInventorySetup
}

$Global:ReportingRunTime = Measure-Command -Expression {
    ExecuteInventoryProcessing
}

ProcessSummary

Write-Host ("Compressing Resources Output: {0}" -f $Global:ZipOutputFile) -ForegroundColor Yellow

$compressionOutput = @{
  Path = $Global:File, $Global:MetricsJsonFile, $Global:JsonFile
  CompressionLevel = "Optimal"
  DestinationPath = $Global:ZipOutputFile
}

Compress-Archive @compressionOutput

Write-Host ("Execution Time: {0}" -f $Runtime) -ForegroundColor Cyan
Write-Host ("Reporting Time: {0}" -f $ReportingRunTime) -ForegroundColor Cyan
Write-Host ("Reporting Data File: {0}" -f $Global:ZipOutputFile) -ForegroundColor Cyan
