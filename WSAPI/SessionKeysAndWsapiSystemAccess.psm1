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
##	File Name:		SessionKeysAndWsapiSystemAccess.psm1
##	Description: 	Session keys and WSAPI system access cmdlets 
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
## New-WSAPIConnection
############################################################################################################################################
Function New-WSAPIConnection {
<#	
  .SYNOPSIS
	Create a WSAPI session key
  
  .DESCRIPTION
	To use Web Services, you must create a session key. Use the same username and password that you use to
	access the 3PAR storage server through the 3PAR CLI or the 3PAR MC. Creating this authorization allows
	you to complete the same operations using WSAPI as you would the CLI or MC.
        
  .EXAMPLE
    New-3PARWSAPIConnection -ArrayFQDNorIPAddress 10.10.10.10 -SANUserName XYZ -SANPassword XYZ@123 -ArrayType 3par
	create a session key with 3par array.
	
  .EXAMPLE
    New-3PARWSAPIConnection -ArrayFQDNorIPAddress 10.10.10.10 -SANUserName XYZ -SANPassword XYZ@123 -ArrayType primera
	create a session key with 3par array.
	
  .PARAMETER UserName 
    Specify user name. 
	
  .PARAMETER Password 
    Specify password 
	
  .PARAMETER ArrayFQDNorIPAddress 
    Specify the Array FQDN or Array IP address.
	
  .PARAMETER ArrayType
	A type of array either 3Par or Primera. 
              
  .Notes
    NAME    : New-WSAPIConnection    
    LASTEDIT: January 2020
    KEYWORDS: New-WSAPIConnection
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
#>
[CmdletBinding()]
	param(
			[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
			[System.String]
			$ArrayFQDNorIPAddress,

			[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
			[System.String]
			$SANUserName=$null,

			[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
			[System.String]
			$SANPassword=$null ,

			[Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Enter array type : 3par or primera")]
			[ValidateSet("3par", "primera")]
			[System.String]
			$ArrayType
		)
#(self-signed) certificate,

if ($PSEdition -eq 'Core')
{
    
} 
else 
{

add-type @" 
using System.Net; 
using System.Security.Cryptography.X509Certificates; 
public class TrustAllCertsPolicy : ICertificatePolicy { 
	public bool CheckValidationResult( 
		ServicePoint srvPoint, X509Certificate certificate, 
		WebRequest request, int certificateProblem) { 
		return true; 
	} 
} 
"@  
		[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

#END of (self-signed) certificate,
		if(!($SANPassword))
		{
			$SANPassword1 = Read-host "SANPassword" -assecurestring
			#$globalpwd = $SANPassword1
			$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SANPassword1)
			$SANPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		}
		
		#Write-DebugLog "start: Entering function New-WSAPIConnection. Validating IP Address format." $Debug	
		#if(-not (Test-IPFormat $ArrayFQDNorIPAddress))		
		#{
		#	Write-DebugLog "Stop: Invalid IP Address $ArrayFQDNorIPAddress" "ERR:"
		#	return "FAILURE : Invalid IP Address $ArrayFQDNorIPAddress"
		#}
		
		#Write-DebugLog "Running: Completed validating IP address format." $Debug		
		#Write-DebugLog "Running: Authenticating credentials - Invoke-WSAPI for user $SANUserName and SANIP= $ArrayFQDNorIPAddress" $Debug
		
		#URL
		$APIurl = $null
		if($ArrayType.ToLower() -eq "3par")
		{
			$global:ArrayT = "3par" 
			$APIurl = "https://$($ArrayFQDNorIPAddress):8080/api/v1" 	
		}
		elseif($ArrayType.ToLower() -eq "primera")
		{
			$global:ArrayT = "Primera" 
			$APIurl = "https://$($ArrayFQDNorIPAddress):443/api/v1" 	
		}
		else
		{
			write-host " You have entered an unsupported Array type : $ArrayType . Please enter the array type as 3par or Primera." -foreground yello
			Return
		}
		
		#connect to 3PAR WSAPI
		$postParams = @{user=$SANUserName;password=$SANPassword} | ConvertTo-Json 
		$headers = @{}  
		$headers["Accept"] = "application/json" 
		
		Try
		{
			Write-DebugLog "Running: Invoke-WebRequest for credential data." $Debug
			if ($PSEdition -eq 'Core')
			{				
				$credentialdata = Invoke-WebRequest -Uri "$APIurl/credentials" -Body $postParams -ContentType "application/json" -Headers $headers -Method POST -UseBasicParsing -SkipCertificateCheck
			} 
			else 
			{				
				$credentialdata = Invoke-WebRequest -Uri "$APIurl/credentials" -Body $postParams -ContentType "application/json" -Headers $headers -Method POST -UseBasicParsing 
			}
		}
		catch
		{
			Write-DebugLog "Stop: Exception Occurs" $Debug
			Show-RequestException -Exception $_
			write-host ""
			write-host "FAILURE : While Establishing connection " -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Establishing connection " $Info
			throw
		}
		
		#$global:3parArray = $ArrayFQDNorIPAddress
		$key = ($credentialdata.Content | ConvertFrom-Json).key
		#$global:3parKey = $key
		if(!$key)
		{
			Write-DebugLog "Stop: No key Generated"
			return "Error: No key Generated"
		}
		
		$SANC1 = New-Object "WSAPIconObject"
		
		$SANC1.IPAddress = $ArrayFQDNorIPAddress					
		$SANC1.Key = $key
				
		$Result = Get-System_WSAPI -WsapiConnection $SANC1
		
		$SANC = New-Object "WSAPIconObject"
		
		$SANC.Id = $Result.id
		$SANC.Name = $Result.name
		$SANC.SystemVersion = $Result.systemVersion
		$SANC.Patches = $Result.patches
		$SANC.IPAddress = $ArrayFQDNorIPAddress
		$SANC.Model = $Result.model
		$SANC.SerialNumber = $Result.serialNumber
		$SANC.TotalCapacityMiB = $Result.totalCapacityMiB
		$SANC.AllocatedCapacityMiB = $Result.allocatedCapacityMiB
		$SANC.FreeCapacityMiB = $Result.freeCapacityMiB					
		$SANC.Key = $key
		
		$global:WsapiConnection = $SANC
		
		
		Write-DebugLog "End: If there are no errors reported on the console then the SAN connection object is set and ready to be used" $Info		
		#Write-Verbose -Message "Acquired token: $global:3parKey"
		Write-Verbose -Message 'You are now connected to the HP 3PAR StoreServ Array.'
		Write-Verbose -Message 'Show array informations:'	
		
		return $SANC
}
#End of New-WSAPIConnection

############################################################################################################################################
## FUNCTION Close-WSAPIConnection
############################################################################################################################################
Function Close-WSAPIConnection
 {
  <#

  .SYNOPSIS
	Delete a session key.
  
  .DESCRIPTION
	When finishes making requests to the server it should delete the session keys it created .
	Unused session keys expire automatically after the configured session times out.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .EXAMPLE
    Close-WSAPIConnection
	Delete a session key.
              
  .Notes
    NAME    : Close-WSAPIConnection    
    LASTEDIT: January 2020
    KEYWORDS: Close-WSAPIConnection
   
  .Link
     Http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>
  [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]
  Param(
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	$WsapiConnection = $global:WsapiConnection 
  )
  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    if ($pscmdlet.ShouldProcess($h.name,"Disconnect from array")) 
	{
      #Build uri
	  
	  #$ip = $WsapiConnection.IPAddress
	  $key = $WsapiConnection.Key
	  
	  Write-DebugLog "Running: Building uri to close wsapi connection ." $Debug
      $uri = '/credentials/'+$key

      #init the response var
      $data = $null

      #Request
	  Write-DebugLog "Request: Request to close wsapi connection (Invoke-3parWSAPI)." $Debug
      $data = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection

	  $global:WsapiConnection = $null
	  
	  return $data
	  <#
      If ($global:3parkey) 
	  {
        Write-Verbose -Message "Delete key session: $global:3parkey"
        Remove-Variable -name 3parKey -scope global
		Write-DebugLog "End: Key Deleted" $Debug
      }
	  If ($global:3parArray) 
	  {
        Write-Verbose -Message "Delete Array: $global:3parArray"
        Remove-Variable -name 3parArray -scope global
		Write-DebugLog "End: Delete Array: $global:3parArray" $Debug
      }
	  #>
    }
	Write-DebugLog "End: Close-WSAPIConnection" $Debug
  }
  End {}  
}
#END Close-WSAPIConnection

Export-ModuleMember New-WSAPIConnection , Close-WSAPIConnection