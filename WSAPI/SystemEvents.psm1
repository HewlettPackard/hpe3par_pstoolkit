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
##	File Name:		SystemEvents.psm1
##	Description: 	System Events cmdlets 
##		
##	Created:		February 2020
##	Last Modified:	February 2020
##	History:		v3.0 - Created	
#####################################################################################

$Info = "INFO:"
$Debug = "DEBUG:"
$global:VSLibraries = Split-Path $MyInvocation.MyCommand.Path
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

############################################################################################################################################
## FUNCTION Open-SSE_WSAPI
############################################################################################################################################
Function Open-SSE_WSAPI 
{
  <#   
  .SYNOPSIS	
	Establishing a communication channel for Server-Sent Event (SSE).
  
  .DESCRIPTION
	Establishing a communication channel for Server-Sent Event (SSE) 
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
        
  .EXAMPLE
	Open-SSE_WSAPI
	
  .Notes
    NAME    : Open-SSE_WSAPI   
    LASTEDIT: 06/06/2018
    KEYWORDS: Open-SSE_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-WSAPIConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null	
	
	
	#Request
	
	$Result = Invoke-WSAPI -uri '/eventstream' -type 'GET' -WsapiConnection $WsapiConnection
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members
	}	
		
		  
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Open-SSE_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Open-SSE_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Open-SSE_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Open-SSE_WSAPI

############################################################################################################################################
## FUNCTION Get-EventLogs_WSAPI
############################################################################################################################################
Function Get-EventLogs_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all past events from system event logs or a logged event information for the available resources. 
  
  .DESCRIPTION
	Get all past events from system event logs or a logged event information for the available resources. 
        
  .EXAMPLE
	Get-EventLogs_WSAPI
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-EventLogs_WSAPI   
    LASTEDIT: 20/02/2018
    KEYWORDS: Get-EventLogs_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-WSAPIConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null	
	
	
	#Request
	
	$Result = Invoke-WSAPI -uri '/eventlog' -type 'GET' -WsapiConnection $WsapiConnection
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members
	}	
		
		  
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-EventLogs_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-EventLogs_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-EventLogs_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-EventLogs_WSAPI

Export-ModuleMember Open-SSE_WSAPI , Get-EventLogs_WSAPI