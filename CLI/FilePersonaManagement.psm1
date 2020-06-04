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
##	File Name:		FilePersonaManagement.psm1
##	Description: 	File Persona Management cmdlets 
##		
##	Created:		November 2019
##	Last Modified:	November 2019
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

####################################################################################################################
########################################### FUNCTION Start-FSNDMP ##############################################
####################################################################################################################
Function Start-FSNDMP
{
<#
   .SYNOPSIS   
	The Start-FSNDMP command is used to start both NDMP service and ISCSI
    service. 
	
   .DESCRIPTION  
	The Start-FSNDMP command is used to start both NDMP service and ISCSI
	service.

   .EXAMPLE	
	Start-FSNDMP

   .PARAMETER SANConnection 
	Specify the SAN Connection object created with new-SANConnection

   .Notes
	NAME: Start-FSNDMP
	LASTEDIT: 19/11/2019
	KEYWORDS: Start-FSNDMP

   .Link
	Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(	
			
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Start-FSNDMP   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Start-FSNDMP   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Start-FSNDMP   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "startfsndmp "	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing  Start-FSNDMP command that displays information iSNS table for iSCSI ports in the system  " "INFO:"	
	write-host ""
	Return $Result
	
} # End Start-FSNDMP

####################################################################################################################
################################################ FUNCTION Stop-FSNDMP ##############################################
####################################################################################################################
Function Stop-FSNDMP
{
<#
  .SYNOPSIS   
	The Stop-FSNDMP command is used to stop both NDMP service and ISCSI
	service.
	
  .DESCRIPTION  
	The Stop-FSNDMP command is used to stop both NDMP service and ISCSI
	service.
	
  .EXAMPLE	
	Stop-FSNDMP	
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
	NAME: Stop-FSNDMP
	LASTEDIT: 19/11/2019
	KEYWORDS: Stop-FSNDMP

  .Link
	Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(	
			
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Stop-FSNDMP   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Stop-FSNDMP   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Stop-FSNDMP   since SAN connection object values are null/empty"
			}
		}
	}
	
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$cmd= "stopfsndmp "
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	
	write-debuglog "  Executing  Stop-FSNDMP command that displays information iSNS table for iSCSI ports in the system  " "INFO:"	
	write-host ""
	return $Result
	
} # End Stop-FSNDMP


Export-ModuleMember Start-FSNDMP , Stop-FSNDMP