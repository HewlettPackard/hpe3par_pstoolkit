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
##	File Name:		FilePersona.psm1
##	Description: 	File Persona cmdlets 
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
## FUNCTION Get-FileServices_WSAPI
############################################################################################################################################
Function Get-FileServices_WSAPI 
{
  <#
  .SYNOPSIS
	Get the File Services information.
  
  .DESCRIPTION
	Get the File Services information.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .EXAMPLE
    Get-FileServices_WSAPI
	display File Services Information

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-FileServices_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Get-FileServices_WSAPI
   
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
  $Result = Invoke-WSAPI -uri '/fileservices' -type 'GET' -WsapiConnection $WsapiConnection

  if($Result.StatusCode -eq 200)
  {
		# Results
		$dataPS = ($Result.content | ConvertFrom-Json)

		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Get-FileServices_WSAPI successfully Executed." $Info

		return $dataPS
  }
  else
  {
		write-host ""
		write-host "FAILURE : While Executing Get-FileServices_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-FileServices_WSAPI. " $Info
		
		return $Result.StatusDescription
  }  
}
#END Get-FileServices_WSAPI

############################################################################################################################################
## FUNCTION New-FPG_WSAPI
############################################################################################################################################
Function New-FPG_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creates a new File Provisioning Group(FPG).
	
  .DESCRIPTION
	Creates a new File Provisioning Group(FPG).
	
  .EXAMPLE
	New-FPG_WSAPI -PFGName "MyFPG" -CPGName "MyCPG"	-SizeTiB 12
	Creates a new File Provisioning Group(FPG), size must be in Terabytes
	
  .EXAMPLE	
	New-FPG_WSAPI -FPGName asFPG -CPGName cpg_test -SizeTiB 1 -FPVV $true
	
  .EXAMPLE	
	New-FPG_WSAPI -FPGName asFPG -CPGName cpg_test -SizeTiB 1 -TDVV $true
	
  .EXAMPLE	
	New-FPG_WSAPI -FPGName asFPG -CPGName cpg_test -SizeTiB 1 -NodeId 1
	
  .PARAMETER FPGName
	Name of the FPG, maximum 22 chars.
  
  .PARAMETER CPGName
	Name of the CPG on which to create the FPG.
  
  .PARAMETER SizeTiB
	Size of the FPG in terabytes.
  
  .PARAMETER FPVV
	Enables (true) or disables (false) FPG volume creation with the FPVV volume. Defaults to false, creating the FPG with the TPVV volume.
  
  .PARAMETER TDVV
	Enables (true) or disables (false) FPG volume creation with the TDVV volume. Defaults to false, creating the FPG with the TPVV volume.
  
  .PARAMETER NodeId
	Bind the created FPG to the specified node.
	
  .PARAMETER Comment
	Specifies any additional information up to 511 characters for the FPG.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : New-FPG_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-FPG_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $FPGName,	  
	  
	  [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $CPGName,	
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $SizeTiB, 
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Boolean]
	  $FPVV,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Boolean]
	  $TDVV,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NodeId,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Comment,
	  
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
    $body["name"] = "$($FPGName)"
	$body["cpg"] = "$($CPGName)"
	$body["sizeTiB"] = $SizeTiB
   
    If ($FPVV) 
    {
		$body["fpvv"] = $FPVV
    }  

	If ($TDVV) 
    {
		$body["tdvv"] = $TDVV
    } 
	
	If ($NodeId) 
    {
		$body["nodeId"] = $NodeId
    }
	
	If ($Comment) 
	{
          $body["comment"] = "$($Comment)"
    }
    
    $Result = $null
	
    #Request
    $Result = Invoke-WSAPI -uri '/fpgs' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 202)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: File Provisioning Groups:$FPGName created successfully" $Info
		
		Get-FPG_WSAPI -FPG $FPGName
		Write-DebugLog "End: New-FPG_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating File Provisioning Groups:$FPGName" -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating File Provisioning Groups:$FPGName" $Info
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG New-FPG_WSAPI

