####################################################################################
## 	© 2019,2020 Hewlett Packard Enterprise Development LP
##
## 	Permission is hereby granted, free of charge, to any person obtaining a
## 	copy of this software and associated documentation files (the "Software"),
## 	to deal in the Software without restriction, including without limitation
## 	the rights to use, copy, modify, merge, publish, distribute, sublicense,
## 	and/or sell copies of the Software, and to permit persons to whom the
## 	Software is furnished to do so, subject to the following conditions:
##
## 	The above copyright notice and this permission notice shall be included
## 	in all copies or substantial portions of the Software.
##
## 	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## 	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## 	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
## 	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
## 	OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
## 	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
## 	OTHER DEALINGS IN THE SOFTWARE.
##
##	File Name:		UserManagement.psm1
##	Description: 	User Management cmdlets 
##		
##	Created:		January 2020
##	Last Modified:	January 2020
##	History:		v3.0 - Created	
#####################################################################################

$Info = "INFO:"
$Debug = "DEBUG:"
$global:VSLibraries = Split-Path $MyInvocation.MyCommand.Path
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

############################################################################################################################################
## FUNCTION Test-3parObject
############################################################################################################################################
Function Test-3parobject 
{
Param( 	
    [string]$ObjectType, 
	[string]$ObjectName ,
	[string]$ObjectMsg = $ObjectType, 
	$SANConnection = $global:SANConnection
	)

	$IsObjectExisted = $True
	$ObjCmd = $ObjectType -replace ' ', '' 
	$Cmds = "show$ObjCmd $ObjectName"
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmds
	if ($Result -like "no $ObjectMsg listed")
	{
		$IsObjectExisted = $false
	}
	return $IsObjectExisted
	
} # End FUNCTION Test-3parObject

######################################################################################
################################## FUNCTION Get-UserConnection #######################
######################################################################################
Function Get-UserConnection{
<#
  .SYNOPSIS
    Displays information about users who are currently connected (logged in) to the storage system.  
  
  .DESCRIPTION
	Displays information about users who are currently connected (logged in) to the storage system.
    
  .EXAMPLE
    Get-UserConnection  
	Shows information about users who are currently connected (logged in) to the storage system.
	 
  .EXAMPLE
    Get-UserConnection   -Current
	Shows all information about the current connection only.
   
  .EXAMPLE
    Get-UserConnection   -Detailed
	Specifies the more detailed information about the user connection

  .PARAMETER Current
	Shows all information about the current connection only.
		
  .PARAMETER Detailed
	Specifies the more detailed information about the user connection.
		
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-PoshSshConnection or New-CLIConnection
	
  .Notes
    NAME:   Get-UserConnection
    LASTEDIT: January 2020
    KEYWORDS:  Get-UserConnection
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3par cli.exe 
 #>
 
[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Current ,
		
		[Parameter(Position=1,Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Detailed ,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
      
	)
	Write-DebugLog "Start: In Get-UserConnection - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-UserConnection since SAN connection object values are null/empty" $Debug
				return "Failure : Exiting Get-UserConnection since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$cmd2 = "showuserconn "
	
	if ($Current)
	{
		$cmd2 += " -current "			
	}
	if($Detailed)
	{
		$cmd2 += " -d "
		$result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd2
		return $result
	}
	$result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd2
	$count = $result.count - 3
	$tempFile = [IO.Path]::GetTempFileName()
	Add-Content -Path $tempFile -Value "Id,Name,IP_Addr,Role,Connected_since_Date,Connected_since_Time,Connected_since_TimeZone,Current,Client,ClientName"
	foreach($s in $result[1..$count])
	{
		$s= [regex]::Replace($s,"^ +","")
		$s= [regex]::Replace($s," +"," ")
		$s= [regex]::Replace($s," ",",")
		$s = $s.trim()
		Add-Content -Path $tempFile -Value $s
	}
	Import-CSV $tempFile
	del $tempFile
} #End Get-UserConnection

#################################################################################
########################## FUNCTION Set-Password ################################
#################################################################################
Function Set-Password
{
<#
  .SYNOPSIS
	Creates a encrypted password file on client machine
  
  .DESCRIPTION
	Creates a encrypted password file on client machine
        
  .EXAMPLE
    Set-Password -CLIDir "C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin" -ArrayNameOrIPAddress "15.212.196.218"  -epwdFile "C:\HPE3paradmepwd.txt"	
	This examples stores the encrypted password file HPE3paradmepwd.txt on client machine c:\ drive, subsequent commands uses this encryped password file 
	 
  .PARAMETER ArrayNameOrIPAddress 
    Specify the SAN IP address.
    
  .PARAMETER CLIDir 
    Specify the absolute path of HPE 3par cli.exe. Default is "C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin"
  
  .PARAMETER epwdFile 
    Specify the file location to create encrypted password file
	
  .Notes
    NAME:   Set-Password
    LASTEDIT: January 2020
    KEYWORDS:  Set-Password
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3par cli.exe 
 #>
 
[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=$false, ValueFromPipeline=$true)]
		[System.string]
		$CLIDir="C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		[Parameter(Position=1,Mandatory=$true, ValueFromPipeline=$true)]
		[System.string]
		$ArrayNameOrIPAddress=$null,
		[Parameter(Position=2,Mandatory=$true, ValueFromPipeline=$true)]
		[System.string]
		$epwdFile ="C:\HPE3parepwdlogin.txt"
       
	)	
	#write-host "In connection"
	if( Test-Path $epwdFile)
	{
		Write-DebugLog "Running: HPE 3par encrypted password file was found , it will overwrite the mentioned file" "INFO:"
	}	
	$passwordFile = $epwdFile	
	$cmd1 = $CLIDir+"\setpassword.bat" 
	& $cmd1 -saveonly -sys $ArrayNameOrIPAddress -file $passwordFile
	if(!($?	))
	{
		Write-DebugLog "STOP: HPE 3par System's  cli dir path or system is not accessible or commands.bat file path was not configured properly " "ERR:"
		return "`nFailure : FATAL ERROR"
	}
	#$cmd2 = "setpassword.bat -saveonly -sys $ArrayNameOrIPAddress -file $passwordFile"
	#Invoke-expression $cmd2
	$global:epwdFile = $passwordFile
	Write-DebugLog "Running: HPE 3par System's encrypted password file has been created successfully and the file location is $passwordfile " "INFO:"
	return "Success : HPE 3par System's encrypted password file has been created successfully and the file location : $passwordfile"

} #End Set-Password

Export-ModuleMember Get-UserConnection , Set-Password