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
##	File Name:		SystemReporter.psm1
##	Description: 	System Reporter cmdlets 
##		
##	Created:		December 2019
##	Last Modified:	December 2019
##	History:		v3.0- Created	
#####################################################################################

$Info = "INFO:"
$Debug = "DEBUG:"
$global:VSLibraries = Split-Path $MyInvocation.MyCommand.Path
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

############################################################################################################################################
## FUNCTION Test-CLIObject
############################################################################################################################################
Function Test-CLIObject 
{
Param( 	
    [string]$ObjectType, 
	[string]$ObjectName ,
	[string]$ObjectMsg = $ObjectType, 
	$SANConnection = $global:SANConnection
	)

	$IsObjectExisted = $True
	$ObjCmd = $ObjectType -replace ' ', '' 
	$Cmds = "show$ObjCmd $ObjectName"
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmds
	if ($Result -like "no $ObjectMsg listed")
	{
		$IsObjectExisted = $false
	}
	return $IsObjectExisted
	
} # End FUNCTION Test-CLIObject

##########################################################################
######################### FUNCTION Get-SRAlertCrit #######################
##########################################################################
Function Get-SRAlertCrit
{
<#
  .SYNOPSIS
    Shows the criteria that System Reporter evaluates to determine if a performance alert should be generated.
  
  .DESCRIPTION
    Shows the criteria that System Reporter evaluates to determine if a performance alert should be generated.
        
  .EXAMPLE
    Get-SRAlertCrit 
	shows the criteria that System Reporter evaluates to determine if a performance alert should be generated.
	
  .EXAMPLE
    Get-SRAlertCrit -Daily
	Example displays all the criteria evaluated on an hourly basis:
	
  .EXAMPLE
	Get-SRAlertCrit -Hires

  .PARAMETER Daily
	This criterion will be evaluated on a daily basis at midnight.
		
  .PARAMETER Hourly
	This criterion will be evaluated on an hourly basis.
		
  .PARAMETER Hires
	This criterion will be evaluated on a high resolution (5 minute) basis. This is the default.
		
  .PARAMETER Major
	This alert should require urgent action.
		
  .PARAMETER Minor
	This alert should require not immediate action.
		
  .PARAMETER Info
	This alert is informational only. This is the default.
	
  .PARAMETER Enabled
	Displays only criteria that are enabled.

  .PARAMETER Disabled
	Displays only criteria that are disabled.

  .PARAMETER Critical
	Displays only criteria that have critical severity.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRAlertCrit
    LASTEDIT: December 2019
    KEYWORDS: Get-SRAlertCrit
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(

		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Major ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Minor ,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Info ,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Enabled ,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Disabled ,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Critical,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	write-DebugLog "Start: In Get-SRAlertCrit - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRAlertCrit since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRAlertCrit since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	
	$cliresult1 = Test-PARCli -SANConnection $SANConnection	
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	
	$version1 = Get-Version -S  -SANConnection $SANConnection
	if( $version1 -lt "3.2.1")
	{
		return "Current OS version $version1 does not support these cmdlet"
	}
	
	$srinfocmd = "showsralertcrit "
	
	if($Hourly)
	{
		$srinfocmd += " -hourly "
	}
	if($Daily)
	{
		$srinfocmd += " -daily "
	}
	if($Hires)
	{
		$srinfocmd += " -hires "
	}
	if($Major)
	{
		$srinfocmd += " -major "
	}
	if($Minor)
	{
		$srinfocmd += " -minor "
	}
	if($Info)
	{
		$srinfocmd += " -info "
	}
	if($Enabled)
	{
		$srinfocmd += " -enabled "
	}
	if($Disabled)
	{
		$srinfocmd += " -disabled "
	}
	if($Critical)
	{
		$srinfocmd += " -critical "
	}
	
	write-debuglog "Get alert criteria command => $srinfocmd" "INFO:"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd	
	if($Result -match "Invalid")
	{
		return "FAILURE : $Result"
	}
	if($Result -match "Error")
	{
		return "FAILURE : $Result"
	}
	if($Result -match "No criteria listed")
	{
		return "No srcriteria listed"
	}
	$tempFile = [IO.Path]::GetTempFileName()
	$range1 = $Result.count-3
	foreach ($s in  $Result[0..$range1] )
	{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
	}
	Import-Csv $tempFile
	del $tempFile
}
## End Get-SRAlertCrit

####################################################################################################################
############################################## FUNCTION Get-SRAOMoves ##############################################
####################################################################################################################
Function Get-SRAOMoves
{
<#
  .SYNOPSIS
    The Get-SRAOMoves command shows the space that AO has moved between tiers.
	
  .DESCRIPTION
    The Get-SRAOMoves command shows the space that AO has moved between tiers.
	
  .EXAMPLE
   Get-SRAOMoves -btsecs 7200
   
   .EXAMPLE
   Get-SRAOMoves -etsecs 7200
   
   .EXAMPLE
   Get-SRAOMoves -oneline 
   
   .EXAMPLE
   Get-SRAOMoves -withvv 
   
   .EXAMPLE
   Get-SRAOMoves -VV_name XYZ
 
  .PARAMETER btsecs 
	Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins is 12 ho                                                          urs ago.
	If -btsecs 0 is specified then the report begins at the earliest sample.

  .PARAMETER etsecs 
	Select the end time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.

  .PARAMETER oneline
	Show data in simplified format with one line per AOCFG.

  .PARAMETER VV_name
	Limit the analysis to VVs with names that match one or more of
	the specified names or glob-style patterns. VV set names must be
	prefixed by "set:".  Note that snapshot VVs will not be considered
	since only base VVs have region space.

  .PARAMETER withvv
	Show the data for each VV.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRAOMoves
    LASTEDIT: December 2019
    KEYWORDS: Get-SRAOMoves
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$btsecs,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$etsecs,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$oneline,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$VV_name,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$withvv,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Get-SRAOMoves   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRAOMoves since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRAOMoves since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "sraomoves "
	
	if ($btsecs)
	{		
		$cmd+=" -btsecs $btsecs "	
	}	
	if ($etsecs)
	{		
		$cmd+=" -etsecs $etsecs "	
	}
	if ($oneline)
	{		
		$cmd+=" -oneline "	
	}
	if ($VV_name)
	{		
		$cmd+=" -vv $VV_name "	
	}
	if ($withvv)
	{		
		$cmd+=" -withvv "	
	}	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Get-SRAOMoves command creates and admits physical disk definitions to enable the use of those disks  " "INFO:" 
	return 	$Result	
} ## End Get-SRAOMoves

##########################################################################
######################### FUNCTION Get-SRCpgSpace ########################
##########################################################################
Function Get-SRCpgSpace
{
<#
  .SYNOPSIS
    Command displays historical space data reports for common provisioning groups (CPGs).
  
  .DESCRIPTION
    Command displays historical space data reports for common provisioning groups (CPGs).
	
  .EXAMPLE
    Get-SRCpgSpace 
	Command displays historical space data reports for common provisioning groups (CPGs).
	
  .EXAMPLE
    Get-SRCpgSpace -Option hourly -btsecs -24h fc*
	example displays aggregate hourly CPG space information for CPGs with names that match the pattern "fc*" beginning 24 hours ago:

  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
  
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.  

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
		
  .PARAMETER Hourly
	Select hourly samples for the report.
		
  .PARAMETER Daily   
	Select daily samples for the report.
		
  .PARAMETER Groupby
	For -attime reports, generate a separate row for each combination of <groupby> items.  Each <groupby> must be different and  one of the following:
	DOM_NAME  Domain name
	CPGID     Common Provisioning Group ID
	CPG_NAME  Common Provisioning Group name
	DISK_TYPE  The disktype of the PDs used by the CPG
	RAID_TYPE The RAID type of the CPG

  .PARAMETER disk_type 
	Limit the data to disks of the types specified. Allowed types are
	FC  - Fast Class
	NL  - Nearline
	SSD - Solid State Drive

  .PARAMETER raid_type
	Limit the data to RAID of the specified types. Allowed types are 0, 1, 5 and 6
	
  .PARAMETER CpgName
	CPGs matching either the specified CPG_name or glob-style pattern are included. This specifier can be repeated to display information for multiple CPGs. If not specified, all CPGs are included.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRCpgSpace
    LASTEDIT: December 2019
    KEYWORDS: Get-SRCpgSpace
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$DiskType,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$RaidType,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$CpgName,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-SRCpgSpace - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRCpgSpace since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRCpgSpace since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srcpgspace"
	$3parosver = Get-Version -S  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		$tempFile = [IO.Path]::GetTempFileName()

		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "DOM_NAME","CPGID","CPGID","CPGID","RAID_TYPE"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					del $tempFile
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"

		}	
		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		if($RaidType)
		{
			$raidarray = "0","1","5","6"
			if($raidarray -eq $RaidType)
			{
				$srinfocmd += " -raid_type $RaidType"
			}
			else
			{
				del $tempFile
				return "FAILURE: Invalid raid option, it should be in ( $raidarray )"
			}			
		}
		if($DiskType)
		{
			$diskarray = "FC","NL","SSD"
			if($diskarray -eq $DiskType.toUpper()){
				$srinfocmd += " -disk_type $DiskType"			
			}
			else
			{
				del $tempFile
				return "FAILURE: Invalid disktype option, it should be in ( $diskarray )"
			}
		}
		if($CpgName)
		{
			$srinfocmd += " $CpgName"			
		}		
		if($attime)
		{		
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "CPG_NAME"
			}
			#Add-Content -Path $tempFile -Value "$optionname,Used(MB)_Adm,Used(MB)_Snp,Used(MB)_Usr,Used(MB)_Total,Free(MB)_Adm,Free(MB)Snp,Free(MB)Usr,Free(MB)Total,Total(MB)_Adm,Total(MB)_Snp,Total(MB)_Usr,Total(MB)_Total,Growth(MB),CapacityEfficiency_Compaction,CapacityEfficiency_Dedup"
			Add-Content -Path $tempFile -Value "CPG_NAME,PrivateBase(MB),PrivateSnap(MB),Shared(MB),Free(MB),Total(MB),UsableFree(MB),Dedup_GC(KB/s),Compact,Dedup,Compress,DataReduce,OverProv"
			$rangestart = "3"			
		}	
		else
		{
			$rangestart = "2"
			#Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,Used(MB)_Adm,Used(MB)_Snp,Used(MB)_Usr,Used(MB)_Total,Free(MB)_Adm,Free(MB)Snp,Free(MB)Usr,Free(MB)Total,Total(MB)_Adm,Total(MB)_Snp,Total(MB)_Usr,Total(MB)_Total,Growth(MB),CapacityEfficiency_Compaction,CapacityEfficiency_Dedup"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,PrivateBase(MB),PrivateSnap(MB),Shared(MB),Free(MB),Total(MB),UsableFree(MB),Dedup_GC(KB/s),Compact,Dedup,Compress,DataReduce,OverProv"
		}
		
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			del $tempFile
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
			
		if($range1 -le "3")
		{
			del $tempFile
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
				#write-host " s= $s"
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				Add-Content -Path $tempFile -Value  $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRCpgSpace 

##########################################################################
######################### FUNCTION Get-SRHistLd ##########################
##########################################################################
Function Get-SRHistLd
{
<#
  .SYNOPSIS
    Displays historical histogram performance data reports for logical disks.
	
  .DESCRIPTION
    Displays historical histogram performance data reports for logical disks.
	
  .EXAMPLE
    Get-SRHistLd 
	Displays historical histogram performance data reports for logical disks.
	
  .EXAMPLE
    Get-SRHistLd -Hourly -btsecs -24h
	example displays aggregate hourly histogram performance statistics for all logical disks beginning 24 hours ago:

  .EXAMPLE
    Get-SRHistLd -Metric Both
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
	
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
	
  .PARAMETER etsecs
    Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	
  .PARAMETER Hourly
	Select hourly samples for the report.
	
  .PARAMETER Daily   
	Select daily samples for the report.
	
  .PARAMETER rw
       Specifies that the display includes separate read and write data. If notspecified, the total is displayed.
	   
  .PARAMETER Groupby
	 For -attime reports, generate a separate row for each combination of
	<groupby> items.  Each <groupby> must be different and
	one of the following:
	DOM_NAME  Domain name
	LDID      Logical disk ID
	LD_NAME   Logical disk name
	CPG_NAME  Common Provisioning Group name
	NODE      The node that owns the LD

  .PARAMETER cpgName
	Limit the data to LDs in CPGs with names that match one or more of the specified names or glob-style patterns.
		
  .PARAMETER node
	Limit the data to that corresponding to one of the specified nodes.

  .PARAMETER LDName
	LDs matching either the specified LD_name or glob-style pattern are included. This specifier can be repeated to display information for multiple LDs. If not specified, all LDs are included.

  .PARAMETER Metric both|time|size
	Selects which metric to display. Metrics can be one of the following:
	both - (Default)Display both I/O time and I/O size histograms
	time - Display only the I/O time histogram
	size - Display only the I/O size histogram

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRHistLd
    LASTEDIT: December 2019
    KEYWORDS: Get-SRHistLd   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$rw,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$groupby,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$cpgName,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$node,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$LDName,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Metric,
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)
	Write-DebugLog "Start: In Get-SRHistLd - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRHistLd since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRHistLd since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "srhistld "
	$3parosver = Get-Version -S -SANConnection  $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($rw)
		{
			$srinfocmd +=  " -rw "
		}
		if($groupby)
		{
			$commarr =  "DOM_NAME","LDID","LD_NAME","CPG_NAME","NODE"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		if($cpgName)
		{
			$srinfocmd +=  " -cpg $cpgName "
		}
		if($node)
		{
			$nodes = $node.split(",")
			$srinfocmd +=  " -node $nodes "			
		}
		if($LDName)
		{
				$srinfocmd += " $LDName "
		}
		if($Metric)
		{			
			$a = "both","time","size"
			$l=$Metric
			if($a -eq $l)
			{
				$srinfocmd += " -metric $Metric"			
			}
			else
			{ 
				Write-DebugLog "Stop: Exiting  Get-SRHistLd   since -Metric $Metric in incorrect "
				Return "FAILURE : Metric :- $Metric is an Incorrect [ both | time | size ]  can be used only . "
			}
		}
		#write-host " cmd = $srinfocmd"
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "LD_NAME"
			}
			Add-Content -Path $tempFile -Value "$optionname,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
			$rangestart = "3"
		}
		elseif($Metric -eq "time")
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec)"
		}
		elseif($Metric -eq "size")
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
		}
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		$range1  = $Result.count
		if($range1 -le "3")
		{
			del $tempFile
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] ){
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRHistLd

##########################################################################
########################### Start Get-SRHistPD ###########################
##########################################################################
Function Get-SRHistPD
{
<#
  .SYNOPSIS
    Command displays historical histogram performance data reports for physical disks. 
	
  .DESCRIPTION
    Command displays historical histogram performance data reports for physical disks. 
	
  .EXAMPLE
    Get-SRHistPD 
	Command displays historical histogram performance data reports for physical disks. 
	
  .EXAMPLE
    Get-SRHistPD -Hourly -btsecs -24h
	Example displays aggregate hourly histogram performance statistics for all physical disks beginning 24 hours ago:

  .EXAMPLE
    Get-SRHistPD -Groupby SPEED
	
  .EXAMPLE
    Get-SRHistPD -Metric both 
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
	
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
	
  .PARAMETER etsecs
    Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	
  .PARAMETER Hourly
	Select hourly samples for the report.
	
  .PARAMETER Daily   
	Select daily samples for the report.
	
  .PARAMETER rw
   Specifies that the display includes separate read and write data. If notspecified, the total is displayed.
	   
  .PARAMETER Groupby
	For -attime reports, generate a separate row for each combination of
	<groupby> items.  Each <groupby> must be different and
	one of the following:
	PDID      Physical disk ID
	PORT_N    The node number for the primary port for the the PD
	PORT_S    The PCI slot number for the primary port for the the PD
	PORT_P    The port number for the primary port for the the PD
	DISK_TYPE  The disktype of the PD
	SPEED     The speed of the PD

  .PARAMETER diskType
	Limit the data to disks of the types specified. Allowed types are
	FC  - Fast Class
	NL  - Nearline
	SSD - Solid State Drive
		
  .PARAMETER rpmSpeed
        Limit the data to disks of the specified RPM. Allowed speeds are 7, 10, 15, 100 and 150

  .PARAMETER Metric both|time|size
	Selects which metric to display. Metrics can be one of the following:
	both - (Default)Display both I/O time and I/O size histograms
	time - Display only the I/O time histogram
	size - Display only the I/O size histogram
		

  .PARAMETER PDID
	LDs matching either the specified LD_name or glob-style pattern are included. This specifier can be repeated to display information for multiple LDs. If not specified, all LDs are included.

  .PARAMETER SANConnection 
   Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection	
   
  .Notes
    NAME:  Get-SRHistPD
    LASTEDIT: December 2019
    KEYWORDS: Get-SRHistPD   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$rw,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$groupby,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$diskType,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$rpmSpeed,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$PDID,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Metric,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-SRHistPD - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRHistPD since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRHistPD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "srhistpd "
	$3parosver = Get-Version -S -SANConnection  $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($rw)
		{
			$srinfocmd +=  " -rw "
		}
		if($groupby)
		{
			$commarr =  "PDID","PORT_N","PORT_S","PORT_P","DISK_TYPE","SPEED"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		if($diskType)
		{
			$diskarr1 = "FC","NL","SSD"
			if($diskarr1 -eq $diskType.toUpper())
			{
				$srinfocmd +=  " -disk_type $diskType "
			}
			else
			{
				return "FAILURE: Invalid diskType it should be in ( $diskarr1 )"
			}
			
		}
		if($Metric)
		{			
			$a = "both","time","size"
			$l=$Metric
			if($a -eq $l)
			{
				$srinfocmd += " -metric $Metric"			
			}
			else
			{ 
				Write-DebugLog "Stop: Exiting  Get-SRHistPD   since -Metric $Metric in incorrect "
				Return "FAILURE : Metric :- $Metric is an Incorrect [ both | time | size ]  can be used only . "
			}
		}
		if($rpmSpeed)
		{
			$rpmarr1 = "7","10","15","100","150"
			if($rpmarr1 -eq $rpmSpeed)
			{
				$srinfocmd +=  " -rpm $rpmSpeed "
			}
			else
			{
				return "FAILURE: Invalid rpmSpeed it should be in ( $rpmarr1 )"
			}		
		}
		if($PDID)
		{
				$srinfocmd += " $PDID "
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "PDID"
			}
			Add-Content -Path $tempFile -Value "$optionname,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
			$rangestart = "3"
		}
		elseif($Metric -eq "time")
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec)"
		}
		elseif($Metric -eq "size")
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		$range1  = $Result.count
		if($range1 -le "3")
		{
			del $tempFile
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile	
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRHistPD

##########################################################################
############################# Start Get-SRHistPort #######################
##########################################################################
Function Get-SRHistPort
{
<#
  .SYNOPSIS
    Command displays historical histogram performance data reports for ports.
	
  .DESCRIPTION
    Command displays historical histogram performance data reports for ports. 
	
  .EXAMPLE
    Get-SRHistPort 
	Command displays historical histogram performance data reports for ports.
	
  .EXAMPLE
    Get-SRHistPort -Metric_Val size

  .EXAMPLE
    Get-SRHistPort -Groupby PORT_N
	
  .EXAMPLE
    Get-SRHistPort -Hurly -btsecs -24h -portType "host,disk" -port "0:*:* 1:*:*"
	example displays aggregate hourly histogram performance statistics for disk and host ports on nodes 0 and 1 beginning 24 hours ago:
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object
 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
	
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
		
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.

  .PARAMETER Hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
		
  .PARAMETER Hourly
		Select hourly samples for the report.
		
  .PARAMETER Daily   
		Select daily samples for the report.

  .PARAMETER Metric_Val both|time|size
	Selects which metric to display. Metrics can be one of the following:
		both - (Default)Display both I/O time and I/O size histograms
		time - Display only the I/O time histogram
		size - Display only the I/O size histogram

		
  .PARAMETER rw
   Specifies that the display includes separate read and write data. If notspecified, the total is displayed.
	   
  .PARAMETER Groupby
	 For -attime reports, generate a separate row for each combination of
	<groupby> items.  Each <groupby> must be different and
	one of the following:
	PORT_N      The node number for the port
	PORT_S      The PCI slot number for the port
	PORT_P      The port number for the port
	PORT_TYPE   The type of the port
	GBITPS      The speed of the port
	TRANS_TYPE  The transaction type - ctl or data


  .PARAMETER portType
	Limit the data to port of the types specified. Allowed types are
	disk  -  Disk port
	host  -  Host Fibre channel port
	iscsi -  Host ISCSI port
	free  -  Unused port
	fs    -  File Persona port
	peer  -  Data Migration FC port
	rcip  -  Remote copy IP port
	rcfc  -  Remote copy FC port

  .PARAMETER Port	
	Ports with <port_n>:<port_s>:<port_p> that match any of the specified[<npat>:<spat>:<ppat>...] patterns are included, where each of the patterns is a glob-style pattern. If not specified, all ports are included.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection	
	
  .Notes
    NAME:  Get-SRHistPort
    LASTEDIT: December 2019
    KEYWORDS: Get-SRHistPort
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$rw,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$groupby,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$portType,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Port,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Metric_Val,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-SRHistPort - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRHistPort since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRHistPort since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "srhistport "
	$3parosver = Get-Version -S -SANConnection  $SANConnection
	if($3parosver -ge "3.1.2")
	{

		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($rw)
		{
			$srinfocmd +=  " -rw "
		}
		if($groupby)
		{
			$commarr =  "PORT_N","PORT_S","PORT_P","PORT_TYPE","GBITPS"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		if($portType)
		{
			$commarr = "disk","host","iscsi","free","fs","peer","rcip","rcfc"
			$splitarr = $portType.split(",")
			foreach ($s in $splitarr){
				if($commarr -match $s.toLower())
				{				
				}
				else
				{
					return "FAILURE: Invalid port type option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -port_type $portType"	
		}		
		if($Port)
		{
				$srinfocmd += " $Port "
		}
		if($Metric_Val)
		{			
			$a = "both","time","size"
			$l=$Metric_Val
			if($a -eq $l)
			{
				$srinfocmd += " -metric $Metric_Val"			
			}
			else
			{ 
				Write-DebugLog "Stop: Exiting  Get-SRHistPort since -Metric $Metric_Val in incorrect "
				Return "FAILURE : Metric :- $Metric_Val is an Incorrect [ both | time | size ]  can be used only . "
			}
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "PORT_TYPE"
			}
			Add-Content -Path $tempFile -Value "$optionname,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
			$rangestart = "3"
		}
		elseif($Metric_Val -eq "time")
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec)"
		}
		elseif($Metric_Val -eq "size")
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		$range1  = $Result.count		
		if($range1 -le "3")
		{
			del $tempFile
			return "No data available "
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}

}
## End Get-SRHistPort

##########################################################################
########################### Start Get-SRHistVLun #########################
##########################################################################
Function Get-SRHistVLun
{
<#
  .SYNOPSIS
    Command displays historical histogram performance data reports for VLUNs. 
	
  .DESCRIPTION
    Command displays historical histogram performance data reports for  VLUNs. 
	
  .EXAMPLE
    Get-SRHistVLun 
	Command displays historical histogram performance data reports for  VLUNs. 
	
  .EXAMPLE
    Get-SRHistVLun  -Hourly -btsecs -24h
	example displays aggregate hourly histogram performance statistics for all VLUNs beginning 24 hours ago:
	
  .EXAMPLE
    Get-SRHistVLun -btsecs -2h -host "set:hostset" -vv "set:vvset*"
	VV or host sets can be specified with patterns:
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	
	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
	
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
	
  .PARAMETER etsecs
    Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
		
  .PARAMETER Hourly
	Select hourly samples for the report.
	
  .PARAMETER Daily   
	Select daily samples for the report.
	
  .PARAMETER rw
   Specifies that the display includes separate read and write data. If notspecified, the total is displayed.
	   
  .PARAMETER Groupby
	For -attime reports, generate a separate row for each combination of  <groupby> items.  Each <groupby> must be different and one of the following:
	DOM_NAME  Domain name
	VV_NAME   Virtual Volume name
	HOST_NAME Host name
	LUN       The LUN number for the VLUN
	HOST_WWN  The host WWN for the VLUN
	PORT_N    The node number for the VLUN  port
	PORT_S    The PCI slot number for the VLUN port
	PORT_P    The port number for the VLUN port
	VVSET_NAME    Virtual volume set name
	HOSTSET_NAME  Host set name

  .PARAMETER host
	 -host <host_name|host_set|pattern>[,<host_name|host_set|pattern>...]
	Limit the data to hosts with names that match one or more of the
	specified names or glob-style patterns. Host set name must start with
	"set:" and can also include patterns.
		
  .PARAMETER vv		
	-vv <VV_name|VV_set|pattern>[,<VV_name|VV_set|pattern>...]
	Limit the data to VVs with names that match one or more of the specified names or glob-style patterns. 
	VV set name must be prefixed by "set:" and can also include patterns.
		
  .PARAMETER lun
    -lun <LUN|pattern>[,<LUN|pattern>...]
	Limit the data to LUNs that match one or more of the specified LUNs or glob-style patterns.

  .PARAMETER Port
    -port <npat>:<spat>:<ppat>[,<npat>:<spat>:<ppat>...]
	Ports with <port_n>:<port_s>:<port_p> that match any of the specified <npat>:<spat>:<ppat> patterns are included, where each of the patterns is a glob-style pattern. If not specified, all ports are included.

  .PARAMETER Metric_Val both|time|size
	Selects which metric to display. Metrics can be one of the following:
	both - (Default)Display both I/O time and I/O size histograms
	time - Display only the I/O time histogram
	size - Display only the I/O size histogram
		
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection	
	
  .Notes
    NAME:  Get-SRHistVLun
    LASTEDIT: December 2019
    KEYWORDS: Get-SRHistVLun
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$rw,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$groupby,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$host,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$vv,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$lun,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Port,
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Metric_Val,
		
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-SRHistVLun - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRHistVLun since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRHistVLun since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "srhistvlun "
	$3parosver = Get-Version -S -SANConnection  $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($rw)
		{
			$srinfocmd +=  " -rw "
		}
		if($groupby)
		{
			$commarr =  "DOM_NAME","VV_NAME","HOST_NAME","LUN","HOST_WWN","PORT_N","PORT_S","PORT_P","VVSET_NAME","HOSTSET_NAME"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		if($host)
		{
			$srinfocmd +=  " -host $host "	
		}
		if($vv)
		{
			$srinfocmd +=  " -vv $vv "	
		}
		if($lun)
		{
			$srinfocmd +=  " -l $lun "	
		}		
		if($Port)
		{
				$srinfocmd += " -port $Port "
		}
		if($Metric_Val)
		{			
			$a = "both","time","size"
			$l=$Metric_Val
			if($a -eq $l)
			{
				$srinfocmd += " -metric $Metric_Val"			
			}
			else
			{ 
				Write-DebugLog "Stop: Exiting  Get-SRHistVLun   since -Metric $Metric_Val in incorrect "
				Return "FAILURE : Metric :- $Metric_Val is an Incorrect [ both | time | size ]  can be used only . "
			}
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "HOST_NAME"
			}
			Add-Content -Path $tempFile -Value "$optionname,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
			$rangestart = "3"
		}
		elseif($Metric_Val -eq "time")
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec)"
		}
		elseif($Metric_Val -eq "size")
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		$range1  = $Result.count
		if($range1 -le "3")
		{
			del $tempFile
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRHistVLun

##########################################################################
######################### Get-SRLDSpace ############################
##########################################################################
Function Get-SRLDSpace
{
<#
  .SYNOPSIS
    Command displays historical space data reports for logical disks (LDs).
  
  .DESCRIPTION
    Command displays historical space data reports for logical disks (LDs).

  .EXAMPLE
    Get-SRLDSpace
	
  .EXAMPLE
    Get-SRLDSpace -groupby OWNER 
	Command displays historical space data reports for logical disks (LDs).

  .EXAMPLE
    Get-SRLDSpace -DiskType FC
	
  .EXAMPLE
    Get-SRLDSpace -raidType 5 -Hourly -btsecs 24h -LDName fc*
	Example displays aggregate hourly LD space information for all RAID 5 LDs with names that match either "fc*" patterns beginning 24 hours ago:
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	
	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
	
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
		
  .PARAMETER etsecs
    Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	
  .PARAMETER Hourly
	Select hourly samples for the report.
	
  .PARAMETER Daily   
	Select daily samples for the report.
		
  .PARAMETER Groupby
	For -attime reports, generate a separate row for each combination of
	<groupby> items.  Each <groupby> must be different and
	one of the following:
	DOM_NAME  Domain name
	CPG_NAME  Common Provisioning Group name
	LDID      Logical disk ID
	LD_NAME   Logical disk name
	DISK_TYPE  The disktype of the PDs used by the LD
	RAID_TYPE The RAID type of the LD
	SET_SIZE  The RAID set size of the LD
	STEP_SIZE The RAID step size of the LD
	ROW_SIZE  The RAID row size of the LD
	OWNER     The owner node for the LD

  .PARAMETER cpgName
	Limit the data to LDs in CPGs with names that match one or more of the specified names or glob-style pattern
	 
  .PARAMETER DiskType 
	Limit the data to disks of the types specified. Allowed types are
		FC  - Fast Class
		NL  - Nearline
		SSD - Solid State Drive

  .PARAMETER RaidType
	Limit the data to RAID of the specified types. Allowed types are 0, 1, 5 and 6
		
  .PARAMETER Ownernode
	Limit data to LDs owned by the specified nodes.
		
  .PARAMETER LDname
	CPGs matching either the specified CPG_name or glob-style pattern are included. This specifier can be repeated to display information for multiple CPGs. If not specified, all CPGs are included.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRLDSpace
    LASTEDIT: December 2019
    KEYWORDS: Get-SRLDSpace
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$cpgName,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$DiskType,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$RaidType,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$ownernode,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$LDname,
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Get-SRLDSpace - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRLDSpace since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRLDSpace since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srldspace"
	$3parosver = Get-Version -S  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "DOM_NAME","CPG_NAME","LDID","LD_NAME","DISK_TYPE","RAID_TYPE","SET_SIZE","STEP_SIZE","ROW_SIZE","OWNER"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}		
		if($RaidType)
		{
			$raidarray = "0","1","5","6"
			if($raidarray -eq $RaidType)
			{
				$srinfocmd += " -raid_type $RaidType"			
			}
			else
			{
				return "FAILURE: Invalid raid option, it should be in ( $raidarray )"
			}			
		}
		if($DiskType)
		{
			$diskarray = "FC","NL","SSD"
			if($diskarray -eq $DiskType.toUpper())
			{
				$srinfocmd += " -disk_type $DiskType"			
			}
			else
			{
				return "FAILURE: Invalid disktype option, it should be in ( $diskarray )"
			}
		}
		if($cpgName)
		{
				$srinfocmd += " -cpg $cpgName"
		}
		if($ownernode)
		{
			$srinfocmd +=  " -owner $ownernode"
		}
		if($LDname)
		{
			$srinfocmd += " $LDName"			
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "LD_NAME"
			}
			Add-Content -Path $tempFile -Value "$optionname,Raw(MB),Used(MB),Free(MB),Total(MB)"
			$rangestart = "3"
		}
		else
		{
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,Raw(MB),Used(MB),Free(MB),Total(MB)"
			$rangestart = "2"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			del $tempFile
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		#write-host "count = $range1"		
		if($range1 -le "3")
		{
			del $tempFile
			return "No data available"
		}		
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRLDSpace

##########################################################################
############################ Get-SRPDSpace ###############################
##########################################################################
Function Get-SRPDSpace
{
<#
  .SYNOPSIS
    Command displays historical space data reports for physical disks (PDs).
  
  .DESCRIPTION
    Command displays historical space data reports for physical disks (PDs).
	
  .EXAMPLE
    Get-SRPDSpace 
	Command displays historical space data reports for physical disks (PDs).
	
  .EXAMPLE
    Get-SRPDSpace  -Hourly -btsecs -24h
	Example displays aggregate hourly PD space information for all PDs beginning 24 hours ago:
	
  .EXAMPLE
    Get-SRPDSpace -capacity -attime -diskType SSD
	Displays current system capacity values of SSD PDs:
	
 .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	
	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
	
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
		
  .PARAMETER etsecs
    Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.
  
  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
		
  .PARAMETER Hourly
	Select hourly samples for the report.
		
  .PARAMETER Daily   
	Select daily samples for the report.
	
  .PARAMETER Groupby
	For -attime reports, generate a separate row for each
	combination of <groupby> items.  Each <groupby> must be different and
	one of the following:
	PDID      Physical disk ID
	CAGEID    Cage ID
	CAGESIDE  Cage Side
	MAG       Disk Magazine number within the cage
	DISK      Disk position within the magazine
	DISK_TYPE The disktype of the PD
	SPEED     The disk speed

  .PARAMETER DiskType 
	Limit the data to disks of the types specified. Allowed types are
		FC  - Fast Class
		NL  - Nearline
		SSD - Solid State Drive
			
  .PARAMETER capacity
	Display disk contributions to the system capacity categories: Allocated, Free, Failed, and Total

  .PARAMETER rpmspeed
   Limit the data to disks of the specified RPM. Allowed speeds are  7, 10, 15, 100 and 150
	
  .PARAMETER PDID
	PDs with IDs that match either the specified PDID or glob-style  pattern are included. This specifier can be repeated to include multiple PDIDs or patterns. 
	If not specified, all PDs are included.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRPDSpace
    LASTEDIT: December 2019
    KEYWORDS: Get-SRPDSpace
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$DiskType,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$capacity,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$rpmspeed,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$PDID,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-SRPDSpace - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRPDSpace since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRPDSpace since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srpdspace"
	$3parosver = Get-Version -S  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{		
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "PDID","CAGEID","CAGESIDE","MAG","DISK","DISK_TYPE","SPEED"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		if($capacity)
		{
			$srinfocmd +=  " -capacity "
		}
		if($rpmspeed)
		{
			$rpmarray = "7","10","15","100","150"
			if($rpmarray -eq $rpmspeed)
			{
				$srinfocmd += " -rpm $rpmspeed"
			}
			else
			{
				return "FAILURE: Invalid rpmspeed it should be in ( $rpmarray )"
			}			
		}
		if($DiskType)
		{
			$diskarray = "FC","NL","SSD"
			if($diskarray -eq $DiskType.toUpper())
			{
				$srinfocmd += " -disk_type $DiskType"			
			}
			else
			{
				return "FAILURE: Invalid disktype option, it should be in ( $diskarray )"
			}
		}
		if($PDID)
		{
				$srinfocmd += " $PDID "
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			#$rangenodata = "3"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "PDID"
			}
			Add-Content -Path $tempFile -Value "$optionname,Normal(Chunklets)_Used_OK,Normal(Chunklets)_Used_Fail,Normal(Chunklets)_Avail_Clean,Normal(Chunklets)_Avail_Dirty,Normal(Chunklets)_Avail_Fail,Spare(Chunklets)_Used_OK,Spare(Chunklets)_Used_Fail,Spare(Chunklets)_Avail_Clean,Spare(Chunklets)_Avail_Dirty,Spare(Chunklets)_Avail_Fail,LifeLeft%,T(C)"			
			$rangestart = "3"
		}
		else
		{			
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,Normal(Chunklets)_Used_OK,Normal(Chunklets)_Used_Fail,Normal(Chunklets)_Avail_Clean,Normal(Chunklets)_Avail_Dirty,Normal(Chunklets)_Avail_Fail,Spare(Chunklets)_Used_OK,Spare(Chunklets)_Used_Fail,Spare(Chunklets)_Avail_Clean,Spare(Chunklets)_Avail_Dirty,Spare(Chunklets)_Avail_Fail,LifeLeft%,T(C)"
		}
		
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			del $tempFile
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		
		if($range1 -le "3")
		{
			del $tempFile
			return "No data available"
		}		
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRPDSpace

##########################################################################
#################### FUNCTION Get-SRrgiodensity ######################
##########################################################################
Function Get-SRrgiodensity()
{
<#
  .SYNOPSIS
   Get-3parSRrgiodensit - System reporter region IO density reports.

  .DESCRIPTION
   The Get-3parSRrgiodensit command shows the distribution of IOP/s intensity
   for Logical Disk (LD) regions for a common provisioning group (CPG) or
   Adaptive Optimization (AO) configuration. For a single CPG, this can be
   used to see whether AO can be effectively used.  For an AO configuration
   the command shows how AO has moved regions between tiers.

  .EXAMPLE

  .PARAMETER Btsecs
	Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins is 12 hours ago.
	If -btsecs 0 is specified then the report begins at the earliest sample.
   
   
  .PARAMETER Etsecs
	Select the end time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.

  .PARAMETER Cmult
   Select the step between histogram columns of the report.  By default
   each column's IO density is 4 times the previous column, but a step
   of 2 or 8 can also be specified.

  .PARAMETER Cpg
   Treat the specifiers as CPG names or glob-style patterns.

  .PARAMETER Vv
   Limit the analysis to VVs with names that match one or more of
   the specified names or glob-style patterns. VV set names must be
   prefixed by "set:".  Note that snapshot VVs will not be considered
   since only base VVs have region space.

  .PARAMETER Cumul
   Show data as cumulative including all the columns to the right.

  .PARAMETER Pct
   Show data as a percentage per row.

  .PARAMETER Totpct
   Show data as a totaled percentage across an AOCFG.

  .PARAMETER Withvv
   Show the data for each VV.

  .PARAMETER Rw
   Specifies that the display includes separate read and write data. If not
   specified, the total is displayed.

  .Notes
    NAME: Get-SRrgiodensity
    LASTEDIT December 2019
    KEYWORDS: Get-SRrgiodensity
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 [Parameter(Position=0, Mandatory=$false)]
 [System.String]
 $Btsecs,

 [Parameter(Position=1, Mandatory=$false)]
 [System.String]
 $Etsecs,

 [Parameter(Position=2, Mandatory=$false)]
 [System.String]
 $Cmult,

 [Parameter(Position=3, Mandatory=$false)]
 [System.String]
 $Cpg,

 [Parameter(Position=4, Mandatory=$false)]
 [System.String]
 $Vv,

 [Parameter(Position=5, Mandatory=$false)]
 [switch]
 $Cumul,

 [Parameter(Position=6, Mandatory=$false)]
 [switch]
 $Pct,

 [Parameter(Position=7, Mandatory=$false)]
 [switch]
 $Totpct,

 [Parameter(Position=8, Mandatory=$false)]
 [switch]
 $Withvv,

 [Parameter(Position=9, Mandatory=$false)]
 [switch]
 $Rw,

 [Parameter(Position=10, Mandatory=$false)]
 [System.String]
 $Aocfg_name,
 
 [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRrgiodensity - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRrgiodensity since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRrgiodensity since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srrgiodensity "

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Cmult)
 {
	$Cmd += " -cmult $Cmult "
 }

 if($Cpg)
 {
	$Cmd += " -cpg $Cpg"
 }

 if($Vv)
 {
	$Cmd += " -vv $Vv "
 }

 if($Cumul)
 {
	$Cmd += " -cumul "
 }

 if($Pct)
 {
	$Cmd += " -pct "
 }

 if($Totpct)
 {
	$Cmd += " -totpct "
 }

 if($Withvv)
 {
	$Cmd += " -withvv "
 }

 if($Rw)
 {
	$Cmd += " -rw "
 }
 
 if($Aocfg_name)
 {
	$Cmd += " $Aocfg_name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRrgiodensity Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-SRrgiodensity

#########################################################################
######################## Function Get-SRStatCache #######################
#########################################################################
Function Get-SRStatCache
{
<#
  .SYNOPSIS
    Command displays historical performance data reports for flash cache and data cache.
  
  .DESCRIPTION
    Command displays historical performance data reports for flash cache and data cache.
	
  .EXAMPLE
    Get-SRStatCache 
	Command displays historical performance data reports for flash cache and data cache.
	
  .EXAMPLE
    Get-SRStatCache -Hourly -btsecs -24h
 	Example displays aggregate hourly performance statistics for flash cache and data cache beginning 24 hours ago:
	
  .EXAMPLE
    Get-SRStatCache -Daily -attime -groupby node     
    Example displays daily flash cache and data cache performance aggregated by nodes
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.

  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
		
  .PARAMETER etsecs
    Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
		
  .PARAMETER Hourly
	Select hourly samples for the report.
		
  .PARAMETER Daily   
	Select daily samples for the report.
	
  .PARAMETER InternalFlashcache
	Lists the IOPS and bandwidth each for both read back and destaged write
	flash cache activity. May be combined with -fmp_queue and -cmp_queue.

  .PARAMETER FmpQueue
	List the FMP queue statistics. May be combined with -cmp_queue and
	-internal_flashcache.

  .PARAMETER CmpQueue
	List the CMP queue statistics. May be combined with -fmp_queue and
	-internal_flashcache.

  .PARAMETER Full
	List all the metrics for each row in a single line.  The output for
	this option is very wide.
		
  .PARAMETER groupby
	For -attime reports, generate a separate row for each combination of
	<groupby> items.  Each <groupby> must be different and
	one of the following:
	NODE      The controller node
		
  .PARAMETER Node
	Only the specified node numbers are included, where each node is a number from 0 through 7. If want to display information for multiple nodes specift <nodenumber>,<nodenumber2>,etc. If not specified, all nodes are included.
	Get-SRStatCache  -Node 0,1,2
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRStatCache
    LASTEDIT: December 2019
    KEYWORDS: Get-SRStatCache
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,	
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $InternalFlashCache ,	
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $FmpQueue ,	
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $CmpQueue ,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Full ,	
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$Node,
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-SRStatCache - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRStatCache since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRStatCache since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srstatcache "
	$3parosver = Get-Version -S  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "NODE"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}
		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		
		if($InternalFlashCache)
		{
			$srinfocmd += " -internal_flashcache"			
		}
		
		if($FmpQueue)
		{
			$srinfocmd += " -fmp_queue"			
		}
		
		if($CmpQueue)
		{
			$srinfocmd += " -cmp_queue"			
		}
		
		if($Full)
		{
			$srinfocmd += " -full"			
		}
		
		if($Node)
		{
			$nodes = $Node.split(",")
			$srinfocmd += " $nodes"
		}
		
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "NODE"
			}
			Add-Content -Path $tempFile -Value "$optionname,CMP_r/s,CMP_w/s,CMP_rhit%,CMP_whit%,FMP_rhit%,FMP_whit%,FMP_Used%,Read_Back_IO/s,Read_Back_MB/s,Dstg_Wrt_IO/s,Dstg_Wrt_MB/s"
			$rangestart = "3"			
		}
		elseif($groupby)
		{
			$optionname = $groupby.toUpper()
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,$optionname,CMP_r/s,CMP_w/s,CMP_rhit%,CMP_whit%,FMP_rhit%,FMP_whit%,FMP_Used%,Read_Back_IO/s,Read_Back_MB/s,Dstg_Wrt_IO/s,Dstg_Wrt_MB/s"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,CMP_r/s,CMP_w/s,CMP_rhit%,CMP_whit%,FMP_rhit%,FMP_whit%,FMP_Used%,Read_Back_IO/s,Read_Back_MB/s,Dstg_Wrt_IO/s,Dstg_Wrt_MB/s"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			del $tempFile
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		if($range1 -le "3")
		{
			del $tempFile
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile	
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRStatCache

#############################################################
################### Start Get-SRStatCMP #####################
#############################################################
Function Get-SRStatCMP
{
<#
  .SYNOPSIS
    Command displays historical performance data reports for cache memory
  
  .DESCRIPTION
    Command displays historical performance data reports for cache memory
	
  .EXAMPLE
    Get-SRStatCMP 
	Command displays historical performance data reports for cache memory
	
  .EXAMPLE
    Get-SRStatCMP -Hourly -btsecs -24h
 	Example displays aggregate hourly performance statisticsfor all node caches beginning 24 hours ago:
	
  .EXAMPLE
    Get-SRStatCMP -Daily -attime -groupby node     
    Example displays daily node cache performance aggregated by nodes
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.

  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
		
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
		
  .PARAMETER Hourly
	Select hourly samples for the report.
		
  .PARAMETER Daily   
	Select daily samples for the report.
	
  .PARAMETER Full
	List all the metrics for each row in a single line.  The output for
	this option is very wide.

  .PARAMETER Page
	List the page state information.

  .PARAMETER Groupby
	 For -attime reports, generate a separate row for each combination of
	<groupby> items.  Each <groupby> must be different and
	one of the following:
	NODE      The controller node
		
  .PARAMETER Node
	Only the specified node numbers are included, where each node is a number from 0 through 7. If want to display information for multiple nodes specift <nodenumber>,<nodenumber2>,etc. If not specified, all nodes are included.
	Get-SRStatCMP  -Node 0,1,2
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRStatCMP
    LASTEDIT: December 2019
    KEYWORDS: Get-SRStatCMP
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Full ,	
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Page ,	
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$Node,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-SRStatCMP - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRStatCMP since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRStatCMP since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srstatcmp "
	$3parosver = Get-Version -S  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "NODE"
			if($commarr -eq $groupby.toUpper())
			{
				$srinfocmd += " -groupby $groupby"
			}
			else
			{
				return "FAILURE: Invalid groupby option it should be in ( $commarr )"
			}
		}		
		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		
		if($Full)
		{
			$srinfocmd += " -full"			
		}
		
		if($Page)
		{
			$srinfocmd += " -page"			
		}		
		
		if($Node)
		{
			$nodes = $Node.split(",")
			$srinfocmd += " $nodes"			
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "NODE"
			}
			Add-Content -Path $tempFile -Value "NODE,rhit(count/sec),whit(count/sec),r(count/sec),w(count/sec),r+w(count/sec),lockblk(count/sec),r(hit%),w(hit%),NL(dack/sec),FC(dack/sec),SSD(dack/sec)"
			$rangestart = "3"			
		}
		elseif($groupby)
		{
			$optionname = $groupby.toUpper()
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,$optionname,rhit(count/sec),whit(count/sec),r(count/sec),w(count/sec),r+w(count/sec),lockblk(count/sec),r(hit%),w(hit%),NL(dack/sec),FC(dack/sec),SSD(dack/sec)"						
		}
		elseif($Page)
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,Free,Clean,Write1,Writen,Wrtsched,Writing,Dcowpend,NL(Dirty),FC(Dirty),SSD(Dirty),NL(MaxDirty),FC(MaxDirty),SSD(Max Dirty)"
		}
		elseif($Full)
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,rhit(count/sec),whit(count/sec),r(count/sec),w(count/sec),r+w(count/sec),lockblk(count/sec),r(hit%),w(hit%),NL(dack/sec),FC(dack/sec),SSD(dack/sec),free(PageStates),clean(PageStates),write1(PageStates),writen(PageStates),wrtsched(PageStates),writing(PageStates),dcowpend(PageStates),NL(DirtyPages),FC(DirtyPages),SSD(DirtyPages),NL(MaxDirtyPages),SSD(MaxDirtyPages)"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,rhit(count/sec),whit(count/sec),r(count/sec),w(count/sec),r+w(count/sec),lockblk(count/sec),r(hit%),w(hit%),NL(dack/sec),FC(dack/sec),SSD(dack/sec)"			
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			del $tempFile
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		if($range1 -le "3")
		{
			del $tempFile
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRStatCMP

#######################################################################
###################### Function Get-SRStatCPU #########################
#######################################################################
Function Get-SRStatCPU
{
<#
  .SYNOPSIS
    Command displays historical performance data reports for CPUs.
  
  .DESCRIPTION
    Command displays historical performance data reports for CPUs.
	
  .EXAMPLE
    Get-SRStatCPU 
	Command displays historical performance data reports for CPUs.

  .EXAMPLE
    Get-SRStatCPU -Groupby CPU
	
  .EXAMPLE
    Get-SRStatCPU -btsecs 24h
	
  .EXAMPLE
    Get-SRStatCPU -Hourly -btsecs 24h
 	Example displays aggregate hourly performance statistics for all CPUs beginning 24 hours ago:
	
  .EXAMPLE
    Get-SRStatCPU -option daily -attime -groupby node     
    Example displays daily node cpu performance aggregated by nodes
	 
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.	
 
 .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
		
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
		
  .PARAMETER Hourly
	Select hourly samples for the report.
	
  .PARAMETER Daily   
	Select daily samples for the report.
		
  .PARAMETER Groupby
	For -attime reports, generate a separate row for each combination of  <groupby> items.  Each <groupby> must be different and one of the following:
	NODE      The controller node
	CPU       The CPU within the controller node

  .PARAMETER Node
	Only the specified node numbers are included, where each node is a number from 0 through 7. If want to display information for multiple nodes specift <nodenumber>,<nodenumber2>,etc. If not specified, all nodes are included.
	Get-SRStatCPU  -Node 0,1,2
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRStatCPU
    LASTEDIT: December 2019
    KEYWORDS: Get-SRStatCPU
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$Node,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-SRStatCPU - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRStatCPU since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRStatCPU since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srstatcpu "
	$3parosver = Get-Version -S  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "CPU","NODE"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		if($Node)
		{
			$nodes = $Node.split(",")
			$srinfocmd += " $nodes"
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "NODE"
			}
			$rangestart = "1"			
		}
		elseif($groupby)
		{
			$optionname = $groupby.toUpper()
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,$optionname,User%,Sys%,Idle%,Intr/s,CtxtSw/s"
		}
		else
		{
			$rangestart = "1"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,User%,Sys%,Idle%,Intr/s,CtxtSw/s"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			del $tempFile
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		if($range1 -le "3")
		{
			del $tempFile
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRStatCPU

##########################################################################
#########################FUNCTION Get-SRStatfsav#########################
##########################################################################
Function Get-SRStatfsav()
{
<#
  .SYNOPSIS
   Get-SRStatfsav - System reporter performance reports for File Persona anti-virus.

  .DESCRIPTION
   The Get-SRStatfsav command displays historical performance data reports for
   File Persona anti-virus activity.

  .EXAMPLE

  .PARAMETER Attime
   Performance is shown at a particular time interval, specified by the
   etsecs option, with one row per object group described by the
   groupby option. Without this option performance is shown versus time,
   with a row per time interval.

  .PARAMETER Btsecs
	Select the begin time in seconds for the report.
	The value can be specified as either
		- The absolute epoch time (for example 1351263600).
		- The absolute time as a text string in one of the following formats:
			- Full time string including time zone: "2012-10-26 11:00:00 PDT"
			- Full time string excluding time zone: "2012-10-26 11:00:00"
			- Date string: "2012-10-26" or 2012-10-26
			- Time string: "11:00:00" or 11:00:00
		- A negative number indicating the number of seconds before the
		  current time. Instead of a number representing seconds, <secs> can
		  be specified with a suffix of m, h or d to represent time in minutes
		  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.


  .PARAMETER Etsecs
   Select the end time in seconds for the report.  If -attime is specified, select the time for the report.
	The value can be specified as either
		- The absolute epoch time (for example 1351263600).
		- The absolute time as a text string in one of the following formats:
			- Full time string including time zone: "2012-10-26 11:00:00 PDT"
			- Full time string excluding time zone: "2012-10-26 11:00:00"
			- Date string: "2012-10-26" or 2012-10-26
			- Time string: "11:00:00" or 11:00:00
		- A negative number indicating the number of seconds before the
		  current time. Instead of a number representing seconds, <secs> can
		  be specified with a suffix of m, h or d to represent time in minutes
		  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.

  .PARAMETER Hires
   Select high resolution samples (5 minute intervals) for the report.
   This is the default.

  .PARAMETER Hourly
   Select hourly samples for the report.

  .PARAMETER Daily
   Select daily samples for the report.

  .PARAMETER Summary
   Summarize performance across requested objects and time range.
   One of these 4 summary keywords must be included:
	   min   Display the minimum for each metric
	   avg   Display the average for each metric
	   max   Display the maximum for each metric
	   <N>%  Display percentile for each metric. <N> may be any number
		from 0 to 100. Multiple percentiles may be specified.
		
   Other keywords which modify the summary display or computation:
   detail
	   Display individual performance records in addition to one
	   or more summaries. By default, -summary output excludes
	   individual records and only displays the summary.
   per_time
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   time. By default, one summary is computed across all records.
   per_group
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   object grouping. By default, one summary is computed across all
	   records.
   only_compareby
	   When requesting data limited to certain object groupings with
	   the -compareby option, use this keyword to compute summaries
	   using only that reduced set of object groupings. By default,
	   summaries are computed from all records and ignore the
	   limitation of the -compareby option, though the "detail"
	   output does conform to the -compareby object limitation.

  .PARAMETER Groupby
   For -attime reports, generate a separate row for each combination of
   <groupby> items.  Each <groupby> must be different and
   one of the following:
   NODE      The controller node

  .PARAMETER Compareby
   The compareby option limits output records to only certain objects,
   compared by a specified field.  Either the top or bottom X objects
   can be displayed, up to 32 objects for vstime reports or 128 objects
   for attime reports.  The field used for comparison can be any of the
   groupby fields or one of the following:
   scanengine, maxscanengine, totalscanned, totalinfected,
   totalquarantined

  .PARAMETER Node
   Limit the data to that corresponding to one of the specified nodes.

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
   inc
   Sort in increasing order (default).
   dec
   Sort in decreasing order.
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.

  .Notes
    NAME: Get-SRStatfsav
    LASTEDIT : December 2019
    KEYWORDS: Get-SRStatfsav
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Attime,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Btsecs,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Etsecs,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Hires,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Hourly,

	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$Daily,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$Summary,

	[Parameter(Position=7, Mandatory=$false)]
	[System.String]
	$Groupby,

	[Parameter(Position=8, Mandatory=$false)]
	[System.String]
	$Compareby,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$Node,

	[Parameter(Position=10, Mandatory=$false)]
	[System.String]
	$Sortcol,
	
	[Parameter(Position=11, Mandatory=$false)]
	[System.String]
	$FPGname,

	[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRStatfsav - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRStatfsav since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRStatfsav since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srstatfsav "

 if($Attime)
 {
	$Cmd += " -attime "
 }

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Hires)
 {
	$Cmd += " -hires "
 }

 if($Hourly)
 {
	$Cmd += " -hourly "
 }

 if($Daily)
 {
	$Cmd += " -daily "
 }

 if($Summary)
 {
	$Cmd += " -summary $Summary "
 }

 if($Groupby)
 {
  $Cmd += " -groupby $Groupby "
 }

 if($Compareby)
 {
	$Cmd += " -compareby $Compareby "
 }

 if($Node)
 {
	$Cmd += " -node $Node "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }
 
 if($FPGname)
 {
	$Cmd += " $FPGname "
 } 

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRStatfsav Command -->" INFO: 
 Return $Result
} ##  End-of Get-SRStatfsav

##########################################################################
#########################FUNCTION Get-SRStatfsblock#########################
##########################################################################
Function Get-SRStatfsblock()
{
<#
  .SYNOPSIS
   Get-SRStatfsblock - System reporter performance reports for File Persona block devices.

  .DESCRIPTION
   The Get-SRStatfsblock command displays historical performance data reports for
   File Persona block devices.

  .EXAMPLE

  .PARAMETER Attime
   Performance is shown at a particular time interval, specified by the
   etsecs option, with one row per object group described by the
   groupby option. Without this option performance is shown versus time,
   with a row per time interval.

  .PARAMETER Btsecs
   Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.

  .PARAMETER Etsecs
   Select the end time in seconds for the report.  If -attime is specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.
   
  .PARAMETER Hires
   Select high resolution samples (5 minute intervals) for the report.
   This is the default.

  .PARAMETER Hourly
   Select hourly samples for the report.

  .PARAMETER Daily
   Select daily samples for the report.

  .PARAMETER Summary
   Summarize performance across requested objects and time range.
   One of these 4 summary keywords must be included:
	   min   Display the minimum for each metric
	   avg   Display the average for each metric
	   max   Display the maximum for each metric
	   <N>%  Display percentile for each metric. <N> may be any number
	   from 0 to 100. Multiple percentiles may be specified.
   Other keywords which modify the summary display or computation:
   detail
	   Display individual performance records in addition to one
	   or more summaries. By default, -summary output excludes
	   individual records and only displays the summary.
   per_time
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   time. By default, one summary is computed across all records.
   per_group
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   object grouping. By default, one summary is computed across all
	   records.
   only_compareby
	   When requesting data limited to certain object groupings with
	   the -compareby option, use this keyword to compute summaries
	   using only that reduced set of object groupings. By default,
	   summaries are computed from all records and ignore the
	   limitation of the -compareby option, though the "detail"
	   output does conform to the -compareby object limitation.

  .PARAMETER Groupby
   For -attime reports, generate a separate row for each combination of
   <groupby> items.  Each <groupby> must be different and
   one of the following:
   NODE            The controller node
   BLOCKDEV_NAME   The block device name

  .PARAMETER Compareby
   The compareby option limits output records to only certain objects,
   compared by a specified field.  Either the top or bottom X objects
   can be displayed, up to 32 objects for vstime reports or 128 objects
   for attime reports.  The field used for comparison can be any of the
   groupby fields or one of the following:
   reads, reads_merged, read_sectors, read_time_ms, writes, writes_merged,
   write_sectors, write_time_ms, ios_current, io_time_ms,
   io_time_weighted_ms

  .PARAMETER Node
   Limit the data to that corresponding to one of the specified nodes.

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
		Sort in increasing order (default).
	   dec
		Sort in decreasing order.
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.
   
  .PARAMETER BlockdevName  
	Block Devices matching either the specified name or glob-style pattern
	are included. This specifier can be repeated to display information
	for multiple devices. If not specified, all block devices are included.

  .Notes
    NAME: Get-SRStatfsblock
    LASTEDIT : December 2019
    KEYWORDS: Get-SRStatfsblock
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Attime,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Btsecs,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Etsecs,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Hires,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Hourly,

	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$Daily,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$Summary,

	[Parameter(Position=7, Mandatory=$false)]
	[System.String]
	$Groupby,

	[Parameter(Position=8, Mandatory=$false)]
	[System.String]
	$Compareby,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$Node,

	[Parameter(Position=10, Mandatory=$false)]
	[System.String]
	$Sortcol,

	[Parameter(Position=11, Mandatory=$false)]
	[System.String]
	$BlockdevName,

	[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRStatfsblock - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRStatfsblock since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRStatfsblock since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srstatfsblock "

 if($Attime)
 {
	$Cmd += " -attime "
 }

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Hires)
 {
	$Cmd += " -hires "
 }

 if($Hourly)
 {
	$Cmd += " -hourly "
 }

 if($Daily)
 {
	$Cmd += " -daily "
 }

 if($Summary)
 {
	$Cmd += " -summary $Summary "
 }

 if($Groupby)
 {
	$Cmd += " -groupby $Groupby "
 }

 if($Compareby)
 {
	$Cmd += " -compareby $Compareby "
 }

 if($Node)
 {
	$Cmd += " -node $Node "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }

 if($BlockdevName)
 {
	$Cmd += " $Blockdev_name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRStatfsblock Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-SRStatfsblock

##########################################################################
######################### FUNCTION Get-SRStatfscpu ###################
##########################################################################
Function Get-SRStatfscpu()
{
<#
  .SYNOPSIS
   Get-SRStatfscpu - System reporter performance reports for File Persona CPU usage.

  .DESCRIPTION
   The Get-SRStatfscpu command displays historical performance data reports for
   File Persona CPU utilization.

  .EXAMPLE

  .PARAMETER Attime
   Performance is shown at a particular time interval, specified by the
   etsecs option, with one row per object group described by the
   groupby option. Without this option performance is shown versus time,
   with a row per time interval.

  .PARAMETER Btsecs
   Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
	
  .PARAMETER Etsecs
   Select the end time in seconds for the report.  If -attime is specified, select the time for the report.
	The value can be specified as either
		- The absolute epoch time (for example 1351263600).
		- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
		- A negative number indicating the number of seconds before the
	current time. Instead of a number representing seconds, <secs> can
	be specified with a suffix of m, h or d to represent time in minutes
	(e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
        sample.

  .PARAMETER Hires
   Select high resolution samples (5 minute intervals) for the report.
   This is the default.

  .PARAMETER Hourly
   Select hourly samples for the report.

  .PARAMETER Daily
   Select daily samples for the report.

  .PARAMETER Summary
   Summarize performance across requested objects and time range.
   One of these 4 summary keywords must be included:
	   min   Display the minimum for each metric
	   avg   Display the average for each metric
	   max   Display the maximum for each metric
	   <N>%  Display percentile for each metric. <N> may be any number
	   from 0 to 100. Multiple percentiles may be specified.
   Other keywords which modify the summary display or computation:
   detail
	   Display individual performance records in addition to one
	   or more summaries. By default, -summary output excludes
	   individual records and only displays the summary.
   per_time
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   time. By default, one summary is computed across all records.
   per_group
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   object grouping. By default, one summary is computed across all
	   records.
   only_compareby
	   When requesting data limited to certain object groupings with
	   the -compareby option, use this keyword to compute summaries
	   using only that reduced set of object groupings. By default,
	   summaries are computed from all records and ignore the
	   limitation of the -compareby option, though the "detail"
	   output does conform to the -compareby object limitation.

  .PARAMETER Groupby
   For -attime reports, generate a separate row for each combination of
   <groupby> items. Each <groupby> must be different and one of the
   following:
   NODE   The controller node
   CPU    The CPU within the controller node

  .PARAMETER Compareby
   The compareby option limits output records to only certain objects,
   compared by a specified field.  Either the top or bottom X objects
   can be displayed, up to 32 objects for vstime reports or 128 objects
   for attime reports.  The field used for comparison can be any of the
   groupby fields or one of the following:
   usage_pct, iowait_pct, idle_pct

  .PARAMETER Node
   Limit the data to that corresponding to one of the specified nodes.

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
		Sort in increasing order (default).
	   dec
		Sort in decreasing order.
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.
   
  .PARAMETER CpuId
	Only the specified CPU ID numbers are included. This specifier can be
	repeated to display information for multiple CPUs. If not specified, all
	CPUs are included.

  .Notes
    NAME: Get-SRStatfscpu
    LASTEDIT : December 2019
    KEYWORDS: Get-SRStatfscpu
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Attime,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Btsecs,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Etsecs,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Hires,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Hourly,

	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$Daily,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$Summary,

	[Parameter(Position=7, Mandatory=$false)]
	[System.String]
	$Groupby,

	[Parameter(Position=8, Mandatory=$false)]
	[System.String]
	$Compareby,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$Node,

	[Parameter(Position=10, Mandatory=$false)]
	[System.String]
	$Sortcol,

	[Parameter(Position=11, Mandatory=$false)]
	[System.String]
	$CpuId,

	[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRStatfscpu - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRStatfscpu since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRStatfscpu since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srstatfscpu "

 if($Attime)
 {
	$Cmd += " -attime "
 }

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Hires)
 {
	$Cmd += " -hires "
 }

 if($Hourly)
 {
	$Cmd += " -hourly "
 }

 if($Daily)
 {
	$Cmd += " -daily "
 }

 if($Summary)
 {
	$Cmd += " -summary $Summary "
 }

 if($Groupby)
 {
	$Cmd += " -groupby $Groupby "
 }

 if($Compareby)
 {
	$Cmd += " -compareby $Compareby "
 }

 if($Node)
 {
	$Cmd += " -node $Node "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }

 if($CpuId)
 {
	$Cmd += " $CpuId "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRStatfscpu Command -->" INFO:
 
 Return $Result
} ##  End-of Get-SRStatfscpu

##########################################################################
#########################FUNCTION Get-SRStatfsfpg#########################
##########################################################################
Function Get-SRStatfsfpg()
{
<#
  .SYNOPSIS
   Get-SRStatfsfpg - System reporter performance reports for File Persona FPGs.

  .DESCRIPTION
   The Get-SRStatfsfpg command displays historical performance data reports for
   File Persona file provisioning groups.

  .EXAMPLE

  .PARAMETER Attime
   Performance is shown at a particular time interval, specified by the
   etsecs option, with one row per object group described by the
   groupby option. Without this option performance is shown versus time,
   with a row per time interval.

  .PARAMETER Btsecs
   Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
	
  .PARAMETER Etsecs
   Select the end time in seconds for the report.  If -attime is specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.

  .PARAMETER Hires
   Select high resolution samples (5 minute intervals) for the report.
   This is the default.

  .PARAMETER Hourly
   Select hourly samples for the report.

  .PARAMETER Daily
   Select daily samples for the report.

  .PARAMETER Summary
   Summarize performance across requested objects and time range.
   One of these 4 summary keywords must be included:
	   min   Display the minimum for each metric
	   avg   Display the average for each metric
	   max   Display the maximum for each metric
	   <N>%  Display percentile for each metric. <N> may be any number
	   from 0 to 100. Multiple percentiles may be specified.
	   
   Other keywords which modify the summary display or computation:
   detail
	   Display individual performance records in addition to one
	   or more summaries. By default, -summary output excludes
	   individual records and only displays the summary.
   per_time
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   time. By default, one summary is computed across all records.
   per_group
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   object grouping. By default, one summary is computed across all
	   records.
   only_compareby
	   When requesting data limited to certain object groupings with
	   the -compareby option, use this keyword to compute summaries
	   using only that reduced set of object groupings. By default,
	   summaries are computed from all records and ignore the
	   limitation of the -compareby option, though the "detail"
	   output does conform to the -compareby object limitation.

  .PARAMETER Groupby
   For -attime reports, generate a separate row for each combination of
   <groupby> items. Each <groupby> must be different and one of the
   following:
   FPG_NAME  File Provisioning Group name
   FPG_ID    File Provisioning Group ID
   NODE      The controller node

  .PARAMETER Compareby
   The compareby option limits output records to only certain objects,
   compared by a specified field.  Either the top or bottom X objects
   can be displayed, up to 32 objects for vstime reports or 128 objects
   for attime reports.  The field used for comparison can be any of the
   groupby fields or one of the following:
   Totalblocks, Freeblocks, Numreads, Numbytesread, Numwrites,
   NumBytesWritten, Creates, Removes, Errors, ReadLatency,
   WriteLatency

  .PARAMETER Node
   Limit the data to that corresponding to one of the specified nodes.

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
		Sort in increasing order (default).
	   dec
		Sort in decreasing order.
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.
   
  .PARAMETER FpgName
	File provisioning groups matching either the specified name or
	glob-style pattern are included. This specifier can be repeated to
	display information for multiple FPGs. If not specified, all FPGs
	are included.


  .Notes
    NAME: Get-SRStatfsfpg
    LASTEDIT : December 2019
    KEYWORDS: Get-SRStatfsfpg
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Attime,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Btsecs,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Etsecs,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Hires,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Hourly,

	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$Daily,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$Summary,

	[Parameter(Position=7, Mandatory=$false)]
	[System.String]
	$Groupby,

	[Parameter(Position=8, Mandatory=$false)]
	[System.String]
	$Compareby,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$Node,

	[Parameter(Position=10, Mandatory=$false)]
	[System.String]
	$Sortcol,

	[Parameter(Position=11, Mandatory=$false)]
	[System.String]
	$FpgName,

	[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRStatfsfpg - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRStatfsfpg since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRStatfsfpg since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srstatfsfpg "

 if($Attime)
 {
	$Cmd += " -attime "
 }

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Hires)
 {
	$Cmd += " -hires "
 }

 if($Hourly)
 {
	$Cmd += " -hourly "
 }

 if($Daily)
 {
	$Cmd += " -daily "
 }

 if($Summary)
 {
	$Cmd += " -summary $Summary "
 }

 if($Groupby)
 {
	$Cmd += " -groupby $Groupby "
 }

 if($Compareby)
 {
	$Cmd += " -compareby $Compareby "
 }

 if($Node)
 {
	$Cmd += " -node $Node "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }

 if($FpgName)
 {
	$Cmd += " $FpgName "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRStatfsfpg Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-SRStatfsfpg

##########################################################################
#########################FUNCTION Get-SRStatfsmem#########################
##########################################################################
Function Get-SRStatfsmem()
{
<#
  .SYNOPSIS
   srstatfsmem - System reporter performance reports for File Persona memory usage

  .DESCRIPTION
   The srstatfsmem command displays historical performance data reports for
   File Persona memory utilization.

  .EXAMPLE

  .PARAMETER Attime
   Performance is shown at a particular time interval, specified by the
   etsecs option, with one row per object group described by the
   groupby option. Without this option performance is shown versus time,
   with a row per time interval.

  .PARAMETER Btsecs
	Select the begin time in seconds for the report.
	The value can be specified as either
		- The absolute epoch time (for example 1351263600).
		- The absolute time as a text string in one of the following formats:
			- Full time string including time zone: "2012-10-26 11:00:00 PDT"
			- Full time string excluding time zone: "2012-10-26 11:00:00"
			- Date string: "2012-10-26" or 2012-10-26
			- Time string: "11:00:00" or 11:00:00
		- A negative number indicating the number of seconds before the
	current time. Instead of a number representing seconds, <secs> can
	be specified with a suffix of m, h or d to represent time in minutes
	(e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.

  .PARAMETER Etsecs
	Select the end time in seconds for the report.  If -attime is specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.
		
  .PARAMETER Hires
   Select high resolution samples (5 minute intervals) for the report.
   This is the default.

  .PARAMETER Hourly
   Select hourly samples for the report.

  .PARAMETER Daily
   Select daily samples for the report.

  .PARAMETER Summary
   Summarize performance across requested objects and time range.
   One of these 4 summary keywords must be included:
	   min   Display the minimum for each metric
	   avg   Display the average for each metric
	   max   Display the maximum for each metric
	   <N>%  Display percentile for each metric. <N> may be any number
	   from 0 to 100. Multiple percentiles may be specified.
	   Other keywords which modify the summary display or computation:
   detail
	   Display individual performance records in addition to one
	   or more summaries. By default, -summary output excludes
	   individual records and only displays the summary.
   per_time
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   time. By default, one summary is computed across all records.
   per_group
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   object grouping. By default, one summary is computed across all
	   records.
   only_compareby
	   When requesting data limited to certain object groupings with
	   the -compareby option, use this keyword to compute summaries
	   using only that reduced set of object groupings. By default,
	   summaries are computed from all records and ignore the
	   limitation of the -compareby option, though the "detail"
	   output does conform to the -compareby object limitation.

  .PARAMETER Groupby
   For -attime reports, generate a separate row for each combination of <groupby> items. Each
   <groupby> must be different and one of the following:
   NODE   The controller node

  .PARAMETER Compareby
   The compareby option limits output records to only certain objects,
   compared by a specified field.  Either the top or bottom X objects
   can be displayed, up to 32 objects for vstime reports or 128 objects
   for attime reports.  The field used for comparison can be any of the
   groupby fields or one of the following:
   usage_pct, swap_pct, free_pct

  .PARAMETER Node
   Limit the data to that corresponding to one of the specified nodes.

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
		Sort in increasing order (default).
	   dec
		Sort in decreasing order.
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.

  .Notes
    NAME: Get-SRStatfsmem
    LASTEDIT : December 2019
    KEYWORDS: Get-SRStatfsmem
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 [Parameter(Position=0, Mandatory=$false)]
 [switch]
 $Attime,

 [Parameter(Position=1, Mandatory=$false)]
 [System.String]
 $Btsecs,

 [Parameter(Position=2, Mandatory=$false)]
 [System.String]
 $Etsecs,

 [Parameter(Position=3, Mandatory=$false)]
 [switch]
 $Hires,

 [Parameter(Position=4, Mandatory=$false)]
 [switch]
 $Hourly,

 [Parameter(Position=5, Mandatory=$false)]
 [switch]
 $Daily,

 [Parameter(Position=6, Mandatory=$false)]
 [System.String]
 $Summary,

 [Parameter(Position=7, Mandatory=$false)]
 [System.String]
 $Groupby,

 [Parameter(Position=8, Mandatory=$false)]
 [System.String]
 $Compareby,

 [Parameter(Position=9, Mandatory=$false)]
 [System.String]
 $Node,

 [Parameter(Position=10, Mandatory=$false)]
 [System.String]
 $Sortcol,

 [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRStatfsmem - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRStatfsmem since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRStatfsmem since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srstatfsmem "

 if($Attime)
 {
	$Cmd += " -attime "
 }

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Hires)
 {
	$Cmd += " -hires "
 }

 if($Hourly)
 {
	$Cmd += " -hourly "
 }

 if($Daily)
 {
	$Cmd += " -daily "
 }

 if($Summary)
 {
	$Cmd += " -summary $Summary "
 }

 if($Groupby)
 {
	$Cmd += " -groupby $Groupby "
 }

 if($Compareby)
 {
	$Cmd += " -compareby $Compareby "
 }

 if($Node)
 {
	$Cmd += " -node $Node "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRStatfsmem Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-SRStatfsmem

##########################################################################
#########################FUNCTION Get-SRStatfsnet#########################
##########################################################################
Function Get-SRStatfsnet()
{
<#
  .SYNOPSIS
   Get-SRStatfsnet - System reporter performance reports for File Persona networking.

  .DESCRIPTION
   The Get-SRStatfsnet command displays historical performance data reports for
   File Persona networking devices.

  .EXAMPLE

  .PARAMETER Attime
   Performance is shown at a particular time interval, specified by the
   etsecs option, with one row per object group described by the
   groupby option. Without this option performance is shown versus time,
   with a row per time interval.

  .PARAMETER Btsecs
	Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
		
  .PARAMETER Etsecs
	Select the end time in seconds for the report.  If -attime is specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.

  .PARAMETER Hires
   Select high resolution samples (5 minute intervals) for the report.
   This is the default.

  .PARAMETER Hourly
   Select hourly samples for the report.

  .PARAMETER Daily
   Select daily samples for the report.

  .PARAMETER Summary
   Summarize performance across requested objects and time range.
   One of these 4 summary keywords must be included:
	   min   Display the minimum for each metric
	   avg   Display the average for each metric
	   max   Display the maximum for each metric
	   <N>%  Display percentile for each metric. <N> may be any number
	   from 0 to 100. Multiple percentiles may be specified.
	   Other keywords which modify the summary display or computation:
   detail
	   Display individual performance records in addition to one
	   or more summaries. By default, -summary output excludes
	   individual records and only displays the summary.
   per_time
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   time. By default, one summary is computed across all records.
   per_group
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   object grouping. By default, one summary is computed across all
	   records.
   only_compareby
	   When requesting data limited to certain object groupings with
	   the -compareby option, use this keyword to compute summaries
	   using only that reduced set of object groupings. By default,
	   summaries are computed from all records and ignore the
	   limitation of the -compareby option, though the "detail"
	   output does conform to the -compareby object limitation.

  .PARAMETER Groupby
   For -attime reports, generate a separate row for each combination of <groupby> items. Each
   <groupby> must be different and one of the following:
   NODE      The controller node
   DEV_NAME  Ethernet interface name

  .PARAMETER Compareby
   The compareby option limits output records to only certain objects,
   compared by a specified field.  Either the top or bottom X objects
   can be displayed, up to 32 objects for vstime reports or 128 objects
   for attime reports.  The field used for comparison can be any of the
   groupby fields or one of the following:
   rx_bytes, rx_packets, tx_bytes, tx_packets

  .PARAMETER Node
   Limit the data to that corresponding to one of the specified nodes.

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
		Sort in increasing order (default).
	   dec
		Sort in decreasing order.
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.

  .PARAMETER EthdevName
	Ethernet interface devices matching either the specified name or
	glob-style pattern are included. This specifier can be repeated to
	display information for multiple devices. If not specified, all devices
	are included.

  .Notes
    NAME: Get-SRStatfsnet
    LASTEDIT : December 2019
    KEYWORDS: Get-SRStatfsnet
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 [Parameter(Position=0, Mandatory=$false)]
 [switch]
 $Attime,

 [Parameter(Position=1, Mandatory=$false)]
 [System.String]
 $Btsecs,

 [Parameter(Position=2, Mandatory=$false)]
 [System.String]
 $Etsecs,

 [Parameter(Position=3, Mandatory=$false)]
 [switch]
 $Hires,

 [Parameter(Position=4, Mandatory=$false)]
 [switch]
 $Hourly,

 [Parameter(Position=5, Mandatory=$false)]
 [switch]
 $Daily,

 [Parameter(Position=6, Mandatory=$false)]
 [System.String]
 $Summary,

 [Parameter(Position=7, Mandatory=$false)]
 [System.String]
 $Groupby,

 [Parameter(Position=8, Mandatory=$false)]
 [System.String]
 $Compareby,

 [Parameter(Position=9, Mandatory=$false)]
 [System.String]
 $Node,

 [Parameter(Position=10, Mandatory=$false)]
 [System.String]
 $Sortcol,

 [Parameter(Position=11, Mandatory=$false)]
 [System.String]
 $EthdevName,

 [Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRStatfsnet - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRStatfsnet since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRStatfsnet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srstatfsnet "

 if($Attime)
 {
	$Cmd += " -attime "
 }

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Hires)
 {
	$Cmd += " -hires "
 }

 if($Hourly)
 {
	$Cmd += " -hourly "
 }

 if($Daily)
 {
	$Cmd += " -daily "
 }

 if($Summary)
 {
	$Cmd += " -summary $Summary "
 }

 if($Groupby)
 {
	$Cmd += " -groupby $Groupby "
 }

 if($Compareby)
 {
	$Cmd += " -compareby $Compareby "
 }

 if($Node)
 {
	$Cmd += " -node $Node "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }

 if($EthdevName)
 {
	$Cmd += " $EthdevName "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRStatfsnet Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-SRStatfsnet

##########################################################################
######################### FUNCTION Get-SRStatfsnfs ###################
##########################################################################
Function Get-SRStatfsnfs()
{
<#
  .SYNOPSIS
   Get-SRStatfsnfs - System reporter performance reports for File Persona NFS shares.

  .DESCRIPTION
   The Get-SRStatfsnfs command displays historical performance data reports for
   File Persona NFS shares.

  .EXAMPLE

  .PARAMETER Attime
   Performance is shown at a particular time interval, specified by the
   etsecs option, with one row per object group described by the
   groupby option. Without this option performance is shown versus time,
   with a row per time interval.

  .PARAMETER Btsecs
	Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
   
  .PARAMETER Etsecs
   Select the end time in seconds for the report.  If -attime is specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.

  .PARAMETER Hires
   Select high resolution samples (5 minute intervals) for the report.
   This is the default.

  .PARAMETER Hourly
   Select hourly samples for the report.

  .PARAMETER Daily
   Select daily samples for the report.

  .PARAMETER Summary
   Summarize performance across requested objects and time range.
	   One of these 4 summary keywords must be included:
	   min   Display the minimum for each metric
	   avg   Display the average for each metric
	   max   Display the maximum for each metric
	   <N>%  Display percentile for each metric. <N> may be any number
	   from 0 to 100. Multiple percentiles may be specified.
	   
   Other keywords which modify the summary display or computation:
   
   detail
	   Display individual performance records in addition to one
	   or more summaries. By default, -summary output excludes
	   individual records and only displays the summary.
   per_time
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   time. By default, one summary is computed across all records.
   per_group
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   object grouping. By default, one summary is computed across all
	   records.
   only_compareby
	   When requesting data limited to certain object groupings with
	   the -compareby option, use this keyword to compute summaries
	   using only that reduced set of object groupings. By default,
	   summaries are computed from all records and ignore the
	   limitation of the -compareby option, though the "detail"
	   output does conform to the -compareby object limitation.

  .PARAMETER Groupby
   For -attime reports, generate a separate row for each combination of <groupby> items. Each
   <groupby> must be different and one of the following:
   NODE   The controller node

  .PARAMETER Compareby
   The compareby option limits output records to only certain objects,
   compared by a specified field.  Either the top or bottom X objects
   can be displayed, up to 32 objects for vstime reports or 128 objects
   for attime reports.  The field used for comparison can be any of the
   groupby fields or one of the following:
   Client_RPC_calls, Client_RPC_retrans, Server_RPC_calls, Server_RPC_badcalls,
   V3_Null, V3_GetAttr, V3_SetAttr, V3_lookup, V3_access, V3_ReadLink, V3_Read,
   V3_Write, V3_Create, V3_MkDir, V3_Symlink, V3_Mknod, V3_Remove, V3_RmDir,
   V3_Rename, V3_Link, V3_ReadDir, V3_ReadDirPlus, V3_FsStat, V3_FsInfo,
   V3_PathConf, V3_Commit, V4_op0_unused, V4_op1_unused, V4_op2_future,
   V4_access, V4_close, V4_commit, V4_create, V4_delegpurge, V4_delegreturn,
   V4_getattr, V4_getfh, V4_link, V4_lock, V4_lockt, V4_locku, V4_lookup,
   V4_lookup_root, V4_nverify, V4_open, V4_openattr, V4_open_conf, V4_open_dgrd,
   V4_putfh, V4_putpubfh, V4_putrootfh, V4_Read, V4_reddir, V4_readlink, V4_remove,
   V4_rename, V4_renew, V4_restorefh, V4_savefh, V4_secinfo, V4_setattr, V4_setcltid,
   V4_setcltidconf, V4_verify, V4_Write, V4_rellockowner, V4_bc_ctl, V4_bind_conn,
   V4_exchange_id, V4_create_ses, V4_destroy_ses, V4_free_stateid, V4_getdirdeleg,
   V4_getdevinfo, V4_getdevlist, V4_layoutcommit, V4_layoutget, V4_layoutreturn,
   V4_secinfononam, V4_sequence, V4_set_ssv, V4_test_stateid, V4_want_deleg,
   V4_destroy_clid, V4_reclaim_comp

  .PARAMETER Node
   Limit the data to that corresponding to one of the specified nodes.

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
		Sort in increasing order (default).
	   dec
		Sort in decreasing order.
		
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.

  .Notes
    NAME: Get-SRStatfsnfs
    LASTEDIT : December 2019
    KEYWORDS: Get-SRStatfsnfs
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 [Parameter(Position=0, Mandatory=$false)]
 [switch]
 $Attime,

 [Parameter(Position=1, Mandatory=$false)]
 [System.String]
 $Btsecs,

 [Parameter(Position=2, Mandatory=$false)]
 [System.String]
 $Etsecs,

 [Parameter(Position=3, Mandatory=$false)]
 [switch]
 $Hires,

 [Parameter(Position=4, Mandatory=$false)]
 [switch]
 $Hourly,

 [Parameter(Position=5, Mandatory=$false)]
 [switch]
 $Daily,

 [Parameter(Position=6, Mandatory=$false)]
 [System.String]
 $Summary,

 [Parameter(Position=7, Mandatory=$false)]
 [System.String]
 $Groupby,

 [Parameter(Position=8, Mandatory=$false)]
 [System.String]
 $Compareby,

 [Parameter(Position=9, Mandatory=$false)]
 [System.String]
 $Node,

 [Parameter(Position=10, Mandatory=$false)]
 [System.String]
 $Sortcol,

 [Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRStatfsnfs - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRStatfsnfs since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRStatfsnfs since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srstatfsnfs "

 if($Attime)
 {
	$Cmd += " -attime "
 }

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Hires)
 {
	$Cmd += " -hires "
 }

 if($Hourly)
 {
	$Cmd += " -hourly "
 }

 if($Daily)
 {
	$Cmd += " -daily "
 }

 if($Summary)
 {
	$Cmd += " -summary $Summary "
 }

 if($Groupby)
 {
	$Cmd += " -groupby $Groupby "
 }

 if($Compareby)
 {
	$Cmd += " -compareby $Compareby "
 }

 if($Node)
 {
	$Cmd += " -node $Node "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRStatfsnfs Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-SRStatfsnfs

##################################################################
##################### Function Set-SRAlertCrit ###################
##################################################################
Function Set-SRAlertCrit
{
<#
  .SYNOPSIS
    Command allows users to enable or disable a System Reporter alert criterion
  
  .DESCRIPTION
    Command allows users to enable or disable a System Reporter alert criterion
        
  .EXAMPLE
    Set-SRAlertCrit -Enable -NameOfTheCriterionToModify write_port_check

  .EXAMPLE
	Set-SRAlertCrit -Disable -NameOfTheCriterionToModify write_port_check

  .EXAMPLE
	Set-SRAlertCrit -Daily -NameOfTheCriterionToModify write_port_check

  .EXAMPLE
	Set-SRAlertCrit -Info -Name write_port_check

  .PARAMETER Daily
	This criterion will be evaluated on a daily basis at midnight.

  .PARAMETER Hourly
	This criterion will be evaluated on an hourly basis.

  .PARAMETER Hires
	This criterion will be evaluated on a high resolution (5 minute) basis.
	This is the default.
		
  .PARAMETER Count
	The number of matching objects that must meet the criteria in order for
	the alert to be generated. Note that only one alert is generated in this
	case and not one alert per affected object.
		
  .PARAMETER Critical
	This alert has the highest severity.

  .PARAMETER Major
	This alert should require urgent action.

  .PARAMETER Minor
	This alert should not require immediate action.

  .PARAMETER Info
	This alert is informational only. This is the default.

  .PARAMETER Enable
	Enables the specified criterion.

  .PARAMETER Disable
	Disables the specified criterion.

  .PARAMETER NameOfTheCriterionToModify
	Specifies the name of the criterion to modify. 

  .PARAMETER Recurrences_Samples 
	The alert will only be generated if the other conditions of the
	criterion recur repeatedly. <recurrences> is an integer value from
	2 to 10, and <samples> is an integer from 2 to 10 representing the
	number of previous System Reporter samples in which the recurrences
	will be examined. <samples> must be at least the requested quantity of
	recurrences. Note that these samples refer to the selected resolution
	of the criterion: hires, hourly, or daily.

  .PARAMETER Btsecs
	A negative number indicating the number of seconds before the data
	sample time used to evaluate conditions which compare against an
	average. Instead of a number representing seconds, btsecs can be
	specified with a suffix of m, h or d to represent time in minutes
	(e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d). The relative time
	cannot be more than 10 samples ago: 50 minutes for hires, 10 hours
	for hourly, or 10 days for daily. If this option is not present the
	average is only computed for the most recent data sample. The
	-btsecs option may not be combined with the -recur option.
	
  .PARAMETER PAT
	Specifies that certain patterns are treated as glob-style patterns and
	that all criteria matching the specified pattern will be modified. This
	option must be used if the pattern specifier is used. This option
	cannot be combined with -name, -condition, or any of the type-specific
	filtering options.

  .PARAMETER ALL
	Specifies that all criteria will have the designated operation applied
	to them, changing the state or attributes of all criteria. This option
	cannot be combined with -name, -condition, or any of the type-specific
	filtering options.
		
  .PARAMETER NewName
	Specifies that the name of the SR alert be changed to <newname>, with a
	maximum of 31 characters.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Set-SRAlertCrit
    LASTEDIT: December 2019
    KEYWORDS: Set-SRAlertCrit
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(

		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Enable, 
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Disable,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily,    
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Count,		
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Recurrences_Samples,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $BtSecs,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Critical,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Major,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Minor,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Info,

		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $PAT,
		
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $ALL,
		
		[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $NewName,
		
		[Parameter(Position=15, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $NameOfTheCriterionToModify,		
		
		[Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Set-SRAlertCrit - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-SRAlertCrit since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Set-SRAlertCrit since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$version1 = Get-Version -S  -SANConnection $SANConnection
	if( $version1 -lt "3.2.1")
	{
		return "Current OS version $version1 does not support these cmdlet"
	}
	
	$srinfocmd = "setsralertcrit "	
	
	if($Enable)
	{
		$srinfocmd += " -enable " 
	}
	if($Disable)
	{
		$srinfocmd += " -disable " 
	}
	if($Daily)
	{
		$srinfocmd += " -daily " 
	}
	if($Hourly)
	{
		$srinfocmd += " -hourly " 
	}
	if($Hires)
	{
		$srinfocmd += " -hires " 
	}
	if($Count)
	{
		$srinfocmd += " -count $Count" 
	}
	if($Recurrences_Samples)
	{
		$srinfocmd += " -recur $Recurrences_Samples " 
	}
	if($BtSecs)
	{
		$srinfocmd += " -btsecs $BtSecs" 
	}
	if($Critical)
	{
		$srinfocmd += " -critical " 
	}
	if($Major)
	{
		$srinfocmd += " -major " 
	}
	if($Minor)
	{
		$srinfocmd += " -minor " 
	}
	if($Info)
	{
		$srinfocmd += " -info " 
	}
	if($PAT)
	{
		$srinfocmd += " -pat " 
	}
	if($ALL)
	{
		$srinfocmd += " -all " 
	}
	if($NewName)
	{
		$srinfocmd += " -name $NewName" 
	}
	if($NameOfTheCriterionToModify)
	{
		$srinfocmd += " $NameOfTheCriterionToModify" 
	}
	
	write-debuglog "Set alert crit command => $srinfocmd" "INFO:"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
	return $Result
}
## End Set-SRAlertCrit

#########################################################################
####################### Function Remove-SRAlertCrit #####################
#########################################################################
Function Remove-SRAlertCrit
{
<#
  .SYNOPSIS
    Command removes a criterion that System Reporter evaluates to determine if a performance alert should be generated.
  
  .DESCRIPTION
    Command removes a criterion that System Reporter evaluates to determine if a performance alert should be generated.        
  
  .EXAMPLE
    Remove-SRAlertCrit -force  -Name write_port_check 
	Example removes the criterion named write_port_check:
	
  .PARAMETER force
	Do not ask for confirmation before removing this criterion.

  .PARAMETER Name
	Specifies the name of the criterion to Remove.  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Remove-SRAlertCrit
    LASTEDIT: December 2019
    KEYWORDS: Remove-SRAlertCrit
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $Name,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
        $force,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Remove-SRAlertCrit - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-SRAlertCrit since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Remove-SRAlertCrit since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$version1 = Get-Version -S  -SANConnection $SANConnection
	if( $version1 -lt "3.2.1")
	{
		return "Current OS version $version1 does not support these cmdlet"
	}
	$srinfocmd = "removesralertcrit "
	if(($force) -and ($Name))
	{
		$srinfocmd += " -f $Name"		
	}
	else
	{
		return "FAILURE : Please specify -force or Name parameter values"
	}
	#write-host "Final Command is $srinfocmd"
	write-debuglog "Remove alert crit => $srinfocmd" "INFO:"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
	if($Result)
	{
		return "FAILURE : $Result"
	}
	else
	{
		return "Success : sralert $Name has been removed"
	}	
}
## End Remove-SRAlertCrit

##############################################################################################
##################################### Start New-SRAlertCrit ##################################
##############################################################################################
Function New-SRAlertCrit
{
<#
  .SYNOPSIS
    Creates a criterion that System Reporter evaluates to determine if a performance alert should be generated.
  
  .DESCRIPTION
    Creates a criterion that System Reporter evaluates to determine if a performance alert should be generated.
        
  .EXAMPLE
    New-SRAlertCrit -Type port  -Condition "write_iops>50" -Name write_port_check
	Example describes a criterion that generates an alert for each port that has more than 50 write IOPS in a high resolution sample:
	
  .EXAMPLE
    New-SRAlertCrit -Type port  -PortType disk -Condition "write_iops>50" -Name write_port_check   

  .PARAMETER Type
	Type must be one of the following: port, vlun, pd, ld, cmp, cpu, link, qos,
	rcopy, rcvv, ldspace, pdspace, cpgspace, vvspace, sysspace.

  .PARAMETER Condition
	The condition must be of the format <field><comparison><value>
	where field is one of the fields corresponding to the type (see above),
	comparison is of the format <,<=,>,>=,=,!= and value is a numeric value,
	or is a numeric value followed by %_average to indicate that the field
	is to be compared against the average across multiple objects as
	as specified by filtering options and/or across multiple data sample
	times as specified by the -btsecs option. See examples.
	Note that some characters, such as < and >, are significant in most
	shells and must be escaped or quoted when running this command from
	another shell. Multiple conditions may be separated by comma (",") to
	indicate a logical AND requirement (conjunction). Conditions may be
	separated by the character "~" to indicate a logical OR requirement
	(disjunction). AND logic takes precedence over OR logic, and
	parentheses are not supported to override the natural precedence
	of the condition terms and logical operators.

  .PARAMETER Name
	Specifies the name of the SR alert criterion, with a maximum of 31
	characters.
	
  .PARAMETER Daily
	This criterion will be evaluated on a daily basis at midnight.

  .PARAMETER Hourly
	This criterion will be evaluated on an hourly basis.

  .PARAMETER Hires
	This criterion will be evaluated on a high resolution (5 minute) basis.
	This is the default.

  .PARAMETER Count 
	The number of matching objects that must meet the criteria in order for
	the alert to be generated. Note that only one alert is generated in this
	case and not one alert per affected object.

  .PARAMETER Recurrences 
	The alert will only be generated if the other conditions of the
	criterion recur repeatedly. <recurrences> is an integer value from
	2 to 10, and <samples> is an integer from 2 to 10 representing the
	number of previous System Reporter samples in which the recurrences
	will be examined. <samples> must be at least the requested quantity of
	recurrences. Note that these samples refer to the selected resolution
	of the criterion: hires, hourly, or daily.

  .PARAMETER Btsecs 
	A negative number indicating the number of seconds before the data
	sample time used to evaluate conditions which compare against an
	average. Instead of a number representing seconds, btsecs can be
	specified with a suffix of m, h or d to represent time in minutes
	(e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d). The relative time
	cannot be more than 10 samples ago: 50 minutes for hires, 10 hours
	for hourly, or 10 days for daily. If this option is not present the
	average is only computed for the most recent data sample. The
	-btsecs option may not be combined with the -recur option.

  .PARAMETER Critical
	This alert has the highest severity.

  .PARAMETER Major
	This alert should require urgent action.

  .PARAMETER Minor
	This alert should not require immediate action.

  .PARAMETER Info
	This alert is informational only. This is the default.

  .PARAMETER Comment 
	Specifies comments or additional information for the criterion. The
	comment can be up to 511 characters long.
		
  .PARAMETER PortType 
	Limit the data to port of the types specified. Allowed types are
	disk  -  Disk port
	host  -  Host Fibre channel port
	iscsi -  Host ISCSI port
	free  -  Unused port
	fs    -  File Persona port
	peer  -  Data Migration FC port
	rcip  -  Remote copy IP port
	rcfc  -  Remote copy FC port

  .PARAMETER Port 
	Ports with <port_n>:<port_s>:<port_p> that match any of the specified
	<npat>:<spat>:<ppat> patterns are included, where each of the patterns
	is a glob-style pattern. If not specified, all ports are included.

  .PARAMETER Both 
	Specifies that both control and data transfers are displayed(-both),
	only control transfers are displayed (-ctl), or only data transfers are
	displayed (-data). If this option is not specified, only data transfers
	are displayed.
		
  .PARAMETER CTL
	Specifies that both control and data transfers are displayed(-both),
	only control transfers are displayed (-ctl), or only data transfers are
	displayed (-data). If this option is not specified, only data transfers
	are displayed.
		
  .PARAMETER Data
	Specifies that both control and data transfers are displayed(-both),
	only control transfers are displayed (-ctl), or only data transfers are
	displayed (-data). If this option is not specified, only data transfers
	are displayed.
		
  .PARAMETER Host
	Limit the data to hosts with names that match one or more of the
	specified names or glob-style patterns. Host set name must start with
	"set:" and can also include patterns. To specify the host by WWN,
	start with "wwn:". A WWN can also include glob-style patterns.

  .PARAMETER VV 
	Limit the data to VVs with names that match one or more of the
	specified names or glob-style patterns. VV set name must be prefixed
	by "set:" and can also include patterns.

  .PARAMETER vLun 
	Limit the data to VLUNs matching the specified combination of host, VV,
	lun, and port. Each of these components in this option may be a
	glob-style pattern. The host and VV components may specify a
	corresponding object set by prefixing "set:" to the component. The
	host component may specify a WWN by prefixing the component with
	"wwn:". The lun and port components are optional, and if not present,
	data will be filtered to any matching combination of host and VV.
	This option cannot be combined with -host, -vv, -l, or -port.

  .PARAMETER CPG 
	Limit the data to LDs in CPGs with names that match one or more of the
	specified names or glob-style patterns.
		
  .PARAMETER DiskType 
	Limit the data to disks of the types specified. Allowed types are
	FC  - Fast Class
	NL  - Nearline
	SSD - Solid State Drive
			
  .PARAMETER RPM 
	Limit the data to disks of the specified RPM. Allowed speeds are
	7, 10, 15, 100 and 150
		
  .PARAMETER Target 
	Limit the data to TARGET_NAMEs that match one or more of the specified
	TARGET_NAMEs or glob-style patterns.
		
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .PARAMETER Duration
	Once an alert is generated, the deferral period prevents the same
	alert from being repeated for a period of time. The deferral duration
	can be specified in seconds or with a suffix of m, h or d to represent
	time in minutes (e.g. 30m), hours (e.g. 1.5h), or days (e.g. 7d).
	Note that a single alert criteria can generate multiple alerts if
	multiple objects exceed the defined threshold. A deferral period
	applies to each unique alert. Acknowledging an alert with
	"setalert ack <id>" will end its deferral period early.
	
  .Notes
    NAME:  New-SRAlertCrit
    LASTEDIT: December 2019
    KEYWORDS: New-SRAlertCrit
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(

		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $Type ,
		
		[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $Condition ,
		
		[Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $Name ,
		
		[Parameter(Position=3, ValueFromPipeline=$true)]
		[switch]
        $Daily , 
		
		[Parameter(Position=4, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,
		
		[Parameter(Position=5, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		
		[Parameter(Position=6, ValueFromPipeline=$true)]
		[System.String]
        $Count ,
		
		[Parameter(Position=7, ValueFromPipeline=$true)]
		[System.String]
        $Recurrences ,
		
		[Parameter(Position=8, ValueFromPipeline=$true)]
		[System.String]
        $Btsecs ,
		
		[Parameter(Position=9, ValueFromPipeline=$true)]
		[switch]
        $Critical ,
		
		[Parameter(Position=10, ValueFromPipeline=$true)]
		[switch]
        $Major ,
		
		[Parameter(Position=11, ValueFromPipeline=$true)]
		[switch]
        $Minor ,
		
		[Parameter(Position=12, ValueFromPipeline=$true)]
		[switch]
        $Info ,
		
		[Parameter(Position=13, ValueFromPipeline=$true)]
		[System.String]
        $Comment ,
		
		[Parameter(Position=14, ValueFromPipeline=$true)]
		[System.String]
        $PortType ,
		
		[Parameter(Position=15, ValueFromPipeline=$true)]
		[System.String]
        $PortNSP ,
		
		[Parameter(Position=16, ValueFromPipeline=$true)]
		[switch]
        $Both ,
		
		[Parameter(Position=17, ValueFromPipeline=$true)]
		[switch]
        $CTL ,
		
		[Parameter(Position=18, ValueFromPipeline=$true)]
		[switch]
        $Data ,
		
		[Parameter(Position=19, ValueFromPipeline=$true)]
		[System.String]
        $Host ,
		
		[Parameter(Position=20, ValueFromPipeline=$true)]
		[System.String]
        $VV ,
		
		[Parameter(Position=21, ValueFromPipeline=$true)]
		[System.String]
        $vLun ,
		
		[Parameter(Position=22, ValueFromPipeline=$true)]
		[System.String]
        $Node ,
		
		[Parameter(Position=23, ValueFromPipeline=$true)]
		[System.String]
        $CPG ,
		
		[Parameter(Position=24, ValueFromPipeline=$true)]
		[System.String]
        $DiskType ,
		
		[Parameter(Position=25, ValueFromPipeline=$true)]
		[System.String]
        $RPM ,
		
		[Parameter(Position=26, ValueFromPipeline=$true)]
		[System.String]
        $Target ,
		
		[Parameter(Position=27, ValueFromPipeline=$true)]
		[System.String]
        $Duration ,
		
		[Parameter(Position=28, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In New-SRAlertCrit - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-SRAlertCrit since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet New-SRAlertCrit since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$version1 = Get-Version -S  -SANConnection $SANConnection
	if( $version1 -lt "3.2.1")
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
	
	$srinfocmd = "createsralertcrit "	
	
	if($Type)
	{
		$typearray = "port","vlun","pd","ld","cmp","cpu","link","qos","rcopy","rcvv"
		if($typearray -match $Type)
		{
			$srinfocmd += " $Type "
		}
		else
		{
			return "FAILURE : Type should be in [ port | vlun | pd | ld | cmp | cpu | link | qos | rcopy | rcvv ]"
		}
	}
	else
	{
		return "Invalid type or type is missing."
	}
	if($Daily)
	{
		$srinfocmd += " -daily "
	}
	if($Hourly)
	{
		$srinfocmd += " -hourly "
	}
	if($Hires)
	{
		$srinfocmd += " -hires "
	}
	if($Count)
	{
		$srinfocmd += " -count $Count "
	}
	if($Recurrences)
	{
		$srinfocmd += " -recur $Recurrences "
	}
	if($Btsecs)
	{
		$srinfocmd += " -btsecs $Btsecs "
	}
	if($Critical)
	{
		$srinfocmd += " -critical "
	}
	if($Major)
	{
		$srinfocmd += " -major "
	}
	if($Minor)
	{
		$srinfocmd += " -minor "
	}
	if($Info)
	{
		$srinfocmd += " -info "
	}
	if($Comment)
	{
		$srinfocmd += " -comment $Comment "
	}
	if($Duration)
	{
		$srinfocmd += " defer $Duration "
	}
	if($PortType)
	{
		$PortTypeArray = "disk","host","iscsi","free","fs","peer","rcip","rcfc"
		if($PortTypeArray -match $PortType)
		{
			$srinfocmd += " -port_type $PortType "
		}
		else
		{
			return "FAILURE : Type name should be in [ disk | host | iscsi | free | fs | peer | rcip | rcip ]"
		}
	}
	if($PortNSP)
	{
		$srinfocmd += " -port $PortNSP "
	}
	if($Both)
	{
		$srinfocmd += " -both "
	}
	if($CTL)
	{
		$srinfocmd += " -ctl "
	}
	if($Data)
	{
		$srinfocmd += " -data "
	}
	if($Host)
	{
		$srinfocmd += " -host $Host "
	}
	if($VV)
	{
		$srinfocmd += " -vv $VV "
	}
	if($vLun)
	{
		$srinfocmd += " -vlun $vLun "
	}
	if($Node)
	{
		$srinfocmd += " -node $Node "
	}
	if($CPG)
	{
		$srinfocmd += " -cpg $CPG "
	}
	if($DiskType)
	{
		$srinfocmd += " -disk_type $DiskType "
	}
	if($RPM)
	{
		$srinfocmd += " -rpm $RPM "
	}
	if($Target)
	{
		$srinfocmd += " -target $Target "
	}
	if($Condition)
	{
		$srinfocmd += " $Condition "
	}
	else
	{
		return "Condition is mandatory."
	}
	if($Name)
	{
		$srinfocmd += " $Name "
	}
	else
	{
		return "Name is Missing Specifies the name of the SR alert criterion, with a maximum of 31 characters."
	}
	
	#write-host "Final Command is $srinfocmd"
	write-debuglog "Create alert criteria command => $srinfocmd" "INFO:"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Executing New-SRAlertCrit Command $Result"
	}
	else
	{
		return  "FAILURE : While Executing New-SRAlertCrit $Result "
	}
}
## End New-SRAlertCrit

############################################################################
############################ Function Get-SRStatPort #######################
############################################################################
Function Get-SRStatPort
{
<#
  .SYNOPSIS
	System reporter performance reports for ports.
  
  .DESCRIPTION
	System reporter performance reports for ports.
	
  .EXAMPLE
    Get-SRStatPort 
	System reporter performance reports for ports.
	 
  .EXAMPLE
    Get-SRStatPort -portType "disk,host" -Hourly -btsecs -24h -port "0:*:* 1:*:*"
	Sexample displays aggregate hourly performance statistics for disk and host ports on nodes 0 and 1 beginning 24 hours ago:
	 
  .EXAMPLE
    Get-SRStatPort -Groupby PORT_N
	
  .EXAMPLE
    Get-SRStatPort -portType rcip
	 
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
 
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
	
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
		
  .PARAMETER Hourly
	Select hourly samples for the report.
		
  .PARAMETER Daily   
	Select daily samples for the report.
		
  .PARAMETER Groupby
	For -attime reports, generate a separate row for each combination of <groupby> items.  Each <groupby> must be different and one of the following:
	PORT_N    The node number for the port
	PORT_S    The PCI slot number for the port
	PORT_P    The port number for the port
	PORT_TYPE The type of the port
	GBITPS    The speed of the port

   .PARAMETER portType    
	Limit the data to port of the types specified. Allowed types are
	disk  -  Disk port
	host  -  Host Fibre channel port
	iscsi -  Host ISCSI port
	free  -  Unused port
	fs    -  File Persona port
	peer  -  Data Migration FC port
	rcip  -  Remote copy IP port
	rcfc  -  Remote copy FC port

  .PARAMETER port
    <npat>:<spat>:<ppat>
	Ports with <port_n>:<port_s>:<port_p> that match any of the specified
	<npat>:<spat>:<ppat> patterns are included, where each of the patterns
	is a glob-style pattern. This specifier can be repeated to include
	multiple ports or patterns. If not specified, all ports are included.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRStatPort
    LASTEDIT: December 2019
    KEYWORDS: Get-SRStatPort
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$portType,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$port,
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-SRStatPort - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRStatPort since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRStatPort since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srstatport "
	$3parosver = Get-Version -S  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "PORT_N","PORT_S","PORT_P","PORT_TYPE","GBITPS"				
			$lista = $groupby.split(",")
			foreach($suba in $lista){
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		if($portType)
		{
			$commarr = "disk","host","iscsi","free","fs","peer","rcip","rcfc"
			$splitarr = $portType.split(",")
			foreach ($s in $splitarr){
				if($commarr -match $s.toLower())
				{				
				}
				else
				{
					return "FAILURE: Invalid port type option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -port_type $portType"

		}
		if($port)
		{
			$srinfocmd += " $port "
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "PORT_TYPE"
			}
			Add-Content -Path $tempFile -Value "PORT_TYPE,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
			$rangestart = "3"
			$rangestart = "4"
		}
		elseif($groupby)
		{
			$optionname = $groupby.toUpper()
			$rangestart = "2"	
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,$optionname,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"			
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"			
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		if($range1 -le "4")
		{
			del $tempFile
			return "No data available"
		}
		$range1 = $range1 - 3
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile	
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRStatPort

#####################################################################################
################################ Function Get-SRStatPD ##############################
#####################################################################################
Function Get-SRStatPD
{
<#
  .SYNOPSIS
    System reporter performance reports for physical disks (PDs).
  
  .DESCRIPTION
    System reporter performance reports for physical disks (PDs).
	
  .EXAMPLE
    Get-SRStatPD 
	System reporter performance reports for physical disks (PDs).
	
  .EXAMPLE
    Get-SRStatPD -Hourly -btsecs -24h
	example displays aggregate hourly performance statistics for all physical disks beginning 24 hours ago:

  .EXAMPLE
    Get-SRStatPD -Groupby SPEED
	
  .EXAMPLE
    Get-SRStatPD -rpmSpeed 100
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
	
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
		
  .PARAMETER etsecs
	Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
		
  .PARAMETER Hourly
	Select hourly samples for the report.
		
  .PARAMETER Daily   
	Select daily samples for the report.
		
  .PARAMETER Groupby
	For -attime reports, generate a separate row for each combination of <groupby> items.  Each <groupby> must be different and one of the following:
	PDID      Physical disk ID
	PORT_N    The node number for the primary port for the the PD
	PORT_S    The PCI slot number for the primary port for the the PD
	PORT_P    The port number for the primary port for the the PD
	DISK_TYPE  The disktype of the PD
	SPEED     The speed of the PD
	
   .PARAMETER diskType    
	Limit the data to disks of the types specified. Allowed types are
		FC  - Fast Class
		NL  - Nearline
		SSD - Solid State Drive
		
   .PARAMETER rpmSpeed   
	Limit the data to disks of the specified RPM. Allowed speeds are 7, 10, 15, 100 and 150
		
  .PARAMETER PDID
	PDs with IDs that match either the specified PDID or glob-style pattern are included. This specifier can be repeated to include multiple PDIDs or patterns. If not specified, all PDs are included.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRStatPD
    LASTEDIT: December 2019
    KEYWORDS: Get-SRStatPD
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$diskType,
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$rpmSpeed,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$PDID,		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-SRStatPD - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRStatPD since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRStatPD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection

	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srstatpd "
	$3parosver = Get-Version -S  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "PDID","PORT_N","PORT_S","PORT_P","DISK_TYPE","SPEED"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		if($diskType)
		{
			$diskarr1 = "FC","NL","SSD"
			if($diskarr1 -eq $diskType.toUpper())
			{
				$srinfocmd += " -disk_type $diskType"
			}
			else
			{
				return "FAILURE: Invalid diskType Option it should be in ( $diskarr1 )"
			}	
		}
		if($rpmSpeed)
		{
			$rpmarr1 = "7","10","15","100","150"
			if($rpmarr1 -eq $rpmSpeed)
			{
				$srinfocmd += " -rpm $rpmSpeed"
			}
			else
			{
				return "FAILURE: Invalid rpm speed option it should be in ( $diskarr1 )"
			}	
		}
		if($PDID)
		{
			$srinfocmd += " $PDID "
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "PDID"
			}
			Add-Content -Path $tempFile -Value "PDID,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
			$rangestart = "3"
			#$rangestart = "4"
		}
		elseif($groupby)
		{
			$optionname = $groupby.toUpper()
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,$optionname,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
		}
		Write-DebugLog "INFO: In Get-SRStatPD - cmd is -> $srinfocmd" $Debug
		#write-host " cmd = $srinfocmd"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd		
		if($Result -contains "FAILURE")
		{	
			del $tempFile
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		if($range1 -le "4")
		{
			del $tempFile
			return "No data available"
		}
		$range1 = $range1 - 3
		foreach ($s in  $Result[$rangestart..$range1] )
		{			
			$s= [regex]::Replace($s,"^ +","")			
			$s= [regex]::Replace($s," +"," ")			
			$s= [regex]::Replace($s," ",",")		
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile	
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRStatPD

##########################################################################
#########################FUNCTION Get-SRStatfssmb#########################
##########################################################################
Function Get-SRStatfssmb()
{
<#
  .SYNOPSIS
   Get-SRStatfssmb - System reporter performance reports for File Persona SMB shares.

  .DESCRIPTION
   The Get-SRStatfssmb command displays historical performance data reports for
   File Persona SMB shares.

  .EXAMPLE

  .PARAMETER Attime
   Performance is shown at a particular time interval, specified by the
   etsecs option, with one row per object group described by the
   groupby option. Without this option performance is shown versus time,
   with a row per time interval.

  .PARAMETER Btsecs
	Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.

  .PARAMETER Etsecs
	Select the end time in seconds for the report.  If -attime is specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.

  .PARAMETER Hires
   Select high resolution samples (5 minute intervals) for the report.
   This is the default.

  .PARAMETER Hourly
   Select hourly samples for the report.

  .PARAMETER Daily
   Select daily samples for the report.

  .PARAMETER Summary
   Summarize performance across requested objects and time range.
   One of these 4 summary keywords must be included:
	   min   Display the minimum for each metric
	   avg   Display the average for each metric
	   max   Display the maximum for each metric
	   <N>%  Display percentile for each metric. <N> may be any number
	   from 0 to 100. Multiple percentiles may be specified.
   Other keywords which modify the summary display or computation:
   detail
	   Display individual performance records in addition to one
	   or more summaries. By default, -summary output excludes
	   individual records and only displays the summary.
   per_time
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   time. By default, one summary is computed across all records.
   per_group
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   object grouping. By default, one summary is computed across all
	   records.
   only_compareby
	   When requesting data limited to certain object groupings with
	   the -compareby option, use this keyword to compute summaries
	   using only that reduced set of object groupings. By default,
	   summaries are computed from all records and ignore the
	   limitation of the -compareby option, though the "detail"
	   output does conform to the -compareby object limitation.

  .PARAMETER Groupby
   For -attime reports, generate a separate row for each combination of <groupby> items. Each
   <groupby> must be different and one of the following:
   NODE   Statistics per node

  .PARAMETER Compareby
   The compareby option limits output records to only certain objects,
   compared by a specified field.  Either the top or bottom X objects
   can be displayed, up to 32 objects for vstime reports or 128 objects
   for attime reports.  The field used for comparison can be any of the
   groupby fields or one of the following:
   connections, maxConnections, sessions, maxSessions, treeConnects,
   maxTreeConnects, openFiles, maxOpenFiles, ReadSumRecorded,
   ReadSampleRecorded, WriteSumRecorded, WriteSampleRecorded

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
		Sort in increasing order (default).
	   dec
		Sort in decreasing order.
		
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.

  .Notes
    NAME: Get-SRStatfssmb
    LASTEDIT : December 2019
    KEYWORDS: Get-SRStatfssmb
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 [Parameter(Position=0, Mandatory=$false)]
 [switch]
 $Attime,

 [Parameter(Position=1, Mandatory=$false)]
 [System.String]
 $Btsecs,

 [Parameter(Position=2, Mandatory=$false)]
 [System.String]
 $Etsecs,

 [Parameter(Position=3, Mandatory=$false)]
 [switch]
 $Hires,

 [Parameter(Position=4, Mandatory=$false)]
 [switch]
 $Hourly,

 [Parameter(Position=5, Mandatory=$false)]
 [switch]
 $Daily,

 [Parameter(Position=6, Mandatory=$false)]
 [System.String]
 $Summary,

 [Parameter(Position=7, Mandatory=$false)]
 [System.String]
 $Groupby,

 [Parameter(Position=8, Mandatory=$false)]
 [System.String]
 $Compareby,

 [Parameter(Position=9, Mandatory=$false)]
 [System.String]
 $Sortcol,

 [Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRStatfssmb - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRStatfssmb since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRStatfssmb since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srstatfssmb "

 if($Attime)
 {
	$Cmd += " -attime "
 }

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Hires)
 {
	$Cmd += " -hires "
 }

 if($Hourly)
 {
	$Cmd += " -hourly "
 }

 if($Daily)
 {
	$Cmd += " -daily "
 }

 if($Summary)
 {
	$Cmd += " -summary $Summary "
 }

 if($Groupby)
 {
	$Cmd += " -groupby $Groupby "
 }

 if($Compareby)
 {
	$Cmd += " -compareby $Compareby "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRStatfssmb Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-SRStatfssmb

#################################################################################
########################### Function Get-SRStatLD ###############################
#################################################################################
Function Get-SRStatLD
{
<#
  .SYNOPSIS
    Command displays historical performance data reports for logical disks.
  
  .DESCRIPTION
    Command displays historical performance data reports for logical disks.
	
  .EXAMPLE
    Get-SRStatLD 
	Command displays historical performance data reports for logical disks.
	
  .EXAMPLE
    Get-SRStatLD -Hourly -btsecs -24h
	example displays aggregate hourly performance statistics for all logical disks beginning 24 hours ago:
	
  .EXAMPLE
    Get-SRStatLD -Groupby Node
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
	
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
		
  .PARAMETER etsecs
    Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
		
  .PARAMETER Hourly
	Select hourly samples for the report.
		
  .PARAMETER Daily   
	Select daily samples for the report.
		
  .PARAMETER Groupby
	For -attime reports, generate a separate row for each combination of  <groupby> items.  Each <groupby> must be different and one of the following:
	DOM_NAME  Domain name
	LDID      Logical disk ID
	LD_NAME   Logical disk name
	CPG_NAME  Common Provisioning Group name
	NODE      The node that owns the LD
	
   .PARAMETER cpgName 	
	Limit the data to LDs in CPGs with names that match one or more of the specified names or glob-style patterns.
	
  .PARAMETER Node  
	Limit the data to that corresponding to one of the specified nodes	
	-Node 0,1,2
	
  .PARAMETER LDName
	LDs matching either the specified LD_name or glob-style pattern are included. This specifier can be repeated to display information for multiple LDs. If not specified, all LDs are included.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRStatLD
    LASTEDIT: December 2019
    KEYWORDS: Get-SRStatLD
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$cpgName,
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$Node,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$LDName,		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-SRStatLD - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRStatLD since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRStatLD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srstatld "
	$3parosver = Get-Version -S  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "LDID","DOM_NAME","LD_NAME","CPG_NAME","NODE"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		if($Node)
		{
			$nodes = $Node.split(",")
			$srinfocmd += " $nodes"			
		}
		if($cpgName)
		{
			$srinfocmd += " -cpg $cpgName "
		}
		if($LDName)
		{
			$srinfocmd += " $LDName "
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "LD_NAME"
			}
			
			Add-Content -Path $tempFile -Value "LD_NAME,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"												
			$rangestart = "3"		
		}
		elseif($groupby)
		{
			$optionname = $groupby.toUpper()
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,$optionname,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
		}
		else
		{			
			$rangestart = "2"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			del $tempFile
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		if($range1 -le "4")
		{
			del $tempFile
			return "No data available"
		}
		$range1 = $range1 - 3
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile	
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRStatLD

##########################################################################
######################### FUNCTION Get-SRStatfssnapshot ##############
##########################################################################
Function Get-SRStatfssnapshot()
{
<#
  .SYNOPSIS
   Get-SRStatfssnapshot - System reporter performance reports for File Persona snapshots

  .DESCRIPTION
   The Get-SRStatfssnapshot command displays historical performance data reports
   for File Persona snapshots.

  .EXAMPLE

  .PARAMETER Attime
   Performance is shown at a particular time interval, specified by the
   etsecs option, with one row per object group described by the
   groupby option. Without this option performance is shown versus time,
   with a row per time interval.

  .PARAMETER Btsecs
	Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.

  .PARAMETER Etsecs
	Select the end time in seconds for the report.  If -attime is specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.

  .PARAMETER Hires
   Select high resolution samples (5 minute intervals) for the report.
   This is the default.

  .PARAMETER Hourly
   Select hourly samples for the report.

  .PARAMETER Daily
   Select daily samples for the report.

  .PARAMETER Summary
   Summarize performance across requested objects and time range.
	   One of these 4 summary keywords must be included:
	   min   Display the minimum for each metric
	   avg   Display the average for each metric
	   max   Display the maximum for each metric
	   <N>%  Display percentile for each metric. <N> may be any number
	   from 0 to 100. Multiple percentiles may be specified.
   Other keywords which modify the summary display or computation:
   detail
	   Display individual performance records in addition to one
	   or more summaries. By default, -summary output excludes
	   individual records and only displays the summary.
   per_time
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   time. By default, one summary is computed across all records.
   per_group
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   object grouping. By default, one summary is computed across all
	   records.
   only_compareby
	   When requesting data limited to certain object groupings with
	   the -compareby option, use this keyword to compute summaries
	   using only that reduced set of object groupings. By default,
	   summaries are computed from all records and ignore the
	   limitation of the -compareby option, though the "detail"
	   output does conform to the -compareby object limitation.

  .PARAMETER Groupby
   For -attime reports, generate a separate row for each combination of <groupby> items. Each
   <groupby> must be different and one of the following:
   NODE   The controller node

  .PARAMETER Compareby
   The compareby option limits output records to only certain objects,
   compared by a specified field.  Either the top or bottom X objects
   can be displayed, up to 32 objects for vstime reports or 128 objects
   for attime reports.  The field used for comparison can be any of the
   groupby fields or one of the following:
   numredirectonwrite

  .PARAMETER Node
   Limit the data to that corresponding to one of the specified nodes.

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
		Sort in increasing order (default).
	   dec
		Sort in decreasing order.
		
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.

  .Notes
    NAME: Get-SRStatfssnapshot
    LASTEDIT : December 2019
    KEYWORDS: Get-SRStatfssnapshot
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Attime,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Btsecs,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Etsecs,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Hires,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Hourly,

	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$Daily,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$Summary,

	[Parameter(Position=7, Mandatory=$false)]
	[System.String]
	$Groupby,

	[Parameter(Position=8, Mandatory=$false)]
	[System.String]
	$Compareby,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$Node,

	[Parameter(Position=10, Mandatory=$false)]
	[System.String]
	$Sortcol,

	[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRStatfssnapshot - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRStatfssnapshot since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRStatfssnapshot since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srstatfssnapshot "

 if($Attime)
 {
	$Cmd += " -attime "
 }

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Hires)
 {
	$Cmd += " -hires "
 }

 if($Hourly)
 {
	$Cmd += " -hourly "
 }

 if($Daily)
 {
	$Cmd += " -daily "
 }

 if($Summary)
 {
	$Cmd += " -summary $Summary "
 }

 if($Groupby)
 {
	$Cmd += " -groupby $Groupby "
 }

 if($Compareby)
 {
	$Cmd += " -compareby $Compareby "
 }

 if($Node)
 {
	$Cmd += " -node $Node "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRStatfssnapshot Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-SRStatfssnapshot

##########################################################################
######################### FUNCTION Get-SRStatlink ####################
##########################################################################
Function Get-SRStatlink()
{
<#
  .SYNOPSIS
   Get-SRStatlink - System reporter performance reports for links.

  .DESCRIPTION
   The Get-SRStatlink command displays historical performance data reports for
   links (internode, PCI and cache memory).

  .EXAMPLE

  .PARAMETER Attime
   Performance is shown at a particular time interval, specified by the
   etsecs option, with one row per object group described by the
   groupby option. Without this option performance is shown versus time,
   with a row per time interval.

  .PARAMETER Btsecs
	Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
	
  .PARAMETER Etsecs
	Select the end time in seconds for the report.  If -attime is specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.

  .PARAMETER Hires
   Select high resolution samples (5 minute intervals) for the report.
   This is the default.

  .PARAMETER Hourly
   Select hourly samples for the report.

  .PARAMETER Daily
   Select daily samples for the report.

  .PARAMETER Summary
   Summarize performance across requested objects and time range.
   One of these 4 summary keywords must be included:
	   min   Display the minimum for each metric
	   avg   Display the average for each metric
	   max   Display the maximum for each metric
	   <N>%  Display percentile for each metric. <N> may be any number
	   from 0 to 100. Multiple percentiles may be specified.
   Other keywords which modify the summary display or computation:
   detail
	   Display individual performance records in addition to one
	   or more summaries. By default, -summary output excludes
	   individual records and only displays the summary.
   per_time
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   time. By default, one summary is computed across all records.
   per_group
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   object grouping. By default, one summary is computed across all
	   records.
   only_compareby
	   When requesting data limited to certain object groupings with
	   the -compareby option, use this keyword to compute summaries
	   using only that reduced set of object groupings. By default,
	   summaries are computed from all records and ignore the
	   limitation of the -compareby option, though the "detail"
	   output does conform to the -compareby object limitation.

  .PARAMETER Groupby
   For -attime reports, generate a separate row for each combination of
   <groupby> items.  Each <groupby> must be different and
   one of the following:
   NODE      The source controller node for the link
   QUEUE     The XCB queue
   NODE_TO   The destination controller node for the link
   ASIC_FROM The source ASIC for the link
   ASIC_TO   The destination ASIC for the link

  .PARAMETER Compareby
   The compareby option limits output records to only certain objects,
   compared by a specified field.  Either the top or bottom X objects
   can be displayed, up to 32 objects for vstime reports or 128 objects
   for attime reports.  The field used for comparison can be any of the
   groupby fields or one of the following:
   xfers_ps, kbps, szkb

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
		Sort in increasing order (default).
	   dec
		Sort in decreasing order.
		
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.

  .PARAMETER Node
	Only the specified node numbers are included, where each node is a
	number from 0 through 7. This specifier can be repeated to display
	information for multiple nodes. If not specified, all nodes are
	included.
   
  .Notes
    NAME: Get-SRStatlink
    LASTEDIT : December 2019
    KEYWORDS: Get-SRStatlink
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Attime,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Btsecs,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Etsecs,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Hires,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Hourly,

	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$Daily,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$Summary,

	[Parameter(Position=7, Mandatory=$false)]
	[System.String]
	$Groupby,

	[Parameter(Position=8, Mandatory=$false)]
	[System.String]
	$Compareby,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$Sortcol,

	[Parameter(Position=10, Mandatory=$false)]
	[System.String]
	$Node,

	[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRStatlink - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRStatlink since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRStatlink since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srstatlink "

 if($Attime)
 {
	$Cmd += " -attime "
 }

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Hires)
 {
	$Cmd += " -hires "
 }

 if($Hourly)
 {
	$Cmd += " -hourly "
 }

 if($Daily)
 {
	$Cmd += " -daily "
 }

 if($Summary)
 {
	$Cmd += " -summary $Summary "
 }

 if($Groupby)
 {
	$Cmd += " -groupby $Groupby "
 }

 if($Compareby)
 {
	$Cmd += " -compareby $Compareby "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }

 if($Node)
 {
	$Cmd += " $Node "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRStatlink Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-SRStatlink

##########################################################################
######################### FUNCTION Get-SRStatqos #####################
##########################################################################
Function Get-SRStatqos()
{
<#
  .SYNOPSIS
   Get-SRStatqos - System reporter performance reports for QoS rules.

  .DESCRIPTION
   The Get-SRStatqos command displays historical performance data reports for
   QoS rules.

  .EXAMPLE

  .PARAMETER Attime
   Performance is shown at a particular time interval, specified by the
   etsecs option, with one row per object group described by the
   groupby option. Without this option performance is shown versus time,
   with a row per time interval.

  .PARAMETER Btsecs
	Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
   
  .PARAMETER Etsecs
	Select the end time in seconds for the report.  If -attime is specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.

  .PARAMETER Hires
   Select high resolution samples (5 minute intervals) for the report.
   This is the default.

  .PARAMETER Hourly
   Select hourly samples for the report.

  .PARAMETER Daily
   Select daily samples for the report.

  .PARAMETER Summary
   Summarize performance across requested objects and time range.
   One of these 4 summary keywords must be included:
	   min   Display the minimum for each metric
	   avg   Display the average for each metric
	   max   Display the maximum for each metric
	   <N>%  Display percentile for each metric. <N> may be any number
	   from 0 to 100. Multiple percentiles may be specified.
   Other keywords which modify the summary display or computation:
   detail
	   Display individual performance records in addition to one
	   or more summaries. By default, -summary output excludes
	   individual records and only displays the summary.
   per_time
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   time. By default, one summary is computed across all records.
   per_group
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   object grouping. By default, one summary is computed across all
	   records.
   only_compareby
	   When requesting data limited to certain object groupings with
	   the -compareby option, use this keyword to compute summaries
	   using only that reduced set of object groupings. By default,
	   summaries are computed from all records and ignore the
	   limitation of the -compareby option, though the "detail"
	   output does conform to the -compareby object limitation.

  .PARAMETER Vvset
   Limit the data to VVSets with names that match one or more of the
   specified names or glob-style patterns.
   This option is deprecated and will be removed in a subsequent release.

  .PARAMETER AllOthers
   Display statistics for all other I/O not regulated by a QoS rule.
   This option is deprecated and will be removed in a subsequent release.

  .PARAMETER Target
   Limit the data to the specified QoS target rule(s).
   Include a target type either {vvset|domain}, and a name or
   glob-style pattern.
   The sys:all_others rule can be selected to display
   statistics for all other host I/O not regulated by any "on" QoS rule.
   Multiple targets types can be specified as a comma separated list.

  .PARAMETER Groupby
   For -attime reports, generate a separate row for each combination of
   <groupby> items.  Each <groupby> must be different and
   one of the following:
   DOM_NAME        Domain name
   TARGET_TYPE     Type of QoS rule target, i.e. vvset
   TARGET_NAME     Name of QoS rule target
   IOPS_LIMIT      The I/O per second limit
   BW_LIMIT_KBPS   The KB per second bandwidth limit

  .PARAMETER Compareby
   The compareby option limits output records to only certain objects,
   compared by a specified field.  Either the top or bottom X objects
   can be displayed, up to 32 objects for vstime reports or 128 objects
   for attime reports.  The field used for comparison can be any of the
   groupby fields or one of the following:
   read_iops, write_iops, total_iops, read_kbps, write_kbps,
   total_kbps, read_svctms, write_svctms, total_svctms,
   read_ioszkb, write_ioszkb, total_ioszkb, total_qlen, busy_pct
   read_wait_ms, write_wait_ms, total_wait_ms, total_wqlen,
   total_io_rej, io_limit, bw_limit, priority, io_guarantee,
   bw_guarantee, latency_target_ms, latency_ms

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
		Sort in increasing order (default).
	   dec
		Sort in decreasing order.
		
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.

  .Notes
    NAME: Get-SRStatqos
    LASTEDIT : December 2019
    KEYWORDS: Get-SRStatqos
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Attime,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Btsecs,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Etsecs,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Hires,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Hourly,

	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$Daily,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$Summary,

	[Parameter(Position=7, Mandatory=$false)]
	[System.String]
	$Vvset,

	[Parameter(Position=8, Mandatory=$false)]
	[switch]
	$AllOthers,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$Target,

	[Parameter(Position=10, Mandatory=$false)]
	[System.String]
	$Groupby,

	[Parameter(Position=11, Mandatory=$false)]
	[System.String]
	$Compareby,

	[Parameter(Position=12, Mandatory=$false)]
	[System.String]
	$Sortcol,

	[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRStatqos - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRStatqos since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRStatqos since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srstatqos "

 if($Attime)
 {
	$Cmd += " -attime "
 }

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Hires)
 {
	$Cmd += " -hires "
 }

 if($Hourly)
 {
	$Cmd += " -hourly "
 }

 if($Daily)
 {
	$Cmd += " -daily "
 }

 if($Summary)
 {
	$Cmd += " -summary $Summary "
 }

 if($Vvset)
 {
	$Cmd += " -vvset $Vvset "
 }

 if($AllOthers)
 {
	$Cmd += " -all_others "
 }

 if($Target)
 {
	$Cmd += " -target $Target "
 }

 if($Groupby)
 {
	$Cmd += " -groupby $Groupby "
 }

 if($Compareby)
 {
	$Cmd += " -compareby $Compareby "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRStatqos Command -->" INFO:
 
 Return $Result
} ##  End-of Get-SRStatqos

##########################################################################
######################### FUNCTION Get-SRStatrcvv ####################
##########################################################################
Function Get-SRStatrcvv()
{
<#
  .SYNOPSIS
    Get-SRStatrcvv - System reporter performance reports for Remote Copy volumes.

  .DESCRIPTION
   The  Get-SRStatrcvv command displays historical performance data reports for
   Remote Copy volumes.

  .EXAMPLE

  .PARAMETER Attime
   Performance is shown at a particular time interval, specified by the
   etsecs option, with one row per object group described by the
   groupby option. Without this option performance is shown versus time,
   with a row per time interval.

  .PARAMETER Btsecs
	Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.

  .PARAMETER Etsecs
	Select the end time in seconds for the report.  If -attime is specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.

  .PARAMETER Hires
   Select high resolution samples (5 minute intervals) for the report.
   This is the default.

  .PARAMETER Hourly
   Select hourly samples for the report.

  .PARAMETER Daily
   Select daily samples for the report.

  .PARAMETER Summary
   Summarize performance across requested objects and time range.
   One of these 4 summary keywords must be included:
	   min   Display the minimum for each metric
	   avg   Display the average for each metric
	   max   Display the maximum for each metric
	   <N>%  Display percentile for each metric. <N> may be any number
	   from 0 to 100. Multiple percentiles may be specified.
   Other keywords which modify the summary display or computation:
   detail
	   Display individual performance records in addition to one
	   or more summaries. By default, -summary output excludes
	   individual records and only displays the summary.
   per_time
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   time. By default, one summary is computed across all records.
   per_group
	   When requesting data across multiple points in time (vstime)
	   and multiple object groupings (-groupby) compute summaries per
	   object grouping. By default, one summary is computed across all
	   records.
   only_compareby
	   When requesting data limited to certain object groupings with
	   the -compareby option, use this keyword to compute summaries
	   using only that reduced set of object groupings. By default,
	   summaries are computed from all records and ignore the
	   limitation of the -compareby option, though the "detail"
	   output does conform to the -compareby object limitation.

  .PARAMETER Groupby
   For -attime reports, generate a separate row for each combination of
   <groupby> items.  Each <groupby> must be different and
   one of the following:
   VV_NAME      The name of a volume admitted to a Remote Copy volume group with admitrcopyvv
   DOM_NAME     The domain name for a Remote Copy group when group was created with creatercopygroup
   TARGET_NAME  The target name of the Remote Copy target created with creatercopytarget
   TARGET_MODE  The target mode - Per: Periodic, Sync: Synchronous or Async: Asynchronous
   GROUP_NAME   The name of the Remote Copy group created with creatercopygroup
   GROUP_ROLE   The role (primary=1 or secondary=0) of the Remote Copy group
   PORT_TYPE    The port type (IP or FC) of the Remote Copy link(s) created with creatercopytarget
   PORT_N       The node number for the port used by a Remote Copy link
   PORT_S       The PCI slot number for the port used by a Remote Copy link
   PORT_P       The port number for the port used by a Remote Copy link
   VVSET_NAME   The virtual volume set name

  .PARAMETER Compareby
   The compareby option limits output records to only certain objects,
   compared by a specified field.  Either the top or bottom X objects
   can be displayed, up to 32 objects for vstime reports or 128 objects
   for attime reports.  The field used for comparison can be any of the
   groupby fields or one of the following:
   lcl_read_iops, lcl_write_iops, lcl_total_iops, lcl_read_kbps, lcl_write_kbps, lcl_total_kbps,
   lcl_read_svctms, lcl_write_svctms, lcl_total_svctms, lcl_read_ioszkb, lcl_write_ioszkb,
   lcl_total_ioszkb, lcl_busy_pct, lcl_total_qlen, rmt_read_iops, rmt_write_iops, rmt_total_iops,
   rmt_read_kbps, rmt_write_kbps, rmt_total_kbps, rmt_read_ioszkb, rmt_write_ioszkb,
   rmt_total_ioszkb, rmt_busy_pct, rmt_total_qlen, rpo_timeInt

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
		Sort in increasing order (default).
	   dec
		Sort in decreasing order.
		
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.

  .PARAMETER Vv
   Limit the data to VVs with names that match one or more of the
   specified names or glob-style patterns. VV set name must be prefixed
   by "set:" and can also include patterns.

  .PARAMETER Target
   Limit the data to TARGET_NAMEs that match one or more of the specified
   TARGET_NAMEs or glob-style patterns.

  .PARAMETER Mode
   Limit the data to TARGET_MODEs of the specified mode. Allowed modes are:
	   Per      - Periodic
	   Sync     - Synchronous
	   Async    - Asynchronous

  .PARAMETER Group
   Limit the data to GROUP_NAMEs that match one or more of the specified
   GROUP_NAMEs or glob-style patterns.

  .Notes
    NAME: Get-SRStatrcvv
    LASTEDIT : December 2019
    KEYWORDS: Get-SRStatrcvv
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Attime,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Btsecs,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Etsecs,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Hires,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Hourly,

	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$Daily,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$Summary,

	[Parameter(Position=7, Mandatory=$false)]
	[System.String]
	$Groupby,

	[Parameter(Position=8, Mandatory=$false)]
	[System.String]
	$Compareby,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$Sortcol,

	[Parameter(Position=10, Mandatory=$false)]
	[System.String]
	$Vv,

	[Parameter(Position=11, Mandatory=$false)]
	[System.String]
	$Target,

	[Parameter(Position=12, Mandatory=$false)]
	[System.String]
	$Mode,

	[Parameter(Position=13, Mandatory=$false)]
	[System.String]
	$Group,

	[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SRStatrcvv - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-CLIConnection $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-CLIConnection $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SRStatrcvv since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-SRStatrcvv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " srstatrcvv "

 if($Attime)
 {
	$Cmd += " -attime "
 }

 if($Btsecs)
 {
	$Cmd += " -btsecs $Btsecs "
 }

 if($Etsecs)
 {
	$Cmd += " -etsecs $Etsecs "
 }

 if($Hires)
 {
	$Cmd += " -hires "
 }

 if($Hourly)
 {
	$Cmd += " -hourly "
 }

 if($Daily)
 {
	$Cmd += " -daily "
 }

 if($Summary)
 {
	$Cmd += " -summary $Summary "
 }

 if($Groupby)
 {
	$Cmd += " -groupby $Groupby "
 }

 if($Compareby)
 {
	$Cmd += " -compareby $Compareby "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }

 if($Vv)
 {
	$Cmd += " -vv $Vv "
 }

 if($Target)
 {
	$Cmd += " -target $Target "
 }

 if($Mode)
 {
	$Cmd += " -mode $Mode "
 }

 if($Group)
 {
	$Cmd += " -group $Group "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-SRStatrcvv Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-SRStatrcvv

#############################################################################
######################### Function Get-SRStatVLun ###########################
#############################################################################
Function Get-SRStatVLun
{
<#
  .SYNOPSIS
    Command displays historical performance data reports for VLUNs.
  
  .DESCRIPTION
    Command displays historical performance data reports for VLUNs.
	
  .EXAMPLE
    Get-SRStatVLun
	Command displays historical performance data reports for VLUNs.
	
  .EXAMPLE
    Get-SRStatVLun -Hourly -btsecs -24h
	Example displays aggregate hourly performance statistics for all VLUNs beginning 24 hours ago:

  .EXAMPLE
    Get-SRStatVLun -btsecs -2h -host "set:hostset" -vv "set:vvset*"
	 VV or host sets can be specified with patterns:
	 
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
	
  .PARAMETER etsecs
    Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	
  .PARAMETER Hourly
	Select hourly samples for the report.
	
  .PARAMETER Daily   
	Select daily samples for the report.
		
  .PARAMETER Groupby
	 For -attime reports, generate a separate row for each combination of
	<groupby> items.  Each <groupby> must be different and
	one of the following:
	DOM_NAME        Domain name
	VV_NAME         Virtual Volume name
	HOST_NAME       Host name
	LUN             The LUN number for the VLUN
	HOST_WWN        The host WWN for the VLUN
	PORT_N          The node number for the VLUN  port
	PORT_S          The PCI slot number for the VLUN port
	PORT_P          The port number for the VLUN port
	VVSET_NAME      Virtual volume set name
	HOSTSET_NAME    Host set name
	VM_NAME         Virtual Machine Name for VVol based VMs
	VM_ID           Virtual Machine Identification number for VVol based VMs
	VM_HOST         Virtual Machine host for VVol based VMs
	VVOLSC          Virtual Volume Storage Container for VVol based VMs

   .PARAMETER host
	Limit the data to hosts with names that match one or more of the specified names or glob-style patterns. Host set name must start with
		
  .PARAMETER vv
	Limit the data to VVs with names that match one or more of thespecified names or glob-style patterns. VV set name must be prefixed by "set:" and can also include patterns.
   
  .PARAMETER lun
	Limit the data to LUNs that match one or more of the specified LUNs or glob-style patterns.
	
  .PARAMETER Port  
	Ports with <port_n>:<port_s>:<port_p> that match any of the specified <npat>:<spat>:<ppat> patterns are included, where each of the patterns is a glob-style pattern. If not specified, all ports are included.	
		
   .PARAMETER vLun
	Limit the data to VLUNs matching the specified combination of host, VV,
	lun, and port. Each of these components in this option may be a
	glob-style pattern. The host and VV components may specify a
	corresponding object set by prefixing "set:" to the component. The
	host component may specify a WWN by prefixing the component with
	"wwn:". The lun and port components are optional, and if not present,
	data will be filtered to any matching combination of host and VV.
	This option cannot be combined with -host, -vv, -l, or -port.

  .PARAMETER vmName 
	Limit the data to VMs that match one or more of the specified VM names
	or glob-styled patterns for VVol based VMs.

  .PARAMETER vmId 
	Limit the data to VMs that match one or more of the specified VM IDs
	or glob-styled patterns for VVol based VMs.

  .PARAMETER vmHost
	Limit the data to VMs that match one or more of the specified VM host
	names or glob-styled patterns for VVol based VMs.

  .PARAMETER vvoLsc
	Limit the data to VVol containers that match one or more of the
	specified VVol container names or glob-styled patterns.
	
  .PARAMETER Summary 
	Summarize performance across requested objects and time range.

		
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRStatVLun
    LASTEDIT: December 2019
    KEYWORDS: Get-SRStatVLun
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Summary,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hires ,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$host,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vv,
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$lun,
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$port,
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vLun,
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vmName,
		[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vmHost,
		[Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vvoLsc,
		[Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vmId,
		[Parameter(Position=17, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Get-SRStatVLun - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRStatVLun since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRStatVLun since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
    $tempFile = [IO.Path]::GetTempFileName()	
	$srinfocmd = "srstatvlun "
	$3parosver = Get-Version -S  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		
		if($Summary)
		{
			$srinfocmd += " -summary $Summary"
		}
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}				
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		if($groupby)
		{
			$commarr = "DOM_NAME","VV_NAME","HOST_NAME","LUN","HOST_WWN","PORT_N","PORT_S","PORT_P","VVSET_NAME","HOSTSET_NAME"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{
					$srinfocmd += " -groupby $groupby"
				}
				else
				{
					del $tempFile
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}			
		}
		if($host)
		{
			$srinfocmd += " -host $host"			
		}
		if($vv)
		{
			$srinfocmd += " -vv $vv "
		}
		if($lun)
		{
			$srinfocmd += " -l $lun "
		}
		if($port)
		{
			$srinfocmd += " -port $port "
		}
		if($vLun)
		{
			$srinfocmd += " -vlun $vLun "
		}	
        if($vmName)
		{
			$srinfocmd += " -vmname $vmName "
		}
		if($vmId)
		{
			$srinfocmd += " -vmid $vmId "
		}		
		if($vmHost)
		{
			$srinfocmd += " -vmhost $vmHost "
		}
		if($vvoLsc)
		{
			$srinfocmd += " -vvolsc $vvoLsc "
		}
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "HOST_NAME"
			}
			Add-Content -Path $tempFile -Value "Host_Name,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
			$rangestart = "4"
		}
		elseif($groupby)
		{
			$optionname = $groupby.toUpper()
			$rangestart = "2"	
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,$optionname,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
		}
		elseif($Summary)
		{	
			$rangestart = "4"	
			Add-Content -Path $tempFile -Value "Summary,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
		}
		else
		{
			$rangestart = "3"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		$range1  = $Result.count -3	
		if($Summary){ $range1 = 4 }
		if($range1 -le "2")
		{ 
			del $tempFile 
			return "No data available" 
		}	
		if($Result.count -gt 4)
		{	
			foreach ($s in  $Result[$rangestart..$range1] )
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				#write-host "s $s"
				Add-Content -Path $tempFile -Value $s
			}
			Import-Csv $tempFile	
			del $tempFile
		}
		else
		{
			del $tempFile
			return $Result
		}
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRStatVLun

#### Start Get-SRVvSpace ####
Function Get-SRVvSpace
{
<#
  .SYNOPSIS
    Command displays historical space data reports for virtual volumes (VVs).
  
  .DESCRIPTION
    Command displays historical space data reports for virtual volumes (VVs).
	
  .EXAMPLE
    Get-SRVvSpace 
	Command displays historical space data reports for virtual volumes (VVs).
	
  .EXAMPLE
    Get-SRVvSpace  -Hourly -btsecs -24h -VVName dbvv*
	example displays aggregate hourly VV space information for VVs with names matching either "dbvv*"  patterns beginning 24 hours ago:
	
  .EXAMPLE
    Get-SRVvSpace -Daily -attime -groupby vv_name -vvName tp*
	Example displays VV space information for the most recent daily sample aggregated by the VV name for VVs with names that match the pattern "tp*".
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	
	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
	
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):        
		- For hires, the default begin time is 12 hours ago (-btsecs -12h).
		- For hourly, the default begin time is 7 days ago (-btsecs -7d).
		- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.
	
  .PARAMETER etsecs
    Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent sample.
 
  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report. This is the default setting.
		
  .PARAMETER Hourly
	Select hourly samples for the report.
		
  .PARAMETER Daily   
	Select daily samples for the report.
		
  .PARAMETER Groupby
	For -attime reports, generate a separate row for each combination of
	<groupby> items.  Each <groupby> must be different and
	one of the following:
	DOM_NAME        Domain name
	VVID            Virtual volume ID
	VV_NAME         Virtual volume name
	BSID            Virtual volume ID of the base virtual volume
	WWN             Virtual volume world wide name (WWN)
	SNP_CPG_NAME    Snap space Common Provisioning Group name
	USR_CPG_NAME    User space Common Provisioning Group name
	PROV_TYPE       The virtual volume provisioning type
	VV_TYPE         The type of the virtual volume
	VVSET_NAME      Virtual volume set name
	VM_NAME         Virtual Machine name for VVol based VMs
	VM_ID           Virtual Machine Identification number for VVol based VMs
	VM_HOST         Virtual Machine host for VVol based VMs
	VVOLSC          Virtual Volume Storage Container for VVol based VMs
	VVOL_STATE      Virtual Volume state, either bound or unbound
	COMPR           Whether Compression is enabled, disabled, or NA

  .PARAMETER usrcpg 
   Only include VVs whose usr space is mapped to a CPG whose name matches one of the specified CPG_name or glob-style patterns.

  .PARAMETER snpcpg
   Only include VVs whose snp space is mapped to a CPG whose name matches one of the specified CPG_name or glob-style patterns.


  .PARAMETER provType
   Only include VVs of the specified provisioning type(s).
   The possible values are: cpvv dds full peer snp tdvv tpsd tpvv
	
  .PARAMETER VVName
	PDs with IDs that match either the specified PDID or glob-style  pattern are included. This specifier can be repeated to include multiple PDIDs or patterns. If not specified, all PDs are included.

  .PARAMETER vmName 
	Limit the data to VMs that match one or more of the specified VM names
	or glob-styled patterns for VVol based VMs.

  .PARAMETER vmId 
	Limit the data to VMs that match one or more of the specified VM IDs
	or glob-styled patterns for VVol based VMs.

  .PARAMETER vmHost 
	Limit the data to VMs that match one or more of the specified VM host
	names or glob-styled patterns for VVol based VMs.

  .PARAMETER vvolState
	Limit the data to VVOLs that have states in either the Bound or
	Unbound state.

  .PARAMETER vvoLsc
	Limit the data to VVol containers that match one or more of the
	specified VVol container names or glob-styled patterns.
		
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SRVvSpace
    LASTEDIT: December 2019
    KEYWORDS: Get-SRVvSpace
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Hourly ,		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $Daily ,		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
       	$Hires ,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$usrcpg,		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$snpcpg,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$provType,
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$VVName,
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vmName,
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vmHost,
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vvoLsc,
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vmId,
		[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vvolState,
		[Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Get-SRVvSpace - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-SRVvSpace since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SRVvSpace since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "srvvspace"
	
	$3parosver = Get-Version -S  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		$tempFile = [IO.Path]::GetTempFileName()
		
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($Hourly)
		{
			$srinfocmd += " -hourly"			
		}
		
		if($Daily)
		{
			$srinfocmd += " -daily"			
		}
		
		if($Hires)
		{
			$srinfocmd += " -hires"			
		}
		if($groupby)
		{
			$commarr = "DOM_NAME","VVID","VV_NAME","BSID","WWN","SNP_CPG_NAME","USR_CPG_NAME","PROV_TYPE","VV_TYPE","VVSET_NAME"
			$lista = $groupby.split(",")
			foreach($suba in $lista){
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					del $tempFile
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		
		if($usrcpg)
		{
			$srinfocmd +=  " -usr_cpg $usrcpg "
		}
		if($snpcpg)
		{
			$srinfocmd +=  " -snp_cpg $snpcpg "
		}
		if($provType)
		{
			$provrray = "cpvv","dds","full","peer","snp","tdvv","tpsd","tpvv"
			if($provrray -eq $provType){
				$srinfocmd += " -prov $provType"
			}
			else
			{
				del $tempFile
				return "FAILURE: Invalid provType it should be in ( $provrray )"
			}			
		}
		if($VVName)
		{
			$srinfocmd += " $VVName "
		}		
        if($vmName)
		{
			$srinfocmd += " -vmname $vmName "
		}
		if($vmId)
		{
			$srinfocmd += " -vmid $vmId "
		}		
		if($vmHost)
		{
			$srinfocmd += " -vmhost $vmHost "
		}
		if($vvoLsc)
		{
			$srinfocmd += " -vvolsc $vvoLsc "
		}
		if($vvolState)
		{
			$srinfocmd += " -vvolstate $vvolState "
		}
		if($attime)
		{		
			$srinfocmd += " -attime "	
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "VV_NAME"
			}
			$rangestart = "3"
			#Add-Content -Path $tempFile -Value "$optionname,RawRsvd(MB)_User,RawRsvd(MB)_Snap,RawRsvd(MB)_Admin,RawRsvd(MB)_Total,User(MB)_Used,User(MB)_Free,User(MB)_Rsvd,Snap(MB)_Used,Snap(MB)_Free,Snap(MB)_Rsvd,Snap(MB)_Vcopy,Admin(MB)_Used,Admin(MB)_Free,Admin(MB)_Rsvd,Admin(MB)_Vcopy,Total(MB)_VcopyTotal(MB)_Used,Total(MB)_Rsvd,Total(MB)_VirtualSize,CapacityEfficiency_Compaction,CapacityEfficiency_Dedup"
			Add-Content -Path $tempFile -Value "$optionname,RawRsvd(MB)_User,RawRsvd(MB)_Snap,RawRsvd(MB)_Total,User(MB)_Used,User(MB)_Free,User(MB)_Rsvd,Snap(MB)_Used,Snap(MB)_Free,Snap(MB)_Rsvd,Snap(MB)_Vcopy,Total(MB)_Vcopy,Total(MB)_Used,Total(MB)_Rsvd,Total(MB)_HostWr,Total(MB)_VirtualSize,KB/s)_Compr_GC,Efficiency_Compact,Efficiency_Compress"
		}
		elseif($groupby)
		{
			$optionname = $groupby.toUpper()
			$rangestart = "2"			
			#Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,$optionname,RawRsvd(MB)_User,RawRsvd(MB)_Snap,RawRsvd(MB)_Total,User(MB)_Used,User(MB)_Free,User(MB)_Rsvd,Snap(MB)_Used,Snap(MB)_Free,Snap(MB)_Rsvd,Snap(MB)_Vcopy,Admin(MB)_Used,Admin(MB)_Free,Admin(MB)_Rsvd,Admin(MB)_Vcopy,Total(MB)_VcopyTotal(MB)_Used,Total(MB)_Rsvd,Total(MB)_VirtualSize,CapacityEfficiency_Compaction,CapacityEfficiency_Dedup"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,$optionname,RawRsvd(MB)_User,RawRsvd(MB)_Snap,RawRsvd(MB)_Total,User(MB)_Used,User(MB)_Free,User(MB)_Rsvd,Snap(MB)_Used,Snap(MB)_Free,Snap(MB)_Rsvd,Snap(MB)_Vcopy,Total(MB)_Vcopy,Total(MB)_Used,Total(MB)_Rsvd,Total(MB)_HostWr,Total(MB)_VirtualSize,KB/s)_Compr_GC,Efficiency_Compact,Efficiency_Compress"
		}
		else
		{
			$rangestart = "2"
			#Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,RawRsvd(MB)_User,RawRsvd(MB)_Snap,RawRsvd(MB)_Total,User(MB)_Used,User(MB)_Free,User(MB)_Rsvd,Snap(MB)_Used,Snap(MB)_Free,Snap(MB)_Rsvd,Snap(MB)_Vcopy,Admin(MB)_Used,Admin(MB)_Free,Admin(MB)_Rsvd,Admin(MB)_Vcopy,Total(MB)_VcopyTotal(MB)_Used,Total(MB)_Rsvd,Total(MB)_VirtualSize,CapacityEfficiency_Compaction,CapacityEfficiency_Dedup"
			Add-Content -Path $tempFile -Value "Date,Time,TimeZone,Secs,RawRsvd(MB)_User,RawRsvd(MB)_Snap,RawRsvd(MB)_Total,User(MB)_Used,User(MB)_Free,User(MB)_Rsvd,Snap(MB)_Used,Snap(MB)_Free,Snap(MB)_Rsvd,Snap(MB)_Vcopy,Total(MB)_Vcopy,Total(MB)_Used,Total(MB)_Rsvd,Total(MB)_HostWr,Total(MB)_VirtualSize,(KB/s)_Compr_GC,Efficiency_Compact,Efficiency_Compress"
		}
		
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			del $tempFile
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		#write-host "count = $range1"		
		if($range1 -le "3")
		{
			del $tempFile
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
## End Get-SRVvSpace

####################################################################################################################
## FUNCTION Show-SrStatIscsi
####################################################################################################################
Function Show-SrStatIscsi
{
<#
  .SYNOPSIS   
	The Show-SrStatIscsi command displays historical performance data reports for
	iSCSI ports.

  .DESCRIPTION  
	The Show-SrStatIscsi command displays historical performance data reports for
    iSCSI ports.

  .EXAMPLE	
	Show-SrStatIscsi
	
  .EXAMPLE
	Show-SrStatIscsi  -Attime

  .EXAMPLE
	Show-SrStatIscsi  -Summary min          /max/aug/detail

  .EXAMPLE
	Show-SrStatIscsi  -BTSecs 1

  .EXAMPLE
	Show-SrStatIscsi  -ETSecs 1

  .EXAMPLE
	Show-SrStatIscsi  -Groupby PORT_N

	.PARAMETER Attime
        Performance is shown at a particular time interval, specified by the
        -etsecs option, with one row per object group described by the
        -groupby option. Without this option performance is shown versus time,
        with a row per time interval.

	.PARAMETER BTsecs
        Select the begin time in seconds for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - The absolute time as a text string in one of the following formats:
            - Full time string including time zone: "2012-10-26 11:00:00 PDT"
            - Full time string excluding time zone: "2012-10-26 11:00:00"
            - Date string: "2012-10-26" or 2012-10-26
            - Time string: "11:00:00" or 11:00:00
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):
            - For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.

	.PARAMETER ETsecs
        Select the end time in seconds for the report.  If -attime is
        specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - The absolute time as a text string in one of the following formats:
            - Full time string including time zone: "2012-10-26 11:00:00 PDT"
            - Full time string excluding time zone: "2012-10-26 11:00:00"
            - Date string: "2012-10-26" or 2012-10-26
            - Time string: "11:00:00" or 11:00:00
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent
        sample.

	.PARAMETER Hires
        Select high resolution samples (5 minute intervals) for the report.
        This is the default.

	.PARAMETER Hourly
        Select hourly samples for the report.

	.PARAMETER Daily
        Select daily samples for the report.

	.PARAMETER Summary 
        Summarize performance across requested objects and time range.
        The possible summary types are:
            "min" (minimum), "avg" (average), "max" (maximum), and "detail"
        The "detail" type causes the individual performance records to be
        presented along with the summary type(s) requested. One or more of these
        summary types may be specified.

	.PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of
        <groupby> items.  Each <groupby> must be different and
        one of the following:
        PORT_N      The node number for the port
        PORT_S      The PCI slot number for the port
        PORT_P      The port number for the port
        PROTOCOL    The protocol type for the port
		
	.PARAMETER NSP
		Dode Sloat Port Value 1:2:3
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
	.Notes
		NAME: Show-SrStatIscsi
		LASTEDIT: January 2020
		KEYWORDS: Show-SrStatIscsi
   
	.Link
		http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$Attime, 
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$Hires,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Hourly,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Daily,
				
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Summary ,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$BTSecs ,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$ETSecs ,
		
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$Groupby ,
		
		[Parameter(Position=8, Mandatory=$false)]
		[System.String]
		$NSP ,		
			
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Show-SrStatIscsi   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Show-SrStatIscsi since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Show-SrStatIscsi since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "srstatiscsi "
	
	if ($Attime)
	{
		$cmd+=" -attime "
	}
	if ($Summary)
	{
		$a = "min","avg","max","detail"
		$l=$Summary
		if($a -eq $l)
		{
			$cmd+=" -summary $Summary "
		}
		else
		{
			return "Summary : $Summary is incorrect value please use [ min | avg | max | detail] only."
		}
		
	}
	if ($BTSecs)
	{
		$cmd+=" -btsecs $BTSecs "
	}
	if ($ETSecs)
	{
		$cmd+=" -etsecs $ETSecs "
	}
	if ($Hires)
	{
		$cmd+=" -hires "
	}
	if ($Hourly)
	{
		$cmd+=" -hourly "
	}
	if ($Daily)
	{
		$cmd+=" -daily "
	}	
	
	if($Groupby)
	{
		$gbVal="PORT_N","PORT_S","PORT_P","PROTOCOL"
		$gbl=$Groupby
		if($gbVal -eq $gbl)
		{
			$cmd+=" -groupby $Groupby"
		}
		else
		{
			Return "FAILURE : Invalid -Group-by option: $Groupby cannot be used only [PORT_N | PORT_S | PORT_P | PROTOCOL] "
		}				
	}	
		
	if ($NSP)
	{
		$cmd+=" $NSP "
	}
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing  Show-SrStatIscsi command that displays information iSNS table for iSCSI ports in the system  " "INFO:"
	
	$Flag="True"
	if($Attime -or $Summary)
	{
		$Flag="Fals"
		if($Result -match "Time")
		{
			if($Result.Count -lt 5)
			{
				return "No data found please try with different values."
			}
			$count=2
			if($Summary)
			{
				$count=3
			}
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count
			$incre = "true" 		
			foreach ($s in  $Result[$count..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim()			
				if($incre -eq "true")
				{		
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')							
					$sTemp[1]="Pkts/s(Receive)"				
					$sTemp[2]="KBytes/s(Receive)"
					$sTemp[3]="Pkts/s(Transmit)"				
					$sTemp[4]="Kytes/s(Transmit)"
					$sTemp[5]="Pkts/s(Total)"				
					$sTemp[6]="Kytes/s(Total)"
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
				if($incre -eq "false")
				{
					$s=$s.Substring(1)
				}			
				Add-Content -Path $tempFile -Value $s	
				$incre="false"
			}			
			Import-Csv $tempFile 
			del $tempFile
		}
		else
		{
			return $Result
		}
	}	
	else
	{	
		if($Flag -eq "True")
		{
			if($Result -match "Time")
			{
				if($Result.Count -lt 4)
				{
					return "No data found please try with different values."
				}
				$tempFile = [IO.Path]::GetTempFileName()
				$LastItem = $Result.Count
				$incre = "true" 		
				foreach ($s in  $Result[1..$LastItem] )
				{			
					$s= [regex]::Replace($s,"^ ","")						
					$s= [regex]::Replace($s," +",",")			
					$s= [regex]::Replace($s,"-","")			
					$s= $s.Trim() -replace 'Time','Date,Time,Zone' 						
					if($incre -eq "true")
					{
						$s=$s.Substring(1)
						$sTemp1=$s				
						$sTemp = $sTemp1.Split(',')							
						$sTemp[4]="Pkts/s(Receive)"				
						$sTemp[5]="KBytes/s(Receive)"
						$sTemp[6]="Pkts/s(Transmit)"				
						$sTemp[7]="Kytes/s(Transmit)"
						$sTemp[8]="Pkts/s(Total)"				
						$sTemp[9]="Kytes/s(Total)"
						$newTemp= [regex]::Replace($sTemp,"^ ","")			
						$newTemp= [regex]::Replace($sTemp," ",",")				
						$newTemp= $newTemp.Trim()
						$s=$newTemp
					}				
					Add-Content -Path $tempFile -Value $s	
					$incre="false"
				}			
				Import-Csv $tempFile 
				del $tempFile
			}
			else
			{
				return $Result
			}
		}
	}	
	if($Result -match "Time")
	{
		return  " Success : Executing Show-SrStatIscsi"
	}
	else
	{			
		return  $Result
	}
	
} # End Show-SrStatIscsi

####################################################################################################################
## FUNCTION Show-SrStatIscsiSession
####################################################################################################################
Function Show-SrStatIscsiSession
{
<#
  .SYNOPSIS   
	The Show-SrStatIscsiSession command displays historical performance data reports for
	iSCSI sessions.

  .DESCRIPTION  
	The Show-SrStatIscsiSession command displays historical performance data reports for
	iSCSI sessions.

  .EXAMPLE	
	Show-SrStatIscsiSession

  .EXAMPLE
	Show-SrStatIscsiSession -Attime

  .EXAMPLE
	Show-SrStatIscsiSession -Attime -NSP 0:2:1

  .EXAMPLE
	Show-SrStatIscsiSession -Summary min -NSP 0:2:1

  .EXAMPLE
	Show-SrStatIscsiSession -Btsecs 1 -NSP 0:2:1

  .EXAMPLE
	Show-SrStatIscsiSession -Hourly -NSP 0:2:1

  .EXAMPLE
	Show-SrStatIscsiSession -Daily

  .EXAMPLE
	Show-SrStatIscsiSession -Groupby PORT_N

  .PARAMETER Attime
	Performance is shown at a particular time interval, specified by the
	-etsecs option, with one row per object group described by the
	-groupby option. Without this option performance is shown versus time,
	with a row per time interval.

  .PARAMETER Btsecs
	Select the begin time in seconds for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
	- Full time string including time zone: "2012-10-26 11:00:00 PDT"
	- Full time string excluding time zone: "2012-10-26 11:00:00"
	- Date string: "2012-10-26" or 2012-10-26
	- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	current time. Instead of a number representing seconds, <secs> can
	be specified with a suffix of m, h or d to represent time in minutes
	(e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the time at which the report begins depends
	on the sample category (-hires, -hourly, -daily):
	- For hires, the default begin time is 12 hours ago (-btsecs -12h).
	- For hourly, the default begin time is 7 days ago (-btsecs -7d).
	- For daily, the default begin time is 90 days ago (-btsecs -90d).
	If begin time and sample category are not specified then the time
	the report begins is 12 hours ago and the default sample category is hires.
	If -btsecs 0 is specified then the report begins at the earliest sample.

  .PARAMETER Etsecs
	Select the end time in seconds for the report.  If -attime is
	specified, select the time for the report.
	The value can be specified as either
	- The absolute epoch time (for example 1351263600).
	- The absolute time as a text string in one of the following formats:
		- Full time string including time zone: "2012-10-26 11:00:00 PDT"
		- Full time string excluding time zone: "2012-10-26 11:00:00"
		- Date string: "2012-10-26" or 2012-10-26
		- Time string: "11:00:00" or 11:00:00
	- A negative number indicating the number of seconds before the
	  current time. Instead of a number representing seconds, <secs> can
	  be specified with a suffix of m, h or d to represent time in minutes
	  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
	If it is not specified then the report ends with the most recent
	sample.

  .PARAMETER Hires
	Select high resolution samples (5 minute intervals) for the report.
	This is the default.

  .PARAMETER Hourly
	Select hourly samples for the report.

  .PARAMETER Daily
	Select daily samples for the report.

  .PARAMETER Summary
	Summarize performance across requested objects and time range.
	The possible summary types are:
		"min" (minimum), "avg" (average), "max" (maximum), and "detail"
	The "detail" type causes the individual performance records to be
	presented along with the summary type(s) requested. One or more of these
	summary types may be specified.

  .PARAMETER Groupby
	For -attime reports, generate a separate row for each combination of
	<groupby> items.  Each <groupby> must be different and
	one of the following:
	PORT_N      The node number for the session
	PORT_S      The PCI slot number for the session
	PORT_P      The port number for the session
	ISCSI_NAME  The iSCSI name for the session
	TPGT        The TPGT ID for the session

  .PARAMETER NSP
	Node Sloat Poart Value 1:2:3

  .PARAMETER SANConnection 
	Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection

  .Notes
	NAME: Show-SrStatIscsiSession
	LASTEDIT: January 2020
	KEYWORDS: Show-SrStatIscsiSession

  .Link
	http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$Attime, 
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$Hires,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Hourly,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Daily,
				
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Summary ,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$BTSecs ,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$ETSecs ,
		
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$Groupby ,
		
		[Parameter(Position=8, Mandatory=$false)]
		[System.String]
		$NSP ,		
			
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)		
	Write-DebugLog "Start: In Show-SrStatIscsiSession   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Show-SrStatIscsiSession since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Show-SrStatIscsiSession since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "srstatiscsisession "	
	
	if ($Attime)
	{
		$cmd+=" -attime "
	}
	if ($Summary)
	{
		$a = "min","avg","max","detail"
		$l=$Summary
		if($a -eq $l)
		{
			$cmd+=" -summary $Summary "
		}
		else
		{
			return "Summary : $Summary is incorrect value please use [ min | avg | max | detail] only."
		}
		
	}
	if ($BTSecs)
	{
		$cmd+=" -btsecs $BTSecs "
	}
	if ($ETSecs)
	{
		$cmd+=" -etsecs $ETSecs "
	}
	if ($Hires)
	{
		$cmd+=" -hires "
	}
	if ($Hourly)
	{
		$cmd+=" -hourly "
	}
	if ($Daily)
	{
		$cmd+=" -daily "
	}	
	
	if($Groupby)
	{
		$gbVal="PORT_N","PORT_S","PORT_P","ISCSI_NAME","TPGT"
		$gbl=$Groupby
		if($gbVal -eq $gbl)
		{
			$cmd+=" -groupby $Groupby"
		}
		else
		{
			Return "FAILURE : Invalid -Group-by option: $Groupby cannot be used only [PORT_N | PORT_S | PORT_P | ISCSI_NAME | TPGT] "
		}				
	}
	
	if ($NSP)
	{
		$cmd+=" $NSP "
	}
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing  Show-SrStatIscsiSession command that displays information iSNS table for iSCSI ports in the system  " "INFO:"
	if($Attime)
	{
		if($Result -match "Time")
		{
			if($Result.Count -lt 5)
			{
				return "No data found please try with different values."
			}
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count
			$incre = "true" 		
			foreach ($s in  $Result[2..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim()			
				if($incre -eq "true")
				{		
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')					
					$sTemp[3]="Total(PDUs/s)"				
					$sTemp[6]="Total(KBytes/s)"
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
				if($incre -eq "false")
				{
					$s=$s.Substring(1)
				}			
				Add-Content -Path $tempFile -Value $s	
				$incre="false"
			}			
			Import-Csv $tempFile 
			del $tempFile
		}
		else
		{
			return $Result
		}
	}
	elseif($Summary)
	{
		if($Result -match "Time")
		{
			if($Result.Count -lt 5)
			{
				return "No data found please try with different values."
			}
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count
			$incre = "true" 		
			foreach ($s in  $Result[3..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim()			
				if($incre -eq "true")
				{		
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')					
					$sTemp[3]="Total(PDUs/s)"				
					$sTemp[6]="Total(KBytes/s)"
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
				if($incre -eq "false")
				{
					$s=$s.Substring(1)
				}			
				Add-Content -Path $tempFile -Value $s	
				$incre="false"
			}			
			Import-Csv $tempFile 
			del $tempFile
		}
		else
		{
			return $Result
		}
	}
	elseif($Groupby)
	{		
		if($Result -match "Time")
		{	
			if($Result.Count -lt 5)
			{
				return "No data found please try with different values."
			}
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count
			$incre = "true" 		
			foreach ($s in  $Result[1..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim() -replace 'Time','Date,Time,Zone'				
				if($incre -eq "true")
				{
					$sTemp1=$s.Substring(1)					
					$sTemp2=$sTemp1.Substring(0,$sTemp1.Length - 17)
					$sTemp2 +="TimeOut"					
					$sTemp = $sTemp2.Split(',')					
					$sTemp[7]="Total(PDUs/s)"				
					$sTemp[10]="Total(KBytes/s)"
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}							
				Add-Content -Path $tempFile -Value $s	
				$incre="false"
			}			
			Import-Csv $tempFile 
			del $tempFile
		}
		else
		{
			return $Result
		}
	}
	else
	{
		if($Result -match "Time")
		{
			if($Result.Count -lt 5)
			{
				return "No data found please try with different values."
			}
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count
			$incre = "true" 		
			foreach ($s in  $Result[1..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim()					
				if($incre -eq "true")
				{
					$s=$s.Substring(1)								
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')							
					$sTemp[4]="Total(PDUs/s)"				
					$sTemp[7]="Total(KBytes/s)"
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
				if($incre -eq "false")
				{
					$sTemp1=$s
					$sTemp = $sTemp1.Split(',')	
					$sTemp2=$sTemp[0]+"-"+$sTemp[1]+"-"+$sTemp[2]
					$sTemp[0]=$sTemp2				
					$sTemp[1]=$sTemp[3]
					$sTemp[2]=$sTemp[4]
					$sTemp[3]=$sTemp[5]
					$sTemp[4]=$sTemp[6]
					$sTemp[5]=$sTemp[7]
					$sTemp[6]=$sTemp[8]
					$sTemp[7]=$sTemp[9]
					$sTemp[8]=$sTemp[10]
					$sTemp[9]=$sTemp[11]
					$sTemp[10]=""
					$sTemp[11]=""				
					$newTemp= [regex]::Replace($sTemp," ",",")	
					$newTemp= $newTemp.Trim()
					$s=$newTemp				
				}
				Add-Content -Path $tempFile -Value $s	
				$incre="false"
			}			
			Import-Csv $tempFile 
			del $tempFile
		}
		else
		{
			return $Result
		}
	}	
	if($Result -match "Time")
	{
		return  " Success : Executing Show-SrStatIscsiSession"
	}
	else
	{			
		return  $Result
	}
	
} # End Show-SrStatIscsiSession

Export-ModuleMember Get-SRAlertCrit , Get-SRAOMoves , Get-SRCpgSpace , Get-SRHistLd , Get-SRHistPD , Get-SRHistPort , Get-SRHistVLun ,
Get-SRLDSpace , Get-SRPDSpace , Get-SRrgiodensity , Get-SRStatCache , Get-SRStatCMP , Get-SRStatCPU , Get-SRStatfsav , Get-SRStatfsblock ,
Get-SRStatfscpu , Get-SRStatfsfpg , Get-SRStatfsmem , Get-SRStatfsnet , Get-SRStatfsnfs , Set-SRAlertCrit , Remove-SRAlertCrit , New-SRAlertCrit ,
Get-SRStatPort , Get-SRStatPD , Get-SRStatfssmb , Get-SRStatLD , Get-SRStatfssnapshot , Get-SRStatlink , Get-SRStatqos , Get-SRStatrcvv , 
Get-SRStatVLun , Get-SRVvSpace , Show-SrStatIscsi , Show-SrStatIscsiSession