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
}

# Get build config for selected Application/Branch
function GetBranchConfig ($APPName, $APIToken, $Branch)
{
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
    $Request = "/v0.1/apps/$(GetAPIUser -APIToken $APIToken)/$($APPName)/builds/$($BuildID)"
    $Method = "POST"
    InvokeAPI -Req $Request -Method $Method -APIToken $APIToken | select id, startTime, finishTime, status, result
}

# Get download link for logs selected Application/BuildID
function GetBuildLogs ($APPName, $APIToken, $BuildID)
{
    $Request = "/v0.1/apps/$(GetAPIUser -APIToken $APIToken)/$($APPName)/builds/$($BuildID)/downloads/logs"
    $Method = "GET"
    InvokeAPI -Req $Request -Method $Method -APIToken $APIToken 
}