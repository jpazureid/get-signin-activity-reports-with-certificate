[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]
    $FromDaysAgo,

    [Parameter(Mandatory = $false)]
    [Datetime]
    $From,

    [Parameter(Mandatory = $false)]
    [Datetime]
    $To,

    [Parameter(Mandatory = $false)]
    [String]
    $UPN
)

if ($FromDaysAgo -and ($From -or $To)) {
    throw "Use either 'FromDaysAgo' or 'From and To'."
    # force exit
    exit
}
elseif ($FromDaysAgo -and ($FromDaysAgo -lt 0) ) {
    throw "'FromDaysAgo' must be a positive value."
    # force exit
    exit
}
elseif (($From -or $To) -and -not ($From -and $To) ) {
    throw "Both 'From' and 'To' must be specified."
    # force exit
    exit
}
elseif ($From -gt $To) {
    throw "'From' must be earlier than 'To'."
    # force exit
    exit
}


Add-Type -Path "Tools\Microsoft.Identity.Client\Microsoft.Identity.Client.dll"

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
# Scopes
#
$scope = "$resource/.default"
$scopes = New-Object System.Collections.ObjectModel.Collection["string"]
$scopes.Add($scope)

#
# Get certificate
#
$cert = Get-ChildItem -path cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $thumprint }

#
# Create AuthenticationContext for acquiring token 
# 
$confidentialApp = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($clientId).WithCertificate($cert).withTenantId($tenantId).Build()

function Get-AccessToken() {
    $authResult = $confidentialApp.AcquireTokenForClient($scopes).ExecuteAsync().Result
    if ($null -eq $authResult) {
        Write-Host "ERROR: No Access Token"
        exit
    }
    return $authResult
}

Function Get-AuthorizationHeader {
    # acquire token if it has been expired.
    $authResult = Get-AccessToken
    $accessToken = $authResult.AccessToken    
    return @{'Authorization' = "Bearer $($accessToken)" }    
}

#
# Compose the access token type and access token for authorization header
#
$url = "$resource/v1.0/auditLogs/signIns"
$isParamAdded = $false

if ($FromDaysAgo) {
    $fromDate = [Datetime]::UtcNow.AddDays(-$FromDaysAgo)

    $fromDateUtc = "{0:s}" -f $fromDate.ToUniversalTime() + "Z"
    $url += "?`$filter=createdDateTime ge $fromDateUtc"
    $isParamAdded = $true
}

if ($From -and $To) {
    $fromDateUtc = "{0:s}" -f $From.ToUniversalTime() + "Z"
    $toDateUtc = "{0:s}" -f $To.ToUniversalTime() + "Z"
    $url += "?`$filter=createdDateTime ge $fromDateUtc and createdDateTime lt $toDateUtc"
    $isParamAdded = $true
}

if ($UPN) {
    If ($isParamAdded) {
        $url += " and userPrincipalName eq '$UPN'"
    }
    else {
        $url += "?`$filter=userPrincipalName eq '$UPN'"
    }
}

Write-Output "Fetching data using Uri: $url"
    
Do {
    $retryNeeded = $false
    
    try {
        $headerParams = Get-AuthorizationHeader
        $myReport = (Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url)
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader $stream
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $errorMessage = $reader.ReadToEnd()

        if ($statusCode -eq 429) {
            $retryAfter = $_.Exception.Response.Headers["Retry-After"]
            Write-Error "429 Too Many Requests detected. Retry after $retryAfter seconds."
            Start-Sleep -s $retryAfter
            $retryNeeded = $true
        }
        else {
            Write-Error "UnEpected Error: $errorMessage"
            exit 1
        }
    }

    if (-Not $retryNeeded) {
        $myReportValue = ($myReport.Content | ConvertFrom-Json).value
        
        for ($j = 0; $j -lt $myReportValue.Count; $j++) {
            $data += $myReportValue[$j]
        }

        $url = ($myReport.Content | ConvertFrom-Json).'@odata.nextLink'
    }
}
while ($null -ne $url)

$data | ConvertTo-Json | Out-File -FilePath $outfile
Write-Host "Sign-in log is exported to $outfile"
