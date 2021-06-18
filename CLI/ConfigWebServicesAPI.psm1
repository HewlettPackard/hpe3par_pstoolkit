####################################################################################
## 	© 2020,2021 Hewlett Packard Enterprise Development LP
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
##	File Name:		ConfigWebServicesAPI.psm1
##	Description: 	Configure Web Services API cmdlets 
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
## FUNCTION Test-CLIObject
############################################################################################################################################
Function Test-CLIObject 
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
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmds
	if ($Result -like "no $ObjectMsg listed")
	{
		$IsObjectExisted = $false
	}
	return $IsObjectExisted
	
} # End FUNCTION Test-CLIObject

##########################################################################
#########################FUNCTION Get-Wsapi#########################
##########################################################################
Function Get-Wsapi()
{
<#
  .SYNOPSIS
   Get-Wsapi - Show the Web Services API server information.

  .DESCRIPTION
   The Get-Wsapi command displays the WSAPI server service configuration state
   as either Enabled or Disabled. It displays the server current running
   status as Active, Inactive or Error. It also displays the current status
   of the HTTP and HTTPS ports and their port numbers. WSAPI server URL is
   also displayed.

  .EXAMPLE
   Get-Wsapi -D

  .PARAMETER D
   Shows WSAPI information in table format.

  .PARAMETER SANConnection 
   Specify the SAN Connection object created with new-SANConnection  
   
  .Notes
    NAME: Get-Wsapi
    LASTEDIT January 2020
    KEYWORDS: Get-Wsapi
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$D,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-Wsapi - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-Wsapi since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-Wsapi since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

 $Cmd = " showwsapi "

 if($D)
 {
	$Cmd += " -d "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-Wsapi Command -->" INFO: 
 
 if($Result -match "-Service-")
	{
		$range = $Result.count
		$tempFile = [IO.Path]::GetTempFileName()
		foreach ($s in  $Result[0..$range] )
		{			
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			$s= $s.Trim() -replace '-Service-,-State-,-HTTP_State-,HTTP_Port,-HTTPS_State-,HTTPS_Port,-Version-,-------------API_URL--------------','Service,State,HTTP_State,HTTP_Port,HTTPS_State,HTTPS_Port,ersion,API_URL'			
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
 
} ##  End-of Get-Wsapi

##########################################################################
#########################FUNCTION Get-WsapiSession#########################
##########################################################################
Function Get-WsapiSession()
{
<#
  .SYNOPSIS
   Get-WsapiSession - Show the Web Services API server sessions information.

  .DESCRIPTION
   The Get-WsapiSession command displays the WSAPI server sessions
   connection information, including the id, node, username, role, hostname,
   and IP Address of the connecting client. It also displays the session
   creation time and session type.

  .EXAMPLE
	Get-WsapiSession
  
  .PARAMETER SANConnection 
   Specify the SAN Connection object created with new-SANConnection
   
  .Notes
    NAME: Get-WsapiSession
    LASTEDIT January 2020
    KEYWORDS: Get-WsapiSession
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-WsapiSession - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
  #check if connection object contents are null/empty
  $Validate1 = Test-CLIConnection $SANConnection
  if($Validate1 -eq "Failed")
  {
    #check if global connection object contents are null/empty
    $Validate2 = Test-CLIConnection $global:SANConnection
    if($Validate2 -eq "Failed")
    {
        Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-SANConnection" " ERR: "
        Write-DebugLog "Stop: Exiting Get-WsapiSession since SAN connection object values are null/empty" $Debug 
        Return "Unable to execute the cmdlet Get-WsapiSession since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
    }
  }
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " showwsapisession "

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-WsapiSession Command" INFO: 
	if($Result.Count -gt 2)
	{
		$range = $Result.count - 3
		$tempFile = [IO.Path]::GetTempFileName()
		foreach ($s in  $Result[0..$range] )
		{			
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			$s= $s.Trim() -replace 'Id,Node,-Name--,-Role-,-Client_IP_Addr-,----Connected_since----,-State-,-Session_Type-','Id,Node,Name,Role,Client_IP_Addr,Connected_since,State,Session_Type'			
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	} 
 
} ##  End-of Get-WsapiSession

##########################################################################
#########################FUNCTION Remove-WsapiSession#########################
##########################################################################
Function Remove-WsapiSession()
{
<#
  .SYNOPSIS
   Remove-WsapiSession - Remove WSAPI user connections.

  .DESCRIPTION
   The Remove-WsapiSession command removes the WSAPI user connections from the
   current system.

  .EXAMPLE
	Remove-WsapiSession -Id "1537246327049685" -User_name 3parxyz -IP_address "10.10.10.10"
	
  .PARAMETER Pat
   Specifies that the <id>, <user_name> and <IP_address> specifiers
   are treated as glob-style (shell-style) patterns and all WSAPI user
   connections matching those patterns are removed. By default,
   confirmation is required to proceed with removing each connection
   unless the -f option is specified.

  .PARAMETER Dr
   Specifies that the operation is a dry run and no connections are
   removed.

  .PARAMETER Close_sse
   Specifies that the Server Sent Event (SSE) connection channel will be
   closed. WSAPI session credential for SSE will not be removed.

  .PARAMETER id
   Specifies the Id of the WSAPI session connection to be removed.

  .PARAMETER user_name
   Specifies the name of the WSAPI user to be removed.

  .PARAMETER IP_address
   Specifies the IP address of the WSAPI user to be removed.
   
  .PARAMETER SANConnection 
   Specify the SAN Connection object created with new-SANConnection
   
  .Notes
    NAME: Remove-WsapiSession
    LASTEDIT January 2020
    KEYWORDS: Remove-WsapiSession
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 [Parameter(Position=0, Mandatory=$false)]
 [switch]
 $Pat,

 [Parameter(Position=1, Mandatory=$false)]
 [switch]
 $Dr,

 [Parameter(Position=3, Mandatory=$false)]
 [switch]
 $Close_sse,

 [Parameter(Position=4, Mandatory=$true)]
 [System.String]
 $Id,

 [Parameter(Position=5, Mandatory=$true)]
 [System.String]
 $User_name,

 [Parameter(Position=6, Mandatory=$true)]
 [System.String]
 $IP_address,

 [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Remove-WsapiSession - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
  #check if connection object contents are null/empty
  $Validate1 = Test-CLIConnection $SANConnection
  if($Validate1 -eq "Failed")
  {
    #check if global connection object contents are null/empty
    $Validate2 = Test-CLIConnection $global:SANConnection
    if($Validate2 -eq "Failed")
    {
        Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-SANConnection" " ERR: "
        Write-DebugLog "Stop: Exiting Remove-WsapiSession since SAN connection object values are null/empty" $Debug 
        Return "Unable to execute the cmdlet Remove-WsapiSession since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
    }
  }
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " removewsapisession -f"

 if($Pat)
 {
  $Cmd += " -pat "
 }

 if($Dr)
 {
  $Cmd += " -dr "
 }
 if($Close_sse)
 {
  $Cmd += " $Close_sse "
 }

 if($Id)
 {
  $Cmd += " $Id "
 }

 if($User_name)
 {
  $Cmd += " $User_name "
 }

 if($IP_address)
 {
  $Cmd += " IP_address "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Remove-WsapiSession Command --> " INFO: 
 Return $Result
} ##  End-of Remove-WsapiSession

##########################################################################
#########################FUNCTION Set-Wsapi#########################
##########################################################################
Function Set-Wsapi()
{
<#
  .SYNOPSIS
   Set-Wsapi - Set the Web Services API server properties.

  .DESCRIPTION
   The Set-Wsapi command sets properties of the Web Services API server,
   including options to enable or disable the HTTP and HTTPS ports.

  .EXAMPLE
	Set-Wsapi -Force -Enable_Http

  .PARAMETER Force
   Forces the operation of the setwsapi command, bypassing the typical
   confirmation message.
   At least one of the following options are required:

  .PARAMETER Pol
   Sets the WSAPI server policy:
   tls_strict       - only TLS connections using TLS 1.2 with
   secure ciphers will be accepted if HTTPS is
   enabled. This is the default policy setting.
   no_tls_strict    - TLS connections using TLS 1.0 - 1.2 will be
   accepted if HTTPS is enabled.

  .PARAMETER Timeout
   Specifies the value that can be set for the idle session timeout for
   a WSAPI session. <value> is a positive integer and in the range
   of 3-1440 minutes or (3 minutes to 24 hours). Changing the session
   timeout takes effect immediately and will affect already opened and
   subsequent WSAPI sessions.
   The default timeout value is 15 minutes.

  .PARAMETER Evtstream
   Enables or disables the event stream feature. This supports Server
   Sent Event (SSE) protocol.
   The default value is enable.
   
  .PARAMETER SANConnection 
   Specify the SAN Connection object created with new-SANConnection
   
  .Notes
    NAME: Set-Wsapi
    LASTEDIT January 2020
    KEYWORDS: Set-Wsapi
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Force,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Pol,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Timeout,

	[Parameter(Position=3, Mandatory=$false)]
	[System.String]
	$Evtstream,

	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Set-Wsapi - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Set-Wsapi since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Set-Wsapi since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " setwsapi "

 if($Force)
 {
	$Cmd += " -f "
 }

 if($Pol)
 {
	$Cmd += " -pol $Pol "
 }

 if($Timeout)
 {
	$Cmd += " -timeout $Timeout "
 }

 if($Evtstream)
 {
	$Cmd += " -evtstream $Evtstream "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Set-Wsapi Command --> " INFO: 
 
 Return $Result
} ##  End-of Set-Wsapi

##########################################################################
#########################FUNCTION Start-Wsapi#########################
##########################################################################
Function Start-Wsapi()
{
<#
  .SYNOPSIS
   Start-Wsapi - Start the Web Services API server to service HTTP and HTTPS requests.

  .DESCRIPTION
   The Start-Wsapi command starts the Web Services API server to service
   HTTP and HTTPS requests.
   By default, the Web Services API server is not started until this
   command is issued.

  .EXAMPLE
   Start-Wsapi

  .Notes
    NAME: Start-Wsapi
    LASTEDIT January 2020
    KEYWORDS: Start-Wsapi
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	 [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	 $SANConnection = $global:SANConnection
 )
 
 Write-DebugLog "Start: In Start-Wsapi - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Start-Wsapi since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Start-Wsapi since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }
 
	$cmd= " startwsapi "
 
 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd 
 
	return $Result	
 
}
#End Of Start-Wsapi

##########################################################################
#########################FUNCTION Stop-Wsapi#########################
##########################################################################
Function Stop-Wsapi()
{
<#
  .SYNOPSIS
   Stop-Wsapi - Stop the Web Services API server. Future HTTP and HTTPS requests
   will be rejected.

  .DESCRIPTION
   The Stop-Wsapi command stops the Web Services API server from servicing
   HTTP and HTTPS requests.

  .EXAMPLE
	Stop-Wsapi

  .Notes
    NAME: Stop-Wsapi
    LASTEDIT January 2020
    KEYWORDS: Stop-Wsapi
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Stop-Wsapi - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Stop-Wsapi since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Stop-Wsapi since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

 $Cmd = " stopwsapi -f "

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Stop-Wsapi Command -->" INFO: 
 
 Return $Result
} ##  End-of Stop-Wsapi

Export-ModuleMember Get-Wsapi , Get-WsapiSession , Remove-WsapiSession , Set-Wsapi , Start-Wsapi , Stop-Wsapi