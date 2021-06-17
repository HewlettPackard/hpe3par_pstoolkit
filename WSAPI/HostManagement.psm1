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
##	File Name:		HostManagement.psm1
##	Description: 	Host Management cmdlets 
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
## FUNCTION New-Host_WSAPI
############################################################################################################################################
Function New-Host_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creates a new host.
	
  .DESCRIPTION    
  	Creates a new host.
    Any user with Super or Edit role, or any role granted host_create permission, can perform this operation. Requires access to all domains.    
	
  .EXAMPLE
	New-Host_WSAPI -HostName MyHost
    Creates a new host.
	
  .EXAMPLE
	New-Host_WSAPI -HostName MyHost -Domain MyDoamin	
	Create the host MyHost in the specified domain MyDoamin.
	
  .EXAMPLE
	New-Host_WSAPI -HostName MyHost -Domain MyDoamin -FCWWN XYZ
	Create the host MyHost in the specified domain MyDoamin with WWN XYZ
	
  .EXAMPLE
	New-Host_WSAPI -HostName MyHost -Domain MyDoamin -FCWWN XYZ -Persona GENERIC_ALUA
	
  .EXAMPLE	
	New-Host_WSAPI -HostName MyHost -Domain MyDoamin -Persona GENERIC
	
  .EXAMPLE	
	New-Host_WSAPI -HostName MyHost -Location 1
		
  .EXAMPLE
	New-Host_WSAPI -HostName MyHost -IPAddr 1.0.1.0
		
  .EXAMPLE	
	New-Host_WSAPI -HostName $hostName -Port 1:0:1
	
  .PARAMETER HostName
	Specifies the host name. Required for creating a host.
	
  .PARAMETER Domain
	Create the host in the specified domain, or in the default domain, if unspecified.
	
  .PARAMETER FCWWN
	Set WWNs for the host.
	
  .PARAMETER ForceTearDown
	If set to true, forces tear down of low-priority VLUN exports.
	
  .PARAMETER ISCSINames
	Set one or more iSCSI names for the host.
	
  .PARAMETER Location
	The host’s location.
	
  .PARAMETER IPAddr
	The host’s IP address.
	
  .PARAMETER OS
	The operating system running on the host.
	
  .PARAMETER Model
	The host’s model.
	
  .PARAMETER Contact
	The host’s owner and contact.
	
  .PARAMETER Comment
	Any additional information for the host.
	
  .PARAMETER Persona
	Uses the default persona "GENERIC_ALUA" unless you specify the host persona.
	1	GENERIC
	2	GENERIC_ALUA
	3	GENERIC_LEGACY
	4	HPUX_LEGACY
	5	AIX_LEGACY
	6	EGENERA
	7	ONTAP_LEGACY
	8	VMWARE
	9	OPENVMS
	10	HPUX
	11	WindowsServer
	12	AIX_ALUA
	
  .PARAMETER Port
	Specifies the desired relationship between the array ports and the host for target-driven zoning. Use this option when the Smart SAN license is installed only.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : New-Host_WSAPI    
    LASTEDIT: 24/01/2018
    KEYWORDS: New-Host_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $HostName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Domain,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [String[]]
	  $FCWWN,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Boolean]
	  $ForceTearDown,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [String[]]
	  $ISCSINames,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Location,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $IPAddr,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $OS,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Model,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Contact,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Comment,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Persona,

	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [String[]]
	  $Port,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
      $WsapiConnection = $global:WsapiConnection 
  )

  Begin 
  {
    # Test if connection exist
    Test-WSAPIConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    # Creation of the body hash
	Write-DebugLog "Running: Creation of the body hash" $Debug
    $body = @{}    
    $body["name"] = "$($HostName)"
   
    If ($Domain) 
    {
		$body["domain"] = "$($Domain)"
    }
    
    If ($FCWWN) 
    {
		$body["FCWWNs"] = $FCWWN
    } 
	
    If ($ForceTearDown) 
	{
		$body["forceTearDown"] = $ForceTearDown
    }
	
	If ($ISCSINames) 
    {
		$body["iSCSINames"] = $ISCSINames
    }
	
	If ($Persona) 
    {
		if($Persona -eq "GENERIC")
		{
			$body["persona"] = 1
		}
		elseif($Persona -eq "GENERIC_ALUA")
		{
			$body["persona"] = 2
		}
		elseif($Persona -eq "GENERIC_LEGACY")
		{
			$body["persona"] = 3
		}
		elseif($Persona -eq "HPUX_LEGACY")
		{
			$body["persona"] = 4
		}
		elseif($Persona -eq "AIX_LEGACY")
		{
			$body["persona"] = 5
		}
		elseif($Persona -eq "EGENERA")
		{
			$body["persona"] = 6
		}
		elseif($Persona -eq "ONTAP_LEGACY")
		{
			$body["persona"] = 7
		}
		elseif($Persona -eq "VMWARE")
		{
			$body["persona"] = 8
		}
		elseif($Persona -eq "OPENVMS")
		{
			$body["persona"] = 9
		}
		elseif($Persona -eq "HPUX")
		{
			$body["persona"] = 10
		}
		elseif($Persona -eq "WindowsServer")
		{
			$body["persona"] = 11
		}
		elseif($Persona -eq "AIX_ALUA")
		{
			$body["persona"] = 12
		}
		else
		{
			Write-DebugLog "Stop: Exiting  New-Host_WSAPI since Persona $Persona in incorrect "
			Return "FAILURE : Persona :- $Persona is an Incorrect Please Use [ GENERIC | GENERIC_ALUA | GENERIC_LEGACY | HPUX_LEGACY | AIX_LEGACY | EGENERA | ONTAP_LEGACY | VMWARE | OPENVMS | HPUX | WindowsServer | AIX_ALUA] only. "
		}		
    }
	
	If ($Port) 
    {
		$body["port"] = $Port
    }
	
	$DescriptorsBody = @{}   
	
	If ($Location) 
    {
		$DescriptorsBody["location"] = "$($Location)"
    }
	
	If ($IPAddr) 
    {
		$DescriptorsBody["IPAddr"] = "$($IPAddr)"
    }
	
	If ($OS) 
    {
		$DescriptorsBody["os"] = "$($OS)"
    }
	
	If ($Model) 
    {
		$DescriptorsBody["model"] = "$($Model)"
    }
	
	If ($Contact) 
    {
		$DescriptorsBody["contact"] = "$($Contact)"
    }
	
	If ($Comment) 
    {
		$DescriptorsBody["Comment"] = "$($Comment)"
    }
	
	if($DescriptorsBody.Count -gt 0)
	{
		$body["descriptors"] = $DescriptorsBody 
	}
    
    $Result = $null
	
	#$json = $body | ConvertTo-Json  -Compress -Depth 10
	#write-host " Body = $json"
	
    #Request
    $Result = Invoke-WSAPI -uri '/hosts' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Host:$HostName successfully created" $Info
		
		Get-Host_WSAPI -HostName $HostName
		Write-DebugLog "End: New-Host_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating Host:$HostName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating Host:$HostName " $Info
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG New-Host_WSAPI

############################################################################################################################################
## FUNCTION Add-RemoveHostWWN_WSAPI
############################################################################################################################################
Function Add-RemoveHostWWN_WSAPI 
{
  <#
  
  .SYNOPSIS
	Add or remove a host WWN from target-driven zoning
	
  .DESCRIPTION    
  	Add a host WWN from target-driven zoning.
    Any user with Super or Edit role, or any role granted host_create permission, can perform this operation. Requires access to all domains.    
	
  .EXAMPLE
	Add-RemoveHostWWN_WSAPI -HostName MyHost -FCWWNs "$wwn" -AddWwnToHost
	
  .EXAMPLE	
	Add-RemoveHostWWN_WSAPI -HostName MyHost -FCWWNs "$wwn" -RemoveWwnFromHost
	
  .PARAMETER HostName
	Host Name.

  .PARAMETER FCWWNs
	WWNs of the host.
	
  .PARAMETER Port
	Specifies the ports for target-driven zoning.
	Use this option when the Smart SAN license is installed only.
	This field is NOT supported for the following actions:ADD_WWN_TO_HOST REMOVE_WWN_FROM_H OST,
	It is a required field for the following actions:ADD_WWN_TO_TZONE REMOVE_WWN_FROM_T ZONE.
	
  .PARAMETER AddWwnToHost
	its a action to be performed.
	Recommended method for adding WWN to host. Operates the same as using a PUT method with the pathOperation specified as ADD.

  .PARAMETER RemoveWwnFromHost
	Recommended method for removing WWN from host. Operates the same as using the PUT method with the pathOperation specified as REMOVE.
	
  .PARAMETER AddWwnToTZone   
	Adds WWN to target driven zone. Creates the target driven zone if it does not exist, and adds the WWN to the host if it does not exist.
	
  .PARAMETER RemoveWwnFromTZone
	Removes WWN from the targetzone. Removes the target driven zone unless it is the last WWN. Does not remove the last WWN from the host.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Add-RemoveHostWWN_WSAPI    
    LASTEDIT: 24/01/2018
    KEYWORDS: Add-RemoveHostWWN_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $HostName,
	  
	  [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [String[]]
	  $FCWWNs,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [String[]]
	  $Port,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $AddWwnToHost,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $RemoveWwnFromHost,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $AddWwnToTZone,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $RemoveWwnFromTZone,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection 
  )

  Begin 
  {
    # Test if connection exist
    Test-WSAPIConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    # Creation of the body hash
	Write-DebugLog "Running: Creation of the body hash" $Debug
    $body = @{}
   
    If($AddWwnToHost) 
    {
		$body["action"] = 1
    }
	elseif($RemoveWwnFromHost)
	{
		$body["action"] = 2
	}
	elseIf($AddWwnToTZone) 
    {
		$body["action"] = 3
    }
	elseif($RemoveWwnFromTZone)
	{
		$body["action"] = 4
	}
	else
	{
		return "Please Select at-list one on above Action [AddWwnToHost | AddWwnToTZone | AddWwnToTZone | RemoveWwnFromTZone]"
	}
	
	$ParametersBody = @{} 
	
    If($FCWWNs) 
    {
		$ParametersBody["FCWWNs"] = $FCWWNs
    }
	
	If($Port) 
    {
		$ParametersBody["port"] = $Port
    }
	
	if($ParametersBody.Count -gt 0)
	{
		$body["parameters"] = $ParametersBody 
	}
    
    $Result = $null
	
	#$json = $body | ConvertTo-Json  -Compress -Depth 10
	#write-host " Body = $json"
	
	$uri = '/hosts/'+$HostName
	
    #Request
    $Result = Invoke-WSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Executed Successfully with Host : $HostName" $Info
		
		Get-Host_WSAPI -HostName $HostName
		Write-DebugLog "End: Add-RemoveHostWWN_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : Cmdlet Execution failed with Host : $HostName." -foreground red
		write-host ""
		Write-DebugLog "cmdlet Execution failed with Host : $HostName." $Info
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG Add-RemoveHostWWN_WSAPI


############################################################################################################################################
## FUNCTION Update-Host_WSAPI
############################################################################################################################################
Function Update-Host_WSAPI 
{
  <#      
  .SYNOPSIS	
	Update Host.
	
  .DESCRIPTION	    
    Update Host.
	
  .EXAMPLE	
	Update-Host_WSAPI -HostName MyHost

  .EXAMPLE	
	Update-Host_WSAPI -HostName MyHost -ChapName TestHostAS	
	
  .EXAMPLE	
	Update-Host_WSAPI -HostName MyHost -ChapOperationMode 1 
	
  .PARAMETER HostName
	Neme of the Host to Update.

  .PARAMETER ChapName
	The chap name.

  .PARAMETER ChapOperationMode
	Initiator or target.
	
  .PARAMETER ChapRemoveTargetOnly
	If true, then remove target chap only.
	
  .PARAMETER ChapSecret
	The chap secret for the host or the target
	
  .PARAMETER ChapSecretHex
	If true, then chapSecret is treated as Hex.

  .PARAMETER ChapOperation
	Add or remove.
	1) INITIATOR : Set the initiator CHAP authentication information on the host.
	2) TARGET : Set the target CHAP authentication information on the host.
	
  .PARAMETER Descriptors
	The description of the host.

  .PARAMETER FCWWN
	One or more WWN to set for the host.

  .PARAMETER ForcePathRemoval
	If true, remove WWN(s) or iSCSI(s) even if there are VLUNs that are exported to the host. 

  .PARAMETER iSCSINames
	One or more iSCSI names to set for the host.

  .PARAMETER NewName
	New name of the host.

  .PARAMETER PathOperation
	If adding, adds the WWN or iSCSI name to the existing host. 
	If removing, removes the WWN or iSCSI names from the existing host.
	1) ADD : Add host chap or path.
	2) REMOVE : Remove host chap or path.
	
  .PARAMETER Persona
	The ID of the persona to modify the host’s persona to.
	1	GENERIC
	2	GENERIC_ALUA
	3	GENERIC_LEGACY
	4	HPUX_LEGACY
	5	AIX_LEGACY
	6	EGENERA
	7	ONTAP_LEGACY
	8	VMWARE
	9	OPENVMS
	10	HPUX
	11	WindowsServer
	12	AIX_ALUA
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command  

  .Notes
    NAME    : Update-Host_WSAPI    
    LASTEDIT: 30/07/2018
    KEYWORDS: Update-Host_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $HostName,
	
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ChapName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $ChapOperationMode,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $ChapRemoveTargetOnly,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ChapSecret,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $ChapSecretHex,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ChapOperation,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Descriptors,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [String[]]
	  $FCWWN,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $ForcePathRemoval,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [String[]]
	  $iSCSINames,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NewName,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $PathOperation,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Persona,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	  
	  )

  Begin 
  {
    # Test if connection exist
    Test-WSAPIConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}		
	
	If($ChapName) 
	{
		$body["chapName"] = "$($ChapName)"
    }
	If($ChapOperationMode) 
	{
		$body["chapOperationMode"] = $ChapOperationMode
    }
	If($ChapRemoveTargetOnly) 
	{
		$body["chapRemoveTargetOnly"] = $true
    }
	If($ChapSecret) 
	{
		$body["chapSecret"] = "$($ChapSecret)"
    }
	If($ChapSecretHex) 
	{
		$body["chapSecretHex"] = $true
    }
	If($ChapOperation) 
	{
		if($ChapOperation.ToUpper() -eq "INITIATOR")
		{
			$body["chapOperation"] = 1
		}
		elseif($ChapOperation.ToUpper() -eq "TARGET")
		{
			$body["chapOperation"] = 2
		}
		else
		{
			return "ChapOperation : $ChapOperation value is incorrect please use [ INITIATOR | TARGET ] " 
		}
    }
	If($Descriptors) 
	{
		$body["descriptors"] = "$($Descriptors)"
    }
	If($FCWWN) 
	{
		$body["FCWWNs"] = $FCWWN
    }
	If($ForcePathRemoval) 
	{
		$body["forcePathRemoval"] = $true
    }
	If($iSCSINames) 
	{
		$body["iSCSINames"] = $iSCSINames
    }
	If($NewName) 
	{
		$body["newName"] = "$($NewName)"
    }
	If($PathOperation) 
	{
		if($PathOperation.ToUpper() -eq "ADD")
		{
			$body["pathOperation"] = 1
		}
		elseif($PathOperation.ToUpper() -eq "REMOVE")
		{
			$body["pathOperation"] = 2
		}
		else
		{
			return "PathOperation : $PathOperation value is incorrect please use [ ADD | REMOVE ] " 
		}
    }
	If($Persona) 
	{
		if($Persona.ToUpper() -eq "GENERIC")
		{
			$body["persona"] = 1
		}
		elseif($Persona.ToUpper() -eq "GENERIC_ALUA")
		{
			$body["persona"] = 2
		}
		elseif($Persona.ToUpper() -eq "GENERIC_LEGACY")
		{
			$body["persona"] = 3
		}
		elseif($Persona.ToUpper() -eq "HPUX_LEGACY")
		{
			$body["persona"] = 4
		}
		elseif($Persona.ToUpper() -eq "AIX_LEGACY")
		{
			$body["persona"] = 5
		}
		elseif($Persona.ToUpper() -eq "EGENERA")
		{
			$body["persona"] = 6
		}
		elseif($Persona.ToUpper() -eq "ONTAP_LEGACY")
		{
			$body["persona"] = 7
		}
		elseif($Persona.ToUpper() -eq "VMWARE")
		{
			$body["persona"] = 8
		}
		elseif($Persona.ToUpper() -eq "OPENVMS")
		{
			$body["persona"] = 9
		}
		elseif($Persona.ToUpper() -eq "HPUX")
		{
			$body["persona"] = 10
		}
		else
		{
			return "Persona : $Persona value is incorrect please use [ GENERIC | GENERIC_ALUA | GENERIC_LEGACY | HPUX_LEGACY | AIX_LEGACY | EGENERA | ONTAP_LEGACY | VMWARE | OPENVMS | HPUX] " 
		}
    }	
	
    $Result = $null
		
    #Request
	Write-DebugLog "Request: Request to Update-Host_WSAPI(Invoke-WSAPI)." $Debug	
	
	#Request
	$uri = '/hosts/'+$HostName
	
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Update Host : $HostName." $Info
				
		# Results
		#return $Result
		if($NewName)
		{
			Get-Host_WSAPI -HostName $NewName
		}
		else
		{
			Get-Host_WSAPI -HostName $HostName
		}
		Write-DebugLog "End: Update-Host_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Updating Host : $HostName." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : Updating Host : $HostName." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Update-Host_WSAPI

