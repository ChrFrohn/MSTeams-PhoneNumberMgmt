#Loggin
$Date = Get-Date -Format "dd-MM-yyyy"
Start-Transcript -Path .\Logs\Teams\$Date.log -Verbose


#Moduels to be used:
Import-Module ActiveDirectory
Import-Module SQLServer #DB Writer permissions
Import-Module MicrosoftTeams #Teams administrator 

#Auth. using Service Principle with Secret against the SQL DB in Azure and Teams
$ClientID = "" # "enter application id that corresponds to the Service Principal" # Do not confuse with its display name
$TenantID = "" # "enter the tenant ID of the Service Principal"
$ClientSecret = "" # "enter the secret associated with the Service Principal"

$RequestToken = Invoke-RestMethod -Method POST `
           -Uri "https://login.microsoftonline.com/$TenantID/oauth2/token"`
           -Body @{ resource="https://database.windows.net/"; grant_type="client_credentials"; client_id=$ClientID; client_secret=$ClientSecret }`
           -ContentType "application/x-www-form-urlencoded"
$AccessToken = $RequestToken.access_token
        
#Connect to Microsoft Teams
Connect-MicrosoftTeams

#Azure DB info
$SQLServer = ""
$DBName = ""
$DBTableName1 = ""



#Functions:
Function ReservedNumber
{
    #Combine Country code and PhoneNumber

    Write-Host -ForegroundColor Cyan $UserInfo.SamAccountName "Enabling user for PSTN in Teams with number" $ReservedNumber #Skal omskrives

    #Configure the user in Teams
    #Set-CsUser $TeamsCheck.WindowsEmailAddress -OnPremLineURI tel:+$CountryCodeAndReservedNumber -EnterpriseVoiceEnabled $true -HostedVoiceMail $true -Verbose
    
    #Update the DB (UsedBy)
    $Query_ReservedUpdateNumber = "UPDATE $DBTableName1 SET UsedBy='$UsedBy' WHERE PSTNNumber=$ReservedNumber"
    #Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DBName -AccessToken $AccessToken -Query $Query_ReservedUpdateNumber -Verbose

}

Function EnableTeamsUser #This funcation cotains the actions that will enable the user in Teams, update the nr. in AD & Update the DB with info om who uses what number
{

    Write-Host -ForegroundColor Cyan $UserInfo.SamAccountName "Enabling user for PSTN in Teams" $Number #Skal omskrives
    
    #Configuring the user in Teams
    #Set-CsUser -Identity $TeamsCheck.WindowsEmailAddress -OnPremLineURI tel:+$CountryCodeAndNumber -EnterpriseVoiceEnabled $true -HostedVoiceMail $true -Verbose
    
    #Updating the DB
    $Query_UpdateNumber = "UPDATE $DBTableName1 SET UsedBy='$UsedBy' WHERE PSTNNumber=$Number"
    #Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DBName -AccessToken $AccessToken -Query $Query_UpdateNumber -Verbose 
    
}

Function IS-OnPremLineURIManuallySet
{
    #Is OnPremLineURIManuallySet set to 'false'
    #False is the disred value
    if($TeamsCheck.OnPremLineURIManuallySet -eq $false)
        {
            #If OnPremLineURIManuallySet is set to false then the user is ready to be enabled, if other contions are meet
            Write-Host -ForegroundColor Green "OnPremLineURIManuallySet is OK"
           
        }
        else
        {
            #If OnPremLineURIManuallySet is set to True, then it could endicate that the user might allready have a PSTN number and is enabled for Teams
            Write-Host -ForegroundColor Red "OnPremLineURIManually has the following value:" $TeamsCheck.OnPremLineURIManuallySet
            Break
        }
}

Function IS-OnPremLineUriSet
{
         #Is OnPremLineUriSet set to 'null'
         #NULL is the disred value
         if([string]::IsNullOrWhiteSpace($TeamsCheck.OnPremLineURI))
            {
                #If OnPremLineURI holds no value then the user is ready to be enabled
                Write-Host -ForegroundColor Green "OnPremLineURI is OK"
              
            }
            else
            {
                #If OnPremLineURI holds a value (fx +4512345678) then that might need to be cleared
                Write-Host -ForegroundColor Red "OnPremLineURI has the following value:" $TeamsCheck.OnPremLineURI
                Break
            }
}

Function IS-LineUriSet
{         
    #Is LineUriSet set to 'null'
    #NULL is the disred value
          If([string]::IsNullOrWhiteSpace($TeamsCheck.LineURI))
                {
                    #If LineURI holds no value then the user is ready to be enabled
                    Write-Host -ForegroundColor Green "LineURI is OK"
                }
                Else
                {
                    #If LineURI holds a value (fx +4512345678) then that might need to be cleared
                    Write-Host -ForegroundColor Red "LineURI has the following value:" $TeamsCheck.LineURI
                    Break
                }

}

Function IS-RegistrarPoolSet
{
    #User needs to be in a RegistrarPool
    #Any pool with name *infra.lync.com at the end is the disered value
        if($TeamsCheck.RegistrarPool -ne $null)
        {
            Write-Host -ForegroundColor Green "RegistrarPool is OK"
        }
        Else
        {
            Write-Host -ForegroundColor Red "RegistrarPool has the following value:" $TeamsCheck.RegistrarPool
            Break
        }

}

Function IS-CoexistenceMode
{
    #If users Coexistence Mode -eq TeamsOnly then go
    If($TeamsCheck.TeamsUpgradeEffectiveMode -eq 'TeamsOnly')
    {
        Write-Host -ForegroundColor Green "Users CoexistenceMode is OK (TeamsOnly)"
    }
    elseif($TeamsCheck.TeamsUpgradeEffectiveMode -eq 'Island Mode')
    {
        Write-Host -ForegroundColor Green "Users CoexistenceMode is OK (Island)"
    }
    Else
    {
        Write-host -ForegroundColor Red "User is not in right mode:" $TeamsCheck.TeamsUpgradeEffectiveMode
    }
}

#Users to Process
$OUS = ""
$ADUsers = Foreach($OU in $OUS) {Get-ADUser -SearchBase $OU -Filter *}

Foreach ($User in $ADUsers)
{
    Try 
    {
        #Processing user infomation
        $TeamsCheck = Get-CsOnlineUser $User.UserPrincipalName
        If(([string]::IsNullOrEmpty($TeamsCheck.LineURI)))
        {
            Write-Host -ForegroundColor Cyan $TeamsCheck.DisplayName ($TeamsCheck.WindowsEmailAddress) "User found in AD - Getting ready to process user:" $UserInfo.SamAccountName

            #UserInfo
        $UsedBy = $TeamsCheck.Alias.ToUpper()
        $UserDepartment = $TeamsCheck.Department
      
    #SQL Querys:
    $Query_AvailableNumbers = "select * from $DBTableName1 where UsedBy IS NULL and ReservedFor IS NULL;"
    $Query_ResverdNumbers = "select * from $DBTableName1 where UsedBy IS NULL and ReservedFor='$UserDepartment';" #Needs varification

    #Get resvered numbers pr. department
    $ResveredNumbers = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DBName -AccessToken $AccessToken -Query $Query_ResverdNumbers -Verbose
    #Select the first avaible reserved phone number
    $FirstAvailableReservedNumber = $ResveredNumbers | Select-Object -First 1

    #First query to get availble numbers
    $AvailableNumbers = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DBName -AccessToken $AccessToken -Query $Query_AvailableNumbers -Verbose
    #Select the first availble phone number
    $FirstAvailableNumber = $AvailableNumbers | Select-Object -First 1

    $CountryCode2 = $FirstAvailableNumber.CountryCode   
    $Number = $FirstAvailableNumber.PSTNnumber
    $CountryCodeAndNumber = "$Countrycode2" + "$Number"

    $CountryCode = $FirstAvailableReservedNumber.CountryCode
    $ReservedNumber = $FirstAvailableReservedNumber.PSTNnumber
    $CountryCodeAndReservedNumber = "$CountryCode" + "$ReservedNumber"

    #XML file containing InterpretedUserType to lookup for actions
    [xml]$xml = Get-Content ".\InterpretedUserType.xml"
    $XMLnode = $TeamsCheck.InterpretedUserType
    $XML_Values=$xml.SelectNodes("/InterpretedUser/Type[@id='$XMLnode']")

    #Looking up user and determines if user can be enabled based on InterpretedUserType attribute in Teams
    #If the InterpretedUserType has "Proceed" under Action in the XML.
    Switch($XML_Values.action)
    {
        "Proceed" 
        {
            IS-OnPremLineURIManuallySet
            IS-OnPremLineUriSet
            IS-LineUriSet
            IS-RegistrarPoolSet
            IS-CoexistenceMode
            
            If([string]::IsNullOrWhiteSpace($FirstAvailableReservedNumber.ReservedFor))

            {
                EnableTeamsUser
            }
            Else
            {
                ReservedNumber
            }
                           

        }
        
        "Stop" 
        {
            Write-host -ForegroundColor Red $XML_Values.Description
            Write-Host -ForegroundColor Red $XML_Values.Solution
            Write-Host -ForegroundColor Yellow "Users Teams attributes are:"
            $TeamsCheck
        }
            
     }

        }
        else
        {
            #Skip user (User is complaint)
            Write-Host -ForegroundColor Yellow $User.SamAccountName "is Teams compliant"    
        }
    }
    Catch
        {
            Write-Host -ForegroundColor Red $User.SamAccountName "Something went wrong - User might not found in Teams."
        }
    

    
}
Stop-Transcript
