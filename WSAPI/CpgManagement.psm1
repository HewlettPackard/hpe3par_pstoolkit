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
##	File Name:		CpgManagement.psm1
##	Description: 	CPG Management cmdlets 
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
## FUNCTION New-Cpg_WSAPI
############################################################################################################################################
Function New-Cpg_WSAPI 
{
  <#
  
  .SYNOPSIS
	The New-Cpg_WSAPI command creates a Common Provisioning Group (CPG).
  
  .DESCRIPTION
	The New-Cpg_WSAPI command creates a Common Provisioning Group (CPG).
        
  .EXAMPLE    
	New-Cpg_WSAPI -CPGName XYZ 
        
  .EXAMPLE	
	New-Cpg_WSAPI -CPGName "MyCPG" -Domain Chef_Test
        
  .EXAMPLE	
	New-Cpg_WSAPI -CPGName "MyCPG" -Domain Chef_Test -Template Test_Temp
        
  .EXAMPLE	
	New-Cpg_WSAPI -CPGName "MyCPG" -Domain Chef_Test -Template Test_Temp -GrowthIncrementMiB 100
        
  .EXAMPLE	
	New-Cpg_WSAPI -CPGName "MyCPG" -Domain Chef_Test -RAIDType R0

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
    NAME    : New-Cpg_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: New-Cpg_WSAPI
   
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
    Test-WSAPIConnection -WsapiConnection $WsapiConnection
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
			Write-DebugLog "Stop: Exiting  New-Cpg_WSAPI   since RAIDType $RAIDType in incorrect "
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
			Write-DebugLog "Stop: Exiting  New-Cpg_WSAPI since HA $HA in incorrect "
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
			Write-DebugLog "Stop: Exiting  New-Cpg_WSAPI since Chunklets $Chunklets in incorrect "
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
			Write-DebugLog "Stop: Exiting  New-Cpg_WSAPI   since DiskType $DiskType in incorrect "
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
    $Result = Invoke-WSAPI -uri '/cpgs' -type 'POST' -body $body -WsapiConnection $WsapiConnection
	$status = $Result.StatusCode
	if($status -eq 201)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: CPG:$CPGName created successfully" $Info
		
		#write-host " StatusCode = $status"
		# Results
		Get-Cpg_WSAPI -CPGName $CPGName
		Write-DebugLog "End: New-Cpg_WSAPI" $Debug
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
#ENG New-Cpg_WSAPI

############################################################################################################################################
## FUNCTION Update-Cpg_WSAPI
############################################################################################################################################
Function Update-Cpg_WSAPI 
{
  <#
  
  .SYNOPSIS
	The Update-Cpg_WSAPI command Update a Common Provisioning Group (CPG).
  
  .DESCRIPTION
	The Update-Cpg_WSAPI command Update a Common Provisioning Group (CPG).
	This operation requires access to all domains, as well as Super, Service, or Edit roles, or any role granted cpg_set permission.
    
  .EXAMPLE   
	Update-Cpg_WSAPI -CPGName ascpg -NewName as_cpg
    
  .EXAMPLE 	
	Update-Cpg_WSAPI -CPGName xxx -RAIDType R1
    
  .EXAMPLE 	
	Update-Cpg_WSAPI -CPGName xxx -DisableAutoGrow $true
    
  .EXAMPLE 	
	Update-Cpg_WSAPI -CPGName xxx -RmGrowthLimit $true
    
  .EXAMPLE 	
	Update-Cpg_WSAPI -CPGName xxx -RmWarningAlert $true
	    
  .EXAMPLE 
	Update-Cpg_WSAPI -CPGName xxx -SetSize 10
    
  .EXAMPLE 	
	Update-Cpg_WSAPI -CPGName xxx -HA PORT
    
  .EXAMPLE 	
	Update-Cpg_WSAPI -CPGName xxx -Chunklets FIRST
    
  .EXAMPLE 	
	Update-Cpg_WSAPI -CPGName xxx -NodeList 0
		
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
    NAME    : Update-Cpg_WSAPI    
    LASTEDIT: February 2020
    KEYWORDS: Update-Cpg_WSAPI
   
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
    Test-WSAPIConnection -WsapiConnection $WsapiConnection
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
			Write-DebugLog "Stop: Exiting  Update-Cpg_WSAPI   since RAIDType $RAIDType in incorrect "
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
			Write-DebugLog "Stop: Exiting  Update-Cpg_WSAPI since HA $HA in incorrect "
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
			Write-DebugLog "Stop: Exiting  Update-Cpg_WSAPI since Chunklets $Chunklets in incorrect "
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
			Write-DebugLog "Stop: Exiting  Update-Cpg_WSAPI   since DiskType $DiskType in incorrect "
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
    $Result = Invoke-WSAPI -uri $uri -type 'PUT' -body $body -WsapiConnection $WsapiConnection
	
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
			Get-Cpg_WSAPI -CPGName $NewName
		}
		else
		{
			Get-Cpg_WSAPI -CPGName $CPGName
		}
		Write-DebugLog "End: Update-Cpg_WSAPI" $Debug
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
#END Update-Cpg_WSAPI


############################################################################################################################################
## FUNCTION Remove-Cpg_WSAPI
############################################################################################################################################
Function Remove-Cpg_WSAPI
 {
  <#
	
  .SYNOPSIS
	Removes a Common Provision Group(CPG).
  
  .DESCRIPTION
	Removes a CommonProvisionGroup(CPG)
    This operation requires access to all domains, as well as Super, or Edit roles, or any role granted cpg_remove permission.    
	
  .EXAMPLE    
	Remove-Cpg_WSAPI -CPGName MyCPG
	Removes a Common Provision Group(CPG) "MyCPG".
	
  .PARAMETER CPGName 
    Specify name of the CPG.
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
	
  .Notes
    NAME    : Remove-Cpg_WSAPI     
    LASTEDIT: February 2020
    KEYWORDS: Remove-Cpg_WSAPI 
   
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
    Test-WSAPIConnection -WsapiConnection $WsapiConnection
  }

  Process 
  {    
	#Build uri
	Write-DebugLog "Running: Building uri to Remove-Cpg_WSAPI  ." $Debug
	$uri = '/cpgs/'+$CPGName

	#init the response var
	$Result = $null

	#Request
	Write-DebugLog "Request: Request to Remove-Cpg_WSAPI : $CPGName (Invoke-WSAPI)." $Debug
	$Result = Invoke-WSAPI -uri $uri -type 'DELETE' -WsapiConnection $WsapiConnection
	
	$status = $Result.StatusCode
	if($status -eq 200)
	{
		write-host ""
		write-host "Cmdlet executed successfully" -foreground green
		write-host ""
		Write-DebugLog "SUCCESS: CPG:$CPGName successfully remove" $Info
		Write-DebugLog "End: Remove-Cpg_WSAPI" $Debug
		return ""		
	}
	else
	{
		write-host ""
		write-host "FAILURE : While Removing CPG:$CPGName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While creating CPG:$CPGName " $Info
		Write-DebugLog "End: Remove-Cpg_WSAPI" $Debug
		
		return $Result.StatusDescription
	}    
	
  }
  End {}  
}
#END Remove-Cpg_WSAPI

