# PSAppCenterBuildScript
Powershell script for build application on MS AppCenter, reports and branch information

The script is written as a test task for AKVELON.

The script allows you to get a list of applications, branches and builds of the user
https://appcenter.ms, as well as statistics on the implementation of the latest builds, including
with saving in HTML file.

For the script to work, a valid AppCenter user token API is needed:
1. Log into https://appcenter.ms
2. Click on Profile - Account Settings - API tokens
3. Press "New API token", add description, select access level and press "Add new API token"
4. In opened message "Here’s your API token." take your new API token and save it in protected place

Script starting with BuildAppCenterv1.ps1 file, use Open with Powershell or Powershell_ISE open and Run script

1.
Insert API key: {insert here your API token}
Token User: API_token_user
Applications:
SomeApp1
SomeApp2
SomeApp3

2.
Insert apllication name for branch list: {Insert here one of your application name}
Branches:
branch1
branch2
master

3.
Select next step:
1 Build all branches
2 Get branches last build
3 Get status report
4 Save status report to HTML
5 Exit script
{Insert here number of next step}

1. Will check all branches for build configuration:
  if some branches does not have build config script will offer to build branch with config and build it in order
  if all branches have build configuration, will start build of all branch in order
  if non of branch have build configuration script show message "Sorry, there is no configured branch" and will back to menu

2. Will show last build status of all branches, if they have any build
   Branches build status

   BranchName BuildID Status    Duration
   ---------- ------- ------    --------
   branch1         13 completed 36.51 s 
   master          14 completed 42.3 s 

3. Will show status report in format
   BranchName Status    result Duration LogLink                                                                                                                                                  
   ---------- ------    ------ -------- -------                                                                                                                                                  
   branch1    completed failed 36.51 s  https://build....
   master     completed failed 42.3 s   https://build....
   
4. Will save status report in HTML-format in script directory
