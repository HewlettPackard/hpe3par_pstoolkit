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
##	File Name:		HostSetsAndVirtualVolumeSets.psm1
##	Description: 	Host sets and virtual volume sets cmdlets 
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
## FUNCTION New-HostSet_WSAPI
############################################################################################################################################
Function New-HostSet_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creates a new host Set.
	
  .DESCRIPTION
	Creates a new host Set.
    Any user with the Super or Edit role can create a host set. Any role granted hostset_set permission can add hosts to a host set.
	You can add hosts to a host set using a glob-style pattern. A glob-style pattern is not supported when removing hosts from sets.
	For additional information about glob-style patterns, see “Glob-Style Patterns” in the HPE 3PAR Command Line Interface Reference.
	  
  .PARAMETER HostSetName
	Name of the host set to be created.
  
  .PARAMETER Comment
	Comment for the host set.
	
  .PARAMETER Domain
	The domain in which the host set will be created.
	
  .PARAMETER SetMembers
	The host to be added to the set. The existence of the hist will not be checked.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command

  .EXAMPLE
	New-HostSet_WSAPI -HostSetName MyHostSet
    Creates a new host Set with name MyHostSet.
	
  .EXAMPLE
	New-HostSet_WSAPI -HostSetName MyHostSet -Comment "this Is Test Set" -Domain MyDomain
    Creates a new host Set with name MyHostSet.
	
  .EXAMPLE
	New-HostSet_WSAPI -HostSetName MyHostSet -Comment "this Is Test Set" -Domain MyDomain -SetMembers MyHost
	Creates a new host Set with name MyHostSet with Set Members MyHost.
	
  .EXAMPLE	
	New-HostSet_WSAPI -HostSetName MyHostSet -Comment "this Is Test Set" -Domain MyDomain -SetMembers "MyHost,MyHost1,MyHost2"
    Creates a new host Set with name MyHostSet with Set Members MyHost.	

  .Notes
    NAME    : New-HostSet_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-HostSet_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $HostSetName,	  
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Comment,	
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Domain, 
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [String[]]
	  $SetMembers,
	  
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
    $body["name"] = "$($HostSetName)"
   
    If ($Comment) 
    {
		$body["comment"] = "$($Comment)"
    }  

	If ($Domain) 
    {
		$body["domain"] = "$($Domain)"
    }
	
	If ($SetMembers) 
    {
		$body["setmembers"] = $SetMembers
    }
    
    $Result = $null
	
    #Request
    $Result = Invoke-WSAPI -uri '/hostsets' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Host Set:$HostSetName created successfully" $Info
		
		Get-HostSet_WSAPI -HostSetName $HostSetName
		Write-DebugLog "End: New-HostSet_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating Host Set:$HostSetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating Host Set:$HostSetName " $Info
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG New-HostSet_WSAPI

