# AriPlus

AriPlus is an enhanced version of the [Azure Resource Inventory](https://github.com/microsoft/ARI) (ARI) tool. ARI is a robust PowerShell script provided by Microsoft that generates an Excel report of any Azure environment to which you have read access. This tool aims to assist Cloud Administrators and other professionals in creating a comprehensive Excel report of an Azure Environment quickly and easily. AriPlus enhances the original script by capturing additional utilization metrics.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the Script](#running-the-script)
- [Acknowledgments](#acknowledgments)

## Prerequisites

AriPlus can be executed in both Azure Cloudshell and PowerShell Desktop environments. 

### Requirements
> **Note:** By default, Azure Resource Inventory will attempt to install the necessary PowerShell modules and Azure CLI components, but you need administrator privileges during the script execution.


- PowerShell 7 or Azure CloudShell
- Azure CLI
- Azure CLI Account Extension
- Azure CLI Resource-Graph Extension


### Dependencies

Install the required PowerShell module:

```powershell
Install-Module ImportExcel
```

## Installation

1. Clone the repository or download the `ResourceInventory.ps1` script.

```bash
git clone https://github.com/stefoy/AriPlus
```

2. Run the script. If you are in Azure CloudShell, you're already authenticated. In PowerShell Desktop, you will be redirected to the Azure sign-in page.

```powershell
./ResourceInventory.ps1 -Online
```

## Running the Script

AriPlus uses concurrency to execute commands in parallel, especially when gathering metrics. By default, the concurrency limit is set to 6. To change this, use the `-ConcurrencyLimit` option. 

The `-Online` option fetches the latest modules from GitHub, meaning you only need to download the `ResourceInventory.ps1`.

Example:

```powershell
./ResourceInventory.ps1 -Online -ConcurrencyLimit 8
```
---

## Parameters

The following table lists the parameters that can be used with the script:

| Parameter         | Type     | Description                                                                                                     |
|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `$TenantID`       | String   | Specifies the Tenant ID you want to create a Resource Inventory                                                                                       |
| `$Appid`          | String   | Service Principal Authentication ID.                                                                                   |
| `$SubscriptionID` | String   | Specifies the Subscription which will be run for Inventory.                                                                                  |
| `$Secret`         | String   | Client Secret of the Service Principal key.                                                                                       |
| `$ResourceGroup`  | String   | Specifies the Resource Group.                                                                                   |
| `$Online`         | Switch   | A switch to indicate if online mode is used.                                                                    |
| `$Debug`          | Switch   | Enable Debug Mode                                                                                  |
| `$SkipMetrics`    | Switch   | A switch to skip metrics retrieval.                                                                             |
| `$Help`           | Switch   | A switch to display the help message.                                                                           |
| `$Consumption`    | Switch   | A switch to indicate if consumption metrics should be gathered.                                                |
| `$DeviceLogin`    | Switch   | A switch to trigger device login.                                                                               |
| `$ConcurrencyLimit` | Integer | Specifies the concurrency limit for parallel command execution. Default value is `6`.                            |

---
## ⚠️ Warning Messages

- **Important:** Azure Resource Inventory will not upgrade the current version of the Powershell modules.
  
- **Important:** If you're running the script inside Azure CloudShell, the final Excel will not have auto-fit columns, and you will see warnings during the script execution. This is an issue with the Import-Excel module but it does not affect the inventory which will remain accurate.

---

## Acknowledgments

Special thanks to Doug Finke, the author of the PowerShell ImportExcel Module. 
© 2023 AriPlus Contributors. All rights reserved.

---
