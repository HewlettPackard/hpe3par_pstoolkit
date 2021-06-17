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
##	File Name:		PortsAndSwitches.psm1
##	Description: 	Ports and switches cmdlets 
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
## FUNCTION Get-Port_WSAPI
############################################################################################################################################
Function Get-Port_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get a single or List ports in the storage system.
  
  .DESCRIPTION
	Get a single or List ports in the storage system.
        
  .EXAMPLE
	Get-Port_WSAPI
	Get list all ports in the storage system.
	
  .EXAMPLE
	Get-Port_WSAPI -NSP 1:1:1
	Single port or given port in the storage system.
	
  .EXAMPLE
	Get-Port_WSAPI -Type HOST
	Single port or given port in the storage system.
	
  .EXAMPLE	
	Get-Port_WSAPI -Type "HOST,DISK"
	
  .PARAMETER NSP
	Get a single or List ports in the storage system depanding upon the given type.

  .PARAMETER Type	
	Port connection type.
	HOST FC port connected to hosts or fabric.	
	DISK FC port connected to disks.	
	FREE Port is not connected to hosts or disks.	
	IPORT Port is in iport mode.
	RCFC FC port used for Remote Copy.	
	PEER FC port used for data migration.	
	RCIP IP (Ethernet) port used for Remote Copy.	
	ISCSI iSCSI (Ethernet) port connected to hosts.	
	CNA CNA port, which can be FCoE or iSCSI.	
	FS Ethernet File Persona ports.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-Port_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-Port_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Type,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
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
	$Query="?query=""  """
	
	#Build uri
	if($NSP)
	{
		if($Type)
		{
			return "FAILURE : While Executing Get-Port_WSAPI. Select only one from NSP : $NSP or Type : $Type"
		}
		$uri = '/ports/'+$NSP
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-Port_WSAPI successfully Executed." $Info

			return $dataPS		
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-Port_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-Port_WSAPI. " $Info

			return $Result.StatusDescription
		}
	}
	elseif($Type)
	{
		$dict = @{}
		$dict.Add('HOST','1')
		$dict.Add('DISK','2')
		$dict.Add('FREE','3')
		$dict.Add('IPORT','4')
		$dict.Add('RCFC','5')
		$dict.Add('PEER','6')
		$dict.Add('RCIP','7')
		$dict.Add('ISCSI','8')
		$dict.Add('CNA','9')
		$dict.Add('FS','10')
		
		$count = 1
		$subEnum = 0
		$lista = $Type.split(",")
		foreach($sub in $lista)
		{	
			$subEnum = $dict.Get_Item("$sub")
			if($subEnum)
			{
				$Query = $Query.Insert($Query.Length-3," type EQ $subEnum")			
				if($lista.Count -gt 1)
				{
					if($lista.Count -ne $count)
					{
						$Query = $Query.Insert($Query.Length-3," OR ")
						$count = $count + 1
					}				
				}
			}
		}

		#Build uri
		$uri = '/ports/'+$Query
		
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{			
			$dataPS = ($Result.content | ConvertFrom-Json).members			
		}
		
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-Port_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-Port_WSAPI. " -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-Port_WSAPI." $Info
			
			return 
		}
	}
	else
	{
		#Request
		$Result = Invoke-WSAPI -uri '/ports' -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}	
			
		if($Result.StatusCode -eq 200)
		{		
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-Port_WSAPI successfully Executed." $Info

			return $dataPS		
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-Port_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-Port_WSAPI. " $Info

			return $Result.StatusDescription
		} 
	}
  }	
}
#END Get-Port_WSAPI

