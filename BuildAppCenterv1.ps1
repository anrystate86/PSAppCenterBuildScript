# Using APIFunc.ps1
. $PSScriptRoot\APIFunc.ps1

##########################################################
Write-Host "AKVELON test AppCenter API PSScript" -f Green
Write-Host

$APIToken = Read-Host -Prompt "Insert API key"
Write-Host

if (TestAPIKey -APIToken $APIToken)
{
    Write-Host "Token User: $(GetAPIUser -APIToken $APIToken)" -ForegroundColor Green
    
    ##################### Applications list #######################
    Write-Host "Applications:"
    $Apps = GetAPIApps -APIToken $APIToken
    if ($Apps -ne $nul)
    {
        $Apps
    }
    else
    {
        Write-Host "none"
        Write-Host "There is no applications, script will be stopped"
        break
    }
    Write-Host
    
    $Application = Read-Host "Insert apllication name for branch list"
    
    ################### Branches list #########################
    Write-Host
    Write-Host "Branches:"
    $Branches = (GetAPIBranches -APPName $Application -APIToken $APIToken).branch.name
    if ($Branches -ne $null)
    {
        $Branches   
    }
    else
    {
        Write-Host "none"
        Write-Host "There is no branches in $($Application), script will be stopped"
        break
    }
    ################## What to do whith branches ########################
    $Wtd = 0
    while ($Wtd -ne 5)
    {
        Write-Host
        Write-Host "Select next step:"
        Write-Host "1 Build all branches"
        Write-Host "2 Get branches last build"
        Write-Host "3 Get status report"
        Write-Host "4 Save status report to HTML"
        Write-Host "5 Exit script"
        $Wtd = Read-Host 
    
        switch ($Wtd)
        {
            ###################### Build all branches #############################
            1 {  
                $Config = (GetAPIBranches -APPName $Application -APIToken $APIToken).branch.name | foreach {
                    $BConf = GetBranchConfig -APPName $Application -APIToken $APIToken -Branch $_
                    if (($Bconf -ne "Not found") -and ($Bconf -ne $Null))
                    {
                        $BrStatus = ''|select Name, Configured
                        $BrStatus.Name = $_
                        $BrStatus.Configured = $True
                        $BrStatus
                    }
                    else
                    {
                        Write-host "Branch " -NoNewline
                        Write-Host $_ -f Yellow -NoNewline
                        Write-Host " has no Build configuration"

                        $BrStatus = ''|select Name, Configured
                        $BrStatus.Name = $_
                        $BrStatus.Configured = $False
                        $BrStatus
                    }
                }
                $Config

                If (($Config.Configured -contains $False) -and ($Config.Configured -contains $True))
                {
                    Write-Host "Branch(es): $($Config | where {$_.Coonfigured -eq $false} | select Name) is not configured, please configure it before Build" -f Yellow
                    Write-Host 
                    $Answ = Read-Host "Complete build with configured branch(es)? (y,n)" 
                    switch ($Answ)
                    {
                        {"Y" -or "y"} {
                            $Cbranches = ($Config | where {$_.Configured -eq $True}).Name
                            $StartedBuilds = $Cbranches | foreach {
                                StartBuild -APPName $Application -APIToken $APIToken -Branch $_
                            }
                            Write-Host
                            Write-Host "Started build branches" -f Green
                            $StartedBuilds | Format-Table
                        }
                        {"N" -or "n"} {Write-Host "Build was canceled" -f Yellow}
                        DEFAULT { Write-Host "Sorry wrong answer, build was canceled" -f Yellow}

                    }
                }
                elseif ($Config.Configured -notcontains $False)
                {
                    Write-Host "All branches configured"
                    $StartedBuilds = $Config.Name | foreach {
                        StartBuild -APPName $Application -APIToken $APIToken -Branch $_
                    }
                    Write-Host
                    Write-Host "Started build branches" -f Green
                    $StartedBuilds | Format-Table
                }
                else
                {
                    Write-Host "Sorry, there is no configured branch" -f Yellow
                }

            }
            ################################# Branches last build ##########################
            2 { 
                $BrLastBuild = (GetAPIBranches -APPName $Application -APIToken $APIToken).lastbuild | select sourceBranch, id, status, startTime, finishTime
        
                $LBuildStats = $BrLastBuild|foreach {
                        $Blb = "" | select BranchName, BuildID, Status, Duration
                        $Blb.BranchName = $_.sourceBranch
                        $Blb.BuildID = $_.id
                        $Blb.Status = $_.status
                        if ($Blb.Status -eq "completed")
                        {
                            $Duration = ($([datetime]::Parse($_.finishTime)) - $([datetime]::Parse($_.startTime))).TotalSeconds
                            $Blb.Duration = "$([Math]::Round($Duration, 2)) s"

                        }
                        $Blb
                }
                Write-Host
                Write-Host "Branches build status" -f Green
                $LBuildStats | Format-Table
            }
            ################################ Status report ######################################
            3 {
                $BrLastBuild = (GetAPIBranches -APPName $Application -APIToken $APIToken).lastbuild | select sourceBranch, id, status, result, startTime, finishTime
        
                $LBuildStats = $BrLastBuild|foreach {
                        $Blb = "" | select BranchName, Status, result, Duration, LogLink
                        $Blb.BranchName = $_.sourceBranch
                        $Blb.LogLink =  (GetBuildLogs -APPName $Application -APIToken $APIToken -BuildID $_.id).uri
                        $Blb.Status = $_.status
                        $Blb.Result = $_.result
                        if ($Blb.Status -eq "completed")
                        {
                            $Duration = ($([datetime]::Parse($_.finishTime)) - $([datetime]::Parse($_.startTime))).TotalSeconds
                            $Blb.Duration = "$([Math]::Round($Duration, 2)) s"
                        }
                        $Blb
                }
                Write-Host
                Write-Host "Build report" -f Green
                $LBuildStats | Format-Table
            }
            ############################### Save status report to html ###################################
            4 {
                $BrLastBuild = (GetAPIBranches -APPName $Application -APIToken $APIToken).lastbuild | select sourceBranch, id, status, result, startTime, finishTime
        
                $LBuildStats = $BrLastBuild|foreach {
                        $Blb = "" | select BranchName, Status, Result, Duration, LogLink
                        $Blb.BranchName = $_.sourceBranch
                        $Blb.LogLink =  (GetBuildLogs -APPName $Application -APIToken $APIToken -BuildID $_.id).uri
                        $Blb.Status = $_.status
                        $Blb.Result = $_.result
                        if ($Blb.Status -eq "completed")
                        {
                            $Duration = ($([datetime]::Parse($_.finishTime)) - $([datetime]::Parse($_.startTime))).TotalSeconds
                            $Blb.Duration = "$([Math]::Round($Duration, 2)) s"
                        }
                        $Blb
                }
                Write-Host
                Write-Host "Save report to HTML" -f Green

                $Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;} 
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

                [System.Web.HttpUtility]::HtmlDecode($($LBuildStats | select -property @{N='Branch name';E={$_.BranchName}},`
                  @{N='Build status';E={$_.Result}}, @{N='Duration';E={$_.Duration}}, @{N='Link to build logs';E={"<a href='$($_.LogLink)'>Link</a>"}}`
                  |  ConvertTo-Html -As Table -Head $Header )) |Out-File -FilePath "$($PSScriptRoot)\$($Application)_BuildReport.html"
                Write-Host "Report saved to $($PSScriptRoot)\$($Application)_BuildReport.html" -f Green
            }
            #################################### Exiting script #############################
            5 {
                Write-Host
                Write-Host "Exiting script, bye!" -f Green
            }
        }
    }
}
else
{
    Write-Host "Error in using API Token" -ForegroundColor Red
    Write-Host "Script will be stopped"
    exit
}
