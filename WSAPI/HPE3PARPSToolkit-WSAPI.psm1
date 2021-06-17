####################################################################################
##***** 	© 2020,2021 Hewlett Packard Enterprise Development LP
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
## 
##	File Name:		HPE3PARPSToolkit-WSAPI.psm1
##	Description: 	Module functions to automate management of HPE 3PAR StoreServ Storage System
##		
##	Pre-requisites: WSAPI uses HPE 3PAR CLI commands to start, configure, and modify the WSAPI server.
##					For more information about using the CLI, see:
##					• HPE 3PAR Command Line Interface Administrator Guide
##					• HPE 3PAR Command Line Interface Reference
##
##					Starting the WSAPI server    : The WSAPI server does not start automatically.
##					Using the CLI, enter startwsapi to manually start the WSAPI server.
## 					Configuring the WSAPI server: To configure WSAPI, enter setwsapi in the CLI.
##
##	Created:		May 2018
##	Last Modified:	January 2019
##	
##	History:		v2.2 - WSAPI (v1.6.3) support for the following:
##							CRUD operations on CPG, Volume, host, host sets, VV sets, VLUN, FPG/VFS/File Shares, Remote Copy Group etc.
##							Querying and filtering system events and tasks
##							Configuring and querying ports
##							Querying system capacity
##							Creating physical copy of volume/VV set and re-synchronizing 
##							SR reports - Statistical data reports for CPG, PD, ports, VLUN, QoS & Remote Copy volumes etc.
##							Querying WSAPI users and roles								
##								
#######################################################################################

$Info = "INFO:"
$Debug = "DEBUG:"
$global:VSLibraries = Split-Path $MyInvocation.MyCommand.Path
$global:ArrayT = $null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

add-type @" 

public struct WSAPIconObject{
public string Id;
public string Name;
public string SystemVersion;
public string Patches;
public string IPAddress;
public string Model;
public string SerialNumber;
public string TotalCapacityMiB;
public string AllocatedCapacityMiB;
public string FreeCapacityMiB;
public string Key;
}

"@

############################################################################################################################################
## New-3PARWSAPIConnection
############################################################################################################################################
Function New-3PARWSAPIConnection {
<#	
  .SYNOPSIS
	Create a WSAPI session key
  
  .DESCRIPTION
    This cmdlet (New-3PARWSAPIConnection) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-WSAPIConnection) instead.
  
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
    Specify the Array FQDN or IP address.
	
  .PARAMETER ArrayType
	A type of array either 3Par or Primera. 
              
  .Notes
    NAME    : New-3PARWSAPIConnection    
    LASTEDIT: 06/01/2018
    KEYWORDS: New-3PARWSAPIConnection
   
  .Link
     http://www.hpe.com
 
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

			[Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true)]
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
		
		#Write-DebugLog "start: Entering function New-3PARWSAPIConnection. Validating IP Address format." $Debug	
		#if(-not (Test-IPFormat $ArrayFQDNorIPAddress))		
		#{
		#	Write-DebugLog "Stop: Invalid IP Address $ArrayFQDNorIPAddress" "ERR:"
		#	return "FAILURE : Invalid IP Address $ArrayFQDNorIPAddress"
		#}
		
		Write-DebugLog "Running: Completed validating IP address format." $Debug		
		Write-DebugLog "Running: Authenticating credentials - Invoke-WSAPI for user $SANUserName and SANIP= $ArrayFQDNorIPAddress" $Debug
		
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
			write-host " You have entered unsupported Array type : $ArrayType . Please enter the array type as 3par or Primera." -foreground yello
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
				
		$Result = Get-3PARSystem_WSAPI -WsapiConnection $SANC1
		
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
#End of New-3PARWSAPIConnection

############################################################################################################################################
## FUNCTION Close-3PARWSAPIConnection
############################################################################################################################################
Function Close-3PARWSAPIConnection
 {
  <#

  .SYNOPSIS
	Delete a session key.
  
  .DESCRIPTION
    This cmdlet (Close-3PARWSAPIConnection ) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Close-WSAPIConnection) instead.
  
	When finishes making requests to the server it should delete the session keys it created .
	Unused session keys expire automatically after the configured session times out.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .EXAMPLE
    Close-3PARWSAPIConnection
	Delete a session key.
              
  .Notes
    NAME    : Close-3PARWSAPIConnection    
    LASTEDIT: 06/01/2018
    KEYWORDS: Close-3PARWSAPIConnection
   
  .Link
     http://www.hpe.com
 
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
	Write-DebugLog "End: Close-3PARWSAPIConnection" $Debug
  }
  End {}  
}
#END Close-3PARWSAPIConnection

############################################################################################################################################
## FUNCTION Get-3PARCapacity_WSAPI
############################################################################################################################################
Function Get-3PARCapacity_WSAPI 
{
  <#
  
  .SYNOPSIS
	Overall system capacity.
  
  .DESCRIPTION
    This cmdlet (Get-3PARCapacity_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-CapacityInfo_WSAPI) instead.
  
	Overall system capacity.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .EXAMPLE
    Get-3PARCapacity_WSAPI
	Display Overall system capacity.
              
  .Notes
    NAME    : Get-3PARCapacity_WSAPI   
    LASTEDIT: 01/08/2018
    KEYWORDS: Get-3PARCapacity_WSAPI
   
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
  Test-3PARConnection -WsapiConnection $WsapiConnection

  #Request 
  $Result = Invoke-3parWSAPI -uri '/capacity' -type 'GET' -WsapiConnection $WsapiConnection

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
  Write-DebugLog "End: Get-3PARCapacity_WSAPI(WSAPI)" $Debug
  return $dataPS
}
#END Get-3PARCapacity_WSAPI

############################################################################################################################################
## FUNCTION New-3PARCpg_WSAPI
############################################################################################################################################
Function New-3PARCpg_WSAPI 
{
  <#
  
  .SYNOPSIS
	The New-3PARCpg_WSAPI command creates a Common Provisioning Group (CPG).
  
  .DESCRIPTION
    This cmdlet (New-3PARCpg_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-Cpg_WSAPI) instead.
  
	The New-3PARCpg_WSAPI command creates a Common Provisioning Group (CPG).
        
  .EXAMPLE    
	New-3PARCpg_WSAPI -CPGName XYZ 
        
  .EXAMPLE	
	New-3PARCpg_WSAPI -CPGName "MyCPG" -Domain Chef_Test
        
  .EXAMPLE	
	New-3PARCpg_WSAPI -CPGName "MyCPG" -Domain Chef_Test -Template Test_Temp
        
  .EXAMPLE	
	New-3PARCpg_WSAPI -CPGName "MyCPG" -Domain Chef_Test -Template Test_Temp -GrowthIncrementMiB 100
        
  .EXAMPLE	
	New-3PARCpg_WSAPI -CPGName "MyCPG" -Domain Chef_Test -RAIDType R0

  .PARAMETER CPGName
	Specifies the name of the CPG.  

  .PARAMETER Domain
	Specifies the name of the domain in which the object will reside.  

  .PARAMETER Template
	Specifies the name of the template from which the CPG is created.
	
  .PARAMETER GrowthIncrementMiB
	Specifies the growth increment, in MiB, the amount of logical disk storage created on each auto-grow operation.  
	
  .PARAMETER GrowthLimitMiB
	Specifies that the autogrow operation is limited to the specified storage amount, in MiB, that sets the growth limit.
	
  .PARAMETER UsedLDWarningAlertMiB
	Specifies that the threshold of used logical disk space, in MiB, when exceeded results in a warning alert.
	  
  .PARAMETER RAIDType
	RAID type for the logical disk
	R0 RAID level 0
	R1 RAID level 1
	R5 RAID level 5
	R6 RAID level 6
	  
  .PARAMETER SetSize
	Specifies the set size in the number of chunklets.
	  
  .PARAMETER HA
	Specifies that the layout must support the failure of one port pair, one cage, or one magazine.
	PORT Support failure of a port.
	CAGE Support failure of a drive cage.
	MAG Support failure of a drive magazine.
	
  .PARAMETER Chunklets
	FIRST Lowest numbered available chunklets, where transfer rate is the fastest.
	LAST  Highest numbered available chunklets, where transfer rate is the slowest.
	
  .PARAMETER NodeList
	Specifies one or more nodes. Nodes are identified by one or more integers. Multiple nodes are separated with a single comma (1,2,3). 
	A range of nodes is separated with a hyphen (0–7). The primary path of the disks must be on the specified node number.
	
  .PARAMETER SlotList
	Specifies one or more PCI slots. Slots are identified by one or more integers. Multiple slots are separated with a single comma (1,2,3). 
	A range of slots is separated with a hyphen (0–7). The primary path of the disks must be on the specified PCI slot number(s).
	
  .PARAMETER PortList
	Specifies one or more ports. Ports are identified by one or more integers. Multiple ports are separated with a single comma (1,2,3). 
	A range of ports is separated with a hyphen (0–4). The primary path of the disks must be on the specified port number(s).
	
  .PARAMETER CageList
	Specifies one or more drive cages. Drive cages are identified by one or more integers. Multiple drive cages are separated with a single comma (1,2,3). 
	A range of drive cages is separated with a hyphen (0– 3). The specified drive cage(s) must contain disks.
	
  .PARAMETER MagList 
	Specifies one or more drive magazines. Drive magazines are identified by one or more integers. Multiple drive magazines are separated with a single comma (1,2,3). 
	A range of drive magazines is separated with a hyphen (0–7). The specified magazine(s) must contain disks.  
	
  .PARAMETER DiskPosList
	Specifies one or more disk positions within a drive magazine. Disk positions are identified by one or more integers. Multiple disk positions are separated with a single comma (1,2,3). 
	A range of disk positions is separated with a hyphen (0–3). The specified portion(s) must contain disks.
	
  .PARAMETER DiskList
	Specifies one or more physical disks. Disks are identified by one or more integers. Multiple disks are separated with a single comma (1,2,3). 
	A range of disks is separated with a hyphen (0–3). Disks must match the specified ID(s). 
	
  .PARAMETER TotalChunkletsGreaterThan
	Specifies that physical disks with total chunklets greater than the number specified be selected.  
	
  .PARAMETER TotalChunkletsLessThan
	Specifies that physical disks with total chunklets less than the number specified be selected. 
	
  .PARAMETER FreeChunkletsGreaterThan
	Specifies that physical disks with free chunklets less than the number specified be selected.  
	
  .PARAMETER FreeChunkletsLessThan
	 Specifies that physical disks with free chunklets greater than the number specified be selected. 
	 
  .PARAMETER DiskType
	Specifies that physical disks must have the specified device type.
	FC Fibre Channel
	NL Near Line
	SSD SSD
	  
  .PARAMETER Rpm
	Disks must be of the specified speed.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : New-3PARCpg_WSAPI    
    LASTEDIT: 01/08/2018
    KEYWORDS: New-3PARCpg_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Mandatory = $true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Specifies the name of the CPG.')]
      [String]
	  $CPGName,
	  
      [Parameter(Mandatory = $false,HelpMessage = 'Specifies the name of the domain in which the object will reside.')]
      [String]
	  $Domain = $null,
	  
      [Parameter(Mandatory = $false,HelpMessage = 'Specifies the name of the template from which the CPG is created')]
      [String]
	  $Template = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies the growth increment, in MiB, the amount of logical disk storage created on each auto-grow operation')]
      [Int]
	  $GrowthIncrementMiB = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies that the autogrow operation is limited to the specified storage amount, in MiB, that sets the growth limit')]
      [int]
	  $GrowthLimitMiB = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies that the threshold of used logical disk space, in MiB, when exceeded results in a warning alert')]
      [int]
	  $UsedLDWarningAlertMiB = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'RAIDType R0,R1,R5 and R6 only.')]
      [string]
	  $RAIDType = $null, 
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies the set size in the number of chunklets.')]
      [int]
	  $SetSize = $null,
	  
      [Parameter(Mandatory = $false,HelpMessage = 'Specifies that the layout must support the failure of one port pair, one cage, or one magazine.')]
      [string]
	  $HA = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies the chunklet location preference characteristics.')]
      [string]
	  $Chunklets = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more nodes. Nodes are identified by one or more integers.')]
      [String]
	  $NodeList = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more nodes. Nodes are identified by one or more integers.')]
      [String]
	  $SlotList = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more ports. Ports are identified by one or more integers..')]
      [String]
	  $PortList = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more drive cages. Drive cages are identified by one or more integers.')]
      [String]
	  $CageList = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more drive magazines. Drive magazines are identified by one or more integers..')]
      [String]
	  $MagList = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more disk positions within a drive magazine. Disk positions are identified by one or more integers.')]
      [String]
	  $DiskPosList = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more physical disks. Disks are identified by one or more integers.')]
      [String]
	  $DiskList = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies that physical disks with total chunklets greater than the number specified be selected.')]
      [int]
	  $TotalChunkletsGreaterThan = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies that physical disks with total chunklets less than the number specified be selected.')]
      [int]
	  $TotalChunkletsLessThan = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies that physical disks with free chunklets less than the number specified be selected.')]
      [int]
	  $FreeChunkletsGreaterThan = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies that physical disks with free chunklets greater than the number specified be selected.')]
      [int]
	  $FreeChunkletsLessThan = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies that physical disks must have the specified device type, FC (Fibre Channel) 2 is for NL (Near Line) 3 is for SSD .')]
      [string]
	  $DiskType = $null,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Disks must be of the specified speed')]
      [int]
	  $Rpm = $null,
	  
	  [Parameter(Mandatory=$false, HelpMessage = 'Connection Paramater' ,ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection 
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    # Creation of the body hash
	Write-DebugLog "Running: Creation of the body hash" $Debug
    $body = @{}	
		
    # Name parameter
    $body["name"] = "$($CPGName)"

    # Domain parameter
    If ($Domain) 
    {
		$body["domain"] = "$($Domain)"
    }

    # Template parameter
    If ($Template) 
    {
		$body["template"] = "$($Template)"
    } 

	# Template parameter
    If ($GrowthIncrementMiB) 
    {
		$body["growthIncrementMiB"] = $GrowthIncrementMiB
    } 
	
	# Template parameter
    If ($GrowthLimitMiB) 
    {
		$body["growthLimitMiB"] = $GrowthLimitMiB
    } 
	
	# Template parameter
    If ($UsedLDWarningAlertMiB) 
    {
		$body["usedLDWarningAlertMiB"] = $UsedLDWarningAlertMiB
    } 
	
	$LDLayoutBody = @{}
	# LDLayout
	#Specifies the RAID type for the logical disk
	if ($RAIDType)
	{		
		if($RAIDType -eq "R0")
		{
			$LDLayoutBody["RAIDType"] = 1
		}
		elseif($RAIDType -eq "R1")
		{
			$LDLayoutBody["RAIDType"] = 2
		}
		elseif($RAIDType -eq "R5")
		{
			$LDLayoutBody["RAIDType"] = 3
		}
		elseif($RAIDType -eq "R6")
		{
			$LDLayoutBody["RAIDType"] = 4
		}
		else
		{
			Write-DebugLog "Stop: Exiting  New-3PARCpg_WSAPI   since RAIDType $RAIDType in incorrect "
			Return "FAILURE : RAIDType :- $RAIDType is an Incorrect Please Use RAIDType R0,R1,R5 and R6 only. "
		}		
	}
	#Specifies the set size in the number of chunklets.
    if ($SetSize)
	{	
		$LDLayoutBody["setSize"] = $SetSize				
	}
	#Specifies that the layout must support the failure of one port pair, one cage, or one magazine.
	if ($HA)
	{
		if($HA -eq "PORT")
		{
			$LDLayoutBody["HA"] = 1					
		}
		elseif($HA -eq "CAGE")
		{
			$LDLayoutBody["HA"] = 2					
		}
		elseif($HA -eq "MAG")
		{
			$LDLayoutBody["HA"] = 3					
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  New-3PARCpg_WSAPI since HA $HA in incorrect "
			Return "FAILURE : HA :- $HA is an Incorrect Please Use [ PORT | CAGE | MAG ] only "
		}
	}
	#Specifies the chunklet location preference characteristics
	if ($Chunklets)
	{		
		if($Chunklets -eq "FIRST")
		{
			$LDLayoutBody["chunkletPosPref"] = 1					
		}
		elseif($Chunklets -eq "LAST")
		{
			$LDLayoutBody["chunkletPosPref"] = 2					
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  New-3PARCpg_WSAPI since Chunklets $Chunklets in incorrect "
			Return "FAILURE : Chunklets :- $Chunklets is an Incorrect Please Use Chunklets FIRST and LAST only. "
		}
	}
	
	$LDLayoutDiskPatternsBody=@()	
	
	if ($NodeList)
	{
		$nodList=@{}
		$nodList["nodeList"] = "$($NodeList)"	
		$LDLayoutDiskPatternsBody += $nodList 			
	}
	
	if ($SlotList)
	{
		$sList=@{}
		$sList["slotList"] = "$($SlotList)"	
		$LDLayoutDiskPatternsBody += $sList 		
	}
	
	if ($PortList)
	{
		$pList=@{}
		$pList["portList"] = "$($PortList)"	
		$LDLayoutDiskPatternsBody += $pList 		
	}
	
	if ($CageList)
	{
		$cagList=@{}
		$cagList["cageList"] = "$($CageList)"	
		$LDLayoutDiskPatternsBody += $cagList 		
	}
	
	if ($MagList)
	{
		$mList=@{}
		$mList["magList"] = "$($MagList)"	
		$LDLayoutDiskPatternsBody += $mList 		
	}
	
	if ($DiskPosList)
	{
		$dpList=@{}
		$dpList["diskPosList"] = "$($DiskPosList)"	
		$LDLayoutDiskPatternsBody += $dpList 		
	}

	if ($DiskList)
	{
		$dskList=@{}
		$dskList["diskList"] = "$($DiskList)"	
		$LDLayoutDiskPatternsBody += $dskList 		
	}
	
	if ($TotalChunkletsGreaterThan)
	{
		$tcgList=@{}
		$tcgList["totalChunkletsGreaterThan"] = $TotalChunkletsGreaterThan	
		$LDLayoutDiskPatternsBody += $tcgList 		
	}
	
	if ($TotalChunkletsLessThan)
	{
		$tclList=@{}
		$tclList["totalChunkletsLessThan"] = $TotalChunkletsLessThan	
		$LDLayoutDiskPatternsBody += $tclList 		
	}
	
	if ($FreeChunkletsGreaterThan)
	{
		$fcgList=@{}
		$fcgList["freeChunkletsGreaterThan"] = $FreeChunkletsGreaterThan	
		$LDLayoutDiskPatternsBody += $fcgList 		
	}
	
	if ($FreeChunkletsLessThan)
	{
		$fclList=@{}
		$fclList["freeChunkletsLessThan"] = $FreeChunkletsLessThan	
		$LDLayoutDiskPatternsBody += $fclList 		
	}
	
	if ($DiskType)
	{		
		if($DiskType -eq "FC")
		{			
			$dtList=@{}
			$dtList["diskType"] = 1	
			$LDLayoutDiskPatternsBody += $dtList						
		}
		elseif($DiskType -eq "NL")
		{			
			$dtList=@{}
			$dtList["diskType"] = 2	
			$LDLayoutDiskPatternsBody += $dtList						
		}
		elseif($DiskType -eq "SSD")
		{			
			$dtList=@{}
			$dtList["diskType"] = 3	
			$LDLayoutDiskPatternsBody += $dtList						
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  New-3PARCpg_WSAPI   since DiskType $DiskType in incorrect "
			Return "FAILURE : DiskType :- $DiskType is an Incorrect Please Use FC (Fibre Channel), NL (Near Line) and SSD only"
		}
	}
	
	if ($Rpm)
	{
		$rpmList=@{}
		$rpmList["RPM"] = $Rpm	
		$LDLayoutDiskPatternsBody += $rpmList
	}	
		
	
	if($LDLayoutDiskPatternsBody.Count -gt 0)
	{
		$LDLayoutBody["diskPatterns"] = $LDLayoutDiskPatternsBody	
	}		
	if($LDLayoutBody.Count -gt 0)
	{
		$body["LDLayout"] = $LDLayoutBody 
	}	
	
    #init the response var
    $Result = $null	
	
	#$json = $body | ConvertTo-Json  -Compress -Depth 10
	#write-host " Body = $json"
	
    #Request
    $Result = Invoke-3parWSAPI -uri '/cpgs' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: CPG:$CPGName created successfully" $Info
		
		#write-host " StatusCode = $status"
		# Results
		Get-3PARCpg_WSAPI -CPGName $CPGName
		Write-DebugLog "End: New-3PARCpg_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating CPG:$CPGName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating CPG:$CPGName " $Info
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG New-3PARCpg_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARCpg_WSAPI
############################################################################################################################################
Function Get-3PARCpg_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get list or single common provisioning groups (CPGs) all CPGs in the storage system.
  
  .DESCRIPTION
    This cmdlet (Get-3PARCpg_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-Cpg_WSAPI) instead.
  
	Get list or single common provisioning groups (CPGs) all CPGs in the storage system.
        
  .EXAMPLE
	Get-3PARCpg_WSAPI
	List all/specified common provisioning groups (CPGs) in the system.
	
  .EXAMPLE
	Get-3PARCpg_WSAPI -CPGName "MyCPG" 
	List Specified CPG name "MyCPG"
	
  .PARAMETER CPGName
	Specify name of the cpg to be listed
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
              
  .Notes
    NAME    : Get-3PARCpg_WSAPI   
    LASTEDIT: 11/01/2018
    KEYWORDS: Get-3PARCpg_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Mandatory = $false,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'CPG Name')]
      [String]
	  $CPGName,
	  
	  [Parameter(Mandatory=$false, ValueFromPipeline=$true , HelpMessage = 'Connection Paramater')]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null	
	
	#Build uri
	if($CPGName)
	{
		$uri = '/cpgs/'+$CPGName
		#Request
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/cpgs' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: CPG:$CPGName Successfully Executed" $Info

		# Add custom type to the resulting oject for formating purpose
		Write-DebugLog "Running: Add custom type to the resulting object for formatting purpose" $Debug
		
		#[array]$AlldataPS = Format-Result -dataPS $dataPS -TypeName '3PAR.Cpgs'		
		#return $AlldataPS
		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARCpg_WSAPI CPG:$CPGName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARCpg_WSAPI CPG:$CPGName " $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARCpg_WSAPI

############################################################################################################################################
## FUNCTION Update-3PARCpg_WSAPI
############################################################################################################################################
Function Update-3PARCpg_WSAPI 
{
  <#
  
  .SYNOPSIS
	The Update-3PARCpg_WSAPI command Update a Common Provisioning Group (CPG).
  
  .DESCRIPTION
    This cmdlet (Update-3PARCpg_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Update-Cpg_WSAPI) instead.
  
	The Update-3PARCpg_WSAPI command Update a Common Provisioning Group (CPG).
	This operation requires access to all domains, as well as Super, Service, or Edit roles, or any role granted cpg_set permission.
    
  .EXAMPLE   
	Update-3PARCpg_WSAPI -CPGName ascpg -NewName as_cpg
    
  .EXAMPLE 	
	Update-3PARCpg_WSAPI -CPGName xxx -RAIDType R1
    
  .EXAMPLE 	
	Update-3PARCpg_WSAPI -CPGName xxx -DisableAutoGrow $true
    
  .EXAMPLE 	
	Update-3PARCpg_WSAPI -CPGName xxx -RmGrowthLimit $true
    
  .EXAMPLE 	
	Update-3PARCpg_WSAPI -CPGName xxx -RmWarningAlert $true
	    
  .EXAMPLE 
	Update-3PARCpg_WSAPI -CPGName xxx -SetSize 10
    
  .EXAMPLE 	
	Update-3PARCpg_WSAPI -CPGName xxx -HA PORT
    
  .EXAMPLE 	
	Update-3PARCpg_WSAPI -CPGName xxx -Chunklets FIRST
    
  .EXAMPLE 	
	Update-3PARCpg_WSAPI -CPGName xxx -NodeList 0
		
  .PARAMETER CPGName,
	pecifies the name of Existing CPG.  

  .PARAMETER NewName,
	Specifies the name of CPG to Update.

  .PARAMETER RmGrowthLimit
	Enables (false) or disables (true) auto grow limit enforcement. Defaults to false.  

  .PARAMETER DisableAutoGrow
	Enables (false) or disables (true) CPG auto grow. Defaults to false..
	
  .PARAMETER RmWarningAlert
	Enables (false) or disables (true) warning limit enforcement. Defaults to false..
	  
  .PARAMETER RAIDType
	RAID type for the logical disk
	R0 RAID level 0
	R1 RAID level 1
	R5 RAID level 5
	R6 RAID level 6
	  
  .PARAMETER SetSize
	Specifies the set size in the number of chunklets.
	  
  .PARAMETER HA
	Specifies that the layout must support the failure of one port pair, one cage, or one magazine.
	PORT Support failure of a port.
	CAGE Support failure of a drive cage.
	MAG Support failure of a drive magazine.
	
  .PARAMETER Chunklets
	FIRST Lowest numbered available chunklets, where transfer rate is the fastest.
	LAST  Highest numbered available chunklets, where transfer rate is the slowest.
	
  .PARAMETER NodeList
	Specifies one or more nodes. Nodes are identified by one or more integers. Multiple nodes are separated with a single comma (1,2,3). 
	A range of nodes is separated with a hyphen (0–7). The primary path of the disks must be on the specified node number.
	
  .PARAMETER SlotList
	Specifies one or more PCI slots. Slots are identified by one or more integers. Multiple slots are separated with a single comma (1,2,3). 
	A range of slots is separated with a hyphen (0–7). The primary path of the disks must be on the specified PCI slot number(s).
	
  .PARAMETER PortList
	Specifies one or more ports. Ports are identified by one or more integers. Multiple ports are separated with a single comma (1,2,3). 
	A range of ports is separated with a hyphen (0–4). The primary path of the disks must be on the specified port number(s).
	
  .PARAMETER CageList
	Specifies one or more drive cages. Drive cages are identified by one or more integers. Multiple drive cages are separated with a single comma (1,2,3). 
	A range of drive cages is separated with a hyphen (0– 3). The specified drive cage(s) must contain disks.
	
  .PARAMETER MagList 
	Specifies one or more drive magazines. Drive magazines are identified by one or more integers. Multiple drive magazines are separated with a single comma (1,2,3). 
	A range of drive magazines is separated with a hyphen (0–7). The specified magazine(s) must contain disks.  
	
  .PARAMETER DiskPosList
	Specifies one or more disk positions within a drive magazine. Disk positions are identified by one or more integers. Multiple disk positions are separated with a single comma (1,2,3). 
	A range of disk positions is separated with a hyphen (0–3). The specified portion(s) must contain disks.
	
  .PARAMETER DiskList
	Specifies one or more physical disks. Disks are identified by one or more integers. Multiple disks are separated with a single comma (1,2,3). 
	A range of disks is separated with a hyphen (0–3). Disks must match the specified ID(s). 
	
  .PARAMETER TotalChunkletsGreaterThan
	Specifies that physical disks with total chunklets greater than the number specified be selected.  
	
  .PARAMETER TotalChunkletsLessThan
	Specifies that physical disks with total chunklets less than the number specified be selected. 
	
  .PARAMETER FreeChunkletsGreaterThan
	Specifies that physical disks with free chunklets less than the number specified be selected.  
	
  .PARAMETER FreeChunkletsLessThan
	 Specifies that physical disks with free chunklets greater than the number specified be selected. 
	 
  .PARAMETER DiskType
	Specifies that physical disks must have the specified device type.
	FC Fibre Channel
	NL Near Line
	SSD SSD
	  
  .PARAMETER Rpm
	Disks must be of the specified speed.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Update-3PARCpg_WSAPI    
    LASTEDIT: 12/01/2018
    KEYWORDS: Update-3PARCpg_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>

  [CmdletBinding()]
	Param(
	[Parameter(Mandatory = $true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Specifies the name of Existing CPG.')]
	[String]$CPGName,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies the name of CPG to Update.')]
	[String]
	$NewName,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Enables (false) or disables (true) CPG auto grow. Defaults to false.')]
	[Boolean]
	$DisableAutoGrow = $false,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Enables (false) or disables (true) auto grow limit enforcement. Defaults to false.')]
	[Boolean]
	$RmGrowthLimit = $false,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Enables (false) or disables (true) warning limit enforcement. Defaults to false.')]
	[Boolean]
	$RmWarningAlert = $false,
	
	[Parameter(Mandatory = $false,HelpMessage = 'RAIDType enumeration 1 is for R0, 2 is for R1,3 is for R5, 4 is for R6')]
    [string]
	$RAIDType = $null, 
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies the set size in the number of chunklets.')]
    [int]
	$SetSize = $null,
	
    [Parameter(Mandatory = $false,HelpMessage = 'Specifies that the layout must support the failure of one port pair, one cage, or one magazine.')]
    [string]
	$HA = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies the chunklet location preference characteristics.')]
    [string]
	$Chunklets = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more nodes. Nodes are identified by one or more integers.')]
	[String]
	$NodeList = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more nodes. Nodes are identified by one or more integers.')]
	[String]
	$SlotList = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more ports. Ports are identified by one or more integers..')]
	[String]
	$PortList = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more drive cages. Drive cages are identified by one or more integers.')]
	[String]
	$CageList = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more drive magazines. Drive magazines are identified by one or more integers..')]
	[String]
	$MagList = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more disk positions within a drive magazine. Disk positions are identified by one or more integers.')]
	[String]
	$DiskPosList = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies one or more physical disks. Disks are identified by one or more integers.')]
	[String]
	$DiskList = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies that physical disks with total chunklets greater than the number specified be selected.')]
	[int]
	$TotalChunkletsGreaterThan = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies that physical disks with total chunklets less than the number specified be selected.')]
	[int]
	$TotalChunkletsLessThan = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies that physical disks with free chunklets less than the number specified be selected.')]
	[int]
	$FreeChunkletsGreaterThan = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies that physical disks with free chunklets greater than the number specified be selected.')]
	[int]
	$FreeChunkletsLessThan = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Specifies that physical disks must have the specified device type .')]
	[int]
	$DiskType = $null,
	
	[Parameter(Mandatory = $false,HelpMessage = 'Disks must be of the specified speed 1 is for FC (Fibre Channel) 2 is for NL (Near Line) 3 is for SSD.')]
	[int]
	$Rpm = $null,
	
	[Parameter(Mandatory=$false, ValueFromPipeline=$true , HelpMessage = 'Connection Paramater')]
	$WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    # Creation of the body hash
	Write-DebugLog "Running: Creation of the body hash" $Debug
    $body = @{}

    # New Name parameter
	If ($NewName) { $body["newName"] ="$($NewName)" } 
	
	<#
	switch($DisableAutoGrow) 
	{
	 {$_ -eq $true} {$body["disableAutoGrow"] =$DisableAutoGrow ;break;}
	 {$_ -eq $false} {$body["disableAutoGrow"] =$DisableAutoGrow ;break;}
	}
	#>
	
	# Disable Auto Growth
    If($DisableAutoGrow) { $body["disableAutoGrow"] =$DisableAutoGrow } #else { $body["disableAutoGrow"] =$DisableAutoGrow}

    # rm Growth Limit
    If($RmGrowthLimit) { $body["rmGrowthLimit"] = $RmGrowthLimit } #else { $body["rmGrowthLimit"] = $RmGrowthLimit } 

	# rm Warning Alert
    If($RmWarningAlert) { $body["rmWarningAlert"] = $RmWarningAlert } #else { $body["rmWarningAlert"] = $RmWarningAlert }
	
	$LDLayoutBody = @{}
	# LDLayout
	#Specifies the RAID type for the logical disk
	if($RAIDType)
	{	
		if($RAIDType -eq "R0")
		{
			$LDLayoutBody["RAIDType"] = 1
		}
		elseif($RAIDType -eq "R1")
		{
			$LDLayoutBody["RAIDType"] = 2
		}
		elseif($RAIDType -eq "R5")
		{
			$LDLayoutBody["RAIDType"] = 3
		}
		elseif($RAIDType -eq "R6")
		{
			$LDLayoutBody["RAIDType"] = 4
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Update-3PARCpg_WSAPI   since RAIDType $RAIDType in incorrect "
			Return "FAILURE : RAIDType :- $RAIDType is an Incorrect Please Use RAIDType R0,R1,R5 and R6 only. "
		}
	}
	#Specifies the set size in the number of chunklets.
    if($SetSize)
	{	
		$LDLayoutBody["setSize"] = $SetSize				
	}
	#Specifies that the layout must support the failure of one port pair, one cage, or one magazine.
	if($HA)
	{
		if($HA -eq "PORT")
		{
			$LDLayoutBody["HA"] = 1					
		}
		elseif($HA -eq "CAGE")
		{
			$LDLayoutBody["HA"] = 2					
		}
		elseif($HA -eq "MAG")
		{
			$LDLayoutBody["HA"] = 3					
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Update-3PARCpg_WSAPI since HA $HA in incorrect "
			Return "FAILURE : HA :- $HA is an Incorrect Please Use PORT,CAGE and MAG only "
		}
	}
	#Specifies the chunklet location preference characteristics
	if ($Chunklets)
	{		
		if($Chunklets -eq "FIRST")
		{
			$LDLayoutBody["chunkletPosPref"] = 1					
		}
		elseif($Chunklets -eq "LAST")
		{
			$LDLayoutBody["chunkletPosPref"] = 2					
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Update-3PARCpg_WSAPI since Chunklets $Chunklets in incorrect "
			Return "FAILURE : Chunklets :- $Chunklets is an Incorrect Please Use Chunklets FIRST and LAST only. "
		}
	}	
		
	$LDLayoutDiskPatternsBody=@()	
	
	if ($NodeList)
	{
		$nodList=@{}
		$nodList["nodeList"] = "$($NodeList)"	
		$LDLayoutDiskPatternsBody += $nodList 			
	}
	
	if ($SlotList)
	{
		$sList=@{}
		$sList["slotList"] = "$($SlotList)"	
		$LDLayoutDiskPatternsBody += $sList 		
	}
	
	if ($PortList)
	{
		$pList=@{}
		$pList["portList"] = "$($PortList)"	
		$LDLayoutDiskPatternsBody += $pList 		
	}
	
	if ($CageList)
	{
		$cagList=@{}
		$cagList["cageList"] = "$($CageList)"	
		$LDLayoutDiskPatternsBody += $cagList 		
	}
	
	if ($MagList)
	{
		$mList=@{}
		$mList["magList"] = "$($MagList)"	
		$LDLayoutDiskPatternsBody += $mList 		
	}
	
	if ($DiskPosList)
	{
		$dpList=@{}
		$dpList["diskPosList"] = "$($DiskPosList)"	
		$LDLayoutDiskPatternsBody += $dpList 		
	}

	if ($DiskList)
	{
		$dskList=@{}
		$dskList["diskList"] = "$($DiskList)"	
		$LDLayoutDiskPatternsBody += $dskList 		
	}
	
	if ($TotalChunkletsGreaterThan)
	{
		$tcgList=@{}
		$tcgList["totalChunkletsGreaterThan"] = $TotalChunkletsGreaterThan	
		$LDLayoutDiskPatternsBody += $tcgList 		
	}
	
	if ($TotalChunkletsLessThan)
	{
		$tclList=@{}
		$tclList["totalChunkletsLessThan"] = $TotalChunkletsLessThan	
		$LDLayoutDiskPatternsBody += $tclList 		
	}
	
	if ($FreeChunkletsGreaterThan)
	{
		$fcgList=@{}
		$fcgList["freeChunkletsGreaterThan"] = $FreeChunkletsGreaterThan	
		$LDLayoutDiskPatternsBody += $fcgList 		
	}
	
	if ($FreeChunkletsLessThan)
	{
		$fclList=@{}
		$fclList["freeChunkletsLessThan"] = $FreeChunkletsLessThan	
		$LDLayoutDiskPatternsBody += $fclList 		
	}
	
	if ($DiskType)
	{		
		if($DiskType -eq "FC")
		{			
			$dtList=@{}
			$dtList["diskType"] = 1	
			$LDLayoutDiskPatternsBody += $dtList						
		}
		elseif($DiskType -eq "NL")
		{			
			$dtList=@{}
			$dtList["diskType"] = 2	
			$LDLayoutDiskPatternsBody += $dtList						
		}
		elseif($DiskType -eq "SSD")
		{			
			$dtList=@{}
			$dtList["diskType"] = 3	
			$LDLayoutDiskPatternsBody += $dtList						
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Update-3PARCpg_WSAPI   since DiskType $DiskType in incorrect "
			Return "FAILURE : DiskType :- $DiskType is an Incorrect Please Use FC (Fibre Channel), NL (Near Line) and SSD only"
		}
	}
	
	if ($Rpm)
	{
		$rpmList=@{}
		$rpmList["RPM"] = $Rpm	
		$LDLayoutDiskPatternsBody += $rpmList
	}	
		
	
	if($LDLayoutDiskPatternsBody.Count -gt 0)	{$LDLayoutBody["diskPatterns"] = $LDLayoutDiskPatternsBody	}		
	if($LDLayoutBody.Count -gt 0){$body["LDLayout"] = $LDLayoutBody }
	
	#$json = $body | ConvertTo-Json  -Compress -Depth 10
	#write-host " Body = $json"
	
	Write-DebugLog "Info:Body : $body" $Info    
    $Result = $null
	
	#Build uri
    $uri = '/cpgs/'+$CPGName	
    #Request
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{	
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: CPG:$CPGName successfully Updated" $Info
		# Results
		if($NewName)
		{
			Get-3PARCpg_WSAPI -CPGName $NewName
		}
		else
		{
			Get-3PARCpg_WSAPI -CPGName $CPGName
		}
		Write-DebugLog "End: Update-3PARCpg_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Updating CPG:$CPGName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating CPG:$CPGName " $Info
		
		return $Result.StatusDescription
	}
  }
  End 
  {
  }
}
#END Update-3PARCpg_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARCpg_WSAPI
############################################################################################################################################
Function Remove-3PARCpg_WSAPI
 {
  <#
	
  .SYNOPSIS
	Removes a Common Provision Group(CPG).
  
  .DESCRIPTION
    This cmdlet (Remove-3PARCpg_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-Cpg_WSAPI) instead.
  
	Removes a CommonProvisionGroup(CPG)
    This operation requires access to all domains, as well as Super, or Edit roles, or any role granted cpg_remove permission.    
	
  .EXAMPLE    
	Remove-3PARCpg_WSAPI -CPGName MyCPG
	Removes a Common Provision Group(CPG) "MyCPG".
	
  .PARAMETER CPGName 
    Specify name of the CPG.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-3PARCpg_WSAPI     
    LASTEDIT: 12/01/2018
    KEYWORDS: Remove-3PARCpg_WSAPI 
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
	
  #>
  [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]
  Param(
	[Parameter(Mandatory = $true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Specifies the name of CPG.')]
	[String]$CPGName,
	
	[Parameter(Mandatory=$false, ValueFromPipeline=$true , HelpMessage = 'Connection Paramater')]
	$WsapiConnection = $global:WsapiConnection
	)
	
  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {    
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-3PARCpg_WSAPI  ." $Debug
	$uri = '/cpgs/'+$CPGName

	#init the response var
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-3PARCpg_WSAPI : $CPGName (Invoke-3parWSAPI)." $Debug
	$Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: CPG:$CPGName successfully remove" $Info
		Write-DebugLog "End: Remove-3PARCpg_WSAPI" $Debug
		return ""		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing CPG:$CPGName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating CPG:$CPGName " $Info
		Write-DebugLog "End: Remove-3PARCpg_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-3PARCpg_WSAPI

############################################################################################################################################
## FUNCTION New-3PARVV_WSAPI
############################################################################################################################################
Function New-3PARVV_WSAPI 
{
  <#      
  .SYNOPSIS
	Creates a vitual volume
  
  .DESCRIPTION
    This cmdlet (New-3PARVV_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-Vv_WSAPI) instead.
  
	Creates a vitual volume
        
  .EXAMPLE    
	New-3PARVV_WSAPI -VVName xxx -CpgName xxx -SizeMiB 1
	        
  .EXAMPLE                         
	New-3PARVV_WSAPI -VVName xxx -CpgName xxx -SizeMiB 1 -Id 1010
	        
  .EXAMPLE                         
	New-3PARVV_WSAPI -VVName xxx -CpgName xxx -SizeMiB 1 -Comment "This is test vv"
	        
  .EXAMPLE                         
	New-3PARVV_WSAPI -VVName xxx -CpgName xxx -SizeMiB 1 -OneHost $true
	        
  .EXAMPLE                         
	New-3PARVV_WSAPI -VVName xxx -CpgName xxx -SizeMiB 1 -Caching $true
	        
  .EXAMPLE                         
	New-3PARVV_WSAPI -VVName xxx -CpgName xxx -SizeMiB 1 -HostDIF NO_HOST_DIF
	
  .PARAMETER VVName
	Volume Name.
	
  .PARAMETER CpgName
	Volume CPG.
	
  .PARAMETER SizeMiB
	Volume size.
	
  .PARAMETER Id
	Specifies the ID of the volume. If not specified, the next available ID is chosen.
	
  .PARAMETER Comment
	Additional informations about the volume.
	
  .PARAMETER StaleSS
	True—Stale snapshots. If there is no space for a copyon- write operation, the snapshot can go stale but the host write proceeds without an error. 
	false—No stale snapshots. If there is no space for a copy-on-write operation, the host write fails.
	
  .PARAMETER OneHost
	True—Indicates a volume is constrained to export to one host or one host cluster. 
	false—Indicates a volume exported to multiple hosts for use by a cluster-aware application, or when port presents VLUNs are used.
	
  .PARAMETER ZeroDetect
	True—Indicates that the storage system scans for zeros in the incoming write data. 
	false—Indicates that the storage system does not scan for zeros in the incoming write data.
	
  .PARAMETER System
	True— Special volume used by the system. false—Normal user volume.
	
  .PARAMETER Caching
	This is a read-only policy and cannot be set. true—Indicates that the storage system is enabled for write caching, read caching, and read ahead for the volume. 
	false—Indicates that the storage system is disabled for write caching, read caching, and read ahead for the volume.
	
  .PARAMETER Fsvc
	This is a read-only policy and cannot be set. true —Indicates that File Services uses this volume. false —Indicates that File Services does not use this volume.
	
  .PARAMETER HostDIF
	Type of host-based DIF policy, 3PAR_HOST_DIF is for 3PAR host-based DIF supported, 
	STD_HOST_DIF is for Standard SCSI host-based DIF supported and NO_HOST_DIF is for Volume does not support host-based DIF.
	
  .PARAMETER SnapCPG
	Specifies the name of the CPG from which the snapshot space will be allocated.
	
  .PARAMETER SsSpcAllocWarningPct
	Enables a snapshot space allocation warning. A warning alert is generated when the reserved snapshot space of the volume exceeds 
	the indicated percentage of the volume size.
	
  .PARAMETER SsSpcAllocLimitPct
	Sets a snapshot space allocation limit. The snapshot space of the volume is prevented from growing beyond the indicated percentage of the volume size.
	
  .PARAMETER tpvv
	Create thin volume.
	
  .PARAMETER tdvv
	Enables (true) or disables (false) TDVV creation. Defaults to false.
	With both tpvv and tdvv set to FALSE or unspecified, defaults to FPVV .
			
  .PARAMETER Reduce
	Enables (true) or disables (false) a thinly deduplicated and compressed volume.

  .PARAMETER UsrSpcAllocWarningPct
	Create fully provisionned volume.
	
  .PARAMETER UsrSpcAllocLimitPct
	Space allocation limit.
	
  .PARAMETER ExpirationHours
	Specifies the relative time (from the current time) that the volume expires. Value is a positive integer with a range of 1–43,800 hours (1825 days).
	
  .PARAMETER RetentionHours
	Specifies the amount of time relative to the current time that the volume is retained. Value is a positive integer with a range of 1– 43,800 hours (1825 days).
	
  .PARAMETER Compression   
	Enables (true) or disables (false) creating thin provisioned volumes with compression. Defaults to false (create volume without compression).
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : New-3PARVV_WSAPI    
    LASTEDIT: 02/08/2018
    KEYWORDS: New-3PARVV_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Mandatory = $true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Volume Name')]
      [String]
	  $VVName,
	  
      [Parameter(Mandatory = $true,HelpMessage = 'Volume CPG')]
      [String]
	  $CpgName,
	  
      [Parameter(Mandatory = $true,HelpMessage = 'Volume size')]
      [int]
	  $SizeMiB,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies the ID of the volume. If not specified, the next available ID is chosen')]
      [int]
	  $Id,
	  
      [Parameter(Mandatory = $false,HelpMessage = 'Additional informations about the volume')]
      [String]
	  $Comment,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'true—Stale snapshots. If there is no space for a copyon- write operation, the snapshot can go stale but the host write proceeds without an error. false—No stale snapshots. If there is no space for a copy-on-write operation, the host write fails')]
      [Boolean]
	  $StaleSS ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'true—Indicates a volume is constrained to export to one host or one host cluster. false—Indicates a volume exported to multiple hosts for use by a cluster-aware application, or when port presents VLUNs are used')]
      [Boolean]
	  $OneHost,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'true—Indicates that the storage system scans for zeros in the incoming write data. false—Indicates that the storage system does not scan for zeros in the incoming write data.')]
      [Boolean]
	  $ZeroDetect,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'true— Special volume used by the system. false—Normal user volume')]
      [Boolean]
	  $System ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'This is a read-only policy and cannot be set. true—Indicates that the storage system is enabled for write caching, read caching, and read ahead for the volume. false—Indicates that the storage system is disabled for write caching, read caching, and read ahead for the volume.')]
      [Boolean]
	  $Caching ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'This is a read-only policy and cannot be set. true —Indicates that File Services uses this volume. false —Indicates that File Services does not use this volume.')]
      [Boolean]
	  $Fsvc ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Type of host-based DIF policy, 3PAR_HOST_DIF is for 3PAR host-based DIF supported, STD_HOST_DIF is for Standard SCSI host-based DIF supported and NO_HOST_DIF is for Volume does not support host-based DIF.')]
      [string]
	  $HostDIF ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies the name of the CPG from which the snapshot space will be allocated.')]
      [String]
	  $SnapCPG,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Enables a snapshot space allocation warning. A warning alert is generated when the reserved snapshot space of the volume exceeds the indicated percentage of the volume size')]
      [int]
	  $SsSpcAllocWarningPct ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Sets a snapshot space allocation limit. The snapshot space of the volume is prevented from growing beyond the indicated percentage of the volume size.')]
      [int]
	  $SsSpcAllocLimitPct ,
	  
      [Parameter(Mandatory = $false,HelpMessage = 'Create thin volume')]
      [Boolean]
	  $TPVV = $false,
	  
      [Parameter(Mandatory = $false,HelpMessage = 'Create fully provisionned volume')]
      [Boolean]
	  $TDVV = $false,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Reduce')]
      [Boolean]
	  $Reduce = $false,
	  
      [Parameter(Mandatory = $false,HelpMessage = 'Space allocation warning')]
      [int]
	  $UsrSpcAllocWarningPct,
	  
      [Parameter(Mandatory = $false,HelpMessage = 'Space allocation limit')]
      [int]
	  $UsrSpcAllocLimitPct,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies the relative time (from the current time) that the volume expires. Value is a positive integer with a range of 1–43,800 hours (1825 days).')]
      [int]
	  $ExpirationHours,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies the amount of time relative to the current time that the volume is retained. Value is a positive integer with a range of 1– 43,800 hours (1825 days).')]
      [int]
	  $RetentionHours,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Enables (true) or disables (false) creating thin provisioned volumes with compression. Defaults to false (create volume without compression).')]
      [Boolean]
	  $Compression = $false,
	  
	  [Parameter(Mandatory=$false, ValueFromPipeline=$true , HelpMessage = 'Connection Paramater')]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}	

    # Name parameter
    $body["name"] = "$($VVName)"

    # cpg parameter
    If ($CpgName) {
          $body["cpg"] = "$($CpgName)"
    }

    # sizeMiB parameter
    If ($SizeMiB) {
          $body["sizeMiB"] = $SizeMiB
    }
	
	# id
    If ($Id) {
          $body["id"] = $Id
    }
	
	$VvPolicies = @{}
	
	If ($StaleSS) 
	{
		$VvPolicies["staleSS"] = $true
    }	
	
	If ($OneHost) 
	{
		$VvPolicies["oneHost"] = $true
    } 
	
	If ($ZeroDetect) 
	{
		$VvPolicies["zeroDetect"] = $true
    }	
	
	If ($System) 
	{
		$VvPolicies["system"] = $true
    } 
	
	If ($Caching) 
	{
		$VvPolicies["caching"] = $true
    }	
	
	If ($Fsvc) 
	{
		$VvPolicies["fsvc"] = $true
    }	
	
	If ($HostDIF) 
	{
		if($HostDIF -eq "3PAR_HOST_DIF")
		{
			$VvPolicies["hostDIF"] = 1
		}
		elseif($HostDIF -eq "STD_HOST_DIF")
		{
			$VvPolicies["hostDIF"] = 2
		}
		elseif($HostDIF -eq "NO_HOST_DIF")
		{
			$VvPolicies["hostDIF"] = 3
		}
		else
		{
			Write-DebugLog "Stop: Exiting  New-3PARVV_WSAPI since HostDIF $HostDIF in incorrect "
			Return "FAILURE : HostDIF :- $HostDIF is an Incorrect Please Use 3PAR_HOST_DIF is for 3PAR host-based DIF supported, STD_HOST_DIF is for Standard SCSI host-based DIF supported and NO_HOST_DIF is for Volume does not support host-based DIF."
		}
    } 	
	
    # comment parameter
    If ($Comment) {
      $body["comment"] = "$($Comment)"
    }
	
	If ($SnapCPG) {
      $body["snapCPG"] = "$($SnapCPG)"
    }
	
	If ($SsSpcAllocWarningPct) {
          $body["ssSpcAllocWarningPct"] = $SsSpcAllocWarningPct
    }
	
	If ($SsSpcAllocLimitPct) {
          $body["ssSpcAllocLimitPct"] = $SsSpcAllocLimitPct
    }

    # tpvv parameter
    If ($TPVV) {
      $body["tpvv"] = $true
    }

    # tdvv parameter
    If ($TDVV) {
      $body["tdvv"] = $true
    }
	
	If($Reduce) 
	{
      $body["reduce"] = $true
    }
	

    # usrSpcAllocWarningPct parameter
    If ($UsrSpcAllocWarningPct) {
          $body["usrSpcAllocWarningPct"] = $UsrSpcAllocWarningPct
    }

    # usrSpcAllocLimitPct parameter
    If ($UsrSpcAllocLimitPct) {
          $body["usrSpcAllocLimitPct"] = $UsrSpcAllocLimitPct
    } 
	
	If ($ExpirationHours) {
          $body["expirationHours"] = $ExpirationHours
    }
	
	If ($RetentionHours) {
          $body["retentionHours"] = $RetentionHours
    }
	
	If ($Compression) {
      $body["compression"] = $true
    }
	
	if($VvPolicies.Count -gt 0){$body["policies"] = $VvPolicies }
	
	#$json = $body | ConvertTo-Json  -Compress -Depth 10
	#write-host " Body = $json"
	
    #init the response var
    $Result = $null

    #Request
	Write-DebugLog "Request: Request to New-3PARVV_WSAPI : $VVName (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri '/volumes' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Volumes:$VVName created successfully" $Info
				
		# Results
		Get-3PARVV_WSAPI -VVName $VVName
		Write-DebugLog "End: New-3PARVV_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating Volumes: $VVName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating Volumes: $VVName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-3PARVV_WSAPI

############################################################################################################################################
## FUNCTION Update-3PARVV_WSAPI
############################################################################################################################################
Function Update-3PARVV_WSAPI 
{
  <#
  .SYNOPSIS
	Update a vitual volume.
  
  .DESCRIPTION
    This cmdlet (Update-3PARVV_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Update-Vv_WSAPI) instead.
  
	Update an existing vitual volume.
        
  .EXAMPLE 
	Update-3PARVV_WSAPI -VVName xxx -NewName zzz
	        
  .EXAMPLE 
	Update-3PARVV_WSAPI -VVName xxx -ExpirationHours 2
	        
  .EXAMPLE 
	Update-3PARVV_WSAPI -VVName xxx -OneHost $true
	        
  .EXAMPLE 
	Update-3PARVV_WSAPI -VVName xxx -SnapCPG xxx
	
  .PARAMETER VVName
	Name of the volume being modified.

  .PARAMETER NewName
	New Volume Name.
	
  .PARAMETER Comment
	Additional informations about the volume.
	
  .PARAMETER WWN
	Specifies changing the WWN of the virtual volume a new WWN.
	If the value of WWN is auto, the system automatically chooses the WWN based on the system serial number, the volume ID, and the wrap counter.
	
  .PARAMETER UserCPG
	User CPG Name.
	
  .PARAMETER StaleSS
	True—Stale snapshots. If there is no space for a copyon- write operation, the snapshot can go stale but the host write proceeds without an error. 
	false—No stale snapshots. If there is no space for a copy-on-write operation, the host write fails.
	
  .PARAMETER OneHost
	True—Indicates a volume is constrained to export to one host or one host cluster. 
	false—Indicates a volume exported to multiple hosts for use by a cluster-aware application, or when port presents VLUNs are used.
	
  .PARAMETER ZeroDetect
	True—Indicates that the storage system scans for zeros in the incoming write data. 
	false—Indicates that the storage system does not scan for zeros in the incoming write data.
	
  .PARAMETER System
	True— Special volume used by the system. false—Normal user volume.
	
  .PARAMETER Caching
	This is a read-only policy and cannot be set. true—Indicates that the storage system is enabled for write caching, read caching, and read ahead for the volume. 
	false—Indicates that the storage system is disabled for write caching, read caching, and read ahead for the volume.
	
  .PARAMETER Fsvc
	This is a read-only policy and cannot be set. true —Indicates that File Services uses this volume. false —Indicates that File Services does not use this volume.
	
  .PARAMETER HostDIF
	Type of host-based DIF policy, 3PAR_HOST_DIF is for 3PAR host-based DIF supported, 
	STD_HOST_DIF is for Standard SCSI host-based DIF supported and NO_HOST_DIF is for Volume does not support host-based DIF.
	
  .PARAMETER SnapCPG
	Specifies the name of the CPG from which the snapshot space will be allocated.
	
  .PARAMETER SsSpcAllocWarningPct
	Enables a snapshot space allocation warning. A warning alert is generated when the reserved snapshot space of the volume exceeds 
	the indicated percentage of the volume size.
	
  .PARAMETER SsSpcAllocLimitPct
	Sets a snapshot space allocation limit. The snapshot space of the volume is prevented from growing beyond the indicated percentage of the volume size.
	
  .PARAMETER tpvv
	Create thin volume.
	
  .PARAMETER tdvv

  .PARAMETER UsrSpcAllocWarningPct
	Create fully provisionned volume.
	
  .PARAMETER UsrSpcAllocLimitPct
	Space allocation limit.
	
  .PARAMETER ExpirationHours
	Specifies the relative time (from the current time) that the volume expires. Value is a positive integer with a range of 1–43,800 hours (1825 days).
	
  .PARAMETER RetentionHours
	Specifies the amount of time relative to the current time that the volume is retained. Value is a positive integer with a range of 1– 43,800 hours (1825 days).
	
  .PARAMETER Compression   
	Enables (true) or disables (false) creating thin provisioned volumes with compression. Defaults to false (create volume without compression).
	
  .PARAMETER RmSsSpcAllocWarning
	Enables (false) or disables (true) removing the snapshot space allocation warning. 
	If false, and warning value is a positive number, then set.

  .PARAMETER RmUsrSpcAllocWarning
	Enables (false) or disables (true) removing the user space allocation warning. If false, and warning value is a posi'

  .PARAMETER RmExpTime
	Enables (false) or disables (true) resetting the expiration time. If false, and expiration time value is a positive number, then set.

  .PARAMETER RmSsSpcAllocLimit
	Enables (false) or disables (true) removing the snapshot space allocation limit. If false, and limit value is 0, setting ignored. If false, and limit value is a positive number, then set
 
  .PARAMETER RmUsrSpcAllocLimit
	Enables (false) or disables (true)false) the allocation limit. If false, and limit value is a positive number, then set
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Update-3PARVV_WSAPI    
    LASTEDIT: 16/01/2018
    KEYWORDS: Update-3PARVV_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0      
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Mandatory = $true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Volume Name')]
      [String]
	  $VVName,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Volume size')]
      [String]
	  $NewName,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Additional informations about the volume')]
      [String]
	  $Comment,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies changing the WWN of the virtual volume a new WWN.')]
      [String]
	  $WWN,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies the relative time (from the current time) that the volume expires. Value is a positive integer with a range of 1–43,800 hours (1825 days).')]
      [int]
	  $ExpirationHours,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies the amount of time relative to the current time that the volume is retained. Value is a positive integer with a range of 1– 43,800 hours (1825 days).')]
      [int]
	  $RetentionHours,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'true—Stale snapshots. If there is no space for a copyon- write operation, the snapshot can go stale but the host write proceeds without an error. false—No stale snapshots. If there is no space for a copy-on-write operation, the host write fails')]
      [Nullable[boolean]]
	  $StaleSS ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'true—Indicates a volume is constrained to export to one host or one host cluster. false—Indicates a volume exported to multiple hosts for use by a cluster-aware application, or when port presents VLUNs are used')]
      [Nullable[boolean]]
	  $OneHost,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'true—Indicates that the storage system scans for zeros in the incoming write data. false—Indicates that the storage system does not scan for zeros in the incoming write data.')]
      [Nullable[boolean]]
	  $ZeroDetect,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'true— Special volume used by the system. false—Normal user volume')]
      [Nullable[boolean]]
	  $System ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'This is a read-only policy and cannot be set. true—Indicates that the storage system is enabled for write caching, read caching, and read ahead for the volume. false—Indicates that the storage system is disabled for write caching, read caching, and read ahead for the volume.')]
      [Nullable[boolean]]
	  $Caching ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'This is a read-only policy and cannot be set. true —Indicates that File Services uses this volume. false —Indicates that File Services does not use this volume.')]
      [Nullable[boolean]]
	  $Fsvc ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Type of host-based DIF policy, 3PAR_HOST_DIF is for 3PAR host-based DIF supported, STD_HOST_DIF is for Standard SCSI host-based DIF supported and NO_HOST_DIF is for Volume does not support host-based DIF.')]
      [string]$HostDIF ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies the name of the CPG from which the snapshot space will be allocated.')]
      [String]
	  $SnapCPG,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Enables a snapshot space allocation warning. A warning alert is generated when the reserved snapshot space of the volume exceeds the indicated percentage of the volume size')]
      [int]
	  $SsSpcAllocWarningPct ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Sets a snapshot space allocation limit. The snapshot space of the volume is prevented from growing beyond the indicated percentage of the volume size.')]
      [int]
	  $SsSpcAllocLimitPct ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'User CPG name')]
      [String]$UserCPG,
	  
      [Parameter(Mandatory = $false,HelpMessage = 'Space allocation warning')]
      [int]
	  $UsrSpcAllocWarningPct,
	  
      [Parameter(Mandatory = $false,HelpMessage = 'Space allocation limit')]
      [int]
	  $UsrSpcAllocLimitPct,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Enables (false) or disables (true) removing the snapshot space allocation warning. If false, and warning value is a positive number, then set.')]
      [Boolean]
	  $RmSsSpcAllocWarning ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Enables (false) or disables (true) removing the user space allocation warning. If false, and warning value is a posi')]
      [Boolean]
	  $RmUsrSpcAllocWarning ,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Enables (false) or disables (true) resetting the expiration time. If false, and expiration time value is a positive number, then set.')]
      [Boolean]
	  $RmExpTime,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Enables (false) or disables (true) removing the snapshot space allocation limit. If false, and limit value is 0, setting ignored. If false, and limit value is a positive number, then set')]
      [Boolean]
	  $RmSsSpcAllocLimit,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Enables (false) or disables (true)false) the allocation limit. If false, and limit value is a positive number, then set')]
      [Boolean]
	  $RmUsrSpcAllocLimit,
	  
	  [Parameter(Mandatory=$false, ValueFromPipeline=$true , HelpMessage = 'Connection Paramater')]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection
  }

  Process 
  {
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}
    
	# New Name parameter
    If ($NewName) {
          $body["newName"] = "$($NewName)"
    }
	
	# comment parameter
    If ($Comment) {
      $body["comment"] = "$($Comment)"
    }
	
	If ($WWN) {
      $body["WWN"] = "$($WWN)"
    }
	
	If ($ExpirationHours) {
          $body["expirationHours"] = $ExpirationHours
    }
	
	If ($RetentionHours) {
          $body["retentionHours"] = $RetentionHours
    }
	
	$VvPolicies = @{}
	
	If ($StaleSS) 
	{
		$VvPolicies["staleSS"] = $true
    }
	If ($StaleSS -eq $false) 
	{
		$VvPolicies["staleSS"] = $false
    }	
	
	If ($OneHost) 
	{
		$VvPolicies["oneHost"] = $true
    }
	If ($OneHost -eq $false) 
	{
		$VvPolicies["oneHost"] = $false
    }
	
	If ($ZeroDetect) 
	{
		$VvPolicies["zeroDetect"] = $true
    }	
	If ($ZeroDetect -eq $false) 
	{
		$VvPolicies["zeroDetect"] = $false
    }
	
	If ($System) 
	{
		$VvPolicies["system"] = $true
    } 
	If ($System -eq $false) 
	{
		$VvPolicies["system"] = $false
    }
	
	If ($Caching) 
	{
		$VvPolicies["caching"] = $true
    }	
	If ($Caching -eq $false) 
	{
		$VvPolicies["caching"] = $false
    }
	
	If ($Fsvc) 
	{
		$VvPolicies["fsvc"] = $true
    }
	If ($Fsvc -eq $false) 
	{
		$VvPolicies["fsvc"] = $false
    }
	
	If ($HostDIF) 
	{
		if($HostDIF -eq "3PAR_HOST_DIF")
		{
			$VvPolicies["hostDIF"] = 1
		}
		elseif($HostDIF -eq "STD_HOST_DIF")
		{
			$VvPolicies["hostDIF"] = 2
		}
		elseif($HostDIF -eq "NO_HOST_DIF")
		{
			$VvPolicies["hostDIF"] = 3
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Update-3PARVV_WSAPI since HostDIF $HostDIF in incorrect "
			Return "FAILURE : HostDIF :- $HostDIF is an Incorrect Please Use 3PAR_HOST_DIF is for 3PAR host-based DIF supported, STD_HOST_DIF is for Standard SCSI host-based DIF supported and NO_HOST_DIF is for Volume does not support host-based DIF."
		}
    } 	   
	
	If ($SnapCPG) {
      $body["snapCPG"] = "$($SnapCPG)"
    }
	
	If ($SsSpcAllocWarningPct) {
          $body["ssSpcAllocWarningPct"] = $SsSpcAllocWarningPct
    }
	
	If ($SsSpcAllocLimitPct) {
          $body["ssSpcAllocLimitPct"] = $SsSpcAllocLimitPct
    }	
	
    # User CPG parameter
    If ($UserCPG) {
          $body["userCPG"] = "$($UserCPG)"
    }
	    

    # usrSpcAllocWarningPct parameter
    If ($UsrSpcAllocWarningPct) {
          $body["usrSpcAllocWarningPct"] = $UsrSpcAllocWarningPct
    }

    # usrSpcAllocLimitPct parameter
    If ($UsrSpcAllocLimitPct) {
          $body["usrSpcAllocLimitPct"] = $UsrSpcAllocLimitPct
    }	
	
	If ($RmSsSpcAllocWarning) {
      $body["rmSsSpcAllocWarning"] = $true
    }
	
	If ($RmUsrSpcAllocWarning) {
      $body["rmUsrSpcAllocWarning"] = $true
    } 
	
	If ($RmExpTime) {
      $body["rmExpTime"] = $true
    } 
	
	If ($RmSsSpcAllocLimit) {
      $body["rmSsSpcAllocLimit"] = $true
    }
	
	If ($RmUsrSpcAllocLimit) {
      $body["rmUsrSpcAllocLimit"] = $true
    }
	
	if($VvPolicies.Count -gt 0){$body["policies"] = $VvPolicies }
	
	#$json = $body | ConvertTo-Json  -Compress -Depth 10
	#write-host " Body = $json"
	
    #init the response var
    $Result = $null
	
	$uri = '/volumes/'+$VVName 
	
    #Request
	Write-DebugLog "Request: Request to Update-3PARVV_WSAPI : $VVName (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Volumes:$VVName successfully Updated" $Info
				
		# Results
		if($NewName)
		{
			Get-3PARVV_WSAPI -VVName $NewName
		}
		else
		{
			Get-3PARVV_WSAPI -VVName $VVName
		}
		Write-DebugLog "End: Update-3PARVV_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Updating Volumes: $VVName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Updating Volumes: $VVName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Update-3PARVV_WSAPI

############################################################################################################################################
## FUNCTION Get-3parVVSpaceDistribution_WSAPI
############################################################################################################################################
Function Get-3parVVSpaceDistribution_WSAPI 
{
  <#
  .SYNOPSIS
	Display volume space distribution for all and for a specific virtual volumes among CPGs.
  
  .DESCRIPTION
    This cmdlet (Get-3parVVSpaceDistribution_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-VvSpaceDistribution_WSAPI) instead.
  
	Display volume space distribution for all and for a specific virtual volumes among CPGs.
        
  .EXAMPLE    
	Get-3parVVSpaceDistribution_WSAPI
	Display volume space distribution for all virtual volumes among CPGs.
	
  .EXAMPLE    
	Get-3parVVSpaceDistribution_WSAPI	-VVName XYZ
	Display space distribution for a specific virtual volume or a volume set.
	
  .PARAMETER VVName 
	Either a single virtual volume name or a volume set name (start with set: to use a 	volume set name o, for example set:vvset1). 
	If you use a volume set name, the system displays the space distribution for all volumes in that volume set.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3parVVSpaceDistribution_WSAPI    
    LASTEDIT: 16/01/2018
    KEYWORDS: Get-3parVVSpaceDistribution_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  
  #>

  [CmdletBinding()]
  Param(
	[Parameter(Mandatory = $false,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Volume Name')]
    [String]$VVName,
	
	[Parameter(Mandatory=$false, ValueFromPipeline=$true , HelpMessage = 'Connection Paramater')]
	$WsapiConnection = $global:WsapiConnection
  )
  Begin {  
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection	
  }

  Process 
  { 	
	Write-DebugLog "Request: Request fo vv Space Distributation (Invoke-3parWSAPI)." $Debug
    #Request    
	$Result = $null
	$dataPS = $null			
	
	#Build uri
	
	#Request
	if($VVName)
	{
		#Build uri
		$uri = '/volumespacedistribution/'+$VVName
		#Request
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection	
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/volumespacedistribution' -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members 
		}			
	}
	
	If($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Get-3parVVSpaceDistribution_WSAPI successfully Executed." $Info
		
		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3parVVSpaceDistribution_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3parVVSpaceDistribution_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
    
  }
End {  }
}#END Get-3parVVSpaceDistribution_WSAPI

############################################################################################################################################
## FUNCTION Resize-Grow3PARVV_WSAPI
############################################################################################################################################
Function Resize-Grow3PARVV_WSAPI 
{
  <#
  .SYNOPSIS
	Increase the size of a virtual volume.
  
  .DESCRIPTION
    This cmdlet (Resize-Grow3PARVV_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Resize-Vv_WSAPI) instead.
  
	Increase the size of a virtual volume.
        
  .EXAMPLE    
	Resize-Grow3PARVV_WSAPI -VVName xxx -SizeMiB xx
	Increase the size of a virtual volume xxx to xx.
	
  .PARAMETER VVName 
	Name of the volume to be grown.
	
  .PARAMETER SizeMiB
    Specifies the size (in MiB) to add to the volume user space. Rounded up to the next multiple of chunklet size.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Resize-Grow3PARVV_WSAPI    
    LASTEDIT: 17/01/2018
    KEYWORDS: Resize-Grow3PARVV_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Mandatory = $true,HelpMessage = 'Volume Name')]
      [String]$VVName,
	  
	  [Parameter(Mandatory = $true,HelpMessage = 'Specifies the size in MiB to be added to the volume user space. The size is rounded up to the next multiple of chunklet size')]
      [int]$SizeMiB,
	  
	  [Parameter(Mandatory=$false, ValueFromPipeline=$true , HelpMessage = 'Connection Paramater')]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}
	$body["action"] = 3 # GROW_VOLUME 3 Increase the size of a virtual volume. refer Volume custom action enumeration
		
	If ($SizeMiB) 
	{
          $body["sizeMiB"] = $SizeMiB
    }
	
	#$json = $body | ConvertTo-Json  -Compress -Depth 10
	#write-host " Body = $json"
	
    #init the response var
    $Result = $null	
	$uri = '/volumes/'+$VVName 
	
    #Request
	Write-DebugLog "Request: Request to Resize-Grow3PARVV_WSAPI : $VVName (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Volumes:$VVName successfully Updated" $Info
				
		# Results		
		Get-3PARVV_WSAPI -VVName $VVName		
		Write-DebugLog "End: Resize-Grow3PARVV_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Growing Volumes: $VVName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Growing Volumes: $VVName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Resize-Grow3PARVV_WSAPI

############################################################################################################################################
## FUNCTION Compress-3PARVV_WSAPI
############################################################################################################################################
Function Compress-3PARVV_WSAPI 
{
  <#
  .SYNOPSIS
	Tune a volume.
  
  .DESCRIPTION
    This cmdlet (Compress-3PARVV_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Compress-Vv_WSAPI) instead.
  
	Tune a volume.
        
  .EXAMPLE    
	Compress-3PARVV_WSAPI -VVName xxx -TuneOperation USR_CPG -KeepVV xxx
        
  .EXAMPLE	
	Compress-3PARVV_WSAPI -VVName xxx -TuneOperation USR_CPG -UserCPG xxx -KeepVV xxx
	        
  .EXAMPLE
	Compress-3PARVV_WSAPI -VVName xxx -TuneOperation SNP_CPG -SnapCPG xxx -KeepVV xxx
        
  .EXAMPLE	
	Compress-3PARVV_WSAPI -VVName xxx -TuneOperation USR_CPG -UserCPG xxx -ConversionOperation xxx -KeepVV xxx
        
  .EXAMPLE	
	Compress-3PARVV_WSAPI -VVName xxx -TuneOperation USR_CPG -UserCPG xxx -Compression $true -KeepVV xxx
	
  .PARAMETER VVName 
	Name of the volume to be tune.
	
  .PARAMETER TuneOperation
	Tune operation
	USR_CPG Change the user CPG of the volume.
	SNP_CPG Change the snap CPG of the volume.

  .PARAMETER UserCPG
	Specifies the new user CPG to which the volume will be tuned.
	
  .PARAMETER SnapCPG
	Specifies the snap CPG to which the volume will be tuned.
	
  .PARAMETER ConversionOperation
	TPVV  :Convert the volume to a TPVV.
	FPVV : Convert the volume to an FPVV.
	TDVV : Convert the volume to a TDVV.
	CONVERT_TO_DECO : Convert the volume to deduplicated and compressed.
	
  .PARAMETER KeepVV
	Name of the new volume where the original logical disks are saved.
	
  .PARAMETER Compression
	Enables (true) or disables (false) compression. You cannot compress a fully provisioned volume.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Compress-3PARVV_WSAPI   
    LASTEDIT: 17/01/2018
    KEYWORDS: Compress-3PARVV_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0      
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Mandatory = $true,HelpMessage = 'Volume Name')]
      [String]$VVName,
	  
	  [Parameter(Mandatory = $true,HelpMessage = 'USR_CPG is to Change the user CPG of the volume, SNP_CPG is to Change the snap CPG of the volume')]
      [string]$TuneOperation,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies the new user CPG to which the volume will be tuned.')]
      [String]$UserCPG,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Specifies the snap CPG to which the volume will be tuned..')]
      [String]$SnapCPG,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'TPVV is to Convert the volume to a TPVV , FPVV is to Convert the volume to an FPVV, TDVV is to Convert the volume to a TDVV, CONVERT_TO_DECO Convert the volume to deduplicated and compressed..')]
      [string]$ConversionOperation,
	  
	  [Parameter(Mandatory = $true,HelpMessage = 'Name of the new volume where the original logical disks are saved.')]
      [String]$KeepVV,
	  
	  [Parameter(Mandatory = $false,HelpMessage = 'Enables (true) or disables (false) compression')]
      [Boolean]$Compression,
	  
	  [Parameter(Mandatory=$false, ValueFromPipeline=$true , HelpMessage = 'Connection Paramater')]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{} 	
	$body["action"] = 6	
	
	If ($TuneOperation) 
	{	
		if($TuneOperation -eq "USR_CPG")
		{
			$body["tuneOperation"] = 1			
		}
		elseif($TuneOperation -eq "SNP_CPG")
		{
			$body["tuneOperation"] = 2			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Compress-3PARVV_WSAPI  since -TuneOperation $TuneOperation in incorrect "
			Return "FAILURE : -TuneOperation :- $TuneOperation is an Incorrect used USR_CPG and SNP_CPG only. " 
		}          
    }
	
	If ($UserCPG) 
	{
		$body["userCPG"] = "$($UserCPG)"
    }
	else
	{
		If ($TuneOperation -eq "USR_CPG") 
		{
			return "Stop Executing Compress-3PARVV_WSAPI, UserCPG is Required with TuneOperation 1"
		}
	}
	If ($SnapCPG) 
	{
		$body["snapCPG"] = "$($SnapCPG)"
    }
	else
	{
		If ($TuneOperation -eq "SNP_CPG") 
		{
			return "Stop Executing Compress-3PARVV_WSAPI, SnapCPG is Required with TuneOperation 1"
		}
	}
	If ($ConversionOperation) 
	{	
		if($ConversionOperation -eq "TPVV")
		{
			$body["conversionOperation"] = 1			
		}
		elseif($ConversionOperation -eq "FPVV")
		{
			$body["conversionOperation"] = 2			
		}
		elseif($ConversionOperation -eq "TDVV")
		{
			$body["conversionOperation"] = 3			
		}
		elseif($ConversionOperation -eq "CONVERT_TO_DECO")
		{
			$body["conversionOperation"] = 4			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Compress-3PARVV_WSAPI   since -ConversionOperation $ConversionOperation in incorrect "
			Return "FAILURE : -ConversionOperation :- $ConversionOperation is an Incorrect used TPVV,FPVV,TDVV or CONVERT_TO_DECO only. "
		}          
    }
	If ($KeepVV) 
	{
		$body["keepVV"] = "$($KeepVV)"
    }
	If ($Compression) 
	{
		$body["compression"] = $false
    } 
	
	#$json = $body | ConvertTo-Json  -Compress -Depth 10
	#write-host " Body = $json"
	
    #init the response var
    $Result = $null	
	$uri = '/volumes/'+$VVName 
	
    #Request
	Write-DebugLog "Request: Request to Compress-3PARVV_WSAPI : $VVName (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Volumes:$VVName successfully Tune" $Info
				
		# Results		
		Get-3PARVV_WSAPI -VVName $VVName		
		Write-DebugLog "End: Compress-3PARVV_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Tuning Volumes: $VVName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Tuning Volumes: $VVName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Compress-3PARVV_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARVV_WSAPI
############################################################################################################################################
Function Get-3PARVV_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of virtual volumes.
  
  .DESCRIPTION
    This cmdlet (Get-3PARVV_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-Vv_WSAPI) instead.
  
	Get Single or list of virtual volumes.
        
  .EXAMPLE
	Get-3PARVV_WSAPI
	Get the list of virtual volumes
	
  .EXAMPLE
	Get-3PARVV_WSAPI -VVName MyVV
	Get the detail of given VV	
	
  .EXAMPLE
	Get-3PARVV_WSAPI -WWN XYZ
	Querying volumes with single WWN
	
  .EXAMPLE
	Get-3PARVV_WSAPI -WWN "XYZ,XYZ1,XYZ2,XYZ3"
	Querying volumes with multiple WWNs
	
  .EXAMPLE
	Get-3PARVV_WSAPI -WWN "XYZ,XYZ1,XYZ2,XYZ3" -UserCPG ABC 
	Querying volumes with multiple filters
	
  .EXAMPLE
	Get-3PARVV_WSAPI -WWN "XYZ" -SnapCPG ABC 
	Querying volumes with multiple filters
	
  .EXAMPLE
	Get-3PARVV_WSAPI -WWN "XYZ" -CopyOf MyVV 
	Querying volumes with multiple filters
	
  .EXAMPLE
	Get-3PARVV_WSAPI -ProvisioningType FULL  
	Querying volumes with Provisioning Type FULL
	
  .EXAMPLE
	Get-3PARVV_WSAPI -ProvisioningType TPVV  
	Querying volumes with Provisioning Type TPVV
	
  .PARAMETER VVName
	Specify name of the volume.
	
  .PARAMETER WWN
	Querying volumes with Single or multiple WWNs
	
  .PARAMETER UserCPG
	User CPG Name
	
  .PARAMETER SnapCPG
	Snp CPG Name 
	
  .PARAMETER CopyOf
	Querying volume copies it required name of the vv to copy
	
  .PARAMETER ProvisioningType
	Querying volume with Provisioning Type
	FULL : 	• FPVV, with no snapshot space or with statically allocated snapshot space.
			• A commonly provisioned VV with fully provisioned user space and snapshot space associated with the snapCPG property.
	TPVV : 	• TPVV, with base volume space allocated from the user space associated with the userCPG property.
			• Old-style, thinly provisioned VV (created on a 2.2.4 release or earlier).
			Both the base VV and snapshot data are allocated from the snapshot space associated with userCPG.
	SNP : 	The VV is a snapshot (Type vcopy) with space provisioned from the base volume snapshot space.
	PEER : 	Remote volume admitted into the local storage system.
	UNKNOWN : Unknown. 
	TDVV : 	The volume is a deduplicated volume.
	DDS : 	A system maintained deduplication storage volume shared by TDVV volumes in a CPG.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-3PARVV_WSAPI    
    LASTEDIT: 18/01/2018
    KEYWORDS: Get-3PARVV_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VVName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $WWN,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $UserCPG,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $SnapCPG,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $CopyOf,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	  [System.String]
	  $ProvisioningType,

	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-3PARVV_WSAPI VVName : $VVName (Invoke-3parWSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null	
	$Query="?query=""  """	
	
	# Results
	if($VVName)
	{
		#Build uri
		$uri = '/volumes/'+$VVName
		#Request
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}		
		If($Result.StatusCode -eq 200)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-3PARVV_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARVV_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARVV_WSAPI. " $Info
			
			return $Result.StatusDescription
		}
	}	
	if($WWN)
	{		
		$count = 1
		$lista = $WWN.split(",")
		foreach($sub in $lista)
		{			
			$Query = $Query.Insert($Query.Length-3," wwn EQ $sub")			
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
	if($UserCPG)
	{
		if($WWN)
		{
			$Query = $Query.Insert($Query.Length-3," OR userCPG EQ $UserCPG")
		}
		else
		{
			$Query = $Query.Insert($Query.Length-3," userCPG EQ $UserCPG")
		}
	}
	if($SnapCPG)
	{
		if($WWN -or $UserCPG)
		{
			$Query = $Query.Insert($Query.Length-3," OR snapCPG EQ $SnapCPG")
		}
		else
		{
			$Query = $Query.Insert($Query.Length-3," snapCPG EQ $SnapCPG")
		}
	}
	if($CopyOf)
	{
		if($WWN -Or $UserCPG -Or $SnapCPG)
		{
			$Query = $Query.Insert($Query.Length-3," OR copyOf EQ $CopyOf")
		}
		else
		{
			$Query = $Query.Insert($Query.Length-3," copyOf EQ $CopyOf")
		}
	}
	
	if($ProvisioningType)
	{
		$PEnum
		
		$a = "FULL","TPVV","SNP","PEER","UNKNOWN","TDVV","DDS"
		$l=$ProvisioningType.ToUpper()
		if($a -eq $l)
		{
			if($ProvisioningType -eq "FULL")
			{
				$PEnum = 1
			}
			if($ProvisioningType -eq "TPVV")
			{
				$PEnum = 2
			}
			if($ProvisioningType -eq "SNP")
			{
				$PEnum = 3
			}
			if($ProvisioningType -eq "PEER")
			{
				$PEnum = 4
			}
			if($ProvisioningType -eq "UNKNOWN")
			{
				$PEnum = 5
			}
			if($ProvisioningType -eq "TDVV")
			{
				$PEnum = 6
			}
			if($ProvisioningType -eq "DDS")
			{
				$PEnum = 7
			}
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Get-3PARVV_WSAPI Since -ProvisioningType $ProvisioningType in incorrect "
			Return "FAILURE : -ProvisioningType :- $ProvisioningType is an Incorrect Provisioning Type [FULL | TPVV | SNP | PEER | UNKNOWN | TDVV | DDS]  can be used only . "
		}			
		
		if($WWN -Or $UserCPG -Or $SnapCPG -Or $CopyOf)
		{
			$Query = $Query.Insert($Query.Length-3," OR provisioningType EQ $PEnum")
		}
		else
		{
			$Query = $Query.Insert($Query.Length-3," provisioningType EQ $PEnum")
		}
	}
	
	if($WWN -Or $UserCPG -Or $SnapCPG -Or $CopyOf -Or $ProvisioningType)
	{
		#Build uri
		$uri = '/volumes/'+$Query		
		#Request
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{			
			$dataPS = ($Result.content | ConvertFrom-Json).members			
		}
	}
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/volumes' -type 'GET' -WsapiConnection $WsapiConnection
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
			Write-DebugLog "SUCCESS: Get-3PARVV_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARVV_WSAPI. Expected Result Not Found with Given Filter Option : UserCPG/$UserCPG | WWN/$WWN | SnapCPG/$SnapCPG | CopyOf/$CopyOf | ProvisioningType/$ProvisioningType." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARVV_WSAPI. Expected Result Not Found with Given Filter Option : UserCPG/$UserCPG | WWN/$WWN | SnapCPG/$SnapCPG | CopyOf/$CopyOf | ProvisioningType/$ProvisioningType." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARVV_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARVV_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-3PARVV_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARVV_WSAPI
############################################################################################################################################
Function Remove-3PARVV_WSAPI
 {
  <#
  .SYNOPSIS
	Delete virtual volumes
  
  .DESCRIPTION
    This cmdlet (Remove-3PARVV_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-Vv_WSAPI) instead.
  
	Delete virtual volumes
        
  .EXAMPLE    
	Remove-3PARVV_WSAPI -VVName MyVV
	
  .PARAMETER VVName 
	Specify name of the volume to be removed

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-3PARVV_WSAPI     
    LASTEDIT: 19/01/2018
    KEYWORDS: Remove-3PARVV_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0	
  #>
  [CmdletBinding(SupportsShouldProcess = $True,ConfirmImpact = 'High')]
  Param(
	[Parameter(Mandatory = $true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Specifies the name of Volume.')]
	[String]$VVName,
	
	[Parameter(Mandatory=$false, ValueFromPipeline=$true , HelpMessage = 'Connection Paramater')]
	$WsapiConnection = $global:WsapiConnection
	)
  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {    
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-3PARVV_WSAPI." $Debug
	$uri = '/volumes/'+$VVName

	#init the response var
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-3PARVV_WSAPI : $VVName (Invoke-3parWSAPI)." $Debug
	$Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Volumes:$VVName successfully remove" $Info
		Write-DebugLog "End: Remove-3PARVV_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing Volume:$VVName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating Volume:$VVName " $Info
		Write-DebugLog "End: Remove-3PARVV_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-3PARVV_WSAPI

############################################################################################################################################
## FUNCTION New-3PARHost_WSAPI
############################################################################################################################################
Function New-3PARHost_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creates a new host.
	
  .DESCRIPTION
    This cmdlet (New-3PARHost_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-Host_WSAPI) instead.
  
	Creates a new host.
    Any user with Super or Edit role, or any role granted host_create permission, can perform this operation. Requires access to all domains.    
	
  .EXAMPLE
	New-3PARHost_WSAPI -HostName MyHost
    Creates a new host.
	
  .EXAMPLE
	New-3PARHost_WSAPI -HostName MyHost -Domain MyDoamin	
	Create the host MyHost in the specified domain MyDoamin.
	
  .EXAMPLE
	New-3PARHost_WSAPI -HostName MyHost -Domain MyDoamin -FCWWN XYZ
	Create the host MyHost in the specified domain MyDoamin with WWN XYZ
	
  .EXAMPLE
	New-3PARHost_WSAPI -HostName MyHost -Domain MyDoamin -FCWWN XYZ -Persona GENERIC_ALUA
	
  .EXAMPLE	
	New-3PARHost_WSAPI -HostName MyHost -Domain MyDoamin -Persona GENERIC
	
  .EXAMPLE	
	New-3PARHost_WSAPI -HostName MyHost -Location 1
		
  .EXAMPLE
	New-3PARHost_WSAPI -HostName MyHost -IPAddr 1.0.1.0
		
  .EXAMPLE	
	New-3PARHost_WSAPI -HostName $hostName -Port 1:0:1
	
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
    NAME    : New-3PARHost_WSAPI    
    LASTEDIT: 24/01/2018
    KEYWORDS: New-3PARHost_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
			Write-DebugLog "Stop: Exiting  New-3PARHost_WSAPI since Persona $Persona in incorrect "
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
    $Result = Invoke-3parWSAPI -uri '/hosts' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Host:$HostName created successfully" $Info
		
		Get-3PARHost_WSAPI -HostName $HostName
		Write-DebugLog "End: New-3PARHost_WSAPI" $Debug
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
#ENG New-3PARHost_WSAPI

############################################################################################################################################
## FUNCTION Add-Rem3PARHostWWN_WSAPI
############################################################################################################################################
Function Add-Rem3PARHostWWN_WSAPI 
{
  <#
  
  .SYNOPSIS
	Add or remove a host WWN from target-driven zoning
	
  .DESCRIPTION
    This cmdlet (Add-Rem3PARHostWWN_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Add-RemoveHostWWN_WSAPI) instead.
  
	Add a host WWN from target-driven zoning.
    Any user with Super or Edit role, or any role granted host_create permission, can perform this operation. Requires access to all domains.    
	
  .EXAMPLE
	Add-Rem3PARHostWWN_WSAPI -HostName MyHost -FCWWNs "$wwn" -AddWwnToHost
	
  .EXAMPLE	
	Add-Rem3PARHostWWN_WSAPI -HostName MyHost -FCWWNs "$wwn" -RemoveWwnFromHost
	
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
    NAME    : Add-Rem3PARHostWWN_WSAPI    
    LASTEDIT: 24/01/2018
    KEYWORDS: Add-Rem3PARHostWWN_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
    $Result = Invoke-3parWSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Executed Successfully with Host : $HostName" $Info
		
		Get-3PARHost_WSAPI -HostName $HostName
		Write-DebugLog "End: Add-Rem3PARHostWWN_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : Command Execution failed with Host : $HostName." -foreground red
		write-host ""
		Write-DebugLog "Command Execution failed with Host : $HostName." $Info
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG Add-Rem3PARHostWWN_WSAPI

############################################################################################################################################
## FUNCTION Update-3PARHost_WSAPI
############################################################################################################################################
Function Update-3PARHost_WSAPI 
{
  <#      
  .SYNOPSIS	
	Update Host.
	
  .DESCRIPTION	
    This cmdlet (Update-3PARHost_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Update-Host_WSAPI) instead.
  
    Update Host.
	
  .EXAMPLE	
	Update-3PARHost_WSAPI -HostName MyHost

  .EXAMPLE	
	Update-3PARHost_WSAPI -HostName MyHost -ChapName TestHostAS	
	
  .EXAMPLE	
	Update-3PARHost_WSAPI -HostName MyHost -ChapOperationMode 1 
	
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
    NAME    : Update-3PARHost_WSAPI    
    LASTEDIT: 30/07/2018
    KEYWORDS: Update-3PARHost_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Update-3PARHost_WSAPI(Invoke-3parWSAPI)." $Debug	
	
	#Request
	$uri = '/hosts/'+$HostName
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
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
			Get-3PARHost_WSAPI -HostName $NewName
		}
		else
		{
			Get-3PARHost_WSAPI -HostName $HostName
		}
		Write-DebugLog "End: Update-3PARHost_WSAPI" $Debug
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

}#END Update-3PARHost_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARHost_WSAPI
############################################################################################################################################
Function Remove-3PARHost_WSAPI
 {
  <#
  .SYNOPSIS
	Remove a Host.
  
  .DESCRIPTION
    This cmdlet (Remove-3PARHost_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-Host_WSAPI) instead.
  
	Remove a Host.
	Any user with Super or Edit role, or any role granted host_remove permission, can perform this operation. Requires access to all domains.
        
  .EXAMPLE    
	Remove-3PARHost_WSAPI -HostName MyHost
	
  .PARAMETER HostName 
	Specify the name of Host to be removed.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-3PARHost_WSAPI     
    LASTEDIT: 24/01/2018
    KEYWORDS: Remove-3PARHost_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {    
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-3PARHost_WSAPI." $Debug
	$uri = '/hosts/'+$HostName
	
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-3PARHost_WSAPI : $HostName (Invoke-3parWSAPI)." $Debug
	$Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Host:$HostName successfully remove" $Info
		Write-DebugLog "End: Remove-3PARHost_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing Host:$HostName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating Host:$HostName " $Info
		Write-DebugLog "End: Remove-3PARHost_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-3PARHost_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARHost_WSAPI
############################################################################################################################################
Function Get-3PARHost_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of Hotes.
  
  .DESCRIPTION
    This cmdlet (Get-3PARHost_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-Host_WSAPI) instead.
  
	Get Single or list of Hotes.
        
  .EXAMPLE
	Get-3PARHost_WSAPI
	Display a list of host.
	
  .EXAMPLE
	Get-3PARHost_WSAPI -HostName MyHost
	Get the information of given host.
	
  .PARAMETER HostName
	Specify name of the Host.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-3PARHost_WSAPI    
    LASTEDIT: 24/01/2018
    KEYWORDS: Get-3PARHost_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-3PARHost_WSAPI HostName : $HostName (Invoke-3parWSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null		
	
	# Results
	if($HostName)
	{
		#Build uri
		$uri = '/hosts/'+$HostName
		#Request
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}	
	}	
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/hosts' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Get-3PARHost_WSAPI successfully Executed." $Info
		
		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARHost_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARHost_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-3PARHost_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARHostWithFilter_WSAPI
############################################################################################################################################
Function Get-3PARHostWithFilter_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of Hotes information with WWN filtering.
  
  .DESCRIPTION
    This cmdlet (Get-3PARHostWithFilter_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-HostWithFilter_WSAPI) instead.
  
	Get Single or list of Hotes information with WWN filtering. specify the FCPaths WWN or the iSCSIPaths name.
	
  .EXAMPLE
	Get-3PARHostWithFilter_WSAPI -WWN 123 
	Get a host detail with single wwn name
	
  .EXAMPLE
	Get-3PARHostWithFilter_WSAPI -WWN "123,ABC,000" 
	Get a host detail with multiple wwn name
	
  .EXAMPLE
	Get-3PARHostWithFilter_WSAPI -ISCSI 123 
	Get a host detail with single ISCSI name
	
  .EXAMPLE
	Get-3PARHostWithFilter_WSAPI -ISCSI "123,ABC,000" 
	Get a host detail with multiple ISCSI name
	
  .EXAMPLE	
	Get-3PARHostWithFilter_WSAPI -WWN "xxx,xxx,xxx" -ISCSI "xxx,xxx,xxx" 
	
  .PARAMETER WWN
	Specify WWN of the Host.
	
  .PARAMETER ISCSI
	Specify ISCSI of the Host.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARHostWithFilter_WSAPI    
    LASTEDIT: 23/01/2018
    KEYWORDS: Get-3PARHostWithFilter_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-3PARHostWithFilter_WSAPI HostName : $HostName (Invoke-3parWSAPI)." $Debug
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
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
			Write-DebugLog "SUCCESS: Get-3PARHostWithFilter_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARHostWithFilter_WSAPI. Expected Result Not Found with Given Filter Option : ISCSI/$ISCSI WWN/$WWN." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARHostWithFilter_WSAPI. Expected Result Not Found with Given Filter Option : ISCSI/$ISCSI WWN/$WWN." $Info
			
			return 
		}		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARHostWithFilter_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARHostWithFilter_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-3PARHostWithFilter_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARHostPersona_WSAPI
############################################################################################################################################
Function Get-3PARHostPersona_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of host persona,.
  
  .DESCRIPTION
    This cmdlet (Get-3PARHostPersona_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-HostPersona_WSAPI) instead.
  
	Get Single or list of host persona,.
        
  .EXAMPLE
	Get-3PARHostPersona_WSAPI
	Display a list of host persona.
	
  .EXAMPLE
	Get-3PARHostPersona_WSAPI -Id 10
	Display a host persona of given id.
	
  .EXAMPLE
	Get-3PARHostPersona_WSAPI -WsapiAssignedId 100
	Display a host persona of given Wsapi Assigned Id.
	
  .EXAMPLE
	Get-3PARHostPersona_WSAPI -Id 10
	Get the information of given host persona.
	
  .EXAMPLE	
	Get-3PARHostPersona_WSAPI -WsapiAssignedId "1,2,3"
	Multiple Host.
	
  .PARAMETER Id
	Specify host persona id you want to query.
	
  .PARAMETER WsapiAssignedId
	To filter by wsapi Assigned Id.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARHostPersona_WSAPI    
    LASTEDIT: 23/01/2018
    KEYWORDS: Get-3PARHostPersona_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-3PARHostPersona_WSAPI Id : $Id (Invoke-3parWSAPI)." $Debug
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
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
			
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-3PARHostPersona_WSAPI successfully Executed." $Info
			
			return $dataPS
		}		
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARHostPersona_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARHostPersona_WSAPI. " $Info
			
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
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{			
			$dataPS = ($Result.content | ConvertFrom-Json).members	

			if($dataPS.Count -gt 0)
			{
				write-host ""
				write-host "Cmdlet executed successfully" -foreground green
				write-host ""
				Write-DebugLog "SUCCESS: Get-3PARHostPersona_WSAPI successfully Executed." $Info
				
				return $dataPS
			}
			else
			{
				write-host ""
				write-host "FAILURE : While Executing Get-3PARHostPersona_WSAPI. Expected Result Not Found with Given Filter Option : WsapiAssignedId/$WsapiAssignedId." -foreground red
				write-host ""
				Write-DebugLog "FAILURE : While Executing Get-3PARHostPersona_WSAPI. Expected Result Not Found with Given Filter Option : WsapiAssignedId/$WsapiAssignedId." $Info
				
				return 
			}
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARHostPersona_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARHostPersona_WSAPI. " $Info
			
			return $Result.StatusDescription
		}
	}
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/hostpersonas' -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{			
			$dataPS = ($Result.content | ConvertFrom-Json).members	
				
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-3PARHostPersona_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARHostPersona_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARHostPersona_WSAPI. " $Info
			
			return $Result.StatusDescription
		}
	}
	
  }
	End {}
}#END Get-3PARHostPersona_WSAPI

############################################################################################################################################
## FUNCTION New-3PARHostSet_WSAPI
############################################################################################################################################
Function New-3PARHostSet_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creates a new host Set.
	
  .DESCRIPTION
    This cmdlet (New-3PARHostSet_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-HostSet_WSAPI) instead.
  
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
	New-3PARHostSet_WSAPI -HostSetName MyHostSet
    Creates a new host Set with name MyHostSet.
	
  .EXAMPLE
	New-3PARHostSet_WSAPI -HostSetName MyHostSet -Comment "this Is Test Set" -Domain MyDomain
    Creates a new host Set with name MyHostSet.
	
  .EXAMPLE
	New-3PARHostSet_WSAPI -HostSetName MyHostSet -Comment "this Is Test Set" -Domain MyDomain -SetMembers MyHost
	Creates a new host Set with name MyHostSet with Set Members MyHost.
	
  .EXAMPLE	
	New-3PARHostSet_WSAPI -HostSetName MyHostSet -Comment "this Is Test Set" -Domain MyDomain -SetMembers "MyHost,MyHost1,MyHost2"
    Creates a new host Set with name MyHostSet with Set Members MyHost.	

  .Notes
    NAME    : New-3PARHostSet_WSAPI    
    LASTEDIT: 22/01/2018
    KEYWORDS: New-3PARHostSet_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
    $Result = Invoke-3parWSAPI -uri '/hostsets' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Host Set:$HostSetName created successfully" $Info
		
		Get-3PARHostSet_WSAPI -HostSetName $HostSetName
		Write-DebugLog "End: New-3PARHostSet_WSAPI" $Debug
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
#ENG New-3PARHostSet_WSAPI

############################################################################################################################################
## FUNCTION Update-3PARHostSet_WSAPI
############################################################################################################################################
Function Update-3PARHostSet_WSAPI 
{
  <#
  .SYNOPSIS
	Update an existing Host Set.
  
  .DESCRIPTION
    This cmdlet (Update-3PARHostSet_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Update-HostSet_WSAPI) instead.
  
	Update an existing Host Set.
    Any user with the Super or Edit role can modify a host set. Any role granted hostset_set permission can add a host to the host set or remove a host from the host set.   
	
  .EXAMPLE    
	Update-3PARHostSet_WSAPI -HostSetName xxx -RemoveMember -Members as-Host4
		
  .EXAMPLE
	Update-3PARHostSet_WSAPI -HostSetName xxx -AddMember -Members as-Host4
	
  .EXAMPLE	
	Update-3PARHostSet_WSAPI -HostSetName xxx -ResyncPhysicalCopy
	
  .EXAMPLE	
	Update-3PARHostSet_WSAPI -HostSetName xxx -StopPhysicalCopy 
		
  .EXAMPLE
	Update-3PARHostSet_WSAPI -HostSetName xxx -PromoteVirtualCopy
		
  .EXAMPLE
	Update-3PARHostSet_WSAPI -HostSetName xxx -StopPromoteVirtualCopy
		
  .EXAMPLE
	Update-3PARHostSet_WSAPI -HostSetName xxx -ResyncPhysicalCopy -Priority high
		
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
    NAME    : Update-3PARHostSet_WSAPI    
    LASTEDIT: 22/01/2018
    KEYWORDS: Update-3PARHostSet_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Update-3PARHostSet_WSAPI : $HostSetName (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Host Set:$HostSetName successfully Updated" $Info
				
		# Results
		if($NewName)
		{
			Get-3PARHostSet_WSAPI -HostSetName $NewName
		}
		else
		{
			Get-3PARHostSet_WSAPI -HostSetName $HostSetName
		}
		Write-DebugLog "End: Update-3PARHostSet_WSAPI" $Debug
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

}#END Update-3PARHostSet_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARHostSet_WSAPI
############################################################################################################################################
Function Remove-3PARHostSet_WSAPI
 {
  <#
  .SYNOPSIS
	Remove a Host Set.
  
  .DESCRIPTION
    This cmdlet (Remove-3PARHostSet_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-HostSet_WSAPI) instead.
  
	Remove a Host Set.
	Any user with Super or Edit role, or any role granted host_remove permission, can perform this operation. Requires access to all domains.
        
  .EXAMPLE    
	Remove-3PARHostSet_WSAPI -HostSetName MyHostSet
	
  .PARAMETER HostSetName 
	Specify the name of Host Set to be removed.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-3PARHostSet_WSAPI     
    LASTEDIT: 25/01/2018
    KEYWORDS: Remove-3PARHostSet_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {    
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-3PARHostSet_WSAPI." $Debug
	$uri = '/hostsets/'+$HostSetName
	
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-3PARHostSet_WSAPI : $HostSetName (Invoke-3parWSAPI)." $Debug
	$Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Host Set:$HostSetName successfully remove" $Info
		Write-DebugLog "End: Remove-3PARHostSet_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing Host Set:$HostSetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating Host Set:$HostSetName " $Info
		Write-DebugLog "End: Remove-3PARHostSet_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-3PARHostSet_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARHostSet_WSAPI
############################################################################################################################################
Function Get-3PARHostSet_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of Hotes Set.
  
  .DESCRIPTION
    This cmdlet (Get-3PARHostSet_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-HostSet_WSAPI) instead.
  
	Get Single or list of Hotes Set.
        
  .EXAMPLE
	Get-3PARHostSet_WSAPI
	Display a list of Hotes Set.
	
  .EXAMPLE
	Get-3PARHostSet_WSAPI -HostSetName MyHostSet
	Get the information of given Hotes Set.
	
  .EXAMPLE
	Get-3PARHostSet_WSAPI -Members MyHost
	Get the information of Hotes Set that contain MyHost as Member.
	
  .EXAMPLE
	Get-3PARHostSet_WSAPI -Members "MyHost,MyHost1,MyHost2"
	Multiple Members.
	
  .EXAMPLE
	Get-3PARHostSet_WSAPI -Id 10
	Filter Host Set with Id
	
  .EXAMPLE
	Get-3PARHostSet_WSAPI -Uuid 10
	Filter Host Set with uuid
	
  .EXAMPLE
	Get-3PARHostSet_WSAPI -Members "MyHost,MyHost1,MyHost2" -Id 10 -Uuid 10
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
    NAME    : Get-3PARHostSet_WSAPI    
    LASTEDIT: 25/01/2018
    KEYWORDS: Get-3PARHostSet_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-3PARHostSet_WSAPI HostSetName : $HostSetName (Invoke-3parWSAPI)." $Debug
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
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
			
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-3PARHostSet_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARHostSet_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARHostSet_WSAPI. " $Info
			
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
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{			
			$dataPS = ($Result.content | ConvertFrom-Json).members			
		}
	}	
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/hostsets' -type 'GET' -WsapiConnection $WsapiConnection
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
			Write-DebugLog "SUCCESS: Get-3PARHostSet_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARHostSet_WSAPI. Expected Result Not Found with Given Filter Option : Members/$Members Id/$Id Uuid/$Uuid." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARHostSet_WSAPI. Expected Result Not Found with Given Filter Option : Members/$Members Id/$Id Uuid/$Uuid." $Info
			
			return 
		}		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARHostSet_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARHostSet_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-3PARHostSet_WSAPI

############################################################################################################################################
## FUNCTION New-3PARVVSet_WSAPI
############################################################################################################################################
Function New-3PARVVSet_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creates a new virtual volume Set.
	
  .DESCRIPTION
    This cmdlet (New-3PARVVSet_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-VvSet_WSAPI) instead.
  
	Creates a new virtual volume Set.
    Any user with the Super or Edit role can create a host set. Any role granted hostset_set permission can add hosts to a host set.
	You can add hosts to a host set using a glob-style pattern. A glob-style pattern is not supported when removing hosts from sets.
	For additional information about glob-style patterns, see “Glob-Style Patterns” in the HPE 3PAR Command Line Interface Reference.
	
  .EXAMPLE
	New-3PARVVSet_WSAPI -VVSetName MyVVSet
    Creates a new virtual volume Set with name MyVVSet.
	
  .EXAMPLE
	New-3PARVVSet_WSAPI -VVSetName MyVVSet -Comment "this Is Test Set" -Domain MyDomain
    Creates a new virtual volume Set with name MyVVSet.
	
  .EXAMPLE
	New-3PARVVSet_WSAPI -VVSetName MyVVSet -Comment "this Is Test Set" -Domain MyDomain -SetMembers xxx
	 Creates a new virtual volume Set with name MyVVSet with Set Members xxx.
	
  .EXAMPLE	
	New-3PARVVSet_WSAPI -VVSetName MyVVSet -Comment "this Is Test Set" -Domain MyDomain -SetMembers "xxx1,xxx2,xxx3"
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
    NAME    : New-3PARVVSet_WSAPI    
    LASTEDIT: 25/01/2018
    KEYWORDS: New-3PARVVSet_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
    $Result = Invoke-3parWSAPI -uri '/volumesets' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: virtual volume Set:$VVSetName created successfully" $Info
		
		Get-3PARVVSet_WSAPI -VVSetName $VVSetName
		Write-DebugLog "End: New-3PARVVSet_WSAPI" $Debug
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
#ENG New-3PARVVSet_WSAPI

############################################################################################################################################
## FUNCTION Update-3PARVVSet_WSAPI
############################################################################################################################################
Function Update-3PARVVSet_WSAPI 
{
  <#
  .SYNOPSIS
	Update an existing virtual volume Set.
  
  .DESCRIPTION
    This cmdlet (Update-3PARVVSet_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Update-VvSet_WSAPI) instead.
  
	Update an existing virtual volume Set.
    Any user with the Super or Edit role can modify a host set. Any role granted hostset_set permission can add a host to the host set or remove a host from the host set.   
	
  .EXAMPLE
	Update-3PARVVSet_WSAPI -VVSetName xxx -RemoveMember -Members testvv3.0
	
  .EXAMPLE 
	Update-3PARVVSet_WSAPI -VVSetName xxx -AddMember -Members testvv3.0
	
  .EXAMPLE 
	Update-3PARVVSet_WSAPI -VVSetName xxx -ResyncPhysicalCopy 
	
  .EXAMPLE 
	Update-3PARVVSet_WSAPI -VVSetName xxx -StopPhysicalCopy 
	
  .EXAMPLE 
	Update-3PARVVSet_WSAPI -VVSetName xxx -PromoteVirtualCopy
	
  .EXAMPLE 
	Update-3PARVVSet_WSAPI -VVSetName xxx -StopPromoteVirtualCopy
	
  .EXAMPLE 
	Update-3PARVVSet_WSAPI -VVSetName xxx -Priority xyz
	
  .EXAMPLE 
	Update-3PARVVSet_WSAPI -VVSetName xxx -ResyncPhysicalCopy -Priority high
	
  .EXAMPLE 
	Update-3PARVVSet_WSAPI -VVSetName xxx -ResyncPhysicalCopy -Priority medium
	
  .EXAMPLE 
	Update-3PARVVSet_WSAPI -VVSetName xxx -ResyncPhysicalCopy -Priority low
	
  .EXAMPLE 
	Update-3PARVVSet_WSAPI -VVSetName xxx -NewName as-vvSet1 -Comment "Updateing new name"

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
    NAME    : Update-3PARVVSet_WSAPI    
    LASTEDIT: 22/01/2018
    KEYWORDS: Update-3PARVVSet_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Update-3PARVVSet_WSAPI : $VVSetName (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: virtual volume Set:$VVSetName successfully Updated" $Info
				
		# Results
		if($NewName)
		{
			Get-3PARVVSet_WSAPI -VVSetName $NewName
		}
		else
		{
			Get-3PARVVSet_WSAPI -VVSetName $VVSetName
		}
		Write-DebugLog "End: Update-3PARVVSet_WSAPI" $Debug
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

}#END Update-3PARVVSet_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARVVSet_WSAPI
############################################################################################################################################
Function Remove-3PARVVSet_WSAPI
 {
  <#
  .SYNOPSIS
	Remove a virtual volume Set.
  
  .DESCRIPTION
    This cmdlet (Remove-3PARVVSet_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-VvSet_WSAPI) instead.
  
	Remove a virtual volume Set.
	Any user with Super or Edit role, or any role granted host_remove permission, can perform this operation. Requires access to all domains.
        
  .EXAMPLE    
	Remove-3PARVVSet_WSAPI -VVSetName MyvvSet
	
  .PARAMETER VVSetName 
	Specify the name of virtual volume Set to be removed.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-3PARVVSet_WSAPI     
    LASTEDIT: 25/01/2018
    KEYWORDS: Remove-3PARVVSet_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {    
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-3PARVVSet_WSAPI." $Debug
	$uri = '/volumesets/'+$VVSetName
	
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-3PARVVSet_WSAPI : $VVSetName (Invoke-3parWSAPI)." $Debug
	$Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: virtual volume Set:$VVSetName successfully remove" $Info
		Write-DebugLog "End: Remove-3PARVVSet_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing virtual volume Set:$VVSetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating virtual volume Set:$VVSetName " $Info
		Write-DebugLog "End: Remove-3PARVVSet_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-3PARVVSet_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARVVSet_WSAPI
############################################################################################################################################
Function Get-3PARVVSet_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of virtual volume Set.
  
  .DESCRIPTION
    This cmdlet (Get-3PARVVSet_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-VvSet_WSAPI) instead.
  
	Get Single or list of virtual volume Set.
        
  .EXAMPLE
	Get-3PARVVSet_WSAPI
	Display a list of virtual volume Set.
	
  .EXAMPLE
	Get-3PARVVSet_WSAPI -VVSetName MyvvSet
	Get the information of given virtual volume Set.
	
  .EXAMPLE
	Get-3PARVVSet_WSAPI -Members Myvv
	Get the information of virtual volume Set that contain MyHost as Member.
	
  .EXAMPLE
	Get-3PARVVSet_WSAPI -Members "Myvv,Myvv1,Myvv2"
	Multiple Members.
	
  .EXAMPLE
	Get-3PARVVSet_WSAPI -Id 10
	Filter virtual volume Set with Id
	
  .EXAMPLE
	Get-3PARVVSet_WSAPI -Uuid 10
	Filter virtual volume Set with uuid
	
  .EXAMPLE
	Get-3PARVVSet_WSAPI -Members "Myvv,Myvv1,Myvv2" -Id 10 -Uuid 10
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
    NAME    : Get-3PARVVSet_WSAPI    
    LASTEDIT: 25/01/2018
    KEYWORDS: Get-3PARVVSet_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-3PARVVSet_WSAPI VVSetName : $VVSetName (Invoke-3parWSAPI)." $Debug
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
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection		 
		If($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
			
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-3PARVVSet_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARVVSet_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARVVSet_WSAPI. " $Info
			
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
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection	
		If($Result.StatusCode -eq 200)
		{			
			$dataPS = ($Result.content | ConvertFrom-Json).members			
		}
	}	
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/volumesets' -type 'GET' -WsapiConnection $WsapiConnection
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
			Write-DebugLog "SUCCESS: Get-3PARVVSet_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARVVSet_WSAPI. Expected Result Not Found with Given Filter Option : Members/$Members Id/$Id Uuid/$Uuid." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARVVSet_WSAPI. Expected Result Not Found with Given Filter Option : Members/$Members Id/$Id Uuid/$Uuid." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARVVSet_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARVVSet_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-3PARVVSet_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARFileServices_WSAPI
############################################################################################################################################
Function Get-3PARFileServices_WSAPI 
{
  <#
  .SYNOPSIS
	Get the File Services information.
  
  .DESCRIPTION
    This cmdlet (Get-3PARFileServices_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-FileServices_WSAPI) instead.
  
	Get the File Services information.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .EXAMPLE
    Get-3PARFileServices_WSAPI
	display File Services Information

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARFileServices_WSAPI    
    LASTEDIT: 29/01/2018
    KEYWORDS: Get-3PARFileServices_WSAPI
   
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
  Test-3PARConnection -WsapiConnection $WsapiConnection

  #Request 
  $Result = Invoke-3parWSAPI -uri '/fileservices' -type 'GET' -WsapiConnection $WsapiConnection

  if($Result.StatusCode -eq 200)
  {
		# Results
		$dataPS = ($Result.content | ConvertFrom-Json)

		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Get-3PARFileServices_WSAPI successfully Executed." $Info

		return $dataPS
  }
  else
  {
		write-host ""
		write-host "FAILURE : While Executing Get-3PARFileServices_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARFileServices_WSAPI. " $Info
		
		return $Result.StatusDescription
  }  
}
#END Get-3PARFileServices_WSAPI

############################################################################################################################################
## FUNCTION New-3PARFPG_WSAPI
############################################################################################################################################
Function New-3PARFPG_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creates a new File Provisioning Group(FPG).
	
  .DESCRIPTION
    This cmdlet (New-3PARFPG_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-FPG_WSAPI) instead.
  
	Creates a new File Provisioning Group(FPG).
	
  .EXAMPLE
	New-3PARFPG_WSAPI -PFGName "MyFPG" -CPGName "MyCPG"	-SizeTiB 12
	Creates a new File Provisioning Group(FPG), size must be in Terabytes
	
  .EXAMPLE	
	New-3PARFPG_WSAPI -FPGName asFPG -CPGName cpg_test -SizeTiB 1 -FPVV $true
	
  .EXAMPLE	
	New-3PARFPG_WSAPI -FPGName asFPG -CPGName cpg_test -SizeTiB 1 -TDVV $true
	
  .EXAMPLE	
	New-3PARFPG_WSAPI -FPGName asFPG -CPGName cpg_test -SizeTiB 1 -NodeId 1
	
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
    NAME    : New-3PARFPG_WSAPI    
    LASTEDIT: 29/01/2018
    KEYWORDS: New-3PARFPG_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
    $Result = Invoke-3parWSAPI -uri '/fpgs' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 202)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: File Provisioning Groups:$FPGName created successfully" $Info
		
		Get-3PARFPG_WSAPI -FPG $FPGName
		Write-DebugLog "End: New-3PARFPG_WSAPI" $Debug
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
#ENG New-3PARFPG_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARFPG_WSAPI
############################################################################################################################################
Function Remove-3PARFPG_WSAPI
 {
  <#
  .SYNOPSIS
	Remove a File Provisioning Group.
  
  .DESCRIPTION
    This cmdlet (Remove-3PARFPG_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-FPG_WSAPI) instead.
  
	Remove a File Provisioning Group.
        
  .EXAMPLE    
	Remove-3PARFPG_WSAPI -FPGId 123 
	
  .PARAMETER FPGId 
	Specify the File Provisioning Group uuid to be removed.
  
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-3PARFPG_WSAPI     
    LASTEDIT: 29/01/2018
    KEYWORDS: Remove-3PARFPG_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {    
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-3PARFPG_WSAPI." $Debug
	$uri = '/fpgs/'+$FPGId
	
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-3PARFPG_WSAPI : $FPGId (Invoke-3parWSAPI)." $Debug
	$Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 202)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: File Provisioning Group:$FPGId successfully remove" $Info
		Write-DebugLog "End: Remove-3PARFPG_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing File Provisioning Group : $FPGId " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Removing File Provisioning Group : $FPGId " $Info
		Write-DebugLog "End: Remove-3PARFPG_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-3PARFPG_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARFPG_WSAPI
############################################################################################################################################
Function Get-3PARFPG_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of File Provisioning Group.
  
  .DESCRIPTION
    This cmdlet (Get-3PARFPG_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-FPG_WSAPI) instead.
  
	Get Single or list of File Provisioning Group.
        
  .EXAMPLE
	Get-3PARFPG_WSAPI
	Display a list of File Provisioning Group.
  
  .EXAMPLE
	Get-3PARFPG_WSAPI -FPG MyFPG
	Display a Given File Provisioning Group.
	
  .EXAMPLE
	Get-3PARFPG_WSAPI -FPG "MyFPG,MyFPG1,MyFPG2,MyFPG3"
	Display Multiple File Provisioning Group.
	
  .PARAMETER FPG
	Name of File Provisioning Group.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-3PARFPG_WSAPI    
    LASTEDIT: 29/01/2018
    KEYWORDS: Get-3PARFPG_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-3PARFPG_WSAPI File Provisioning Group : $FPG (Invoke-3parWSAPI)." $Debug
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
			$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection		
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
			$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection		
			If($Result.StatusCode -eq 200)
			{
				$dataPS = $Result.content | ConvertFrom-Json				
			}		
		}
			
	}
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/fpgs' -type 'GET' -WsapiConnection $WsapiConnection
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
			Write-DebugLog "SUCCESS: Get-3PARFPG_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARFPG_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARFPG_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARFPG_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARFPG_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-3PARFPG_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARFPGReclamationTasks_WSAPI
############################################################################################################################################
Function Get-3PARFPGReclamationTasks_WSAPI 
{
  <#
  .SYNOPSIS
	Get the reclamation tasks for the FPG.
  
  .DESCRIPTION
    This cmdlet (Get-3PARFPGReclamationTasks_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-FPGReclamationTasks_WSAPI) instead.
  
	Get the reclamation tasks for the FPG.
        
  .EXAMPLE
    Get-3PARFPGReclamationTasks_WSAPI
	Get the reclamation tasks for the FPG.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-3PARFPGReclamationTasks_WSAPI    
    LASTEDIT: 29/01/2018
    KEYWORDS: Get-3PARFPGReclamationTasks_WSAPI
   
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
  Test-3PARConnection -WsapiConnection $WsapiConnection

  #Request 
  $Result = Invoke-3parWSAPI -uri '/fpgs/reclaimtasks' -type 'GET' -WsapiConnection $WsapiConnection

  if($Result.StatusCode -eq 200)
  {
		# Results
		$dataPS = ($Result.content | ConvertFrom-Json).members

		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-3PARFPGReclamationTasks_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARFPGReclamationTasks_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARFPGReclamationTasks_WSAPI." $Info
			
			return 
		}
  }
  else
  {
		write-host ""
		write-host "FAILURE : While Executing Get-3PARFPGReclamationTasks_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARFPGReclamationTasks_WSAPI. " $Info
		
		return $Result.StatusDescription
  }  
}
#END Get-3PARFPGReclamationTasks_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARPort_WSAPI
############################################################################################################################################
Function Get-3PARPort_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get a single or List ports in the storage system.
  
  .DESCRIPTION
    This cmdlet (Get-3PARPort_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-Port_WSAPI) instead.
  
	Get a single or List ports in the storage system.
        
  .EXAMPLE
	Get-3PARPort_WSAPI
	Get list all ports in the storage system.
	
  .EXAMPLE
	Get-3PARPort_WSAPI -NSP 1:1:1
	Single port or given port in the storage system.
	
  .EXAMPLE
	Get-3PARPort_WSAPI -Type HOST
	Single port or given port in the storage system.
	
  .EXAMPLE	
	Get-3PARPort_WSAPI -Type "HOST,DISK"
	
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
    NAME    : Get-3PARPort_WSAPI   
    LASTEDIT: 30/01/2018
    KEYWORDS: Get-3PARPort_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
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
			return "FAILURE : While executing Get-3PARPort_WSAPI. Select only one from NSP : $NSP or Type : $Type"
		}
		$uri = '/ports/'+$NSP
		#Request
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-3PARPort_WSAPI successfully Executed." $Info

			return $dataPS		
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARPort_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARPort_WSAPI. " $Info

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
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{			
			$dataPS = ($Result.content | ConvertFrom-Json).members			
		}
		
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-3PARPort_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARPort_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARPort_WSAPI." $Info
			
			return 
		}
	}
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/ports' -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}	
			
		if($Result.StatusCode -eq 200)
		{		
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Get-3PARPort_WSAPI successfully Executed." $Info

			return $dataPS		
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARPort_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARPort_WSAPI. " $Info

			return $Result.StatusDescription
		} 
	}
  }	
}
#END Get-3PARPort_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARiSCSIVLANs_WSAPI
############################################################################################################################################
Function Get-3PARiSCSIVLANs_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Querying iSCSI VLANs for an iSCSI port
  
  .DESCRIPTION
    This cmdlet (Get-3PARiSCSIVLANs_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-IscsivLans_WSAPI) instead.
  
	Querying iSCSI VLANs for an iSCSI port
        
  .EXAMPLE
	Get-3PARiSCSIVLANs_WSAPI
	Get the status of all tasks
	
  .EXAMPLE
	Get-3PARiSCSIVLANs_WSAPI -Type FS
	
  .EXAMPLE
	Get-3PARiSCSIVLANs_WSAPI -NSP 1:0:1
	
  .EXAMPLE	
	Get-3PARiSCSIVLANs_WSAPI -VLANtag xyz -NSP 1:0:1
	
  .PARAMETER Type
	Port connection type.
  
  .PARAMETER NSP
	The <n:s:p> variable identifies the node, slot, and port of the device.
  
  .PARAMETER VLANtag
	VLAN ID.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Get-3PARiSCSIVLANs_WSAPI   
    LASTEDIT: 31/07/2018
    KEYWORDS: Get-3PARiSCSIVLANs_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
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
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
			
			$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
			$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARiSCSIVLANs_WSAPI Successfully Executed" $Info
		
		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARiSCSIVLANs_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARiSCSIVLANs_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARiSCSIVLANs_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARPortDevices_WSAPI
############################################################################################################################################
Function Get-3PARPortDevices_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get single or list of port devices in the storage system.
  
  .DESCRIPTION
    This cmdlet (Get-3PARPortDevices_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-PortDevices_WSAPI) instead.
  
	Get single or list of port devices in the storage system.
        
  .EXAMPLE
	Get-3PARPortDevices_WSAPI -NSP 1:1:1
	Get a list of port devices in the storage system.
	
  .EXAMPLE
	Get-3PARPortDevices_WSAPI -NSP "1:1:1,0:0:0"
	Multiple Port option Get a list of port devices in the storage system.
	
  .PARAMETER NSP
	The <n:s:p> variable identifies the node, slot, and port of the device.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARPortDevices_WSAPI   
    LASTEDIT: 30/01/2018
    KEYWORDS: Get-3PARPortDevices_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
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
			$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
			If($Result.StatusCode -eq 200)
			{			
				$dataPS = ($Result.content | ConvertFrom-Json).members			
			}
			
			if($dataPS.Count -gt 0)
			{
				write-host ""
				write-host "Cmdlet executed successfully" -foreground green
				write-host ""
				Write-DebugLog "SUCCESS: Get-3PARPortDevices_WSAPI successfully Executed." $Info
				
				return $dataPS
			}
			else
			{
				write-host ""
				write-host "FAILURE : While Executing Get-3PARPortDevices_WSAPI" -foreground red
				write-host ""
				Write-DebugLog "FAILURE : While Executing Get-3PARPortDevices_WSAPI." $Info
				
				return 
			}
		}
		else
		{		
			#Build uri
			$uri = '/portdevices/all/'+$NSP
			
			#Request
			$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
			If($Result.StatusCode -eq 200)
			{			
				$dataPS = ($Result.content | ConvertFrom-Json).members			
			}	

			if($dataPS.Count -gt 0)
			{
				write-host ""
				write-host "Cmdlet executed successfully" -foreground green
				write-host ""
				Write-DebugLog "SUCCESS: Get-3PARPortDevices_WSAPI successfully Executed." $Info
				
				return $dataPS
			}
			else
			{
				write-host ""
				write-host "FAILURE : While Executing Get-3PARPortDevices_WSAPI." -foreground red
				write-host ""
				Write-DebugLog "FAILURE : While Executing Get-3PARPortDevices_WSAPI." $Info
				
				return 
			}
		}
	}	
  }	
}
#END Get-3PARPortDevices_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARPortDeviceTDZ_WSAPI
############################################################################################################################################
Function Get-3PARPortDeviceTDZ_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of port device target-driven zones.
  
  .DESCRIPTION
    This cmdlet (Get-3PARPortDeviceTDZ_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-PortDeviceTDZ_WSAPI) instead.
  
	Get Single or list of port device target-driven zones.
        
  .EXAMPLE
	Get-3PARPortDeviceTDZ_WSAPI
	Display a list of port device target-driven zones.
	
  .EXAMPLE
	Get-3PARPortDeviceTDZ_WSAPI -NSP 0:0:0
	Get the information of given port device target-driven zones.
	
  .PARAMETER NSP
	The <n:s:p> variable identifies the node, slot, and port of the device.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-3PARPortDeviceTDZ_WSAPI    
    LASTEDIT: 30/01/2018
    KEYWORDS: Get-3PARPortDeviceTDZ_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-3PARPortDeviceTDZ_WSAPI NSP : $NSP (Invoke-3parWSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null		
	
	# Results
	if($NSP)
	{
		#Build uri
		$uri = '/portdevices/targetdrivenzones/'+$NSP
		#Request
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}	
	}	
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/portdevices/targetdrivenzones/' -type 'GET' -WsapiConnection $WsapiConnection
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
				Write-DebugLog "SUCCESS: Get-3PARPortDeviceTDZ_WSAPI successfully Executed." $Info
				
				return $dataPS
			}
			else
			{
				write-host ""
				write-host "FAILURE : While Executing Get-3PARPortDeviceTDZ_WSAPI." -foreground red
				write-host ""
				Write-DebugLog "FAILURE : While Executing Get-3PARPortDeviceTDZ_WSAPI." $Info
				
				return 
			}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARPortDeviceTDZ_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARPortDeviceTDZ_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-3PARPortDeviceTDZ_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARFCSwitches_WSAPI
############################################################################################################################################
Function Get-3PARFCSwitches_WSAPI 
{
  <#
  .SYNOPSIS
	Get a list of all FC switches connected to a specified port.
  
  .DESCRIPTION
    This cmdlet (Get-3PARFCSwitches_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-FcSwitches_WSAPI) instead.
  
	Get a list of all FC switches connected to a specified port.
	
  .EXAMPLE
	Get-3PARFCSwitches_WSAPI -NSP 0:0:0
	Get a list of all FC switches connected to a specified port.
	
  .PARAMETER NSP
	The <n:s:p> variable identifies the node, slot, and port of the device.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Get-3PARFCSwitches_WSAPI    
    LASTEDIT: 30/01/2018
    KEYWORDS: Get-3PARFCSwitches_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-3PARFCSwitches_WSAPI NSP : $NSP (Invoke-3parWSAPI)." $Debug
    #Request
    
	$Result = $null
	$dataPS = $null		
	
	# Results
	if($NSP)
	{
		#Build uri
		$uri = '/portdevices/fcswitch/'+$NSP
		#Request
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
			Write-DebugLog "SUCCESS: Get-3PARFCSwitches_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{			
			write-host ""
			write-host "FAILURE : While Executing Get-3PARFCSwitches_WSAPI." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARFCSwitches_WSAPI." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARFCSwitches_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARFCSwitches_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-3PARFCSwitches_WSAPI

############################################################################################################################################
## FUNCTION Set-3PARISCSIPort_WSAPI
############################################################################################################################################
Function Set-3PARISCSIPort_WSAPI 
{
  <#
  .SYNOPSIS
	Configure iSCSI ports
  
  .DESCRIPTION
	Configure iSCSI ports
        
  .EXAMPLE    
	Set-3PARISCSIPort_WSAPI -NSP 1:2:3 -IPAdr 1.1.1.1 -Netmask xxx -Gateway xxx -MTU xx -ISNSPort xxx -ISNSAddr xxx
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
    NAME    : Set-3PARISCSIPort_WSAPI    
    LASTEDIT: 30/01/2018
    KEYWORDS: Set-3PARISCSIPort_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Set-3PARISCSIPort_WSAPI : $NSP (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: iSCSI ports : $NSP successfully configure." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Set-3PARISCSIPort_WSAPI" $Debug
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

}#END Set-3PARISCSIPort_WSAPI

############################################################################################################################################
## FUNCTION New-3PARISCSIVlan_WSAPI
############################################################################################################################################
Function New-3PARISCSIVlan_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creates a VLAN on an iSCSI port.
	
  .DESCRIPTION
    This cmdlet (New-3PARISCSIVlan_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-IscsivLun_WSAPI) instead.
  
	Creates a VLAN on an iSCSI port.
	
  .EXAMPLE
	New-3PARISCSIVlan_WSAPI -NSP 1:1:1 -IPAddress x.x.x.x -Netmask xx -VlanTag xx
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
    NAME    : New-3PARISCSIVlan_WSAPI    
    LASTEDIT: 30/01/2018
    KEYWORDS: New-3PARISCSIVlan_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: VLAN on an iSCSI port :$NSP created successfully" $Info		
		Write-DebugLog "End: New-3PARISCSIVlan_WSAPI" $Debug
		
		return $Result
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating VLAN on an iSCSI port : $NSP" -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While VLAN on an iSCSI port : $NSP" $Info
		Write-DebugLog "End: New-3PARISCSIVlan_WSAPI" $Debug
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG New-3PARISCSIVlan_WSAPI

############################################################################################################################################
## FUNCTION Set-3PARISCSIVlan_WSAPI
############################################################################################################################################
Function Set-3PARISCSIVlan_WSAPI 
{
  <#
  .SYNOPSIS
	Configure VLAN on an iSCSI port
  
  .DESCRIPTION
    This cmdlet (Set-3PARISCSIVlan_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Set-IscsivLan_WSAPI) instead.
  
	Configure VLAN on an iSCSI port
        
  .EXAMPLE    
	Set-3PARISCSIVlan_WSAPI -NSP 1:2:3 -IPAdr 1.1.1.1 -Netmask xxx -Gateway xxx -MTU xx -STGT xx -ISNSPort xxx -ISNSAddr xxx
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
    NAME    : Set-3PARISCSIVlan_WSAPI    
    LASTEDIT: 31/01/2018
    KEYWORDS: Set-3PARISCSIVlan_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Set-3PARISCSIVlan_WSAPI : $NSP (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully configure VLAN on an iSCSI port : $NSP ." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Set-3PARISCSIVlan_WSAPI" $Debug
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

}#END Set-3PARISCSIVlan_WSAPI

############################################################################################################################################
## FUNCTION Reset-3PARISCSIPort_WSAPI
############################################################################################################################################
Function Reset-3PARISCSIPort_WSAPI 
{
  <#
  
  .SYNOPSIS
	Resetting an iSCSI port configuration
	
  .DESCRIPTION
    This cmdlet (Reset-3PARISCSIPort_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Reset-IscsiPort_WSAPI) instead.
  
	Resetting an iSCSI port configuration
	
  .EXAMPLE
	Reset-3PARISCSIPort_WSAPI -NSP 1:1:1 
	
  .PARAMETER NSP
	The <n:s:p> parameter identifies the port you want to configure.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Reset-3PARISCSIPort_WSAPI    
    LASTEDIT: 31/01/2018
    KEYWORDS: Reset-3PARISCSIPort_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Reset an iSCSI port configuration $NSP" $Info		
		Write-DebugLog "End: Reset-3PARISCSIPort_WSAPI" $Debug
		
		return $Result
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Resetting an iSCSI port configuration : $NSP" -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Resetting an iSCSI port configuration : $NSP" $Info
		Write-DebugLog "End: Reset-3PARISCSIPort_WSAPI" $Debug
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG Reset-3PARISCSIPort_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARISCSIVlan_WSAPI
############################################################################################################################################
Function Remove-3PARISCSIVlan_WSAPI
 {
  <#
  .SYNOPSIS
	Removing an iSCSI port VLAN.
  
  .DESCRIPTION
    This cmdlet (Remove-3PARISCSIVlan_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-IscsivLan_WSAPI) instead.
  
	Remove a File Provisioning Group.
        
  .EXAMPLE    
	Remove-3PARISCSIVlan_WSAPI -NSP 1:1:1 -VlanTag 1 
	Removing an iSCSI port VLAN
	
  .PARAMETER NSP 
	The <n:s:p> parameter identifies the port you want to configure.

  .PARAMETER VlanTag 
	VLAN tag.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-3PARISCSIVlan_WSAPI     
    LASTEDIT: 31/01/2018
    KEYWORDS: Remove-3PARISCSIVlan_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {    
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-3PARISCSIVlan_WSAPI." $Debug
	
	$uri = "/ports/"+$NSP+"/iSCSIVlans/"+$VlanTag 
	
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-3PARISCSIVlan_WSAPI : $NSP (Invoke-3parWSAPI)." $Debug
	$Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 202)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully remove an iSCSI port VLAN : $NSP" $Info
		Write-DebugLog "End: Remove-3PARISCSIVlan_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing an iSCSI port VLAN : $NSP " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Removing an iSCSI port VLAN : $NSP " $Info
		Write-DebugLog "End: Remove-3PARISCSIVlan_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-3PARISCSIVlan_WSAPI

############################################################################################################################################
## FUNCTION New-3PARVLun_WSAPI
############################################################################################################################################
Function New-3PARVLun_WSAPI 
{
  <#
  
  .SYNOPSIS
	Creating a VLUN
	
  .DESCRIPTION
    This cmdlet (New-3PARVLun_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-vLun_WSAPI) instead.
  
	Creating a VLUN
	Any user with Super or Edit role, or any role granted vlun_create permission, can perform this operation.
	
  .EXAMPLE
	New-3PARVLun_WSAPI -VolumeName xxx -LUNID x -HostName xxx

  .EXAMPLE
	New-3PARVLun_WSAPI -VolumeName xxx -LUNID x -HostName xxx -NSP 1:1:1
	
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
    NAME    : New-3PARVLun_WSAPI    
    LASTEDIT: 31/01/2018
    KEYWORDS: New-3PARVLun_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
    $Result = Invoke-3parWSAPI -uri '/vluns' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode	
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		#write-host "SUCCESS: Status Code : $Result.StatusCode ." -foreground green
		#write-host "SUCCESS: Status Description : $Result.StatusDescription." -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created a VLUN" $Info	
		Get-3PARVLun_WSAPI -VolumeName $VolumeName -LUNID $LUNID -HostName $HostName
		
		Write-DebugLog "End: New-3PARVLun_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Creating a VLUN" -foreground red
		write-host ""
		Write-DebugLog "FAILURE : Creating a VLUN" $Info
		Write-DebugLog "End: New-3PARVLun_WSAPI" $Debug
		
		return $Result.StatusDescription
	}	
  }
  End 
  {
  }  
}
#ENG New-3PARVLun_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARVLun_WSAPI
############################################################################################################################################
Function Remove-3PARVLun_WSAPI
 {
  <#
	
  .SYNOPSIS
	Removing a VLUN.
  
  .DESCRIPTION
    This cmdlet (Remove-3PARVLun_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-vLun_WSAPI) instead.
  
	Removing a VLUN
    Any user with the Super or Edit role, or any role granted with the vlun_remove right, can perform this operation.    
	
  .EXAMPLE    
	Remove-3PARVLun_WSAPI -VolumeName xxx -LUNID xx -HostName xxx

  .EXAMPLE    
	Remove-3PARVLun_WSAPI -VolumeName xxx -LUNID xx -HostName xxx -NSP x:x:x
	
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
	required if volume is exported to port, or to both host and port .Notes NAME : Remove-3PARVLun_WSAPI 
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : Remove-3PARVLun_WSAPI    
    LASTEDIT: 31/01/2018
    KEYWORDS: Remove-3PARVLun_WSAPI 
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {    
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-3PARVLun_WSAPI  ." $Debug
	$uri = "/vluns/"+$VolumeName+","+$LUNID+","+$HostName
	
	if($NSP)
	{
		$uri = $uri+","+$NSP
	}	

	#init the response var
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-3PARVLun_WSAPI : $CPGName (Invoke-3parWSAPI)." $Debug
	$Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: VLUN Successfully removed with Given Values [ VolumeName : $VolumeName | LUNID : $LUNID | HostName : $HostName | NSP : $NSP ]." $Info
		Write-DebugLog "End: Remove-3PARVLun_WSAPI" $Debug
		return $Result		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing VLUN with Given Values [ VolumeName : $VolumeName | LUNID : $LUNID | HostName : $HostName | NSP : $NSP ]. " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Removing VLUN with Given Values [ VolumeName : $VolumeName | LUNID : $LUNID | HostName : $HostName | NSP : $NSP ]." $Info
		Write-DebugLog "End: Remove-3PARVLun_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-3PARVLun_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARVLun_WSAPI
############################################################################################################################################
Function Get-3PARVLun_WSAPI 
{
  <#
  .SYNOPSIS
	Get Single or list of VLun.
  
  .DESCRIPTION
    This cmdlet (Get-3PARVLun_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-vLun_WSAPI) instead.
  
	Get Single or list of VLun
        
  .EXAMPLE
	Get-3PARVLun_WSAPI
	Display a list of VLun.
	
  .EXAMPLE
	Get-3PARVLun_WSAPI -VolumeName xxx -LUNID x -HostName xxx 
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
    NAME    : Get-3PARVLun_WSAPI    
    LASTEDIT: 31/01/2018
    KEYWORDS: Get-3PARVLun_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-3PARVLun_WSAPI [ VolumeName : $VolumeName | LUNID : $LUNID | HostName : $HostName | NSP : $NSP] (Invoke-3parWSAPI)." $Debug
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
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		If($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/vluns' -type 'GET' -WsapiConnection $WsapiConnection
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
				Write-DebugLog "SUCCESS: Get-3PARVLun_WSAPI successfully Executed." $Info
				
				return $dataPS
			}
			else
			{
				write-host ""
				write-host "FAILURE : While Executing Get-3PARVLun_WSAPI. Expected Result Not Found [ VolumeName : $VolumeName | LUNID : $LUNID | HostName : $HostName | NSP : $NSP]." -foreground red
				write-host ""
				Write-DebugLog "FAILURE : While Executing Get-3PARVLun_WSAPI. Expected Result Not Found [ VolumeName : $VolumeName | LUNID : $LUNID | HostName : $HostName | NSP : $NSP]" $Info
				
				return 
			}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARVLun_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARVLun_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-3PARVLun_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARVLunUsingFilters_WSAPI
############################################################################################################################################
Function Get-3PARVLunUsingFilters_WSAPI 
{
  <#
  .SYNOPSIS
	Get VLUNs using filters.
  
  .DESCRIPTION
    This cmdlet (Get-3PARVLunUsingFilters_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-vLunUsingFilters_WSAPI) instead.
  
	Get VLUNs using filters.
	Available filters for VLUN queries
	Use the following filters to query VLUNs:
	• volumeWWN
	• remoteName
	• volumeName
	• hostname
	• serial
        
  .EXAMPLE
	Get-3PARVLunUsingFilters_WSAPI -VolumeWWN "xxx"

  .EXAMPLE
	Get-3PARVLunUsingFilters_WSAPI -VolumeWWN "xxx,yyy,zzz"
	
  .EXAMPLE
	Get-3PARVLunUsingFilters_WSAPI -RemoteName "xxx"
	
  .EXAMPLE
	Get-3PARVLunUsingFilters_WSAPI -RemoteName "xxx,yyy,zzz"
	
  .EXAMPLE
	Get-3PARVLunUsingFilters_WSAPI -RemoteName "xxx" -VolumeWWN "xxx"
	Supporting single or multipule values using ","

  .EXAMPLE
	Get-3PARVLunUsingFilters_WSAPI -RemoteName "xxx" -VolumeWWN "xxx" -VolumeName "xxx"
	Supporting single or multipule values using ","
	
  .EXAMPLE
	Get-3PARVLunUsingFilters_WSAPI -RemoteName "xxx" -VolumeWWN "xxx" -VolumeName "xxx" -HostName "xxx"
	Supporting single or multipule values using ","
	
  .EXAMPLE
	Get-3PARVLunUsingFilters_WSAPI -RemoteName "xxx" -VolumeWWN "xxx" -VolumeName "xxx" -HostName "xxx" -Serial "xxx"
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
    NAME    : Get-3PARVLunUsingFilters_WSAPI    
    LASTEDIT: 01/02/2018
    KEYWORDS: Get-3PARVLunUsingFilters_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection	 
  }

  Process 
  {
	Write-DebugLog "Request: Request to Get-3PARVLunUsingFilters_WSAPI VVSetName : $VVSetName (Invoke-3parWSAPI)." $Debug
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
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection		
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
			Write-DebugLog "SUCCESS: Get-3PARVLunUsingFilters_WSAPI successfully Executed." $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARVLunUsingFilters_WSAPI. Expected Result Not Found with Given Filter Option : VolumeWWN/$VolumeWWN RemoteName/$RemoteName VolumeName/$VolumeName HostName/$HostName Serial/$Serial." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARVLunUsingFilters_WSAPI. Expected Result Not Found with Given Filter Option : VolumeWWN/$VolumeWWN RemoteName/$RemoteName VolumeName/$VolumeName HostName/$HostName Serial/$Serial." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARVLunUsingFilters_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARVLunUsingFilters_WSAPI. " $Info
		
		return $Result.StatusDescription
	}
  }
	End {}
}#END Get-3PARVLunUsingFilters_WSAPI

############################################################################################################################################
## FUNCTION LoopingFunction
############################################################################################################################################
Function LoopingFunction
 {
  <#
  .SYNOPSIS
	Internal function for looping .
  
  .DESCRIPTION
	Internal function for looping .
        
  .EXAMPLE    
	LoopingFunction -Value xxx -condition xxx -flg $true/False
	
  .PARAMETER Value 
	value for to split or pass.
	
  .PARAMETER Condition 
	condition.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : LoopingFunction     
    LASTEDIT: 1/02/2018
    KEYWORDS: LoopingFunction
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0	
  #>
  [CmdletBinding()]
  Param(
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Value,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Condition,
	
	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[boolean]
	$flg,
	
	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Query,
	
	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	$WsapiConnection = $global:WsapiConnection
	
	)	
	
	#write-host "Query = $Query"
	
	$count = 1
	$lista = $Value.split(",")
	foreach($sub in $lista)
	{	
		if($flg)
		{
			$Query = $Query.Insert($Query.Length-3," OR $Condition EQ $sub")
			$flg = $false
		}
		else
		{
			$Query = $Query.Insert($Query.Length-3," $Condition EQ $sub")
		}
		if($lista.Count -gt 1)
		{
			if($lista.Count -ne $count)
			{
				$Query = $Query.Insert($Query.Length-3," OR ")
				$count = $count + 1
			}				
		}
	}
	return $Query 
}
#END LoopingFunction

############################################################################################################################################
## FUNCTION New-3PARVVSnapshot_WSAPI
############################################################################################################################################
Function New-3PARVVSnapshot_WSAPI 
{
  <#      
  .SYNOPSIS	
	Creating a volume snapshot
  
  .DESCRIPTION	
     This cmdlet (New-3PARVVSnapshot_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-VvSnapshot_WSAPI) instead.
  
     Creating a volume snapshot
	 
  .EXAMPLE    
	New-3PARVVSnapshot_WSAPI -VolumeName $val -snpVVName snpvv1
        
  .EXAMPLE	
	New-3PARVVSnapshot_WSAPI -VolumeName $val -snpVVName snpvv1 -ID 11
        
  .EXAMPLE	
	New-3PARVVSnapshot_WSAPI -VolumeName $val -snpVVName snpvv1 -ID 11 -Comment hello
        
  .EXAMPLE	
	New-3PARVVSnapshot_WSAPI -VolumeName $val -snpVVName snpvv1 -ID 11 -Comment hello -ReadOnly $true
        
  .EXAMPLE	
	New-3PARVVSnapshot_WSAPI -VolumeName $val -snpVVName snpvv1 -ID 11 -Comment hello -ReadOnly $true -ExpirationHours 10
        
  .EXAMPLE	
	New-3PARVVSnapshot_WSAPI -VolumeName $val -snpVVName snpvv1 -ID 11 -Comment hello -ReadOnly $true -ExpirationHours 10 -RetentionHours 10
        
  .EXAMPLE	
	New-3PARVVSnapshot_WSAPI -VolumeName $val -snpVVName snpvv1 -AddToSet asvvset
	
  .PARAMETER VolumeName
	The <VolumeName> parameter specifies the name of the volume from which you want to copy.
	
  .PARAMETER snpVVName
	Specifies a snapshot volume name up to 31 characters in length.	For a snapshot of a volume set, use	name patterns that are used to form	the snapshot volume name. 
	See, VV	Name Patterns in the HPE 3PAR Command Line Interface Reference,available from the HPE Storage Information Library.
	
  .PARAMETER ID
	Specifies the ID of the snapshot. If not specified, the system chooses the next available ID.
	Not applicable for VV-set snapshot creation.
	
  .PARAMETER Comment
	Specifies any additional information up to 511 characters for the volume.
	
  .PARAMETER ReadOnly
	true—Specifies that the copied volume is read-only.
	false—(default) The volume is read/write.
	
  .PARAMETER ExpirationHours
	Specifies the relative time from the current time that the volume expires. Value is a positive integer and in the range of 1–43,800 hours, or 1825 days.
	
  .PARAMETER RetentionHours
	Specifies the relative time from the current time that the volume will expire. Value is a positive integer and in the range of 1–43,800 hours, or 1825 days.
	
  .PARAMETER AddToSet
	The name of the volume set to which the system adds your created snapshots. If the volume set does not exist, it will be created.
 
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : New-3PARVVSnapshot_WSAPI    
    LASTEDIT: 13/01/2018
    KEYWORDS: New-3PARVVSnapshot_WSAPI
   
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
      [System.String]
	  $snpVVName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $ID,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Comment,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $ReadOnly,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $ExpirationHours,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $RetentionHours,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $AddToSet,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}	
	$ParameterBody = @{}

    # Name parameter
    $body["action"] = "createSnapshot"

   
    If($snpVVName) 
	{
          $ParameterBody["name"] = "$($snpVVName)"
    }
    If($ID) 
	{
          $ParameterBody["id"] = $ID
    }
	If($Comment) 
	{
          $ParameterBody["comment"] = "$($Comment)"
    }
    If($ReadOnly) 
	{
          $ParameterBody["readOnly"] = $ReadOnly
    }
	If($ExpirationHours) 
	{
          $ParameterBody["expirationHours"] = $ExpirationHours
    }
	If($RetentionHours) 
	{
          $ParameterBody["retentionHours"] = $RetentionHours
    }
	If($AddToSet) 
	{
          $ParameterBody["addToSet"] = "$($AddToSet)"
    }
	
	if($ParameterBody.Count -gt 0)
	{
		$body["parameters"] = $ParameterBody 
	}

    $Result = $null
	
    #Request
	Write-DebugLog "Request: Request to New-3PARVVSnapshot_WSAPI : $snpVVName (Invoke-3parWSAPI)." $Debug
	
	$uri = '/volumes/'+$VolumeName
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: volume snapshot:$snpVVName created successfully" $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARVVSnapshot_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating volume snapshot: $snpVVName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating volume snapshot: $snpVVName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-3PARVVSnapshot_WSAPI

############################################################################################################################################
## FUNCTION New-3PARVVListGroupSnapshot_WSAPI
############################################################################################################################################
Function New-3PARVVListGroupSnapshot_WSAPI 
{
  <#      
  .SYNOPSIS	
	Creating group snapshots of a virtual volumes list
  
  .DESCRIPTION
    This cmdlet (New-3PARVVListGroupSnapshot_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-VvListGroupSnapshot_WSAPI) instead.
  
	Creating group snapshots of a virtual volumes list
        
  .EXAMPLE    
	New-3PARVVListGroupSnapshot_WSAPI -VolumeName xyz -SnapshotName asSnpvv -SnapshotId 10 -SnapshotWWN 60002AC0000000000101142300018F8D -ReadWrite $true -Comment Hello -ReadOnly $true -Match $true -ExpirationHours 10 -RetentionHours 10 -SkipBlock $true
	
  .PARAMETER VolumeName 
	Name of the volume being copied. Required.
  
  .PARAMETER SnapshotName
	If not specified, the system generates the snapshot name.
  
  .PARAMETER SnapshotId
	ID of the snapShot volume. If not specified, the system chooses an ID.
  
  .PARAMETER SnapshotWWN
	WWN of the snapshot Virtual Volume. With no snapshotWWNspecified, a WWN is chosen automatically.
  
  .PARAMETER ReadWrite
	Optional.
	A True setting applies read-write status to the snapshot.
	A False setting applies read-only status to the snapshot.
	Overrides the readOnly and match settings for the snapshot.
  
  .PARAMETER Comment
	Specifies any additional information for the volume.
  
  .PARAMETER ReadOnly
	Specifies that the copied volumes are read-only. Do not combine with the match member.
  
  .PARAMETER Match
	By default, all snapshots are created read-write. Specifies the creation of snapshots that match the read-only or read-write setting of parent. Do not combine the readOnly and match options.
  
  .PARAMETER ExpirationHours
	Specifies the time relative to the current time that the copied volumes expire. Value is a positive integer with a range of 1–43,800 hours (1825 days).
  
  .PARAMETER RetentionHours
	Specifies the time relative to the current time that the copied volumes are retained. Value is a positive integer with a range of 1–43,800 hours (1825 days).
  
  .PARAMETER SkipBlock
	Occurs if the host IO is blocked while the snapshot is being created.
  
  .PARAMETER AddToSet
	The name of the volume set to which the system adds your created snapshots. If the volume set does not exist, it will be created.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : New-3PARVVListGroupSnapshot_WSAPI    
    LASTEDIT: 01/02/2018
    KEYWORDS: New-3PARVVListGroupSnapshot_WSAPI
   
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
      [System.String]
	  $SnapshotName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $SnapshotId,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $SnapshotWWN,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $ReadWrite,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Comment,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $ReadOnly,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $Match,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $ExpirationHours,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $RetentionHours,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $SkipBlock,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $AddToSet,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}	
	$VolumeGroupBody = @()
	$ParameterBody = @{}

    # Name parameter
    $body["action"] = 8	
   
    If ($VolumeName) 
	{
		$VName=@{}
		$VName["volumeName"] = "$($VolumeName)"	
		$VolumeGroupBody += $VName		
    }
	If ($SnapshotName) 
	{
		$snpName=@{}
		$snpName["snapshotName"] = "$($SnapshotName)"	
		$VolumeGroupBody += $snpName
    }
    If ($SnapshotId) 
	{
		$snpId=@{}
		$snpId["snapshotId"] = $SnapshotId	
		$VolumeGroupBody += $snpId
    }
	If ($SnapshotWWN) 
	{
		$snpwwn=@{}
		$snpwwn["SnapshotWWN"] = "$($SnapshotWWN)"	
		$VolumeGroupBody += $snpwwn
    }
    If ($ReadWrite) 
	{
		$rw=@{}
		$rw["readWrite"] = $ReadWrite	
		$VolumeGroupBody += $rw
    }
	
	if($VolumeGroupBody.Count -gt 0)
	{
		$ParameterBody["volumeGroup"] = $VolumeGroupBody 
	}
	
	If ($Comment) 
	{
          $ParameterBody["comment"] = "$($Comment)"
    }	
	If ($ReadOnly) 
	{
          $ParameterBody["readOnly"] = $ReadOnly
    }	
	If ($Match) 
	{
          $ParameterBody["match"] = $Match
    }	
	If ($ExpirationHours) 
	{
          $ParameterBody["expirationHours"] = $ExpirationHours
    }
	If ($RetentionHours) 
	{
          $ParameterBody["retentionHours"] = $RetentionHours
    }
	If ($SkipBlock) 
	{
          $ParameterBody["skipBlock"] = $SkipBlock
    }
	If ($AddToSet) 
	{
          $ParameterBody["addToSet"] = "$($AddToSet)"
    }
	
	if($ParameterBody.Count -gt 0)
	{
		$body["parameters"] = $ParameterBody 
	}
	
    $Result = $null
	
    #Request
	Write-DebugLog "Request: Request to New-3PARVVListGroupSnapshot_WSAPI : $SnapshotName (Invoke-3parWSAPI)." $Debug
		
    $Result = Invoke-3parWSAPI -uri '/volumes' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 300)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Group snapshots of a virtual volumes list : $SnapshotName created successfully" $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARVVListGroupSnapshot_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating group snapshots of a virtual volumes list : $SnapshotName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating group snapshots of a virtual volumes list : $SnapshotName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-3PARVVListGroupSnapshot_WSAPI

############################################################################################################################################
## FUNCTION New-3PARVVPhysicalCopy_WSAPI
############################################################################################################################################
Function New-3PARVVPhysicalCopy_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create a physical copy of a volume.
	
  .DESCRIPTION	
    This cmdlet (New-3PARVVPhysicalCopy_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-VvPhysicalCopy_WSAPI) instead.
  
    Create a physical copy of a volume.
    
  .EXAMPLE    
	New-3PARVVPhysicalCopy_WSAPI -VolumeName xyz -DestVolume Test1
    
  .EXAMPLE
    New-3PARVVPhysicalCopy_WSAPI -VolumeName xyz -DestVolume Test -DestCPG as_cpg
    
  .EXAMPLE
	New-3PARVVPhysicalCopy_WSAPI -VolumeName xyz -DestVolume Test -Online
    
  .EXAMPLE
	New-3PARVVPhysicalCopy_WSAPI -VolumeName xyz -DestVolume Test -WWN "60002AC0000000000101142300018F8D"
    
  .EXAMPLE
	New-3PARVVPhysicalCopy_WSAPI -VolumeName xyz -DestVolume Test -TPVV
    
  .EXAMPLE
	New-3PARVVPhysicalCopy_WSAPI -VolumeName xyz -DestVolume Test -SnapCPG as_cpg
    
  .EXAMPLE
	New-3PARVVPhysicalCopy_WSAPI -VolumeName xyz -DestVolume Test -SkipZero
    
  .EXAMPLE
	New-3PARVVPhysicalCopy_WSAPI -VolumeName xyz -DestVolume Test -Compression
    
  .EXAMPLE
	New-3PARVVPhysicalCopy_WSAPI -VolumeName xyz -DestVolume Test -SaveSnapshot
    
  .EXAMPLE
	New-3PARVVPhysicalCopy_WSAPI -VolumeName $val -DestVolume Test -Priority high
	
  .PARAMETER VolumeName
	The <VolumeName> parameter specifies the name of the volume to copy.
 
  .PARAMETER DestVolume
	Specifies the destination volume.
  
  .PARAMETER DestCPG
	Specifies the destination CPG for an online copy.
  
  .PARAMETER Online
	Enables (true) or disables (false) whether to perform the physical copy online. Defaults to false.
  
  .PARAMETER WWN
	Specifies the WWN of the online copy virtual volume.
  
  .PARAMETER TDVV
	Enables (true) or disables (false) whether the online copy is a TDVV. Defaults to false. tpvv and tdvv cannot be set to true at the same time.
  
  .PARAMETER Reduce
	Enables (true) or disables (false) a thinly deduplicated and compressed volume.
	
  .PARAMETER TPVV
	Enables (true) or disables (false) whether the online copy is a TPVV. Defaults to false. tpvv and tdvv cannot be set to true at the same time.
  
  .PARAMETER SnapCPG
	Specifies the snapshot CPG for an online copy.
	
  .PARAMETER SkipZero
	Enables (true) or disables (false) copying only allocated portions of the source VV from a thin provisioned source. Use only on a newly created destination, or if the destination was re-initialized to zero. Does not overwrite preexisting data on the destination VV to match the source VV unless the same offset is allocated in the source.
  
  .PARAMETER Compression
	For online copy only:
	Enables (true) or disables (false) compression of the created volume. Only tpvv or tdvv are compressed. Defaults to false.
  
  .PARAMETER SaveSnapshot
	Enables (true) or disables (false) saving the the snapshot of the source volume after completing the copy of the volume. Defaults to false
  
  .PARAMETER Priority
	Does not apply to online copy.
	HIGH : High priority.
	MED : Medium priority.
	LOW : Low priority.
  
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
 
  .Notes
    NAME    : New-3PARVVPhysicalCopy_WSAPI    
    LASTEDIT: 02/02/2018
    KEYWORDS: New-3PARVVPhysicalCopy_WSAPI
   
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
      [System.String]
	  $DestVolume,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $DestCPG,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $Online,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $WWN,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $TPVV,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $TDVV,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $Reduce,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $SnapCPG,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $SkipZero,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $Compression,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $SaveSnapshot,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Priority,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}	
	$ParameterBody = @{}

    # Name parameter
    $body["action"] = "createPhysicalCopy"

   
    If ($DestVolume) 
	{
          $ParameterBody["destVolume"] = "$($DestVolume)"
    }    
	If ($Online) 
	{
		$ParameterBody["online"] = $true
		If ($DestCPG) 
		{
		  $ParameterBody["destCPG"] = $DestCPG
		}
		else
		{
			return "Specifies the destination CPG for an online copy."
		}
    }
	
    If ($WWN) 
	{
          $ParameterBody["WWN"] = "$($WWN)"
    }
	If ($TPVV) 
	{
          $ParameterBody["tpvv"] = $true
    }
	If ($TDVV) 
	{
          $ParameterBody["tdvv"] = $true
    }
	If ($Reduce) 
	{
          $ParameterBody["reduce"] = $true
    }	
	If ($SnapCPG) 
	{
          $ParameterBody["snapCPG"] = "$($SnapCPG)"
    }
	If ($SkipZero) 
	{
          $ParameterBody["skipZero"] = $true
    }
	If ($Compression) 
	{
          $ParameterBody["compression"] = $true
    }
	If ($SaveSnapshot) 
	{
          $ParameterBody["saveSnapshot"] = $SaveSnapshot
    }
	If ($Priority) 
	{
		if($Priority.ToUpper() -eq "HIGH")
		{
			$ParameterBody["priority"] = 1
		}
		elseif($Priority.ToUpper() -eq "MED")
		{
			$ParameterBody["priority"] = 2
		}
		elseif($Priority.ToUpper() -eq "LOW")
		{
			$ParameterBody["priority"] = 3
		}
		else
		{
			return "Priority value is wrong : $Priority , value should be [HIGH | MED | LOW ]."
		}
          
    }
	
	if($ParameterBody.Count -gt 0)
	{
		$body["parameters"] = $ParameterBody 
	}

    $Result = $null
	
    #Request
	Write-DebugLog "Request: Request to New-3PARVVPhysicalCopy_WSAPI : $VolumeName (Invoke-3parWSAPI)." $Debug
	
	$uri = '/volumes/'+$VolumeName
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Physical copy of a volume: $VolumeName created successfully" $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARVVPhysicalCopy_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating Physical copy of a volume : $VolumeName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating Physical copy of a volume : $VolumeName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-3PARVVPhysicalCopy_WSAPI

############################################################################################################################################
## FUNCTION Reset-3PARPhysicalCopy_WSAPI
############################################################################################################################################
Function Reset-3PARPhysicalCopy_WSAPI 
{
  <#
  .SYNOPSIS
	Resynchronizing a physical copy to its parent volume
  
  .DESCRIPTION
    This cmdlet (Reset-3PARPhysicalCopy_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Reset-PhysicalCopy_WSAPI) instead.
  
	Resynchronizing a physical copy to its parent volume
        
  .EXAMPLE    
	Reset-3PARPhysicalCopy_WSAPI -VolumeName xxx
	Resynchronizing a physical copy to its parent volume
	
  .PARAMETER VolumeName 
	The <VolumeName> parameter specifies the name of the destination volume you want to resynchronize.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Reset-3PARPhysicalCopy_WSAPI    
    LASTEDIT: 02/02/2018
    KEYWORDS: Reset-3PARPhysicalCopy_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {  
	$body = @{}	
	
	$body["action"] = 2	
    
    $Result = $null	
	$uri = "/volumes/" + $VolumeName
	
    #Request
	Write-DebugLog "Request: Request to Reset-3PARPhysicalCopy_WSAPI : $VolumeName (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Resynchronize a physical copy to its parent volume : $VolumeName ." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Reset-3PARPhysicalCopy_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Resynchronizing a physical copy to its parent volume : $VolumeName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Resynchronizing a physical copy to its parent volume : $VolumeName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Reset-3PARPhysicalCopy_WSAPI

############################################################################################################################################
## FUNCTION Stop-3PARPhysicalCopy_WSAPI
############################################################################################################################################
Function Stop-3PARPhysicalCopy_WSAPI 
{
  <#
  .SYNOPSIS
	Stop a physical copy of given Volume
  
  .DESCRIPTION
    This cmdlet (Stop-3PARPhysicalCopy_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Stop-PhysicalCopy_WSAPI) instead.
  
	Stop a physical copy of given Volume
        
  .EXAMPLE    
	Stop-3PARPhysicalCopy_WSAPI -VolumeName xxx
	Stop a physical copy of given Volume 
	
  .PARAMETER VolumeName 
	The <VolumeName> parameter specifies the name of the destination volume you want to resynchronize.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Stop-3PARPhysicalCopy_WSAPI    
    LASTEDIT: 02/02/2018
    KEYWORDS: Stop-3PARPhysicalCopy_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {  
	$body = @{}	
	
	$body["action"] = 1	
    
    $Result = $null	
	$uri = "/volumes/" + $VolumeName
	
    #Request
	Write-DebugLog "Request: Request to Stop-3PARPhysicalCopy_WSAPI : $VolumeName (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Stop a physical copy of : $VolumeName ." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Stop-3PARPhysicalCopy_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While stopping a physical copy : $VolumeName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While stopping a physical copy : $VolumeName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Stop-3PARPhysicalCopy_WSAPI

############################################################################################################################################
## FUNCTION Move-3PARVirtualCopy_WSAPI
############################################################################################################################################
Function Move-3PARVirtualCopy_WSAPI 
{
  <#
  .SYNOPSIS
	To promote the changes from a virtual copy back onto the base volume, thereby overwriting the base volume with the virtual copy.
  
  .DESCRIPTION
    This cmdlet (Move-3PARVirtualCopy_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Move-VirtualCopy_WSAPI) instead.
  
	To promote the changes from a virtual copy back onto the base volume, thereby overwriting the base volume with the virtual copy.
        
  .EXAMPLE
	Move-3PARVirtualCopy_WSAPI -VirtualCopyName xyz
        
  .EXAMPLE	
	Move-3PARVirtualCopy_WSAPI -VirtualCopyName xyz -Online
        
  .EXAMPLE	
	Move-3PARVirtualCopy_WSAPI -VirtualCopyName xyz -Priority HIGH
        
  .EXAMPLE	
	Move-3PARVirtualCopy_WSAPI -VirtualCopyName xyz -AllowRemoteCopyParent
	
  .PARAMETER VirtualCopyName 
	The <virtual_copy_name> parameter specifies the name of the virtual copy to be promoted.
  
  .PARAMETER Online	
	Enables (true) or disables (false) executing the promote operation on an online volume. The default setting is false.
  
  .PARAMETER Priority
	Task priority.
	HIGH : High priority.
	MED : Medium priority.
	LOW : Low priority.
	
  .PARAMETER AllowRemoteCopyParent
	Allows the promote operation to proceed even if the RW parent volume is currently in a Remote Copy volume group, if that group has not been started. If the Remote Copy group has been started, this command fails.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Move-3PARVirtualCopy_WSAPI    
    LASTEDIT: 02/02/2018
    KEYWORDS: Move-3PARVirtualCopy_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VirtualCopyName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Online,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Priority,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AllowRemoteCopyParent,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {  
	$body = @{}	
	
	$body["action"] = 4
	
	if($Online)
	{
		$body["online"] = $true	
	}	
	if($Priority)
	{		
		if($Priority.ToUpper() -eq "HIGH")
		{
			$body["priority"] = 1		
		}
		elseif($Priority.ToUpper() -eq "MED")
		{
			$body["priority"] = 2		
		}
		elseif($Priority.ToUpper() -eq "LOW")
		{
			$body["priority"] = 3		
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Since -Priority $Priority in incorrect "
			Return "FAILURE : -Priority :- $Priority is an Incorrect Priority  [high | med | low]  can be used only . "
		}
		
	}
	if($AllowRemoteCopyParent)
	{
		$body["allowRemoteCopyParent"] = $true	
	}
    
    $Result = $null	
	$uri = "/volumes/" + $VirtualCopyName
	
    #Request
	Write-DebugLog "Request: Request to Move-3PARVirtualCopy_WSAPI : $VirtualCopyName (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	 
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Promoted a virtual copy : $VirtualCopyName ." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Move-3PARVirtualCopy_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Promoting a virtual copy : $VirtualCopyName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Promoting a virtual copy : $VirtualCopyName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Move-3PARVirtualCopy_WSAPI

############################################################################################################################################
## FUNCTION Move-3PARVVSetVirtualCopy_WSAPI
############################################################################################################################################
Function Move-3PARVVSetVirtualCopy_WSAPI 
{
  <#
  .SYNOPSIS
	To promote the changes from a vv set virtual copy back onto the base volume, thereby overwriting the base volume with the virtual copy.
  
  .DESCRIPTION
    This cmdlet (Move-3PARVVSetVirtualCopy_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Move-VvSetVirtualCopy_WSAPI) instead.
  
	To promote the changes from a vv set virtual copy back onto the base volume, thereby overwriting the base volume with the virtual copy.
        
  .EXAMPLE
	Move-3PARVVSetVirtualCopy_WSAPI
        
  .EXAMPLE	
	Move-3PARVVSetVirtualCopy_WSAPI -VVSetName xyz
        
  .EXAMPLE	
	Move-3PARVVSetVirtualCopy_WSAPI -VVSetName xyz -Online
        
  .EXAMPLE	
	Move-3PARVVSetVirtualCopy_WSAPI -VVSetName xyz -Priority HIGH
        
  .EXAMPLE	
	Move-3PARVVSetVirtualCopy_WSAPI -VVSetName xyz -AllowRemoteCopyParent
	
  .PARAMETER VirtualCopyName 
	The <virtual_copy_name> parameter specifies the name of the virtual copy to be promoted.
  
  .PARAMETER Online	
	Enables (true) or disables (false) executing the promote operation on an online volume. The default setting is false.
  
  .PARAMETER Priority
	Task priority.
	HIGH : High priority.
	MED : Medium priority.
	LOW : Low priority.
	
  .PARAMETER AllowRemoteCopyParent
	Allows the promote operation to proceed even if the RW parent volume is currently in a Remote Copy volume group, if that group has not been started. If the Remote Copy group has been started, this command fails.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Move-3PARVVSetVirtualCopy_WSAPI    
    LASTEDIT: 02/02/2018
    KEYWORDS: Move-3PARVVSetVirtualCopy_WSAPI
   
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
      [Switch]
	  $Online,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Priority,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AllowRemoteCopyParent,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {  
	$body = @{}	
	
	$body["action"] = 4
	
	if($Online)
	{
		$body["online"] = $true	
	}	
	if($Priority)
	{		
		if($Priority.ToUpper() -eq "HIGH")
		{
			$body["priority"] = 1		
		}
		elseif($Priority.ToUpper() -eq "MED")
		{
			$body["priority"] = 2		
		}
		elseif($Priority.ToUpper() -eq "LOW")
		{
			$body["priority"] = 3		
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Since -Priority $Priority in incorrect "
			Return "FAILURE : -Priority :- $Priority is an Incorrect Priority  [high | med | low]  can be used only . "
		}
		
	}
	if($AllowRemoteCopyParent)
	{
		$body["allowRemoteCopyParent"] = $true	
	}
    
    $Result = $null	
	$uri = "/volumesets/" + $VVSetName
	
    #Request
	Write-DebugLog "Request: Request to Move-3PARVVSetVirtualCopy_WSAPI : $VVSetName (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	 
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Promoted a VV-Set virtual copy : $VVSetName ." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Move-3PARVVSetVirtualCopy_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Promoting a VV-Set virtual copy : $VVSetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Promoting a VV-Set virtual copy : $VVSetName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Move-3PARVVSetVirtualCopy_WSAPI

############################################################################################################################################
## FUNCTION New-3PARVVSetSnapshot_WSAPI
############################################################################################################################################
Function New-3PARVVSetSnapshot_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create a VV-set snapshot.
	
  .DESCRIPTION	
    This cmdlet (New-3PARVVSetSnapshot_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-VvSetSnapshot_WSAPI) instead.
  
    Create a VV-set snapshot.
	Any user with the Super or Edit role or any role granted sv_create permission (for snapshots) can create a VV-set snapshot.
    
  .EXAMPLE    
	New-3PARVVSetSnapshot_WSAPI -VolumeSetName Test_delete -SnpVVName PERF_AIX38 -ID 110 -Comment Hello -readOnly -ExpirationHours 1 -RetentionHours 1
	
  .PARAMETER VolumeSetName
	The <VolumeSetName> parameter specifies the name of the VV set to copy.
  
  .PARAMETER SnpVVName
	Specifies a snapshot volume name up to 31 characters in length.
	For a snapshot of a volume set, use name patterns that are used to form the snapshot volume name. See, VV Name Patterns in the HPE 3PAR Command Line Interface Reference,available from the HPE Storage Information Library.
	  
  .PARAMETER ID
	Specifies the ID of the snapshot. If not specified, the system chooses the next available ID.
	Not applicable for VV-set snapshot creation.
	  
  .PARAMETER Comment
	Specifies any additional information up to 511 characters for the volume.
	  
  .PARAMETER readOnly
	true—Specifies that the copied volume is read-only. false—(default) The volume is read/write.
	  
  .PARAMETER ExpirationHours
	Specifies the relative time from the current time that the volume expires. Value is a positive integer and in the range of 1–43,800 hours, or 1825 days.
	  
  .PARAMETER RetentionHours
	Specifies the relative time from the current time that the volume will expire. Value is a positive integer and in the range of 1–43,800 hours, or 1825 days.
	  
  .PARAMETER AddToSet 
	The name of the volume set to which the system adds your created snapshots. If the volume set does not exist, it will be created.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : New-3PARVVSetSnapshot_WSAPI    
    LASTEDIT: 05/02/2018
    KEYWORDS: New-3PARVVSetSnapshot_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeSetName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $SnpVVName,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $ID,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Comment,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $readOnly,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $ExpirationHours,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $RetentionHours,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $AddToSet,

	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	  
	  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}	
	$ParameterBody = @{}

    # Name parameter
    $body["action"] = "createSnapshot"

   
    If ($SnpVVName) 
	{
		$ParameterBody["name"] = "$($SnpVVName)"
    }    
	If ($ID) 
	{
		$ParameterBody["id"] = $ID		
    }	
    If ($Comment) 
	{
		$ParameterBody["comment"] = "$($Comment)"
    }
	If ($ReadOnly) 
	{
		$ParameterBody["readOnly"] = $true
    }
	If ($ExpirationHours) 
	{
		$ParameterBody["expirationHours"] = $ExpirationHours
    }
	If ($RetentionHours) 
	{
		$ParameterBody["retentionHours"] = "$($RetentionHours)"
    }
	If ($AddToSet) 
	{
		$ParameterBody["addToSet"] = "$($AddToSet)"
    }
	if($ParameterBody.Count -gt 0)
	{
		$body["parameters"] = $ParameterBody 
	}
	
    $Result = $null	
    #Request
	Write-DebugLog "Request: Request to New-3PARVVSetSnapshot_WSAPI : $SnpVVName (Invoke-3parWSAPI)." $Debug	
	$uri = '/volumesets/'+$VolumeSetName
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: VV-set snapshot : $SnpVVName created successfully" $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARVVSetSnapshot_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating VV-set snapshot : $SnpVVName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating VV-set snapshot : $SnpVVName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-3PARVVSetSnapshot_WSAPI

############################################################################################################################################
## FUNCTION New-3PARVVSetPhysicalCopy_WSAPI
############################################################################################################################################
Function New-3PARVVSetPhysicalCopy_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create a VV-set snapshot.
	
  .DESCRIPTION
    This cmdlet (New-3PARVVSetPhysicalCopy_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-VvSetPhysicalCopy_WSAPI) instead.
  
    Create a VV-set snapshot.
	Any user with the Super or Edit role or any role granted sv_create permission (for snapshots) can create a VV-set snapshot.
    
  .EXAMPLE    
	New-3PARVVSetPhysicalCopy_WSAPI -VolumeSetName Test_delete -DestVolume PERF_AIX38 
	
  .PARAMETER VolumeSetName
	The <VolumeSetName> parameter specifies the name of the VV set to copy.
	
  .PARAMETER DestVolume
	Specifies the destination volume set.
  
  .PARAMETER SaveSnapshot
	Enables (true) or disables (false) whether to save the source volume snapshot after completing VV set copy.
  
  .PARAMETER Priority
	Task priority.
	HIGH High priority.
	MED Medium priority.
	LOW Low priority.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : New-3PARVVSetPhysicalCopy_WSAPI    
    LASTEDIT: 05/02/2018
    KEYWORDS: New-3PARVVSetPhysicalCopy_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeSetName,
	  
	  [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $DestVolume,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $SaveSnapshot,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Priority,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	  
	  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}	
	$ParameterBody = @{}

    # Name parameter
    $body["action"] = "createPhysicalCopy"

   
    If ($DestVolume) 
	{
		$ParameterBody["destVolume"] = "$($DestVolume)"
    }    
	If ($SaveSnapshot) 
	{
		$ParameterBody["saveSnapshot"] = $SaveSnapshot		
    }
	if($Priority)
	{		
		if($Priority -eq "HIGH")
		{
			$ParameterBody["priority"] = 1		
		}
		elseif($Priority -eq "MED")
		{
			$ParameterBody["priority"] = 2		
		}
		elseif($Priority -eq "LOW")
		{
			$ParameterBody["priority"] = 3		
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Since -Priority $Priority in incorrect "
			Return "FAILURE : -Priority :- $Priority is an Incorrect Priority  [high | med | low]  can be used only . "
		}
		
	}
	if($ParameterBody.Count -gt 0)
	{
		$body["parameters"] = $ParameterBody 
	}
	
    $Result = $null	
    #Request
	Write-DebugLog "Request: Request to New-3PARVVSetPhysicalCopy_WSAPI : $VolumeSetName (Invoke-3parWSAPI)." $Debug	
	$uri = '/volumesets/'+$VolumeSetName
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Physical copy of a VV set : $VolumeSetName created successfully" $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARVVSetPhysicalCopy_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating Physical copy of a VV set : $VolumeSetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating Physical copy of a VV set : $VolumeSetName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-3PARVVSetPhysicalCopy_WSAPI

############################################################################################################################################
## FUNCTION Reset-3PARVVSetPhysicalCopy_WSAPI
############################################################################################################################################
Function Reset-3PARVVSetPhysicalCopy_WSAPI 
{
  <#
  .SYNOPSIS
	Resynchronizing a VV set physical copy
  
  .DESCRIPTION
    This cmdlet (Reset-3PARVVSetPhysicalCopy_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Reset-VvSetPhysicalCopy_WSAPI) instead.
  
	Resynchronizing a VV set physical copy
        
  .EXAMPLE
    Reset-3PARVVSetPhysicalCopy_WSAPI -VolumeSetName xyz
         
  .EXAMPLE 
	Reset-3PARVVSetPhysicalCopy_WSAPI -VolumeSetName xxx -Priority HIGH
		
  .PARAMETER VolumeSetName 
	The <VolumeSetName> specifies the name of the destination VV set to resynchronize.
	
  .PARAMETER Priority
	Task priority.
	HIGH High priority.
	MED Medium priority.
	LOW Low priority.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Reset-3PARVVSetPhysicalCopy_WSAPI    
    LASTEDIT: 02/02/2018
    KEYWORDS: Reset-3PARVVSetPhysicalCopy_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeSetName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Priority,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {  
	$body = @{}	
	
	$body["action"] = 3
	
	if($Priority)
	{		
		if($Priority -eq "HIGH")
		{
			$body["priority"] = 1		
		}
		elseif($Priority -eq "MED")
		{
			$body["priority"] = 2		
		}
		elseif($Priority -eq "LOW")
		{
			$body["priority"] = 3		
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Since -Priority $Priority in incorrect "
			Return "FAILURE : -Priority :- $Priority is an Incorrect Priority  [high | med | low]  can be used only . "
		}
		
	}
    
    $Result = $null	
	$uri = "/volumesets/" + $VolumeSetName
	
    #Request
	Write-DebugLog "Request: Request to Reset-3PARVVSetPhysicalCopy_WSAPI : $VolumeSetName (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Resynchronize a VV set physical copy : $VolumeSetName ." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Reset-3PARVVSetPhysicalCopy_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Resynchronizing a VV set physical copy : $VolumeSetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Resynchronizing a VV set physical copy : $VolumeSetName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Reset-3PARVVSetPhysicalCopy_WSAPI

############################################################################################################################################
## FUNCTION Stop-3PARVVSetPhysicalCopy_WSAPI
############################################################################################################################################
Function Stop-3PARVVSetPhysicalCopy_WSAPI 
{
  <#
  .SYNOPSIS
	Stop a VV set physical copy
  
  .DESCRIPTION
    This cmdlet (Stop-3PARVVSetPhysicalCopy_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Stop-VvSetPhysicalCopy_WSAPI) instead.
  
	Stop a VV set physical copy
        
  .EXAMPLE
    Stop-3PARVVSetPhysicalCopy_WSAPI -VolumeSetName xxx
         
  .EXAMPLE 
	Stop-3PARVVSetPhysicalCopy_WSAPI -VolumeSetName xxx -Priority HIGH
	
  .PARAMETER VolumeSetName 
	The <VolumeSetName> specifies the name of the destination VV set to resynchronize.
	
  .PARAMETER Priority
	Task priority.
	HIGH High priority.
	MED Medium priority.
	LOW Low priority.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Stop-3PARVVSetPhysicalCopy_WSAPI    
    LASTEDIT: 02/02/2018
    KEYWORDS: Stop-3PARVVSetPhysicalCopy_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $VolumeSetName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Priority,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {  
	$body = @{}	
	
	$body["action"] = 4
	
	if($Priority)
	{		
		if($Priority -eq "HIGH")
		{
			$body["priority"] = 1		
		}
		elseif($Priority -eq "MED")
		{
			$body["priority"] = 2		
		}
		elseif($Priority -eq "LOW")
		{
			$body["priority"] = 3		
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Since -Priority $Priority in incorrect "
			Return "FAILURE : -Priority :- $Priority is an Incorrect Priority  [high | med | low]  can be used only . "
		}
		
	}
    
    $Result = $null	
	$uri = "/volumesets/" + $VolumeSetName
	
    #Request
	Write-DebugLog "Request: Request to Stop-3PARVVSetPhysicalCopy_WSAPI : $VolumeSetName (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	 
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Stop a VV set physical copy : $VolumeSetName ." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Stop-3PARVVSetPhysicalCopy_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Stopping a VV set physical copy : $VolumeSetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Stopping a VV set physical copy : $VolumeSetName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Stop-3PARVVSetPhysicalCopy_WSAPI

############################################################################################################################################
## FUNCTION Update-3PARVVOrVVSets_WSAPI
############################################################################################################################################
Function Update-3PARVVOrVVSets_WSAPI 
{
  <#      
  .SYNOPSIS	
	Update virtual copies or VV-sets
	
  .DESCRIPTION	
    This cmdlet (Update-3PARVVOrVVSets_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Update-VvOrVvSets_WSAPI) instead.
  
    Update virtual copies or VV-sets
	
  .EXAMPLE
	Update-3PARVVOrVVSets_WSAPI -VolumeSnapshotList "xxx,yyy,zzz" 
	Update virtual copies or VV-sets
	
  .EXAMPLE
	Update-3PARVVOrVVSets_WSAPI -VolumeSnapshotList "xxx,yyy,zzz" -ReadOnly $true/$false
	Update virtual copies or VV-sets
	
  .PARAMETER VolumeSnapshotList
	List one or more volume snapshots to update. If specifying a vvset, use the	following format
	set:vvset_name.
	
  .PARAMETER VolumeSnapshotList
	Specifies that if the virtual copy is read-write, the command updates the read-only parent volume also.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Update-3PARVVOrVVSets_WSAPI    
    LASTEDIT: 06/02/2018
    KEYWORDS: Update-3PARVVOrVVSets_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [String[]]
	  $VolumeSnapshotList,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $ReadOnly,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	  
	  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}	
	$ParameterBody = @{}

    # Name parameter
    $body["action"] = 7

   
    If ($VolumeSnapshotList) 
	{
		$ParameterBody["volumeSnapshotList"] = $VolumeSnapshotList
    }    
	If ($ReadOnly) 
	{
		$ParameterBody["readOnly"] = $ReadOnly		
    }
	
	if($ParameterBody.Count -gt 0)
	{
		$body["parameters"] = $ParameterBody 
	}
	
    $Result = $null	
    #Request
	Write-DebugLog "Request: Request to Update-3PARVVOrVVSets_WSAPI : $VolumeSnapshotList (Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri '/volumes/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Virtual copies or VV-sets : $VolumeSnapshotList successfully Updated." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Update-3PARVVOrVVSets_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Updating virtual copies or VV-sets : $VolumeSnapshotList " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Updating virtual copies or VV-sets : $VolumeSnapshotList " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Update-3PARVVOrVVSets_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARSystem_WSAPI
############################################################################################################################################
Function Get-3PARSystem_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Retrieve informations about the array.
  
  .DESCRIPTION
    This cmdlet (Get-3PARSystem_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-System_WSAPI) instead.
  
	Retrieve informations about the array.
        
  .EXAMPLE
	Get-3PARSystem_WSAPI
	Retrieve informations about the array.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command	
	
  .Notes
    NAME    : Get-3PARSystem_WSAPI   
    LASTEDIT: 06/02/2018
    KEYWORDS: Get-3PARSystem_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null	
	$dataPS = $null	
	
	#Request
	$Result = Invoke-3parWSAPI -uri '/system' -type 'GET' -WsapiConnection $WsapiConnection 
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = $Result.content | ConvertFrom-Json
	}
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS:Successfully Executed" $Info

		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARSystem_WSAPI" -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARSystem_WSAPI" $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARSystem_WSAPI

############################################################################################################################################
## FUNCTION Update-3PARSystem_WSAPI
############################################################################################################################################
Function Update-3PARSystem_WSAPI 
{
  <#
  .SYNOPSIS
	Update storage system parameters
  
  .DESCRIPTION
    This cmdlet (Update-3PARSystem_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Update-System_WSAPI) instead.
  
	Update storage system parameters
	You can set all of the system parameters in one request, but some updates might fail.
        
  .EXAMPLE
	Update-3PARSystem_WSAPI -RemoteSyslog $true
        
  .EXAMPLE
	Update-3PARSystem_WSAPI -remoteSyslogHost "0.0.0.0"
        
  .EXAMPLE	
	Update-3PARSystem_WSAPI -PortFailoverEnabled $true
        
  .EXAMPLE	
	Update-3PARSystem_WSAPI -DisableDedup $true
        
  .EXAMPLE	
	Update-3PARSystem_WSAPI -OverProvRatioLimit 3
        
  .EXAMPLE	
	Update-3PARSystem_WSAPI -AllowR5OnFCDrives $true
	
  .PARAMETER RemoteSyslog
	Enable (true) or disable (false) sending events to a remote system as syslog messages.
	
  .PARAMETER RemoteSyslogHost
	IP address of the systems to which events are sent as syslog messages.
	
  .PARAMETER RemoteSyslogSecurityHost
	Sets the hostname or IP address, and optionally the port, of the remote syslog servers to which security events are sent as syslog messages.

  .PARAMETER PortFailoverEnabled
	Enable (true) or disable (false) the automatic fail over of target ports to their designated partner ports.
	
  .PARAMETER FailoverMatchedSet
	Enable (true) or disable (false) the automatic fail over of matched-set VLUNs during a persistent port fail over. This does not affect host-see VLUNs, which are always failed over.
	
  .PARAMETER DisableDedup
	Enable or disable new write requests to TDVVs serviced by the system to be deduplicated.
	true – Disables deduplication
	false – Enables deduplication
	
  .PARAMETER DisableCompr
	Enable or disable the compression of all new write requests to the compressed VVs serviced by the system.
	True - The new writes are not compressed.
	False - The new writes are compressed.
	
  .PARAMETER OverProvRatioLimit
	The system, device types, and all CPGs are limited to the specified overprovisioning ratio.
	
  .PARAMETER OverProvRatioWarning
	An overprovisioning ratio, which when exceeded by the system, a device type, or a CPG, results in a warning alert.
	
  .PARAMETER AllowR5OnNLDrives
	Enable (true) or disable (false) support for RAID-5 on NL drives.
	
  .PARAMETER AllowR5OnFCDrives
	Enable (true) or disable (false) support for RAID-5 on FC drives.
	
  .PARAMETER ComplianceOfficerApproval
	Enable (true) or disable (false) compliance officer approval mode.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Update-3PARSystem_WSAPI    
    LASTEDIT: 07/02/2018
    KEYWORDS: Update-3PARSystem_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $RemoteSyslog,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $RemoteSyslogHost,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $RemoteSyslogSecurityHost,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $PortFailoverEnabled,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $FailoverMatchedSet,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $DisableDedup,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $DisableCompr,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $OverProvRatioLimit,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $OverProvRatioWarning,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $AllowR5OnNLDrives,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $AllowR5OnFCDrives,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [boolean]
	  $ComplianceOfficerApproval,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {  
	$body = @{}	
	$ObjMain=@{}	
	
	If ($RemoteSyslog) 
	{
		$Obj=@{}
		$Obj["remoteSyslog"] = $RemoteSyslog
		$ObjMain += $Obj				
    }
	If ($RemoteSyslogHost) 
	{
		$Obj=@{}
		$Obj["remoteSyslogHost"] = "$($RemoteSyslogHost)"
		$ObjMain += $Obj
    }
	If ($RemoteSyslogSecurityHost) 
	{
		$Obj=@{}
		$Obj["remoteSyslogSecurityHost"] = "$($RemoteSyslogSecurityHost)"
		$ObjMain += $Obj		
    }
	If ($PortFailoverEnabled) 
	{
		$Obj=@{}
		$Obj["portFailoverEnabled"] = $PortFailoverEnabled
		$ObjMain += $Obj			
    }
	If ($FailoverMatchedSet) 
	{
		$Obj=@{}
		$Obj["failoverMatchedSet"] = $FailoverMatchedSet
		$ObjMain += $Obj				
    }
	If ($DisableDedup) 
	{
		$Obj=@{}
		$Obj["disableDedup"] = $DisableDedup
		$ObjMain += $Obj				
    }
	If ($DisableCompr) 
	{
		$Obj=@{}
		$Obj["disableCompr"] = $DisableCompr
		$ObjMain += $Obj				
    }
	If ($OverProvRatioLimit) 
	{
		$Obj=@{}
		$Obj["overProvRatioLimit"] = $OverProvRatioLimit
		$ObjMain += $Obj				
    }
	If ($OverProvRatioWarning) 
	{
		$Obj=@{}
		$Obj["overProvRatioWarning"] = $OverProvRatioWarning	
		$ObjMain += $Obj			
    }
	If ($AllowR5OnNLDrives) 
	{
		$Obj=@{}
		$Obj["allowR5OnNLDrives"] = $AllowR5OnNLDrives	
		$ObjMain += $Obj				
    }
	If ($AllowR5OnFCDrives) 
	{
		$Obj=@{}
		$Obj["allowR5OnFCDrives"] = $AllowR5OnFCDrives	
		$ObjMain += $Obj				
    }
	If ($ComplianceOfficerApproval) 
	{
		$Obj=@{}
		$Obj["complianceOfficerApproval"] = $ComplianceOfficerApproval	
		$ObjMain += $Obj				
    }
	
	if($ObjMain.Count -gt 0)
	{
		$body["parameters"] = $ObjMain 
	}	
    
    $Result = $null
    #Request
	Write-DebugLog "Request: Request to Update-3PARSystem_WSAPI (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri '/system' -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Update storage system parameters." $Info
				
		# Results		
		Get-3PARSystem_WSAPI		
		Write-DebugLog "End: Update-3PARSystem_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Updating storage system parameters." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Updating storage system parameters." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Update-3PARSystem_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARVersion_WSAPI
############################################################################################################################################
Function Get-3PARVersion_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get version information.
  
  .DESCRIPTION
    This cmdlet (Get-3PARVersion_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-Version_WSAPI) instead.
  
	Get version information.
        
  .EXAMPLE
	Get-3PARVersion_WSAPI
	Get version information.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARVersion_WSAPI   
    LASTEDIT: 07/02/2018
    KEYWORDS: Get-3PARVersion_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )
  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null	
	$dataPS = $null	
	
	$ip = $WsapiConnection.IPAddress
	$key = $WsapiConnection.Key
	$arrtyp = $global:ArrayT
	
	$APIurl = $Null
	
	if($arrtyp -eq "3par")
	{
		#$APIurl = "https://$($ArrayFQDNorIPAddress):8080/api/v1"
		$APIurl = 'https://'+$ip+':8080/api'		
	}
	Elseif($arrtyp -eq "Primera")
	{
		#$APIurl = "https://$($ArrayFQDNorIPAddress):443/api/v1"
		$APIurl = 'https://'+$ip+':443/api'				
	}
	else
	{
		return "Array type is Null."
	}	
	
    #Construct header
	Write-DebugLog "Running: Constructing header." $Debug
	$headers = @{}
    $headers["Accept"] = "application/json"
    $headers["Accept-Language"] = "en"
    $headers["Content-Type"] = "application/json"
    $headers["X-HP3PAR-WSAPI-SessionKey"] = $key
	
	#Request	
	if ($PSEdition -eq 'Core')
	{				
		$Result = Invoke-WebRequest -Uri "$APIurl" -Headers $headers -Method GET -UseBasicParsing -SkipCertificateCheck
	} 
	else 
	{				
		$Result = Invoke-WebRequest -Uri "$APIurl" -Headers $headers -Method GET -UseBasicParsing 
	}
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = $Result.content | ConvertFrom-Json
	}
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS:Successfully Executed" $Info

		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARVersion_WSAPI" -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARVersion_WSAPI" $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARVersion_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARWSAPIConfigInfo
############################################################################################################################################
Function Get-3PARWSAPIConfigInfo 
{
  <#
   
  .SYNOPSIS	
	Get Getting WSAPI configuration information
  
  .DESCRIPTION
    This cmdlet (Get-3PARWSAPIConfigInfo) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-WSAPIConfigInfo) instead.
  
	Get Getting WSAPI configuration information
        
  .EXAMPLE
	Get-3PARWSAPIConfigInfo
	Get Getting WSAPI configuration information

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command	

  .Notes
    NAME    : Get-3PARWSAPIConfigInfo   
    LASTEDIT: 07/02/2018
    KEYWORDS: Get-3PARWSAPIConfigInfo
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null	
	$dataPS = $null	
	
	#Request
	$Result = Invoke-3parWSAPI -uri '/wsapiconfiguration' -type 'GET' -WsapiConnection $WsapiConnection
	if($Result.StatusCode -eq 200)
	{
		$dataPS = $Result.content | ConvertFrom-Json
	}
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS:Successfully Executed" $Info

		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARWSAPIConfigInfo" -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARWSAPIConfigInfo" $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARWSAPIConfigInfo

############################################################################################################################################
## FUNCTION Get-3PARTask_WSAPI
############################################################################################################################################
Function Get-3PARTask_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get the status of all or given tasks
  
  .DESCRIPTION
    This cmdlet (Get-3PARTask_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-Task_WSAPI) instead.
  
	Get the status of all or given tasks
        
  .EXAMPLE
	Get-3PARTask_WSAPI
	Get the status of all tasks
	
  .EXAMPLE
	Get-3PARTask_WSAPI -TaskID 101
	Get the status of given tasks
	
  .PARAMETER TaskID	
    Task ID

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARTask_WSAPI   
    LASTEDIT: 07/02/2018
    KEYWORDS: Get-3PARTask_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $TaskID,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null	
	
	#Build uri
	if($TaskID)
	{
		$uri = '/tasks/'+$TaskID
		#Request
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/tasks' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARTask_WSAPI Successfully Executed" $Info
		
		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARTask_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARTask_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARTask_WSAPI

############################################################################################################################################
## FUNCTION Stop-3PAROngoingTask_WSAPI
############################################################################################################################################
Function Stop-3PAROngoingTask_WSAPI 
{
  <#
  .SYNOPSIS
	Cancels the ongoing task.
  
  .DESCRIPTION
    This cmdlet (Stop-3PAROngoingTask_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Stop-OngoingTask_WSAPI) instead.
  
	Cancels the ongoing task.
        
  .EXAMPLE
	Stop-3PAROngoingTask_WSAPI -TaskID 1
	
  .PARAMETER TaskID
	Task id.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Stop-3PAROngoingTask_WSAPI    
    LASTEDIT: 08/02/2018
    KEYWORDS: Stop-3PAROngoingTask_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [System.String]
	  $TaskID,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {  
	$body = @{}	
	$body["action"] = 4
	
    $Result = $null	
	$uri = "/tasks/" + $TaskID
	
    #Request
	Write-DebugLog "Request: Request to Stop-3PAROngoingTask_WSAPI : $TaskID (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Cancels the ongoing task : $TaskID ." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Stop-3PAROngoingTask_WSAPI." $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Cancelling the ongoing task : $TaskID " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Cancelling the ongoing task : $TaskID " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Stop-3PAROngoingTask_WSAPI

############################################################################################################################################
## FUNCTION Set-3PARFlashCache_WSAPI
############################################################################################################################################
Function Set-3PARFlashCache_WSAPI 
{
  <#
  .SYNOPSIS
	Setting Flash Cache policy
  
  .DESCRIPTION
    This cmdlet (Set-3PARFlashCache_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Set-FlashCache_WSAPI) instead.
  
	Setting Flash Cache policy
        
  .EXAMPLE
	Set-3PARFlashCache_WSAPI -Enable
	Enable Flash Cache policy
	
  .EXAMPLE
	Set-3PARFlashCache_WSAPI -Disable
	Disable Flash Cache policy
	
  .PARAMETER Enable
	Enable Flash Cache policy
	
  .PARAMETER Disable
	Disable Flash Cache policy

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Set-3PARFlashCache_WSAPI    
    LASTEDIT: 08/02/2018
    KEYWORDS: Set-3PARFlashCache_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $Enable,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [switch]
	  $Disable,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {  
	$body = @{}	
	
	If ($Enable) 
	{
		$body["flashCachePolicy"] = 1	
    }
	elseIf ($Disable) 
	{
		$body["flashCachePolicy"] = 2	
    }
	else
	{
		return "Please Select at-list any one from [Enable Or Disable]"
	}
	
	
    $Result = $null	
	
    #Request
	Write-DebugLog "Request: Request to Set-3PARFlashCache_WSAPI (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri '/system' -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Set Flash Cache policy." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Set-3PARFlashCache_WSAPI." $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Setting Flash Cache policy." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Setting Flash Cache policy." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Set-3PARFlashCache_WSAPI

############################################################################################################################################
## FUNCTION New-3PARRCopyGroup_WSAPI
############################################################################################################################################
Function New-3PARRCopyGroup_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create a Remote Copy group
	
  .DESCRIPTION	
    This cmdlet (New-3PARRCopyGroup_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-RCopyGroup_WSAPI) instead.
  
    Create a Remote Copy group
	
  .EXAMPLE
	New-3PARRCopyGroup_WSAPI -RcgName xxx -TargetName xxx -Mode SYNC
	
  .EXAMPLE	
	New-3PARRCopyGroup_WSAPI -RcgName xxx -TargetName xxx -Mode PERIODIC -Domain xxx
	
  .EXAMPLE	
	New-3PARRCopyGroup_WSAPI -RcgName xxx -TargetName xxx -Mode ASYNC -UserCPG xxx -LocalUserCPG xxx -SnapCPG xxx -LocalSnapCPG xxx
	
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
    NAME    : New-3PARRCopyGroup_WSAPI    
    LASTEDIT: 08/02/2018
    KEYWORDS: New-3PARRCopyGroup_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to New-3PARRCopyGroup_WSAPI : $RcgName (Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri '/remotecopygroups' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Remote Copy group : $RcgName created successfully." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARRCopyGroup_WSAPI" $Debug
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

}#END New-3PARRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Start-3PARRCopyGroup_WSAPI
############################################################################################################################################
Function Start-3PARRCopyGroup_WSAPI 
{
  <#
  .SYNOPSIS
	Starting a Remote Copy group.
  
  .DESCRIPTION
    This cmdlet (Start-3PARRCopyGroup_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Start-RCopyGroup_WSAPI) instead.
  
	Starting a Remote Copy group.
        
  .EXAMPLE
	Start-3PARRCopyGroup_WSAPI -GroupName xxx
	Starting a Remote Copy group.
        
  .EXAMPLE	
	Start-3PARRCopyGroup_WSAPI -GroupName xxx -TargetName xxx
        
  .EXAMPLE	
	Start-3PARRCopyGroup_WSAPI -GroupName xxx -SkipInitialSync
	
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
    NAME    : Start-3PARRCopyGroup_WSAPI    
    LASTEDIT: 12/02/2018
    KEYWORDS: Start-3PARRCopyGroup_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Start-3PARRCopyGroup_WSAPI (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Start a Remote Copy group." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Start-3PARRCopyGroup_WSAPI." $Debug
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

}#END Start-3PARRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Stop-3PARRCopyGroup_WSAPI
############################################################################################################################################
Function Stop-3PARRCopyGroup_WSAPI 
{
  <#
  .SYNOPSIS
	Stop a Remote Copy group.
  
  .DESCRIPTION
    This cmdlet (Stop-3PARRCopyGroup_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Stop-RCopyGroup_WSAPI) instead.
  
	Stop a Remote Copy group.
        
  .EXAMPLE
	Stop-3PARRCopyGroup_WSAPI -GroupName xxx
	Stop a Remote Copy group.
        
  .EXAMPLE	
	Stop-3PARRCopyGroup_WSAPI -GroupName xxx -TargetName xxx 
        
  .EXAMPLE	
	Stop-3PARRCopyGroup_WSAPI -GroupName xxx -NoSnapshot
	
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
    NAME    : Stop-3PARRCopyGroup_WSAPI    
    LASTEDIT: 12/02/2018
    KEYWORDS: Stop-3PARRCopyGroup_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Stop-3PARRCopyGroup_WSAPI (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Stop a Remote Copy group." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Stop-3PARRCopyGroup_WSAPI." $Debug
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

}#END Stop-3PARRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Sync-3PARRCopyGroup_WSAPI
############################################################################################################################################
Function Sync-3PARRCopyGroup_WSAPI 
{
  <#
  .SYNOPSIS
	Synchronize a Remote Copy group.
  
  .DESCRIPTION
    This cmdlet (Sync-3PARRCopyGroup_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Sync-RCopyGroup_WSAPI) instead.
  
	Synchronize a Remote Copy group.
        
  .EXAMPLE
	Sync-3PARRCopyGroup_WSAPI -GroupName xxx
	Synchronize a Remote Copy group.
        
  .EXAMPLE	
	Sync-3PARRCopyGroup_WSAPI -GroupName xxx -NoResyncSnapshot
	        
  .EXAMPLE
	Sync-3PARRCopyGroup_WSAPI -GroupName xxx -TargetName xxx
	        
  .EXAMPLE
	Sync-3PARRCopyGroup_WSAPI -GroupName xxx -TargetName xxx -NoResyncSnapshot
	        
  .EXAMPLE
	Sync-3PARRCopyGroup_WSAPI -GroupName xxx -FullSync
	        
  .EXAMPLE
	Sync-3PARRCopyGroup_WSAPI -GroupName xxx -TargetName xxx -NoResyncSnapshot -FullSync
	
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
    NAME    : Sync-3PARRCopyGroup_WSAPI    
    LASTEDIT: 12/02/2018
    KEYWORDS: Sync-3PARRCopyGroup_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Sync-3PARRCopyGroup_WSAPI (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Synchronize a Remote Copy groupp." $Info
				
		# Results		
		return $Result		
		Write-DebugLog "End: Sync-3PARRCopyGroup_WSAPI." $Debug
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

}#END Sync-3PARRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARRCopyGroup_WSAPI
############################################################################################################################################
Function Remove-3PARRCopyGroup_WSAPI
 {
  <#
  .SYNOPSIS
	Remove a Remote Copy group.
  
  .DESCRIPTION
    This cmdlet (Remove-3PARRCopyGroup_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-RCopyGroup_WSAPI) instead.
  
	Remove a Remote Copy group.
        
  .EXAMPLE    
	Remove-3PARRCopyGroup_WSAPI -GroupName xxx
	
  .PARAMETER GroupName 
	Group Name.
	
  .PARAMETER KeepSnap 
	To remove a Remote Copy group with the option of retaining the local volume resynchronization snapshot
	The parameter uses one of the following, case-sensitive values:
	• keepSnap=true
	• keepSnap=false

  .EXAMPLE    
	Remove-3PARRCopyGroup_WSAPI -GroupName xxx -KeepSnap $true 

  .EXAMPLE    
	Remove-3PARRCopyGroup_WSAPI -GroupName xxx -KeepSnap $false

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-3PARRCopyGroup_WSAPI     
    LASTEDIT: 12/02/2018
    KEYWORDS: Remove-3PARRCopyGroup_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {    
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-3PARRCopyGroup_WSAPI." $Debug
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
	Write-DebugLog "Request: Request to Remove-3PARRCopyGroup_WSAPI : $GroupName (Invoke-3parWSAPI)." $Debug
	$Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 202)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Remove a Remote Copy group:$GroupName successfully remove" $Info
		Write-DebugLog "End: Remove-3PARRCopyGroup_WSAPI" $Debug
		
		return ""
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing a Remote Copy group : $GroupName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : Removing a Remote Copy group : $GroupName " $Info
		Write-DebugLog "End: Remove-3PARRCopyGroup_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-3PARRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Update-3PARRCopyGroup_WSAPI
############################################################################################################################################
Function Update-3PARRCopyGroup_WSAPI 
{
  <#
  .SYNOPSIS
	Modify a Remote Copy group
  
  .DESCRIPTION
    This cmdlet (Update-3PARRCopyGroup_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Update-RCopyGroup_WSAPI) instead.
  
	Modify a Remote Copy group.
        
  .EXAMPLE
	Update-3PARRCopyGroup_WSAPI -GroupName xxx -SyncPeriod 301 -Mode ASYNC
	
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
    NAME    : Update-3PARRCopyGroup_WSAPI    
    LASTEDIT: 12/02/2018
    KEYWORDS: Update-3PARRCopyGroup_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Update-3PARRCopyGroup_WSAPI (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Update Remote Copy group." $Info
				
		# Results		
		Get-3PARSystem_WSAPI		
		Write-DebugLog "End: Update-3PARRCopyGroup_WSAPI" $Debug
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

}#END Update-3PARRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Update-3PARRCopyGroupTarget_WSAPI
############################################################################################################################################
Function Update-3PARRCopyGroupTarget_WSAPI 
{
  <#
  .SYNOPSIS
	Modifying a Remote Copy group target.
  
  .DESCRIPTION
    This cmdlet (Update-3PARRCopyGroupTarget_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Update-RCopyGroupTarget_WSAPI) instead.
  
	Modifying a Remote Copy group target.
        
  .EXAMPLE
	Update-3PARRCopyGroupTarget_WSAPI -GroupName xxx -TargetName xxx -Mode SYNC 
	
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
    NAME    : Update-3PARRCopyGroupTarget_WSAPI    
    LASTEDIT: 01/08/2018
    KEYWORDS: Update-3PARRCopyGroupTarget_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Update-3PARRCopyGroupTarget_WSAPI (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Update Remote Copy group target." $Info
				
		# Results		
		Get-3PARSystem_WSAPI		
		Write-DebugLog "End: Update-3PARRCopyGroupTarget_WSAPI" $Debug
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

}#END Update-3PARRCopyGroupTarget_WSAPI

############################################################################################################################################
## FUNCTION Restore-3PARRCopyGroup_WSAPI
############################################################################################################################################
Function Restore-3PARRCopyGroup_WSAPI 
{
  <#      
  .SYNOPSIS	
	Recovering a Remote Copy group
	
  .DESCRIPTION	
    This cmdlet (Restore-3PARRCopyGroup_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Restore-RCopyGroup_WSAPI) instead.
  
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
    NAME    : Restore-3PARRCopyGroup_WSAPI    
    LASTEDIT: 13/02/2018
    KEYWORDS: Restore-3PARRCopyGroup_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Restore-3PARRCopyGroup_WSAPI : $GroupName (Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Remote Copy group : $GroupName successfully Recover." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Restore-3PARRCopyGroup_WSAPI" $Debug
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

}#END Restore-3PARRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Add-3PARVVToRCopyGroup_WSAPI
############################################################################################################################################
Function Add-3PARVVToRCopyGroup_WSAPI 
{
  <#      
  .SYNOPSIS	
	Admit a volume into a Remote Copy group
	
  .DESCRIPTION	
    This cmdlet (Add-3PARVVToRCopyGroup_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Add-VvToRCopyGroup_WSAPI) instead.
  
    Admit a volume into a Remote Copy group
	
  .EXAMPLE	
	Add-3PARVVToRCopyGroup_WSAPI -GroupName xxx -VolumeName xxx -TargetName xxx -SecVolumeName xxx
	
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
    NAME    : Add-3PARVVToRCopyGroup_WSAPI    
    LASTEDIT: 13/02/2018
    KEYWORDS: Add-3PARVVToRCopyGroup_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Add-3PARVVToRCopyGroup_WSAPI : $VolumeName (Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Volume into a Remote Copy group : $VolumeName successfully Admitted." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Add-3PARVVToRCopyGroup_WSAPI" $Debug
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

}#END Add-3PARVVToRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARVVFromRCopyGroup_WSAPI
############################################################################################################################################
Function Remove-3PARVVFromRCopyGroup_WSAPI 
{
  <#      
  .SYNOPSIS	
	Dismiss a volume from a Remote Copy group
	
  .DESCRIPTION	
    This cmdlet (Remove-3PARVVFromRCopyGroup_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-VvFromRCopyGroup_WSAPI) instead.
  
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
    NAME    : Remove-3PARVVFromRCopyGroup_WSAPI    
    LASTEDIT: 13/02/2018
    KEYWORDS: Remove-3PARVVFromRCopyGroup_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Remove-3PARVVFromRCopyGroup_WSAPI : $VolumeName (Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Volume from a Remote Copy group : $VolumeName successfully Remove." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-3PARVVFromRCopyGroup_WSAPI" $Debug
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

}#END Remove-3PARVVFromRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION New-3PARRCopyTarget_WSAPI
############################################################################################################################################
Function New-3PARRCopyTarget_WSAPI 
{
  <#      
  .SYNOPSIS	
	Creating a Remote Copy target
	
  .DESCRIPTION
    This cmdlet (New-3PARRCopyTarget_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-RCopyTarget_WSAPI) instead.
  
    Creating a Remote Copy target
	
  .EXAMPLE	
	New-3PARRCopyTarget_WSAPI -TargetName xxx -IP
	
  .EXAMPLE	
	New-3PARRCopyTarget_WSAPI -TargetName xxx  -NodeWWN xxx -FC
	
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
    NAME    : New-3PARRCopyTarget_WSAPI    
    LASTEDIT: 14/02/2018
    KEYWORDS: New-3PARRCopyTarget_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to New-3PARRCopyTarget_WSAPI : $TargetName (Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri '/remotecopytargets' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Remote Copy Target : $TargetName created successfully." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARRCopyTarget_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating a Remote Copy target : $TargetName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating a Remote Copy target : $TargetName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-3PARRCopyTarget_WSAPI

############################################################################################################################################
## FUNCTION Update-3PARRCopyTarget_WSAPI
############################################################################################################################################
Function Update-3PARRCopyTarget_WSAPI 
{
  <#
  .SYNOPSIS
	Modify a Remote Copy Target
  
  .DESCRIPTION
    This cmdlet (Update-3PARRCopyTarget_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Update-RCopyTarget_WSAPI) instead.
  
	Modify a Remote Copy Target.
        
  .EXAMPLE
	Update-3PARRCopyTarget_WSAPI -TargetName xxx
        
  .EXAMPLE
	Update-3PARRCopyTarget_WSAPI -TargetName xxx -MirrorConfig $true
	
  .PARAMETER TargetName
	The <target_name> parameter corresponds to the name of the Remote Copy target you want to modify

  .PARAMETER MirrorConfig
	Enables (true) or disables (false) the duplication of all configurations involving the specified target.
	Defaults to true.
	Use false to allow recovery from an unusual error condition only, and only after consulting your Hewlett Packard Enterprise representative.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Update-3PARRCopyTarget_WSAPI    
    LASTEDIT: 14/02/2018
    KEYWORDS: Update-3PARRCopyTarget_WSAPI
   
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
		Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Update-3PARRCopyTarget_WSAPI (Invoke-3parWSAPI)." $Debug
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Update Remote Copy Target / Target Name : $TargetName." $Info
				
		# Results			
		Write-DebugLog "End: Update-3PARRCopyTarget_WSAPI" $Debug
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

}#END Update-3PARRCopyTarget_WSAPI

############################################################################################################################################
## FUNCTION Add-3PARTargetToRCopyGroup_WSAPI
############################################################################################################################################
Function Add-3PARTargetToRCopyGroup_WSAPI 
{
  <#      
  .SYNOPSIS	
	Admitting a target into a Remote Copy group
	
  .DESCRIPTION
    This cmdlet (Add-3PARTargetToRCopyGroup_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Add-TargetToRCopyGroup_WSAPI) instead.
  
    Admitting a target into a Remote Copy group
	
  .EXAMPLE	
	Add-3PARTargetToRCopyGroup_WSAPI -GroupName xxx -TargetName xxx
	
  .EXAMPLE	
	Add-3PARTargetToRCopyGroup_WSAPI -GroupName xxx -TargetName xxx -Mode xxx
	
  .EXAMPLE	
	Add-3PARTargetToRCopyGroup_WSAPI -GroupName xxx -TargetName xxx -Mode xxx -LocalVolumeName xxx -RemoteVolumeName xxx
		
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
    NAME    : Add-3PARTargetToRCopyGroup_WSAPI    
    LASTEDIT: 14/02/2018
    KEYWORDS: Add-3PARTargetToRCopyGroup_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Add-3PARTargetToRCopyGroup_WSAPI : TargetName = $TargetName / GroupName = $GroupName(Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Admitted a target into a Remote Copy group : TargetName = $TargetName / GroupName = $GroupName." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Add-3PARTargetToRCopyGroup_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While admitting a target into a Remote Copy group : TargetName = $TargetName / GroupName = $GroupName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While admitting a target into a Remote Copy group : TargetName = $TargetName / GroupName = $GroupName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Add-3PARTargetToRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARTargetFromRCopyGroup_WSAPI
############################################################################################################################################
Function Remove-3PARTargetFromRCopyGroup_WSAPI 
{
  <#      
  .SYNOPSIS	
	Remove a target from a Remote Copy group
	
  .DESCRIPTION	
    This cmdlet (Remove-3PARTargetFromRCopyGroup_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-TargetFromRCopyGroup_WSAPI) instead.
  
    Remove a target from a Remote Copy group
	
  .EXAMPLE	
	Remove-3PARTargetFromRCopyGroup_WSAPI
	
  .PARAMETER GroupName
	Remote Copy group Name.
  
  .PARAMETER TargetName
	Target Name to be removed.  

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Remove-3PARTargetFromRCopyGroup_WSAPI    
    LASTEDIT: 14/02/2018
    KEYWORDS: Remove-3PARTargetFromRCopyGroup_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {    
    $Result = $null
	$uri = "/remotecopygroups/"+$GroupName+"/targets/"+$TargetName
	
    #Request
	Write-DebugLog "Request: Request to Remove-3PARTargetFromRCopyGroup_WSAPI : TargetName = $TargetName / GroupName = $GroupName(Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Remove a target from a Remote Copy group : TargetName = $TargetName / GroupName = $GroupName." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-3PARTargetFromRCopyGroup_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While removing a target from a Remote Copy group : TargetName = $TargetName / GroupName = $GroupName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While removing a target from a Remote Copy group : TargetName = $TargetName / GroupName = $GroupName " $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Remove-3PARTargetFromRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION New-3PARSnapRCGroupVV_WSAPI
############################################################################################################################################
Function New-3PARSnapRCGroupVV_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create coordinated snapshots across all Remote Copy group volumes.
	
  .DESCRIPTION
    This cmdlet (New-3PARSnapRCGroupVV_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-SnapRcGroupVv_WSAPI) instead.
  
    Create coordinated snapshots across all Remote Copy group volumes.
	
  .EXAMPLE	
	New-3PARSnapRCGroupVV_WSAPI -GroupName xxx -NewVvNmae xxx -Comment "Hello"
	
  .EXAMPLE	
	New-3PARSnapRCGroupVV_WSAPI -GroupName xxx -NewVvNmae xxx -VolumeName Test -Comment "Hello"
	
  .EXAMPLE	
	New-3PARSnapRCGroupVV_WSAPI -GroupName xxx -NewVvNmae xxx -Comment "Hello" -RetentionHours 1
	
  .EXAMPLE	
	New-3PARSnapRCGroupVV_WSAPI -GroupName xxx -NewVvNmae xxx -Comment "Hello" -VolumeName Test -RetentionHours 1
	
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
    NAME    : New-3PARSnapRCGroupVV_WSAPI    
    LASTEDIT: 15/02/2018
    KEYWORDS: New-3PARSnapRCGroupVV_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to New-3PARSnapRCGroupVV_WSAPI(Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Create coordinated snapshots across all Remote Copy group volumes." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARSnapRCGroupVV_WSAPI" $Debug
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

}#END New-3PARSnapRCGroupVV_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARRCopyInfo_WSAPI
############################################################################################################################################
Function Get-3PARRCopyInfo_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get overall Remote Copy information
  
  .DESCRIPTION
    This cmdlet (Get-3PARRCopyInfo_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-RCopyInfo_WSAPI) instead.
  
	Get overall Remote Copy information
        
  .EXAMPLE
	Get-3PARRCopyInfo_WSAPI
	Get overall Remote Copy information

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARRCopyInfo_WSAPI   
    LASTEDIT: 15/02/2018
    KEYWORDS: Get-3PARRCopyInfo_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	
	#Request
	$Result = Invoke-3parWSAPI -uri '/remotecopy' -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = $Result.content | ConvertFrom-Json
	
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-3PARRCopyInfo_WSAPI Successfully Executed" $Info
		
		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARRCopyInfo_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARRCopyInfo_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARRCopyInfo_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARRCopyTarget_WSAPI
############################################################################################################################################
Function Get-3PARRCopyTarget_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single Remote Copy targets
  
  .DESCRIPTION
    This cmdlet (Get-3PARRCopyTarget_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-RCopyTarget_WSAPI) instead.
  
	Get all or single Remote Copy targets
        
  .EXAMPLE
	Get-3PARRCopyTarget_WSAPI

  .EXAMPLE
	Get-3PARRCopyTarget_WSAPI -TargetName xxx	
	
  .PARAMETER TargetName	
    Remote Copy Target Name

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARRCopyTarget_WSAPI   
    LASTEDIT: 15/02/2018
    KEYWORDS: Get-3PARRCopyTarget_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
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
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/remotecopytargets' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARRCopyTarget_WSAPI Successfully Executed" $Info
		
		return $dataPS
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARRCopyTarget_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARRCopyTarget_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARRCopyTarget_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARRCopyGroup_WSAPI
############################################################################################################################################
Function Get-3PARRCopyGroup_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single Remote Copy Group
  
  .DESCRIPTION
    This cmdlet (Get-3PARRCopyGroup_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-RCopyGroup_WSAPI) instead.
  
	Get all or single Remote Copy Group
        
  .EXAMPLE
	Get-3PARRCopyGroup_WSAPI
	Get List of Groups
	
  .EXAMPLE
	Get-3PARRCopyGroup_WSAPI -GroupName XXX
	Get a single Groups of given name

  .EXAMPLE
	Get-3PARRCopyGroup_WSAPI -GroupName XXX*
	Get a single or list of Groups of given name like or match the words
	
  .EXAMPLE
	Get-3PARRCopyGroup_WSAPI -GroupName "XXX,YYY,ZZZ"
	For multiple Group name 
	
  .PARAMETER GroupName	
    Remote Copy Group Name

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARRCopyGroup_WSAPI   
    LASTEDIT: 15/02/2018
    KEYWORDS: Get-3PARRCopyGroup_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
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
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members	
		}
	}
	else
	{
		#Request
		$Result = Invoke-3parWSAPI -uri '/remotecopygroups' -type 'GET' -WsapiConnection $WsapiConnection
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
			Write-DebugLog "SUCCESS: Command Get-3PARRCopyGroup_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARRCopyGroup_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARRCopyGroup_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARRCopyGroup_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARRCopyGroup_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARRCopyGroup_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARRCopyGroupTarget_WSAPI
############################################################################################################################################
Function Get-3PARRCopyGroupTarget_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single Remote Copy Group target
  
  .DESCRIPTION
    This cmdlet (Get-3PARRCopyGroupTarget_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-RCopyGroupTarget_WSAPI) instead.
  
	Get all or single Remote Copy Group target
        
  .EXAMPLE
	Get-3PARRCopyGroupTarget_WSAPI
	Get List of Groups target
	
  .EXAMPLE
	Get-3PARRCopyGroupTarget_WSAPI -TargetName xxx	
	Get Single Target
	
  .PARAMETER GroupName	
    Remote Copy Group Name
	
  .PARAMETER TargetName	
    Target Name

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARRCopyGroupTarget_WSAPI   
    LASTEDIT: 19/02/2018
    KEYWORDS: Get-3PARRCopyGroupTarget_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null	
	
	if($TargetName)
	{
		#Request
		$uri = '/remotecopygroups/'+$GroupName+'/targets/'+$TargetName
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	else
	{
		#Request
		$uri = '/remotecopygroups/'+$GroupName+'/targets'
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARRCopyGroupTarget_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARRCopyGroupTarget_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARRCopyGroupTarget_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARRCopyGroupTarget_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARRCopyGroupVV_WSAPI
############################################################################################################################################
Function Get-3PARRCopyGroupVV_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single Remote Copy Group volume
  
  .DESCRIPTION
    This cmdlet (Get-3PARRCopyGroupVV_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-RCopyGroupVv_WSAPI) instead.
  
	Get all or single Remote Copy Group volume
        
  .EXAMPLE
	Get-3PARRCopyGroupVV_WSAPI -GroupName asRCgroup
	
  .EXAMPLE
	Get-3PARRCopyGroupVV_WSAPI -GroupName asRCgroup -VolumeName Test
	
  .PARAMETER GroupName	
    Remote Copy Group Name
	
  .PARAMETER VolumeName	
    Remote Copy Volume Name

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARRCopyGroupVV_WSAPI   
    LASTEDIT: 19/02/2018
    KEYWORDS: Get-3PARRCopyGroupVV_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null	
	
	if($VolumeName)
	{
		#Request
		$uri = '/remotecopygroups/'+$GroupName+'/volumes/'+$VolumeName
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	else
	{
		#Request
		$uri = '/remotecopygroups/'+$GroupName+'/volumes'
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARRCopyGroupVV_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARRCopyGroupVV_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARRCopyGroupVV_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARRCopyGroupVV_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARRCopyLink_WSAPI
############################################################################################################################################
Function Get-3PARRCopyLink_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single Remote Copy Link
  
  .DESCRIPTION
    This cmdlet (Get-3PARRCopyLink_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-RCopyLink_WSAPI) instead.
  
	Get all or single Remote Copy Link
        
  .EXAMPLE
	Get-3PARRCopyLink_WSAPI
	Get List Remote Copy Link
	
  .EXAMPLE
	Get-3PARRCopyLink_WSAPI -LinkName xxx
	Get Single Remote Copy Link
	
  .PARAMETER LinkName	
    Remote Copy Link Name

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARRCopyLink_WSAPI   
    LASTEDIT: 19/02/2018
    KEYWORDS: Get-3PARRCopyLink_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null	
	
	if($LinkName)
	{
		#Request
		$uri = '/remotecopylinks/'+$LinkName
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	else
	{
		#Request
		
		$Result = Invoke-3parWSAPI -uri '/remotecopylinks' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARRCopyLink_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARRCopyLink_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARRCopyLink_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARRCopyLink_WSAPI

############################################################################################################################################
## FUNCTION Open-3PARSSE_WSAPI
############################################################################################################################################
Function Open-3PARSSE_WSAPI 
{
  <#   
  .SYNOPSIS	
	Establishing a communication channel for Server-Sent Event (SSE).
  
  .DESCRIPTION
    This cmdlet (Open-3PARSSE_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Open-SSE_WSAPI) instead.
  
	Establishing a communication channel for Server-Sent Event (SSE) 
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
        
  .EXAMPLE
	Open-3PARSSE_WSAPI
	
  .Notes
    NAME    : Open-3PARSSE_WSAPI   
    LASTEDIT: 06/06/2018
    KEYWORDS: Open-3PARSSE_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null	
	
	
	#Request
	
	$Result = Invoke-3parWSAPI -uri '/eventstream' -type 'GET' -WsapiConnection $WsapiConnection
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members
	}	
		
		  
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Open-3PARSSE_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Open-3PARSSE_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Open-3PARSSE_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Open-3PARSSE_WSAPI

############################################################################################################################################
## FUNCTION Get-3PAREventLogs_WSAPI
############################################################################################################################################
Function Get-3PAREventLogs_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all past events from system event logs or a logged event information for the available resources. 
  
  .DESCRIPTION
    This cmdlet (Get-3PAREventLogs_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-EventLogs_WSAPI) instead.
  
	Get all past events from system event logs or a logged event information for the available resources. 
        
  .EXAMPLE
	Get-3PAREventLogs_WSAPI
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PAREventLogs_WSAPI   
    LASTEDIT: 20/02/2018
    KEYWORDS: Get-3PAREventLogs_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null	
	
	
	#Request
	
	$Result = Invoke-3parWSAPI -uri '/eventlog' -type 'GET' -WsapiConnection $WsapiConnection
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members
	}	
		
		  
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-3PAREventLogs_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PAREventLogs_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PAREventLogs_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PAREventLogs_WSAPI

############################################################################################################################################
## FUNCTION New-3PARVFS_WSAPI
############################################################################################################################################
Function New-3PARVFS_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create Virtual File Servers.
	
  .DESCRIPTION
    This cmdlet (New-3PARVFS_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-VFS_WSAPI) instead.
  
    Create Virtual File Servers.
	
  .EXAMPLE	
	New-3PARVFS_WSAPI
	
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
    NAME    : New-3PARVFS_WSAPI    
    LASTEDIT: 21/02/2018
    KEYWORDS: New-3PARVFS_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to New-3PARVFS_WSAPI(Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri '/virtualfileservers/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 202)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created Virtual File Servers VFS Name : $VFSName." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARVFS_WSAPI" $Debug
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

}#END New-3PARVFS_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARVFS_WSAPI
############################################################################################################################################
Function Remove-3PARVFS_WSAPI 
{
  <#      
  .SYNOPSIS	
	Removing a Virtual File Servers.
	
  .DESCRIPTION	
    This cmdlet (Remove-3PARVFS_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-VFS_WSAPI) instead.
  
    Removing a Virtual File Servers.
	
  .EXAMPLE	
	Remove-3PARVFS_WSAPI -VFSID 1
	
  .PARAMETER VFSID
	Virtual File Servers id.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-3PARVFS_WSAPI    
    LASTEDIT: 21/02/2018
    KEYWORDS: Remove-3PARVFS_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    $Result = $null
	
	$uri = "/virtualfileservers/"+$VFSID
    #Request
	
	Write-DebugLog "Request: Request to Remove-3PARVFS_WSAPI : $VFSID (Invoke-3parWSAPI)." $Debug	
    $Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Virtual File Servers : $VFSID successfully Remove." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-3PARVFS_WSAPI" $Debug
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

}#END Remove-3PARVFS_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARVFS_WSAPI
############################################################################################################################################
Function Get-3PARVFS_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single Virtual File Servers
  
  .DESCRIPTION
    This cmdlet (Get-3PARVFS_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-VFS_WSAPI) instead.
  
	Get all or single Virtual File Servers
        
  .EXAMPLE
	Get-3PARVFS_WSAPI
	Get List Virtual File Servers
	
  .EXAMPLE
	Get-3PARVFS_WSAPI -VFSID xxx
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
    NAME    : Get-3PARVFS_WSAPI   
    LASTEDIT: 21/02/2018
    KEYWORDS: Get-3PARVFS_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}		
	}
	else
	{
		#Request
		
		$Result = Invoke-3parWSAPI -uri '/virtualfileservers' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARVFS_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARVFS_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARVFS_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARVFS_WSAPI

############################################################################################################################################
## FUNCTION New-3PARFileStore_WSAPI
############################################################################################################################################
Function New-3PARFileStore_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create File Store.
	
  .DESCRIPTION	
    This cmdlet (New-3PARFileStore_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-FileStore_WSAPI) instead.
  
    Create Create File Store.
	
  .EXAMPLE	
	New-3PARFileStore_WSAPI
	
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
    NAME    : New-3PARFileStore_WSAPI    
    LASTEDIT: 03/08/2018
    KEYWORDS: New-3PARFileStore_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to New-3PARFileStore_WSAPI(Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri '/filestores/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created File Store, Name: $FSName." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARFileStore_WSAPI" $Debug
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

}#END New-3PARFileStore_WSAPI

############################################################################################################################################
## FUNCTION Update-3PARFileStore_WSAPI
############################################################################################################################################
Function Update-3PARFileStore_WSAPI 
{
  <#      
  .SYNOPSIS	
	Update File Store.
	
  .DESCRIPTION	
    This cmdlet (Update-3PARFileStore_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Update-FileStore_WSAPI) instead.
  
    Updating File Store.
	
  .EXAMPLE	
	Update-3PARFileStore_WSAPI
	
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
    NAME    : Update-3PARFileStore_WSAPI    
    LASTEDIT: 03/08/2018
    KEYWORDS: Update-3PARFileStore_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Update-3PARFileStore_WSAPI(Invoke-3parWSAPI)." $Debug	
	
	#Request
	$uri = '/filestores/'+$FStoreID
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Updated File Store, File Store ID: $FStoreID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Update-3PARFileStore_WSAPI" $Debug
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

}#END Update-3PARFileStore_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARFileStore_WSAPI
############################################################################################################################################
Function Remove-3PARFileStore_WSAPI 
{
  <#      
  .SYNOPSIS	
	Remove File Store.
	
  .DESCRIPTION
    This cmdlet (Remove-3PARFileStore_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-FileStore_WSAPI) instead.
  
    Remove File Store.
	
  .EXAMPLE	
	Remove-3PARFileStore_WSAPI
	
  .PARAMETER FStoreID
	File Stores ID.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Remove-3PARFileStore_WSAPI    
    LASTEDIT: 28/02/2018
    KEYWORDS: Remove-3PARFileStore_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {		
    #Request
	Write-DebugLog "Request: Request to Remove-3PARFileStore_WSAPI(Invoke-3parWSAPI)." $Debug	
	
	#Request
	$uri = '/filestores/'+$FStoreID
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Removed File Store, File Store ID: $FStoreID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-3PARFileStore_WSAPI" $Debug
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

}#END Remove-3PARFileStore_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARFileStore_WSAPI
############################################################################################################################################
Function Get-3PARFileStore_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single File Stores.
  
  .DESCRIPTION
    This cmdlet (Get-3PARFileStore_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-FileStore_WSAPI) instead.
  
	Get all or single File Stores.
        
  .EXAMPLE
	Get-3PARFileStore_WSAPI
	Get List of File Stores.
	
  .EXAMPLE
	Get-3PARFileStore_WSAPI -FStoreID xxx
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
    NAME    : Get-3PARFileStore_WSAPI   
    LASTEDIT: 28/02/2018
    KEYWORDS: Get-3PARFileStore_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}		
	}
	else
	{
		#Request
		
		$Result = Invoke-3parWSAPI -uri '/filestores' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARFileStore_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARFileStore_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARFileStore_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARFileStore_WSAPI

############################################################################################################################################
## FUNCTION New-3PARFileStoreSnapshot_WSAPI
############################################################################################################################################
Function New-3PARFileStoreSnapshot_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create File Store snapshot.
	
  .DESCRIPTION	
    This cmdlet (New-3PARFileStoreSnapshot_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-FileStoreSnapshot_WSAPI) instead.
  
    Create Create File Store snapshot.
	
  .EXAMPLE	
	New-3PARFileStoreSnapshot_WSAPI
	
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
    NAME    : New-3PARFileStoreSnapshot_WSAPI    
    LASTEDIT: 28/02/2018
    KEYWORDS: New-3PARFileStoreSnapshot_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to New-3PARFileStoreSnapshot_WSAPI(Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri '/filestoresnapshots/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created File Store snapshot." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARFileStoreSnapshot_WSAPI" $Debug
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

}#END New-3PARFileStoreSnapshot_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARFileStoreSnapshot_WSAPI
############################################################################################################################################
Function Remove-3PARFileStoreSnapshot_WSAPI 
{
  <#      
  .SYNOPSIS	
	Remove File Store snapshot.
	
  .DESCRIPTION	
    This cmdlet (Remove-3PARFileStoreSnapshot_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-FileStoreSnapshot_WSAPI) instead.
  
    Remove File Store snapshot.
	
  .EXAMPLE	
	Remove-3PARFileStoreSnapshot_WSAPI
	
  .PARAMETER ID
	File Store snapshot ID.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Remove-3PARFileStoreSnapshot_WSAPI    
    LASTEDIT: 28/02/2018
    KEYWORDS: Remove-3PARFileStoreSnapshot_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {		
    #Request
	Write-DebugLog "Request: Request to Remove-3PARFileStoreSnapshot_WSAPI(Invoke-3parWSAPI)." $Debug	
	
	#Request
	$uri = '/filestoresnapshots/'+$ID
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Removed File Store snapshot, File Store snapshot ID: $ID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-3PARFileStoreSnapshot_WSAPI" $Debug
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

}#END Remove-3PARFileStoreSnapshot_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARFileStoreSnapshot_WSAPI
############################################################################################################################################
Function Get-3PARFileStoreSnapshot_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single File Stores snapshot.
  
  .DESCRIPTION
    This cmdlet (Get-3PARFileStoreSnapshot_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-FileStoreSnapshot_WSAPI) instead.
  
	Get all or single File Stores snapshot.
        
  .EXAMPLE
	Get-3PARFileStoreSnapshot_WSAPI
	Get List of File Stores snapshot.
	
  .EXAMPLE
	Get-3PARFileStoreSnapshot_WSAPI -ID xxx
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
    NAME    : Get-3PARFileStoreSnapshot_WSAPI   
    LASTEDIT: 28/02/2018
    KEYWORDS: Get-3PARFileStoreSnapshot_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}		
	}	
	else
	{
		#Request
		
		$Result = Invoke-3parWSAPI -uri '/filestoresnapshots' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARFileStoreSnapshot_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARFileStoreSnapshot_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARFileStoreSnapshot_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARFileStoreSnapshot_WSAPI

############################################################################################################################################
## FUNCTION New-3PARFileShares_WSAPI
############################################################################################################################################
Function New-3PARFileShares_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create File Share.
	
  .DESCRIPTION	
    This cmdlet (New-3PARFileShares_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-FileShare_WSAPI) instead.
  
    Create Create File Share.
	
  .EXAMPLE	
	New-3PARFileShares_WSAPI
	
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
    NAME    : New-3PARFileShares_WSAPI    
    LASTEDIT: 26/07/2018
    KEYWORDS: New-3PARFileShares_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to New-3PARFileShares_WSAPI(Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri '/fileshares/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created File Share, Name: $FSName." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARFileShares_WSAPI" $Debug
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

}#END New-3PARFileShares_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARFileShare_WSAPI
############################################################################################################################################
Function Remove-3PARFileShare_WSAPI 
{
  <#      
  .SYNOPSIS	
	Remove File Share.
	
  .DESCRIPTION	
    This cmdlet (Remove-3PARFileShare_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-FileShare_WSAPI) instead.
  
    Remove File Share.
	
  .EXAMPLE	
	Remove-3PARFileShare_WSAPI
	
  .PARAMETER ID
	File Share ID contains the unique identifier of the File Share you want to remove.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Remove-3PARFileShare_WSAPI    
    LASTEDIT: 28/02/2018
    KEYWORDS: Remove-3PARFileShare_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {		
    #Request
	Write-DebugLog "Request: Request to Remove-3PARFileShare_WSAPI(Invoke-3parWSAPI)." $Debug	
	
	#Request
	$uri = '/fileshares/'+$ID
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Removed File Share, File Share ID: $ID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-3PARFileShare_WSAPI" $Debug
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

}#END Remove-3PARFileShare_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARFileShare_WSAPI
############################################################################################################################################
Function Get-3PARFileShare_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single File Shares.
  
  .DESCRIPTION
    This cmdlet (Get-3PARFileShare_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-FileShare_WSAPI) instead.
  
	Get all or single File Shares.
        
  .EXAMPLE
	Get-3PARFileShare_WSAPI
	Get List of File Shares.
	
  .EXAMPLE
	Get-3PARFileShare_WSAPI -ID xxx
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
    NAME    : Get-3PARFileShare_WSAPI   
    LASTEDIT: 28/02/2018
    KEYWORDS: Get-3PARFileShare_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}
	else 
	{
		#Request
		
		$Result = Invoke-3parWSAPI -uri '/fileshares' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARFileShare_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARFileShare_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARFileShare_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARFileShare_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARDirPermission_WSAPI
############################################################################################################################################
Function Get-3PARDirPermission_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get directory permission properties.
  
  .DESCRIPTION
    This cmdlet (Get-3PARDirPermission_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-DirPermission_WSAPI) instead.
  
	Get directory permission properties.
        
  .EXAMPLE
	Get-3PARDirPermission_WSAPI -ID 12
	
  .PARAMETER ID	
    File Share ID contains the unique identifier of the File Share you want to Query.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARDirPermission_WSAPI   
    LASTEDIT: 28/02/2018
    KEYWORDS: Get-3PARDirPermission_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null	
	
	
	#Request
	$uri = '/fileshares/'+$ID+'/dirperms'
	
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARDirPermission_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARDirPermission_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARDirPermission_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARDirPermission_WSAPI

############################################################################################################################################
## FUNCTION New-3PARFilePersonaQuota_WSAPI
############################################################################################################################################
Function New-3PARFilePersonaQuota_WSAPI 
{
  <#      
  .SYNOPSIS	
	Create File Persona quota.
	
  .DESCRIPTION	
    This cmdlet (New-3PARFilePersonaQuota_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-FilePersonaQuota_WSAPI) instead.
  
    Create File Persona quota.
	
  .EXAMPLE	
	New-3PARFilePersonaQuota_WSAPI
	
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
    NAME    : New-3PARFilePersonaQuota_WSAPI    
    LASTEDIT: 28/02/2018
    KEYWORDS: New-3PARFilePersonaQuota_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to New-3PARFilePersonaQuota_WSAPI(Invoke-3parWSAPI)." $Debug	
	
    $Result = Invoke-3parWSAPI -uri '/filepersonaquotas/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created File Persona quota." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARFilePersonaQuota_WSAPI" $Debug
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

}#END New-3PARFilePersonaQuota_WSAPI

############################################################################################################################################
## FUNCTION Update-3PARFilePersonaQuota_WSAPI
############################################################################################################################################
Function Update-3PARFilePersonaQuota_WSAPI 
{
  <#      
  .SYNOPSIS	
	Update File Persona quota information.
	
  .DESCRIPTION	
    This cmdlet (Update-3PARFilePersonaQuota_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Update-FilePersonaQuota_WSAPI) instead.
  
    Updating File Persona quota information.
	
  .EXAMPLE	
	Update-3PARFilePersonaQuota_WSAPI
	
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
    NAME    : Update-3PARFilePersonaQuota_WSAPI    
    LASTEDIT: 28/02/2018
    KEYWORDS: Update-3PARFilePersonaQuota_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Update-3PARFilePersonaQuota_WSAPI(Invoke-3parWSAPI)." $Debug	
	
	#Request
	$uri = '/filepersonaquotas/'+$ID
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Updated File Persona quota information, ID: $ID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Update-3PARFilePersonaQuota_WSAPI" $Debug
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

}#END Update-3PARFilePersonaQuota_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARFilePersonaQuota_WSAPI
############################################################################################################################################
Function Remove-3PARFilePersonaQuota_WSAPI 
{
  <#      
  .SYNOPSIS	
	Remove File Persona quota.
	
  .DESCRIPTION	
    This cmdlet (Remove-3PARFilePersonaQuota_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-FilePersonaQuota_WSAPI) instead.
  
    Remove File Persona quota.
	
  .EXAMPLE	
	Remove-3PARFilePersonaQuota_WSAPI
	
  .PARAMETER ID
	The <id> variable contains the unique ID of the File Persona you want to Remove.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-3PARFilePersonaQuota_WSAPI    
    LASTEDIT: 28/02/2018
    KEYWORDS: Remove-3PARFilePersonaQuota_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {		
    #Request
	Write-DebugLog "Request: Request to Remove-3PARFilePersonaQuota_WSAPI(Invoke-3parWSAPI)." $Debug	
	
	#Request
	$uri = '/filepersonaquotas/'+$ID
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Removed File Persona quota, File Persona quota ID: $ID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-3PARFilePersonaQuota_WSAPI" $Debug
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

}#END Remove-3PARFilePersonaQuota_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARFilePersonaQuota_WSAPI
############################################################################################################################################
Function Get-3PARFilePersonaQuota_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get all or single File Persona quota.
  
  .DESCRIPTION
    This cmdlet (Get-3PARFilePersonaQuota_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-FilePersonaQuota_WSAPI) instead.
  
	Get all or single File Persona quota.
        
  .EXAMPLE
	Get-3PARFilePersonaQuota_WSAPI
	Get List of File Persona quota.
	
  .EXAMPLE
	Get-3PARFilePersonaQuota_WSAPI -ID xxx
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
    NAME    : Get-3PARFilePersonaQuota_WSAPI   
    LASTEDIT: 05/03/2018
    KEYWORDS: Get-3PARFilePersonaQuota_WSAPI
   
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
	Test-3PARConnection -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
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
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}
	}	
	else
	{
		#Request
		
		$Result = Invoke-3parWSAPI -uri '/filepersonaquota' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARFilePersonaQuota_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARFilePersonaQuota_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARFilePersonaQuota_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARFilePersonaQuota_WSAPI

############################################################################################################################################
## FUNCTION Restore-3PARFilePersonaQuota_WSAPI
############################################################################################################################################
Function Restore-3PARFilePersonaQuota_WSAPI 
{
  <#      
  .SYNOPSIS	
	Restore a File Persona quota.
	
  .DESCRIPTION	
    This cmdlet (Restore-3PARFilePersonaQuota_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Restore-FilePersonaQuota_WSAPI) instead.
  
    Restore a File Persona quota.
	
  .EXAMPLE	
	Restore-3PARFilePersonaQuota_WSAPI
	
  .PARAMETER VFSUUID
	VFS UUID.
  
  .PARAMETER ArchivedPath
	The path to the archived file from which the file persona quotas are to be restored.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command  
  
  .Notes
    NAME    : Restore-3PARFilePersonaQuota_WSAPI    
    LASTEDIT: 28/02/2018
    KEYWORDS: Restore-3PARFilePersonaQuota_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Restore-3PARFilePersonaQuota_WSAPI(Invoke-3parWSAPI)." $Debug	
	
	#Request	
    $Result = Invoke-3parWSAPI -uri '/filepersonaquotas/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Restore a File Persona quota, VFSUUID: $VFSUUID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Restore-3PARFilePersonaQuota_WSAPI" $Debug
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

}#END Restore-3PARFilePersonaQuota_WSAPI

############################################################################################################################################
## FUNCTION Group-3PARFilePersonaQuota_WSAPI
############################################################################################################################################
Function Group-3PARFilePersonaQuota_WSAPI 
{
  <#      
  .SYNOPSIS	
	Archive a File Persona quota.
	
  .DESCRIPTION
    This cmdlet (Group-3PARFilePersonaQuota_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Group-FilePersonaQuota_WSAPI) instead.
  
    Archive a File Persona quota.
	
  .EXAMPLE	
	Group-3PARFilePersonaQuota_WSAPI
	
  .PARAMETER QuotaArchiveParameter
	VFS UUID.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command  
  
  .Notes
    NAME    : Group-3PARFilePersonaQuota_WSAPI    
    LASTEDIT: 04/07/2018
    KEYWORDS: Group-3PARFilePersonaQuota_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Group-3PARFilePersonaQuota_WSAPI(Invoke-3parWSAPI)." $Debug	
	
	#Request	
    $Result = Invoke-3parWSAPI -uri '/filepersonaquotas/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Restore a File Persona quota, VFSUUID: $VFSUUID." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Group-3PARFilePersonaQuota_WSAPI" $Debug
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

}#END Group-3PARFilePersonaQuota_WSAPI

############################################################################################################################################
## FUNCTION Set-3PARVVSetFlashCachePolicy_WSAPI
############################################################################################################################################
Function Set-3PARVVSetFlashCachePolicy_WSAPI 
{
  <#      
  .SYNOPSIS	
	Setting a VV-set Flash Cache policy.
	
  .DESCRIPTION
    This cmdlet (Set-3PARVVSetFlashCachePolicy_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Set-VvSetFlashCachePolicy_WSAPI) instead.
  
    Setting a VV-set Flash Cache policy.
	
  .EXAMPLE	
	Set-3PARVVSetFlashCachePolicy_WSAPI
	
  .PARAMETER VvSet
	Name Of the VV-set to Set Flash Cache policy.
  
  .PARAMETER Enable
	To Enable VV-set Flash Cache policy
	
  .PARAMETER Disable
	To Disable VV-set Flash Cache policy
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
  
  .Notes
    NAME    : Set-3PARVVSetFlashCachePolicy_WSAPI    
    LASTEDIT: 16/07/2018
    KEYWORDS: Set-3PARVVSetFlashCachePolicy_WSAPI
   
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
    Test-3PARConnection -WsapiConnection $WsapiConnection
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
	Write-DebugLog "Request: Request to Set-3PARVVSetFlashCachePolicy_WSAPI(Invoke-3parWSAPI)." $Debug	
	
	#Request
	$uri = '/volumesets/'+$VvSet
	
    $Result = Invoke-3parWSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Set Flash Cache policy $Massage to vv-set $VvSet." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Set-3PARVVSetFlashCachePolicy_WSAPI" $Debug
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

}#END Set-3PARVVSetFlashCachePolicy_WSAPI

############################################################################################################################################
## FUNCTION New-3PARFlashCache_WSAPI
############################################################################################################################################
Function New-3PARFlashCache_WSAPI 
{
  <#      
  .SYNOPSIS	
	Creating a Flash Cache.
	
  .DESCRIPTION
    This cmdlet (New-3PARFlashCache_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (New-FlashCache_WSAPI) instead.
  
    Creating a Flash Cache.
	
  .EXAMPLE	
	New-3PARFlashCache_WSAPI -SizeGiB 64 -Mode 1 -RAIDType R6
	
  .EXAMPLE	
	New-3PARFlashCache_WSAPI -SizeGiB 64 -Mode 1 -RAIDType R0
	
  .EXAMPLE	
	New-3PARFlashCache_WSAPI -NoCheckSCMSize "true"
	
  .EXAMPLE	
	New-3PARFlashCache_WSAPI -NoCheckSCMSize "false"
	
  .PARAMETER SizeGiB
	Specifies the node pair size of the Flash Cache on the system.
	
  .PARAMETER Mode
	Simulator: 1 Real: 2 (default)
	
  .PARAMETER RAIDType  
	Raid Type of the logical disks for flash cache. When unspecified, storage system chooses the default(R0 Level0,R1 Level1).

  .PARAMETER NoCheckSCMSize
	Overrides the size comparison check to allow Adaptive Flash Cache creation with mismatched SCM device sizes.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : New-3PARFlashCache_WSAPI    
    LASTEDIT: 16/07/2018
    KEYWORDS: New-3PARFlashCache_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0     
  #>

  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $SizeGiB,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $Mode,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $RAIDType,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NoCheckSCMSize,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	  )

  Begin 
  {
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
    Write-DebugLog "Running: Creation of the body hash" $Debug
    # Creation of the body hash
    $body = @{}
	$FlashCacheBody = @{} 
	
	If($SizeGiB) 
	{
		$FlashCacheBody["sizeGiB"] = $SizeGiB
    }
	If($Mode) 
	{
		$FlashCacheBody["mode"] = $Mode
    }
	if($RAIDType)
	{	
		if($RAIDType -eq "R0")
		{
			$FlashCacheBody["RAIDType"] = 1
		}
		elseif($RAIDType -eq "R1")
		{
			$FlashCacheBody["RAIDType"] = 2
		}		
		else
		{
			Write-DebugLog "Stop: Exiting  Update-3PARCpg_WSAPI   since RAIDType $RAIDType in incorrect "
			Return "FAILURE : RAIDType :- $RAIDType is an Incorrect Please Use RAIDType R0 or R1 only. "
		}
	}
	If($NoCheckSCMSize) 
	{
		$val = $NoCheckSCMSize.ToUpper()
		if($val -eq "TRUE")
		{
			$FlashCacheBody["noCheckSCMSize"] = $True
		}
		if($val -eq "FALSE")
		{
			$FlashCacheBody["noCheckSCMSize"] = $false
		}		
    }
	
	
	if($FlashCacheBody.Count -gt 0){$body["flashCache"] = $FlashCacheBody }
	
    $Result = $null
		
    #Request
	Write-DebugLog "Request: Request to New-3PARFlashCache_WSAPI(Invoke-3parWSAPI)." $Debug	
	
	#Request	
    $Result = Invoke-3parWSAPI -uri '/' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Created Flash Cache." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: New-3PARFlashCache_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While creating a Flash Cache." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating a Flash Cache." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END New-3PARFlashCache_WSAPI

############################################################################################################################################
## FUNCTION Remove-3PARFlashCache_WSAPI
############################################################################################################################################
Function Remove-3PARFlashCache_WSAPI 
{
  <#      
  .SYNOPSIS	
	Removing a Flash Cache.
	
  .DESCRIPTION
    This cmdlet (Remove-3PARFlashCache_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Remove-FlashCache_WSAPI) instead.
  
    Removing a Flash Cache.
	
  .EXAMPLE	
	Remove-3PARFlashCache_WSAPI

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-3PARFlashCache_WSAPI    
    LASTEDIT: 17/07/2018
    KEYWORDS: Remove-3PARFlashCache_WSAPI
   
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
    # Test if connection exist
    Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {		
    #Request
	Write-DebugLog "Request: Request to Remove-3PARFlashCache_WSAPI(Invoke-3parWSAPI)." $Debug	
	
	#Request
		
    $Result = Invoke-3parWSAPI -uri '/flashcache' -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Successfully Removed Flash CacheD." $Info
				
		# Results
		return $Result
		Write-DebugLog "End: Remove-3PARFlashCache_WSAPI" $Debug
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing Flash Cache." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Removing Flash Cache." $Info
		
		return $Result.StatusDescription
	}
  }

  End {  }

}#END Remove-3PARFlashCache_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARFlashCache_WSAPI
############################################################################################################################################
Function Get-3PARFlashCache_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get Flash Cache information.
  
  .DESCRIPTION
    This cmdlet (Get-3PARFlashCache_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-FlashCache_WSAPI) instead.
  
	Get Flash Cache information.
        
  .EXAMPLE
	Get-3PARFlashCache_WSAPI
	Get Flash Cache information.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARFlashCache_WSAPI   
    LASTEDIT: 17/07/2018
    KEYWORDS: Get-3PARFlashCache_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	
	#Request
	
	$Result = Invoke-3parWSAPI -uri '/flashcache' -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = $Result.content | ConvertFrom-Json
	}	
		  
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: Command Get-3PARFlashCache_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARFlashCache_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARFlashCache_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARFlashCache_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARUsers_WSAPI
############################################################################################################################################
Function Get-3PARUsers_WSAPI 
{
  <#   
  .SYNOPSIS	
	Get all or single WSAPI users information.
  
  .DESCRIPTION
    This cmdlet (Get-3PARUsers_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-Users_WSAPI) instead.
  
	Get all or single WSAPI users information.
        
  .EXAMPLE
	Get-3PARUsers_WSAPI
	Get all WSAPI users information.

  .EXAMPLE
	Get-3PARUsers_WSAPI -UserName XYZ
	Get single WSAPI users information.
	
  .PARAMETER UserName
	Name Of The User.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARUsers_WSAPI   
    LASTEDIT: 17/07/2018
    KEYWORDS: Get-3PARUsers_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $UserName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
		
	if($UserName)
	{
		#Request
		$uri = '/users/'+$UserName
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}	
	else
	{
		#Request
		
		$Result = Invoke-3parWSAPI -uri '/users' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARUsers_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARUsers_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARUsers_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARUsers_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARRoles_WSAPI
############################################################################################################################################
Function Get-3PARRoles_WSAPI 
{
  <#   
  .SYNOPSIS	
	Get all or single WSAPI role information.
  
  .DESCRIPTION
    This cmdlet (Get-3PARRoles_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-Roles_WSAPI) instead.
  
	Get all or single WSAPI role information.
        
  .EXAMPLE
	Get-3PARRoles_WSAPI
	Get all WSAPI role information.

  .EXAMPLE
	Get-3PARRoles_WSAPI -RoleName XYZ
	Get single WSAPI role information.
	
  .PARAMETER WsapiConnection 
	Name of the Role.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARRoles_WSAPI   
    LASTEDIT: 17/07/2018
    KEYWORDS: Get-3PARRoles_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $RoleName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
		
	if($RoleName)
	{
		#Request
		$uri = '/roles/'+$RoleName
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}	
	else
	{
		#Request
		
		$Result = Invoke-3parWSAPI -uri '/roles' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARRoles_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARRoles_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARRoles_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARRoles_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARAOConfiguration_WSAPI
############################################################################################################################################
Function Get-3PARAOConfiguration_WSAPI 
{
  <#   
  .SYNOPSIS	
	Get all or single WSAPI AO configuration information.
  
  .DESCRIPTION
    This cmdlet (Get-3PARAOConfiguration_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-AOConfiguration_WSAPI) instead.
  
	Get all or single WSAPI AO configuration information.
        
  .EXAMPLE
	Get-3PARAOConfiguration_WSAPI
	Get all WSAPI AO configuration information.

  .EXAMPLE
	Get-3PARAOConfiguration_WSAPI -AOconfigName XYZ
	Get single WSAPI AO configuration information.

  .PARAMETER AOconfigName
	AO configuration name.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARAOConfiguration_WSAPI   
    LASTEDIT: 17/07/2018
    KEYWORDS: Get-3PARAOConfiguration_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
	  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $AOconfigName,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
		
	if($AOconfigName)
	{
		#Request
		$uri = '/aoconfigurations/'+$AOconfigName
		
		$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}	
	else
	{
		#Request
		
		$Result = Invoke-3parWSAPI -uri '/aoconfigurations' -type 'GET' -WsapiConnection $WsapiConnection
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
		Write-DebugLog "SUCCESS: Command Get-3PARAOConfiguration_WSAPI Successfully Executed" $Info
		
		return $dataPS		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARAOConfiguration_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARAOConfiguration_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARAOConfiguration_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARCacheMemoryStatisticsDataReports_WSAPI
############################################################################################################################################
Function Get-3PARCacheMemoryStatisticsDataReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Cache memory statistics data reports
  
  .DESCRIPTION
    This cmdlet (Get-3PARCacheMemoryStatisticsDataReports_WSAPI ) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-CacheMemoryStatisticsDataReports_WSAPI) instead.
  
	Cache memory statistics data reports.Request cache memory statistics data using either Versus Time or At Time reports.

	
  .EXAMPLE	
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -VersusTime -Frequency_Hires
	
  .EXAMPLE	
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -AtTime -Frequency_Hires
	
  .EXAMPLE	
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -VersusTime -Frequency_Hires -NodeId 1
	
  .EXAMPLE	
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -VersusTime -Frequency_Hires -NodeId "1,2,3"
		
  .EXAMPLE
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -VersusTime -Frequency_Hires -Groupby node
		
  .EXAMPLE
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -AtTime -Frequency_Hires -NodeId 1
	
  .EXAMPLE
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -AtTime -Frequency_Hires -NodeId "1,2,3"
		
  .EXAMPLE
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -AtTime -Frequency_Hires -Groupby node
	
  .EXAMPLE
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -VersusTime -Frequency_Hires -Summary min
	
  .EXAMPLE
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -VersusTime -Frequency_Hires -Compareby top -NoOfRecords 2 -ComparebyField hitIORead
	
  .EXAMPLE	
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -VersusTime -Frequency_Hires -GETime 2018-07-18T13:20:00+05:30 -LETime 2018-07-18T13:25:00+05:30  
	        
  .EXAMPLE
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -VersusTime -Frequency_Hires -GETime 2018-07-18T13:20:00+05:30 
	        
  .EXAMPLE
	Get-3PARCacheMemoryStatisticsDataReports_WSAPI -VersusTime -Frequency_Hires -LETime 2018-07-18T13:25:00+05:30  
	
  .PARAMETER VersusTime
	Request cache memory statistics data using Versus Time reports.
	
  .PARAMETER AtTime
	Request cache memory statistics data using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily
	
  .PARAMETER NodeId
	<nodeid> – Provides cache memory data for the specified nodes, in the range of 0 to 7. For example specify node:1,3,2. With no nodeid specified, the system calculates cache memory data for all nodes in the system.
	
  .PARAMETER Groupby
	Group the sample data into the node category.
	
  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER Compareby
	It should be either top or bottom, Specifies whether to display the top records or the bottom records. Choose one.

  .PARAMETER NoOfRecords
	Specifies the number of records to return in the range of 1 to 32 (Versus TIme) and 1 to 128 (At Time).
	
  .PARAMETER ComparebyField
	please select any one from
	hitIORead : Number of read I/Os per second while data was in cache
	hitIOWrite : Number of write I/Os per second while data was in cache
	missIORead : Number of read I/Os per second while data was not in cache
	missIOWrite : Number of write I/Os per second while data was not in cache
	accessIORead : Number of read I/Os per second
	accessIOWrite : Number of write I/Os per second
	hitPctRead : Hits divided by accesses in percentage for read I/Os
	hitPctWrite : Hits divided by accesses in percentage for write I/Os
	totalAccessIO : Number of total read and write I/Os per second
	lockBulkIO : Number of pages modified per second by host I/O and written to disk by the flusher
	pageStatisticDelayAckPagesNL_7 : Delayed acknowledgment pages associated with NL 7
	pageStatisticDelayAckPagesFC : Delayed acknowledgment pages associated with FC
	pageStatisticDelayAckPagesSSD : Delayed acknowledgment pages associated with SSD
	pageStatisticPageStatesFree : Number of cache pages without valid data on them
	pageStatisticPageStatesClean : Number of clean cache pages
	pageStatisticPageStatesWriteOnce : Number of dirty pages modified exactly 1 time
	pageStatisticPageStatesWriteMultiple : Number of dirty pages modified more than 1 time
	pageStatisticPageStatesWriteScheduled : Number of pages scheduled to be written to disk
	pageStatisticPageStatesWriteing : Number of pages being written to disk
	pageStatisticPageStatesDcowpend : Number of pages waiting for delayed copy on write resolution
	pageStatisticDirtyPagesNL : Dirty cluster memory pages associated with NL 7
	pageStatisticDirtyPagesFC : Dirty cluster memory pages associated with FC
	pageStatisticDirtyPagesSSD : Dirty cluster memory pages associated with SSD
	pageStatisticMaxDirtyPagesNL_7 : Maximum allowed number of dirty cluster memory pages associated with NL 7
	pageStatisticMaxDirtyPagesFC : Maximum allowed number of dirty cluster memory pages associated with FC
	pageStatisticMaxDirtyPagesSSD : Maximum allowed number of dirty cluster memory pages associated with SSD

  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARCacheMemoryStatisticsDataReports_WSAPI   
    LASTEDIT: 18/07/2018
    KEYWORDS: Get-3PARCacheMemoryStatisticsDataReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NodeId,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Summary,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Compareby,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NoOfRecords,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ComparebyField,		
		
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select atlist any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
	
	#Build uri
	$uri = '/systemreporter/'+$Action+'/cachememorystatistics/'+$Frequency
	
	if($NodeId) { if($AtTime) { return "We cannot pass node values in At Time report." } $uri = $uri+";node:$NodeId"}
	if($Groupby) { $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}
	if($Compareby)
	{ 
		$cmpVal = $Compareby.ToLower()
		if($cmpVal -eq "top" -OR $cmpVal -eq "bottom")
		{
			$uri = $uri+";compareby:$cmpVal,"
		}
		else
		{
			return "Compareby should be either top or bottom"
		}
		if($NoOfRecords)
		{
			$uri = $uri+$NoOfRecords+","
		}
		else
		{
			return "NoOfRecords is mandatory with Compareby. "
		}
		if($ComparebyField)
		{
			$uri = $uri+$ComparebyField
		}
		else
		{
			return "ComparebyField is mandatory with Compareby.please see the parameter help for this"
		}		
	}
	
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	
	write-host "URL = $uri"
	
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARCacheMemoryStatisticsDataReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARCacheMemoryStatisticsDataReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARCacheMemoryStatisticsDataReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARCacheMemoryStatisticsDataReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARCacheMemoryStatisticsDataReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARCacheMemoryStatisticsDataReports_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARCPGSpaceDataReports_WSAPI
############################################################################################################################################
Function Get-3PARCPGSpaceDataReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	CPG space data using either Versus Time or At Time reports.
  
  .DESCRIPTION
    This cmdlet (Get-3PARCPGSpaceDataReports_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-CPGSpaceDataReports_WSAPI) instead.
  
	CPG space data using either Versus Time or At Time reports..
        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -VersusTime -Frequency_Hires
	        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -VersusTime -Frequency_Hires -CpgName xxx
	        
  .EXAMPLE	
	Get-3PARCPGSpaceDataReports_WSAPI -VersusTime -Frequency_Hires -DiskType FC
	        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -VersusTime -Frequency_Hires -DiskType "FC,LN,SSD"
	        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -VersusTime -Frequency_Hires -RAIDType R1
	        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -VersusTime -Frequency_Hires -RAIDType "R1,R2"
	        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -VersusTime -Frequency_Hires -Groupby "id,diskType,RAIDType"
	        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -VersusTime -Frequency_Hourly -Summary max
	        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -VersusTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
		        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -AtTime -Frequency_Hires -CpgName xxx
	        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -AtTime -Frequency_Hires -DiskType FC
	        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -AtTime -Frequency_Hires -DiskType "FC,NL"
	
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -AtTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
 .EXAMPLE	
	Get-3PARCPGSpaceDataReports_WSAPI -VersusTime -Frequency_Hires -GETime 2018-07-18T13:20:00+05:30 -LETime 2018-07-18T13:25:00+05:30  
	        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -VersusTime -Frequency_Hires -GETime 2018-07-18T13:20:00+05:30 
	        
  .EXAMPLE
	Get-3PARCPGSpaceDataReports_WSAPI -VersusTime -Frequency_Hires -LETime 2018-07-18T13:25:00+05:30
		
  .PARAMETER VersusTime
	Request CPG space data using  Versus Time reports.
	
  .PARAMETER AtTime
	Request CPG space data using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily
	
  .PARAMETER DiskType
	The CPG space sample data is for the specified disk types. With no disk type specified, the system calculates the CPG space sample data is for all the disk types in the system.
	1 is for :- FC : Fibre Channel
	2 is for :- NL : Near Line
	3 is for :- SSD : SSD
	4 is for :- SCM : SCM Disk type
	
  .PARAMETER CpgName
	Indicates that the CPG space sample data is only for the specified CPG names. With no name specified, the system calculates the CPG space sample data for all CPGs.
		
  .PARAMETER RAIDType
	Indicates that the CPG space sample data is for the specified raid types. With no type specified, the system calculates the CPG space sample data for all the raid types in the system.
	R0 : RAID level 0
	R1 : RAID level 1
	R5 : RAID level 5
	R6 : RAID level 6

  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER Compareby
	It should be either top or bottom, Specifies whether to display the top records or the bottom records. Choose one.

  .PARAMETER NoOfRecords
	Specifies the number of records to return in the range of 1 to 32 (Versus TIme) and 1 to 128 (At Time).
	
  .PARAMETER ComparebyField
	please select any one from
	totalSpaceMiB : Total space in MiB.
	freeSpaceMiB : Free space in MiB.
	usedSpaceMiB : Used space in MiB
	compaction : Compaction ratio.
	compression : Compression ratio.
	deduplication : Deduplication ratio.
	dataReduction : Data reduction ratio.
	
  .PARAMETER Groupby  
	Group the sample data into categories. With no category specified, the system groups data into all
	categories. Separate multiple groupby categories using a comma (,) and no spaces. Use the structure,
	groupby:domain,id,name,diskType,RAIDType.
  
  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter
  
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARCPGSpaceDataReports_WSAPI   
    LASTEDIT: 18/07/2018
    KEYWORDS: Get-3PARCPGSpaceDataReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $CpgName,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $DiskType,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $RAIDType,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Summary,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Compareby,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NoOfRecords,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ComparebyField,	
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select at-list any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
	
	#Build uri
	$uri = '/systemreporter/'+$Action+'/cpgspacedata/'+$Frequency
		
	if($CpgName) { if($AtTime) { return "We cannot pass CpgName in At Time report." } $uri = $uri+";name:$CpgName"}
	if($DiskType) 
	{
		if($AtTime)	{ return "We cannot pass DiskType in At Time report." }
		[System.String]$DislTV = ""
		$DislTV = Add-DiskType -DT $DiskType		
		$uri = $uri+";diskType:"+$DislTV.Trim()
	}
	if($RAIDType) 
	{ 
		if($AtTime) { return "We cannot pass RAIDType in At Time report." }
		[System.String]$RedTV = ""
		$RedTV = Add-RedType -RT $RAIDType		
		$uri = $uri+";RAIDType:"+$RedTV.Trim()	
	}
	if($Groupby) {  $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}
	if($Compareby)
	{ 
		$cmpVal = $Compareby.ToLower()
		if($cmpVal -eq "top" -OR $cmpVal -eq "bottom")
		{
			$uri = $uri+";compareby:$cmpVal,"
		}
		else
		{
			return "Compareby should be either top or bottom"
		}
		if($NoOfRecords)
		{
			$uri = $uri+$NoOfRecords+","
		}
		else
		{
			return "NoOfRecords is mandatory with Compareby. "
		}
		if($ComparebyField)
		{
			$uri = $uri+$ComparebyField
		}
		else
		{
			return "ComparebyField is mandatory with Compareby.please see the parameter help for this"
		}		
	}
	
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARCPGSpaceDataReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARCPGSpaceDataReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARCPGSpaceDataReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARCPGSpaceDataReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARCPGSpaceDataReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARCPGSpaceDataReports_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARCPGStatisticalDataReports_WSAPI
############################################################################################################################################
Function Get-3PARCPGStatisticalDataReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	CPG statistical data using either Versus Time or At Time reports.
  
  .DESCRIPTION
    This cmdlet (Get-3PARCPGStatisticalDataReports_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-CPGStatisticalDataReports_WSAPI) instead.
  
	CPG statistical data using either Versus Time or At Time reports.
        
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -VersusTime -Frequency_Hourly
        
  .EXAMPLE	
	Get-3PARCPGStatisticalDataReports_WSAPI -VersusTime -Frequency_Hires -CpgName $cpg
	        
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -VersusTime -Frequency_Hires -Groupby name
	        
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -AtTime -Frequency_Hourly
	        
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -AtTime -Frequency_Hires -CpgName $cpg
	        
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -AtTime -Frequency_Hires -Groupby name
	        
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30"
        
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -AtTime -Frequency_Hires -LETime "2018-04-09T12:20:00+05:30"
        
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30" -LETime "2018-04-09T12:20:00+05:30"
	        
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -VersusTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30"
        
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -VersusTime -Frequency_Hires -LETime "2018-04-09T12:20:00+05:30"
        
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -VersusTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30" -LETime "2018-04-09T12:20:00+05:30"
	
   .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -VersusTime -Frequency_Hourly -Summary max
	
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -AtTime -Frequency_Hires -Summary max
  
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -VersusTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARCPGStatisticalDataReports_WSAPI -AtTime -Frequency_Hires -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .PARAMETER VersusTime
	Request CPG space data using  Versus Time reports.
	
  .PARAMETER AtTime
	Request CPG space data using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily
	
  .PARAMETER CpgName
	Indicates that the CPG space sample data is only for the specified CPG names. With no name specified, the system calculates the CPG space sample data for all CPGs.
 
  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER Compareby
	It should be either top or bottom, Specifies whether to display the top records or the bottom records. Choose one.

  .PARAMETER NoOfRecords
	Specifies the number of records to return in the range of 1 to 32 (Versus TIme) and 1 to 128 (At Time).
	
  .PARAMETER ComparebyField
	please select any one from
	totalIOPs : Total number of IOPs

  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter.
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter.

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARCPGStatisticalDataReports_WSAPI   
    LASTEDIT: 18/07/2018
    KEYWORDS: Get-3PARCPGStatisticalDataReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $CpgName,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Summary,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Compareby,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NoOfRecords,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ComparebyField,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select at-list any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
	
	#Build uri
	$uri = '/systemreporter/'+$Action+'/cpgstatistics/'+$Frequency
		
	if($CpgName) { if($AtTime) { return "We cannot pass CpgName in At Time report." } $uri = $uri+";name:$CpgName"}	
	if($Groupby) {  $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}
    if($Compareby)
	{ 
		$cmpVal = $Compareby.ToLower()
		if($cmpVal -eq "top" -OR $cmpVal -eq "bottom")
		{
			$uri = $uri+";compareby:$cmpVal,"
		}
		else
		{
			return "Compareby should be either top or bottom"
		}
		if($NoOfRecords)
		{
			$uri = $uri+$NoOfRecords+","
		}
		else
		{
			return "NoOfRecords is mandatory with Compareby. "
		}
		if($ComparebyField)
		{
			$uri = $uri+$ComparebyField
		}
		else
		{
			return "ComparebyField is mandatory with Compareby.please see the parameter help for this"
		}		
	}
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	
	#write-host "URL = $uri"
	
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARCPGStatisticalDataReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARCPGStatisticalDataReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARCPGStatisticalDataReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARCPGStatisticalDataReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARCPGStatisticalDataReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARCPGStatisticalDataReports_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARCPUStatisticalDataReports_WSAPI
############################################################################################################################################
Function Get-3PARCPUStatisticalDataReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	CPU statistical data reports.
  
  .DESCRIPTION
    This cmdlet (Get-3PARCPUStatisticalDataReports_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-CPUStatisticalDataReports_WSAPI) instead.
  
	CPU statistical data reports.
	
  .EXAMPLE 
	Get-3PARCPUStatisticalDataReports_WSAPI -AtTime -Frequency_Hires
  
  .EXAMPLE  
	Get-3PARCPUStatisticalDataReports_WSAPI -VersusTime -Frequency_Hires
	
  .EXAMPLE  
	Get-3PARCPUStatisticalDataReports_WSAPI -VersusTime -Frequency_Hires -NodeId 1
	
  .EXAMPLE  
	Get-3PARCPUStatisticalDataReports_WSAPI -VersusTime -Frequency_Hires -Groupby cpu
  
  .EXAMPLE
	Get-3PARCPUStatisticalDataReports_WSAPI -VersusTime -Frequency_Hourly -Summary max
	
  .EXAMPLE
	Get-3PARCPUStatisticalDataReports_WSAPI -AtTime -Frequency_Hires -Summary max
  
  .EXAMPLE
	Get-3PARCPUStatisticalDataReports_WSAPI -VersusTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARCPUStatisticalDataReports_WSAPI -AtTime -Frequency_Hires -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARCPUStatisticalDataReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30"
        
  .EXAMPLE
	Get-3PARCPUStatisticalDataReports_WSAPI -AtTime -Frequency_Hires -LETime "2018-04-09T12:20:00+05:30"
        
  .EXAMPLE
	Get-3PARCPUStatisticalDataReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30" -LETime "2018-04-09T12:20:00+05:30"
			
  .PARAMETER VersusTime
	Request CPU statistics data using Versus Time reports.
	
  .PARAMETER AtTime
	Request CPU statistics data using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily
	
  .PARAMETER NodeId
	Indicates that the CPU statistics sample data is only for the specified nodes. The valid range of node IDs is 0 - 7. For example, specify node:1,3,2. With no node ID specified, the system calculates CPU statistics sample data for all nodes in the system.
  
  .PARAMETER Groupby
	You can group the CPU statistical data into categories. With no groupby parameter specified, the system groups the data into all categories.
		    
  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER Compareby
	It should be either top or bottom, Specifies whether to display the top records or the bottom records. Choose one.

  .PARAMETER NoOfRecords
	Specifies the number of records to return in the range of 1 to 32 (Versus TIme) and 1 to 128 (At Time).
	
  .PARAMETER ComparebyField
	please select any one from
	userPct : Percent of CPU time in user-mode
	systemPct : Percent of CPU time in system-mode
	idlePct : Percent of CPU time in idle
	interruptsPerSec : Number of interrupts per second
	contextSwitchesPerSec : Number of context switches per second
	
  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARCPUStatisticalDataReports_WSAPI   
    LASTEDIT: 18/07/2018
    KEYWORDS: Get-3PARCPUStatisticalDataReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NodeId,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Summary,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Compareby,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NoOfRecords,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ComparebyField,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select atlist any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
	
	#Build uri
	$uri = '/systemreporter/'+$Action+'/cpustatistics/'+$Frequency
	
	if($NodeId) { if($AtTime) { return "We cannot pass node values in At Time report." } $uri = $uri+";node:$NodeId"}
	if($Groupby) { $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}
    if($Compareby)
	{ 
		$cmpVal = $Compareby.ToLower()
		if($cmpVal -eq "top" -OR $cmpVal -eq "bottom")
		{
			$uri = $uri+";compareby:$cmpVal,"
		}
		else
		{
			return "Compareby should be either top or bottom"
		}
		if($NoOfRecords)
		{
			$uri = $uri+$NoOfRecords+","
		}
		else
		{
			return "NoOfRecords is mandatory with Compareby. "
		}
		if($ComparebyField)
		{
			$uri = $uri+$ComparebyField
		}
		else
		{
			return "ComparebyField is mandatory with Compareby.please see the parameter help for this"
		}		
	}
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARCPUStatisticalDataReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARCPUStatisticalDataReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARCPUStatisticalDataReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARCPUStatisticalDataReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARCPUStatisticalDataReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARCPUStatisticalDataReports_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARPDCapacityReports_WSAPI
############################################################################################################################################
Function Get-3PARPDCapacityReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Physical disk capacity reports.
  
  .DESCRIPTION
    This cmdlet (Get-3PARPDCapacityReports_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-PDCapacityReports_WSAPI) instead.
  
	Physical disk capacity reports.
        
  .EXAMPLE 
	Get-3PARPDCapacityReports_WSAPI -AtTime -Frequency_Hires
  
  .EXAMPLE  
	Get-3PARPDCapacityReports_WSAPI -VersusTime -Frequency_Hires
	  
  .EXAMPLE 
	Get-3PARPDCapacityReports_WSAPI -VersusTime -Frequency_Hires -Id 1
	  
  .EXAMPLE 
	Get-3PARPDCapacityReports_WSAPI -VersusTime -Frequency_Hires -DiskType FC
	  
  .EXAMPLE 
	Get-3PARPDCapacityReports_WSAPI -AtTime -Frequency_Hires -DiskType "FC,SSD"
	  
  .EXAMPLE 
	Get-3PARPDCapacityReports_WSAPI -VersusTime -Frequency_Hires -Groupby id
	  
  .EXAMPLE 
	Get-3PARPDCapacityReports_WSAPI -AtTime -Frequency_Hires -Groupby "id,type"
  
  .EXAMPLE
	Get-3PARPDCapacityReports_WSAPI -VersusTime -Frequency_Hourly -Summary max
	
  .EXAMPLE
	Get-3PARPDCapacityReports_WSAPI -AtTime -Frequency_Hires -Summary max
  
  .EXAMPLE
	Get-3PARPDCapacityReports_WSAPI -VersusTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARPDCapacityReports_WSAPI -AtTime -Frequency_Hires -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARPDCapacityReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30"
        
  .EXAMPLE
	Get-3PARPDCapacityReports_WSAPI -AtTime -Frequency_Hires -LETime "2018-04-09T12:20:00+05:30"
        
  .EXAMPLE
	Get-3PARPDCapacityReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30" -LETime "2018-04-09T12:20:00+05:30"	
		
  .PARAMETER VersusTime
	Request Physical disk capacity using Versus Time reports.
	
  .PARAMETER AtTime
	Request Physical disk capacity using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily
	
  .PARAMETER Id
	Requests disk capacity data for the specified disks only. For example, specify id:1,3,2. With no id specified, the system calculates physical disk capacity for all disks in the system.
  
  .PARAMETER DiskType
	Specifies the disk types to query for physical disk capacity sample data. With no disktype specified, the system calculates physical disk capacity for all disk types in the system.
	FC : Fibre Channel
	NL : Near Line
	SSD : SSD
	
  .PARAMETER RPM
	Specifies the RPM speeds to query for physical disk capacity data. With no speed indicated, the system calculates physical disk capacity data for all speeds in the system. You can specify one or more disk RPM speeds by separating them with a comma (,). For example, specify RPM:7,15,150. Valid RPM values are: 7,10,15,100,150.
  
  .PARAMETER Groupby
	id | cageID | cageSide | mag | diskPos | type | RPM
	Groups the sample data into specified categories. With no category specified, the system groups data into all categories. To specify multiple groupby categories, separate them using a comma (,). For example, id,type,RPM.
	    
  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARPDCapacityReports_WSAPI   
    LASTEDIT: 18/07/2018
    KEYWORDS: Get-3PARPDCapacityReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Id,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $DiskType,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $RPM,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Summary,
	  	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select at-list any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
	
	#Build uri
	$uri = '/systemreporter/'+$Action+'/physicaldiskcapacity/'+$Frequency
		
	if($Id) { if($AtTime) { return "We cannot pass Id in At Time report." } $uri = $uri+";id:$Id"}
	#if($DiskType) { if($AtTime) { return "We cannot pass DiskType in At Time report." } $uri = $uri+";type:$DiskType"}
	if($DiskType) 
	{
		if($AtTime)	{ return "We cannot pass DiskType in At Time report." }
		[System.String]$DislTV = ""
		$DislTV = Add-DiskType -DT $DiskType		
		$uri = $uri+";type:"+$DislTV.Trim()
	}	
	if($RPM) { if($AtTime) { return "We cannot pass RPM in At Time report." } $uri = $uri+";RPM:$RPM"}
	if($Groupby) {  $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}	
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	
	#write-host "URL = $uri"
	
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARPDCapacityReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARPDCapacityReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARPDCapacityReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARPDCapacityReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARPDCapacityReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARPDCapacityReports_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARPDStatisticsReports_WSAPI
############################################################################################################################################
Function Get-3PARPDStatisticsReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	physical disk statistics reports using either Versus Time or At Time reports.
  
  .DESCRIPTION
    This cmdlet (Get-3PARPDStatisticsReports_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-PDStatisticsReports_WSAPI) instead.
  
	physical disk statistics reports using either Versus Time or At Time reports.
        
  .EXAMPLE 
	Get-3PARPDStatisticsReports_WSAPI -AtTime -Frequency_Hires
  
  .EXAMPLE  
	Get-3PARPDStatisticsReports_WSAPI -VersusTime -Frequency_Hires
	  
  .EXAMPLE 
	Get-3PARPDStatisticsReports_WSAPI -VersusTime -Frequency_Hires -Id 1
	  
  .EXAMPLE 
	Get-3PARPDStatisticsReports_WSAPI -VersusTime -Frequency_Hires -DiskType FC
	  
  .EXAMPLE 
	Get-3PARPDStatisticsReports_WSAPI -AtTime -Frequency_Hires -DiskType "FC,SSD"
	  
  .EXAMPLE	
	Get-3PARPDStatisticsReports_WSAPI -VersusTime -Frequency_Hires -RPM 7
	  
  .EXAMPLE
	Get-3PARPDStatisticsReports_WSAPI -AtTime -Frequency_Hires -RPM "7,10"
	
  .EXAMPLE 
	Get-3PARPDStatisticsReports_WSAPI -VersusTime -Frequency_Hires -Groupby id
	  
  .EXAMPLE 
	Get-3PARPDStatisticsReports_WSAPI -AtTime -Frequency_Hires -Groupby "id,type"
  
  .EXAMPLE
	Get-3PARPDStatisticsReports_WSAPI -VersusTime -Frequency_Hourly -Summary max
	
  .EXAMPLE
	Get-3PARPDStatisticsReports_WSAPI -AtTime -Frequency_Hires -Summary max
  
  .EXAMPLE
	Get-3PARPDStatisticsReports_WSAPI -VersusTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARPDStatisticsReports_WSAPI -AtTime -Frequency_Hires -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARPDStatisticsReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30"
        
  .EXAMPLE
	Get-3PARPDStatisticsReports_WSAPI -AtTime -Frequency_Hires -LETime "2018-04-09T12:20:00+05:30"
        
  .EXAMPLE
	Get-3PARPDStatisticsReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30" -LETime "2018-04-09T12:20:00+05:30"	
		
  .PARAMETER VersusTime
	Request Physical disk capacity using Versus Time reports.
	
  .PARAMETER AtTime
	Request Physical disk capacity using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily
	
  .PARAMETER Id
	Requests disk capacity data for the specified disks only. For example, specify id:1,3,2. With no id specified, the system calculates physical disk capacity for all disks in the system.
  
  .PARAMETER DiskType
	Specifies the disk types to query for physical disk capacity sample data. With no disktype specified, the system calculates physical disk capacity for all disk types in the system.
	FC : Fibre Channel
	NL : Near Line
	SSD : SSD
	
  .PARAMETER RPM
	Specifies the RPM speeds to query for physical disk capacity data. With no speed indicated, the system calculates physical disk capacity data for all speeds in the system. You can specify one or more disk RPM speeds by separating them with a comma (,). For example, specify RPM:7,15,150. Valid RPM values are: 7,10,15,100,150.
  
  .PARAMETER Groupby
	id | cageID | cageSide | mag | diskPos | type | RPM
	Groups the sample data into specified categories. With no category specified, the system groups data into all categories. To specify multiple groupby categories, separate them using a comma (,). For example, id,type,RPM.
     
  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER Compareby
	It should be either top or bottom, Specifies whether to display the top records or the bottom records. Choose one.

  .PARAMETER NoOfRecords
	Specifies the number of records to return in the range of 1 to 32 (Versus TIme) and 1 to 128 (At Time).
	
  .PARAMETER ComparebyField
	please select any one from
	totalIOPs : Total IOPs.

  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARPDStatisticsReports_WSAPI   
    LASTEDIT: 18/07/2018
    KEYWORDS: Get-3PARPDStatisticsReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Id,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $DiskType,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $RPM,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Summary,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Compareby,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NoOfRecords,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ComparebyField,
	  	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select at-list any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
	
	#Build uri
	$uri = '/systemreporter/'+$Action+'/physicaldiskstatistics/'+$Frequency
		
	if($Id) { if($AtTime) { return "We cannot pass Id in At Time report." } $uri = $uri+";id:$Id"}
	if($DiskType) { if($AtTime) { return "We cannot pass DiskType in At Time report." } $uri = $uri+";type:$DiskType"}
	if($RPM) { if($AtTime) { return "We cannot pass RPM in At Time report." } $uri = $uri+";RPM:$RPM"}
	if($Groupby) {  $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}
    if($Compareby)
	{ 
		$cmpVal = $Compareby.ToLower()
		if($cmpVal -eq "top" -OR $cmpVal -eq "bottom")
		{
			$uri = $uri+";compareby:$cmpVal,"
		}
		else
		{
			return "Compareby should be either top or bottom"
		}
		if($NoOfRecords)
		{
			$uri = $uri+$NoOfRecords+","
		}
		else
		{
			return "NoOfRecords is mandatory with Compareby. "
		}
		if($ComparebyField)
		{
			$uri = $uri+$ComparebyField
		}
		else
		{
			return "ComparebyField is mandatory with Compareby.please see the parameter help for this"
		}		
	}	
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	
	#write-host "URL = $uri"
	
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARPDStatisticsReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARPDStatisticsReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARPDStatisticsReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARPDStatisticsReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARPDStatisticsReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARPDStatisticsReports_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARPDSpaceReports_WSAPI
############################################################################################################################################
Function Get-3PARPDSpaceReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Request physical disk space data reports using either Versus Time or At Time reports.
  
  .DESCRIPTION
    This cmdlet (Get-3PARPDSpaceReports_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-PDSpaceReports_WSAPI) instead.
  
	Request physical disk space data reports using either Versus Time or At Time reports.
        
  .EXAMPLE 
	Get-3PARPDSpaceReports_WSAPI -AtTime -Frequency_Hires
  
  .EXAMPLE  
	Get-3PARPDSpaceReports_WSAPI -VersusTime -Frequency_Hires
	  
  .EXAMPLE 
	Get-3PARPDSpaceReports_WSAPI -VersusTime -Frequency_Hires -Id 1
	  
  .EXAMPLE 
	Get-3PARPDSpaceReports_WSAPI -VersusTime -Frequency_Hires -DiskType FC
	  
  .EXAMPLE 
	Get-3PARPDSpaceReports_WSAPI -AtTime -Frequency_Hires -DiskType "FC,SSD"
	  
  .EXAMPLE	
	Get-3PARPDSpaceReports_WSAPI -VersusTime -Frequency_Hires -RPM 7
	  
  .EXAMPLE
	Get-3PARPDSpaceReports_WSAPI -AtTime -Frequency_Hires -RPM "7,10"
	
  .EXAMPLE 
	Get-3PARPDSpaceReports_WSAPI -VersusTime -Frequency_Hires -Groupby id
	  
  .EXAMPLE 
	Get-3PARPDSpaceReports_WSAPI -AtTime -Frequency_Hires -Groupby "id,cageID"
  
  .EXAMPLE
	Get-3PARPDSpaceReports_WSAPI -VersusTime -Frequency_Hourly -Summary max
	
  .EXAMPLE
	Get-3PARPDSpaceReports_WSAPI -AtTime -Frequency_Hires -Summary max
  
  .EXAMPLE
	Get-3PARPDSpaceReports_WSAPI -VersusTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARPDSpaceReports_WSAPI -AtTime -Frequency_Hires -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARPDSpaceReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30"
        
  .EXAMPLE
	Get-3PARPDSpaceReports_WSAPI -AtTime -Frequency_Hires -LETime "2018-04-09T12:20:00+05:30"
        
  .EXAMPLE
	Get-3PARPDSpaceReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30" -LETime "2018-04-09T12:20:00+05:30"	
		
  .PARAMETER VersusTime
	Request Physical disk capacity using Versus Time reports.
	
  .PARAMETER AtTime
	Request Physical disk capacity using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily
	
  .PARAMETER Id
	Requests disk capacity data for the specified disks only. For example, specify id:1,3,2. With no id specified, the system calculates physical disk capacity for all disks in the system.
  
  .PARAMETER DiskType
	Specifies the disk types to query for physical disk capacity sample data. With no disktype specified, the system calculates physical disk capacity for all disk types in the system.
	FC : Fibre Channel
	NL : Near Line
	SSD : SSD
	
  .PARAMETER RPM
	Specify the RPM speed to query for physical disk capacity data. With no speed indicated, the system
	calculates physical disk capacity data for all speeds in the system. Specify one or more disk RPM speeds
	by separating them with a comma (,). Use the structure, RPM:7,15,150. Valid RPM values are:7,10,15,100,150.
  
  .PARAMETER Groupby
	id | cageID | cageSide | mag | diskPos | type | RPM
	Groups the sample data into specified categories. With no category specified, the system groups data into all categories. To specify multiple groupby categories, separate them using a comma (,). For example, id,type,RPM.
	    
  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER Compareby
	It should be either top or bottom, Specifies whether to display the top records or the bottom records. Choose one.

  .PARAMETER NoOfRecords
	Specifies the number of records to return in the range of 1 to 32 (Versus TIme) and 1 to 128 (At Time).
	
  .PARAMETER ComparebyField
	please select any one from
	totalIOPs : Total number of IOPs
	normalChunkletsUsedOK : Normal used good chunklets
	normalChunkletsUsedFailed : Normal used failed chunklets
	normalChunkletsAvailClean : Normal available clean chunklets
	normalChunkletsAvailDirty : Normal available dirty chunklets
	normalChunkletsAvailFailed : Normal available failed chunklets
	spareChunkletsUsedOK : Spare used good chunklets
	spareChunkletsUsedFailed : Spare used failed chunklets
	spareChunkletsAvailClean : Spare available clean chunklets
	spareChunkletsAvailDirty : Spare available dirty chunklets
	spareChunkletsAvailFailed : Spare available failed chunklets
	lifeLeftPct : Percentage of life left
	temperatureC : Temperature in Celsius
	
  .PARAMETER Compareby
	top|bottom,noOfRecords,comparebyField
	Optional parameter provided in comma-separated format, and in the specific order shown above. Requires simultaneous use of the groupby parameter. The following table describes the parameter values.
	
  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter


  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARPDSpaceReports_WSAPI   
    LASTEDIT: 18/07/2018
    KEYWORDS: Get-3PARPDSpaceReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Id,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $DiskType,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $RPM,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [System.String]
	  $Summary,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Compareby,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NoOfRecords,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ComparebyField,
	  	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select at-list any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
	
	#Build uri
	$uri = '/systemreporter/'+$Action+'/physicaldiskspacedata/'+$Frequency
		
	if($Id) { if($AtTime) { return "We cannot pass Id in At Time report." } $uri = $uri+";id:$Id"}	
	if($DiskType) 
	{
		if($AtTime)	{ return "We cannot pass DiskType in At Time report." }
		[System.String]$DislTV = ""
		$DislTV = Add-DiskType -DT $DiskType		
		$uri = $uri+";type:"+$DislTV.Trim()
	}
	if($RPM) { if($AtTime) { return "We cannot pass RPM in At Time report." } $uri = $uri+";RPM:$RPM"}
	if($Groupby) {  $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}
    if($Compareby)
	{ 
		$cmpVal = $Compareby.ToLower()
		if($cmpVal -eq "top" -OR $cmpVal -eq "bottom")
		{
			$uri = $uri+";compareby:$cmpVal,"
		}
		else
		{
			return "Compareby should be either top or bottom"
		}
		if($NoOfRecords)
		{
			$uri = $uri+$NoOfRecords+","
		}
		else
		{
			return "NoOfRecords is mandatory with Compareby. "
		}
		if($ComparebyField)
		{
			$uri = $uri+$ComparebyField
		}
		else
		{
			return "ComparebyField is mandatory with Compareby.please see the parameter help for this"
		}		
	}	
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	
	#write-host "URL = $uri"
	
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARPDSpaceReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARPDSpaceReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARPDSpaceReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARPDSpaceReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARPDSpaceReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARPDSpaceReports_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARPortStatisticsReports_WSAPI
############################################################################################################################################
Function Get-3PARPortStatisticsReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Request a port statistics report using either Versus Time or At Time reports.
  
  .DESCRIPTION
    This cmdlet (Get-3PARPortStatisticsReports_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-PortStatisticsReports_WSAPI) instead.
  
	Request a port statistics report using either Versus Time or At Time reports.
        
  .EXAMPLE 
	Get-3PARPortStatisticsReports_WSAPI -AtTime -Frequency_Hires
  
  .EXAMPLE  
	Get-3PARPortStatisticsReports_WSAPI -VersusTime -Frequency_Hires
	  
  .EXAMPLE
	Get-3PARPortStatisticsReports_WSAPI -VersusTime -Frequency_Hires -NSP "1:0:1"
	  
  .EXAMPLE
	Get-3PARPortStatisticsReports_WSAPI -AtTime -Frequency_Hires -PortType 1
	  
  .EXAMPLE
	Get-3PARPortStatisticsReports_WSAPI -VersusTime -Frequency_Hires -PortType :1,2"
	  
  .EXAMPLE
	Get-3PARPortStatisticsReports_WSAPI -VersusTime -Frequency_Hourly -Groupby slot
	  
  .EXAMPLE
	Get-3PARPortStatisticsReports_WSAPI -AtTime -Frequency_Hourly -Groupby "slot,type"
	
  .EXAMPLE
	Get-3PARPortStatisticsReports_WSAPI -VersusTime -Frequency_Hourly -Summary max
	
  .EXAMPLE
	Get-3PARPortStatisticsReports_WSAPI -AtTime -Frequency_Hires -Summary max
  
  .EXAMPLE
	Get-3PARPortStatisticsReports_WSAPI -VersusTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARPortStatisticsReports_WSAPI -AtTime -Frequency_Hires -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARPortStatisticsReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30"
        
  .EXAMPLE
	Get-3PARPortStatisticsReports_WSAPI -AtTime -Frequency_Hires -LETime "2018-04-09T12:20:00+05:30"
        
  .EXAMPLE
	Get-3PARPortStatisticsReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30" -LETime "2018-04-09T12:20:00+05:30"	
		
  .PARAMETER VersusTime
	Request port statistics report using Versus Time reports.
	
  .PARAMETER AtTime
	Request port statistics report using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily

  .PARAMETER NSP
	Requests sample data for the specified ports only using n:s:p. For example, specify port:1:0:1,2:1:3,6:2:1. With no portPos specified, the system calculates performance data for all ports in the system.
  
  .PARAMETER PortType
	Requests sample data for the specified port type (see, portConnType enumeration) . With no type specified, the system calculates performance data for all port types in the system. You can specify one or more port types by separating them with a comma (,). For example, specify type: 1,2,8.
	Symbol Value Description
	1 for :- HOST : FC port connected to hosts or fabric.	
	2 for :- DISK : FC port connected to disks.	
	3 for :- FREE : Port is not connected to hosts or disks.	
	4 for :- IPORT : Port is in iport mode.	
	5 for :- RCFC : FC port used for Remote Copy.	
	6 for :- PEER : FC port used for data migration.	
	7 for :- RCIP : IP (Ethernet) port used for Remote Copy.	
	8 for :- ISCSI : iSCSI (Ethernet) port connected to hosts.	
	9 for :- CNA : CNA port, which can be FCoE or iSCSI.	
	10 for :- FS : Ethernet File Persona ports.
	
  .PARAMETER Groupby
	node | slot | cardPort | type | speed
	Groups the sample data into specified categories. With no category specified, the system groups data into all categories. To specify multiple groupby categories, separate them using a comma (,). For example, slot,cardPort,type. 
	      
  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER Compareby
	It should be either top or bottom, Specifies whether to display the top records or the bottom records. Choose one.

  .PARAMETER NoOfRecords
	Specifies the number of records to return in the range of 1 to 32 (Versus TIme) and 1 to 128 (At Time).
	
  .PARAMETER ComparebyField
	please select any one from
	totalIOPs : Total IOPs.

  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARPortStatisticsReports_WSAPI   
    LASTEDIT: 18/07/2018
    KEYWORDS: Get-3PARPortStatisticsReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $PortType,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Summary,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Compareby,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NoOfRecords,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ComparebyField,
	  	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select at-list any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
	
	#Build uri
	$uri = '/systemreporter/'+$Action+'/portstatistics/'+$Frequency
		
	if($NSP) { if($AtTime) { return "We cannot pass NSP in At Time report." } $uri = $uri+";portPos:$NSP"}
	if($PortType) { if($AtTime) { return "We cannot pass PortType in At Time report." } $uri = $uri+";type:$PortType"}	
	if($Groupby) {  $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}
    if($Compareby)
	{ 
		$cmpVal = $Compareby.ToLower()
		if($cmpVal -eq "top" -OR $cmpVal -eq "bottom")
		{
			$uri = $uri+";compareby:$cmpVal,"
		}
		else
		{
			return "Compareby should be either top or bottom"
		}
		if($NoOfRecords)
		{
			$uri = $uri+$NoOfRecords+","
		}
		else
		{
			return "NoOfRecords is mandatory with Compareby. "
		}
		if($ComparebyField)
		{
			$uri = $uri+$ComparebyField
		}
		else
		{
			return "ComparebyField is mandatory with Compareby.please see the parameter help for this"
		}		
	}		
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARPortStatisticsReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARPortStatisticsReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARPortStatisticsReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARPortStatisticsReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARPortStatisticsReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARPortStatisticsReports_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARQoSStatisticalReports_WSAPI
############################################################################################################################################
Function Get-3PARQoSStatisticalReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Request Quality of Service (QoS) statistical data using either Versus Time or At Time reports.
  
  .DESCRIPTION
    This cmdlet (Get-3PARQoSStatisticalReports_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-QoSStatisticalReports_WSAPI) instead.
  
	Request Quality of Service (QoS) statistical data using either Versus Time or At Time reports.

  .EXAMPLE	
	Get-3PARQoSStatisticalReports_WSAPI -VersusTime -Frequency_Hires
	
  .EXAMPLE	
	Get-3PARQoSStatisticalReports_WSAPI -VersusTime -Frequency_Hires -VvSetName "asvvset2"

  .EXAMPLE	
	Get-3PARQoSStatisticalReports_WSAPI -VersusTime -Frequency_Hires -VvSetName "asvvset,asvvset2"

  .EXAMPLE		
	Get-3PARQoSStatisticalReports_WSAPI -VersusTime -Frequency_Daily -All_Others

  .EXAMPLE		
	Get-3PARQoSStatisticalReports_WSAPI -VersusTime -Frequency_Daily -Domain asdomain
	
  .EXAMPLE 
	Get-3PARQoSStatisticalReports_WSAPI -AtTime -Frequency_Hires
  
  .EXAMPLE  
	Get-3PARQoSStatisticalReports_WSAPI -VersusTime -Frequency_Hires
	
  .EXAMPLE
	Get-3PARQoSStatisticalReports_WSAPI -VersusTime -Frequency_Hourly -Summary max
	
  .EXAMPLE
	Get-3PARQoSStatisticalReports_WSAPI -AtTime -Frequency_Hires -Summary max
  
  .EXAMPLE
	Get-3PARQoSStatisticalReports_WSAPI -VersusTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARQoSStatisticalReports_WSAPI -AtTime -Frequency_Hires -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARQoSStatisticalReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30"
        
  .EXAMPLE
	Get-3PARQoSStatisticalReports_WSAPI -AtTime -Frequency_Hires -LETime "2018-04-09T12:20:00+05:30"
        
  .EXAMPLE
	Get-3PARQoSStatisticalReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30" -LETime "2018-04-09T12:20:00+05:30"	
	
  .PARAMETER VersusTime
	Request port statistics report using Versus Time reports.
	
  .PARAMETER AtTime
	Request port statistics report using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily

  .PARAMETER VvSetName
	Retrieve QoS statistics for the specified vvset. Specify multiple vvsets using vvset_name1,vvset_name2...
  
  .PARAMETER Domain
	Retrieve QoS statistics for the specified domain. Use the structure, domain:<domain_name>, or specify multiple domains using domain_name1,domain_name2...

  .PARAMETER All_Others
	Specify all host I/Os not regulated by any active QoS rule. Use the structure, all_others
	
  .PARAMETER Groupby
	Group QoS statistical data into categories. With no groupby parameter specified, the system groups the
	data into all categories. You can specify one or more groupby categories by separating them with a
	comma. Use the structure, groupby:domain,type,name,ioLimit.
      
  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER Compareby
	It should be either top or bottom, Specifies whether to display the top records or the bottom records. Choose one.

  .PARAMETER NoOfRecords
	Specifies the number of records to return in the range of 1 to 32 (Versus TIme) and 1 to 128 (At Time).
	
  .PARAMETER ComparebyField
	please select any one from
	readIOPS : Read input/output operations per second.
	writeIOPS : Write input/output operations per second.
	totalIOPS : Total input/output operations per second.
	readKBytes : Read kilobytes.
	writeKBytes : Write kilobytes.
	totalKBytes : Total kilobytes.
	readServiceTimeMS : Read service time in milliseconds.
	writeServiceTimeMS : Write service time in milliseconds.
	totalServiceTimeMS : Total service time in milliseconds.
	readIOSizeKB : Read input/output size in kilobytes
	writeIOSizeKB : Write input/output size in kilobytes
	totalIOSizeKB : Total input/output size in kilobytes
	readWaitTimeMS : Read wait time in milliseconds.
	writeWaitTimeMS : Write wait time in milliseconds.
	totalWaitTimeMS : Total wait time in milliseconds.
	IOLimit : IO limit.
	BWLimit : Bandwidth limit.
	IOGuarantee : Input/output guarantee.
	BWGuarantee : Bandwidth guarantee.
	busyPct : Busy Percentage.
	queueLength : Total queue length.
	waitQueueLength : Total wait queue length.
	IORejection : Total input/output rejection.
	latencyMS : Latency in milliseconds.
	latencyTargetMS : Latency target in milliseconds.

  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARQoSStatisticalReports_WSAPI   
    LASTEDIT: 25/09/2018
    KEYWORDS: Get-3PARQoSStatisticalReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VvSetName,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Domain,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $All_Others,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Summary,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Compareby,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NoOfRecords,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ComparebyField,
	  	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select at-list any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
	
	#Build uri
	$uri = '/systemreporter/'+$Action+'/qosstatistics/'+$Frequency
		
	if($VvSetName) 
	{ 
		if($AtTime) { return "We cannot pass VvSetName in At Time report." }
		$lista = $VvSetName.split(",")		
		$count = 1
		$set =""
		foreach($sub in $lista)
		{
			$prfx ="vvset:"+$sub
			if($lista.Count -gt 1)
			{
				if($lista.Count -ne $count)
				{					
					$prfx = $prfx + ","
					$count = $count + 1
				}				
			}
			$set = $prfx
		}
		
		$uri = $uri+";$set"
	}
	if($Domain) 
	{ 
		if($AtTime) { return "We cannot pass Domain in At Time report." }
		$lista = $Domain.split(",")		
		$count = 1
		$dom =""
		foreach($sub in $lista)
		{
			$prfx ="domain:"+$sub
			if($lista.Count -gt 1)
			{
				if($lista.Count -ne $count)
				{					
					$prfx = $prfx + ","
					$count = $count + 1
				}				
			}
			$dom = $prfx
		}
		
		$uri = $uri+";$dom"
	}
	if($All_Others) 
	{ 
		if($AtTime) { return "We cannot pass All_Others in At Time report." }			
		$uri = $uri+";sys:all_others"
	}	
	if($Groupby) {  $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}
    if($Compareby)
	{ 
		$cmpVal = $Compareby.ToLower()
		if($cmpVal -eq "top" -OR $cmpVal -eq "bottom")
		{
			$uri = $uri+";compareby:$cmpVal,"
		}
		else
		{
			return "Compareby should be either top or bottom"
		}
		if($NoOfRecords)
		{
			$uri = $uri+$NoOfRecords+","
		}
		else
		{
			return "NoOfRecords is mandatory with Compareby. "
		}
		if($ComparebyField)
		{
			$uri = $uri+$ComparebyField
		}
		else
		{
			return "ComparebyField is mandatory with Compareby.please see the parameter help for this"
		}		
	}		
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	
	write-host " uri = $uri"
	
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARQoSStatisticalReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARQoSStatisticalReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARQoSStatisticalReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARQoSStatisticalReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARQoSStatisticalReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARQoSStatisticalReports_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARRCStatisticalReports_WSAPI
############################################################################################################################################
Function Get-3PARRCStatisticalReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Request Remote Copy statistical data using either Versus Time or At Time reports.
  
  .DESCRIPTION
    This cmdlet (Get-3PARRCStatisticalReports_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-RCopyStatisticalReports_WSAPI) instead.
  
	Request Remote Copy statistical data using either Versus Time or At Time reports.
        
  .EXAMPLE 
	Get-3PARRCStatisticalReports_WSAPI -AtTime -Frequency_Hires
        
  .EXAMPLE 	
	Get-3PARRCStatisticalReports_WSAPI -AtTime -Frequency_Hires -TargetName xxx
	        
  .EXAMPLE 
	Get-3PARRCStatisticalReports_WSAPI -AtTime -Frequency_Hires -NSP x:x:x
	        
  .EXAMPLE 
	Get-3PARRCStatisticalReports_WSAPI -AtTime -Frequency_Hires -NSP "x:x:x,x:x:x:
	        
  .EXAMPLE 
	Get-3PARRCStatisticalReports_WSAPI -AtTime -Frequency_Hires -Groupby "targetName,linkId"
  
  .EXAMPLE  
	Get-3PARRCStatisticalReports_WSAPI -VersusTime -Frequency_Hires
	
  .EXAMPLE
	Get-3PARRCStatisticalReports_WSAPI -VersusTime -Frequency_Hourly -Summary max
	
  .EXAMPLE
	Get-3PARRCStatisticalReports_WSAPI -AtTime -Frequency_Hires -Summary max
  
  .EXAMPLE
	Get-3PARRCStatisticalReports_WSAPI -VersusTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARRCStatisticalReports_WSAPI -AtTime -Frequency_Hires -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARRCStatisticalReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30"
        
  .EXAMPLE
	Get-3PARRCStatisticalReports_WSAPI -AtTime -Frequency_Hires -LETime "2018-04-09T12:20:00+05:30"
        
  .EXAMPLE
	Get-3PARRCStatisticalReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30" -LETime "2018-04-09T12:20:00+05:30"	
		
  .PARAMETER VersusTime
	Request port statistics report using Versus Time reports.
	
  .PARAMETER AtTime
	Request port statistics report using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily

  .PARAMETER TargetName
	Specify the target from which to gather Remote Copy statistics. Separate multiple target names using a comma (,). 
	With no target specified, the request calculates Remote Copy statistics for all targets in the system. Use the structure, targetName:<target1>,<target2> . . .

  .PARAMETER NSP
	Specify the port from which to gather Remote Copy statistics. Separate multiple port positions with a
	comma (,) Use the structure, <n:s:p>,<n:s:p> . . .. With no port specified, the request
	calculates Remote Copy statistics for all ports in the system.
	
  .PARAMETER Groupby
	Group Remote Copy statistical data into categories. With no groupby parameter specified, the system groups the data into all categories. 
	Separate multiple groups with a comma (,). Use the structure,
	groupby:targetName,linkId,linkAddr,node,slotPort,cardPort.  
	
  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER Compareby
	It should be either top or bottom, Specifies whether to display the top records or the bottom records. Choose one.

  .PARAMETER NoOfRecords
	Specifies the number of records to return in the range of 1 to 32 (Versus TIme) and 1 to 128 (At Time).
	
  .PARAMETER ComparebyField
	please select any one from 
	kbs : Kilobytes.
	kbps : Kilobytes per second.
	hbrttms : Round trip time for a heartbeat message on the link.
	targetName : Name of the Remote Copy target created with creatercopytarget.
	linkId : ID of the Remote Copy target created with creatercopytarget.
	linkAddr : Address (IP or FC) of the Remote Copy target created with creatercopytarget.
	node : Node number for the port used by a Remote Copy link.
	slotPort : PCI slot number for the port used by a Remote Copy link.
	cardPort : Port number for the port used by a Remote Copy link.

  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARRCStatisticalReports_WSAPI   
    LASTEDIT: 25/09/2018
    KEYWORDS: Get-3PARRCStatisticalReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Summary,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Compareby,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NoOfRecords,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ComparebyField,
	  	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select at-list any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
	
	#Build uri
	$uri = '/systemreporter/'+$Action+'/remotecopystatistics/'+$Frequency
	
	if($TargetName)	{ if($AtTime) { return "We cannot pass TargetName in At Time report." } $uri = $uri+";targetName:$TargetName" }
	if($NSP)	{ if($AtTime) { return "We cannot pass NSP in At Time report." } $uri = $uri+";portPos:$NSP" }
	if($Groupby) {  $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}
    if($Compareby)
	{ 
		$cmpVal = $Compareby.ToLower()
		if($cmpVal -eq "top" -OR $cmpVal -eq "bottom")
		{
			$uri = $uri+";compareby:$cmpVal,"
		}
		else
		{
			return "Compareby should be either top or bottom"
		}
		if($NoOfRecords)
		{
			$uri = $uri+$NoOfRecords+","
		}
		else
		{
			return "NoOfRecords is mandatory with Compareby. "
		}
		if($ComparebyField)
		{
			$uri = $uri+$ComparebyField
		}
		else
		{
			return "ComparebyField is mandatory with Compareby.please see the parameter help for this"
		}		
	}		
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARRCStatisticalReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARRCStatisticalReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARRCStatisticalReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARRCStatisticalReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARRCStatisticalReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARRCStatisticalReports_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARRCopyVolumeStatisticalReports_WSAPI
############################################################################################################################################
Function Get-3PARRCopyVolumeStatisticalReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Request statistical data related to Remote Copy volumes using either Versus Time or At Time reports.
  
  .DESCRIPTION
    This cmdlet (Get-3PARRCopyVolumeStatisticalReports_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-RCopyVolumeStatisticalReports_WSAPI) instead.
  
	Request statistical data related to Remote Copy volumes using either Versus Time or At Time reports.
        
  .EXAMPLE 
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -AtTime -Frequency_Hires
  
  .EXAMPLE  
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -VersusTime -Frequency_Hires
	  
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -VersusTime -Frequency_Hires -vvName xxx
	  
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -VersusTime -Frequency_Hires -vvName "xxx,xxx"
	  
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -VersusTime -Frequency_Hires -TargetName xxx
	  
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -VersusTime -Frequency_Hires -TargetName "xxx,xxx"
	  
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -VersusTime -Frequency_Hires -Mode SYNC
	  
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -VersusTime -Frequency_Hires -RCopyGroup xxx
	  
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -VersusTime -Frequency_Hires -Groupby domain
	  
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -VersusTime -Frequency_Hires -Groupby "domain,targetNamex"
	
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -VersusTime -Frequency_Hourly -Summary max
	
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -AtTime -Frequency_Hires -Summary max
  
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -VersusTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -AtTime -Frequency_Hires -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30"
        
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -AtTime -Frequency_Hires -LETime "2018-04-09T12:20:00+05:30"
        
  .EXAMPLE
	Get-3PARRCopyVolumeStatisticalReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30" -LETime "2018-04-09T12:20:00+05:30"	
		
  .PARAMETER VersusTime
	Request port statistics report using Versus Time reports.
	
  .PARAMETER AtTime
	Request port statistics report using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily

  .PARAMETER vvName
	Specify the name of the volume from which to gather Remote Copy volume statistics. Separate multiple
	names with a comma (,) Use <vvname1>,<vvname2> . . .. To specify the name of a set of volumes, use set:<vvsetname>.
  
  .PARAMETER TargetName
	Specify the target from which to gather Remote Copy volume statistics. Separate multiple target names using a comma (,). 
	With no target specified, the request calculates Remote Copy volume statistics for all targets in the system.

  .PARAMETER Mode
	Specify the mode of the target from which to gather Remote Copy volume statistics.
	SYNC : Remote Copy group mode is synchronous.
	PERIODIC : Remote Copy group mode is periodic. Although WSAPI 1.5 and later supports PERIODIC 2, Hewlett Packard Enterprise	recommends using PERIODIC 3.
	PERIODIC : Remote Copy group mode is periodic.
	ASYNC : Remote Copy group mode is asynchronous.
	
  .PARAMETER RCopyGroup	
	Specify the remote copy group from which to gather Remote Copy volume statistics. Separate multiple group names using a comma (,).
	With no remote copy group specified, the request calculates remote copy volume statistics for all remote copy groups in the system.
	
  .PARAMETER Groupby
	Group the Remote Copy volume statistical data into categories. With no groupby parameter specified,the system groups the data into all categories. 
	Separate multiple groups with a comma (,). Use the structure,groupby:volumeName,volumeSetName,domain,targetName,mode,remoteCopyGroup,remote CopyGroupRole,node,slot,cardPort,portType.
      
  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER Compareby
	It should be either top or bottom, Specifies whether to display the top records or the bottom records. Choose one.

  .PARAMETER NoOfRecords
	Specifies the number of records to return in the range of 1 to 32 (Versus TIme) and 1 to 128 (At Time).
	
  .PARAMETER ComparebyField
	please select any one from 
	readIOLocal : Local read input/output operations per second.
	writeIOLocal : Local write input/output operations per second.
	IOLocal : Local total input/output operations per second.
	readKBytesLocal : Local read kilobytes.
	writeKBytesLocal : Local write kilobytes.
	KBytesLocal : Local total kilobytes.
	readServiceTimeMSLocal : Local read service time in milliseconds.
	writeServiceTimeMSLocal : Local write service time in milliseconds.
	ServiceTimeMSLocal : Local total service time in milliseconds.
	readIOSizeKBLocal : Local read IO size in kilobytes.
	writeIOSizeKBLocal : Local write IO size in kilobytes.
	IOSizeKBLocal : Local total IO size in kilobytes.
	busyPctLocal : Local busy Percentage.
	queueLengthLocal : Local queue length.
	readIORemote : Remote read input/output operations per second.
	wirteIORemote : Remote write input/output operations per second.
	IORemote : Remote total input/output operations per second.
	readKBytesRemote : Remote read kilobytes.
	writeKBytesRemote : Remote write kilobytes.
	KBytesRemote : Remote total kilobytes.
	readServiceTimeMSRemote : Remote read service time in milliseconds.
	writeServiceTimeMSRemote : Remote write service time in milliseconds.
	ServiceTimeMSRemote : Remote total service time in milliseconds.
	readIOSizeKBRemote : Remote read IO size in kilobytes.
	writeIOSizeKBRemote : Remote write IO size in kilobytes.
	IOSizeKBRemote : Remote total IO size in kilobytes.
	busyPctRemote : Remote busy Percentage.
	queueLengthRemote : Remote queue length.
	RPO : Recovery point objective.	
	
  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARRCopyVolumeStatisticalReports_WSAPI   
    LASTEDIT: 25/09/2018
    KEYWORDS: Get-3PARRCopyVolumeStatisticalReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $vvName,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $TargetName,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Mode,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $RCopyGroup,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Summary,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Compareby,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NoOfRecords,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ComparebyField,
	  	  
	  [Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select at-list any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
	
	#Build uri
	$uri = '/systemreporter/'+$Action+'/remotecopyvolumestatistics/'+$Frequency
		
	if($vvName)	{ if($AtTime) { return "We cannot pass vvName in At Time report." } $uri = $uri+";volumeName:$vvName" }
	if($TargetName)	{ if($AtTime) { return "We cannot pass TargetName in At Time report." } $uri = $uri+";targetName:$TargetName" }
	If ($Mode) 
	{
		if($AtTime) { return "We cannot pass Mode in At Time report." }
		if($Mode.ToUpper() -eq "SYNC") { $uri = $uri+";mode:1" }
		elseif($Mode.ToUpper() -eq "PERIODIC"){	$uri = $uri+";mode:3" }
		elseif($Mode.ToUpper() -eq "ASYNC") { $uri = $uri+";mode:4" }
		else 
		{ 
			Write-DebugLog "Stop: Exiting Since -Mode $Mode in incorrect "
			Return "FAILURE : -Mode :- $Mode is an Incorrect Mode  [ SYNC | PERIODIC | ASYNC ] can be used only . "
		}
    }
	if($RCopyGroup)	{ if($AtTime) { return "We cannot pass RCopyGroup in At Time report." } $uri = $uri+";remoteCopyGroup:$RCopyGroup" }		
	if($Groupby) {  $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}
    if($Compareby)
	{ 
		$cmpVal = $Compareby.ToLower()
		if($cmpVal -eq "top" -OR $cmpVal -eq "bottom")
		{
			$uri = $uri+";compareby:$cmpVal,"
		}
		else
		{
			return "Compareby should be either top or bottom"
		}
		if($NoOfRecords)
		{
			$uri = $uri+$NoOfRecords+","
		}
		else
		{
			return "NoOfRecords is mandatory with Compareby. "
		}
		if($ComparebyField)
		{
			$uri = $uri+$ComparebyField
		}
		else
		{
			return "ComparebyField is mandatory with Compareby.please see the parameter help for this"
		}		
	}		
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARRCopyVolumeStatisticalReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARRCopyVolumeStatisticalReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARRCopyVolumeStatisticalReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARRCopyVolumeStatisticalReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARRCopyVolumeStatisticalReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARRCopyVolumeStatisticalReports_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARVLUNStatisticsReports_WSAPI
############################################################################################################################################
Function Get-3PARVLUNStatisticsReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Request VLUN statistics data using either Versus Time or At Time reports.
  
  .DESCRIPTION
    This cmdlet (Get-3PARVLUNStatisticsReports_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-vLunStatisticsReports_WSAPI) instead.
  
	Request VLUN statistics data using either Versus Time or At Time reports.
        
  .EXAMPLE 
	Get-3PARVLUNStatisticsReports_WSAPI -AtTime -Frequency_Hires
  
  .EXAMPLE  
	Get-3PARVLUNStatisticsReports_WSAPI -VersusTime -Frequency_Hires
	  
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -VersusTime -Frequency_Hires -VlunId 1
	  
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -AtTime -Frequency_Hires -VlunId "1,2"
	  
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -VersusTime -Frequency_Hires -VvName Test
	  
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -AtTime -Frequency_Hourly -VvSetName asvvset
	  
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -VersusTime -Frequency_Hourly -NSP "1:0:1"
	  
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -VersusTime -Frequency_Daily -HostName asHost
	  
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -VersusTime -Frequency_Daily -HostSetName asHostSet
	  
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -VersusTime -Frequency_Daily -Groupby "domain,volumeName"
	
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -VersusTime -Frequency_Hourly -Summary max
	
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -AtTime -Frequency_Hires -Summary max
  
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -VersusTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -AtTime -Frequency_Hires -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30"
        
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -AtTime -Frequency_Hires -LETime "2018-04-09T12:20:00+05:30"
        
  .EXAMPLE
	Get-3PARVLUNStatisticsReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30" -LETime "2018-04-09T12:20:00+05:30"	
		
  .PARAMETER VersusTime
	Request VLUNstatistics data using Versus Time reports.
	
  .PARAMETER AtTime
	Request VLUN statistics data using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily

  .PARAMETER VlunId
	Requests data for the specified VLUNs only. For example, specify lun:1,2,4. With no lun specified, the system calculates performance data for all VLUNs in the system
  
  .PARAMETER VvName
	Retrieves data for the specified volume or volumeset only. Specify the volumeset as volumeName:set:<vvset_name>. With no volumeName specified, the system calculates VLUN performance data for all the VLUNs in the system.
  
  .PARAMETER HostName
	Retrieves data for the specified host or hostset only. Specify the hostset as hostname:set:<hostset_name>. With no hostname specified, the system calculates VLUN performance data for all the hosts in the system.

  .PARAMETER VvSetName
	Specify the VV set name.
  
  .PARAMETER HostSetName
	Specify the Host Set Name.
  
  .PARAMETER NSP
	Retrieves data for the specified ports. For example, specify portPos: 1:0:1,2:1:3,6:2:1. With no portPos specified, the system calculates VLUN performance data for all ports in the system.
  
  .PARAMETER Groupby
	domain | volumeName | hostname| lun | hostWWN | node | slot | vvsetName | hostsetName | cardPort
	Groups sample data into specified categories. With no category specified, the system groups data into all categories. To specify multiple groupby categories, separate them using a comma (,). For example, slot,cardPort,type.
    
  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER Compareby
	It should be either top or bottom, Specifies whether to display the top records or the bottom records. Choose one.

  .PARAMETER NoOfRecords
	Specifies the number of records to return in the range of 1 to 32 (Versus TIme) and 1 to 128 (At Time).
	
  .PARAMETER ComparebyField
	please select any one from
	totalIOPs : Total IOPs.
  
  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARVLUNStatisticsReports_WSAPI   
    LASTEDIT: 18/07/2018
    KEYWORDS: Get-3PARVLUNStatisticsReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VlunId,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VvName,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $HostName,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VvSetName,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $HostSetName,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $NSP,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Summary,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Compareby,
	  
	  [Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NoOfRecords,
	  
	  [Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ComparebyField,
	  	  
	  [Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=17, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=18, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select at-list any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
		
	#Build uri
	$uri = '/systemreporter/'+$Action+'/vlunstatistics/'+$Frequency
		
	if($VlunId) { if($AtTime) { return "We cannot pass VlunId in At Time report." } $uri = $uri+";lun:$VlunId"}
	if($VvName) { if($AtTime) { return "We cannot pass VvName in At Time report." } $uri = $uri+";volumeName:$VvName"}
	if($HostName) { if($AtTime) { return "We cannot pass HostName in At Time report." } $uri = $uri+";hostname:$HostName"}
	if($VvSetName) { if($AtTime) { return "We cannot pass VvSetName in At Time report." } $uri = $uri+";volumeName:set:$VvSetName"}
	if($HostSetName) { if($AtTime) { return "We cannot pass HostSetName in At Time report." } $uri = $uri+";hostname:set:$HostSetName"}
	if($NSP) { if($AtTime) { return "We cannot pass NSP in At Time report." } $uri = $uri+";portPos:$NSP"}	
	if($Groupby) {  $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}
    if($Compareby)
	{ 
		$cmpVal = $Compareby.ToLower()
		if($cmpVal -eq "top" -OR $cmpVal -eq "bottom")
		{
			$uri = $uri+";compareby:$cmpVal,"
		}
		else
		{
			return "Compareby should be either top or bottom"
		}
		if($NoOfRecords)
		{
			$uri = $uri+$NoOfRecords+","
		}
		else
		{
			return "NoOfRecords is mandatory with Compareby. "
		}
		if($ComparebyField)
		{
			$uri = $uri+$ComparebyField
		}
		else
		{
			return "ComparebyField is mandatory with Compareby.please see the parameter help for this"
		}		
	}
		
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	
	#write-host "URL = $uri"
	
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARVLUNStatisticsReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARVLUNStatisticsReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARVLUNStatisticsReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARVLUNStatisticsReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARVLUNStatisticsReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARVLUNStatisticsReports_WSAPI

############################################################################################################################################
## FUNCTION Get-3PARVVSpaceReports_WSAPI
############################################################################################################################################
Function Get-3PARVVSpaceReports_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Request volume space data using either Versus Time or At Time reports.
  
  .DESCRIPTION
    This cmdlet (Get-3PARVVSpaceReports_WSAPI) will be deprecated in a later version of PowerShell Toolkit. Consider using the cmdlet  (Get-VvSpaceReports_WSAPI) instead.
  
	Request volume space data using either Versus Time or At Time reports.
        
  .EXAMPLE 
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires
  
  .EXAMPLE  
	Get-3PARVVSpaceReports_WSAPI -VersusTime -Frequency_Hires
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -VersusTime -Frequency_Hires -VvName xxx
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -VersusTime -Frequency_Hires -VvSetName asVVSet
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -VersusTime -Frequency_Hires -UserCPG ascpg
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -VersusTime -Frequency_Hires -SnapCPG assnpcpg
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -VersusTime -Frequency_Hires -ProvType 1
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -VersusTime -Frequency_Hires -Groupby id
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -VersusTime -Frequency_Hires -Groupby "id,name"
	
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires -VvName xxx
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires -VvSetName asVVSet
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires -UserCPG ascpg
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires -SnapCPG assnpcpg
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires -ProvType 1
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires -Groupby id
	        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires -Groupby "id,name"
	
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -VersusTime -Frequency_Hourly -Summary max
	
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires -Summary max
  
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -VersusTime -Frequency_Daily -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires -Compareby top -NoOfRecords 10 -ComparebyField totalSpaceMiB
	
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30"
        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires -LETime "2018-04-09T12:20:00+05:30"
        
  .EXAMPLE
	Get-3PARVVSpaceReports_WSAPI -AtTime -Frequency_Hires -GETime "2018-04-09T09:20:00+05:30" -LETime "2018-04-09T12:20:00+05:30"	
		
  .PARAMETER VersusTime
	Request  volume space data using Versus Time reports.
	
  .PARAMETER AtTime
	Request  volume space data using At Time reports.
	
  .PARAMETER Frequency_Hires
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• hires—based on 5 minutes (high resolution)
		
  .PARAMETER Frequency_Hourly
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:	
	• hourly
	
  .PARAMETER Frequency_Daily
	As part of the report identifier, you must specify one <samplefreq> parameter. The <samplefreq> parameter indicates how often to generate the performance sample data. You may specify only one.
	Options are:
	• daily

  .PARAMETER VvName
	Requests volume space sample data for the specified volume (vv_name) or volume set (vvset_name) only. Specify vvset as name:set:<vvset_name>. With no name specified, the system calculates volume space data for all volumes in the system.
  
  .PARAMETER VvSetName
	Requests volume space sample data for the specified volume (vv_name) or volume set (vvset_name) only.
  
  .PARAMETER UserCPG
	Retrieves volume space data for the specified userCPG volumes only. With no userCPG specified, the system calculates space data for all volumes in the system.
  
  .PARAMETER SnapCPG
	Retrieves space data for the specified snapCPG volumes only. With no snapCPG specified, the system calculates space data for all volumes in the system.
  
  .PARAMETER ProvType
	Retrieves space data for volumes that match the specified . With no provtype specified, the system calculates space data for all volumes in the system.
  
  .PARAMETER Groupby
	id | name | baseId | wwn | snapCPG | userCPG
	Optional parameter that groups sample data into specified categories. With no category specified, the system groups data into all categories. To specify multiple groupby categories, separate them using a comma (,). For example: domain,id,name,baseId,WWN.
      
  .PARAMETER Summary
	Provide at least one of the mandatory field names, and use a comma (,) to separate multiple fields.
	Mandatory 
	min : Display the minimum for each metric.
	max : Display the maximum for each metric.
	avg : Display the average for each metric.
	pct : Displays the percentile for each metric where pct is any floating number from 0 to 100. Separate multiple	pct with a comma (,).
	
	Optional
	perTime : When requesting data across multiple points in time(vstime) using multiple object groupings (groupby), use the perTime field name to compute 	summaries. Defaults to one summary computed across all records. Use this with the groupby field only.
	perGroup : When requesting data across multiple points in time,(vstime) using multiple object groupings (groupby),use the perGroup field name to compute summaries per object grouping. Defaults to one summary computed across all records.
	onlyCompareby : When using the compareby field to request data limited to certain object groupings, use this field name to compute summaries using only that reduced set of object groupings. Defaults to computing summaries from all records and ignores the limitation of the compareby option.
	
  .PARAMETER Compareby
	It should be either top or bottom, Specifies whether to display the top records or the bottom records. Choose one.

  .PARAMETER NoOfRecords
	Specifies the number of records to return in the range of 1 to 32 (Versus TIme) and 1 to 128 (At Time).
	
  .PARAMETER ComparebyField
	please select any one from
	totalSpaceUsedMiB : Total used space in MiB.
	userSpaceUsedMiB : Used user space in MiB.
	snapshotSpaceUsedMiB : Used snapshot space in MiB
	userSpaceFreeMiB : Free user space in MiB.
	snapshotSpaceFreeMiB : Free snapshot space in MiB.
	compaction : Compaction ratio.
	compression : Compression ratio.

  .PARAMETER GETime
	Gerater thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER LETime
	Lase thane time For At Time query expressions, you can use the sampleTime parameter
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Get-3PARVVSpaceReports_WSAPI   
    LASTEDIT: 18/07/2018
    KEYWORDS: Get-3PARVVSpaceReports_WSAPI
   
  .Link
     http://www.hpe.com
 
  #Requires PS -Version 3.0
   
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $VersusTime,
	  
	  [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $AtTime,
	  
	  [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hires,
	  
	  [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Hourly,
	  
	  [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
      [Switch]
	  $Frequency_Daily,
	  
	  [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VvName,
	  
	  [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $VvSetName,
	  
	  [Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $UserCPG,
	  
	  [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $SnapCPG,
	  
	  [Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ProvType,
	  
	  [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Groupby,
	  
	  [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Summary,
	  
	  [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $Compareby,
	  
	  [Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
      [int]
	  $NoOfRecords,
	  
	  [Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $ComparebyField,
	  	  
	  [Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $GETime,
	  
	  [Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
      [System.String]
	  $LETime,
	  
	  [Parameter(Position=17, Mandatory=$false, ValueFromPipeline=$true)]
	  $WsapiConnection = $global:WsapiConnection
	)

  Begin 
  {
	#Test if connection exist
	Test-3PARConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {
	$Result = $null
	$dataPS = $null
	$Action = $null
	$Frequency = $null
	$flg = "Yes"
	$addQuery = "No"
	$Query="?query=""  """
	
	if($VersusTime)	{	$Action = "vstime"	}	elseif($AtTime)	{	$Action = "attime"	}	else{	Return "Please Select at-list any one from Versus Time or At Time for statistics report." }
	
	if($Frequency_Hires){	$Frequency = "hires"	}	elseif($Frequency_Hourly)	{	$Frequency = "hourly"	} elseif($Frequency_Daily)	{	$Frequency = "daily"	}	else{ Return "Please select Frequency it is mandatory" }
		
	#Build uri
	$uri = '/systemreporter/'+$Action+'/volumespacedata/'+$Frequency
		
	if($VvName) { if($AtTime) { return "We cannot pass VvName in At Time report." } $uri = $uri+";name:$VvName"}
	if($VvSetName) { if($AtTime) { return "We cannot pass VvSetName in At Time report." } $uri = $uri+";name:set:$VvSetName"}
	if($UserCPG) { if($AtTime) { return "We cannot pass UserCPG in At Time report." } $uri = $uri+";userCPG:$UserCPG"}
	if($SnapCPG) { if($AtTime) { return "We cannot pass SnapCPG in At Time report." } $uri = $uri+";snapCPG:$SnapCPG"}
	if($ProvType) { if($AtTime) { return "We cannot pass ProvType in At Time report." } $uri = $uri+";provType:$ProvType"}		
	if($Groupby) {  $uri = $uri+";groupby:$Groupby"}
	if($Summary) { $uri = $uri+";summary:$Summary"}
    if($Compareby)
	{ 
		$cmpVal = $Compareby.ToLower()
		if($cmpVal -eq "top" -OR $cmpVal -eq "bottom")
		{
			$uri = $uri+";compareby:$cmpVal,"
		}
		else
		{
			return "Compareby should be either top or bottom"
		}
		if($NoOfRecords)
		{
			$uri = $uri+$NoOfRecords+","
		}
		else
		{
			return "NoOfRecords is mandatory with Compareby. "
		}
		if($ComparebyField)
		{
			$uri = $uri+$ComparebyField
		}
		else
		{
			return "ComparebyField is mandatory with Compareby.please see the parameter help for this"
		}		
	}
		
	if($GETime)
	{		
		$Query = $Query.Insert($Query.Length-3," sampleTime GE $GETime")			
		
		if($LETime)
		{
			$Query = $Query.Insert($Query.Length-3," AND sampleTime LE $LETime")
			$flg = "No"
		}
		$addQuery = "Yes"
	}
	if($LETime)
	{
		if($flg -eq "Yes")
		{
			$Query = $Query.Insert($Query.Length-3," sampleTime LE $LETime")
		}
		$addQuery = "Yes"		
	}
	
	if($addQuery -eq "Yes")
	{
		$uri = $uri+$Query
	}
	
	#write-host "URL = $uri"
	
	#Request
	$Result = Invoke-3parWSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
	
	if($Result.StatusCode -eq 200)
	{
		$dataPS = ($Result.content | ConvertFrom-Json).members	
	}		
		  
	if($Result.StatusCode -eq 200)
	{
		if($dataPS.Count -gt 0)
		{
			write-host ""
			write-host "Cmdlet executed successfully" -foreground green
			write-host ""
			Write-DebugLog "SUCCESS: Command Get-3PARVVSpaceReports_WSAPI Successfully Executed" $Info
			
			return $dataPS
		}
		else
		{
			write-host ""
			write-host "FAILURE : While Executing Get-3PARVVSpaceReports_WSAPI. Expected Result Not Found with Given Filter Option ." -foreground red
			write-host ""
			Write-DebugLog "FAILURE : While Executing Get-3PARVVSpaceReports_WSAPI. Expected Result Not Found with Given Filter Option." $Info
			
			return 
		}
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Executing Get-3PARVVSpaceReports_WSAPI." -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-3PARVVSpaceReports_WSAPI." $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-3PARVVSpaceReports_WSAPI

############################################################################################################################################
## FUNCTION Add-DiskType
############################################################################################################################################
Function Add-DiskType
{
<#
  .SYNOPSIS
    find and add disk type to temp variable.
  
  .DESCRIPTION
    find and add disk type to temp variable. 
        
  .EXAMPLE
    Add-DiskType -Dt $td

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME:  Add-DiskType  
    LASTEDIT: 25/09/2018
    KEYWORDS: 3parCmdList
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
 [CmdletBinding()]
	param
	(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$DT,

		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		$WsapiConnection = $global:WsapiConnection
	)
	Begin 
	{
		# Test if connection exist
		Test-3PARConnection -WsapiConnection $WsapiConnection
	}
	Process 
	{
		$lista = $DT.split(",")		
		$count = 1
		[string]$DTyp
		foreach($sub in $lista)
		{
			$val_Fix = "FC","NL","SSD","SCM"
			$val_Input =$sub
			if($val_Fix -eq $val_Input)
			{
				if($val_Input.ToUpper() -eq "FC")
				{
					$DTyp = $DTyp + "1"
				}
				if($val_Input.ToUpper() -eq "NL")
				{
					$DTyp = $DTyp + "2"
				}
				if($val_Input.ToUpper() -eq "SSD")
				{
					$DTyp = $DTyp + "3"
				}
				if($val_Input.ToUpper() -eq "SCM")
				{
					$DTyp = $DTyp + "4"
				}
				if($lista.Count -gt 1)
				{
					if($lista.Count -ne $count)
					{					
						$DTyp = $DTyp + ","
						$count = $count + 1
					}				
				}
			}
			else
			{ 
				Write-DebugLog "Stop: Exiting Since -DiskType $DT in incorrect "
				Return "FAILURE : -DiskType :- $DT is an Incorrect, Please Use [ FC | NL | SSD | SCM] only ."
			}						
		}
		return $DTyp.Trim()		
	}
	End {  }
 }# Ended Add-DiskType
 
############################################################################################################################################
## FUNCTION Add-RedType
############################################################################################################################################
Function Add-RedType
{
<#
  .SYNOPSIS
    find and add Red type to temp variable.
  
  .DESCRIPTION
    find and add Red type to temp variable. 
        
  .EXAMPLE
    Add-RedType -RT $td

  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME:  Add-RedType  
    LASTEDIT: 25/09/2018
    KEYWORDS: 3parCmdList
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
 [CmdletBinding()]
	param
	(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$RT,

		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		$WsapiConnection = $global:WsapiConnection
	)
	Begin 
	{
		# Test if connection exist
		Test-3PARConnection -WsapiConnection $WsapiConnection
	}
	Process 
	{
		$lista = $RT.split(",")		
		$count = 1
		[string]$RType
		foreach($sub in $lista)
		{
			$val_Fix = "R0","R1","R5","R6"
			$val_Input =$sub
			if($val_Fix -eq $val_Input)
			{
				if($val_Input.ToUpper() -eq "R0")
				{
					$RType = $RType + "1"
				}
				if($val_Input.ToUpper() -eq "R1")
				{
					$RType = $RType + "2"
				}
				if($val_Input.ToUpper() -eq "R5")
				{
					$RType = $RType + "3"
				}
				if($val_Input.ToUpper() -eq "R6")
				{
					$RType = $RType + "4"
				}
				if($lista.Count -gt 1)
				{
					if($lista.Count -ne $count)
					{					
						$RType = $RType + ","
						$count = $count + 1
					}				
				}
			}
			else
			{ 
				Write-DebugLog "Stop: Exiting Since -RedType $RT in incorrect "
				Return "FAILURE : -RedType :- $RT is an Incorrect, Please Use [ R0 | R1 | R5 | R6 ] only ."
			}						
		}
		return $RType.Trim()		
	}
	End {  }
 }# Ended Add-RedType

Export-ModuleMember New-3PARWSAPIConnection , Close-3PARWSAPIConnection , Get-3PARRCStatisticalReports_WSAPI , Get-3PARRCopyVolumeStatisticalReports_WSAPI , Get-3PARQoSStatisticalReports_WSAPI , New-3PARFileShares_WSAPI , Get-3PARVVSpaceReports_WSAPI , Get-3PARVLUNStatisticsReports_WSAPI , Get-3PARPortStatisticsReports_WSAPI , Get-3PARPDSpaceReports_WSAPI , Get-3PARPDStatisticsReports_WSAPI , Get-3PARPDCapacityReports_WSAPI , Get-3PARCPUStatisticalDataReports_WSAPI , Get-3PARCPGStatisticalDataReports_WSAPI , Get-3PARCPGSpaceDataReports_WSAPI , Get-3PARCacheMemoryStatisticsDataReports_WSAPI , Get-3PARAOConfiguration_WSAPI , Get-3PARRoles_WSAPI , Get-3PARUsers_WSAPI , Get-3PARFlashCache_WSAPI , Remove-3PARFlashCache_WSAPI , New-3PARFlashCache_WSAPI , Set-3PARVVSetFlashCachePolicy_WSAPI , Restore-3PARFilePersonaQuota_WSAPI , Group-3PARFilePersonaQuota_WSAPI , Get-3PARFilePersonaQuota_WSAPI , Remove-3PARFilePersonaQuota_WSAPI , Update-3PARFilePersonaQuota_WSAPI , New-3PARFilePersonaQuota_WSAPI , Get-3PARDirPermission_WSAPI , Get-3PARFileShare_WSAPI , Remove-3PARFileShare_WSAPI , Get-3PARFileStoreSnapshot_WSAPI , Remove-3PARFileStoreSnapshot_WSAPI , New-3PARFileStoreSnapshot_WSAPI , Get-3PARFileStore_WSAPI , Remove-3PARFileStore_WSAPI , Update-3PARFileStore_WSAPI , New-3PARFileStore_WSAPI , Get-3PARVFS_WSAPI , Remove-3PARVFS_WSAPI , New-3PARVFS_WSAPI , Get-3PAREventLogs_WSAPI , Get-3PARRCopyLink_WSAPI , Get-3PARRCopyGroupVV_WSAPI , Get-3PARRCopyGroupTarget_WSAPI , Get-3PARRCopyGroup_WSAPI , Get-3PARRCopyTarget_WSAPI , Get-3PARRCopyInfo_WSAPI , New-3PARSnapRCGroupVV_WSAPI , Remove-3PARTargetFromRCopyGroup_WSAPI , Add-3PARTargetToRCopyGroup_WSAPI , Update-3PARRCopyTarget_WSAPI , New-3PARRCopyTarget_WSAPI , Remove-3PARVVFromRCopyGroup_WSAPI , Add-3PARVVToRCopyGroup_WSAPI , Restore-3PARRCopyGroup_WSAPI , Update-3PARRCopyGroup_WSAPI , Update-3PARRCopyGroupTarget_WSAPI , Remove-3PARRCopyGroup_WSAPI , Sync-3PARRCopyGroup_WSAPI , Stop-3PARRCopyGroup_WSAPI , Start-3PARRCopyGroup_WSAPI , New-3PARRCopyGroup_WSAPI , Set-3PARFlashCache_WSAPI , Stop-3PAROngoingTask_WSAPI , Get-3PARTask_WSAPI , Get-3PARWSAPIConfigInfo , Get-3PARVersion_WSAPI , Update-3PARSystem_WSAPI , Get-3PARSystem_WSAPI , Update-3PARVVOrVVSets_WSAPI , Stop-3PARVVSetPhysicalCopy_WSAPI , Reset-3PARVVSetPhysicalCopy_WSAPI , New-3PARVVSetPhysicalCopy_WSAPI , New-3PARVVSetSnapshot_WSAPI , Stop-3PARPhysicalCopy_WSAPI , Move-3PARVirtualCopy_WSAPI , Move-3PARVVSetVirtualCopy_WSAPI , Reset-3PARPhysicalCopy_WSAPI , New-3PARVVPhysicalCopy_WSAPI , New-3PARVVListGroupSnapshot_WSAPI , New-3PARVVSnapshot_WSAPI , Get-3PARVLunUsingFilters_WSAPI , Get-3PARVLun_WSAPI , Remove-3PARVLun_WSAPI , New-3PARVLun_WSAPI , Remove-3PARISCSIVlan_WSAPI , Reset-3PARISCSIPort_WSAPI , Set-3PARISCSIVlan_WSAPI , New-3PARISCSIVlan_WSAPI , Set-3PARISCSIPort_WSAPI , Get-3PARFCSwitches_WSAPI , Get-3PARPortDeviceTDZ_WSAPI , Get-3PARPortDevices_WSAPI , Get-3PARPort_WSAPI , Get-3PARiSCSIVLANs_WSAPI , Get-3PARFPGReclamationTasks_WSAPI , Get-3PARFPG_WSAPI , Remove-3PARFPG_WSAPI , New-3PARFPG_WSAPI , Get-3PARFileServices_WSAPI , Get-3PARVVSet_WSAPI , Remove-3PARVVSet_WSAPI , Update-3PARVVSet_WSAPI , New-3PARVVSet_WSAPI , Get-3PARHostSet_WSAPI , Remove-3PARHostSet_WSAPI , Add-Rem3PARHostWWN_WSAPI , Update-3PARHost_WSAPI , Update-3PARHostSet_WSAPI , New-3PARHostSet_WSAPI , Get-3PARHost_WSAPI , Get-3PARHostWithFilter_WSAPI , Get-3PARHostPersona_WSAPI , Remove-3PARHost_WSAPI , New-3PARHost_WSAPI , Get-3PARCapacity_WSAPI , Get-3PARVV_WSAPI , Remove-3PARVV_WSAPI , Compress-3PARVV_WSAPI , Resize-Grow3PARVV_WSAPI , Get-3parVVSpaceDistribution_WSAPI , Update-3PARVV_WSAPI , New-3PARVV_WSAPI , Get-3PARCpg_WSAPI , Remove-3PARCpg_WSAPI , Update-3PARCpg_WSAPI, New-3PARCpg_WSAPI , Open-3PARSSE_WSAPI 

# SIG # Begin signature block
# MIIlhQYJKoZIhvcNAQcCoIIldjCCJXICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCACx12V96YztERH
# PBXg1ZsILKpUbLYmV+c/UReI9iv3/aCCFikwggVMMIIDNKADAgECAhMzAAAANdjV
# WVsGcUErAAAAAAA1MA0GCSqGSIb3DQEBBQUAMH8xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAMTIE1pY3Jvc29mdCBDb2RlIFZlcmlm
# aWNhdGlvbiBSb290MB4XDTEzMDgxNTIwMjYzMFoXDTIzMDgxNTIwMzYzMFowbzEL
# MAkGA1UEBhMCU0UxFDASBgNVBAoTC0FkZFRydXN0IEFCMSYwJAYDVQQLEx1BZGRU
# cnVzdCBFeHRlcm5hbCBUVFAgTmV0d29yazEiMCAGA1UEAxMZQWRkVHJ1c3QgRXh0
# ZXJuYWwgQ0EgUm9vdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALf3
# GjPm8gAELTngTlvtH7xsD821+iO2zt6bETOXpClMfZOfvUq8k+0DGuOPz+VtUFrW
# lymUWoCwSXrbLpX9uMq/NzgtHj6RQa1wVsfwTz/oMp50ysiQVOnGXw94nZpAPA6s
# YapeFI+eh6FqUNzXmk6vBbOmcZSccbNQYArHE504B4YCqOmoaSYYkKtMsE8jqzpP
# hNjfzp/haW+710LXa0Tkx63ubUFfclpxCDezeWWkWaCUN/cALw3CknLa0Dhy2xSo
# RcRdKn23tNbE7qzNE0S3ySvdQwAl+mG5aWpYIxG3pzOPVnVZ9c0p10a3CitlttNC
# bxWyuHv77+ldU9U0WicCAwEAAaOB0DCBzTATBgNVHSUEDDAKBggrBgEFBQcDAzAS
# BgNVHRMBAf8ECDAGAQH/AgECMB0GA1UdDgQWBBStvZh6NLQm9/rEJlTvA73gJMtU
# GjALBgNVHQ8EBAMCAYYwHwYDVR0jBBgwFoAUYvsKIVt/Q24R2glUUGv10pZx8Z4w
# VQYDVR0fBE4wTDBKoEigRoZEaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9j
# cmwvcHJvZHVjdHMvTWljcm9zb2Z0Q29kZVZlcmlmUm9vdC5jcmwwDQYJKoZIhvcN
# AQEFBQADggIBADYrovLhMx/kk/fyaYXGZA7Jm2Mv5HA3mP2U7HvP+KFCRvntak6N
# NGk2BVV6HrutjJlClgbpJagmhL7BvxapfKpbBLf90cD0Ar4o7fV3x5v+OvbowXvT
# gqv6FE7PK8/l1bVIQLGjj4OLrSslU6umNM7yQ/dPLOndHk5atrroOxCZJAC8UP14
# 9uUjqImUk/e3QTA3Sle35kTZyd+ZBapE/HSvgmTMB8sBtgnDLuPoMqe0n0F4x6GE
# NlRi8uwVCsjq0IT48eBr9FYSX5Xg/N23dpP+KUol6QQA8bQRDsmEntsXffUepY42
# KRk6bWxGS9ercCQojQWj2dUk8vig0TyCOdSogg5pOoEJ/Abwx1kzhDaTBkGRIywi
# pacBK1C0KK7bRrBZG4azm4foSU45C20U30wDMB4fX3Su9VtZA1PsmBbg0GI1dRtI
# uH0T5XpIuHdSpAeYJTsGm3pOam9Ehk8UTyd5Jz1Qc0FMnEE+3SkMc7HH+x92DBdl
# BOvSUBCSQUns5AZ9NhVEb4m/aX35TUDBOpi2oH4x0rWuyvtT1T9Qhs1ekzttXXya
# Pz/3qSVYhN0RSQCix8ieN913jm1xi+BbgTRdVLrM9ZNHiG3n71viKOSAG0DkDyrR
# fyMVZVqsmZRDP0ZVJtbE+oiV4pGaoy0Lhd6sjOD5Z3CfcXkCMfdhoinEMIIFYTCC
# BEmgAwIBAgIQJl6ULMWyOufq8fQJzRxR/TANBgkqhkiG9w0BAQsFADB8MQswCQYD
# VQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdT
# YWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1NlY3Rp
# Z28gUlNBIENvZGUgU2lnbmluZyBDQTAeFw0xOTA0MjYwMDAwMDBaFw0yMDA0MjUy
# MzU5NTlaMIHSMQswCQYDVQQGEwJVUzEOMAwGA1UEEQwFOTQzMDQxCzAJBgNVBAgM
# AkNBMRIwEAYDVQQHDAlQYWxvIEFsdG8xHDAaBgNVBAkMEzMwMDAgSGFub3ZlciBT
# dHJlZXQxKzApBgNVBAoMIkhld2xldHQgUGFja2FyZCBFbnRlcnByaXNlIENvbXBh
# bnkxGjAYBgNVBAsMEUhQIEN5YmVyIFNlY3VyaXR5MSswKQYDVQQDDCJIZXdsZXR0
# IFBhY2thcmQgRW50ZXJwcmlzZSBDb21wYW55MIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEAvxp2KuPOGop6ObVmKZ17bhP+oPpH4ZdDHwiaCP2KKn1m13Wd
# 5YuMcYOmF6xxb7rK8vcFRRf72MWwPvI05bKGZ1hKilh4UQZ8IpDZ6PlVF6cOFRKv
# PVt3r1nzA3fpEptdNmK54HktcfQIlTBNa0gBAzuWD5nwXckfwTujfa9bxT3ZLfNV
# V6rA9oMmsIUCF5rKQBnlwYGP5ceFFW0KBfdDNOZSLI5/96AbWO7Kh7+lfFjYYYyp
# j9a/+BdgxeLAUAc3wwtspxPui0FPDpmFAFs3Mj/eLSBjlBwd+Gb1OzQvgE+fagoy
# Kh6MB8xO4dueEdwJBEyNqNQIatE+klCMAS3L/QIDAQABo4IBhjCCAYIwHwYDVR0j
# BBgwFoAUDuE6qFM6MdWKvsG7rWcaA4WtNA4wHQYDVR0OBBYEFPqXMYWJeByh5r0Z
# 7Cfmb6MYpSExMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBABgNVHSAEOTA3MDUGDCsG
# AQQBsjEBAgEDAjAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQ
# UzBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3Rp
# Z29SU0FDb2RlU2lnbmluZ0NBLmNybDBzBggrBgEFBQcBAQRnMGUwPgYIKwYBBQUH
# MAKGMmh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1JTQUNvZGVTaWduaW5n
# Q0EuY3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkq
# hkiG9w0BAQsFAAOCAQEAfggdDqfErm1J/WVBlc2H1wSKATk/d/vgypGsrFU1uOqv
# 3qJrz9X51HMMh/7zn5J6pKonnj5Gn9unqYPbBjyEZTYPDPfmFZNC9zZC+vhxO0mV
# PCiV9wd1f1sJjF4GBcNi/eUbCSXsXeiDWxRs1ISFj5pDp+sefNEpyMx6ryObuZ/G
# 0m3TsvMwgFy/oRKB7rcL8tACN+K4lotiuFDYjy0+vB7VuorM0fmvs9BIAnatbCz7
# begsrw0tRhw9A3tB3fEtgEZAOHsK1vg+CqFnB1vbNX3XLHw4znn7+fYdjlL1ZRo+
# zoGO6MGPIrILnlQnsldwpwYYd619q1aVkMZ8GycvojCCBXcwggRfoAMCAQICEBPq
# KHBb9OztDDZjCYBhQzYwDQYJKoZIhvcNAQEMBQAwbzELMAkGA1UEBhMCU0UxFDAS
# BgNVBAoTC0FkZFRydXN0IEFCMSYwJAYDVQQLEx1BZGRUcnVzdCBFeHRlcm5hbCBU
# VFAgTmV0d29yazEiMCAGA1UEAxMZQWRkVHJ1c3QgRXh0ZXJuYWwgQ0EgUm9vdDAe
# Fw0wMDA1MzAxMDQ4MzhaFw0yMDA1MzAxMDQ4MzhaMIGIMQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNV
# BAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJT
# QSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAIASZRc2DsPbCLPQrFcNdu3NJ9NMrVCDYeKqIE0JLWQJ3M6Jn8w9
# qez2z8Hc8dOx1ns3KBErR9o5xrw6GbRfpr19naNjQrZ28qk7K5H44m/Q7BYgkAk+
# 4uh0yRi0kdRiZNt/owbxiBhqkCI8vP4T8IcUe/bkH47U5FHGEWdGCFHLhhRUP7wz
# /n5snP8WnRi9UY41pqdmyHJn2yFmsdSbeAPAUDrozPDcvJ5M/q8FljUfV1q3/875
# PbcstvZU3cjnEjpNrkyKt1yatLcgPcp/IjSufjtoZgFE5wFORlObM2D3lL5TN5Bz
# Q/Myw1Pv26r+dE5px2uMYJPexMcM3+EyrsyTO1F4lWeL7j1W/gzQaQ8bD/MlJmsz
# bfduR/pzQ+V+DqVmsSl8MoRjVYnEDcGTVDAZE6zTfTen6106bDVc20HXEtqpSQvf
# 2ICKCZNijrVmzyWIzYS4sT+kOQ/ZAp7rEkyVfPNrBaleFoPMuGfi6BOdzFuC00yz
# 7Vv/3uVzrCM7LQC/NVV0CUnYSVgaf5I25lGSDvMmfRxNF7zJ7EMm0L9BX0CpRET0
# medXh55QH1dUqD79dGMvsVBlCeZYQi5DGky08CVHWfoEHpPUJkZKUIGy3r54t/xn
# FeHJV4QeD2PW6WK61l9VLupcxigIBCU5uA4rqfJMlxwHPw1S9e3vL4IPAgMBAAGj
# gfQwgfEwHwYDVR0jBBgwFoAUrb2YejS0Jvf6xCZU7wO94CTLVBowHQYDVR0OBBYE
# FFN5v1qqK0rPVIDh2JvAnfKyA2bLMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8E
# BTADAQH/MBEGA1UdIAQKMAgwBgYEVR0gADBEBgNVHR8EPTA7MDmgN6A1hjNodHRw
# Oi8vY3JsLnVzZXJ0cnVzdC5jb20vQWRkVHJ1c3RFeHRlcm5hbENBUm9vdC5jcmww
# NQYIKwYBBQUHAQEEKTAnMCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1
# c3QuY29tMA0GCSqGSIb3DQEBDAUAA4IBAQCTZfY3g5UPXsOCHB/Wd+c8isCqCfDp
# Cybx4MJqdaHHecm5UmDIKRIO8K0D1gnEdt/lpoGVp0bagleplZLFto8DImwzd8F7
# MhduB85aFEE6BSQb9hQGO6glJA67zCp13blwQT980GM2IQcfRv9gpJHhZ7zeH34Z
# FMljZ5HqZwdrtI+LwG5DfcOhgGyyHrxThX3ckKGkvC3vRnJXNQW/u0a7bm03mbb/
# I5KRxm5A+I8pVupf1V8UU6zwT2Hq9yLMp1YL4rg0HybZexkFaD+6PNQ4BqLT5o8O
# 47RxbUBCxYS0QJUr9GWgSHn2HYFjlp1PdeD4fOSOqdHyrYqzjMchzcLvMIIF9TCC
# A92gAwIBAgIQHaJIMG+bJhjQguCWfTPTajANBgkqhkiG9w0BAQwFADCBiDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBD
# aXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVT
# RVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTgxMTAyMDAw
# MDAwWhcNMzAxMjMxMjM1OTU5WjB8MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3Jl
# YXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0
# aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBD
# QTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAIYijTKFehifSfCWL2MI
# Hi3cfJ8Uz+MmtiVmKUCGVEZ0MWLFEO2yhyemmcuVMMBW9aR1xqkOUGKlUZEQauBL
# Yq798PgYrKf/7i4zIPoMGYmobHutAMNhodxpZW0fbieW15dRhqb0J+V8aouVHltg
# 1X7XFpKcAC9o95ftanK+ODtj3o+/bkxBXRIgCFnoOc2P0tbPBrRXBbZOoT5Xax+Y
# vMRi1hsLjcdmG0qfnYHEckC14l/vC0X/o84Xpi1VsLewvFRqnbyNVlPG8Lp5UEks
# 9wO5/i9lNfIi6iwHr0bZ+UYc3Ix8cSjz/qfGFN1VkW6KEQ3fBiSVfQ+noXw62oY1
# YdMCAwEAAaOCAWQwggFgMB8GA1UdIwQYMBaAFFN5v1qqK0rPVIDh2JvAnfKyA2bL
# MB0GA1UdDgQWBBQO4TqoUzox1Yq+wbutZxoDha00DjAOBgNVHQ8BAf8EBAMCAYYw
# EgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHSUEFjAUBggrBgEFBQcDAwYIKwYBBQUH
# AwgwEQYDVR0gBAowCDAGBgRVHSAAMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9j
# cmwudXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9y
# aXR5LmNybDB2BggrBgEFBQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQu
# dXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEF
# BQcwAYYZaHR0cDovL29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOC
# AgEATWNQ7Uc0SmGk295qKoyb8QAAHh1iezrXMsL2s+Bjs/thAIiaG20QBwRPvrjq
# iXgi6w9G7PNGXkBGiRL0C3danCpBOvzW9Ovn9xWVM8Ohgyi33i/klPeFM4MtSkBI
# v5rCT0qxjyT0s4E307dksKYjalloUkJf/wTr4XRleQj1qZPea3FAmZa6ePG5yOLD
# CBaxq2NayBWAbXReSnV+pbjDbLXP30p5h1zHQE1jNfYw08+1Cg4LBH+gS667o6XQ
# hACTPlNdNKUANWlsvp8gJRANGftQkGG+OY96jk32nw4e/gdREmaDJhlIlc5KycF/
# 8zoFm/lv34h/wCOe0h5DekUxwZxNqfBZslkZ6GqNKQQCd3xLS81wvjqyVVp4Pry7
# bwMQJXcVNIr5NsxDkuS6T/FikyglVyn7URnHoSVAaoRXxrKdsbwcCtp8Z359Luko
# TBh+xHsxQXGaSynsCz1XUNLK3f2eBVHlRHjdAd6xdZgNVCT98E7j4viDvXK6yz06
# 7vBeF5Jobchh+abxKgoLpbn0nu6YMgWFnuv5gynTxix9vTp3Los3QqBqgu07SqqU
# EKThDfgXxbZaeTMYkuO1dfih6Y4KJR7kHvGfWocj/5+kUZ77OYARzdu1xKeogG/l
# U9Tg46LC0lsa+jImLWpXcBw8pFguo/NbSwfcMlnzh6cabVgxgg6yMIIOrgIBATCB
# kDB8MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAw
# DgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAiBgNV
# BAMTG1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBDQQIQJl6ULMWyOufq8fQJzRxR
# /TANBglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJ
# AzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8G
# CSqGSIb3DQEJBDEiBCAFenVdX+P8wqZVM+fzzN1ul1Lw849rl3ZWaeuagux2bTAN
# BgkqhkiG9w0BAQEFAASCAQAI/PRvzNNYK02IEP7LbIuVw01+Xc9JQf9ZHHajBnlf
# 3oz5A/+ZW2+MstahCPZdjNzpbDoonsyAJvK/9+VgCoV1hhQP+MthXlo5P6uz6jMG
# OLaQlIqcSHHHQ8kFC7899x611p/Aq1spq/Be/0UO+EXjdzkS8OXOTBnoQRvILc5P
# bkRVUDItmRZjPjFB47Kkg7vcbMqNJSgoguKMqnJvpKmdGh3n5dZ+KzY4AV0k8a4O
# bC6y+b32BTAFiswzt3+yPIGxwrIUOUCRdEIBdz8tP/Z56MTm5v789FJx5mWli9Hw
# qBeUov2N3meDrwMWLPHojM2RN5NNo6QyPRUOSB4ZXgmzoYIMdDCCDHAGCisGAQQB
# gjcDAwExggxgMIIMXAYJKoZIhvcNAQcCoIIMTTCCDEkCAQMxDzANBglghkgBZQME
# AgEFADCBrwYLKoZIhvcNAQkQAQSggZ8EgZwwgZkCAQEGCSsGAQQBoDICAzAxMA0G
# CWCGSAFlAwQCAQUABCC5+EZ4MvPKE56ZYwzxgzyLGsvX3M60bPN1w6F27EAWOQIU
# BlHHSCpGg3AH4lLisTNZ461G/MQYDzIwMTkwODIyMTA1MjUxWqAvpC0wKzEpMCcG
# A1UEAwwgR2xvYmFsU2lnbiBUU0EgZm9yIEFkdmFuY2VkIC0gRzKgggjTMIIEtjCC
# A56gAwIBAgIMDKfPXQcHJKyJ55o6MA0GCSqGSIb3DQEBCwUAMFsxCzAJBgNVBAYT
# AkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxT
# aWduIFRpbWVzdGFtcGluZyBDQSAtIFNIQTI1NiAtIEcyMB4XDTE4MDIxOTAwMDAw
# MFoXDTI5MDMxODEwMDAwMFowKzEpMCcGA1UEAwwgR2xvYmFsU2lnbiBUU0EgZm9y
# IEFkdmFuY2VkIC0gRzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC3
# x5KKKNjzkctQDV3rKUTBglmlymTOvYO1UeWUzG6Amhds3P9i5jZDXgHCDGSNynee
# 9l13RbleyCTrQTcRZjesyM10m8yz70zifxvOc77Jlp01Hnz3VPds7KAS1q6ZnWPE
# eF9ZqS4i9cMn2LJbRWMnkP+MsT2ptPMOwPEgZQaJnQMco7BSQYU067zLzlT2Ev6z
# AYlKpvpUxR/70xzA47+X4z/QG/lAxxvV6yZ8QzDHcPJ4EaqFTqUODQBKOhF3o8oj
# AYCeyJNWXUbMitjSqgqEhbKJW9UyzkF7GE5UyqvRUl4S0ySeVvMMj929ko551UGJ
# w6Og5ZH8x2edhzPOcTJzAgMBAAGjggGoMIIBpDAOBgNVHQ8BAf8EBAMCB4AwTAYD
# VR0gBEUwQzBBBgkrBgEEAaAyAR4wNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cu
# Z2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYDVR0TBAIwADAWBgNVHSUBAf8E
# DDAKBggrBgEFBQcDCDBGBgNVHR8EPzA9MDugOaA3hjVodHRwOi8vY3JsLmdsb2Jh
# bHNpZ24uY29tL2dzL2dzdGltZXN0YW1waW5nc2hhMmcyLmNybDCBmAYIKwYBBQUH
# AQEEgYswgYgwSAYIKwYBBQUHMAKGPGh0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5j
# b20vY2FjZXJ0L2dzdGltZXN0YW1waW5nc2hhMmcyLmNydDA8BggrBgEFBQcwAYYw
# aHR0cDovL29jc3AyLmdsb2JhbHNpZ24uY29tL2dzdGltZXN0YW1waW5nc2hhMmcy
# MB0GA1UdDgQWBBQtbm7RjeUDgO7nY+mn2doLPFciPTAfBgNVHSMEGDAWgBSSIadK
# lV1ksJu0HuYAN0fmnUErTDANBgkqhkiG9w0BAQsFAAOCAQEAjf0dH4+I02X4tVxG
# 6afTtj9Ky0MFwgcNw14DhCM3qHqMlyP/J5yEfWHrXEtXPpv0RNuAWPe2Zd6PEgpf
# p4d0t9oUQIdR7J9KR1XwF+gYPnEgMeYoIqtO9q6ca8LnRPtoDSB/Uz+UG6GGgk4y
# FhBaP4lYwdC027aQ+40y6aFLRlA3tsM66SkkEpJaTiu5tgp6NoyXwO+JfDPeMeGh
# l+TnRa1hUv1aidNUfopNW4l7DpZ30fI8OBva+aVhIGUCvMWt1wxiECgs3bbjqGEA
# rAgmo42F0GTJNpAeilLJh401pV1IkfyTpqVl8ez5OtylLJ4EbWIz/t76n8XOr5Xz
# UajyzjCCBBUwggL9oAMCAQICCwQAAAAAATGJxlAEMA0GCSqGSIb3DQEBCwUAMEwx
# IDAeBgNVBAsTF0dsb2JhbFNpZ24gUm9vdCBDQSAtIFIzMRMwEQYDVQQKEwpHbG9i
# YWxTaWduMRMwEQYDVQQDEwpHbG9iYWxTaWduMB4XDTExMDgwMjEwMDAwMFoXDTI5
# MDMyOTEwMDAwMFowWzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hB
# MjU2IC0gRzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCqm47DqxFR
# JQG2lpTiT9jBCPZGI9lFxZWXW6sav9JsV8kzBh+gD8Y8flNIer+dh56v7sOMR+FC
# 7OPjoUpsDBfEpsG5zVvxHkSJjv4L3iFYE+5NyMVnCxyys/E0dpGiywdtN8WgRyYC
# FaSQkal5ntfrV50rfCLYFNfxBx54IjZrd3mvr/l/jk7htQgx/ertS3FijCPxAzmP
# RHm2dgNXnq0vCEbc0oy89I50zshoaVF2EYsPXSRbGVQ9JsxAjYInG1kgfVn2k4CO
# +Co4/WugQGUfV3bMW44ETyyo24RQE0/G3Iu5+N1pTIjrnHswJvx6WLtZvBRykoFX
# t3bJ2IAKgG4JAgMBAAGjgegwgeUwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQI
# MAYBAf8CAQAwHQYDVR0OBBYEFJIhp0qVXWSwm7Qe5gA3R+adQStMMEcGA1UdIARA
# MD4wPAYEVR0gADA0MDIGCCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWdu
# LmNvbS9yZXBvc2l0b3J5LzA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vY3JsLmds
# b2JhbHNpZ24ubmV0L3Jvb3QtcjMuY3JsMB8GA1UdIwQYMBaAFI/wS3+oLkUkrk1Q
# +mOai97i3Ru8MA0GCSqGSIb3DQEBCwUAA4IBAQAEVoJKfNDOyb82ZtG+NZ6TbJfo
# Bs4xGFn5bEFfgC7AQiW4GMf81LE3xGigzyhqA3RLY5eFd2E71y/j9b0zopJ9ER+e
# imzvLLD0Yo02c9EWNvG8Xuy0gJh4/NJ2eejhIZTgH8Si4apn27Occ+VAIs85ztvm
# d5Wnu7LL9hmGnZ/I1JgFsnFvTnWu8T1kajteTkamKl0IkvGj8x10v2INI4xcKjiV
# 0sDVzc+I2h8otbqBaWQqtaai1XOv3EbbBK6R127FmLrUR8RWdIBHeFiMvu8r/exs
# v9GU979Q4HvgkP0gGHgYIl0ILowcoJfzHZl9o52R0wZETgRuehwg4zbwtlC5MYIC
# qDCCAqQCAQEwazBbMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBu
# di1zYTExMC8GA1UEAxMoR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBTSEEy
# NTYgLSBHMgIMDKfPXQcHJKyJ55o6MA0GCWCGSAFlAwQCAQUAoIIBDjAaBgkqhkiG
# 9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTE5MDgyMjEwNTI1
# MVowLwYJKoZIhvcNAQkEMSIEIGzzHeyaLdOl+P+hBRk8AWwj3C42K2AqOHEJ3bYm
# svpLMIGgBgsqhkiG9w0BCRACDDGBkDCBjTCBijCBhwQUmxIFeucqr/bWN3K0n2oj
# byZJzakwbzBfpF0wWzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hB
# MjU2IC0gRzICDAynz10HBySsieeaOjANBgkqhkiG9w0BAQEFAASCAQBZNMxs7o5I
# X669+SqTwAzY4c/EGJWAIJ1YG7UFN0L/vhwjQ+V2CP+gRgFw2ITJzjfz9pOJWVCE
# 6VR2hY2gqajhmTvHJmKEXAdtPZOg7IQ84iFazVr31u7BF7Ttz3mRGsdEETinUdoy
# jTonxmnHok5phSXtnZehSHkgeqFHCGb6iyYX1A4gbztfjhlrRC0FAStV2Gj/vpOM
# jaR63TB+8pLxBe9REmIYVfPhEJjjSIOwxmQCuCNTKtxDfpvmqK0GfAdcB1ONBzx8
# I34sA1j/tf57IrOjT1KiQy8URZ41qU4rLiqHAIZ86gbpGLXN01ejkotHZpiZV/2G
# FBiv6sHZLeyA
# SIG # End signature block
