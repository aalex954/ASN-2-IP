# Finds all AS numbers associated with an organization name and returns a deduplicated list of IPv4 and IPv6 subnets owned controlled by each AS number in a text file called asn_ip_ranges.txt
param([string]$ORGANIZATION_NAME="microsoft") 

<#
.SYNOPSIS
Returns a list of strings representing all AS Numbers owned by an organization.
It queries the BGPView API to get the AS Numbers associated with the specified organization name.
Takes an optional param of {url} representing the organization name in a ARIN WHOIS record.
If no {url} param is provided, the organization name defaults to "microsoft".
#>
function Global:Get-ASNInfo {
    param (
        [switch]$Passthru,
        [Parameter(Position = 0, Mandatory = $true)]
        $ORGANIZATION_NAME
    )
    $url = "https://api.bgpview.io/search?query_term=$ORGANIZATION_NAME"
    try {
        $response = (Invoke-WebRequest -Uri $url -Method Get)
        $responseContent = ($response).Content
    } catch {
        Write-Host "Request Error: Failed to retrieve information for $ORGANIZATION_NAME" -ForegroundColor Red
        return
    }
    Write-Host "Getting AS Numbers........." -NoNewline -ForegroundColor Yellow

    if ($response.StatusCode -eq "200") {
        $asnInfo = ConvertFrom-Json $responseContent
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
    else { Write-Host "Function Error: $($response.status) - $($response.status_message)" -ForegroundColor Red; return }
    return $asnValues | Sort-Object
}


<#
.SYNOPSIS
Returns a list of strings representing all IP prefixes of a provided AS number. 
It queries the RIPE NCC API to get the announced prefixes for the given AS number.
Takes an mandatory param of {asn} representing an Autonomous System (AS) number.
#>
function Global:Get-ASNPrefixes {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        $ASN
    )
    $url = "https://stat.ripe.net/data/announced-prefixes/data.json?resource=$ASN"
    try {
        $response = Invoke-WebRequest -Uri $url -Method Get | Select-Object -ExpandProperty Content
    } catch {
        Write-Error "Error: Failed to get response from $url"
        throw
    }

    Write-Host "Getting AS Prefixes for...." -NoNewline -ForegroundColor Yellow

    $asnPrefixInfo = $response | ConvertFrom-Json

    if ($asnPrefixInfo.status -eq "ok") {
        $prefixes = $asnPrefixInfo.data.prefixes
        $prefixValues = @()

        foreach ($prefix in $prefixes) { $prefixValues += $prefix.prefix}
    }
    else { 
        Write-Host "Error: $($asnPrefixInfo.status) - $($asnPrefixInfo.status_message)" -ForegroundColor Red 
        throw "Failed to get prefixes for ASN $ASN"
    }


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
        [Parameter(Mandatory = $true)]
        $ASN_PREFIXES
    )

    $UniqueCountryCodesCount = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object CountryCode | Select-Object -ExpandProperty CountryCode | Sort-Object -Unique).count
    $UniqueASN = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object ASN | Select-Object -ExpandProperty ASN | Sort-Object { [int]$_ }) -join ','
    $UniqueASNCount = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object ASN | Select-Object -ExpandProperty ASN | Sort-Object -Unique).count
    $UniqueNames = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object Name | Select-Object -ExpandProperty Name | Sort-Object) -join ','
    $UniqueNamesCount = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object Name | Select-Object -ExpandProperty Name | Sort-Object -Unique).count
    $UniqueDescriptions = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object Description | Select-Object -ExpandProperty Description | Sort-Object) -join ','
    $UniqueDescriptionsCount = ($global:asn_analytics | ConvertFrom-Csv -Delimiter ',' | Select-Object Description | Select-Object -ExpandProperty Description | Sort-Object -Unique).count
    $UniquePrefixCount = ($ASN_PREFIXES | Get-Unique | Measure-Object).Count

    Write-Host ([string]::new('-' * ($host.UI.RawUI.BufferSize.Width - 1)))
    Write-Host "UniqueCountryCodesCount: " -NoNewline -ForegroundColor Yellow
    Write-Host $UniqueCountryCodesCount
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
    Write-Host "Exporting to: $PWD\asn_analytics.txt" -ForegroundColor Green

    $output | Set-Content "$PWD\asn_analytics.txt"
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
    try {
        $ASNumbers = Get-ASNInfo -ORGANIZATION_NAME $organizationName
        $ASNPrefixes = @()
        $ASNumbers | Sort-Object | ForEach-Object { 
            try {
                $ASNPrefixes += Get-ASNPrefixes -asn $_ 
            }
            catch {
                Write-Host "Failed to get prefixes for ASN $_. Error message: $($_.Exception.Message)" -ForegroundColor Red
                exit 1
            }
        }
        $DeduplicatedASNPrefixes = $ASNPrefixes | Sort-Object -Unique
        if ($ASNPrefixes.Count -ne $DeduplicatedASNPrefixes.Count) {
            Write-Host "WARNING: $($ASNPrefixes.Count - $DeduplicatedASNPrefixes.Count) duplicate prefixes detected" -ForegroundColor Red
            Write-Host "This can occur due to various reasons, such as misconfiguration, lack of coordination, or even malicious intent (e.g., BGP hijacking)" -ForegroundColor Red
        }

        Write-Host "`nExporting deduplicated ASN Prefixes to: " -ForegroundColor Green
        Write-Host "$(Get-Location) asn_ip_ranges.txt" -ForegroundColor Green
        $ASNPrefixes | Sort-Object -Unique | Set-Content  "asn_ip_ranges.txt"

        Write-Host "Output Analytics...." -ForegroundColor Yellow
        Write-ASNAnalytics -asn_prefixes $ASNPrefixes
    }
    catch {
        Write-Host "Failed to run the script. Error message: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

# -------------------------------------------------------------------------------------------------------
Run -organizationName $ORGANIZATION_NAME