############################################################################################################################################
## FUNCTION Remove-Host_WSAPI
############################################################################################################################################
Function Remove-Host_WSAPI
 {
  <#
  .SYNOPSIS
	Remove a Host.
  
  .DESCRIPTION
	Remove a Host.
	Any user with Super or Edit role, or any role granted host_remove permission, can perform this operation. Requires access to all domains.
        
  .EXAMPLE    
	Remove-Host_WSAPI -HostName MyHost
	
  .PARAMETER HostName 
	Specify the name of Host to be removed.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-Host_WSAPI     
    LASTEDIT: 24/01/2018
    KEYWORDS: Remove-Host_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0	
  #>
  [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]
  Param(
	[Parameter(Mandatory = $true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Specifies the name of Host.')]
	[String]$HostName,
	
	[Parameter(Mandatory=$false, ValueFromPipeline=$true , HelpMessage = 'Connection Paramater')]
	$WsapiConnection = $global:WsapiConnection
	)
  Begin 
  {
    # Test if connection exist
    Test-WSAPIConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {    
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-Host_WSAPI." $Debug
	$uri = '/hosts/'+$HostName
	
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-Host_WSAPI : $HostName (Invoke-WSAPI)." $Debug
	$Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Host:$HostName successfully remove" $Info
		Write-DebugLog "End: Remove-Host_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing Host:$HostName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating Host:$HostName " $Info
		Write-DebugLog "End: Remove-Host_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-Host_WSAPI

############################################################################################################################################
## FUNCTION Get-Host_WSAPI
############################################################################################################################################
Function Get-Host_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of Hotes.
  
  .DESCRIPTION
	Get Single or list of Hotes.
        
  .EXAMPLE
	Get-Host_WSAPI
	Display a list of host.
	
  .EXAMPLE
	Get-Host_WSAPI -HostName MyHost
	Get the information of given host.
	
  .PARAMETER HostName
	Specify name of the Host.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-Host_WSAPI    
    LASTEDIT: 24/01/2018
    KEYWORDS: Get-Host_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $HostName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-WSAPIConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-Host_WSAPI HostName : $HostName (Invoke-WSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null		
	
	# Results
	if($HostName)
	{
		#Build uri
		$uri = '/hosts/'+$HostName
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}	
	}	
	else
	{
		#Request
		$Result = Invoke-WSAPI -uri '/hosts' -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{			
			$dataPS = ($Result.content | ConvertFrom-Json).members			
		}		
	}

	If($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Get-Host_WSAPI successfully Executed." $Info
		
		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-Host_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-Host_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-Host_WSAPI

############################################################################################################################################
## FUNCTION Get-HostWithFilter_WSAPI
############################################################################################################################################
Function Get-HostWithFilter_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of Hotes information with WWN filtering.
  
  .DESCRIPTION
	Get Single or list of Hotes information with WWN filtering. specify the FCPaths WWN or the iSCSIPaths name.
	
  .EXAMPLE
	Get-HostWithFilter_WSAPI -WWN 123 
	Get a host detail with single wwn name
	
  .EXAMPLE
	Get-HostWithFilter_WSAPI -WWN "123,ABC,000" 
	Get a host detail with multiple wwn name
	
  .EXAMPLE
	Get-HostWithFilter_WSAPI -ISCSI 123 
	Get a host detail with single ISCSI name
	
  .EXAMPLE
	Get-HostWithFilter_WSAPI -ISCSI "123,ABC,000" 
	Get a host detail with multiple ISCSI name
	
  .EXAMPLE	
	Get-HostWithFilter_WSAPI -WWN "xxx,xxx,xxx" -ISCSI "xxx,xxx,xxx" 
	
  .PARAMETER WWN
	Specify WWN of the Host.
	
  .PARAMETER ISCSI
	Specify ISCSI of the Host.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-HostWithFilter_WSAPI    
    LASTEDIT: 23/01/2018
    KEYWORDS: Get-HostWithFilter_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(	  
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $WWN,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $ISCSI,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-WSAPIConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-HostWithFilter_WSAPI HostName : $HostName (Invoke-WSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null	
	$Query="?query=""  """	
		
	if($WWN)
	{
		$Query = $Query.Insert($Query.Length-3," FCPaths[ ]")
		$count = 1
		$lista = $WWN.split(",")
		foreach($sub in $lista)
		{			
			$Query = $Query.Insert($Query.Length-4," wwn EQ $sub")			
			if($lista.Count -gt 1)
			{
				if($lista.Count -ne $count)
				{
					$Query = $Query.Insert($Query.Length-4," OR ")
					$count = $count + 1
				}				
			}
		}		
	}	
	if($ISCSI)
	{
		$Link
		if($WWN)
		{
			$Query = $Query.Insert($Query.Length-2," OR iSCSIPaths[ ]")
			$Link = 3
		}
		else
		{
			$Query = $Query.Insert($Query.Length-3," iSCSIPaths[ ]")
			$Link = 5
		}		
		$count = 1
		$lista = $ISCSI.split(",")
		foreach($sub in $lista)
		{			
			$Query = $Query.Insert($Query.Length-$Link," name EQ $sub")			
			if($lista.Count -gt 1)
			{
				if($lista.Count -ne $count)
				{
					$Query = $Query.Insert($Query.Length-$Link," OR ")
					$count = $count + 1
				}				
			}
		}		
	}
	
	#write-host "Query = $Query"
	#Build uri
	if($ISCSI -Or $WWN)
	{
		$uri = '/hosts/'+$Query
	}
	else
	{
		return "Please select at list any one from [ISCSI | WWN]"
	}
	
	#Request
	$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	If($Result.StatusCode -eq 200)
	{			
		$dataPS = ($Result.content | ConvertFrom-Json).members			
	}
	
	If($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-HostWithFilter_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-HostWithFilter_WSAPI. Expected Result Not Found with Given Filter Option : ISCSI/$ISCSI WWN/$WWN." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-HostWithFilter_WSAPI. Expected Result Not Found with Given Filter Option : ISCSI/$ISCSI WWN/$WWN." $Info
			
			return 
		}		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-HostWithFilter_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-HostWithFilter_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-HostWithFilter_WSAPI

############################################################################################################################################
## FUNCTION Get-HostPersona_WSAPI
############################################################################################################################################
Function Get-HostPersona_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of host persona,.
  
  .DESCRIPTION  
	Get Single or list of host persona,.
        
  .EXAMPLE
	Get-HostPersona_WSAPI
	Display a list of host persona.
	
  .EXAMPLE
	Get-HostPersona_WSAPI -Id 10
	Display a host persona of given id.
	
  .EXAMPLE
	Get-HostPersona_WSAPI -WsapiAssignedId 100
	Display a host persona of given Wsapi Assigned Id.
	
  .EXAMPLE
	Get-HostPersona_WSAPI -Id 10
	Get the information of given host persona.
	
  .EXAMPLE	
	Get-HostPersona_WSAPI -WsapiAssignedId "1,2,3"
	Multiple Host.
	
  .PARAMETER Id
	Specify host persona id you want to query.
	
  .PARAMETER WsapiAssignedId
	To filter by wsapi Assigned Id.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-HostPersona_WSAPI    
    LASTEDIT: 23/01/2018
    KEYWORDS: Get-HostPersona_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $Id,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $WsapiAssignedId,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-WSAPIConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-HostPersona_WSAPI Id : $Id (Invoke-WSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null		
	$Query="?query=""  """
	
	# Results
	if($Id)
	{
		#Build uri
		$uri = '/hostpersonas/'+$Id
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
			
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-HostPersona_WSAPI successfully Executed." $Info
			
			return $dataPS
		}		
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-HostPersona_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-HostPersona_WSAPI. " $Info
			
			return $Result.StatusDescription
		}
	}
	elseif($WsapiAssignedId)
	{		
		$count = 1
		$lista = $WsapiAssignedId.split(",")
		foreach($sub in $lista)
		{			
			$Query = $Query.Insert($Query.Length-3," wsapiAssignedId EQ $sub")			
			if($lista.Count -gt 1)
			{
				if($lista.Count -ne $count)
				{
					$Query = $Query.Insert($Query.Length-3," OR ")
					$count = $count + 1
				}				
			}
		}
		
		#Build uri
		$uri = '/hostpersonas/'+$Query		
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{			
			$dataPS = ($Result.content | ConvertFrom-Json).members	

			if($dataPS.Count -gt 0)
			{
				write-host ""
				write-host "Cmdlet executed successfully" -foreground green
				write-host ""
				Write-DebugLog "SUCCESS: Get-HostPersona_WSAPI successfully Executed." $Info
				
				return $dataPS
			}
			else
			{
				write-host ""
				write-host "FAILURE : While Executing Get-HostPersona_WSAPI. Expected Result Not Found with Given Filter Option : WsapiAssignedId/$WsapiAssignedId." -foreground red
				write-host ""
				Write-DebugLog "FAILURE : While Executing Get-HostPersona_WSAPI. Expected Result Not Found with Given Filter Option : WsapiAssignedId/$WsapiAssignedId." $Info
				
				return 
			}
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-HostPersona_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-HostPersona_WSAPI. " $Info
			
			return $Result.StatusDescription
		}
	}
	else
	{
		#Request
		$Result = Invoke-WSAPI -uri '/hostpersonas' -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{			
			$dataPS = ($Result.content | ConvertFrom-Json).members	
				
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-HostPersona_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-HostPersona_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-HostPersona_WSAPI. " $Info
			
			return $Result.StatusDescription
		}
	}
	
  }
	End {}
}#END Get-HostPersona_WSAPI


Export-ModuleMember New-Host_WSAPI , Add-RemoveHostWWN_WSAPI , Update-Host_WSAPI , Remove-Host_WSAPI , Get-Host_WSAPI , Get-HostWithFilter_WSAPI , Get-HostPersona_WSAPI