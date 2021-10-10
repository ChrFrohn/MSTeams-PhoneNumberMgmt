# MSTeams-PhoneNumberMgmt 
# Still work in progress
A project to manage PSTN phone numbers using PowerShell in combination with a SQL DB and Power BI 

## About: 

This project is created with a dream to ease the management of phone numbers provided to an organization by an external provider (Telecommunications company's like T-Mobil or TDC). Phone numbers are often provided in an Excel spreadsheet and System administrator in charge needs to assign the number “by hand” and remember to update the spreadsheet. 

This project aims to ease that pain by having the phone numbers in a database and Power BI report to display insight in to how the numbers are used and then a couple of PowerShell scripts to assign phone numbers and then a PowerShell script to “clean up” the database. 
  
### Installation / Configuration - Quick and dirty

- Create a Azure SQL manage instance
- Create a table using the SQL query - CreateTables.sql found in this repo
- Create a Azure App reg and assig SQL write permission to it using SQL query lauange on the SQL manage instance
- Then add the app reg information to the PowerShell scripts
- Find the "$OUs" variable in the script and then all the OU's in Active Directory you want to process.
- Create a task schedule for the script "EnableAndAssignPhoneNumber.ps1"
- Create a task schedule for the script "DB-Maintenance.ps1"

### Installation / Configuration - Detailed

- coming soon

---------------------------------------------------- -------------------------- -------------------------- --------------------------  

### PowerShell script - Assign Phone number: 

The PowerShell script will assign the first available phone number (PSTN) it can find in the DB and assign it to the user and then ‘enable’ the user to use PSTN calling in Teams 
- There is a function for reserved numbers. Currently if it only looks at the department attribute. Say a user is in "IT" department then if a number is reserved for "IT" then the user will get the first available that is reserved for IT. otherwise the user will get the first available number.
 

### PowerShell script – DB maintenance: 

This PowerShell script will first look at all users in Teams and add them to the database. After that the script will look up all users in the database in Teams.
This is to ensure that the numberserie is always up to date.
 

### Database 

The database contains the following data: 
* Phone number 
* Used by 
* Department 
* Reserved for 

### Power BI report 

The reports display insight in to how the phone numbers are assigned.

### To-do / Bug fixes:
* Change authentication method against Teams to use a Service Principle insted of a regular user (Currently auth. method with SP is broken)
* Better error handling
* Maybe URL to XML file for InterpretedUserType
* Update Active Directory OfficePhone attribute with assigned phone number
