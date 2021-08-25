# MSTeams-PhoneNumberMgmt 

A project to manage PSTN phone numbers using PowerShell in combination with a SQL DB and Power BI 

##### About: 

This project is created with a dream to ease the management of phone numbers provided to an organization by an external provider (Telecommunications company's like T-Mobil or TDC). Phone numbers are often provided in an Excel spreadsheet and System administrator in charge needs to assign the number “by hand” and remember to update the spreadsheet. 

This project aims to ease that pain by having the phone numbers in a database and Power BI report to display insight in to how the numbers are used and then a couple of PowerShell scripts to assign phone numbers and then a PowerShell script to “clean up” the database. 
  

##### PowerShell script - Assign Phone number: 

The PowerShell script will assign the first available phone number (PSTN) it can find in the DB and assign it to the user and then ‘enable’ the user to use PSTN calling in Teams 

 

##### PowerShell script – DB maintenance: 

This PowerShell script will look for users that a no longer using their phone number and remove the user from the database 
 

##### Database 

The database contains the following data: 
* Phone number 
* Used by 
* Department 
* Reserved for 

##### Power BI report 

The reports display insight in to how the phone numbers are assigned.  
