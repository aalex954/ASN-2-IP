# Finds all AS numbers associated with an organization name and returns a deduplicated list of IPv4 and IPv6 subnets owned controlled by each AS number in a text file called asn_ip_ranges.txt
param([string]$ORGANIZATION_NAME="microsoft") 

<#
.SYNOPSIS
Returns a list of strings representing all AS Numbers owned by an organization.
It queries the BGPView API to get the AS Numbers associated with the specified organization name.
Takes an optional param of {url} representing the organization name in a ARIN WHOIS record.
If no {url} param is provided, the organization name defaults to "microsoft".
#>
function Get-ASNInfo {
    param (
        [switch]$Passthru,
        [Parameter(Position = 0, Mandatory = $true)]
        $ORGANIZATION_NAME
    )
    $url = "https://api.bgpview.io/search?query_term=$ORGANIZATION_NAME"
    $response = Invoke-RestMethod -Uri $url -Method Get
    Write-Host "Getting AS Numbers........." -NoNewline -ForegroundColor Yellow

    if ($response.status -eq "ok") {
        $asnInfo = $response
        #$asnInfo = Get-Content .\msft_asns_bgpview.json -Raw | ConvertFrom-Json
        $asns = $AsnInfo.data.asns
        $asnValues = @()
        $data = @("Name,CountryCode,Description,ASN")
        foreach ($asn in $asns) {
            $asnValues += $asn | Select-Object asn | Select-Object -ExpandProperty asn
            $data += "$($asn.name -replace ","),$($asn.country_code -replace ","),$($asn.description -replace ","),$($asn | Select-Object asn | Select-Object -ExpandProperty asn)"
        }
        Set-Variable -Name ASN_ANALYTICS -Value @("Name,CountryCode,Description,ASN") -Scope global
        Set-Variable -Name ASN_ANALYTICS -Value $data -Scope global

        $okFormatted = "{0,-8}" -f "Ok"
        $asnsCountFormatted = "{0,4}" -f $asns.Count
        
        Write-Host $okFormatted -NoNewline -ForegroundColor Green
        Write-Host "(" -NoNewline -ForegroundColor Yellow
        Write-Host $asnsCountFormatted -NoNewline -ForegroundColor Green
        Write-Host ")" -ForegroundColor Yellow
    }
    else { Write-Host "Error: $($response.status) - $($response.status_message)" -ForegroundColor Red }
    return $asnValues | Sort-Object
}

<#
.SYNOPSIS
Returns a list of strings representing all IP prefixes of a provided AS number. 
It queries the RIPE NCC API to get the announced prefixes for the given AS number.
Takes an mandatory param of {asn} representing an Autonomous System (AS) number.
#>
function Get-ASNPrefixes {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        $ASN
    )
    $url = "https://stat.ripe.net/data/announced-prefixes/data.json?resource=$ASN"
    $response = Invoke-RestMethod -Uri $url -Method Get

    Write-Host "Getting AS Prefixes for...." -NoNewline -ForegroundColor Yellow

    if ($response.status -eq "ok") {
        $asnPrefixInfo = $response
        #$asnPrefixInfo = Get-Content .\ripe_prefix.json -Raw | ConvertFrom-Json
        $prefixes = $asnPrefixInfo.data.prefixes
        $prefixValues = @()

        foreach ($prefix in $prefixes) { $prefixValues += $prefix.prefix}
    }
    else { Write-Host "Error: $($response.status) - $($response.status_message)" -ForegroundColor Red }


    $y = if ($null -eq $prefixValues[-1]) {0} else { $prefixValues[-1].ToString().Length }
    $z = if ($prefixValues[-1] -eq $null) { '0' } else { $prefixValues[-1].ToString().Length }
    
    $ASNFormatted = "{0,-8}" -f $ASN
    $prefixCountFormatted = "{0,4}" -f $prefixValues.Count
    
    Write-Host "$ASNFormatted" -noNewLine -ForegroundColor Green
    Write-Host "(" -NoNewline -ForegroundColor Yellow
    Write-Host $prefixCountFormatted -NoNewline -ForegroundColor Green
    Write-Host ")" -ForegroundColor Yellow
    return $prefixValues
}