############################################################################################################################################
## FUNCTION Get-IscsivLans_WSAPI
############################################################################################################################################
Function Get-IscsivLans_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Querying iSCSI VLANs for an iSCSI port
  
  .DESCRIPTION
	Querying iSCSI VLANs for an iSCSI port
        
  .EXAMPLE
	Get-IscsivLans_WSAPI
	Get the status of all tasks
	
  .EXAMPLE
	Get-IscsivLans_WSAPI -Type FS
	
  .EXAMPLE
	Get-IscsivLans_WSAPI -NSP 1:0:1
	
  .EXAMPLE	
	Get-IscsivLans_WSAPI -VLANtag xyz -NSP 1:0:1
	
  .PARAMETER Type
	Port connection type.
  
  .PARAMETER NSP
	The <n:s:p> variable identifies the node, slot, and port of the device.
  
  .PARAMETER VLANtag
	VLAN ID.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Get-IscsivLans_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-IscsivLans_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Type,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VLANtag,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
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
	$Query="?query=""  """
	#Build uri
	if($Type)
	{
		$count = 1
		$lista = $Type.split(",")
		foreach($sub in $lista)
		{			
			$Query = $Query.Insert($Query.Length-3," type EQ $sub")			
			if($lista.Count -gt 1)
			{
				if($lista.Count -ne $count)
				{
					$Query = $Query.Insert($Query.Length-3," OR ")
					$count = $count + 1
				}				
			}
		}	
		
		$uri = '/ports/'+$Query
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}
	else
	{
		if($VLANtag)
		{
			#Request
			if(-not $NSP)
			{
				Return "N S P required with VLANtag."
			}
			$uri = '/ports/'+$NSP+'/iSCSIVlans/'+$VLANtag
			
			$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
			if($Result.StatusCode -eq 200)
			{
				$dataPS = $Result.content | ConvertFrom-Json
			}
		}
		else
		{
			if(-not $NSP)
			{
				Return "N S P required with VLANtag."
			}
			$uri = '/ports/'+$NSP+'/iSCSIVlans/'
			#Request
			$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
			if($Result.StatusCode -eq 200)
			{
				$dataPS = ($Result.content | ConvertFrom-Json).members
			}
		}		
	}
		  
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-IscsivLans_WSAPI Successfully Executed" $Info
		
		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-IscsivLans_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-IscsivLans_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-IscsivLans_WSAPI

############################################################################################################################################
## FUNCTION Get-PortDevices_WSAPI
############################################################################################################################################
Function Get-PortDevices_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get single or list of port devices in the storage system.
  
  .DESCRIPTION
	Get single or list of port devices in the storage system.
        
  .EXAMPLE
	Get-PortDevices_WSAPI -NSP 1:1:1
	Get a list of port devices in the storage system.
	
  .EXAMPLE
	Get-PortDevices_WSAPI -NSP "1:1:1,0:0:0"
	Multiple Port option Get a list of port devices in the storage system.
	
  .PARAMETER NSP
	The <n:s:p> variable identifies the node, slot, and port of the device.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-PortDevices_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-PortDevices_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Mandatory = $true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
      [String]
	  $NSP,
	  
	  [Parameter(Mandatory=$false, ValueFromPipeline=$true , HelpMessage = 'Connection Paramater')]
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
	$Query="?query=""  """
		
	#Build uri
	if($NSP)
	{
		$lista = $NSP.split(",")
		
		if($lista.Count -gt 1)
		{
			$count = 1
			foreach($sub in $lista)
			{	
				$Query = $Query.Insert($Query.Length-3," portPos EQ $sub")			
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
			$uri = '/portdevices'+$Query
			
			#Request
			$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
			If($Result.StatusCode -eq 200)
			{			
				$dataPS = ($Result.content | ConvertFrom-Json).members			
			}
			
			if($dataPS.Count -gt 0)
			{
				write-host ""
				write-host "Cmdlet executed successfully" -foreground green
				write-host ""
				Write-DebugLog "SUCCESS: Get-PortDevices_WSAPI successfully Executed." $Info
				
				return $dataPS
			}
			else
			{
				write-host ""
				write-host "FAILURE : While Executing Get-PortDevices_WSAPI." -foreground red
				write-host ""
				Write-DebugLog "FAILURE : While Executing Get-PortDevices_WSAPI." $Info
				
				return 
			}
		}
		else
		{		
			#Build uri
			$uri = '/portdevices/all/'+$NSP
			
			#Request
			$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
			If($Result.StatusCode -eq 200)
			{			
				$dataPS = ($Result.content | ConvertFrom-Json).members			
			}	

			if($dataPS.Count -gt 0)
			{
				write-host ""
				write-host "Cmdlet executed successfully" -foreground green
				write-host ""
				Write-DebugLog "SUCCESS: Get-PortDevices_WSAPI successfully Executed." $Info
				
				return $dataPS
			}
			else
			{
				write-host ""
				write-host "FAILURE : While Executing Get-PortDevices_WSAPI. " -foreground red
				write-host ""
				Write-DebugLog "FAILURE : While Executing Get-PortDevices_WSAPI." $Info
				
				return 
			}
		}
	}	
  }	
}
#END Get-PortDevices_WSAPI