############################################################################################################################################
## FUNCTION Update-HostSet_WSAPI
############################################################################################################################################
Function Update-HostSet_WSAPI 
{
  <#
  .SYNOPSIS
	Update an existing Host Set.
  
  .DESCRIPTION
	Update an existing Host Set.
    Any user with the Super or Edit role can modify a host set. Any role granted hostset_set permission can add a host to the host set or remove a host from the host set.   
	
  .EXAMPLE    
	Update-HostSet_WSAPI -HostSetName xxx -RemoveMember -Members as-Host4
		
  .EXAMPLE
	Update-HostSet_WSAPI -HostSetName xxx -AddMember -Members as-Host4
	
  .EXAMPLE	
	Update-HostSet_WSAPI -HostSetName xxx -ResyncPhysicalCopy
	
  .EXAMPLE	
	Update-HostSet_WSAPI -HostSetName xxx -StopPhysicalCopy 
		
  .EXAMPLE
	Update-HostSet_WSAPI -HostSetName xxx -PromoteVirtualCopy
		
  .EXAMPLE
	Update-HostSet_WSAPI -HostSetName xxx -StopPromoteVirtualCopy
		
  .EXAMPLE
	Update-HostSet_WSAPI -HostSetName xxx -ResyncPhysicalCopy -Priority high
		
  .PARAMETER HostSetName
	Existing Host Name
	
  .PARAMETER AddMember
	Adds a member to the VV set.
	
  .PARAMETER RemoveMember
	Removes a member from the VV set.
	
  .PARAMETER ResyncPhysicalCopy
	Resynchronize the physical copy to its VV set.
  
  .PARAMETER StopPhysicalCopy
	Stops the physical copy.
  
  .PARAMETER PromoteVirtualCopy
	Promote virtual copies in a VV set.
	
  .PARAMETER StopPromoteVirtualCopy
	Stops the promote virtual copy operations in a VV set.
	
  .PARAMETER NewName
	New name of the set.
	
  .PARAMETER Comment
	New comment for the VV set or host set.
	To remove the comment, use “”.

  .PARAMETER Members
	The volume or host to be added to or removed from the set.
  
  .PARAMETER Priority
	1: high
	2: medium
	3: low

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Update-HostSet_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Update-HostSet_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0      
  #>

  [CmdletBinding()]
  Param(
	[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
	[System.String]
	$HostSetName,
	
	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$AddMember,	
	
	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$RemoveMember,
	
	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$ResyncPhysicalCopy,
	
	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$StopPhysicalCopy,
	
	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$PromoteVirtualCopy,
	
	[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$StopPromoteVirtualCopy,
	
	[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$NewName,
	
	[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Comment,
	
	[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
	[String[]]
	$Members,
	
	[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Priority,

	[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
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
	$counter
	
    If ($AddMember) 
	{
          $body["action"] = 1
		  $counter = $counter + 1
    }
	If ($RemoveMember) 
	{
          $body["action"] = 2
		  $counter = $counter + 1
    }
	If ($ResyncPhysicalCopy) 
	{
          $body["action"] = 3
		  $counter = $counter + 1
    }
	If ($StopPhysicalCopy) 
	{
          $body["action"] = 4
		  $counter = $counter + 1
    }
	If ($PromoteVirtualCopy) 
	{
          $body["action"] = 5
		  $counter = $counter + 1
    }
	If ($StopPromoteVirtualCopy) 
	{
          $body["action"] = 6
		  $counter = $counter + 1
    }
	if($counter -gt 1)
	{
		return "Please Select Only One from [ AddMember | RemoveMember | ResyncPhysicalCopy | StopPhysicalCopy | PromoteVirtualCopy | StopPromoteVirtualCopy]. "
	}
	
	If ($NewName) 
	{
          $body["newName"] = "$($NewName)"
    }
	
	If ($Comment) 
	{
          $body["comment"] = "$($Comment)"
    }
	
	If ($Members) 
	{
          $body["setmembers"] = $Members
    }
	
	If ($Priority) 
	{	
		$a = "high","medium","low"
		$l=$Priority
		if($a -eq $l)
		{
			if($Priority -eq "high")
			{
				$body["priority"] = 1
			}	
			if($Priority -eq "medium")
			{
				$body["priority"] = 2
			}
			if($Priority -eq "low")
			{
				$body["priority"] = 3
			}
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Since -Priority $Priority in incorrect "
			Return "FAILURE : -Priority :- $Priority is an Incorrect Priority  [high | medium | low]  can be used only . "
		} 
    }
	
    $Result = $null	
	$uri = '/hostsets/'+$HostSetName 
	
    #Request
	Write-DebugLog "Request: Request to Update-HostSet_WSAPI : $HostSetName (Invoke-WSAPI)." $Debug
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Host Set:$HostSetName successfully Updated" $Info
				
		# Results
		if($NewName)
		{
			Get-HostSet_WSAPI -HostSetName $NewName
		}
		else
		{
			Get-HostSet_WSAPI -HostSetName $HostSetName
		}
		Write-DebugLog "End: Update-HostSet_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Updating Host Set: $HostSetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Updating Host Set: $HostSetName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Update-HostSet_WSAPI

############################################################################################################################################
## FUNCTION Remove-HostSet_WSAPI
############################################################################################################################################
Function Remove-HostSet_WSAPI
 {
  <#
  .SYNOPSIS
	Remove a Host Set.
  
  .DESCRIPTION
	Remove a Host Set.
	Any user with Super or Edit role, or any role granted host_remove permission, can perform this operation. Requires access to all domains.
        
  .EXAMPLE    
	Remove-HostSet_WSAPI -HostSetName MyHostSet
	
  .PARAMETER HostSetName 
	Specify the name of Host Set to be removed.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-HostSet_WSAPI     
    LASTEDIT: February 2020
    KEYWORDS: Remove-HostSet_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0	
  #>
  [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]
  Param(
	[Parameter(Mandatory = $true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Specifies the name of Host Set.')]
	[String]$HostSetName,
	
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
	Write-DebugLog "Running: Building uri to Remove-HostSet_WSAPI." $Debug
	$uri = '/hostsets/'+$HostSetName
	
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-HostSet_WSAPI : $HostSetName (Invoke-WSAPI)." $Debug
	$Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Host Set:$HostSetName successfully remove" $Info
		Write-DebugLog "End: Remove-HostSet_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing Host Set:$HostSetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating Host Set:$HostSetName " $Info
		Write-DebugLog "End: Remove-HostSet_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-HostSet_WSAPI

############################################################################################################################################
## FUNCTION Get-HostSet_WSAPI
############################################################################################################################################
Function Get-HostSet_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of Hotes Set.
  
  .DESCRIPTION
	Get Single or list of Hotes Set.
        
  .EXAMPLE
	Get-HostSet_WSAPI
	Display a list of Hotes Set.
	
  .EXAMPLE
	Get-HostSet_WSAPI -HostSetName MyHostSet
	Get the information of given Hotes Set.
	
  .EXAMPLE
	Get-HostSet_WSAPI -Members MyHost
	Get the information of Hotes Set that contain MyHost as Member.
	
  .EXAMPLE
	Get-HostSet_WSAPI -Members "MyHost,MyHost1,MyHost2"
	Multiple Members.
	
  .EXAMPLE
	Get-HostSet_WSAPI -Id 10
	Filter Host Set with Id
	
  .EXAMPLE
	Get-HostSet_WSAPI -Uuid 10
	Filter Host Set with uuid
	
  .EXAMPLE
	Get-HostSet_WSAPI -Members "MyHost,MyHost1,MyHost2" -Id 10 -Uuid 10
	Multiple Filter
	
  .PARAMETER HostSetName
	Specify name of the Hotes Set.
	
  .PARAMETER Members
	Specify name of the Hotes.

  .PARAMETER Id
	Specify id of the Hotes Set.
	
  .PARAMETER Uuid
	Specify uuid of the Hotes Set.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-HostSet_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Get-HostSet_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $HostSetName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Members,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Id,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Uuid,
	  
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
	Write-DebugLog "Request: Request to Get-HostSet_WSAPI HostSetName : $HostSetName (Invoke-WSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null		
	$Query="?query=""  """
	
	# Results
	if($HostSetName)
	{
		#Build uri
		$uri = '/hostsets/'+$HostSetName
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
			
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-HostSet_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-HostSet_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-HostSet_WSAPI. " $Info
			
			return $Result.StatusDescription
		}
	}
	if($Members)
	{		
		$count = 1
		$lista = $Members.split(",")
		foreach($sub in $lista)
		{			
			$Query = $Query.Insert($Query.Length-3," setmembers EQ $sub")			
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
	if($Id)
	{
		if($Members)
		{
			$Query = $Query.Insert($Query.Length-3," OR id EQ $Id")
		}
		else
		{
			$Query = $Query.Insert($Query.Length-3," id EQ $Id")
		}
	}
	if($Uuid)
	{
		if($Members -or $Id)
		{
			$Query = $Query.Insert($Query.Length-3," OR uuid EQ $Uuid")
		}
		else
		{
			$Query = $Query.Insert($Query.Length-3," uuid EQ $Uuid")
		}
	}
	
	if($Members -Or $Id -Or $Uuid)
	{
		#Build uri
		$uri = '/hostsets/'+$Query
		
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
		$Result = Invoke-WSAPI -uri '/hostsets' -type 'GET' -WsapiConnection $WsapiConnection
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
			Write-DebugLog "SUCCESS: Get-HostSet_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-HostSet_WSAPI. Expected Result Not Found with Given Filter Option : Members/$Members Id/$Id Uuid/$Uuid." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-HostSet_WSAPI. Expected Result Not Found with Given Filter Option : Members/$Members Id/$Id Uuid/$Uuid." $Info
			
			return 
		}		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-HostSet_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-HostSet_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-HostSet_WSAPI

############################################################################################################################################
## FUNCTION New-VvSet_WSAPI
############################################################################################################################################
Function New-VvSet_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creates a new virtual volume Set.
	
  .DESCRIPTION
	Creates a new virtual volume Set.
    Any user with the Super or Edit role can create a host set. Any role granted hostset_set permission can add hosts to a host set.
	You can add hosts to a host set using a glob-style pattern. A glob-style pattern is not supported when removing hosts from sets.
	For additional information about glob-style patterns, see “Glob-Style Patterns” in the HPE 3PAR Command Line Interface Reference.
	
  .EXAMPLE
	New-VvSet_WSAPI -VVSetName MyVVSet
    Creates a new virtual volume Set with name MyVVSet.
	
  .EXAMPLE
	New-VvSet_WSAPI -VVSetName MyVVSet -Comment "this Is Test Set" -Domain MyDomain
    Creates a new virtual volume Set with name MyVVSet.
	
  .EXAMPLE
	New-VvSet_WSAPI -VVSetName MyVVSet -Comment "this Is Test Set" -Domain MyDomain -SetMembers xxx
	 Creates a new virtual volume Set with name MyVVSet with Set Members xxx.
	
  .EXAMPLE	
	New-VvSet_WSAPI -VVSetName MyVVSet -Comment "this Is Test Set" -Domain MyDomain -SetMembers "xxx1,xxx2,xxx3"
    Creates a new virtual volume Set with name MyVVSet with Set Members xxx.
	
  .PARAMETER VVSetName
	Name of the virtual volume set to be created.
  
  .PARAMETER Comment
	Comment for the virtual volume set.
	
  .PARAMETER Domain
	The domain in which the virtual volume set will be created.
	
  .PARAMETER SetMembers
	The virtual volume to be added to the set. The existence of the hist will not be checked.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : New-VvSet_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-VvSet_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VVSetName,	  
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Comment,	
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Domain, 
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [String[]]
	  $SetMembers,
	  
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
    $body["name"] = "$($VVSetName)"
   
    If ($Comment) 
    {
		$body["comment"] = "$($Comment)"
    }  

	If ($Domain) 
    {
		$body["domain"] = "$($Domain)"
    }
	
	If ($SetMembers) 
    {
		$body["setmembers"] = $SetMembers
    }
    
    $Result = $null
	
    #Request
    $Result = Invoke-WSAPI -uri '/volumesets' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: virtual volume Set:$VVSetName created successfully" $Info
		
		Get-VvSet_WSAPI -VVSetName $VVSetName
		Write-DebugLog "End: New-VvSet_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating virtual volume Set:$VVSetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating virtual volume Set:$VVSetName " $Info
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG New-VvSet_WSAPI

############################################################################################################################################
## FUNCTION Update-VvSet_WSAPI
############################################################################################################################################
Function Update-VvSet_WSAPI 
{
  <#
  .SYNOPSIS
	Update an existing virtual volume Set.
  
  .DESCRIPTION
	Update an existing virtual volume Set.
    Any user with the Super or Edit role can modify a host set. Any role granted hostset_set permission can add a host to the host set or remove a host from the host set.   
	
  .EXAMPLE
	Update-VvSet_WSAPI -VVSetName xxx -RemoveMember -Members testvv3.0
	
  .EXAMPLE 
	Update-VvSet_WSAPI -VVSetName xxx -AddMember -Members testvv3.0
	
  .EXAMPLE 
	Update-VvSet_WSAPI -VVSetName xxx -ResyncPhysicalCopy 
	
  .EXAMPLE 
	Update-VvSet_WSAPI -VVSetName xxx -StopPhysicalCopy 
	
  .EXAMPLE 
	Update-VvSet_WSAPI -VVSetName xxx -PromoteVirtualCopy
	
  .EXAMPLE 
	Update-VvSet_WSAPI -VVSetName xxx -StopPromoteVirtualCopy
	
  .EXAMPLE 
	Update-VvSet_WSAPI -VVSetName xxx -Priority xyz
	
  .EXAMPLE 
	Update-VvSet_WSAPI -VVSetName xxx -ResyncPhysicalCopy -Priority high
	
  .EXAMPLE 
	Update-VvSet_WSAPI -VVSetName xxx -ResyncPhysicalCopy -Priority medium
	
  .EXAMPLE 
	Update-VvSet_WSAPI -VVSetName xxx -ResyncPhysicalCopy -Priority low
	
  .EXAMPLE 
	Update-VvSet_WSAPI -VVSetName xxx -NewName as-vvSet1 -Comment "Updateing new name"

  .PARAMETER VVSetName
	Existing virtual volume Name
	
  .PARAMETER AddMember
	Adds a member to the virtual volume set.
	
  .PARAMETER RemoveMember
	Removes a member from the virtual volume set.
	
  .PARAMETER ResyncPhysicalCopy
	Resynchronize the physical copy to its virtual volume set.
  
  .PARAMETER StopPhysicalCopy
	Stops the physical copy.
  
  .PARAMETER PromoteVirtualCopy
	Promote virtual copies in a virtual volume set.
	
  .PARAMETER StopPromoteVirtualCopy
	Stops the promote virtual copy operations in a virtual volume set.
	
  .PARAMETER NewName
	New name of the virtual volume set.
	
  .PARAMETER Comment
	New comment for the virtual volume set or host set.
	To remove the comment, use “”.

  .PARAMETER Members
	The volume to be added to or removed from the virtual volume set.
  
  .PARAMETER Priority
	1: high
	2: medium
	3: low
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Update-VvSet_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Update-VvSet_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0      
  #>

  [CmdletBinding()]
  Param(
	[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
	[System.String]
	$VVSetName,
	
	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$AddMember,	
	
	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$RemoveMember,
	
	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$ResyncPhysicalCopy,
	
	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$StopPhysicalCopy,
	
	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$PromoteVirtualCopy,
	
	[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$StopPromoteVirtualCopy,
	
	[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$NewName,
	
	[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Comment,
	
	[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
	[String[]]
	$Members,
	
	[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Priority,

	[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
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
	$counter
	
    If ($AddMember) 
	{
          $body["action"] = 1
		  $counter = $counter + 1
    }
	If ($RemoveMember) 
	{
          $body["action"] = 2
		  $counter = $counter + 1
    }
	If ($ResyncPhysicalCopy) 
	{
          $body["action"] = 3
		  $counter = $counter + 1
    }
	If ($StopPhysicalCopy) 
	{
          $body["action"] = 4
		  $counter = $counter + 1
    }
	If ($PromoteVirtualCopy) 
	{
          $body["action"] = 5
		  $counter = $counter + 1
    }
	If ($StopPromoteVirtualCopy) 
	{
          $body["action"] = 6
		  $counter = $counter + 1
    }
	if($counter -gt 1)
	{
		return "Please Select Only One from [ AddMember | RemoveMember | ResyncPhysicalCopy | StopPhysicalCopy | PromoteVirtualCopy | StopPromoteVirtualCopy]. "
	}
	
	If ($NewName) 
	{
          $body["newName"] = "$($NewName)"
    }
	
	If ($Comment) 
	{
          $body["comment"] = "$($Comment)"
    }
	
	If ($Members) 
	{
          $body["setmembers"] = $Members
    }
	
	If ($Priority) 
	{	
		$a = "high","medium","low"
		$l=$Priority
		if($a -eq $l)
		{
			if($Priority -eq "high")
			{
				$body["priority"] = 1
			}	
			if($Priority -eq "medium")
			{
				$body["priority"] = 2
			}
			if($Priority -eq "low")
			{
				$body["priority"] = 3
			}
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Since -Priority $Priority in incorrect "
			Return "FAILURE : -Priority :- $Priority is an Incorrect Priority  [high | medium | low]  can be used only . "
		} 
    }
	
    $Result = $null	
	$uri = '/volumesets/'+$VVSetName 
	
    #Request
	Write-DebugLog "Request: Request to Update-VvSet_WSAPI : $VVSetName (Invoke-WSAPI)." $Debug
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: virtual volume Set:$VVSetName successfully Updated" $Info
				
		# Results
		if($NewName)
		{
			Get-VvSet_WSAPI -VVSetName $NewName
		}
		else
		{
			Get-VvSet_WSAPI -VVSetName $VVSetName
		}
		Write-DebugLog "End: Update-VvSet_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Updating virtual volume Set: $VVSetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Updating virtual volume Set: $VVSetName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Update-VvSet_WSAPI

############################################################################################################################################
## FUNCTION Remove-VvSet_WSAPI
############################################################################################################################################
Function Remove-VvSet_WSAPI
 {
  <#
  .SYNOPSIS
	Remove a virtual volume Set.
  
  .DESCRIPTION
	Remove a virtual volume Set.
	Any user with Super or Edit role, or any role granted host_remove permission, can perform this operation. Requires access to all domains.
        
  .EXAMPLE    
	Remove-VvSet_WSAPI -VVSetName MyvvSet
	
  .PARAMETER VVSetName 
	Specify the name of virtual volume Set to be removed.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-VvSet_WSAPI     
    LASTEDIT: February 2020
    KEYWORDS: Remove-VvSet_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0	
  #>
  [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]
  Param(
	[Parameter(Mandatory = $true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Specifies the name of virtual volume Set.')]
	[String]$VVSetName,
	
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
	Write-DebugLog "Running: Building uri to Remove-VvSet_WSAPI." $Debug
	$uri = '/volumesets/'+$VVSetName
	
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-VvSet_WSAPI : $VVSetName (Invoke-WSAPI)." $Debug
	$Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: virtual volume Set:$VVSetName successfully remove" $Info
		Write-DebugLog "End: Remove-VvSet_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing virtual volume Set:$VVSetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating virtual volume Set:$VVSetName " $Info
		Write-DebugLog "End: Remove-VvSet_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-VvSet_WSAPI

############################################################################################################################################
## FUNCTION Get-VvSet_WSAPI
############################################################################################################################################
Function Get-VvSet_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of virtual volume Set.
  
  .DESCRIPTION
	Get Single or list of virtual volume Set.
        
  .EXAMPLE
	Get-VvSet_WSAPI
	Display a list of virtual volume Set.
	
  .EXAMPLE
	Get-VvSet_WSAPI -VVSetName MyvvSet
	Get the information of given virtual volume Set.
	
  .EXAMPLE
	Get-VvSet_WSAPI -Members Myvv
	Get the information of virtual volume Set that contain MyHost as Member.
	
  .EXAMPLE
	Get-VvSet_WSAPI -Members "Myvv,Myvv1,Myvv2"
	Multiple Members.
	
  .EXAMPLE
	Get-VvSet_WSAPI -Id 10
	Filter virtual volume Set with Id
	
  .EXAMPLE
	Get-VvSet_WSAPI -Uuid 10
	Filter virtual volume Set with uuid
	
  .EXAMPLE
	Get-VvSet_WSAPI -Members "Myvv,Myvv1,Myvv2" -Id 10 -Uuid 10
	Multiple Filter
	
  .PARAMETER VVSetName
	Specify name of the virtual volume Set.
	
  .PARAMETER Members
	Specify name of the virtual volume.

  .PARAMETER Id
	Specify id of the virtual volume Set.
	
  .PARAMETER Uuid
	Specify uuid of the virtual volume Set.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-VvSet_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Get-VvSet_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VVSetName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Members,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Id,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Uuid,
	  
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-WSAPIConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-VvSet_WSAPI VVSetName : $VVSetName (Invoke-WSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null		
	$Query="?query=""  """
	
	# Results
	if($VVSetName)
	{
		#Build uri
		$uri = '/volumesets/'+$VVSetName
		#Request
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection		 
		If($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
			
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-VvSet_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-VvSet_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-VvSet_WSAPI. " $Info
			
			return $Result.StatusDescription
		}
	}
	if($Members)
	{		
		$count = 1
		$lista = $Members.split(",")
		foreach($sub in $lista)
		{			
			$Query = $Query.Insert($Query.Length-3," setmembers EQ $sub")			
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
	if($Id)
	{
		if($Members)
		{
			$Query = $Query.Insert($Query.Length-3," OR id EQ $Id")
		}
		else
		{
			$Query = $Query.Insert($Query.Length-3," id EQ $Id")
		}
	}
	if($Uuid)
	{
		if($Members -or $Id)
		{
			$Query = $Query.Insert($Query.Length-3," OR uuid EQ $Uuid")
		}
		else
		{
			$Query = $Query.Insert($Query.Length-3," uuid EQ $Uuid")
		}
	}
	
	if($Members -Or $Id -Or $Uuid)
	{
		#Build uri
		$uri = '/volumesets/'+$Query
		
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
		$Result = Invoke-WSAPI -uri '/volumesets' -type 'GET' -WsapiConnection $WsapiConnection
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
			Write-DebugLog "SUCCESS: Get-VvSet_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-VvSet_WSAPI. Expected Result Not Found with Given Filter Option : Members/$Members Id/$Id Uuid/$Uuid." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-VvSet_WSAPI. Expected Result Not Found with Given Filter Option : Members/$Members Id/$Id Uuid/$Uuid." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-VvSet_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-VvSet_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-VvSet_WSAPI

############################################################################################################################################
## FUNCTION Set-VvSetFlashCachePolicy_WSAPI
############################################################################################################################################
Function Set-VvSetFlashCachePolicy_WSAPI 
{
  <#      
  .SYNOPSIS	
	Setting a VV-set Flash Cache policy.
	
  .DESCRIPTION	
    Setting a VV-set Flash Cache policy.
	
  .EXAMPLE	
	Set-VvSetFlashCachePolicy_WSAPI
	
  .PARAMETER VvSet
	Name Of the VV-set to Set Flash Cache policy.
  
  .PARAMETER Enable
	To Enable VV-set Flash Cache policy
	
  .PARAMETER Disable
	To Disable VV-set Flash Cache policy
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Set-VvSetFlashCachePolicy_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Set-VvSetFlashCachePolicy_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VvSet,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Enable,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Disable,
	  
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
    $Massage = ""
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}		
	
	If($Enable) 
	{
		$body["flashCachePolicy"] = 1
		$Massage = "Enable"
    }		
	elseIf($Disable) 
	{
		$body["flashCachePolicy"] = 2 
		$Massage = "Disable"
    }
	else
	{
		$body["flashCachePolicy"] = 2 
		$Massage = "Default (Disable)"
    }		
	
    $Result = $null
		
    #Request
	Write-DebugLog "Request: Request to Set-VvSetFlashCachePolicy_WSAPI(Invoke-WSAPI)." $Debug	
	
	#Request
	$uri = '/volumesets/'+$VvSet
	
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Set Flash Cache policy $Massage to vv-set $VvSet." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Set-VvSetFlashCachePolicy_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Setting Flash Cache policy $Massage to vv-set $VvSet." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : VV-set Flash Cache policy To $Massage." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Set-VvSetFlashCachePolicy_WSAPI


Export-ModuleMember New-HostSet_WSAPI , Update-HostSet_WSAPI , Remove-HostSet_WSAPI , Get-HostSet_WSAPI , New-VvSet_WSAPI ,
Update-VvSet_WSAPI , Remove-VvSet_WSAPI , Get-VvSet_WSAPI , Set-VvSetFlashCachePolicy_WSAPI