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
##	File Name:		VirtualLUNs.psm1
##	Description: 	Virtual LUNs cmdlets 
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
## FUNCTION New-vLun_WSAPI
############################################################################################################################################
Function New-vLun_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creating a VLUN
	
  .DESCRIPTION
	Creating a VLUN
	Any user with Super or Edit role, or any role granted vlun_create permission, can perform this operation.
	
  .EXAMPLE
	New-vLun_WSAPI -VolumeName xxx -LUNID x -HostName xxx

  .EXAMPLE
	New-vLun_WSAPI -VolumeName xxx -LUNID x -HostName xxx -NSP 1:1:1
	
  .PARAMETER VolumeName
	Name of the volume or VV set to export.

  .PARAMETER LUNID
	LUN ID.
	
  .PARAMETER HostName  
	Name of the host or host set to which the volume or VV set is to be exported.
	The host set should be in set:hostset_name format.
	
  .PARAMETER NSP
	System port of VLUN exported to. It includes node number, slot number, and card port number.

  .PARAMETER NoVcn
	Specifies that a VCN not be issued after export (-novcn). Default: false.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : New-vLun_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-vLun_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>
  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeName,
	  
	  [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [int]
	  $LUNID,
	  
	  [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $HostName,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Boolean]
	  $NoVcn = $false,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
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
    
	If ($VolumeName) 
	{ 
		$body["volumeName"] ="$($VolumeName)" 
	}  
	If ($LUNID) 
	{ 
		$body["lun"] =$LUNID
	}
	If ($HostName) 
	{ 
		$body["hostname"] ="$($HostName)" 
	}
	If ($NSP) 
	{
		$NSPbody = @{} 
		
		$list = $NSP.split(":")
		
		$NSPbody["node"] = [int]$list[0]		
		$NSPbody["slot"] = [int]$list[1]
		$NSPbody["cardPort"] = [int]$list[2]		
		
		$body["portPos"] = $NSPbody		
	}
	If ($NoVcn) 
	{ 
		$body["noVcn"] = $NoVcn
	}
	
    
    $Result = $null
	
    #Request	
    $Result = Invoke-WSAPI -uri '/vluns' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		#write-host "SUCCESS: Status Code : $Result.StatusCode ." -foreground green
		#write-host "SUCCESS: Status Description : $Result.StatusDescription." -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created a VLUN" $Info	
		Get-vLun_WSAPI -VolumeName $VolumeName -LUNID $LUNID -HostName $HostName
		
		Write-DebugLog "End: New-vLun_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Creating a VLUN" -foreground red
		write-host ""
		Write-DebugLog "FAILURE : Creating a VLUN" $Info
		Write-DebugLog "End: New-vLun_WSAPI" $Debug
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG New-vLun_WSAPI

############################################################################################################################################
## FUNCTION Remove-vLun_WSAPI
############################################################################################################################################
Function Remove-vLun_WSAPI
 {
  <#
	
  .SYNOPSIS
	Removing a VLUN.
  
  .DESCRIPTION
	Removing a VLUN
    Any user with the Super or Edit role, or any role granted with the vlun_remove right, can perform this operation.    
	
  .EXAMPLE    
	Remove-vLun_WSAPI -VolumeName xxx -LUNID xx -HostName xxx

  .EXAMPLE    
	Remove-vLun_WSAPI -VolumeName xxx -LUNID xx -HostName xxx -NSP x:x:x
	
  .PARAMETER VolumeName
	Name of the volume or VV set to be exported.
	The VV set should be in set:<volumeset_name> format.
  
  .PARAMETER LUNID
   Lun Id
   
  .PARAMETER HostName
	Name of the host or host set to which the volume or VV set is to be exported. For VLUN of port type, the value is empty.
	The host set should be in set:<hostset_name> format.required if volume is exported to host or host set,or to both the host or host set and port
  
  .PARAMETER NSP
	Specifies the system port of the VLUN export. It includes the system node number, PCI bus slot number, and card port number on the FC card in the format:<node>:<slot>:<port>
	required if volume is exported to port, or to both host and port .Notes NAME : Remove-vLun_WSAPI 
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Remove-vLun_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Remove-vLun_WSAPI 
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
	
  #>
  [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeName,
	  
	  [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [int]
	  $LUNID,
	  
	  [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $HostName,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,

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
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-vLun_WSAPI  ." $Debug
	$uri = "/vluns/"+$VolumeName+","+$LUNID+","+$HostName
	
	if($NSP)
	{
		$uri = $uri+","+$NSP
	}	

	#init the response var
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-vLun_WSAPI : $CPGName (Invoke-WSAPI)." $Debug
	$Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: VLUN Successfully removed with Given Values [ VolumeName : $VolumeName | LUNID : $LUNID | HostName : $HostName | NSP : $NSP ]." $Info
		Write-DebugLog "End: Remove-vLun_WSAPI" $Debug
		return $Result		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing VLUN with Given Values [ VolumeName : $VolumeName | LUNID : $LUNID | HostName : $HostName | NSP : $NSP ]. " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Removing VLUN with Given Values [ VolumeName : $VolumeName | LUNID : $LUNID | HostName : $HostName | NSP : $NSP ]." $Info
		Write-DebugLog "End: Remove-vLun_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-vLun_WSAPI

############################################################################################################################################
## FUNCTION Get-vLun_WSAPI
############################################################################################################################################
Function Get-vLun_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of VLun.
  
  .DESCRIPTION
	Get Single or list of VLun
        
  .EXAMPLE
	Get-vLun_WSAPI
	Display a list of VLun.
	
  .EXAMPLE
	Get-vLun_WSAPI -VolumeName xxx -LUNID x -HostName xxx 
	Display a list of VLun.

  .PARAMETER VolumeName
	Name of the volume to be exported.	
  
  .PARAMETER LUNID
   Lun
   
  .PARAMETER HostName
	Name of the host to which the volume is to be exported. For VLUN of port type, the value is empty.
		
  .PARAMETER NSP
	The <n:s:p> variable identifies the node, slot, and port of the device.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-vLun_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Get-vLun_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Vlun_id,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $LUNID,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $HostName,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-WSAPIConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-vLun_WSAPI [ VolumeName : $VolumeName | LUNID : $LUNID | HostName : $HostName | NSP : $NSP] (Invoke-WSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null		
	$uri = "/vluns/"+$Vlun_id+"/"
	# Results
	if($VolumeName)
	{
		#Build uri
		$uri = $uri+$VolumeName			
	}
	if($LUNID)
	{
		if($VolumeName)
		{
			#Build uri
			$uri = $uri+","+$LUNID			
		}
		else
		{
			$uri = $uri+$LUNID
		}
		
	}
	if($HostName)
	{
		if($VolumeName -Or $LUNID)
		{
			#Build uri
			$uri = $uri+","+$HostName			
		}
		else
		{
			$uri = $uri+$HostName
		}
	}
	if($NSP)
	{
		if($VolumeName -Or $LUNID -Or $HostName)
		{
			#Build uri
			$uri = $uri+","+$NSP			
		}
		else
		{
			$uri = $uri+$NSP
		}
	}
	if($Vlun_id -Or $VolumeName -Or $LUNID -Or $HostName -Or $NSP)
	{
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}
	else
	{
		#Request
		$Result = Invoke-WSAPI -uri '/vluns' -type 'GET' -WsapiConnection $WsapiConnection
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
				Write-DebugLog "SUCCESS: Get-vLun_WSAPI successfully Executed." $Info
				
				return $dataPS
			}
			else
			{
				write-host ""
				write-host "FAILURE : While Executing Get-vLun_WSAPI. Expected Result Not Found [ VolumeName : $VolumeName | LUNID : $LUNID | HostName : $HostName | NSP : $NSP]." -foreground red
				write-host ""
				Write-DebugLog "FAILURE : While Executing Get-vLun_WSAPI. Expected Result Not Found [ VolumeName : $VolumeName | LUNID : $LUNID | HostName : $HostName | NSP : $NSP]" $Info
				
				return 
			}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-vLun_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-vLun_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-vLun_WSAPI


############################################################################################################################################
## FUNCTION Get-vLunUsingFilters_WSAPI
############################################################################################################################################
Function Get-vLunUsingFilters_WSAPI 
{
  <#
  .SYNOPSIS
	Get VLUNs using filters.
  
  .DESCRIPTION
	Get VLUNs using filters.
	Available filters for VLUN queries
	Use the following filters to query VLUNs:
	• volumeWWN
	• remoteName
	• volumeName
	• hostname
	• serial
        
  .EXAMPLE
	Get-vLunUsingFilters_WSAPI -VolumeWWN "xxx"

  .EXAMPLE
	Get-vLunUsingFilters_WSAPI -VolumeWWN "xxx,yyy,zzz"
	
  .EXAMPLE
	Get-vLunUsingFilters_WSAPI -RemoteName "xxx"
	
  .EXAMPLE
	Get-vLunUsingFilters_WSAPI -RemoteName "xxx,yyy,zzz"
	
  .EXAMPLE
	Get-vLunUsingFilters_WSAPI -RemoteName "xxx" -VolumeWWN "xxx"
	Supporting single or multipule values using ","

  .EXAMPLE
	Get-vLunUsingFilters_WSAPI -RemoteName "xxx" -VolumeWWN "xxx" -VolumeName "xxx"
	Supporting single or multipule values using ","
	
  .EXAMPLE
	Get-vLunUsingFilters_WSAPI -RemoteName "xxx" -VolumeWWN "xxx" -VolumeName "xxx" -HostName "xxx"
	Supporting single or multipule values using ","
	
  .EXAMPLE
	Get-vLunUsingFilters_WSAPI -RemoteName "xxx" -VolumeWWN "xxx" -VolumeName "xxx" -HostName "xxx" -Serial "xxx"
	Supporting single or multipule values using ","
	
  .PARAMETER VolumeWWN
	The value of <VolumeWWN> is the WWN of the exported volume
	
  .PARAMETER RemoteName
	the <RemoteName> value is the host WWN or an iSCSI pathname.
	
  .PARAMETER VolumeName
	Volume Name
	
  .PARAMETER HostName
	Host Name
	
  .PARAMETER Serial
	To Get volumes using a serial number
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-vLunUsingFilters_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Get-vLunUsingFilters_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeWWN,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $RemoteName,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeName,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $HostName,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Serial,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-WSAPIConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-vLunUsingFilters_WSAPI VVSetName : $VVSetName (Invoke-WSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null		
	$Query="?query=""  """
	
	# Results	
	if($VolumeWWN)
	{		
		$Query = LoopingFunction -Value $VolumeWWN -condition "volumeWWN" -flg $false -Query $Query		
	}
	if($RemoteName)
	{
		if($VolumeWWN)
		{
			$Query = LoopingFunction -Value $RemoteName -condition "remoteName" -flg $true -Query $Query
		}
		else
		{
			$Query = LoopingFunction -Value $RemoteName -condition "remoteName" -flg $false -Query $Query
		}
	}
	if($VolumeName)
	{
		if($VolumeWWN -or $RemoteName)
		{
			$Query = LoopingFunction -Value $VolumeName -condition "volumeName" -flg $true -Query $Query
		}
		else
		{
			$Query = LoopingFunction -Value $VolumeName -condition "volumeName" -flg $false -Query $Query
		}
	}
	if($HostName)
	{
		if($VolumeWWN -or $RemoteName -or $VolumeName)
		{
			$Query = LoopingFunction -Value $HostName -condition "hostname" -flg $true -Query $Query
		}
		else
		{
			$Query = LoopingFunction -Value $HostName -condition "hostname" -flg $false -Query $Query
		}
	}
	if($Serial)
	{
		if($VolumeWWN -or $RemoteName -or $VolumeName -or $HostName)
		{
			$Query = LoopingFunction -Value $Serial -condition "serial" -flg $true -Query $Query
		}
		else
		{
			$Query = LoopingFunction -Value $Serial -condition "serial" -flg $false -Query $Query
		}
	}
	
	if($VolumeWWN -or $RemoteName -or $VolumeName -or $HostName -or $Serial)
	{
		#Build uri
		$uri = '/vluns/'+$Query
		
		#write-host "uri = $uri"
		
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection		
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
			Write-DebugLog "SUCCESS: Get-vLunUsingFilters_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-vLunUsingFilters_WSAPI. Expected Result Not Found with Given Filter Option : VolumeWWN/$VolumeWWN RemoteName/$RemoteName VolumeName/$VolumeName HostName/$HostName Serial/$Serial." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-vLunUsingFilters_WSAPI. Expected Result Not Found with Given Filter Option : VolumeWWN/$VolumeWWN RemoteName/$RemoteName VolumeName/$VolumeName HostName/$HostName Serial/$Serial." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-vLunUsingFilters_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-vLunUsingFilters_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-vLunUsingFilters_WSAPI


Export-ModuleMember New-vLun_WSAPI , Remove-vLun_WSAPI , Get-vLun_WSAPI , Get-vLunUsingFilters_WSAPI