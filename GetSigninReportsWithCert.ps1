Add-Type -Path ".\Tools\Microsoft.IdentityModel.Clients.ActiveDirectory\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"

#
# Authorization & resource Url
#
$tenantId = "yourtenant.onmicrosoft.com" 
$clientID = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
$thumprint = "0123456789ABCDEF0123456789ABCDEF01234567"

$resource = "https://graph.microsoft.com"
$outfile = "output.csv"
$data = @()

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
$clientCred = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate $clientID, $cert

#
# Acquire the authentication result
#
$authResult = $authContext.AcquireTokenAsync($resource, $clientCred).Result 

if ($null -ne $authResult.AccessToken) {
    #
    # Compose the access token type and access token for authorization header
    #
    $headerParams = @{'Authorization' = "$($authResult.AccessTokenType) $($authResult.AccessToken)"}
    $url = "$resource/beta/auditLogs/signIns"
    
    Write-Output "Fetching data using Uri: $url"
 
    Do {
        $myReport = (Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url)
        $myReportValue = ($myReport.Content | ConvertFrom-Json).value
        $myReportVaultCount = $myReportValue.Count
 
        for ($j = 0; $j -lt $myReportVaultCount; $j++) {
            $eachEvent = @{}
 
            $thisEvent = $myReportValue[$j]
            $canumbers = $thisEvent.conditionalAccessPolicies.Count
 
            $eachEvent = $thisEvent |
            Select-Object id,
            createdDateTime,
            userDisplayName,
            userPrincipalName,
            userId,
            appId,
            appDisplayName,
            ipAddress,
            clientAppUsed,
            mfaDetail,
            correlationId,
            conditionalAccessStatus,
            isRisky,
            riskLevel,
 
            @{Name = 'status.errorCode'; Expression = {$_.status.errorCode}},
            @{Name = 'status.failureReason'; Expression = {$_.status.failureReason}},
            @{Name = 'status.additionalDetails'; Expression = {$_.status.additionalDetails}},
 
            @{Name = 'deviceDetail.deviceId'; Expression = {$_.deviceDetail.deviceId}},
            @{Name = 'deviceDetail.displayName'; Expression = {$_.deviceDetail.displayName}},
            @{Name = 'deviceDetail.operatingSystem'; Expression = {$_.deviceDetail.operatingSystem}},
            @{Name = 'deviceDetail.browser'; Expression = {$_.deviceDetail.browser}},
 
            @{Name = 'location.city'; Expression = {$_.location.city}},
            @{Name = 'location.state'; Expression = {$_.location.state}},
            @{Name = 'location.countryOrRegion'; Expression = {$_.location.countryOrRegion}},
            @{Name = 'location.geoCoordinates.altitude'; Expression = {$_.location.geoCoordinates.altitude}},
            @{Name = 'location.geoCoordinates.latitude'; Expression = {$_.location.geoCoordinates.latitude}},
            @{Name = 'location.geoCoordinates.longitude'; Expression = {$_.location.geoCoordinates.longitude}}
 
            for ($k = 0; $k -lt $canumbers; $k++) {
                $temp = $thisEvent.conditionalAccessPolicies[$k].id
                $eachEvent = $eachEvent | Add-Member @{"conditionalAccessPolicies.id$k" = $temp} -PassThru
 
                $temp = $thisEvent.conditionalAccessPolicies[$k].displayName
                $eachEvent = $eachEvent | Add-Member @{"conditionalAccessPolicies.displayName$k" = $temp} -PassThru
 
                $temp = $thisEvent.conditionalAccessPolicies[$k].enforcedGrantControls
                $eachEvent = $eachEvent | Add-Member @{"conditionalAccessPolicies.enforcedGrantControls$k" = $temp} -PassThru
 
                $temp = $thisEvent.conditionalAccessPolicies[$k].enforcedSessionControls
                $eachEvent = $eachEvent | Add-Member @{"conditionalAccessPolicies.enforcedSessionControls$k" = $temp} -PassThru
 
                $temp = $thisEvent.conditionalAccessPolicies[$k].result
                $eachEvent = $eachEvent | Add-Member @{"conditionalAccessPolicies.result$k" = $temp} -PassThru
            }
            $data += $eachEvent
        }
        
        #
        #Get url from next link
        #
        $url = ($myReport.Content | ConvertFrom-Json).'@odata.nextLink'
    }while ($null -ne $url)
}
else {
    Write-Host "ERROR: No Access Token"
}
 
$data | Sort-Object -Property createdDateTime  | Export-Csv $outfile -encoding "utf8" -NoTypeInformation
