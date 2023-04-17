# Loops through a range of AS Numbers and stores the resulting IP address ranges in a text file called asn_ip_ranges.txt


# Analytics csv
$global:ASN_ANALYTICS = @("Name,CountryCode,Description,ASN`n")

function Get-ASNInfo {
    param (
        $OrganizationName = "microsoft"
    )
    $url = "https://api.bgpview.io/search?query_term=$OrganizationName"
    $response = Invoke-RestMethod -Uri $url -Method Get

    if ($response.status -eq "ok") {
        # $asnInfo = $response | ConvertFrom-Json 
        $asnInfo = Get-Content .\msft_asns_bgpview.json -Raw | ConvertFrom-Json
        $asns = $AsnInfo.data.asns
        $asnValues = @()
        $data = @("Name,CountryCode,Description,ASN`n")
        foreach ($asn in $asns) {
            #echo "asnInfo log: $asn.asn"
            #$test = $asn.asn | Select-Object asn
            #echo $test
            $asnValues += $asn.asn
            $data += "$($asn.name),$($asn.country_code),$($asn.description),$($asn.asn)`n"
            #echo $ASN_ANALYTICS
        }
        Set-Variable -Name $ASN_ANALYTICS -Value $data -Scope Global
    }
    else {
        Write-Host "Error: $($response.status) - $($response.status_message)"
    }
    return $asnValues | Sort-Object
}

function Get-ASNPrefixes {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        $ASN
    )
    $url = "https://stat.ripe.net/data/announced-prefixes/data.json?resource=$ASN"
    $response = Invoke-RestMethod -Uri $url -Method Get

    if ($response.status -eq "ok") {
        # TESTING : $asnPrefixInfo = $response | ConvertFrom-Json
        $asnPrefixInfo = Get-Content .\ripe_prefix.json -Raw | ConvertFrom-Json
        $prefixes = $asnPrefixInfo.data.prefixes
        $prefixValues = @()

        foreach ($prefix in $prefixes) {
            echo $prefix.prefix
            $prefixValues += $prefix.prefix
        }
    }
    else {
        Write-Host "Error: $($response.status) - $($response.status_message)"
    }
    return $prefixValues
}

function Write-ASNAnalytics {
    param (
        # [Parameter(Mandatory = $true)]
        # $asn_analytics,
        [Parameter(Mandatory = $true)]
        $asn_prefixes
    )
    $asn_analytics = $global:ASN_ANALYTICS

    $UniqueCountryCodesCount = ($asn_analytics | Select-Object CountryCode | Get-Unique | Measure-Object).Count
    $UniqueASN = ($asn_analytics | Select-Object ASN | Sort-Object | Get-Unique | Select-Object -ExpandProperty ASN)
    $UniqueASNCount = ($asn_analytics | Select-Object ASN | Get-Unique | Measure-Object).Count
    #$UniqueNames = ($asn_analytics | Select-Object Name | Sort-Object | Get-Unique | Select-Object -ExpandProperty Name)
    $UniqueNames = ($asn_analytics | Select-Object Name | Get-Unique | Select-Object -ExpandProperty Name)
    $UniqueNamesCount = ($asn_analytics | Select-Object Name | Get-Unique | Measure-Object).Count
    #$UniqueDescriptions = ($asn_analytics | Select-Object Description | Sort-Object | Get-Unique | Select-Object -ExpandProperty Description)
    $UniqueDescriptions = ($asn_analytics | Select-Object Description | Get-Unique | Select-Object -ExpandProperty Description)
    $UniqueDescriptionsCount = ($asn_analytics | Select-Object Description | Get-Unique | Measure-Object).Count

    $UniquePrefixes = ($prefix_analytics | Sort-Object | Get-Unique | Select-Object -ExpandProperty Name)
    $UniquePrefixCount = ($prefix_analytics | Get-Unique | Measure-Object).Count

    Write-Host "UniqueCountryCodesCount: $UniqueCountryCodesCount"
    Write-Host "UniqueASN: $UniqueASN"
    Write-Host "UniqueASNCount: $UniqueASNCount"
    Write-Host "UniqueNames: $UniqueNames"
    Write-Host "UniqueNamesCount: $UniqueNamesCount"
    Write-Host "UniqueDescriptions: $UniqueDescriptions"
    Write-Host "UniqueDescriptionsCount: $UniqueDescriptionsCount"

    Write-Host "UniquePrefixes: $UniquePrefixes"
    Write-Host "UniquePrefixCount: $UniquePrefixCount"

    $output = "
UniqueCountryCodesCount: $UniqueCountryCodesCount`n
UniqueASN: $UniqueASN`n
UniqueASNCount: $UniqueASNCount`n
UniqueNamesCount: $UniqueNamesCount`n
UniqueDescriptions: $UniqueDescriptions`n
UniqueDescriptionsCount: $UniqueDescriptionsCount`n
UniquePrefixes: $UniquePrefixes`n
UniquePrefixCount $UniquePrefixCount`n
"
    Write-Host "Exporting to: $PWD\asn_analytics.txt"

    $output | Out-File -FilePath "$PWD\asn_analytics.txt" -Encoding utf8 -Append
}
# -------------------------------------------------------------------------------------------------------

# Get all asn for a given org name
$ASNumbers = Get-ASNInfo -OrganizationName "microsoft"

# Get all prefixes assoiciated with each AS number
$ASNPrefixes = @()
foreach ($ASNumber in $ASNumbers) {
    echo "main log: $ASNumber"
    $ASNPrefixes += Get-ASNPrefixes -ASN $ASNumber
}

# Write analytics file to working dir
#Write-ASNAnalytics -asn_analytics $ASN_ANALYTICS -asn_prefixes $ASNPrefixes
Write-ASNAnalytics -asn_prefixes $ASNPrefixes

# Write all prefixes to file
$ASNPrefixes | Out-File -FilePath "asn_ip_ranges.txt" -Encoding utf8 -Append