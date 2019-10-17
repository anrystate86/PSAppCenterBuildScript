# Get User from API token
function GetAPIUser ($APIToken)
{
    $TReq = "/v0.1/user"
    $TMethod = "GET"
    (InvokeAPI -Req $TReq -Method $TMethod -APIToken $APIToken).name
}

# Test API token for later authorization
function TestAPIKey ($APIToken)
{
    
    $Resp = Invoke-WebRequest -Uri "https://api.appcenter.ms/v0.1/user" -Method "GET" -Headers @{"Accept"="application/json"; "X-API-Token"="$($APIToken)"; "Content-Type"="application/json"} -WarningAction SilentlyContinue;
    If ($Resp.StatusCode -eq 200)
    {
        Return $true
    }
    elseif ($Resp.StatusCode -eq 401)
    {
        Write-Host "Error: (401) Unauthorized" -f Red
        Return $false
    }
    else
    {
        Write-Host $Error[0] -f Red
        Return $false
    }
}

# Get Applications
function GetAPIApps ($APIToken)
{
    $TReq = "/v0.1/apps"
    $TMethod = "GET"
    (InvokeAPI -Req $TReq -Method $TMethod -APIToken $APIToken).name
}

# Get Branches from selected Application
function GetAPIBranches ($APPName, $APIToken)
{
    $TReq = "/v0.1/apps/$(GetAPIUser -APIToken $APIToken)/$APPName/branches"
    $TMethod = "GET"
    (InvokeAPI -Req $TReq -Method $TMethod -APIToken $APIToken)
    #name, commit, protected, protection, protection_url
}

# Invoke API web request with $Req param, $Method and $APIToken
function InvokeAPI ($Req, $Method, $APIToken)
{
    $Resp = Invoke-WebRequest -Uri "https://api.appcenter.ms$Req" -Method $Method -Headers @{"Accept"="application/json"; "X-API-Token"="$($APIToken)"; "Content-Type"="application/json"};
    If ($Resp.StatusCode -eq 200)
    {
        Return $(ConvertFrom-Json $($Resp.Content))
    }
    else
    {
        Write-Host $Resp.StatusDescription -ForegroundColor Red
        exit
    }
}

# Start build selected Application/Branch 
function StartBuild ($APPName, $APIToken, $Branch)
{
    $Request = "/v0.1/apps/$(GetAPIUser -APIToken $APIToken)/$($APPName)/branches/$($Branch)/builds"
    $Method = "POST"
    InvokeAPI -Req $Request -Method $Method -APIToken $APIToken | select @{N='BranchName';E={$_.sourceBranch}}, @{N='BuildID';E={$_.id}}
    
    <#
    id              : 5
    buildNumber     : 5
    queueTime       : 2019-10-16T12:35:59.8029452Z
    lastChangedDate : 2019-10-16T12:35:59.86Z
    status          : notStarted
    reason          : manual
    sourceBranch    : master
    tags            : {}
    properties      : 
    #>
}

# Get build config for selected Application/Branch
function GetBranchConfig ($APPName, $APIToken, $Branch)
{
    #/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config
    try
    {
        $Resp = Invoke-WebRequest -Uri "https://api.appcenter.ms/v0.1/apps/$(GetAPIUser -APIToken $APIToken)/$($APPName)/branches/$($Branch)/config" -Method "GET" -Headers @{"Accept"="application/json"; "X-API-Token"="$($APIToken)"; "Content-Type"="application/json"} -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
        Return $(ConvertFrom-Json $($Resp.Content))
    }
    catch [System.Net.WebException]
    {
        if ($_.exception -match "(404)")
        {
            Return "Not Found"
        }
        else
        {
            Write-Host "Something goes wrong:" -f Red
            Write-Host $_.exception -f Red
            break
        }
    }
}

# Get last build status for Application/Branch
function GetBuildStatus ($APPName, $APIToken, $BuildID)
{
    #/v0.1/apps/{owner_name}/{app_name}/builds/{build_id}
    $Request = "/v0.1/apps/$(GetAPIUser -APIToken $APIToken)/$($APPName)/builds/$($BuildID)"
    $Method = "POST"
    InvokeAPI -Req $Request -Method $Method -APIToken $APIToken | select id, startTime, finishTime, status, result

    <#
    id              : 6
    buildNumber     : 6
    queueTime       : 2019-10-16T12:41:39.8121022Z
    startTime       : 2019-10-16T12:41:47.4042167Z
    finishTime      : 2019-10-16T12:42:22.7477444Z
    lastChangedDate : 2019-10-16T12:42:22.833Z
    status          : completed
    result          : failed
    reason          : manual
    sourceBranch    : branch1
    sourceVersion   : 24cd8ef69079e255ad67ee7e1ff9d2e7e529e064
    tags            : {normal, signed, uwp, manual}
    properties      : 
    #>
}

# Get download link for logs selected Application/BuildID
function GetBuildLogs ($APPName, $APIToken, $BuildID)
{
    #/v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/downloads/{download_type}
    $Request = "/v0.1/apps/$(GetAPIUser -APIToken $APIToken)/$($APPName)/builds/$($BuildID)/downloads/logs"
    $Method = "GET"
    InvokeAPI -Req $Request -Method $Method -APIToken $APIToken 

    #uri : https://build.appcenter.ms/v0.1/public/apps/595e04de-59bb-4759-841b-ad386e2483a0/downloads?token=97bfca897c8fcc02de9b35ce50b47f8f733dbf44d7701cc671909025e63599e7
}