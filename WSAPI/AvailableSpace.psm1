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
##	File Name:		AvailableSpace.psm1
##	Description: 	Available space cmdlets 
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
## FUNCTION Get-CapacityInfo_WSAPI
############################################################################################################################################
Function Get-CapacityInfo_WSAPI 
{
  <#
  
  .SYNOPSIS
	Overall system capacity.
  
  .DESCRIPTION
	Overall system capacity.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .EXAMPLE
    Get-CapacityInfo_WSAPI
	Display Overall system capacity.
              
  .Notes
    NAME    : Get-CapacityInfo_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-CapacityInfo_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
  $WsapiConnection = $global:WsapiConnection
  )

  # Test if connection exist    
  Test-WSAPIConnection -WsapiConnection $WsapiConnection

  #Request 
  $Result = Invoke-WSAPI -uri '/capacity' -type 'GET' -WsapiConnection $WsapiConnection

  if($Result.StatusCode -eq 200)
  {
	  # Results
	  $dataPS = ($Result.content | ConvertFrom-Json)
  }
  else
  {
	return $Result.StatusDescription
  }
  # Add custom type to the resulting oject for formating purpose
  Write-DebugLog "Running: Add custom type to the resulting object for formatting purpose" $Debug
  #$AlldataPS = Format-Result -dataPS $dataPS -TypeName '3PAR.Capacity'
  
  Write-Verbose "Return result(s) without any filter"
  Write-DebugLog "End: Get-CapacityInfo_WSAPI(WSAPI)" $Debug
  return $dataPS
}
#END Get-CapacityInfo_WSAPI


Export-ModuleMember Get-CapacityInfo_WSAPI