<#
.SYNOPSIS
Writes analytics to the console and as a text file named asn_analytics.txt.
Takes an mandatory param of {asn_prefixes} representing IP prefixes of one or many Autonomous System (AS) numbers.
#>
function Write-ASNAnalytics {
    param (
        # [Parameter(Mandatory = $true)]
        # $asn_analytics,
        [Parameter(Mandatory = $true)]
        $ASN_PREFIXES
    )
    $asn_analytics = $global:ASN_ANALYTICS

    $UniqueCountryCodesCount = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object CountryCode | Select-Object -ExpandProperty CountryCode | Sort-Object -Unique).count
    $UniqueASN = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object ASN | Select-Object -ExpandProperty ASN | Sort-Object { [int]$_ }) -join ','
    $UniqueASNCount = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object ASN | Select-Object -ExpandProperty ASN | Sort-Object -Unique).count
    $UniqueNames = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object Name | Select-Object -ExpandProperty Name | Sort-Object) -join ','
    $UniqueNamesCount = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object Name | Select-Object -ExpandProperty Name | Sort-Object -Unique).count
    $UniqueDescriptions = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object Description | Select-Object -ExpandProperty Description | Sort-Object) -join ','
    $UniqueDescriptionsCount = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object Description | Select-Object -ExpandProperty Description | Sort-Object -Unique).count

    $UniquePrefixCount = ($ASN_PREFIXES | Get-Unique | Measure-Object).Count
    Write-Host ([string]::new('-' * ($host.UI.RawUI.BufferSize.Width - 1)))
    Write-Host "UniqueCountryCodesCount: $UniqueCountryCodesCount"

    Write-Host "UniqueASN: " -NoNewline -ForegroundColor Yellow
    Write-Host $UniqueASN
    Write-Host "UniqueASNCount: " -NoNewline -ForegroundColor Yellow
    Write-Host $UniqueASNCount
    Write-Host "UniqueNames: " -NoNewline -ForegroundColor Yellow
    Write-Host $UniqueNames
    Write-Host "UniqueNamesCount: " -NoNewline -ForegroundColor Yellow
    Write-Host $UniqueNamesCount
    Write-Host "UniqueDescriptions: " -NoNewline -ForegroundColor Yellow
    Write-Host $UniqueDescriptions
    Write-Host "UniqueDescriptionsCount: " -NoNewline -ForegroundColor Yellow
    Write-Host $UniqueDescriptionsCount
    #Write-Host "UniquePrefixes: $UniquePrefixes"
    Write-Host "UniquePrefixCount: " -NoNewline -ForegroundColor Yellow
    Write-Host $UniquePrefixCount
    Write-Host ([string]::new('-' * ($host.UI.RawUI.BufferSize.Width - 1)))

    $output = "
UniqueCountryCodesCount: $UniqueCountryCodesCount`n
UniqueASN: $UniqueASN`n
UniqueASNCount: $UniqueASNCount`n
UniqueNamesCount: $UniqueNamesCount`n
UniqueDescriptions: $UniqueDescriptions`n
UniqueDescriptionsCount: $UniqueDescriptionsCount`n
UniquePrefixes: UniquePrefixes`n
UniquePrefixCount $UniquePrefixCount`n
"
    Write-Host "Exporting to: $PWD\asn_analytics.txt" -ForegroundColor Yellow

    $output | Out-File -FilePath "$PWD\asn_analytics.txt" -Encoding utf8 -Force
}

<#
.SYNOPSIS
Runs with default vaules
#>
function Run {
    param (
        [Parameter(Mandatory = $false)]
        $organizationName = "microsoft"
    )
    $ASNumbers = Get-ASNInfo -ORGANIZATION_NAME $organizationName
    $ASNPrefixes = @()
    $ASNPrefixes = $ASNumbers | Sort-Object | ForEach-Object { Get-ASNPrefixes -asn $_ } 

    $DeduplicatedASNPrefixes = $ASNPrefixes | Sort-Object -Unique
    if ($ASNPrefixes.Count -ne $DeduplicatedASNPrefixes.Count) {
        Write-Host "WARNING: $($ASNPrefixes.Count - $DeduplicatedASNPrefixes.Count) duplicate prefixes detected" -ForegroundColor Red
        Write-Host "This can occur due to various reasons, such as misconfiguration, lack of coordination, or even malicious intent (e.g., BGP hijacking)" -ForegroundColor Red
    }

    Write-Host "`nExporting deduplicated ASN Prefixes to: " -NoNewline -ForegroundColor Green
    Write-Host "$(Get-Location) asn_ip_ranges.txt" -ForegroundColor Green
    $ASNPrefixes | Sort-Object -Unique | Out-File -FilePath "asn_ip_ranges.txt" -Encoding utf8 -Force

    Write-Host "Output Analytics...." -ForegroundColor Yellow
    Write-ASNAnalytics -asn_prefixes $ASNPrefixes
}
# -------------------------------------------------------------------------------------------------------
Run -organizationName $ORGANIZATION_NAME