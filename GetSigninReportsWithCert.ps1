Add-Type -Path ".\Tools\Microsoft.IdentityModel.Clients.ActiveDirectory\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"

#
# Authorization & resource Url
#
$tenantId = "yourtenant.onmicrosoft.com" # or GUID "01234567-89AB-CDEF-0123-456789ABCDEF"
$clientId = "FEDCBA98-7654-3210-FEDC-BA9876543210"
$thumprint = "3EE9F1B266F88848D1AECC72FDCE847CC49ED98C"
$resource = "https://graph.microsoft.com"
$outFile = "output.json"
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
    $url = "$resource/v1.0/auditLogs/signIns"

    Write-Output "Fetching data using Uri: $url"

    Do {
        $myReport = (Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url)
        $myReportValue = ($myReport.Content | ConvertFrom-Json).value

        for ($j = 0; $j -lt $myReportValue.Count; $j++) {
            $data += $myReportValue[$j]
        }

        #
        # Get url from next link
        #
        $url = ($myReport.Content | ConvertFrom-Json).'@odata.nextLink'

        #
        # Acquire token again if it expires soon
        #
        $expiresOn = ($authResult.ExpiresOn).AddSeconds(-300) # minus 5 min
        $getdate = [DateTime]::UtcNow

        if ($expiresOn -lt $getdate) {
            $authResult = $authContext.AcquireTokenAsync($resource, $clientCred).Result 
        }
    } while ($null -ne $url)
}
else {
    Write-Host "ERROR: No Access Token"
}

$data | ConvertTo-Json | Out-File -FilePath $outfile
Write-Host "Sign-in log is exported to $outfile"