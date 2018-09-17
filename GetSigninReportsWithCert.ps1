Add-Type -Path ".\Tools\Microsoft.IdentityModel.Clients.ActiveDirectory\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"

#
# Authorization & resource Url
#
$tenantId = "yourtenant.onmicrosoft.com" # or GUID "01234567-89AB-CDEF-0123-456789ABCDEF"
$clientId = "FEDCBA98-7654-3210-FEDC-BA9876543210"
$thumprint = "3EE9F1B266F88848D1AECC72FDCE847CC49ED98C"

$outputFile = "output.csv"

#
# Graph API Endpoint
#
$resource = "https://graph.microsoft.com"

#
# Authorization & resource Url
#
$authUrl = "https://login.microsoftonline.com/$tenantId/" 

#
# Get certificate
#
$cert = Get-ChildItem -path cert:\CurrentUser\My | Where-Object {$_.Thumbprint -eq $thumprint}

#
# Create AuthenticationContext for acquiring token 
# 
$authContext = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext $authUrl, $false

#
# Create credential for client application 
#
$clientCred = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate $clientId, $cert

#
# Acquire the authentication result
#
$authResult = $authContext.AcquireTokenAsync($resource, $clientCred).Result 

$data = @()

#
# Compose the access token type and access token for authorization header
#
$headerParams = @{'Authorization' = "$($authResult.AccessTokenType) $($authResult.AccessToken)"}
$url = "$resource/beta/auditLogs/signIns"

Do {
    Write-Output "Fetching data..."

    $report = (Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url)
    $reportValue = ($report.Content | ConvertFrom-Json).value
    $reportVaultCount = $reportValue.Count

    for ($j = 0; $j -lt $reportVaultCount; $j++) {
        $eachEvent = New-Object PSCustomObject
        $thisEvent = $reportValue[$j]
        $canumbers = $thisEvent.conditionalAccessPolicies.Count
        
        $temp = $thisEvent.id
        $eachEvent = $eachEvent | Add-Member "id" "$temp" -PassThru

        $temp = $thisEvent.createdDateTime
        $eachEvent = $eachEvent | Add-Member @{"createdDateTime" = "$temp"} -PassThru

        $temp = $thisEvent.userDisplayName
        $eachEvent = $eachEvent | Add-Member @{"userDisplayName" = "$temp"} -PassThru

        $temp = $thisEvent.userPrincipalName
        $eachEvent = $eachEvent | Add-Member @{"userPrincipalName" = "$temp"} -PassThru

        $temp = $thisEvent.userId
        $eachEvent = $eachEvent | Add-Member @{"userId" = "$temp"} -PassThru

        $temp = $thisEvent.appId
        $eachEvent = $eachEvent | Add-Member @{"appId" = "$temp"} -PassThru

        $temp = $thisEvent.appDisplayName
        $eachEvent = $eachEvent | Add-Member @{"appDisplayName" = "$temp"} -PassThru

        $temp = $thisEvent.ipAddress
        $eachEvent = $eachEvent | Add-Member @{"ipAddress" = "$temp"} -PassThru

        $temp = $thisEvent.clientAppUsed
        $eachEvent = $eachEvent | Add-Member @{"clientAppUsed" = "$temp"} -PassThru

        $temp = $thisEvent.mfaDetail.authMethod
        $eachEvent = $eachEvent | Add-Member @{"mfaDetail.authMethod" = "$temp"} -PassThru

        $temp = $thisEvent.mfaDetail.authDetail
        $eachEvent = $eachEvent | Add-Member @{"mfaDetail.authDetail" = "$temp"} -PassThru

        $temp = $thisEvent.correlationId
        $eachEvent = $eachEvent | Add-Member @{"correlationId" = "$temp"} -PassThru

        $temp = $thisEvent.conditionalAccessStatus
        $eachEvent = $eachEvent | Add-Member @{"conditionalAccessStatus" = "$temp"} -PassThru

        $temp = $thisEvent.isRisky
        $eachEvent = $eachEvent | Add-Member @{"isRisky" = "$temp"} -PassThru

        $temp = $thisEvent.riskLevel
        $eachEvent = $eachEvent | Add-Member @{"riskLevel" = "$temp"} -PassThru

        $temp = $thisEvent.status.errorCode
        $eachEvent = $eachEvent | Add-Member @{"status.errorCode" = "$temp"} -PassThru

        $temp = $thisEvent.status.failureReason
        $eachEvent = $eachEvent | Add-Member @{"status.failureReason" = "$temp"} -PassThru

        $temp = $thisEvent.status.additionalDetails
        $eachEvent = $eachEvent | Add-Member @{"status.additionalDetails" = "$temp"} -PassThru

        $temp = $thisEvent.deviceDetail.deviceId
        $eachEvent = $eachEvent | Add-Member @{"deviceDetail.deviceId" = "$temp"} -PassThru

        $temp = $thisEvent.deviceDetail.displayName
        $eachEvent = $eachEvent | Add-Member @{"deviceDetail.displayName" = "$temp"} -PassThru
        
        $temp = $thisEvent.deviceDetail.operatingSystem
        $eachEvent = $eachEvent | Add-Member @{"deviceDetail.operatingSystem" = "$temp"} -PassThru

        $temp = $thisEvent.deviceDetail.browser
        $eachEvent = $eachEvent | Add-Member @{"deviceDetail.browser" = "$temp"} -PassThru

        $temp = $thisEvent.deviceDetail.isCompliant
        $eachEvent = $eachEvent | Add-Member @{"deviceDetail.isCompliant" = "$temp"} -PassThru

        $temp = $thisEvent.deviceDetail.isManaged
        $eachEvent = $eachEvent | Add-Member @{"deviceDetail.isManaged" = "$temp"} -PassThru

        $temp = $thisEvent.deviceDetail.trustType
        $eachEvent = $eachEvent | Add-Member @{"deviceDetail.trustType" = "$temp"} -PassThru

        $temp = $thisEvent.location.city
        $eachEvent = $eachEvent | Add-Member @{"location.city" = "$temp"} -PassThru

        $temp = $thisEvent.location.state
        $eachEvent = $eachEvent | Add-Member @{"location.state" = "$temp"} -PassThru

        $temp = $thisEvent.location.countryOrRegion
        $eachEvent = $eachEvent | Add-Member @{"location.countryOrRegion" = "$temp"} -PassThru

        $temp = $thisEvent.location.geoCoordinates.altitude
        $eachEvent = $eachEvent | Add-Member @{"location.geoCoordinates.altitude" = "$temp"} -PassThru

        $temp = $thisEvent.location.geoCoordinates.latitude
        $eachEvent = $eachEvent | Add-Member @{"location.geoCoordinates.latitude" = "$temp"} -PassThru

        $temp = $thisEvent.location.geoCoordinates.longitude
        $eachEvent = $eachEvent | Add-Member @{"location.geoCoordinates.longitude" = "$temp"} -PassThru

        $temp = $thisEvent.conditionalAccessPolicies | ConvertTo-Json
        $eachEvent = $eachEvent | Add-Member @{"conditionalAccessPolicies" = "$temp"} -PassThru

        $data += $eachEvent
    }
    
    #
    # Get url from next link
    #
    $url = ($report.Content | ConvertFrom-Json).'@odata.nextLink'
} while ($null -ne $url)

$data | Sort-Object -Property createdDateTime | Export-Csv $outputFile -encoding "utf8" -NoTypeInformation