############################################################################################################################################
## FUNCTION Get-PortDeviceTDZ_WSAPI
############################################################################################################################################
Function Get-PortDeviceTDZ_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of port device target-driven zones.
  
  .DESCRIPTION
	Get Single or list of port device target-driven zones.
        
  .EXAMPLE
	Get-PortDeviceTDZ_WSAPI
	Display a list of port device target-driven zones.
	
  .EXAMPLE
	Get-PortDeviceTDZ_WSAPI -NSP 0:0:0
	Get the information of given port device target-driven zones.
	
  .PARAMETER NSP
	The <n:s:p> variable identifies the node, slot, and port of the device.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-PortDeviceTDZ_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Get-PortDeviceTDZ_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
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
	Write-DebugLog "Request: Request to Get-PortDeviceTDZ_WSAPI NSP : $NSP (Invoke-WSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null		
	
	# Results
	if($NSP)
	{
		#Build uri
		$uri = '/portdevices/targetdrivenzones/'+$NSP
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
		$Result = Invoke-WSAPI -uri '/portdevices/targetdrivenzones/' -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{			
			$dataPS = ($Result.content | ConvertFrom-Json).members			
		}		
	}

	If($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
			{
				write-host ""
				write-host "Cmdlet executed successfully" -foreground green
				write-host ""
				Write-DebugLog "SUCCESS: Get-PortDeviceTDZ_WSAPI successfully Executed." $Info
				
				return $dataPS
			}
			else
			{
				write-host ""
				write-host "FAILURE : While Executing Get-PortDeviceTDZ_WSAPI. " -foreground red
				write-host ""
				Write-DebugLog "FAILURE : While Executing Get-PortDeviceTDZ_WSAPI." $Info
				
				return 
			}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-PortDeviceTDZ_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-PortDeviceTDZ_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-PortDeviceTDZ_WSAPI

############################################################################################################################################
## FUNCTION Get-FcSwitches_WSAPI
############################################################################################################################################
Function Get-FcSwitches_WSAPI 
{
  <#
  .SYNOPSIS
	Get a list of all FC switches connected to a specified port.
  
  .DESCRIPTION
	Get a list of all FC switches connected to a specified port.
	
  .EXAMPLE
	Get-FcSwitches_WSAPI -NSP 0:0:0
	Get a list of all FC switches connected to a specified port.
	
  .PARAMETER NSP
	The <n:s:p> variable identifies the node, slot, and port of the device.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-FcSwitches_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Get-FcSwitches_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
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
	Write-DebugLog "Request: Request to Get-FcSwitches_WSAPI NSP : $NSP (Invoke-WSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null		
	
	# Results
	if($NSP)
	{
		#Build uri
		$uri = '/portdevices/fcswitch/'+$NSP
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{
			#FC switches			
		}	
	}

	If($Result.StatusCode -eq 200)
	{		
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-FcSwitches_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{			
			write-host ""
			write-host "FAILURE : While Executing Get-FcSwitches_WSAPI. " -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-FcSwitches_WSAPI." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-FcSwitches_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-FcSwitches_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-FcSwitches_WSAPI

############################################################################################################################################
## FUNCTION Set-ISCSIPort_WSAPI
############################################################################################################################################
Function Set-ISCSIPort_WSAPI 
{
  <#
  .SYNOPSIS
	Configure iSCSI ports
  
  .DESCRIPTION
	Configure iSCSI ports
        
  .EXAMPLE    
	Set-ISCSIPort_WSAPI -NSP 1:2:3 -IPAdr 1.1.1.1 -Netmask xxx -Gateway xxx -MTU xx -ISNSPort xxx -ISNSAddr xxx
	Configure iSCSI ports for given NSP
	
  .PARAMETER NSP 
	The <n:s:p> parameter identifies the port you want to configure.
	
  .PARAMETER IPAdr
	Port IP address
  
  .PARAMETER Netmask
	Netmask for Ethernet
	
  .PARAMETER Gateway
	Gateway IP address
	
  .PARAMETER MTU
	MTU size in bytes
	
  .PARAMETER ISNSPort
	TCP port number for the iSNS server
	
  .PARAMETER ISNSAddr
	iSNS server IP address

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Set-ISCSIPort_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Set-ISCSIPort_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $IPAdr,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Netmask,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Gateway,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $MTU,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $ISNSPort,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ISNSAddr,
	  
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
  
	$body = @{}
	$iSCSIPortInfobody = @{}
		
	If ($IPAdr) 
	{ 
		$iSCSIPortInfobody["ipAddr"] ="$($IPAdr)" 
	}  
	If ($Netmask) 
	{ 
		$iSCSIPortInfobody["netmask"] ="$($Netmask)" 
	}
	If ($Gateway) 
	{ 
		$iSCSIPortInfobody["gateway"] ="$($Gateway)" 
	}
	If ($MTU) 
	{ 
		$iSCSIPortInfobody["mtu"] = $MTU
	}
	If ($ISNSPort) 
	{ 
		$iSCSIPortInfobody["iSNSPort"] =$ISNSPort
	}
	If ($ISNSAddr) 
	{ 
		$iSCSIPortInfobody["iSNSAddr"] ="$($ISNSAddr)" 
	}
	
	if($iSCSIPortInfobody.Count -gt 0)
	{
		$body["iSCSIPortInfo"] = $iSCSIPortInfobody 
	}
    
    $Result = $null	
	$uri = '/ports/'+$NSP 
	
    #Request
	Write-DebugLog "Request: Request to Set-ISCSIPort_WSAPI : $NSP (Invoke-WSAPI)." $Debug
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: iSCSI ports : $NSP successfully configure." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Set-ISCSIPort_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Configuring iSCSI ports: $NSP " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Configuring iSCSI ports: $NSP " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Set-ISCSIPort_WSAPI

############################################################################################################################################
## FUNCTION New-IscsivLan_WSAPI
############################################################################################################################################
Function New-IscsivLan_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creates a VLAN on an iSCSI port.
	
  .DESCRIPTION
	Creates a VLAN on an iSCSI port.
	
  .EXAMPLE
	New-IscsivLan_WSAPI -NSP 1:1:1 -IPAddress x.x.x.x -Netmask xx -VlanTag xx
	a VLAN on an iSCSI port
	
  .PARAMETER NSP
	The <n:s:p> parameter identifies the port you want to configure.
  
  .PARAMETER IPAddress
	iSCSI port IPaddress
	
  .PARAMETER Netmask
	Netmask for Ethernet
	
  .PARAMETER VlanTag
	VLAN tag

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : New-IscsivLan_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-IscsivLan_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>
  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
      [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $IPAddress,	  
	  
	  [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $Netmask,	
	  
	  [Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true)]
      [int]
	  $VlanTag,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
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
    $body["ipAddr"] = "$($IPAddress)"
	$body["netmask"] = "$($Netmask)"
	$body["vlanTag"] = $VlanTag   
    
    $Result = $null
	
    #Request
	$uri = "/ports/"+$NSP+"/iSCSIVlans/"
	
    $Result = Invoke-WSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: VLAN on an iSCSI port :$NSP created successfully" $Info		
		Write-DebugLog "End: New-IscsivLan_WSAPI" $Debug
		
		return $Result
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating VLAN on an iSCSI port : $NSP" -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While VLAN on an iSCSI port : $NSP" $Info
		Write-DebugLog "End: New-IscsivLan_WSAPI" $Debug
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG New-IscsivLan_WSAPI

############################################################################################################################################
## FUNCTION New-IscsivLun_WSAPI
############################################################################################################################################
Function New-IscsivLun_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creates a VLAN on an iSCSI port.
	
  .DESCRIPTION    
  	Creates a VLAN on an iSCSI port.
	
  .EXAMPLE
	New-IscsivLun_WSAPI -NSP 1:1:1 -IPAddress x.x.x.x -Netmask xx -VlanTag xx
	a VLAN on an iSCSI port
	
  .PARAMETER NSP
	The <n:s:p> parameter identifies the port you want to configure.
  
  .PARAMETER IPAddress
	iSCSI port IPaddress
	
  .PARAMETER Netmask
	Netmask for Ethernet
	
  .PARAMETER VlanTag
	VLAN tag

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : New-IscsivLun_WSAPI    
    LASTEDIT: 328/05/2020
    KEYWORDS: New-IscsivLun_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>
  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
      [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $IPAddress,	  
	  
	  [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $Netmask,	
	  
	  [Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true)]
      [int]
	  $VlanTag,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
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
    $body["ipAddr"] = "$($IPAddress)"
	$body["netmask"] = "$($Netmask)"
	$body["vlanTag"] = $VlanTag   
    
    $Result = $null
	
    #Request
	$uri = "/ports/"+$NSP+"/iSCSIVlans/"
	
    $Result = Invoke-WSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: VLAN on an iSCSI port :$NSP created successfully" $Info		
		Write-DebugLog "End: New-IscsivLun_WSAPI" $Debug
		
		return $Result
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating VLAN on an iSCSI port : $NSP" -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While VLAN on an iSCSI port : $NSP" $Info
		Write-DebugLog "End: New-IscsivLun_WSAPI" $Debug
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG New-IscsivLun_WSAPI

############################################################################################################################################
## FUNCTION Set-IscsivLan_WSAPI
############################################################################################################################################
Function Set-IscsivLan_WSAPI 
{
  <#
  .SYNOPSIS
	Configure VLAN on an iSCSI port
  
  .DESCRIPTION
	Configure VLAN on an iSCSI port
        
  .EXAMPLE    
	Set-IscsivLan_WSAPI -NSP 1:2:3 -IPAdr 1.1.1.1 -Netmask xxx -Gateway xxx -MTU xx -STGT xx -ISNSPort xxx -ISNSAddr xxx
	Configure VLAN on an iSCSI port
	
  .PARAMETER NSP 
	The <n:s:p> parameter identifies the port you want to configure.

  .PARAMETER VlanTag 
	VLAN tag.
	
  .PARAMETER IPAdr
	Port IP address
  
  .PARAMETER Netmask
	Netmask for Ethernet
	
  .PARAMETER Gateway
	Gateway IP address
	
  .PARAMETER MTU
	MTU size in bytes
	
  .PARAMETER STGT
	Send targets group tag of the iSCSI target.
	
  .PARAMETER ISNSPort
	TCP port number for the iSNS server
	
  .PARAMETER ISNSAddr
	iSNS server IP address

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Set-IscsivLan_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Set-IscsivLan_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
	  [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [int]
	  $VlanTag,	  
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $IPAdr,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Netmask,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Gateway,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $MTU,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $STGT,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $ISNSPort,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ISNSAddr,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-WSAPIConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
  
	$body = @{}	
		
	If ($IPAdr) 
	{ 
		$body["ipAddr"] ="$($IPAdr)" 
	}  
	If ($Netmask) 
	{ 
		$body["netmask"] ="$($Netmask)" 
	}
	If ($Gateway) 
	{ 
		$body["gateway"] ="$($Gateway)" 
	}
	If ($MTU) 
	{ 
		$body["mtu"] = $MTU
	}
	If ($MTU) 
	{ 
		$body["stgt"] = $STGT
	}
	If ($ISNSPort) 
	{ 
		$body["iSNSPort"] =$ISNSPort
	}
	If ($ISNSAddr) 
	{ 
		$body["iSNSAddr"] ="$($ISNSAddr)" 
	}
    
    $Result = $null	
	$uri = "/ports/" + $NSP + "/iSCSIVlans/" + $VlanTag 
	
    #Request
	Write-DebugLog "Request: Request to Set-IscsivLan_WSAPI : $NSP (Invoke-WSAPI)." $Debug
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully configure VLAN on an iSCSI port : $NSP ." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Set-IscsivLan_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Configuring VLAN on an iSCSI port : $NSP " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Configuring VLAN on an iSCSI port : $NSP " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Set-IscsivLan_WSAPI

############################################################################################################################################
## FUNCTION Reset-IscsiPort_WSAPI
############################################################################################################################################
Function Reset-IscsiPort_WSAPI 
{
  <#
  
  .SYNOPSIS
	Resetting an iSCSI port configuration
	
  .DESCRIPTION
	Resetting an iSCSI port configuration
	
  .EXAMPLE
	Reset-IscsiPort_WSAPI -NSP 1:1:1 
	
  .PARAMETER NSP
	The <n:s:p> parameter identifies the port you want to configure.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Reset-IscsiPort_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Reset-IscsiPort_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>
  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
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
    # Creation of the body hash
	Write-DebugLog "Running: Creation of the body hash" $Debug
    $body = @{}    
    $body["action"] = 2
    
    $Result = $null
	
    #Request
	$uri = '/ports/'+$NSP 
	
    $Result = Invoke-WSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Reset an iSCSI port configuration $NSP" $Info		
		Write-DebugLog "End: Reset-IscsiPort_WSAPI" $Debug
		
		return $Result
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Resetting an iSCSI port configuration : $NSP" -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Resetting an iSCSI port configuration : $NSP" $Info
		Write-DebugLog "End: Reset-IscsiPort_WSAPI" $Debug
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG Reset-IscsiPort_WSAPI

############################################################################################################################################
## FUNCTION Remove-IscsivLan_WSAPI
############################################################################################################################################
Function Remove-IscsivLan_WSAPI
 {
  <#
  .SYNOPSIS
	Removing an iSCSI port VLAN.
  
  .DESCRIPTION
	Remove a File Provisioning Group.
        
  .EXAMPLE    
	Remove-IscsivLan_WSAPI -NSP 1:1:1 -VlanTag 1 
	Removing an iSCSI port VLAN
	
  .PARAMETER NSP 
	The <n:s:p> parameter identifies the port you want to configure.

  .PARAMETER VlanTag 
	VLAN tag.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-IscsivLan_WSAPI     
    LASTEDIT: February 2020
    KEYWORDS: Remove-IscsivLan_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0	
  #>
  [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
	  [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [int]
	  $VlanTag,
	  
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
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-IscsivLan_WSAPI." $Debug
	
	$uri = "/ports/"+$NSP+"/iSCSIVlans/"+$VlanTag 
	
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-IscsivLan_WSAPI : $NSP (Invoke-WSAPI)." $Debug
	$Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 202)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully remove an iSCSI port VLAN : $NSP" $Info
		Write-DebugLog "End: Remove-IscsivLan_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing an iSCSI port VLAN : $NSP " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Removing an iSCSI port VLAN : $NSP " $Info
		Write-DebugLog "End: Remove-IscsivLan_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-IscsivLan_WSAPI


Export-ModuleMember Get-Port_WSAPI , Get-IscsivLans_WSAPI , Get-PortDevices_WSAPI , Get-PortDeviceTDZ_WSAPI , 
Get-FcSwitches_WSAPI , Get-IscsivLans_WSAPI , Set-ISCSIPort_WSAPI, Set-IscsivLan_WSAPI , New-IscsivLun_WSAPI , Reset-IscsiPort_WSAPI , Remove-IscsivLan_WSAPI