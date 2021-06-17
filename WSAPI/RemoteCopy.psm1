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
##	File Name:		RemoteCopy.psm1
##	Description: 	Remote Copy cmdlets 
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
## FUNCTION New-RCopyGroup_WSAPI
############################################################################################################################################
Function New-RCopyGroup_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create a Remote Copy group
	
  .DESCRIPTION	
    Create a Remote Copy group
	
  .EXAMPLE
	New-RCopyGroup_WSAPI -RcgName xxx -TargetName xxx -Mode SYNC
	
  .EXAMPLE	
	New-RCopyGroup_WSAPI -RcgName xxx -TargetName xxx -Mode PERIODIC -Domain xxx
	
  .EXAMPLE	
	New-RCopyGroup_WSAPI -RcgName xxx -TargetName xxx -Mode ASYNC -UserCPG xxx -LocalUserCPG xxx -SnapCPG xxx -LocalSnapCPG xxx
	
  .PARAMETER RcgName
	Specifies the name of the Remote Copy group to create.
  
  .PARAMETER Domain
	Specifies the domain in which to create the Remote Copy group.
  
  .PARAMETER TargetName
	Specifies the target name associated with the Remote Copy group to be created.
  
  .PARAMETER Mode
	Specifies the volume group mode.
	SYNC : Remote Copy group mode is synchronous.
	PERIODIC : Remote Copy group mode is periodic. Although WSAPI 1.5 and later supports PERIODIC 2, Hewlett Packard Enterprise recommends using PERIODIC 3.
	PERIODIC : Remote Copy group mode is periodic.
	ASYNC : Remote Copy group mode is asynchronous.
	
  .PARAMETER UserCPG
	Specifies the user CPG used for autocreated target volumes.(Required if you specify localUserCPG.Otherwise,optional.)
  
  .PARAMETER SnapCPG
	Specifies the snap CPG used for auto-created target volumes.(Required if you specify localSnapCPG.Otherwise,optional.)
  
  .PARAMETER LocalUserCPG
	CPG used for autocreated volumes. (Required if you specify localSnapCPG;Otherwise,optional.)
  
  .PARAMETER LocalSnapCPG
	Specifies the local snap CPG used for autocreated volumes.(Optional field. It is required if localUserCPG is specified.)

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : New-RCopyGroup_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-RCopyGroup_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $RcgName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Domain,
	  
	  [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
	  [Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $Mode,

	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $UserCPG,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $SnapCPG,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LocalUserCPG,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LocalSnapCPG,
	  
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
	$TargetsObj = @()
	$TargetsBody = @{}

   
    If ($RcgName) 
	{
		$body["name"] = "$($RcgName)"
    }  
	If ($Domain) 
	{
		$body["domain"] = "$($Domain)"  
    }
	If ($TargetName) 
	{
		$TargetsBody["targetName"] = "$($TargetName)"		
    }
	If ($Mode) 
	{		
		if($Mode.ToUpper() -eq "SYNC")
		{
			$TargetsBody["mode"] = 1			
		}
		elseif($Mode.ToUpper() -eq "PERIODIC")
		{
			$TargetsBody["mode"] = 3	
		}
		elseif($Mode.ToUpper() -eq "ASYNC")
		{
			$TargetsBody["mode"] = 4	
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Since -Mode $Mode in incorrect "
			Return "FAILURE : -Mode :- $Mode is an Incorrect Mode  [SYNC | PERIODIC | ASYNC] can be used only . "
		}
    }
	If ($UserCPG) 
	{
		$TargetsBody["userCPG"] = "$($UserCPG)"
    }
	If ($SnapCPG) 
	{
		$TargetsBody["snapCPG"] = "$($SnapCPG)"
    }
	If ($LocalUserCPG) 
	{
		$body["localUserCPG"] = "$($LocalUserCPG)"
    }
	If ($LocalSnapCPG) 
	{
		$body["localSnapCPG"] = "$($LocalSnapCPG)"
    }
	
	if($TargetsBody.Count -gt 0)
	{
		$TargetsObj += $TargetsBody 
	}
	if($TargetsObj.Count -gt 0)
	{
		$body["targets"] = $TargetsObj 
	}
	
    $Result = $null	
    #Request
	Write-DebugLog "Request: Request to New-RCopyGroup_WSAPI : $RcgName (Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri '/remotecopygroups' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Remote Copy group : $RcgName created successfully." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-RCopyGroup_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Creating a Remote Copy group : $RcgName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Creating a Remote Copy group : $RcgName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-RCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Start-RCopyGroup_WSAPI
############################################################################################################################################
Function Start-RCopyGroup_WSAPI 
{
  <#
  .SYNOPSIS
	Starting a Remote Copy group.
  
  .DESCRIPTION
	Starting a Remote Copy group.
        
  .EXAMPLE
	Start-RCopyGroup_WSAPI -GroupName xxx
	Starting a Remote Copy group.
        
  .EXAMPLE	
	Start-RCopyGroup_WSAPI -GroupName xxx -TargetName xxx
        
  .EXAMPLE	
	Start-RCopyGroup_WSAPI -GroupName xxx -SkipInitialSync
	
  .PARAMETER GroupName
	Group Name.
	
  .PARAMETER SkipInitialSync
	If true, the volume should skip the initial synchronization and sets the volumes to a synchronized state.
	The default setting is false.
  
  .PARAMETER TargetName
	The target name associated with this group.
	
  .PARAMETER VolumeName
	volume name.
	
  .PARAMETER SnapshotName
	Snapshot name.
	
	Note : When used, you must specify all the volumes in the group. While specifying the pair, the starting snapshot is optional.
	When not used, the system performs a full resynchronization of the volume.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Start-RCopyGroup_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Start-RCopyGroup_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
  
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $GroupName,	  
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $SkipInitialSync,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeName,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $SnapshotName,
	  
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
	$body = @{}
	$ObjStartingSnapshots=@{}
	$body["action"] = 3		
	
	If ($SkipInitialSync) 
	{
		$body["skipInitialSync"] = $true	
    }	
	If ($TargetName) 
	{
		$body["targetName"] = "$($TargetName)"
    }	
	If ($VolumeName) 
	{
		$Obj=@{}
		$Obj["volumeName"] = "$($VolumeName)"
		$ObjStartingSnapshots += $Obj				
    }
	If ($SnapshotName) 
	{
		$Obj=@{}
		$Obj["snapshotName"] = "$($SnapshotName)"
		$ObjStartingSnapshots += $Obj				
    }
	
	if($ObjStartingSnapshots.Count -gt 0)
	{
		$body["startingSnapshots"] = $ObjStartingSnapshots 
	}
	
    $Result = $null	
	$uri = "/remotecopygroups/" + $GroupName
	
    #Request
	Write-DebugLog "Request: Request to Start-RCopyGroup_WSAPI (Invoke-WSAPI)." $Debug
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Start a Remote Copy group." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Start-RCopyGroup_WSAPI." $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Starting a Remote Copy group." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Starting a Remote Copy group." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Start-RCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Stop-RCopyGroup_WSAPI
############################################################################################################################################
Function Stop-RCopyGroup_WSAPI 
{
  <#
  .SYNOPSIS
	Stop a Remote Copy group.
  
  .DESCRIPTION
	Stop a Remote Copy group.
        
  .EXAMPLE
	Stop-RCopyGroup_WSAPI -GroupName xxx
	Stop a Remote Copy group.
        
  .EXAMPLE	
	Stop-RCopyGroup_WSAPI -GroupName xxx -TargetName xxx 
        
  .EXAMPLE	
	Stop-RCopyGroup_WSAPI -GroupName xxx -NoSnapshot
	
  .PARAMETER GroupName
	Group Name.
	
  .PARAMETER NoSnapshot
	If true, this option turns off creation of snapshots in synchronous and periodic modes, and deletes the current synchronization snapshots.
	The default setting is false.
  
  .PARAMETER TargetName
	The target name associated with this group.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Stop-RCopyGroup_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Stop-RCopyGroup_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
  
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $GroupName,	  
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $NoSnapshot,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
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
	#$ObjStartingSnapshots=@{}
	$body["action"] = 4		
	
	If ($NoSnapshot) 
	{
		$body["noSnapshot"] = $true	
    }	
	If ($TargetName) 
	{
		$body["targetName"] = "$($TargetName)"
    }	
	
    $Result = $null	
	$uri = "/remotecopygroups/" + $GroupName
	
    #Request
	Write-DebugLog "Request: Request to Stop-RCopyGroup_WSAPI (Invoke-WSAPI)." $Debug
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Stop a Remote Copy group." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Stop-RCopyGroup_WSAPI." $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Stopping a Remote Copy group." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Stopping a Remote Copy group." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Stop-RCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Sync-RCopyGroup_WSAPI
############################################################################################################################################
Function Sync-RCopyGroup_WSAPI 
{
  <#
  .SYNOPSIS
	Synchronize a Remote Copy group.
  
  .DESCRIPTION
	Synchronize a Remote Copy group.
        
  .EXAMPLE
	Sync-RCopyGroup_WSAPI -GroupName xxx
	Synchronize a Remote Copy group.
        
  .EXAMPLE	
	Sync-RCopyGroup_WSAPI -GroupName xxx -NoResyncSnapshot
	        
  .EXAMPLE
	Sync-RCopyGroup_WSAPI -GroupName xxx -TargetName xxx
	        
  .EXAMPLE
	Sync-RCopyGroup_WSAPI -GroupName xxx -TargetName xxx -NoResyncSnapshot
	        
  .EXAMPLE
	Sync-RCopyGroup_WSAPI -GroupName xxx -FullSync
	        
  .EXAMPLE
	Sync-RCopyGroup_WSAPI -GroupName xxx -TargetName xxx -NoResyncSnapshot -FullSync
	
  .PARAMETER GroupName
	Group Name.
	
  .PARAMETER NoResyncSnapshot
	Enables (true) or disables (false) saving the resynchronization snapshot. Applicable only to Remote Copy groups in asynchronous periodic mode.
	Defaults to false.
  
  .PARAMETER TargetName
	The target name associated with this group.
	
  .PARAMETER FullSync
	Enables (true) or disables (false)forcing a full synchronization of the Remote Copy group, even if the volumes are already synchronized.
	Applies only to volume groups in synchronous mode, and can be used to resynchronize volumes that have become inconsistent.
	Defaults to false.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Sync-RCopyGroup_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Sync-RCopyGroup_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
  
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $GroupName,	  
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $NoResyncSnapshot,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $FullSync,
	  
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
	$body = @{}
	#$ObjStartingSnapshots=@{}
	$body["action"] = 5		
	
	If ($NoResyncSnapshot) 
	{
		$body["noResyncSnapshot"] = $true	
    }	
	If ($TargetName) 
	{
		$body["targetName"] = "$($TargetName)"
    }
	If ($FullSync) 
	{
		$body["fullSync"] = $true	
    }	
	
    $Result = $null	
	$uri = "/remotecopygroups/" + $GroupName
	
    #Request
	Write-DebugLog "Request: Request to Sync-RCopyGroup_WSAPI (Invoke-WSAPI)." $Debug
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Synchronize a Remote Copy groupp." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Sync-RCopyGroup_WSAPI." $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Synchronizing a Remote Copy group." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Synchronizing a Remote Copy group." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Sync-RCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Remove-RCopyGroup_WSAPI
############################################################################################################################################
Function Remove-RCopyGroup_WSAPI
 {
  <#
  .SYNOPSIS
	Remove a Remote Copy group.
  
  .DESCRIPTION
	Remove a Remote Copy group.
        
  .EXAMPLE    
	Remove-RCopyGroup_WSAPI -GroupName xxx
	
  .PARAMETER GroupName 
	Group Name.
	
  .PARAMETER KeepSnap 
	To remove a Remote Copy group with the option of retaining the local volume resynchronization snapshot
	The parameter uses one of the following, case-sensitive values:
	• keepSnap=true
	• keepSnap=false

  .EXAMPLE    
	Remove-RCopyGroup_WSAPI -GroupName xxx -KeepSnap $true 

  .EXAMPLE    
	Remove-RCopyGroup_WSAPI -GroupName xxx -KeepSnap $false

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-RCopyGroup_WSAPI     
    LASTEDIT: February 2020
    KEYWORDS: Remove-RCopyGroup_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0	
  #>
  [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]
  Param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$GroupName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[boolean]
		$KeepSnap,
		
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
	Write-DebugLog "Running: Building uri to Remove-RCopyGroup_WSAPI." $Debug
	$uri = '/remotecopygroups/'+ $GroupName
	
	if($keepSnap)
	{
		$uri = $uri + "?keepSnap=true"
	}
	if(!$keepSnap)
	{
		$uri = $uri + "?keepSnap=false"
	}
	
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-RCopyGroup_WSAPI : $GroupName (Invoke-WSAPI)." $Debug
	$Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 202)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Remove a Remote Copy group:$GroupName successfully remove" $Info
		Write-DebugLog "End: Remove-RCopyGroup_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing a Remote Copy group : $GroupName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : Removing a Remote Copy group : $GroupName " $Info
		Write-DebugLog "End: Remove-RCopyGroup_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-RCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Update-RCopyGroup_WSAPI
############################################################################################################################################
Function Update-RCopyGroup_WSAPI 
{
  <#
  .SYNOPSIS
	Modify a Remote Copy group
  
  .DESCRIPTION
	Modify a Remote Copy group.
        
  .EXAMPLE
	Update-RCopyGroup_WSAPI -GroupName xxx -SyncPeriod 301 -Mode ASYNC
	
  .PARAMETER GroupName
	Remote Copy group to update.
	
  .PARAMETER LocalUserCPG
	Specifies the local user CPG for use by autocreated volumes.
	Specify together with:
	• localSnapCPG
	• remoteUserCPG
	• remoteSnapCPG

  .PARAMETER LocalSnapCPG	
	Specifies the local snap CPG for use by autocreated volumes.
	Specify together with:
	• localSnapCPG
	• remoteUserCPG
	• remoteSnapCPG

  .PARAMETER TargetName 
	Specifies the target name associated with the created Remote Copy group.

  .PARAMETER RemoteUserCPG
	Specifies the user CPG on the target used by autocreated volumes.

  .PARAMETER RemoteSnapCPG
	Specifies the snap CPG on the target for use by autocreated volumes.
  
  .PARAMETER SyncPeriod
	Specifies periodic synchronization of asynchronous periodic Remote Copy groups to the<period_value>. Range is 300–31622400 seconds (1year).

  .PARAMETER RmSyncPeriod
	Enables (true) or disables (false)resetting the syncPeriod time to 0 (zero).If false, and the syncPeriod value is positive, the synchronizaiton period is set.

  .PARAMETER Mode
	Specifies the volume group mode.
	SYNC : Remote Copy group mode is synchronous.
	PERIODIC : Remote Copy group mode is periodic. Although WSAPI 1.5 and later supports PERIODIC 2, Hewlett Packard Enterprise recommends using PERIODIC 3.
	PERIODIC : Remote Copy group mode is periodic.
	ASYNC : Remote Copy group mode is asynchronous.

  .PARAMETER SnapFrequency
	Async mode only.
	Specifies the interval in seconds at which Remote Copy takes coordinated snapshots. Range is 300–31622400 seconds (1 year).

  .PARAMETER RmSnapFrequency
	Enables (true) or disables (false) resetting the snapFrequency time to 0 (zero). If false , and the snapFrequency value is positive, sets the snapFrequency value.

  .PARAMETER AutoRecover
	If the Remote Copy is stopped as a result of links going down, the Remote Copy group can be automatically restarted after the links come back up.

  .PARAMETER OverPeriodAlert
	If synchronization of an asynchronous periodic Remote Copy group takes longer to complete than its synchronization period, an alert is generated.	

  .PARAMETER AutoFailover
	Automatic failover on a Remote Copy group.

  .PARAMETER PathManagement
	Automatic failover on a Remote Copy group.

  .PARAMETER MultiTargetPeerPersistence
	Specifies that the group is participating in a Multitarget Peer Persistence configuration. The group must have two targets, one of which must be synchronous.
	The synchronous group target also requires pathManagement and autoFailover policy settings.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Update-RCopyGroup_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Update-RCopyGroup_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
	  [System.String]
	  $GroupName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $LocalUserCPG,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $LocalSnapCPG,	  
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $TargetName,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $RemoteUserCPG,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $RemoteSnapCPG,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $SyncPeriod,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $RmSyncPeriod,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Mode,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $SnapFrequency,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $RmSnapFrequency,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $AutoRecover,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $OverPeriodAlert,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $AutoFailover,
	  
	  [Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $PathManagement,
	  
	  [Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $MultiTargetPeerPersistence,

	  [Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
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
	$TargetsBody=@()
	$PoliciesBody=@{}

	if($LocalUserCPG)
	{
		$body["localUserCPG"] = "$($LocalUserCPG)"
	}
	if($LocalSnapCPG)
	{
		$body["localSnapCPG"] = "$($LocalSnapCPG)"
	}
	If ($TargetName) 
	{
		$Obj=@{}
		$Obj["targetName"] = $TargetName
		$TargetsBody += $Obj				
    }
	If ($RemoteUserCPG) 
	{
		$Obj=@{}
		$Obj["remoteUserCPG"] = "$($RemoteUserCPG)"
		$TargetsBody += $Obj
    }	
	If ($RemoteSnapCPG) 
	{
		$Obj=@{}
		$Obj["remoteSnapCPG"] = "$($RemoteSnapCPG)"
		$TargetsBody += $Obj		
    }	
	If ($SyncPeriod) 
	{
		$Obj=@{}
		$Obj["syncPeriod"] = $SyncPeriod
		$TargetsBody += $Obj			
    }	
	If ($RmSyncPeriod) 
	{
		$Obj=@{}
		$Obj["rmSyncPeriod"] = $RmSyncPeriod
		$TargetsBody += $Obj				
    }
	If ($Mode) 
	{		
		if($Mode -eq "SYNC")
		{
			$MOD=@{}
			$MOD["mode"] = 1
			$TargetsBody += $MOD				
		}
		elseif($Mode -eq "PERIODIC")
		{
			$MOD=@{}
			$MOD["mode"] = 3
			$TargetsBody += $MOD		
		}
		elseif($Mode -eq "ASYNC")
		{
			$MOD=@{}
			$MOD["mode"] = 4
			$TargetsBody += $MOD		
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Since -Mode $Mode in incorrect "
			Return "FAILURE : -Mode :- $Mode is an Incorrect Mode  [SYNC | PERIODIC | ASYNC] can be used only . "
		}
    }	
	If ($SnapFrequency) 
	{
		$Obj=@{}
		$Obj["snapFrequency"] = $SnapFrequency
		$TargetsBody += $Obj				
    }
	If ($RmSnapFrequency) 
	{
		$Obj=@{}
		$Obj["rmSnapFrequency"] = $RmSnapFrequency
		$TargetsBody += $Obj				
    }
	If ($AutoRecover) 
	{		
		$PoliciesBody["autoRecover"] = $AutoRecover
    }
	If ($OverPeriodAlert) 
	{		
		$PoliciesBody["overPeriodAlert"] = $OverPeriodAlert
    }
	If ($AutoFailover) 
	{		
		$PoliciesBody["autoFailover"] = $AutoFailover
    }
	If ($PathManagement) 
	{		
		$PoliciesBody["pathManagement"] = $PathManagement
    }
	If ($MultiTargetPeerPersistence) 
	{		
		$PoliciesBody["multiTargetPeerPersistence"] = $MultiTargetPeerPersistence
    }
	
	if($PoliciesBody.Count -gt 0)
	{
		$TargetsBody += $PoliciesBody 
	}	
	if($TargetsBody.Count -gt 0)
	{
		$body["targets"] = $TargetsBody 
	}	
    
    $Result = $null
	$uri = '/remotecopygroups/'+ $GroupName
	
	
    #Request
	Write-DebugLog "Request: Request to Update-RCopyGroup_WSAPI (Invoke-WSAPI)." $Debug
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Update Remote Copy group." $Info
				
		# Results		
		Get-System_WSAPI		
		Write-DebugLog "End: Update-RCopyGroup_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Updating Remote Copy group." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Updating Remote Copy group." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Update-RCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Update-RCopyGroupTarget_WSAPI
############################################################################################################################################
Function Update-RCopyGroupTarget_WSAPI 
{
  <#
  .SYNOPSIS
	Modifying a Remote Copy group target.
  
  .DESCRIPTION
	Modifying a Remote Copy group target.
        
  .EXAMPLE
	Update-RCopyGroupTarget_WSAPI -GroupName xxx -TargetName xxx -Mode SYNC 
	
  .PARAMETER GroupName
	Remote Copy group Name
  
  .PARAMETER TargetName
	Target Name
	
  .PARAMETER SnapFrequency
	Specifies the interval in seconds at which Remote Copy takes coordinated snapshots. Range is 300–31622400 seconds (1 year).Applicable only for Async mode.

  .PARAMETER RmSnapFrequency
	Enables (true) or disables (false) the snapFrequency interval. If false, and the snapFrequency value is positive, then the snapFrequency value is set.

  .PARAMETER SyncPeriod
	Specifies that asynchronous periodic mode groups should be periodically synchronized to the<period_value>.Range is 300 –31622400 secs (1yr).

  .PARAMETER RmSyncPeriod
	Enables (true) or disables (false) the syncPeriod reset time. If false, and syncPeriod value is positive, then set.

  .PARAMETER Mode
	Specifies the volume group mode.
	SYNC : Remote Copy group mode is synchronous.
	PERIODIC : Remote Copy group mode is periodic. Although WSAPI 1.5 and later supports PERIODIC 2, Hewlett Packard Enterprise recommends using PERIODIC 3.
	PERIODIC : Remote Copy group mode is periodic.
	ASYNC : Remote Copy group mode is asynchronous.

  .PARAMETER AutoRecover
	If the Remote Copy is stopped as a result of links going down, the Remote Copy group can be automatically restarted after the links come back up.

  .PARAMETER OverPeriodAlert
	If synchronization of an asynchronous periodic Remote Copy group takes longer to complete than its synchronization period, an alert is generated.

  .PARAMETER AutoFailover
	Automatic failover on a Remote Copy group.

  .PARAMETER PathManagement
	Automatic failover on a Remote Copy group.

  .PARAMETER MultiTargetPeerPersistence
	Specifies that the group is participating in a Multitarget Peer Persistence configuration. The group must have two targets, one of which must be synchronous. The synchronous group target also requires pathManagement and autoFailover policy settings.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Update-RCopyGroupTarget_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Update-RCopyGroupTarget_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
	  [System.String]
	  $GroupName,
	  
	  [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
	  [System.String]
	  $TargetName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $SnapFrequency,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	  [Boolean]
	  $RmSnapFrequency,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $SyncPeriod,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	  [Boolean]
	  $RmSyncPeriod,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Mode,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $AutoRecover,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $OverPeriodAlert,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $AutoFailover,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $PathManagement,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
	  [int]
	  $MultiTargetPeerPersistence,

	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
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
	#$TargetsBody=@()
	$PoliciesBody=@{}
	
	If ($SyncPeriod) 
	{
		$body["syncPeriod"] = $SyncPeriod
    }	
	If ($RmSyncPeriod) 
	{
		$body["rmSyncPeriod"] = $RmSyncPeriod					
    }
	If ($SnapFrequency) 
	{
		$body["snapFrequency"] = $SnapFrequency
    }
	If ($RmSnapFrequency) 
	{
		$body["rmSnapFrequency"] = $RmSnapFrequency
    }
	If ($Mode) 
	{		
		if($Mode.ToUpper() -eq "SYNC")
		{
			$body["mode"] = 1			
		}
		elseif($Mode.ToUpper() -eq "PERIODIC")
		{
			$body["mode"] = 2		
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Since -Mode $Mode in incorrect "
			Return "FAILURE : -Mode :- $Mode is an Incorrect Mode  [SYNC | PERIODIC] can be used only . "
		}
    }	
	
	If ($AutoRecover) 
	{		
		$PoliciesBody["autoRecover"] = $AutoRecover
    }
	If ($OverPeriodAlert) 
	{		
		$PoliciesBody["overPeriodAlert"] = $OverPeriodAlert
    }
	If ($AutoFailover) 
	{		
		$PoliciesBody["autoFailover"] = $AutoFailover
    }
	If ($PathManagement) 
	{		
		$PoliciesBody["pathManagement"] = $PathManagement
    }
	If ($MultiTargetPeerPersistence) 
	{		
		$PoliciesBody["multiTargetPeerPersistence"] = $MultiTargetPeerPersistence
    }
	
	if($PoliciesBody.Count -gt 0)
	{
		$body["policies"] = $PoliciesBody
	}
    
    $Result = $null
	$uri = '/remotecopygroups/'+ $GroupName+'/targets/'+$TargetName
	
	
    #Request
	Write-DebugLog "Request: Request to Update-RCopyGroupTarget_WSAPI (Invoke-WSAPI)." $Debug
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Update Remote Copy group target." $Info
				
		# Results		
		Get-System_WSAPI		
		Write-DebugLog "End: Update-RCopyGroupTarget_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Updating Remote Copy group target." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Updating Remote Copy group target." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Update-RCopyGroupTarget_WSAPI

############################################################################################################################################
## FUNCTION Restore-RCopyGroup_WSAPI
############################################################################################################################################
Function Restore-RCopyGroup_WSAPI 
{
  <#      
  .SYNOPSIS	
	Recovering a Remote Copy group
	
  .DESCRIPTION	
    Recovering a Remote Copy group
	
  .EXAMPLE
	Recovering a Remote Copy group
	
  .PARAMETER GroupName
	Remote Copy group Name.
	
  .PARAMETER TargetName
	The target name associated with this group on which you want to perform the disaster recovery operation. If the group has multiple targets, the target must be specified.
	
  .PARAMETER SkipStart
	If true, groups are not started after role reversal is completed. Valid for only FAILOVER, RECOVER, and RESTORE operations.
	The default is false.
	
  .PARAMETER SkipSync
	If true, the groups are not synchronized after role reversal is completed. Valid for FAILOVER, RECOVER, and RESTORE operations only.
	The default setting is false.
	
  .PARAMETER DiscardNewData
	If true and the group has multiple targets, don’t check other targets of the group to see if newer data should be pushed from them. Valid for FAILOVER operation only.
	The default setting is false.
  
  .PARAMETER SkipPromote
	If true, the snapshots of the groups that are switched from secondary to primary are not promoted to the base volume. Valid for FAILOVER and REVERSE operations only.
	The default setting is false.
	
  .PARAMETER NoSnapshot
	If true, the snapshots are not taken of the groups that are switched from secondary to primary. Valid for FAILOVER, REVERSE, and RESTOREoperations.
	The default setting is false.
	
  .PARAMETER StopGroups
	If true, the groups are stopped before performing the reverse operation. Valid for REVERSE operation only. 
	The default setting is false.
	
  .PARAMETER LocalGroupsDirection
	If true, the group’s direction is changed only on the system where the operation is run. Valid for REVERSE operation only.
	The default setting is false.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Restore-RCopyGroup_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Restore-RCopyGroup_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $GroupName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $SkipStart,

	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $SkipSync,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $DiscardNewData,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $SkipPromote,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $NoSnapshot,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $StopGroups,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $LocalGroupsDirection,
	  
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
	$body["action"] = 6   
    
	If ($TargetName) 
	{
		$body["targetName"] = "$($TargetName)"
    }
	If ($SkipStart) 
	{
		$body["skipStart"] = $true
    }
	If ($SkipSync) 
	{
		$body["skipSync"] = $true
    }
	If ($DiscardNewData) 
	{
		$body["discardNewData"] = $true
    }
	If ($SkipPromote) 
	{
		$body["skipPromote"] = $true
    }
	If ($NoSnapshot) 
	{
		$body["noSnapshot"] = $true
    }
	If ($StopGroups) 
	{
		$body["stopGroups"] = $true
    }
	If ($LocalGroupsDirection) 
	{
		$body["localGroupsDirection"] = $true
    }	
	
    $Result = $null
	$uri = "/remotecopygroups/"+$GroupName
    #Request
	Write-DebugLog "Request: Request to Restore-RCopyGroup_WSAPI : $GroupName (Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Remote Copy group : $GroupName successfully Recover." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Restore-RCopyGroup_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Recovering a Remote Copy group : $GroupName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Recovering a Remote Copy group : $GroupName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Restore-RCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Add-VvToRCopyGroup_WSAPI
############################################################################################################################################
Function Add-VvToRCopyGroup_WSAPI 
{
  <#      
  .SYNOPSIS	
	Admit a volume into a Remote Copy group
	
  .DESCRIPTION	
    Admit a volume into a Remote Copy group
	
  .EXAMPLE	
	Add-VvToRCopyGroup_WSAPI -GroupName xxx -VolumeName xxx -TargetName xxx -SecVolumeName xxx
	
  .PARAMETER GroupName
	Remote Copy group Name.

  .PARAMETER VolumeName
	Specifies the name of the existing virtual volume to be admitted to an existing Remote Copy group.

  .PARAMETER SnapshotName
	The optional read-only snapshotName is a starting snapshot when the group is started without performing a full resynchronization.
	Instead, for synchronized groups,the volume synchronizes deltas between this snapshotName and the base volume. For periodic groups, the volume synchronizes deltas between this snapshotName and a snapshot of the base.

  .PARAMETER VolumeAutoCreation
	If volumeAutoCreation is set to true, the secondary volumes should be created automatically on the target using the CPG associated with the Remote Copy group on that target. This cannot be set to true if the snapshot name is specified.

  .PARAMETER SkipInitialSync
	If skipInitialSync is set to true, the volume should skip the initial sync. This is for the admission of volumes that have been presynced with the target volume. This cannot be set to true if the snapshot name is specified.

  .PARAMETER DifferentSecondaryWWN
	Setting differentSecondary WWN to true, ensures that the system uses a different WWN on the secondary volume. Defaults to false. Use with volumeAutoCreation

  .PARAMETER TargetName
	Specify at least one pair of targetName and secVolumeName.

  .PARAMETER SecVolumeName
	Specifies the name of the secondary volume on the target system.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Add-VvToRCopyGroup_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Add-VvToRCopyGroup_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $GroupName,
	  
	  [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $SnapshotName,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $VolumeAutoCreation,

	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $SkipInitialSync,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $DifferentSecondaryWWN,
	  
	  [Parameter(Position=6, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
	  [Parameter(Position=7, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $SecVolumeName,
	  
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
	$TargetsBody=@{}	
	$body["action"] = 1   
    
	If ($VolumeName) 
	{
		$body["volumeName"] = "$($VolumeName)"
    }
	If ($SnapshotName) 
	{
		$body["snapshotName"] = "$($SnapshotName)"
    }
	If ($VolumeAutoCreation) 
	{
		$body["volumeAutoCreation"] = $VolumeAutoCreation
    }
	If ($SkipInitialSync) 
	{
		$body["skipInitialSync"] = $SkipInitialSync
    }
	If ($DifferentSecondaryWWN) 
	{
		$body["differentSecondaryWWN"] = $DifferentSecondaryWWN
    }
	If ($TargetName) 
	{
		$Obj=@{}
		$Obj["targetName"] = "$($TargetName)"
		$TargetsBody += $Obj
    }	
	If ($SecVolumeName) 
	{
		$Obj=@{}
		$Obj["secVolumeName"] = "$($SecVolumeName)"
		$TargetsBody += $Obj		
    }	
	if($TargetsBody.Count -gt 0)
	{
		$body["targets"] = $TargetsBody 
	}
	
    $Result = $null
	$uri = "/remotecopygroups/"+$GroupName+"/volumes"
    #Request
	Write-DebugLog "Request: Request to Add-VvToRCopyGroup_WSAPI : $VolumeName (Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Volume into a Remote Copy group : $VolumeName successfully Admitted." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Add-VvToRCopyGroup_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Admitting a volume into a Remote Copy group : $VolumeName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Admitting a volume into a Remote Copy group : $VolumeName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Add-VvToRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Remove-VvFromRCopyGroup_WSAPI
############################################################################################################################################
Function Remove-VvFromRCopyGroup_WSAPI 
{
  <#      
  .SYNOPSIS	
	Dismiss a volume from a Remote Copy group
	
  .DESCRIPTION	
    Dismiss a volume from a Remote Copy group
	
  .EXAMPLE	
	
  .PARAMETER GroupName
	Remote Copy group Name.
	
  .PARAMETER VolumeName
	Specifies the name of the existing virtual volume to be admitted to an existing Remote Copy group.
  
  .PARAMETER KeepSnap
	Enables (true) or disables (false) retention of the local volume resynchronization snapshot. Defaults to false. Do not use with removeSecondaryVolu me.
  
  .PARAMETER RemoveSecondaryVolume
	Enables (true) or disables (false) deletion of the remote volume on the secondary array from the system. Defaults to false. Do not use with keepSnap.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Remove-VvFromRCopyGroup_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Remove-VvFromRCopyGroup_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $GroupName,
	  
	  [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $KeepSnap,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $RemoveSecondaryVolume,
	  
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
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}
	#$TargetsBody=@()	
	$body["action"] = 1   
    
	If ($VolumeName) 
	{
		$body["volumeName"] = "$($VolumeName)"
    }
	If ($KeepSnap) 
	{
		$body["keepSnap"] = $KeepSnap
    }
	If ($RemoveSecondaryVolume) 
	{
		$body["removeSecondaryVolume"] = $RemoveSecondaryVolume
    }
	
    $Result = $null
	$uri = "/remotecopygroups/"+$GroupName+"/volumes/"+$VolumeName
    #Request
	Write-DebugLog "Request: Request to Remove-VvFromRCopyGroup_WSAPI : $VolumeName (Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri $uri -type 'DELETE' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Volume from a Remote Copy group : $VolumeName successfully Remove." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-VvFromRCopyGroup_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Dismissing a volume from a Remote Copy group : $VolumeName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Dismissing a volume from a Remote Copy group : $VolumeName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Remove-VvFromRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION New-RCopyTarget_WSAPI
############################################################################################################################################
Function New-RCopyTarget_WSAPI 
{
  <#      
  .SYNOPSIS	
	Creating a Remote Copy target
	
  .DESCRIPTION	
    Creating a Remote Copy target
	
  .EXAMPLE	
	New-RCopyTarget_WSAPI -TargetName xxx -IP
	
  .EXAMPLE	
	New-RCopyTarget_WSAPI -TargetName xxx  -NodeWWN xxx -FC
	
  .PARAMETER TargetName
	Specifies the name of the target definition to create, up to 24 characters.
  
  .PARAMETER IP
	IP : IP Target Type	
  
  .PARAMETER FC
	FC : FC Target Type
  
  .PARAMETER NodeWWN
	WWN of the node on system2.
  
  .PARAMETER PortPos
	Specifies the port information of system1 (n:s:p) for Remote Copy.
  
  .PARAMETER Link
	Specifies the link for system2. If the linkProtocolType , is IP, specify an IP address for the corresponding port on system2. If the linkProtocolType is FC, specify the WWN of the peer port on system2.

  .PARAMETER Disabled
	Enable (true) or disable (false) the creation of the target in disabled mode.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : New-RCopyTarget_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-RCopyTarget_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $IP,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $FC,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NodeWWN,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $PortPos,

	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $Link, 
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Disabled,
	  
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
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}
	$PortPosAndLinkBody=@{}	 
    
	If($TargetName) 
	{
		$body["name"] = "$($TargetName)"
    }
	If($IP) 
	{
		$body["type"] = 1
    }
	ElseIf ($FC) 
	{
		$body["type"] = 2
    }
	else
	{
		return "Please select at-list any one from IP or FC Type."
	}
	If($NodeWWN) 
	{
		$body["nodeWWN"] = "$($NodeWWN)"
    }
	If($DifferentSecondaryWWN) 
	{
		$body["differentSecondaryWWN"] = $DifferentSecondaryWWN
    }
	If($PortPos) 
	{
		$Obj=@{}
		$Obj["portPos"] = "$($PortPos)"
		$PortPosAndLinkBody += $Obj
    }
	If($Link) 
	{
		$Obj=@{}
		$Obj["link"] = "$($Link)"
		$PortPosAndLinkBody += $Obj
    }
	If($Disabled) 
	{
		$body["disabled"] = $true
    }
	if($PortPosAndLinkBody.Count -gt 0)
	{
		$body["portPosAndLink"] = $PortPosAndLinkBody 
	}
	
    $Result = $null
	
    #Request
	Write-DebugLog "Request: Request to New-RCopyTarget_WSAPI : $TargetName (Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri '/remotecopytargets' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Remote Copy Target : $TargetName created successfully." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-RCopyTarget_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating a Remote Copy target : $TargetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : Creating a Remote Copy target : $TargetName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-RCopyTarget_WSAPI

############################################################################################################################################
## FUNCTION Update-RCopyTarget_WSAPI
############################################################################################################################################
Function Update-RCopyTarget_WSAPI 
{
  <#
  .SYNOPSIS
	Modify a Remote Copy Target
  
  .DESCRIPTION
	Modify a Remote Copy Target.
        
  .EXAMPLE
	Update-RCopyTarget_WSAPI -TargetName xxx
        
  .EXAMPLE
	Update-RCopyTarget_WSAPI -TargetName xxx -MirrorConfig $true
	
  .PARAMETER TargetName
	The <target_name> parameter corresponds to the name of the Remote Copy target you want to modify

  .PARAMETER MirrorConfig
	Enables (true) or disables (false) the duplication of all configurations involving the specified target.
	Defaults to true.
	Use false to allow recovery from an unusual error condition only, and only after consulting your Hewlett Packard Enterprise representative.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Update-RCopyTarget_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Update-RCopyTarget_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  	  
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
	  [System.String]
	  $TargetName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  [Switch]
	  $MirrorConfig,

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
	$body = @{}
	$PoliciesBody = @{}
	
	If ($MirrorConfig) 
	{
		$Obj=@{}
		$Obj["mirrorConfig"] = $true		
		$PoliciesBody += $Obj
    }
	else
	{
		$Obj=@{}
		$Obj["mirrorConfig"] = $false		
		$PoliciesBody += $Obj
	}
	
	if($PoliciesBody.Count -gt 0)
	{
		$body["policies"] = $PoliciesBody 
	}
    
    $Result = $null
	$uri = '/remotecopytargets/'+ $TargetName
	
	
    #Request
	Write-DebugLog "Request: Request to Update-RCopyTarget_WSAPI (Invoke-WSAPI)." $Debug
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Update Remote Copy Target / Target Name : $TargetName." $Info
				
		# Results			
		Write-DebugLog "End: Update-RCopyTarget_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Updating Remote Copy Target / Target Name : $TargetName." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Updating Remote Copy Target / Target Name : $TargetName." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Update-RCopyTarget_WSAPI

############################################################################################################################################
## FUNCTION Add-TargetToRCopyGroup_WSAPI
############################################################################################################################################
Function Add-TargetToRCopyGroup_WSAPI 
{
  <#      
  .SYNOPSIS	
	Admitting a target into a Remote Copy group
	
  .DESCRIPTION	
    Admitting a target into a Remote Copy group
	
  .EXAMPLE	
	Add-TargetToRCopyGroup_WSAPI -GroupName xxx -TargetName xxx
	
  .EXAMPLE	
	Add-TargetToRCopyGroup_WSAPI -GroupName xxx -TargetName xxx -Mode xxx
	
  .EXAMPLE	
	Add-TargetToRCopyGroup_WSAPI -GroupName xxx -TargetName xxx -Mode xxx -LocalVolumeName xxx -RemoteVolumeName xxx
		
  .PARAMETER GroupName
	Remote Copy group Name.
  
  .PARAMETER TargetName
	Specifies the name of the target to admit to an existing Remote Copy group.
  
  .PARAMETER Mode
	Specifies the mode of the target being added.
	SYNC : Remote Copy group mode is synchronous.
	PERIODIC : Remote Copy group mode is periodic. Although WSAPI 1.5 and later supports PERIODIC 2, Hewlett Packard Enterprise recommends using PERIODIC 3.
	PERIODIC : Remote Copy group mode is periodic.
	ASYNC : Remote Copy group mode is asynchronous.
  
  .PARAMETER LocalVolumeName
	Name of the volume on the primary.
  
  .PARAMETER RemoteVolumeName
	Name of the volume on the target.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Add-TargetToRCopyGroup_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Add-TargetToRCopyGroup_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $GroupName,
	   
      [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Mode,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LocalVolumeName,

	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $RemoteVolumeName,
	  
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
	$volumeMappingsObj=@()	
	$volumeMappingsBody=@{}	
    
	If($TargetName) 
	{
		$body["targetName"] = "$($TargetName)"
    }
	If ($Mode) 
	{		
		if($Mode -eq "SYNC")
		{
			$body["mode"] = 1						
		}
		elseif($Mode -eq "PERIODIC")
		{
			$body["mode"] = 3		
		}
		elseif($Mode -eq "ASYNC")
		{
			$body["mode"] = 4		
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Since -Mode $Mode in incorrect "
			Return "FAILURE : -Mode :- $Mode is an Incorrect Mode  [SYNC | PERIODIC | ASYNC] can be used only . "
		}
    }
	If($LocalVolumeName) 
	{
		$volumeMappingsBody["localVolumeName"] = "$($LocalVolumeName)"
    }
	If($RemoteVolumeName) 
	{
		$volumeMappingsBody["remoteVolumeName"] = "$($RemoteVolumeName)"
    }
	
	if($volumeMappingsBody.Count -gt 0)
	{
		$volumeMappingsObj += $volumeMappingsBody 
	}
	if($volumeMappingsObj.Count -gt 0)
	{
		$body["volumeMappings"] = $volumeMappingsObj 
	}
	
    $Result = $null
	$uri = "/remotecopygroups/"+$GroupName+"/targets"
	
    #Request
	Write-DebugLog "Request: Request to Add-TargetToRCopyGroup_WSAPI : TargetName = $TargetName / GroupName = $GroupName(Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Admitted a target into a Remote Copy group : TargetName = $TargetName / GroupName = $GroupName." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Add-TargetToRCopyGroup_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While admitting a target into a Remote Copy group : TargetName = $TargetName / GroupName = $GroupName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : Admitting a target into a Remote Copy group : TargetName = $TargetName / GroupName = $GroupName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Add-TargetToRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Remove-TargetFromRCopyGroup_WSAPI
############################################################################################################################################
Function Remove-TargetFromRCopyGroup_WSAPI 
{
  <#      
  .SYNOPSIS	
	Remove a target from a Remote Copy group
	
  .DESCRIPTION	
    Remove a target from a Remote Copy group
	
  .EXAMPLE	
	Remove-TargetFromRCopyGroup_WSAPI
	
  .PARAMETER GroupName
	Remote Copy group Name.
  
  .PARAMETER TargetName
	Target Name to be removed.  

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Remove-TargetFromRCopyGroup_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Remove-TargetFromRCopyGroup_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $GroupName,
	   
      [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
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
    $Result = $null
	$uri = "/remotecopygroups/"+$GroupName+"/targets/"+$TargetName
	
    #Request
	Write-DebugLog "Request: Request to Remove-TargetFromRCopyGroup_WSAPI : TargetName = $TargetName / GroupName = $GroupName(Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Remove a target from a Remote Copy group : TargetName = $TargetName / GroupName = $GroupName." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-TargetFromRCopyGroup_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While removing  a target from a Remote Copy group : TargetName = $TargetName / GroupName = $GroupName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : Removing a target from a Remote Copy group : TargetName = $TargetName / GroupName = $GroupName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Remove-TargetFromRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION New-SnapRcGroupVv_WSAPI
############################################################################################################################################
Function New-SnapRcGroupVv_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create coordinated snapshots across all Remote Copy group volumes.
	
  .DESCRIPTION	
    Create coordinated snapshots across all Remote Copy group volumes.
	
  .EXAMPLE	
	New-SnapRcGroupVv_WSAPI -GroupName xxx -NewVvNmae xxx -Comment "Hello"
	
  .EXAMPLE	
	New-SnapRcGroupVv_WSAPI -GroupName xxx -NewVvNmae xxx -VolumeName Test -Comment "Hello"
	
  .EXAMPLE	
	New-SnapRcGroupVv_WSAPI -GroupName xxx -NewVvNmae xxx -Comment "Hello" -RetentionHours 1
	
  .EXAMPLE	
	New-SnapRcGroupVv_WSAPI -GroupName xxx -NewVvNmae xxx -Comment "Hello" -VolumeName Test -RetentionHours 1
	
  .PARAMETER GroupName
	Group Name
	
  .PARAMETER VolumeName
	The <volume-name> is the name of the volume to be captured (not the name of the new snapshot volume).
  
  .PARAMETER VVNmae
	Specifies a snapshot VV name up to 31 characters in length. 
	
  .PARAMETER Comment
	Specifies any additional information up to 511 characters for the volume.
	  
  .PARAMETER ExpirationHous
	Specifies the relative time from the current time when volume expires. Positive integer and in the range of 1 - 43,800 hours (1825 days).
	
  .PARAMETER RetentionHours
	Specifies the amount of time,relative to the current time, that the volume is retained. Positive integer in the range of 1 - 43,800 hours (1825 days).
	
  .PARAMETER SkipBlock
	Enables (true) or disables (false) whether the storage system blocks host i/o to the parent virtual volume during the creation of a readonly snapshot.
	Defaults to false.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : New-SnapRcGroupVv_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-SnapRcGroupVv_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $GroupName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeName,
	  
      [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $NewVvNmae,
	   
      [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Comment,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $ExpirationHous,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $RetentionHours,

	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	  [Switch]
	  $SkipBlock,
	  
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
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}
	$ParametersBody=@{}	
    
	$body["action"] = 1   
	
	If($NewVvNmae) 
	{
		$ParametersBody["name"] = "$($NewVvNmae)"
    }
	If($Comment) 
	{
		$ParametersBody["comment"] = "$($Comment)"
    }
	If($ExpirationHous) 
	{
		$ParametersBody["expirationHous"] = $ExpirationHous
    }
	If($RetentionHours) 
	{
		$ParametersBody["retentionHours"] = $RetentionHours
    }
	If($SkipBlock) 
	{
		$ParametersBody["skipBlock"] = $true
    }
	
	if($ParametersBody.Count -gt 0)
	{
		$body["parameters"] = $ParametersBody 
	}
	
    $Result = $null
	if($VolumeName)
	{
		$uri = "/remotecopygroups/"+$GroupName+"/volumes/"+$VolumeName
	}
	else
	{
		$uri = "/remotecopygroups/"+$GroupName+"/volumes"
	}
	
	
    #Request
	Write-DebugLog "Request: Request to New-SnapRcGroupVv_WSAPI(Invoke-WSAPI)." $Debug	
	
    $Result = Invoke-WSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Create coordinated snapshots across all Remote Copy group volumes." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-SnapRcGroupVv_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Creating coordinated snapshots across all Remote Copy group volumes." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Creating coordinated snapshots across all Remote Copy group volumes." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-SnapRcGroupVv_WSAPI

############################################################################################################################################
## FUNCTION Get-RCopyInfo_WSAPI
############################################################################################################################################
Function Get-RCopyInfo_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get overall Remote Copy information
  
  .DESCRIPTION
	Get overall Remote Copy information
        
  .EXAMPLE
	Get-RCopyInfo_WSAPI
	Get overall Remote Copy information

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-RCopyInfo_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-RCopyInfo_WSAPI
   
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
	$Result = Invoke-WSAPI -uri '/remotecopy' -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = $Result.content | ConvertFrom-Json
	
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-RCopyInfo_WSAPI Successfully Executed" $Info
		
		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-RCopyInfo_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-RCopyInfo_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-RCopyInfo_WSAPI

############################################################################################################################################
## FUNCTION Get-RCopyTarget_WSAPI
############################################################################################################################################
Function Get-RCopyTarget_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single Remote Copy targets
  
  .DESCRIPTION
	Get all or single Remote Copy targets
        
  .EXAMPLE
	Get-RCopyTarget_WSAPI

  .EXAMPLE
	Get-RCopyTarget_WSAPI -TargetName xxx	
	
  .PARAMETER TargetName	
    Remote Copy Target Name

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-RCopyTarget_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-RCopyTarget_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
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
	
	#Build uri
	if($TargetName)
	{
		$uri = '/remotecopytargets/'+$TargetName
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	else
	{
		#Request
		$Result = Invoke-WSAPI -uri '/remotecopytargets' -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}		
	}
		  
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-RCopyTarget_WSAPI Successfully Executed" $Info
		
		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-RCopyTarget_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-RCopyTarget_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-RCopyTarget_WSAPI

############################################################################################################################################
## FUNCTION Get-RCopyGroup_WSAPI
############################################################################################################################################
Function Get-RCopyGroup_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single Remote Copy Group
  
  .DESCRIPTION
	Get all or single Remote Copy Group
        
  .EXAMPLE
	Get-RCopyGroup_WSAPI
	Get List of Groups
	
  .EXAMPLE
	Get-RCopyGroup_WSAPI -GroupName XXX
	Get a single Groups of given name

  .EXAMPLE
	Get-RCopyGroup_WSAPI -GroupName XXX*
	Get a single or list of Groups of given name like or match the words
	
  .EXAMPLE
	Get-RCopyGroup_WSAPI -GroupName "XXX,YYY,ZZZ"
	For multiple Group name 
	
  .PARAMETER GroupName	
    Remote Copy Group Name

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-RCopyGroup_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-RCopyGroup_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GroupName,
	  
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
	$Query="?query=""  """
	
	#Build uri
	if($GroupName)
	{
		$lista = $GroupName.split(",")
		
		$count = 1
		foreach($sub in $lista)
		{	
			$Query = $Query.Insert($Query.Length-3," name LIKE $sub")			
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
		$uri = '/remotecopygroups/'+$Query
		
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members	
		}
	}
	else
	{
		#Request
		$Result = Invoke-WSAPI -uri '/remotecopygroups' -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}		
	}
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-RCopyGroup_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While executing Get-RCopyGroup_WSAPI. Expected result not found with given filter option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-RCopyGroup_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-RCopyGroup_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-RCopyGroup_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-RCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Get-RCopyGroupTarget_WSAPI
############################################################################################################################################
Function Get-RCopyGroupTarget_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single Remote Copy Group target
  
  .DESCRIPTION
	Get all or single Remote Copy Group target
        
  .EXAMPLE
	Get-RCopyGroupTarget_WSAPI
	Get List of Groups target
	
  .EXAMPLE
	Get-RCopyGroupTarget_WSAPI -TargetName xxx	
	Get Single Target
	
  .PARAMETER GroupName	
    Remote Copy Group Name
	
  .PARAMETER TargetName	
    Target Name

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-RCopyGroupTarget_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-RCopyGroupTarget_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $GroupName,
	  
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
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
	
	if($TargetName)
	{
		#Request
		$uri = '/remotecopygroups/'+$GroupName+'/targets/'+$TargetName
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	else
	{
		#Request
		$uri = '/remotecopygroups/'+$GroupName+'/targets'
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}	
	
		  
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-RCopyGroupTarget_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-RCopyGroupTarget_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-RCopyGroupTarget_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-RCopyGroupTarget_WSAPI

############################################################################################################################################
## FUNCTION Get-RCopyGroupVv_WSAPI
############################################################################################################################################
Function Get-RCopyGroupVv_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single Remote Copy Group volume
  
  .DESCRIPTION
	Get all or single Remote Copy Group volume
        
  .EXAMPLE
	Get-RCopyGroupVv_WSAPI -GroupName asRCgroup
	
  .EXAMPLE
	Get-RCopyGroupVv_WSAPI -GroupName asRCgroup -VolumeName Test
	
  .PARAMETER GroupName	
    Remote Copy Group Name
	
  .PARAMETER VolumeName	
    Remote Copy Volume Name

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-RCopyGroupVv_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-RCopyGroupVv_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $GroupName,
	  
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
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
	
	if($VolumeName)
	{
		#Request
		$uri = '/remotecopygroups/'+$GroupName+'/volumes/'+$VolumeName
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	else
	{
		#Request
		$uri = '/remotecopygroups/'+$GroupName+'/volumes'
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}	
	}	
		  
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-RCopyGroupVv_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-RCopyGroupVv_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-RCopyGroupVv_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-RCopyGroupVv_WSAPI

############################################################################################################################################
## FUNCTION Get-RCopyLink_WSAPI
############################################################################################################################################
Function Get-RCopyLink_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single Remote Copy Link
  
  .DESCRIPTION
	Get all or single Remote Copy Link
        
  .EXAMPLE
	Get-RCopyLink_WSAPI
	Get List Remote Copy Link
	
  .EXAMPLE
	Get-RCopyLink_WSAPI -LinkName xxx
	Get Single Remote Copy Link
	
  .PARAMETER LinkName	
    Remote Copy Link Name

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-RCopyLink_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-RCopyLink_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LinkName,
	  
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
	
	if($LinkName)
	{
		#Request
		$uri = '/remotecopylinks/'+$LinkName
		
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	else
	{
		#Request
		
		$Result = Invoke-WSAPI -uri '/remotecopylinks' -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}	
	}	
		  
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-RCopyLink_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-RCopyLink_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-RCopyLink_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-RCopyLink_WSAPI


Export-ModuleMember New-RCopyGroup_WSAPI , Start-RCopyGroup_WSAPI , Stop-RCopyGroup_WSAPI , Sync-RCopyGroup_WSAPI , Remove-RCopyGroup_WSAPI , Update-RCopyGroup_WSAPI ,
Restore-RCopyGroup_WSAPI , Add-VvToRCopyGroup_WSAPI , Remove-VvFromRCopyGroup_WSAPI , New-RCopyTarget_WSAPI , Update-RCopyTarget_WSAPI , Update-RCopyGroupTarget_WSAPI ,
Add-TargetToRCopyGroup_WSAPI , Remove-TargetFromRCopyGroup_WSAPI , New-SnapRcGroupVv_WSAPI , Get-RCopyInfo_WSAPI , Get-RCopyTarget_WSAPI , Get-RCopyGroup_WSAPI ,
Get-RCopyGroupTarget_WSAPI , Get-RCopyGroupVv_WSAPI , Get-RCopyLink_WSAPI