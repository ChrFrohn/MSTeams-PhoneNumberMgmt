#Loggin
$Date = Get-Date -Format "dd-MM-yyyy"
Start-Transcript -Path .\Logs\DB\$Date.log -Verbose

#Moduels to be used:
Import-Module SQLServer 
Import-Module MicrosoftTeams

#Auth. using Service Principle with Secret against the SQL DB in Azure and Teams
$ClientID = "" # "enter application id that corresponds to the Service Principal" # Do not confuse with its display name
$TenantID = "" # "enter the tenant ID of the Service Principal"
$ClientSecret = "" # "enter the secret associated with the Service Principal"

$RequestToken = Invoke-RestMethod -Method POST `
           -Uri "https://login.microsoftonline.com/$TenantID/oauth2/token"`
           -Body @{ resource="https://database.windows.net/"; grant_type="client_credentials"; client_id=$ClientID; client_secret=$ClientSecret }`
           -ContentType "application/x-www-form-urlencoded"
$AccessToken = $RequestToken.access_token
       
#Connect to Teams
Connect-MicrosoftTeams

#Azure DB info
$SQLServer = ""
$DBName = ""
$DBTableName1 = ""

$TeamsUsers = Get-CsOnlineUser | Select-Object Alias, LineURI

$Query_UsersInDB = "select * from $DBTableName1 where UsedBy IS NOT NULL;"
$UsersInDB = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DBName -AccessToken $AccessToken -Query $Query_UsersInDB -Verbose

#Check if a user is in Teams but not in DB - If the user is in Teams but not in DB. Then update DB with information 
Function Lookup-Database
{
    if($UsersInDB.UsedBy -contains $User.Alias)
    {
        #Nothing to do
    }
    else 
    {
        if([string]::IsNullOrWhiteSpace($User.LineURI))
        {
            #Nothing to do
        }
        else {
            
            $UserPhoneNumber = $User.LineURI.TrimStart('TEL:+45')
            $UserNameInTeams = $User.Alias
            Write-Host "DB Update for" $User.Alias $UserPhoneNumber
            $Query_UsersInDB_Add = "UPDATE $DBTableName1 SET UsedBy='$UserNameInTeams' where PSTNnumber ='$UserPhoneNumber'"

            Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DBName -AccessToken $AccessToken -Query $Query_UsersInDB_Add -Verbose 
        }
    }
}

Foreach($User in $TeamsUsers)
{
    Lookup-Database #This is a function
}

#########################################################################################################################################################

#Check if the user is in DB, but not in Teams. If user is not found in Teams but is in DB, release number in DB: 
Function Lookup-Teams
{
    if ($TeamsUsers.Alias -contains $User)
    {#Nothing to do
    }
    else {
        
        Write-Host $User "Is not found in Microsoft Teams, user will be remove from the DB and number will be come avalibe" 
        $Query_UsersInDB_CleanUp = "UPDATE $DBTableName1 SET UsedBy='NULL' where Usedby ='$User'"
        Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DBName -AccessToken $AccessToken -Query $Query_UsersInDB_CleanUp -Verbose 
    }
}


Foreach($User in $UsersInDB.UsedBy)
{
    Lookup-Teams #This is a function

}

