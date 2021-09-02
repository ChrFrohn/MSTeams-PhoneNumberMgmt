#Moduels to be used:
Import-Module SQLServer -Verbose #DB Writer permissions
Import-Module MicrosoftTeams -Verbose #Teams administrator #https://docs.microsoft.com/en-us/powershell/module/teams/connect-microsoftteams?view=teams-ps#parameters #Need to conenct as Service Princs

#Reference
# https://docs.microsoft.com/en-us/powershell/module/sqlserver/invoke-sqlcmd?view=sqlserver-ps&source=docs#example-13--connect-to-azure-sql-database--or-managed-instance--using-a-managed-identity
# https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-service-principal-tutorial#assign-an-identity-to-the-azure-sql-logical-server
#
#Auth. using Service Principle with Secret against the SQL DB in Azure and Teams
$ClientID = "e1dd41c9-1d58-4e88-a7b4-9e9aa88fba58" # "enter application id that corresponds to the Service Principal" # Do not confuse with its display name
$TenantID = "b6c54b6e-3286-496c-a554-2a43795873ff" # "enter the tenant ID of the Service Principal"
$ClientSecret = "v_0Wa0~.4Q-ik.mNE5XANZD8L7GQ48.-AI" # "enter the secret associated with the Service Principal"

$RequestToken = Invoke-RestMethod -Method POST `
           -Uri "https://login.microsoftonline.com/$TenantID/oauth2/token"`
           -Body @{ resource="https://database.windows.net/"; grant_type="client_credentials"; client_id=$ClientID; client_secret=$ClientSecret }`
           -ContentType "application/x-www-form-urlencoded"
$AccessToken = $RequestToken.access_token
        
       
#Connect to Teams
Connect-MicrosoftTeams #When this is fixed as SP change it

#Azure DB info
$SQLServer = "seattle.database.windows.net"
$DBName = "PSTNnumbers_DK"
$DBTableName1 = "dbo.PhoneNumbers"

$TeamsUsers = Get-CsOnlineUser | Select-Object Alias, LineURI

$Query_UsersInDB = "select * from $DBTableName1 where UsedBy IS NOT NULL;"

$UsersInDB = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DBName -AccessToken $AccessToken -Query $Query_UsersInDB -Verbose

#Kig efter om brugeren er i DB, men ikke Teams - Ryd derefter op i DB
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
            Write-Host "DB Update for" $User.Alias $UserPhoneNumber
            $UserPhoneNumber = $User.LineURI.TrimStart('tel:+45')
            $UserNameInTeams = $User.Alias
            $Query_UsersInDB_Add = "UPDATE $DBTableName1 SET UsedBy='$UserNameInTeams' where PSTNnumber = '$UserPhoneNumber'"
            
            #Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DBName -AccessToken $AccessToken -Query $Query_UsersInDB_Add -Verbose 
        }
    }
}

Foreach($User in $TeamsUsers)
{
    Lookup-Database
}

#########################################################################################################################################################

#Kig efter om brugeren er i Teams, men ikke i DB og opdatere derefter DB

Function Lookup-Teams
{
    if ($TeamsUsers.Alias -contains $User)
    {#Nothing to do
    }
    else {
        
        Write-Host $User "Is not found in Microsoft Teams, user will be remove from the DB and number will be come avalibe"
        $Query_UsersInDB_CleanUp = "UPDATE $DBTableName1 SET UsedBy='NULL' where Usedby = $User"
        #Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DBName -AccessToken $AccessToken -Query $Query_UsersInDB_CleanUp -Verbose 
    }
}


#Kig efter om brugeren er i Teams, men ikke i DB og opdatere derefter DB
Foreach($User in $UsersInDB.UsedBy)
{
    Lookup-Teams
}

