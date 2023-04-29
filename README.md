# ASN 2 IP

## Description

This PowerShell script retrieves all the Autonomous System (AS) Numbers associated with an organization and then gets a deduplicated list of IPv4 and IPv6 subnets controlled by each AS number. Written in PWSH core, this script is cross compatable and works on both Linux and Windows machines provided they have PWSH core installed.

When the script is executed, it fetches AS Numbers associated with the specified organization (defaults to "microsoft"), retrieves the IP prefixes for each AS Number, deduplicates the IP prefixes, and writes the deduplicated IP prefixes to a file asn_ip_ranges.txt. It also generates analytics information, such as unique country codes, unique AS Numbers, unique names, unique descriptions, and unique prefix counts, and writes this information to the console and a file asn_analytics.txt.

```
Output Analytics....
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
UniqueCountryCodesCount: 4
UniqueASN: 3598,5761,6182,6584,8068,8069,8070,8071,8075,12076,13399,14271,14719,20046,23468,35106,45139,52985,395496,395524,395851,396463,398575,398656,400572
UniqueASNCount: 25
UniqueNames: AZURE-MICROSOFT-PEERING,MICROSOFT,Microsoft do Brasil Imp. e Com. Software e Video G,MICROSOFT-AS-AP,MICROSOFT-AZURE-DEDICATED,MICROSOFT-AZURE-DEDICATED,MICROSOFT-AZURE-ORBITAL,MICROSOFT-BOS,MICROSOFT-CORP-AS,MICROSOFT-CORP-AS-BLOCK-MSIT,MICROSOFT-CORP-AS-BLOCK-MSIT2,MICROSOFT-CORP-AS-BLOCK-MSIT3,MICROSOFT-CORP-AS-BLOCK-MSIT4,MICROSOFT-CORP-BCENTRAL,MICROSOFT-CORP-MSN-AS-2,MICROSOFT-CORP-MSN-AS-4,MICROSOFT-CORP-MSN-AS-BLOCK,MICROSOFT-CORP-MSN-AS-BLOCK,MICROSOFT-CORP-MSN-AS-BLOCK,MICROSOFT-CORP-MSN-AS-BLOCK,MICROSOFT-CORP-MSN-AS-BLOCK,MICROSOFT-CORP-MSN-AS-SATURN,MICROSOFT-CORP-XBOX-ONLINE,MICROSOFT-GP-AS,MICROSOFT-LIVE-MEETING
UniqueNamesCount: 20
UniqueDescriptions: Microsoft Corp,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation,Microsoft Corporation AS8075,Microsoft do Brasil Imp. e Com. Software e Video G,Proconex Inc.
UniqueDescriptionsCount: 5
UniquePrefixCount: 823
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

```

## Background

### What is an autonomous system number?

- An Autonomous System is a collection of connected Internet Protocol (IP) routing prefixes under the control of one or more network operators that presents a common, 
clearly defined routing policy to the internet.

- Each AS is assigned a unique ASN (Autonomous System Number), which is used to identify the AS and its associated routing policies.

- AS (Autonomous System) prefixes, also known as BGP (Border Gateway Protocol) prefixes, are blocks of IP addresses that are assigned to an Autonomous System.

## Usage

This script can be called directly using its built in defaults or its functions used in another script.

### To call directly

```powershell
powershell.exe .\ASN2IP.ps1 -ORGANIZATION_NAME "microsoft"
```

### To use functions in external script:

```powershell
. .\ASN2IP.ps1
$ASNumbers = Get-ASNInfo -ORGANIZATION_NAME $OrganizationName
$ASNPrefixes = $ASNumbers | Sort-Object | ForEach-Object { Get-ASNPrefixes -ASN $_ }
$ASNPrefixes | Sort-Object -Unique | Out-File -FilePath "asn_ip_ranges.txt" -Encoding utf8 -Force
```

## Functions

### Get-ASNInfo

Returns a list of strings representing all AS Numbers owned by an organization.
It queries the BGPView API to get the AS Numbers associated with the specified organization name.
Takes an optional param of {url} representing the organization name in a ARIN WHOIS record.
If no {url} param is provided, the organization name defaults to "microsoft".

```powershell
Get-ASNInfo -ORGANIZATION_NAME
```

### Get-ASNPrefixes

Returns a list of strings representing all IP prefixes of a provided AS number.
It queries the RIPE NCC API to get the announced prefixes for the given AS number.
Takes an mandatory param of {asn} representing an Autonomous System (AS) number.

```powershell
Get-ASNPrefixes -ASN
```


### Write-ASNAnalytics

Writes analytics to the console and as a text file named asn_analytics.txt.
Takes an mandatory param of {asn_prefixes} representing IP prefixes of one or many Autonomous System (AS) numbers.
This function also references a global variable called ```$env:ASN_ANALYTICS``` and as such cannot be called externally without also having first run the ```Get-ASNInfo``` function which will set the global variable.

```powershell
Write-ASNAnalytics
```


### Run

The main function that runs with default values or a provided organization name. It calls the other functions to retrieve AS Numbers, get the associated IP prefixes, and write the analytics information to the console and text files.

```powershell
Run -organizationName $ORGANIZATION_NAME
```

![ASN-2-IP_1](https://user-images.githubusercontent.com/6628565/233575960-5d92e9cb-8152-4056-9be1-99fedc6e5626.jpg)
![ASN-2-IP_2](https://user-images.githubusercontent.com/6628565/233574774-fdfeb143-8a32-4b40-9ac6-7cd1542ef6c4.jpg)