############################################################################################################################################
## FUNCTION Get-Cpg_WSAPI
############################################################################################################################################
Function Get-Cpg_WSAPI 
{
  <#
   
  .SYNOPSIS	
	Get list or single common provisioning groups (CPGs) all CPGs in the storage system.
  
  .DESCRIPTION
	Get list or single common provisioning groups (CPGs) all CPGs in the storage system.
        
  .EXAMPLE
	Get-Cpg_WSAPI
	List all/specified common provisioning groups (CPGs) in the system.
	
  .EXAMPLE
	Get-Cpg_WSAPI -CPGName "MyCPG" 
	List Specified CPG name "MyCPG"
	
  .PARAMETER CPGName
	Specify name of the cpg to be listed
	
  .PARAMETER WsapiConnection 
    WSAPI Connection object created with Connection command
              
  .Notes
    NAME    : Get-Cpg_WSAPI   
    LASTEDIT: February 2020
    KEYWORDS: Get-Cpg_WSAPI
   
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
	Test-WSAPIConnection -WsapiConnection $WsapiConnection
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
		$Result = Invoke-WSAPI -uri $uri -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = $Result.content | ConvertFrom-Json
		}
	}
	else
	{
		#Request
		$Result = Invoke-WSAPI -uri '/cpgs' -type 'GET' -WsapiConnection $WsapiConnection
		if($Result.StatusCode -eq 200)
		{
			$dataPS = ($Result.content | ConvertFrom-Json).members
		}		
	}
		  
	if($Result.StatusCode -eq 200)
	{
		write-host ""
		write-host "Executed successfully" -foreground green
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
		write-host "FAILURE : While Executing Get-Cpg_WSAPI CPG:$CPGName " -foreground red
		write-host ""
		Write-DebugLog "FAILURE : While Executing Get-Cpg_WSAPI CPG:$CPGName " $Info
		
		return $Result.StatusDescription
	}
  }	
}
#END Get-Cpg_WSAPI

Export-ModuleMember New-Cpg_WSAPI , Update-Cpg_WSAPI , Remove-Cpg_WSAPI , Get-Cpg_WSAPI