############################################################################################################################################
## FUNCTION Remove-FPG_WSAPI
############################################################################################################################################
Function Remove-FPG_WSAPI
 {
  <#
  .SYNOPSIS
	Remove a File Provisioning Group.
  
  .DESCRIPTION
	Remove a File Provisioning Group.
        
  .EXAMPLE    
	Remove-FPG_WSAPI -FPGId 123 
	
  .PARAMETER FPGId 
	Specify the File Provisioning Group uuid to be removed.
  
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-FPG_WSAPI     
    LASTEDIT: February 2020
    KEYWORDS: Remove-FPG_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0	
  #>
  [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]
  Param(
	[Parameter(Mandatory = $true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Specify the File Provisioning Group uuid to be removed.')]
	[String]$FPGId,
	
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
	Write-DebugLog "Running: Building uri to Remove-FPG_WSAPI." $Debug
	$uri = '/fpgs/'+$FPGId
	
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-FPG_WSAPI : $FPGId (Invoke-WSAPI)." $Debug
	$Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 202)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: File Provisioning Group:$FPGId successfully remove" $Info
		Write-DebugLog "End: Remove-FPG_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing File Provisioning Group : $FPGId " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Removing File Provisioning Group : $FPGId " $Info
		Write-DebugLog "End: Remove-FPG_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-FPG_WSAPI

############################################################################################################################################
## FUNCTION Get-FPG_WSAPI
############################################################################################################################################
Function Get-FPG_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of File Provisioning Group.
  
  .DESCRIPTION
	Get Single or list of File Provisioning Group.
        
  .EXAMPLE
	Get-FPG_WSAPI
	Display a list of File Provisioning Group.
  
  .EXAMPLE
	Get-FPG_WSAPI -FPG MyFPG
	Display a Given File Provisioning Group.
	
  .EXAMPLE
	Get-FPG_WSAPI -FPG "MyFPG,MyFPG1,MyFPG2,MyFPG3"
	Display Multiple File Provisioning Group.
	
  .PARAMETER FPG
	Name of File Provisioning Group.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-FPG_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Get-FPG_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FPG,
	  
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
	Write-DebugLog "Request: Request to Get-FPG_WSAPI File Provisioning Group : $FPG (Invoke-WSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null		
	$Query="?query=""  """
	
	if($FPG)
	{		
		$count = 1
		$lista = $FPG.split(",")
		if($lista.Count -gt 1)
		{
			foreach($sub in $lista)
			{			
				$Query = $Query.Insert($Query.Length-3," name EQ $sub")			
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
			$uri = '/fpgs/'+$Query
			
			#Request
			$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection		
			If($Result.StatusCode -eq 200)
			{			
				$dataPS = ($Result.content | ConvertFrom-Json).members				
			}
		}
		else
		{
			#Build uri
			$uri = '/fpgs/'+$FPG
			#Request
			$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection		
			If($Result.StatusCode -eq 200)
			{
				$dataPS = $Result.content | ConvertFrom-Json				
			}		
		}
			
	}
	else
	{
		#Request
		$Result = Invoke-WSAPI -uri '/fpgs' -type 'GET' -WsapiConnection $WsapiConnection
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
			Write-DebugLog "SUCCESS: Get-FPG_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-FPG_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-FPG_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-FPG_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-FPG_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-FPG_WSAPI

############################################################################################################################################
## FUNCTION Get-FPGReclamationTasks_WSAPI
############################################################################################################################################
Function Get-FPGReclamationTasks_WSAPI 
{
  <#
  .SYNOPSIS
	Get the reclamation tasks for the FPG.
  
  .DESCRIPTION
	Get the reclamation tasks for the FPG.
        
  .EXAMPLE
    Get-FPGReclamationTasks_WSAPI
	Get the reclamation tasks for the FPG.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-FPGReclamationTasks_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Get-FPGReclamationTasks_WSAPI
   
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
  $Result = Invoke-WSAPI -uri '/fpgs/reclaimtasks' -type 'GET' -WsapiConnection $WsapiConnection

  if($Result.StatusCode -eq 200)
  {
		# Results
		$dataPS = ($Result.content | ConvertFrom-Json).members

		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-FPGReclamationTasks_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-FPGReclamationTasks_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-FPGReclamationTasks_WSAPI." $Info
			
			return 
		}
  }
  else
  {
		write-host ""
		write-host "FAILURE : While Executing Get-FPGReclamationTasks_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-FPGReclamationTasks_WSAPI. " $Info
		
		return $Result.StatusDescription
  }  
}
#END Get-FPGReclamationTasks_WSAPI

############################################################################################################################################
## FUNCTION New-VFS_WSAPI
############################################################################################################################################
Function New-VFS_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create Virtual File Servers.
	
  .DESCRIPTION	
    Create Virtual File Servers.
	
  .EXAMPLE	
	New-VFS_WSAPI
	
  .PARAMETER VFSName
	Name of the VFS to be created.
  
  .PARAMETER PolicyId
	Policy ID associated with the network configuration.
  
  .PARAMETER FPG_IPInfo
	FPG to which VFS belongs.
  
  .PARAMETER VFS
	VFS where the network is configured.
  
  .PARAMETER IPAddr
	IP address.
  
  .PARAMETER Netmask
	Subnet mask.
  
  .PARAMETER NetworkName
	Network configuration name.
  
  .PARAMETER VlanTag
	VFS network configuration VLAN ID.
  
  .PARAMETER CPG
	CPG in which to create the FPG.
  
  .PARAMETER FPG
	Name of an existing FPG in which to create the VFS.
  
  .PARAMETER SizeTiB
	Specifies the size of the FPG you want to create. Required when using the cpg option.
  
  .PARAMETER TDVV
	Enables (true) or disables false creation of the FPG with tdvv volumes. Defaults to false which creates the FPG with the default volume type (tpvv).
  
  .PARAMETER FPVV
	Enables (true) or disables false creation of the FPG with fpvv volumes. Defaults to false which creates the FPG with the default volume type (tpvv).
  
  .PARAMETER NodeId
	Node ID to which to assign the FPG. Always use with cpg member.
  
  .PARAMETER Comment
	Specifies any additional comments while creating the VFS.
  
  .PARAMETER BlockGraceTimeSec
	Block grace time in seconds for quotas within the VFS.
  
  .PARAMETER InodeGraceTimeSec
	The inode grace time in seconds for quotas within the VFS.
  
  .PARAMETER NoCertificate
	true – Does not create a selfsigned certificate associated with the VFS. false – (default) Creates a selfsigned certificate associated with the VFS.
  
  .PARAMETER SnapshotQuotaEnabled
	Enables (true) or disables (false) the quota accounting flag for snapshots at VFS level.
  
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : New-VFS_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-VFS_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VFSName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $PolicyId,
	  
      [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FPG_IPInfo,
	   
      [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VFS,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $IPAddr,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Netmask,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NetworkName,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $VlanTag,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $CPG,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FPG,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $SizeTiB,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $TDVV,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $FPVV,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NodeId, 
	  
	  [Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Comment,
	  
	  [Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $BlockGraceTimeSec,
	  
	  [Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $InodeGraceTimeSec,
	  
	  [Parameter(Position=17, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $NoCertificate,
	  
	  [Parameter(Position=18, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $SnapshotQuotaEnabled,
	  
	  [Parameter(Position=19, Mandatory=$false, ValueFromPipeline=$true)]
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
	$IPInfoBody=@{}
	
	If($VFSName) 
	{
		$body["name"] = "$($VFSName)"
    }
	If($PolicyId) 
	{
		$IPInfoBody["policyId"] = "$($PolicyId)"
    }
	If($FPG_IPInfo) 
	{
		$IPInfoBody["fpg"] = "$($FPG_IPInfo)"
    }
	If($VFS) 
	{
		$IPInfoBody["vfs"] = "$($VFS)"
    }
	If($IPAddr) 
	{
		$IPInfoBody["IPAddr"] = "$($IPAddr)"
    }
	If($Netmask) 
	{
		$IPInfoBody["netmask"] = $Netmask
    }
	If($NetworkName) 
	{
		$IPInfoBody["networkName"] = "$($NetworkName)"
    }
	If($VlanTag) 
	{
		$IPInfoBody["vlanTag"] = $VlanTag
    }
	If($CPG) 
	{
		$body["cpg"] = "$($CPG)" 
    }
	If($FPG) 
	{
		$body["fpg"] = "$($FPG)" 
    }
	If($SizeTiB) 
	{
		$body["sizeTiB"] = $SizeTiB
    }
	If($TDVV) 
	{
		$body["tdvv"] = $true
    }
	If($FPVV) 
	{
		$body["fpvv"] = $true
    }
	If($NodeId) 
	{
		$body["nodeId"] = $NodeId
    }
	If($Comment) 
	{
		$body["comment"] = "$($Comment)"
    }
	If($BlockGraceTimeSec) 
	{
		$body["blockGraceTimeSec"] = $BlockGraceTimeSec
    }
	If($InodeGraceTimeSec) 
	{
		$body["inodeGraceTimeSec"] = $InodeGraceTimeSec
    }
	If($NoCertificate) 
	{
		$body["noCertificate"] = $true
    }
	If($SnapshotQuotaEnabled) 
	{
		$body["snapshotQuotaEnabled"] = $true
    }
	
	if($IPInfoBody.Count -gt 0)
	{
		$body["IPInfo"] = $IPInfoBody 
	}
	
    $Result = $null
		
    #Request
	Write-DebugLog "Request: Request to New-VFS_WSAPI(Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri '/virtualfileservers/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 202)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created Virtual File Servers VFS Name : $VFSName." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-VFS_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Creating Virtual File Servers VFS Name : $VFSName." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Creating Virtual File Servers VFS Name : $VFSName." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-VFS_WSAPI

############################################################################################################################################
## FUNCTION Remove-VFS_WSAPI
############################################################################################################################################
Function Remove-VFS_WSAPI 
{
  <#      
  .SYNOPSIS	
	Removing a Virtual File Servers.
	
  .DESCRIPTION	
    Removing a Virtual File Servers.
	
  .EXAMPLE	
	Remove-VFS_WSAPI -VFSID 1
	
  .PARAMETER VFSID
	Virtual File Servers id.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-VFS_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Remove-VFS_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [int]
	  $VFSID,
	  
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
    $Result = $null
	
	$uri = "/virtualfileservers/"+$VFSID
    #Request
	
	Write-DebugLog "Request: Request to Remove-VFS_WSAPI : $VFSID (Invoke-WSAPI)." $Debug	
    $Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Virtual File Servers : $VFSID successfully Remove." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-VFS_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Dismissing a Virtual File Servers : $VFSID " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Dismissing a Virtual File Servers : $VFSID " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Remove-VFS_WSAPI

############################################################################################################################################
## FUNCTION Get-VFS_WSAPI
############################################################################################################################################
Function Get-VFS_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single Virtual File Servers
  
  .DESCRIPTION
	Get all or single Virtual File Servers
        
  .EXAMPLE
	Get-VFS_WSAPI
	Get List Virtual File Servers
	
  .EXAMPLE
	Get-VFS_WSAPI -VFSID xxx
	Get Single Virtual File Servers
	
  .PARAMETER VFSID	
    Virtual File Servers id.
	
  .PARAMETER VFSName	
    Virtual File Servers Name.
	
  .PARAMETER FPGName	
    File Provisioning Groups Name.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-VFS_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-VFS_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $VFSID,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VFSName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FPGName,
	  
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
	$flg = "Yes"	
	$Query="?query=""  """

	
	if($VFSID)
	{
		if($VFSName -Or $FPGName)
		{
			Return "we cannot use VFSName and FPGName with VFSID as VFSName and FPGName is use for filtering."
		}
		#Request
		$uri = '/virtualfileservers/'+$VFSID
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}		
	}	
	elseif($VFSName)
	{		
		$Query = $Query.Insert($Query.Length-3," name EQ $VFSName")			
		
		if($FPGName)
		{
			$Query = $Query.Insert($Query.Length-3," AND fpg EQ $FPGName")
			$flg = "No"
		}
		#Request
		$uri = '/virtualfileservers/'+$Query
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}
	elseif($FPGName)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," fpg EQ $FPGName")
		}
		#Request
		$uri = '/virtualfileservers/'+$Query
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}		
	}
	else
	{
		#Request
		
		$Result = Invoke-WSAPI -uri '/virtualfileservers' -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}	
	}	
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -eq 0)
		{
			return "No data Fount."
		}
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-VFS_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-VFS_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-VFS_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-VFS_WSAPI

############################################################################################################################################
## FUNCTION New-FileStore_WSAPI
############################################################################################################################################
Function New-FileStore_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create File Store.
	
  .DESCRIPTION	
    Create Create File Store.
	
  .EXAMPLE	
	New-FileStore_WSAPI
	
  .PARAMETER FSName
	Name of the File Store you want to create (max 255 characters).
  
  .PARAMETER VFS
	Name of the VFS under which to create the File Store. If it does not exist, the system creates it.
  
  .PARAMETER FPG
	Name of the FPG in which to create the File Store.
  
  .PARAMETER NTFS
	File Store security mode is NTFS.
  
  .PARAMETER LEGACY
	File Store security mode is legacy.
  
  .PARAMETER SupressSecOpErr 
	Enables or disables the security operations error suppression for File Stores in NTFS security mode. Defaults to false. Cannot be used in LEGACY security mode.
  
  .PARAMETER Comment
	Specifies any additional information about the File Store.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : New-FileStore_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-FileStore_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $FSName,
	     
      [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VFS,
	  
	  [Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $FPG,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $NTFS,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $LEGACY,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $SupressSecOpErr,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Comment,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
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
	
	If($FSName) 
	{
		$body["name"] = "$($FSName)"
    }
	If($VFS) 
	{
		$body["vfs"] = "$($VFS)"
    }
	If($FPG) 
	{
		$body["fpg"] = "$($FPG)" 
    }
	If($NTFS) 
	{
		if($LEGACY)
		{
			return "Please Select Only One Security Mode NTFS or LEGACY"
		}
		else
		{
			$body["securityMode"] = 1
		}
    }
	If($LEGACY) 
	{
		if($NTFS)
		{
			return "Please Select Only One Security Mode NTFS or LEGACY"
		}
		else
		{
			$body["securityMode"] = 2
		}
    }
	If($SupressSecOpErr) 
	{
		$body["supressSecOpErr"] = $true 
    }
	If($Comment) 
	{
		$body["comment"] = "$($Comment)"
    }
	
    $Result = $null
		
    #Request
	Write-DebugLog "Request: Request to New-FileStore_WSAPI(Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri '/filestores/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created File Store, Name: $FSName." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-FileStore_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Creating File Store, Name: $FSName." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Creating File Store, Name: $FSName." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-FileStore_WSAPI

############################################################################################################################################
## FUNCTION Update-FileStore_WSAPI
############################################################################################################################################
Function Update-FileStore_WSAPI 
{
  <#      
  .SYNOPSIS	
	Update File Store.
	
  .DESCRIPTION	
    Updating File Store.
	
  .EXAMPLE	
	Update-FileStore_WSAPI
	
  .PARAMETER FStoreID
	File Stores ID.
	
  .PARAMETER NTFS
	File Store security mode is NTFS.
  
  .PARAMETER LEGACY
	File Store security mode is legacy.
  
  .PARAMETER SupressSecOpErr 
	Enables or disables the security operations error suppression for File Stores in NTFS security mode. Defaults to false. Cannot be used in LEGACY security mode.
  
  .PARAMETER Comment
	Specifies any additional information about the File Store.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Update-FileStore_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Update-FileStore_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $FStoreID,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Comment,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $NTFS,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $LEGACY,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $SupressSecOpErr,
	  
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
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}		
	
	If($Comment) 
	{
		$body["comment"] = "$($Comment)"
    }
	If($NTFS) 
	{
		if($LEGACY)
		{
			return "Please Select Only One Security Mode NTFS or LEGACY"
		}
		else
		{
			$body["securityMode"] = 1
		}
    }
	If($LEGACY) 
	{
		if($NTFS)
		{
			return "Please Select Only One Security Mode NTFS or LEGACY"
		}
		else
		{
			$body["securityMode"] = 2
		}
    }	
	If($SupressSecOpErr) 
	{
		$body["supressSecOpErr"] = $true 
    }	
	
    $Result = $null
		
    #Request
	Write-DebugLog "Request: Request to Update-FileStore_WSAPI(Invoke-WSAPI)." $Debug	
	
	#Request
	$uri = '/filestores/'+$FStoreID
	
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Updated File Store, File Store ID: $FStoreID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Update-FileStore_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Updating File Store, File Store ID: $FStoreID." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Updating File Store, File Store ID: $FStoreID." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Update-FileStore_WSAPI

############################################################################################################################################
## FUNCTION Remove-FileStore_WSAPI
############################################################################################################################################
Function Remove-FileStore_WSAPI 
{
  <#      
  .SYNOPSIS	
	Remove File Store.
	
  .DESCRIPTION	
    Remove File Store.
	
  .EXAMPLE	
	Remove-FileStore_WSAPI
	
  .PARAMETER FStoreID
	File Stores ID.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Remove-FileStore_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Remove-FileStore_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $FStoreID,
	  
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
    #Request
	Write-DebugLog "Request: Request to Remove-FileStore_WSAPI(Invoke-WSAPI)." $Debug	
	
	#Request
	$uri = '/filestores/'+$FStoreID
	
    $Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Removed File Store, File Store ID: $FStoreID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-FileStore_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing File Store, File Store ID: $FStoreID." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Removing File Store, File Store ID: $FStoreID." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Remove-FileStore_WSAPI

############################################################################################################################################
## FUNCTION Get-FileStore_WSAPI
############################################################################################################################################
Function Get-FileStore_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single File Stores.
  
  .DESCRIPTION
	Get all or single File Stores.
        
  .EXAMPLE
	Get-FileStore_WSAPI
	Get List of File Stores.
	
  .EXAMPLE
	Get-FileStore_WSAPI -FStoreID xxx
	Get Single File Stores.
	
  .PARAMETER FStoreID
	File Stores ID.
  
  .PARAMETER FileStoreName
	File Store Name.
  
  .PARAMETER VFSName
	Virtual File Servers Name.
  
  .PARAMETER FPGName
    File Provisioning Groups Name.	

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-FileStore_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-FileStore_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $FStoreID,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FileStoreName,	  
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VFSName,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FPGName,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
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
	$flgVFS = "Yes"
	$flgFPG = "Yes"
	$Query="?query=""  """
	
	if($FStoreID)
	{
		if($VFSName -Or $FPGName -Or $FileStoreName)
		{
			Return "we cannot use VFSName,FileStoreName and FPGName with FStoreID as VFSName,FileStoreName and FPGName is use for filtering."
		}
		#Request
		$uri = '/filestores/'+$FStoreID
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	elseif($FileStoreName)
	{		
		$Query = $Query.Insert($Query.Length-3," name EQ $FileStoreName")			
		
		if($VFSName)
		{
			$Query = $Query.Insert($Query.Length-3," AND vfs EQ $VFSName")
			$flgVFS = "No"
		}
		if($FPGName)
		{
			$Query = $Query.Insert($Query.Length-3," AND fpg EQ $FPGName")
			$flgFPG = "No"
		}
		#Request
		$uri = '/filestores/'+$Query
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}	
	elseif($VFSName)
	{		
		if($flgVFS -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," vfs EQ $VFSName")
		}
		if($FPGName)
		{
			if($flgFPG -eq "Yes")
			{
				$Query = $Query.Insert($Query.Length-3," AND fpg EQ $FPGName")
				$flgFPG = "No"
			}
		}
		#Request
		$uri = '/filestores/'+$Query
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}
	elseif($FPGName)
	{
		if($flgFPG -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," fpg EQ $FPGName")
			$flgFPG = "No"
		}
		#Request
		$uri = '/filestores/'+$Query
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}		
	}
	else
	{
		#Request
		
		$Result = Invoke-WSAPI -uri '/filestores' -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}	
	}	
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -eq 0)
		{
			return "No data Fount."
		}
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-FileStore_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-FileStore_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-FileStore_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-FileStore_WSAPI


############################################################################################################################################
## FUNCTION New-FileStoreSnapshot_WSAPI
############################################################################################################################################
Function New-FileStoreSnapshot_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create File Store snapshot.
	
  .DESCRIPTION	
    Create Create File Store snapshot.
	
  .EXAMPLE	
	New-FileStoreSnapshot_WSAPI
	
  .PARAMETER TAG
	The suffix appended to the timestamp of a snapshot creation to form the snapshot name (<timestamp>_< tag>), using ISO8601 date and time format. Truncates tags in excess of 255 characters.
  
  .PARAMETER FStore
	The name of the File Store for which you are creating a snapshot.
  
  .PARAMETER VFS
	The name of the VFS to which the File Store belongs.
  
  .PARAMETER RetainCount
	In the range of 1 to 1024, specifies the number of snapshots to retain for the File Store.
	Snapshots in excess of the count are deleted beginning with the oldest snapshot.
	If the tag for the specified retainCount exceeds the count value, the oldest snapshot is deleted before the new snapshot is created. 
	If the creation of the new snapshot fails, the deleted snapshot will not be restored.
	
  .PARAMETER FPG
	The name of the FPG to which the VFS belongs.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : New-FileStoreSnapshot_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-FileStoreSnapshot_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $TAG,
	  
	  [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $FStore,
	     
      [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VFS,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $RetainCount,
	  
	  [Parameter(Position=4, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $FPG,
	  
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
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}	
	
	If($TAG) 
	{
		$body["tag"] = "$($TAG)"
    }
	If($FStore) 
	{
		$body["fstore"] = "$($FStore)"
    }
	If($VFS) 
	{
		$body["vfs"] = "$($VFS)"
    }
	If($RetainCount) 
	{
		$body["retainCount"] = $RetainCount 
    }
	If($FPG) 
	{
		$body["fpg"] = "$($FPG)" 
    }
	
    $Result = $null
		
    #Request
	Write-DebugLog "Request: Request to New-FileStoreSnapshot_WSAPI(Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri '/filestoresnapshots/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created File Store snapshot." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-FileStoreSnapshot_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Creating File Store snapshot." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Creating File Store snapshot." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-FileStoreSnapshot_WSAPI

############################################################################################################################################
## FUNCTION Remove-FileStoreSnapshot_WSAPI
############################################################################################################################################
Function Remove-FileStoreSnapshot_WSAPI 
{
  <#      
  .SYNOPSIS	
	Remove File Store snapshot.
	
  .DESCRIPTION	
    Remove File Store snapshot.
	
  .EXAMPLE	
	Remove-FileStoreSnapshot_WSAPI
	
  .PARAMETER ID
	File Store snapshot ID.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Remove-FileStoreSnapshot_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Remove-FileStoreSnapshot_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $ID,
	  
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
    #Request
	Write-DebugLog "Request: Request to Remove-FileStoreSnapshot_WSAPI(Invoke-WSAPI)." $Debug	
	
	#Request
	$uri = '/filestoresnapshots/'+$ID
	
    $Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Removed File Store snapshot, File Store snapshot ID: $ID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-FileStoreSnapshot_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing File Store snapshot, File Store snapshot ID: $ID." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Removing File Store snapshot, File Store snapshot ID: $ID." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Remove-FileStoreSnapshot_WSAPI

############################################################################################################################################
## FUNCTION Get-FileStoreSnapshot_WSAPI
############################################################################################################################################
Function Get-FileStoreSnapshot_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single File Stores snapshot.
  
  .DESCRIPTION
	Get all or single File Stores snapshot.
        
  .EXAMPLE
	Get-FileStoreSnapshot_WSAPI
	Get List of File Stores snapshot.
	
  .EXAMPLE
	Get-FileStoreSnapshot_WSAPI -ID xxx
	Get Single File Stores snapshot.
	
  .PARAMETER ID	
    File Store snapshot ID.
  
  .PARAMETER FileStoreSnapshotName
	File Store snapshot name — exact match and pattern match.
  
  .PARAMETER FileStoreName
	File Store name.
  
  .PARAMETER VFSName
	The name of the VFS to which the File Store snapshot belongs.
  
  .PARAMETER FPGName
	The name of the FPG to which the VFS belongs.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-FileStoreSnapshot_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-FileStoreSnapshot_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ID,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FileStoreSnapshotName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FileStoreName,	  
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VFSName,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FPGName,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
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
	$flgFSN = "Yes"	
	$flgVFS = "Yes"
	$flgFPG = "Yes"
	$Query="?query=""  """
	
	if($ID)
	{
		if($FileStoreSnapshotName -Or $VFSName -Or $FPGName -Or $FileStoreName)
		{
			Return "we cannot use FileStoreSnapshotName,VFSName,FileStoreName and FPGName with ID as FileStoreSnapshotName,VFSName,FileStoreName and FPGName is use for filtering."
		}
		#Request
		$uri = '/filestoresnapshots/'+$ID
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	elseif($FileStoreSnapshotName)
	{		
		$Query = $Query.Insert($Query.Length-3," name EQ $FileStoreSnapshotName")			
		
		if($FileStoreName)
		{
			$Query = $Query.Insert($Query.Length-3," AND fstore EQ $FileStoreName")
			$flgFSN = "No"
		}
		if($VFSName)
		{
			$Query = $Query.Insert($Query.Length-3," AND vfs EQ $VFSName")
			$flgVFS = "No"
		}
		if($FPGName)
		{
			$Query = $Query.Insert($Query.Length-3," AND fpg EQ $FPGName")
			$flgFPG = "No"
		}
		#Request
		$uri = '/filestoresnapshots/'+$Query
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}	

	elseif($FileStoreName)
	{	
		if($flgFSN -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," fstore EQ $FileStoreName")	
		}		
		if($VFSName)
		{
			if($flgVFS -eq "Yes")
			{
				$Query = $Query.Insert($Query.Length-3," AND vfs EQ $VFSName")
				$flgVFS = "No"
			}
		}
		if($FPGName)
		{
			if($flgFPG -eq "Yes")
			{
				$Query = $Query.Insert($Query.Length-3," AND fpg EQ $FPGName")
				$flgFPG = "No"
			}
		}
		#Request
		$uri = '/filestoresnapshots/'+$Query
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}	
	elseif($VFSName)
	{		
		if($flgVFS -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," vfs EQ $VFSName")
		}
		if($FPGName)
		{
			if($flgFPG -eq "Yes")
			{
				$Query = $Query.Insert($Query.Length-3," AND fpg EQ $FPGName")
				$flgFPG = "No"
			}
		}
		#Request
		$uri = '/filestoresnapshots/'+$Query
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}
	elseif($FPGName)
	{
		if($flgFPG -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," fpg EQ $FPGName")
			$flgFPG = "No"
		}
		#Request
		$uri = '/filestoresnapshots/'+$Query
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}		
	}	
	else
	{
		#Request
		
		$Result = Invoke-WSAPI -uri '/filestoresnapshots' -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}	
	}	
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -eq 0)
		{
			return "No data Fount."
		}
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-FileStoreSnapshot_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-FileStoreSnapshot_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-FileStoreSnapshot_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-FileStoreSnapshot_WSAPI

############################################################################################################################################
## FUNCTION New-FileShare_WSAPI
############################################################################################################################################
Function New-FileShare_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create File Share.
	
  .DESCRIPTION	
    Create Create File Share.
	
  .EXAMPLE	
	New-FileShare_WSAPI
	
  .PARAMETER FSName	
	Name of the File Share you want to create.

  .PARAMETER NFS
	File Share of type NFS.

  .PARAMETER SMB
	File Share of type SMB.

  .PARAMETER VFS
	Name of the VFS under which to create the File Share. If it does not exist, the system creates it.

  .PARAMETER ShareDirectory
	Directory path to the File Share. Requires fstore.

  .PARAMETER FStore
	Name of the File Store in which to create the File Share.

  .PARAMETER FPG
	Name of FPG in which to create the File Share.

  .PARAMETER Comment
	Specifies any additional information about the File Share.

  .PARAMETER Enables_SSL
	Enables (true) SSL. Valid for OBJ and FTP File Share types only.

  .PARAMETER Disables_SSL
	Disables (false) SSL. Valid for OBJ and FTP File Share types only.

  .PARAMETER ObjurlPath
	URL that clients will use to access the share. Valid for OBJ File Share type only.

  .PARAMETER NFSOptions
	Valid for NFS File Share type only. Specifies options to use when creating the share. Supports standard NFS export options except no_subtree_check.
	With no options specified, automatically sets the default options.

  .PARAMETER NFSClientlist
	Valid for NFS File Share type only. Specifies the clients that can access the share.
	Specify the NFS client using any of the following:
	• Full name (sys1.hpe.com)
	• Name with a wildcard (*.hpe.com)
	• IP address (usea comma to separate IPaddresses)
	With no list specified, defaults to match everything.

  .PARAMETER SmbABE
	Valid for SMB File Share only.
	Enables (true) or disables (false) Access Based Enumeration (ABE). ABE specifies that users can see only the files and directories to which they have been allowed access on the shares. 
	Defaults to false.

  .PARAMETER SmbAllowedIPs
	List of client IP addresses that are allowed access to the share. Valid for SMB File Share type only.

  .PARAMETER SmbDeniedIPs
	List of client IP addresses that are not allowed access to the share. Valid for SMB File Share type only.

  .PARAMETER SmbContinuosAvailability
	Enables (true) or disables (false) SMB3 continuous availability features for the share. Defaults to true. Valid for SMB File Share type only. 

  .PARAMETER SmbCache
	Specifies clientside caching for offline files.Valid for SMB File Share type only.

  .PARAMETER FtpShareIPs
	Lists the IP addresses assigned to the FTP share. Valid only for FTP File Share type.

  .PARAMETER FtpOptions
	Specifies the configuration options for the FTP share. Use the format:

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : New-FileShare_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-FileShare_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $FSName,
	     
      [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $NFS,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $SMB,
	  
	  [Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VFS,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ShareDirectory,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FStore,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FPG,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Comment,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Enables_SSL,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Disables_SSL,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ObjurlPath,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NFSOptions,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [String[]]
	  $NFSClientlist,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $SmbABE,
	  
	  [Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
      [String[]]
	  $SmbAllowedIPs,
	  
	  [Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
      [String[]]
	  $SmbDeniedIPs,
	  	  
	  [Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $SmbContinuosAvailability,
	  
	  [Parameter(Position=17, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $SmbCache,
	  
	  [Parameter(Position=18, Mandatory=$false, ValueFromPipeline=$true)]
      [String[]]
	  $FtpShareIPs,
	  
	  [Parameter(Position=19, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FtpOptions,
	  	  
	  [Parameter(Position=20, Mandatory=$false, ValueFromPipeline=$true)]
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
	
	If($FSName) 
	{
		$body["name"] = "$($FSName)"
    }
	If($NFS) 
	{
		$body["type"] = 1
    }
	elseIf($SMB) 
	{
		$body["type"] = 2
    }
	else
	{
		return "Please select at-list any one from NFS or SMB its mandatory."
	}
	If($VFS) 
	{
		$body["vfs"] = "$($VFS)"
    }	
	If($ShareDirectory) 
	{
		$body["shareDirectory"] = "$($ShareDirectory)" 
    }
	If($FStore) 
	{
		$body["fstore"] = "$($FStore)" 
    }
	If($FPG) 
	{
		$body["fpg"] = "$($FPG)" 
    }
	If($Comment) 
	{
		$body["comment"] = "$($Comment)"
    }
	If($Enables_SSL) 
	{
		$body["ssl"] = $true
    }	
	If($Disables_SSL) 
	{
		$body["ssl"] = $false
    }
	If($ObjurlPath) 
	{
		$body["objurlPath"] = "$($ObjurlPath)"
    }
	If($NFSOptions) 
	{
		$body["nfsOptions"] = "$($NFSOptions)"
    }
	If($NFSClientlist) 
	{
		$body["nfsClientlist"] = "$($NFSClientlist)"
    }
	If($SmbABE) 
	{
		$body["smbABE"] = $true
    }
	If($SmbAllowedIPs) 
	{
		$body["smbAllowedIPs"] = "$($SmbAllowedIPs)"
    }
	If($SmbDeniedIPs) 
	{
		$body["smbDeniedIPs"] = "$($SmbDeniedIPs)"
    }
	If($SmbContinuosAvailability) 
	{
		$body["smbContinuosAvailability"] = $true
    }
	If($SmbCache) 
	{
		if($SmbCache -Eq "OFF")
		{
			$body["smbCache"] = 1
		}
		elseif($SmbCache -Eq "MANUAL")
		{
			$body["smbCache"] = 2
		}
		elseif($SmbCache -Eq "OPTIMIZED")
		{
			$body["smbCache"] = 3
		}
		elseif($SmbCache -Eq "AUTO")
		{
			$body["smbCache"] = 4
		}
		else
		{
			returm "SmbCache value is incorrect please use any one from [OFF | MANUAL | OPTIMIZED | AUTO] "
		}		
    }
	If($FtpShareIPs) 
	{
		$body["ftpShareIPs"] = "$($FtpShareIPs)"
    }
	If($FtpOptions) 
	{
		$body["ftpOptions"] = "$($FtpOptions)"
    }
	
    $Result = $null
		
    #Request
	Write-DebugLog "Request: Request to New-FileShare_WSAPI(Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri '/fileshares/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created File Share, Name: $FSName." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-FileShare_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Creating File Share, Name: $FSName." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Creating File Share, Name: $FSName." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-FileShare_WSAPI

############################################################################################################################################
## FUNCTION Remove-FileShare_WSAPI
############################################################################################################################################
Function Remove-FileShare_WSAPI 
{
  <#      
  .SYNOPSIS	
	Remove File Share.
	
  .DESCRIPTION	
    Remove File Share.
	
  .EXAMPLE	
	Remove-FileShare_WSAPI
	
  .PARAMETER ID
	File Share ID contains the unique identifier of the File Share you want to remove.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Remove-FileShare_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Remove-FileShare_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $ID,
	  
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
    #Request
	Write-DebugLog "Request: Request to Remove-FileShare_WSAPI(Invoke-WSAPI)." $Debug	
	
	#Request
	$uri = '/fileshares/'+$ID
	
    $Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Removed File Share, File Share ID: $ID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-FileShare_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing File Share, File Share ID: $ID." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Removing File Share, File Share ID: $ID." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Remove-FileShare_WSAPI

############################################################################################################################################
## FUNCTION Get-FileShare_WSAPI
############################################################################################################################################
Function Get-FileShare_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single File Shares.
  
  .DESCRIPTION
	Get all or single File Shares.
        
  .EXAMPLE
	Get-FileShare_WSAPI
	Get List of File Shares.
	
  .EXAMPLE
	Get-FileShare_WSAPI -ID xxx
	Get Single File Shares.
	
  .PARAMETER ID	
    File Share ID contains the unique identifier of the File Share you want to Query.
	
  .PARAMETER FSName
	File Share name.
  
  .PARAMETER FSType
	File Share type, ie, smb/nfs/obj
   
  .PARAMETER VFS
	Name of the Virtual File Servers.
  
  .PARAMETER FPG
	Name of the File Provisioning Groups.
  
  .PARAMETER FStore
	Name of the File Stores.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-FileShare_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-FileShare_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $ID,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FSName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FSType,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VFS,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FPG,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FStore,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
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
	$flg = "NO"
	
	if($ID)
	{
		#Request
		$uri = '/fileshares/'+$ID
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	elseif($FSName -Or $FSType -Or $VFS -Or $FPG -Or $FStore)	
	{
		if($FSName)
		{ 
			$Query = $Query.Insert($Query.Length-3," name EQ $FSName")			
			$flg = "YES"
		}
		if($FSType)
		{
			 if($flg -eq "NO")
			 {
				$Query = $Query.Insert($Query.Length-3," type EQ $FSType")
			 }
			 else
			 {
				$Query = $Query.Insert($Query.Length-3," AND type EQ $FSType")
			 }
			 $flg = "YES"
		}
		if($VFS)
		{
			 if($flg -eq "NO")
			 {
				$Query = $Query.Insert($Query.Length-3," vfs EQ $VFS")
			 }
			 else
			 {
				$Query = $Query.Insert($Query.Length-3," AND vfs EQ $VFS")
			 }
			 $flg = "YES"
		}
		if($FPG)
		{
			 if($flg -eq "NO")
			 {
				$Query = $Query.Insert($Query.Length-3," fpg EQ $FPG")
			 }
			 else
			 {
				$Query = $Query.Insert($Query.Length-3," AND fpg EQ $FPG")
			 }
			 $flg = "YES"
		}
		if($FStore)
		{
			 if($flg -eq "NO")
			 {
				$Query = $Query.Insert($Query.Length-3," fstore EQ $FStore")
			 }
			 else
			 {
				$Query = $Query.Insert($Query.Length-3," AND fstore EQ $FStore")
			 }
			 $flg = "YES"
		}
		
		#Request
		$uri = '/fileshares/'+$Query
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}
	else 
	{
		#Request
		
		$Result = Invoke-WSAPI -uri '/fileshares' -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}	
	}	
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -eq 0)
		{
			return "No data Fount."
		}
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-FileShare_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-FileShare_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-FileShare_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-FileShare_WSAPI

############################################################################################################################################
## FUNCTION Get-DirPermission_WSAPI
############################################################################################################################################
Function Get-DirPermission_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get directory permission properties.
  
  .DESCRIPTION
	Get directory permission properties.
        
  .EXAMPLE
	Get-DirPermission_WSAPI -ID 12
	
  .PARAMETER ID	
    File Share ID contains the unique identifier of the File Share you want to Query.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-DirPermission_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-DirPermission_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [int]
	  $ID,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
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
	$uri = '/fileshares/'+$ID+'/dirperms'
	
	$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	if($Result.StatusCode -eq 200)
	{
		$dataPS = $Result.content | ConvertFrom-Json
	}
	
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -eq 0)
		{
			return "No data Fount."
		}
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-DirPermission_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-DirPermission_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-DirPermission_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-DirPermission_WSAPI

############################################################################################################################################
## FUNCTION New-FilePersonaQuota_WSAPI
############################################################################################################################################
Function New-FilePersonaQuota_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create File Persona quota.
	
  .DESCRIPTION	
    Create File Persona quota.
	
  .EXAMPLE	
	New-FilePersonaQuota_WSAPI
	
  .PARAMETER Name
	The name of the object that the File Persona quotas to be created for.
  
  .PARAMETER Type
	The type of File Persona quota to be created.
	1) user    :user quota type.
	2) group   :group quota type.
	3) fstore  :fstore quota type.
  
  .PARAMETER VFS
	VFS name associated with the File Persona quota.
  
  .PARAMETER FPG
	Name of the FPG hosting the VFS.
  
  .PARAMETER SoftBlockMiB
	Soft capacity storage quota.
  
  .PARAMETER HardBlockMiB
	Hard capacity storage quota.
  
  .PARAMETER SoftFileLimit
	Specifies the soft limit for the number of stored files.
  
  .PARAMETER HardFileLimit
	Specifies the hard limit for the number of stored files.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : New-FilePersonaQuota_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-FilePersonaQuota_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $Name,
	  
	  [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $Type,
	     
      [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VFS,
	  
	  [Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $FPG,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $SoftBlockMiB,	

	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $HardBlockMiB,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $SoftFileLimit,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $HardFileLimit,

	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
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
	
	If($Name) 
	{
		$body["name"] = "$($Name)"
    }
	if($Type)
	{
		$a = "user","group","fstore"
		$l=$Type
		if($a -eq $l)
		{
			if($Type -eq "user")
			{
				$body["type"] = 1
			}
			if($Type -eq "group")
			{
				$body["type"] = 2
			}
			if($Type -eq "fstore")
			{
				$body["type"] = 3
			}						
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Since -Type $Type in incorrect "
			Return "FAILURE : -Type :- $Type is an Incorrect Type [user | group | fstore] can be used only . "
		}
		
	}
	If($VFS) 
	{
		$body["vfs"] = "$($VFS)"
    }
	If($FPG) 
	{
		$body["fpg"] = "$($FPG)" 
    }
	If($SoftBlockMiB) 
	{
		$body["softBlockMiB"] = $SoftBlockMiB
    }
	If($HardBlockMiB) 
	{
		$body["hardBlockMiB"] = $HardBlockMiB
    }
	If($SoftFileLimit) 
	{
		$body["softFileLimit"] = $SoftFileLimit
    }
	If($HardFileLimit) 
	{
		$body["hardFileLimit"] = $HardFileLimit
    }
	
    $Result = $null
		
    #Request
	Write-DebugLog "Request: Request to New-FilePersonaQuota_WSAPI(Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri '/filepersonaquotas/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created File Persona quota." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-FilePersonaQuota_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Creating File Persona quota." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Creating File Persona quota." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-FilePersonaQuota_WSAPI

############################################################################################################################################
## FUNCTION Update-FilePersonaQuota_WSAPI
############################################################################################################################################
Function Update-FilePersonaQuota_WSAPI 
{
  <#      
  .SYNOPSIS	
	Update File Persona quota information.
	
  .DESCRIPTION	
    Updating File Persona quota information.
	
  .EXAMPLE	
	Update-FilePersonaQuota_WSAPI
	
  .PARAMETER ID
	The <id> variable contains the unique ID of the File Persona you want to modify.

  .PARAMETER SoftFileLimit
	Specifies the soft limit for the number of stored files.
	
  .PARAMETER RMSoftFileLimit
	Resets softFileLimit:
	• true —resets to 0
	• false — ignored if false and softFileLimit is set to 0. Set to limit if false and softFileLimit is a positive value.
	
  .PARAMETER HardFileLimit
	Specifies the hard limit for the number of stored files.

  .PARAMETER RMHardFileLimit
	Resets hardFileLimit:
	• true —resets to 0 
	• If false , and hardFileLimit is set to 0, ignores. 
	• If false , and hardFileLimit is a positive value, then set to that limit.	

  .PARAMETER SoftBlockMiB
	Soft capacity storage quota.
	
  .PARAMETER RMSoftBlockMiB
	Resets softBlockMiB: 
	• true —resets to 0 
	• If false , and softBlockMiB is set to 0, ignores.
	• If false , and softBlockMiB is a positive value, then set to that limit.
  
  .PARAMETER HardBlockMiB
	Hard capacity storage quota.
  
  .PARAMETER RMHardBlockMiB
	Resets hardBlockMiB: 
	• true —resets to 0 
	• If false , and hardBlockMiB is set to 0, ignores.
	• If false , and hardBlockMiB is a positive value, then set to that limit.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Update-FilePersonaQuota_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Update-FilePersonaQuota_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $ID,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $SoftFileLimit,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $RMSoftFileLimit,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $HardFileLimit,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $RMHardFileLimit,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $SoftBlockMiB,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $RMSoftBlockMiB,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $HardBlockMiB,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [Int]
	  $RMHardBlockMiB,
	  
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
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}
		
	If($SoftFileLimit) 
	{
		$body["softFileLimit"] = $SoftFileLimit 
    }	
	If($RMSoftFileLimit) 
	{
		$body["rmSoftFileLimit"] = $RMSoftFileLimit 
    }
	If($HardFileLimit) 
	{
		$body["hardFileLimit"] = $HardFileLimit 
    }
	If($RMHardFileLimit) 
	{
		$body["rmHardFileLimit"] = $RMHardFileLimit 
    }
	If($SoftBlockMiB) 
	{
		$body["softBlockMiB"] = $SoftBlockMiB 
    }
	If($RMSoftBlockMiB) 
	{
		$body["rmSoftBlockMiB"] = $RMSoftBlockMiB 
    }
	If($HardBlockMiB) 
	{
		$body["hardBlockMiB"] = $HardBlockMiB 
    }
	If($RMHardBlockMiB) 
	{
		$body["rmHardBlockMiB"] = $RMHardBlockMiB 
    }
	
    $Result = $null
		
    #Request
	Write-DebugLog "Request: Request to Update-FilePersonaQuota_WSAPI(Invoke-WSAPI)." $Debug	
	
	#Request
	$uri = '/filepersonaquotas/'+$ID
	
    $Result = Invoke-WSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Updated File Persona quota information, ID: $ID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Update-FilePersonaQuota_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Updating File Persona quota information, ID: $ID." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Updating File Persona quota information, ID: $ID." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Update-FilePersonaQuota_WSAPI

############################################################################################################################################
## FUNCTION Remove-FilePersonaQuota_WSAPI
############################################################################################################################################
Function Remove-FilePersonaQuota_WSAPI 
{
  <#      
  .SYNOPSIS	
	Remove File Persona quota.
	
  .DESCRIPTION	
    Remove File Persona quota.
	
  .EXAMPLE	
	Remove-FilePersonaQuota_WSAPI
	
  .PARAMETER ID
	The <id> variable contains the unique ID of the File Persona you want to Remove.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-FilePersonaQuota_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Remove-FilePersonaQuota_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $ID,

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
    #Request
	Write-DebugLog "Request: Request to Remove-FilePersonaQuota_WSAPI(Invoke-WSAPI)." $Debug	
	
	#Request
	$uri = '/filepersonaquotas/'+$ID
	
    $Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Removed File Persona quota, File Persona quota ID: $ID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-FilePersonaQuota_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing File Persona quota, File Persona quota ID: $ID." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Removing File Persona quota, File Persona quota ID: $ID." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Remove-FilePersonaQuota_WSAPI

############################################################################################################################################
## FUNCTION Get-FilePersonaQuota_WSAPI
############################################################################################################################################
Function Get-FilePersonaQuota_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single File Persona quota.
  
  .DESCRIPTION
	Get all or single File Persona quota.
        
  .EXAMPLE
	Get-FilePersonaQuota_WSAPI
	Get List of File Persona quota.
	
  .EXAMPLE
	Get-FilePersonaQuota_WSAPI -ID xxx
	Get Single File Persona quota.
	
  .PARAMETER ID	
    The <id> variable contains the unique ID of the File Persona.
	
  .PARAMETER Name
	user, group, or fstore name.
	
  .PARAMETER Key
	user, group, or fstore id.
	
  .PARAMETER QType
	Quota type.
  
  .PARAMETER VFS
	Virtual File Servers name.
  
  .PARAMETER FPG
	File Provisioning Groups name.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-FilePersonaQuota_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-FilePersonaQuota_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $ID,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Name,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Key,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $QType,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VFS,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $FPG,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
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
	$flg = "NO"	
	
	if($ID)
	{
		#Request
		$uri = '/filepersonaquota/'+$ID
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	elseif($Name -Or $Key -Or $QType -Or $VFS -Or $FPG)
	{
		if($Name)
		{ 
			$Query = $Query.Insert($Query.Length-3," name EQ $Name")			
			$flg = "YES"
		}
		if($Key)
		{
			 if($flg -eq "NO")
			 {
				$Query = $Query.Insert($Query.Length-3," key EQ $Key")
			 }
			 else
			 {
				$Query = $Query.Insert($Query.Length-3," AND key EQ $Key")
			 }
			 $flg = "YES"
		}
		if($QType)
		{
			 if($flg -eq "NO")
			 {
				$Query = $Query.Insert($Query.Length-3," type EQ $QType")
			 }
			 else
			 {
				$Query = $Query.Insert($Query.Length-3," AND type EQ $QType")
			 }
			 $flg = "YES"
		}
		if($VFS)
		{
			 if($flg -eq "NO")
			 {
				$Query = $Query.Insert($Query.Length-3," vfs EQ $VFS")
			 }
			 else
			 {
				$Query = $Query.Insert($Query.Length-3," AND vfs EQ $VFS")
			 }
			 $flg = "YES"
		}
		if($FPG)
		{
			 if($flg -eq "NO")
			 {
				$Query = $Query.Insert($Query.Length-3," fpg EQ $FPG")
			 }
			 else
			 {
				$Query = $Query.Insert($Query.Length-3," AND fpg EQ $FPG")
			 }
			 $flg = "YES"
		}
		
		#Request
		$uri = '/filepersonaquota/'+$Query
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}	
	else
	{
		#Request
		
		$Result = Invoke-WSAPI -uri '/filepersonaquota' -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}	
	}	
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -eq 0)
		{
			return "No data Fount."
		}
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-FilePersonaQuota_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-FilePersonaQuota_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-FilePersonaQuota_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-FilePersonaQuota_WSAPI

############################################################################################################################################
## FUNCTION Restore-FilePersonaQuota_WSAPI
############################################################################################################################################
Function Restore-FilePersonaQuota_WSAPI 
{
  <#      
  .SYNOPSIS	
	Restore a File Persona quota.
	
  .DESCRIPTION	
    Restore a File Persona quota.
	
  .EXAMPLE	
	Restore-FilePersonaQuota_WSAPI
	
  .PARAMETER VFSUUID
	VFS UUID.
  
  .PARAMETER ArchivedPath
	The path to the archived file from which the file persona quotas are to be restored.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command  
  
  .Notes
    NAME    : Restore-FilePersonaQuota_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Restore-FilePersonaQuota_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VFSUUID,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ArchivedPath,
	  
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
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}
	$body["action"] = 2 
	
	If($VFSUUID) 
	{
		$body["vfsUUID"] = "$($VFSUUID)"
    }
	
	If($ArchivedPath) 
	{
		$body["archivedPath"] = "$($ArchivedPath)"
    }
	
    $Result = $null
		
    #Request
	Write-DebugLog "Request: Request to Restore-FilePersonaQuota_WSAPI(Invoke-WSAPI)." $Debug	
	
	#Request	
    $Result = Invoke-WSAPI -uri '/filepersonaquotas/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Restore a File Persona quota, VFSUUID: $VFSUUID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Restore-FilePersonaQuota_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Restoring a File Persona quota, VFSUUID: $VFSUUID." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Restoring a File Persona quota, VFSUUID: $VFSUUID." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Restore-FilePersonaQuota_WSAPI

############################################################################################################################################
## FUNCTION Group-FilePersonaQuota_WSAPI
############################################################################################################################################
Function Group-FilePersonaQuota_WSAPI 
{
  <#      
  .SYNOPSIS	
	Archive a File Persona quota.
	
  .DESCRIPTION	
    Archive a File Persona quota.
	
  .EXAMPLE	
	Group-FilePersonaQuota_WSAPI
	
  .PARAMETER QuotaArchiveParameter
	VFS UUID.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command  
  
  .Notes
    NAME    : Group-FilePersonaQuota_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Group-FilePersonaQuota_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $QuotaArchiveParameter,
	  
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
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}
	$body["action"] = 1 
	
	If($QuotaArchiveParameter) 
	{
		$body["quotaArchiveParameter"] = "$($QuotaArchiveParameter)"
    }
	
    $Result = $null
		
    #Request
	Write-DebugLog "Request: Request to Group-FilePersonaQuota_WSAPI(Invoke-WSAPI)." $Debug	
	
	#Request	
    $Result = Invoke-WSAPI -uri '/filepersonaquotas/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Restore a File Persona quota, VFSUUID: $VFSUUID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Group-FilePersonaQuota_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Restoring a File Persona quota, VFSUUID: $VFSUUID." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Restoring a File Persona quota, VFSUUID: $VFSUUID." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Group-FilePersonaQuota_WSAPI


Export-ModuleMember Get-FileServices_WSAPI , New-FPG_WSAPI , Remove-FPG_WSAPI , Get-FPG_WSAPI , Get-FPGReclamationTasks_WSAPI , New-VFS_WSAPI ,
Remove-VFS_WSAPI , Get-VFS_WSAPI , New-FileStore_WSAPI , Update-FileStore_WSAPI , Remove-FileStore_WSAPI , Get-FileStore_WSAPI , New-FileStoreSnapshot_WSAPI ,
Remove-FileStoreSnapshot_WSAPI , Get-FileStoreSnapshot_WSAPI , New-FileShare_WSAPI , Remove-FileShare_WSAPI , Get-FileShare_WSAPI , Get-DirPermission_WSAPI ,
New-FilePersonaQuota_WSAPI , Update-FilePersonaQuota_WSAPI , Remove-FilePersonaQuota_WSAPI , Get-FilePersonaQuota_WSAPI , Group-FilePersonaQuota_WSAPI ,
Restore-FilePersonaQuota_WSAPI