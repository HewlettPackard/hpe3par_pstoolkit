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
##	File Name:		PerformanceManagement.psm1
##	Description: 	Performance Management cmdlets 
##		
##	Created:		October 2019
##	Last Modified:	October 2019
##	History:		v3.0 - Created	
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

######################################################################################################################
## FUNCTION Compress-VV
######################################################################################################################
Function Compress-VV
{
<#
  .SYNOPSIS   
	The Compress-VV command is used to change the properties of a virtual volume that
	was created with the createvv command by associating it with a different CPG.
	
  .DESCRIPTION  
	The Compress-VV command is used to change the properties of a virtual volume that
    was created with the createvv command by associating it with a different CPG.
	
  .EXAMPLE	
	Compress-VV -SUBCommand usr_cpg -CPGName XYZ
		
  .EXAMPLE
	Compress-VV -SUBCommand usr_cpg -CPGName XYZ -VVName XYZ
	
  .EXAMPLE
	Compress-VV -SUBCommand usr_cpg -CPGName XYZ -Option XYZ -VVName XYZ
	
  .EXAMPLE
	Compress-VV -SUBCommand usr_cpg -CPGName XYZ -Option keepvv -KeepVVName XYZ -VVName XYZ
		
  .EXAMPLE
	Compress-VV -SUBCommand snp_cpg -CPGName XYZ -VVName XYZ
	
  .PARAMETER SUBCommand
	usr_cpg <cpg>
		Moves the logical disks being used for user space to the specified CPG.
		
	snp_cpg <cpg>
		Moves the logical disks being used for snapshot space to the specified
		CPG.
		
	restart
		Restarts a tunevv command call that was previously interrupted because
		of component failure, or because of user initiated cancellation. This
		cannot be used on TPVVs or TDVVs.
		
	rollback
		Returns to a previously issued tunevv operation call that was
		interrupted. The canceltask command needs to run before the rollback.
		This cannot be used on TPVVs or TDVVs.
	
  .PARAMETER CPGName
	Indicates that only regions of the VV which are part of the the specified
	CPG should be tuned to the destination USR or SNP CPG.
	
  .PARAMETER VVName
	 Specifies the name of the existing virtual volume.

  .PARAMETER WaitTask
	Specifies that the command will wait for any created tasks to
	complete.

  .PARAMETER DryRun
	Specifies that the command is a dry run and that no logical disks or
	virtual volumes are actually tuned.  Cannot be used with the -tpvv,
	-dedup, -full, or -compr options.

  .PARAMETER Count
	Specifies the number of identical virtual volumes to tune using an
	integer from 1 through 999. If not specified, one virtual volume
	is tuned. If the '-cnt' option is specified, then the subcommands,
	"restart" and "rollback" are not permitted.

  .PARAMETER TPVV
	Indicates that the VV should be converted to a thin provision virtual
	volume.  Cannot be used with the -dedup or -full options.

  .PARAMETER TDVV
	This option is deprecated, see -dedup.

  .PARAMETER DeDup
	Indicates that the VV should be converted to a thin provision virtual
	volume that shares logical disk space with other instances of this
	volume type.  Cannot be used with the -tpvv or -full options.

  .PARAMETER Full
	Indicates that the VV should be converted to a fully provisioned virtual
	volume.  Cannot be used with the -tpvv, -dedup, or -compr options.

  .PARAMETER Compr
	Indicates that the VV should be converted to a compressed virtual
	volume.  Cannot be used with the -full option.

  .PARAMETER KeepVV
	Indicates that the original logical disks should be saved under a new
	virtual volume with the given name.  Can only be used with the -tpvv,
	-dedup, -full, or -compr options.

  .PARAMETER Src_Cpg 
	Indicates that only regions of the VV which are part of the the specified
	CPG should be tuned to the destination USR or SNP CPG. This option is
	recommended when a VV belongs to an AO configuration and will avoid
	disrupting any optimizations already performed.

  .PARAMETER Threshold 
	Slice threshold. Volumes above this size will be tuned in slices.
	<threshold> must be in multiples of 128GiB. Minimum is 128GiB.
	Default is 16TiB. Maximum is 16TiB.

  .PARAMETER SliceSize
	Slice size. Size of slice to use when volume size is greater than
	<threshold>. <size> must be in multiples of 128GiB. Minimum is 128GiB.
	 Default is 2TiB. Maximum is 16TiB.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
	NAME: Compress-VV
	LASTEDIT: November 2019
	KEYWORDS: Compress-VV
   
	.Link
		http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(	
		[Parameter(Position=0, Mandatory=$true)]
		[System.String]
		$SUBCommand ,
		
		[Parameter(Position=1, Mandatory=$true)]
		[System.String]
		$VVName ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
        $CPGName ,	
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$WaitTask ,		
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$DryRun ,		
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Count ,
		
		[Parameter(Position=6, Mandatory=$false)]
		[switch]
		$TPVV ,
		
		[Parameter(Position=7, Mandatory=$false)]
		[switch]
		$TDVV ,
		
		[Parameter(Position=8, Mandatory=$false)]
		[switch]
		$DeDup ,
		
		[Parameter(Position=9, Mandatory=$false)]
		[switch]
		$Full ,
		
		[Parameter(Position=10, Mandatory=$false)]
		[switch]
		$Compr ,
		
		[Parameter(Position=11, Mandatory=$false)]
		[System.String]
		$KeepVV ,		
		
		[Parameter(Position=13, Mandatory=$false)]
		[System.String]
		$Threshold , 
		
		[Parameter(Position=14, Mandatory=$false)]
		[System.String]
		$SliceSize , 
		
		[Parameter(Position=15, Mandatory=$false)]
		[System.String]
		$Src_Cpg ,
				
		[Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Compress-VV - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Compress-VV since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Compress-VV since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$Cmd = " tunevv "
	
	if($SUBCommand)
	{
		$test="usr_cpg","snp_cpg","restart","rollback"
		$SbCmd = $SUBCommand.toLower()
		if ($test -eq $SbCmd)
		{
			$Cmd += " $SUBCommand"			
		}
		else
		{
			return "SubCommand Should be [usr_cpg | snp_cpg | restart | rollback]"
		}
		if($SUBCommand -eq "usr_cpg" -Or $SUBCommand -eq "snp_cpg")
		{
			if($CPGName)
			{
				$Cmd += " $CPGName"
			}
			else
			{
				return "SubCommand : $SUBCommand,Must Require CPG Name."
			}
		}
	}
	$Cmd += " -f "
	
	if($WaitTask)
	{
		$Cmd += " -waittask "
	}
	if($DryRun)
	{
		$Cmd += " -dr "
	}
	if($Count)
	{
		$Cmd += " -cnt $Count"
	}
	if($TPVV)
	{
		$Cmd += " -tpvv "
	}
	if($TDVV)
	{
		$Cmd += " -tdvv "
	}
	if($DeDup)
	{
		$Cmd += " -dedup "
	}
	if($Full)
	{
		$Cmd += " -full "
	}
	if($Compr)
	{
		$Cmd += " -compr "
	}
	if($KeepVV)
	{
		$Cmd += " -keepvv $KeepVV"
	}
	if($Src_Cpg)
	{
		$Cmd += " -src_cpg $Src_Cpg"
	}
	if($Threshold)
	{
		$Cmd += " -slth $Threshold"
	}
	if($SliceSize)
	{
		$Cmd += " -slsz $SliceSize"
	}
	if($VVName)
	{					
		$Cmd += " $VVName"			
	}
	
	#write-host "Command = $Cmd"
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
	write-debuglog "  Executing Compress-VV for tuning virtual volume.-->  " "INFO:" 
	return  $Result

} ##  End-of  Compress-VV

####################################################################################################################
## FUNCTION Get-HistChunklet
#####################################################################################################################

Function Get-HistChunklet  
{
<#
  .SYNOPSIS
    The Get-HistChunklet command displays a histogram of service times in a timed loop for individual chunklets
  
  .DESCRIPTION
	The Get-HistChunklet command displays a histogram of service times in a timed loop for individual chunklets
        
  .EXAMPLE
  
    Get-HistChunklet -Iteration 1 
	This example displays one iteration of a histogram of service
		
  .EXAMPLE
    Get-HistChunklet –LDname dildil -Iteration 1 
	identified by name, from which chunklet statistics are sampled.
	
  .EXAMPLE
	Get-HistChunklet -Iteration 1 -Previous

  .PARAMETER Chunklet_num
	Specifies that statistics are limited to only the specified chunklet, identified
	by number.

  .PARAMETER Metric both|time|size
	Selects which metric to display. Metrics can be one of the following:
		both - (Default)Display both I/O time and I/O size histograms
		time - Display only the I/O time histogram
		size - Display only the I/O size histogram

  .PARAMETER Percentage
	Shows the access count in each bucket as a percentage. If this option is
	not specified, the histogram shows the access counts.

  .PARAMETER Previous
	Histogram displays data either from a previous sample(-prev) or from
	when the system was last started(-begin). If no option is specified, the
	histogram shows data from the beginning of the command's execution.
		
  .PARAMETER Beginning
	Histogram displays data either from a previous sample(-prev) or from
	when the system was last started(-begin). If no option is specified, the
	histogram shows data from the beginning of the command's execution.

  .PARAMETER RW
	Specifies that the display includes separate read and write data. If not
	specified, the total is displayed.

  .PARAMETER Interval
	Specifies the interval in seconds that statistics are sampled from
	using an integer from 1 through 2147483. If no count is specified, the
	command defaults to 2 seconds.

  .PARAMETER Iteration
	Specifies that the histogram is to stop after the indicated number of
	iterations using an integer from 1 through 2147483647.
		
  .PARAMETER NI
	Specifies that histograms for only non-idle devices are displayed. This
	option is shorthand for the option -filt t,0,0.

  .PARAMETER LDname 
    Specifies the Logical Disk (LD), identified by name, from which chunklet statistics are sampled.
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-HistChunklet
    LASTEDIT: November 2019
    KEYWORDS: Get-HistChunklet
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(	
	    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$LDname,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Chunklet_num,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Metric,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Iteration,
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$Percentage,
		
		[Parameter(Position=5, Mandatory=$false)]
		[switch]
		$Previous,
		
		[Parameter(Position=6, Mandatory=$false)]
		[switch]
		$Beginning,
		
		[Parameter(Position=7, Mandatory=$false)]
		[switch]
		$RW,
		
		[Parameter(Position=8, Mandatory=$false)]
		[System.String]
		$Interval,
		
		[Parameter(Position=9, Mandatory=$false)]
		[switch]
		$NI,
			
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-HistChunklet - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-HistChunklet since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-HistChunklet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli 
	
	if($plinkresult -match "FAILURE :")	
	{
		Write-DebugLog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$histchCMD = "histch"
	
	if($Iteration )
	{
		$histchCMD+=" -iter $iteration"
	}
	else
	{
		return "Iteration is mandatory..."
	}
	if($LDname)
	{
		$histchCMD +=" -ld $LDname "
	}
	if($Chunklet_num)
	{
		$histchCMD +=" -ch $Chunklet_num "
	} 
	if($Metric)
	{
		$histchCMD +=" -metric $Metric "
	}
	if($Percentage)
	{
		$histchCMD +=" -pct "
	}
	if($Previous)
	{
		$histchCMD +=" -prev "
	}
	if($Beginning)
	{
		$histchCMD +=" -begin "
	}
	if($RW)
	{
		$histchCMD +=" -rw "
	}
	if($Interval)
	{
		$histchCMD +=" -d $Interval "
	}
	if($NI)
	{
		$histchCMD +=" -ni "
	}	
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $histchCMD
	
	$range1 = $Result.count
	
	if($range1 -le "5")
	{
		return "No data available Please try with valid input."
	}
	Write-DebugLog " displays a histogram of service -->$histchCMD "INFO:"" 
	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		
		$LastItem = $Result.Count		
		if($RW)
		{
			$LastItem = $LastItem - 4			
		}		
		Add-Content -Path $tempFile -Value 'Ldid,Ldname,logical_Disk_CH,Pdid,PdCh,0.5,1.0,2.0,4.0,8.0,16,32,64,128,256,4k,8k,16k,32k,64k,128k,256k,512k,1m,time,date'
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "millisec")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Ldname"))
			{
				continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "20")
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}	
}
#END Get-HistChunklet

####################################################################################################################
## FUNCTION Get-HistLD
####################################################################################################################
Function Get-HistLD
{
<#
  .SYNOPSIS
    The Get-HistLD command displays a histogram of service times for Logical Disks (LDs) in a timed loop.
  
  .DESCRIPTION
    The Get-HistLD command displays a histogram of service times for Logical Disks (LDs) in a timed loop.
        
  .EXAMPLE
    Get-HistLD -Iteration 1
	displays a histogram of service Iteration number of times
	
	 
  .EXAMPLE
	Get-HistLD -LdName abcd -Iteration 1
	displays a histogram of service linked with LD_NAME on  Iteration number of times
	
  .EXAMPLE
	Get-HistLD -Iteration 1 -VV_Name ZXZX
	Shows only logical disks that are mapped to virtual volumes with names
	matching any of the names or patterns specified.
	
  .EXAMPLE
	Get-HistLD -Iteration 1 -Domain ZXZX
    Shows only logical disks that are in domains with names matching any
	of the names or patterns specified.
	
  .EXAMPLE
	Get-HistLD -Iteration 1 -Percentage
	Shows the access count in each bucket as a percentage.

  .PARAMETER Timecols
	For the I/O time histogram, shows the columns from the first column
	<fcol> through last column <lcol>. The available columns range from 0
	through 31.

	The first column (<fcol>) must be a value greater than or equal to 0,
	but less than the value of the last column (<lcol>).

	The last column (<lcol>) must be less than or equal to 31.

	The first column includes all data accumulated for columns less than the
	first column and the last column includes accumulated data for all
	columns greater than the last column.

	The default value of <fcol> is 6.
	The default value of <lcol> is 15.

  .PARAMETER Sizecols
	For the I/O size histogram, shows the columns from the first column
	(<fcol>) through the last column (<lcol>). Available columns range from
	0 through 15.

	The first column (<fcol>) must be a value greater than or equal to 0,
	but less than the value of the last column (<lcol>) (default value of 3).
	The last column (<lcol>) must be less than or equal to 15 (default value
	of 11).

	The default value of <fcol> is 3.
	The default value of <lcol> is 11.

  .PARAMETER Percentage
	Shows the access count in each bucket as a percentage. If this option is
	not specified, the histogram shows the access counts.

  .PARAMETER Secs
	Specifies the interval in seconds that statistics are sampled from
	using an integer from 1 through 2147483. If no count is specified, the
	command defaults to 2 seconds.

  .PARAMETER NI
	Specifies that histograms for only non-idle devices are displayed. This
	option is shorthand for the option -filt t,0,0.	
	
  .PARAMETER Iteration 
    displays a histogram of service Iteration number of times
  
  .PARAMETER LdName 
    displays a histogram of service linked with LD_NAME
	
  .PARAMETER VV_Name
	Shows only logical disks that are mapped to virtual volumes with names
	matching any of the names or patterns specified. Multiple volumes or
	patterns can be repeated using a comma separated list.

  .PARAMETER Domain
	Shows only logical disks that are in domains with names matching any
	of the names or patterns specified. Multiple domain names or patterns
	can be repeated using a comma separated list.

  .PARAMETER Metric
	Selects which metric to display. Metrics can be one of the following:
	both - (Default)Display both I/O time and I/O size histograms
	time - Display only the I/O time histogram
	size - Display only the I/O size histogram

  .PARAMETER Previous 
	Histogram displays data either from a previous sample(-prev) or from
	when the system was last started(-begin). If no option is specified, the
	histogram shows data from the beginning of the command's execution.
		
  .PARAMETER Beginning
	Histogram displays data either from a previous sample(-prev) or from
	when the system was last started(-begin). If no option is specified, the
	histogram shows data from the beginning of the command's execution.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-HistLD
    LASTEDIT: November 2019
    KEYWORDS: Get-HistLD
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(	
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Iteration,	

		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Metric,

		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$VV_Name,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Domain,
				
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Timecols,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Sizecols, 
		
		[Parameter(Position=6, Mandatory=$false)]
		[Switch]
		$Percentage,
		
		[Parameter(Position=7, Mandatory=$false)]
		[Switch]
		$Previous,
		
		[Parameter(Position=8, Mandatory=$false)]
		[Switch]
		$Beginning,
		
		[Parameter(Position=9, Mandatory=$false)]
		[Switch]
		$NI,
		
		[Parameter(Position=10, Mandatory=$false)]
		[System.String]
		$Secs,
				
		[Parameter(Position=11, Mandatory=$false)]
		[System.String]
		$LdName,
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-HistLD - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-HistLD since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-HistLD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	$histldCmd = "histld "
	if ($Iteration)
	{
		$histldCmd += " -iter $Iteration "
	}
	else
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "		
	}
	if ($Metric)
	{
		$a = "both","time","size"
		$l=$Metric
		if($a -eq $l)
		{
			$histldCmd+=" -metric $Metric "						
		}
		else
		{ 			
			Return "FAILURE : -Metric $Metric is an Invalid Value Please used only [ both|time|size ]. "
		}
	}
	if($VV_Name)
	{
		$cmd= "showvv "
		$demo = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
		if($demo -match $VV_Name )
		{
			$histldCmd+=" -vv $VV_Name"
		}
		else
		{ 
			return  "FAILURE : No Virtual Volume : $VV_Name found, Please try with valid input."
		}		
	} 
	if($Domain)
	{		
		$cmd= "showdomain "
		$demo = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
		if($demo -match $Domain )
		{
			$histldCmd+=" -domain $Domain"
		}
		else
		{ 
			return  "FAILURE : No Domain : $Domain found, Please try with valid input."
		}
	}	
	if($Timecols)
	{
		$histldCmd+=" -timecols $Timecols"
	}
	if($Sizecols)
	{
		$histldCmd+=" -sizecols $Sizecols"
	}	
	if ($Percentage)
	{
		$histldCmd += " -pct "
	}
	if ($Previous)
	{
		$histldCmd += " -prev "
	}	
	if ($Beginning)
	{
		$histldCmd += " -begin "
	}
	if($Secs)
	{
		$histldCmd+=" -d $Secs"
	}
	if ($NI)
	{
		$histldCmd += " -ni "
	}
	if ($LdName)
	{
		#check wether ld is available or not 
		$cmd= "showld "
		$demo = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
		if($demo -match $LdName )
		{
			$histldCmd += "  $LdName"
		}
		else
		{ 
			return  "FAILURE : No LD_name $LdName found "
		}
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $histldCmd
	write-debuglog "  The Get-HistLD command displays a histogram of service times for Logical Disks (LDs) in a timed loop.->$cmd" "INFO:"	
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -lt "5")
	{
		write-host ""
		return "No data available Please Try With Valid Data. `n"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		if ($Metric -eq "time")
		{
			Add-Content -Path $tempFile -Value  'Logical_Disk_Name,0.50,1,2,4,8,16,32,64,128,256,time,date'
		}
		if ($Metric -eq "size")
		{
			Add-Content -Path $tempFile -Value  'Logical_Disk_Name,4k,8k,16k,32k,64k,128k,256k,512k,1m,time,date' 
		}
		else
		{
			Add-Content -Path $tempFile -Value  'Logical_Disk_Name,0.50,1,2,4,8,16,32,64,128,256,4k,8k,16k,32k,64k,128k,256k,512k,1m,time,date' 
		}
		foreach ($s in  $Result[0..$LastItem] )
		{			
			if ($s -match "millisec")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]
				continue
			}
			if (($s -match "-------") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Ldname"))
			{
				#write-host " s equal-1 $s"
				continue
			}
			#write-host "s = $s"
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s
			#write-host "s final $s"
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-HistLD

####################################################################################################################
## FUNCTION Get-HistPD
###################################################################################################################
Function Get-HistPD
{
<#
  .SYNOPSIS
    The Get-HistPD command displays a histogram of service times for Physical Disks (PDs).
  
  .DESCRIPTION
    The Get-HistPD command displays a histogram of service times for Physical Disks (PDs).
       
  .EXAMPLE
    Get-HistPD  -iteration 1 -WWN abcd
	Specifies the world wide name of the PD for which service times are displayed.
	 
  .EXAMPLE
	Get-HistPD -iteration 1
	The Get-HistPD displays a histogram of service iteration number of times
	Histogram displays data from when the system was last started (–begin).
	
  .EXAMPLE	
	Get-HistPD -iteration 1 -Devinfo
	Indicates the device disk type and speed.
	
  .EXAMPLE	
	Get-HistPD -iteration 1 -Metric both
	(Default)Display both I/O time and I/O size histograms

  .PARAMETER WWN
	Specifies the world wide name of the PD for which service times are displayed.

  .PARAMETER Nodes
	Specifies that the display is limited to specified nodes and physical
	disks connected to those nodes. The node list is specified as a series
	of integers separated by commas (e.g. 1,2,3). The list can also consist
	of a single integer. If the node list is not specified, all disks on all
	nodes are displayed.

  .PARAMETER Slots
	Specifies that the display is limited to specified PCI slots and
	physical disks connected to those PCI slots. The slot list is specified
	as a series of integers separated by commas (e.g. 1,2,3). The list can
	also consist of a single integer. If the slot list is not specified, all
	disks on all slots are displayed.

  .PARAMETER Ports
	Specifies that the display is limited to specified ports and
	physical disks connected to those ports. The port list is specified
	as a series of integers separated by commas (e.g. 1,2,3). The list can
	also consist of a single integer. If the port list is not specified, all
	disks on all ports are displayed.
		
  .PARAMETER Percentage
	Shows the access count in each bucket as a percentage. If this option is
	not specified, the histogram shows the access counts.

  .PARAMETER Previous 
	Histogram displays data either from a previous sample(-prev) or from
	when the system was last started(-begin). If no option is specified, the
	histogram shows data from the beginning of the command's execution.
	
  .PARAMETER Beginning
	Histogram displays data either from a previous sample(-prev) or from
	when the system was last started(-begin). If no option is specified, the
	histogram shows data from the beginning of the command's execution.

  .PARAMETER Devinfo
	Indicates the device disk type and speed.

  .PARAMETER Metric both|time|size
	Selects which metric to display. Metrics can be one of the following:
		both - (Default)Display both I/O time and I/O size histograms
		time - Display only the I/O time histogram
		size - Display only the I/O size histogram
		
  .PARAMETER Iteration 
    Specifies that the histogram is to stop after the indicated number of iterations using an integer from 1 up-to 2147483647.
  
  .PARAMETER FSpec
	Specifies that histograms below the threshold specified by the <fspec>
	argument are not displayed. The <fspec> argument is specified in the
	syntax of <op>,<val_ms>, <count>.
	<op>
		The <op> argument can be specified as one of the following:
			r - Specifies read statistics.
			w - Specifies write statistics.
			t - Specifies total statistics.
			rw - Specifies total read and write statistics.
	<val_ms>
		Specifies the threshold service time in milliseconds.
	<count>
	Specifies the minimum number of access above the threshold service
	time. When filtering is done, the <count> is compared with the sum
	of all columns starting with the one which corresponds to the
	threshold service time. For example, -t,8,100 means to only display
	the rows where the 8ms column and all columns to the right adds
	up to more than 100.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME: Get-HistPD
    LASTEDIT: November 2019
    KEYWORDS: Get-HistPD
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Iteration,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$WWN,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Nodes,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Slots,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Ports,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Devinfo,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$Metric,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Percentage,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Previous,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Beginning,	
			
		[Parameter(Position=10, Mandatory=$false)]
		[System.String]
		$FSpec,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-HistPD - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-HistPD since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-HistPD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	$Cmd = "histpd "
	if($Iteration)
	{
		$Cmd += "-iter $Iteration"	
	}
	else
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "
	}	
		
	if ($WWN)
	{
		$Cmd += " -w $WWN"
	}
	if ($Nodes)
	{
		$Cmd += " -nodes $Nodes"
	}
	if ($Slots)
	{
		$Cmd += " -slots $Slots"
	}
	if ($Ports)
	{
		$Cmd += " -ports $Ports"
	}
	if ($Devinfo)
	{
		$Cmd += " -devinfo "
	}
	if($Metric)
	{
		$Met = $Metric
		$c = "both","time","size"
		$Metric = $metric.toLower()
		if($c -eq $Met)
		{
			$Cmd += " -metric $Metric "
		}
		else
		{
			return "FAILURE: -Metric $Metric is Invalid. Use only [ both | time | size ]."
		}
	}
	if ($Previous)
	{
		$Cmd += " -prev "
	}
	if ($Beginning)
	{
		$Cmd += " -begin "
	}
	if ($Percentage)
	{
		$Cmd += " -pct "
	}	
	if ($FSpec)
	{
		$Cmd += " -filt $FSpec"
	}
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd 
	write-debuglog " The Get-HistPD command displays a histogram of service times for Physical Disks (PDs). " "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -lt "5")
	{
		return "No data available"
	}		
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()

		$LastItem = $Result.Count
		
		if("time" -eq $Metric.trim().tolower())
		{
			#write-host " in time"
			Add-Content -Path $tempFile -Value 'ID,Port,0.50,1,2,4,8,16,32,64,128,256,time,date'
			$LastItem = $Result.Count - 3
		}
		elseif("size" -eq $Metric.trim().tolower())
		{
			#write-host " in size"
			Add-Content -Path $tempFile -Value 'ID,Port,4k,8k,16k,32k,64k,128k,256k,512k,1m,time,date'	
			$LastItem = $Result.Count - 3
		}
		elseif ($Devinfo)
		{	
			Add-Content -Path $tempFile -Value  'ID,Port,Type,K_RPM,0.50,1,2,4,8,16,32,64,128,256,4k,8k,16k,32k,64k,128k,256k,512k,1m,time,date'
		}
		else
		{
			Add-Content -Path $tempFile -Value  'ID,Port,0.50,1,2,4,8,16,32,64,128,256,4k,8k,16k,32k,64k,128k,256k,512k,1m,time,date'			
		}
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "millisec")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "ID"))
			{
				continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line			
			$aa=$s.split(",").length
			if ($aa -eq "20") 
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-HistPD

####################################################################################################################
## FUNCTION Get-HistPort
####################################################################################################################
Function Get-HistPort
{
<#
  .SYNOPSIS
    The Get-HistPort command displays a histogram of service times for ports within the system.
  
  .DESCRIPTION
   The Get-HistPort command displays a histogram of service times for ports within the system.
      
  .EXAMPLE
    Get-HistPort -iteration 1
	displays a histogram of service times with option it can be one of these [both|ctrl|data].
	 
  .EXAMPLE
	Get-HistPort -iteration 1 -Both
	Specifies that both control and data transfers are displayed(-both)
	
  .EXAMPLE
	Get-HistPort -iteration 1 -Nodes nodesxyz
	Specifies that the display is limited to specified nodes and physical disks connected to those nodes.
	
  .EXAMPLE	
	Get-HistPort –Metric both -iteration 1
	displays a histogram of service times with -metric option. metric can be one of these –metric [both|time|size]
	
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
		
  .PARAMETER Nodes
	Specifies that the display is limited to specified nodes and physical
	disks connected to those nodes. The node list is specified as a series
	of integers separated by commas (e.g. 1,2,3). The list can also consist
	of a single integer. If the node list is not specified, all disks on all
	nodes are displayed.

  .PARAMETER Slots
	Specifies that the display is limited to specified PCI slots and
	physical disks connected to those PCI slots. The slot list is specified
	as a series of integers separated by commas (e.g. 1,2,3). The list can
	also consist of a single integer. If the slot list is not specified, all
	disks on all slots are displayed.

  .PARAMETER Ports
	Specifies that the display is limited to specified ports and
	physical disks connected to those ports. The port list is specified
	as a series of integers separated by commas (e.g. 1,2,3). The list can
	also consist of a single integer. If the port list is not specified, all
	disks on all ports are displayed.
	
  .PARAMETER Host
	Specifies to display only host ports (target ports), only disk ports
	(initiator ports), only Fibre Channel Remote Copy configured ports, or
	only Fibre Channel ports for Data Migration.
	If no option is specified, all ports are displayed.
		
  .PARAMETER Disk 
	Specifies to display only host ports (target ports), only disk ports
	(initiator ports), only Fibre Channel Remote Copy configured ports, or
	only Fibre Channel ports for Data Migration.
	If no option is specified, all ports are displayed.
		
  .PARAMETER RCFC 
	Specifies to display only host ports (target ports), only disk ports
	(initiator ports), only Fibre Channel Remote Copy configured ports, or
	only Fibre Channel ports for Data Migration.
	If no option is specified, all ports are displayed.
		
  .PARAMETER PEER
	Specifies to display only host ports (target ports), only disk ports
	(initiator ports), only Fibre Channel Remote Copy configured ports, or
	only Fibre Channel ports for Data Migration.
	If no option is specified, all ports are displayed.

  .PARAMETER Metric
	Selects which metric to display. Metrics can be one of the following:
		both - (Default)Display both I/O time and I/O size histograms
		time - Display only the I/O time histogram
		size - Display only the I/O size histogram
	
  .PARAMETER Iteration 
    Specifies that the histogram is to stop after the indicated number of iterations using an integer from 1 up-to 2147483647.

  .PARAMETER Percentage
	Shows the access count in each bucket as a percentage. If this option is
	not specified, the histogram shows the access counts.

  .PARAMETER Previous 
	Histogram displays data either from a previous sample(-prev) or from
	when the system was last started(-begin). If no option is specified, the
	histogram shows data from the beginning of the command's execution.
	
  .PARAMETER Beginning
	Histogram displays data either from a previous sample(-prev) or from
	when the system was last started(-begin). If no option is specified, the
	histogram shows data from the beginning of the command's execution.

  .PARAMETER RW	
	Specifies that the display includes separate read and write data. If not
	specified, the total is displayed.
		
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME: Get-HistPort
    LASTEDIT: November 2019
    KEYWORDS: Get-HistPort
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Iteration,	
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Both,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$CTL,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Data,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Nodes,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Slots,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$Ports,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Host,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$PEER,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Disk,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$RCFC,
		
		[Parameter(Position=11, Mandatory=$false)]
		[System.String]
		$Metric,		
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Percentage,
		
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Previous,
		
		[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Beginning,
		
		[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$RW,
		
		[Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Get-HistPort - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-HistPort since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-HistPort since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	$Cmd = "histport "
	if($Iteration)
	{	
		$Cmd +=" -iter $Iteration"
	}
	else
	{
		write-debuglog "Get-HistPort parameter is empty. Simply return  " "INFO:"
		return "Error: -Iteration mandatory"
	}
	if($Both)
	{	
		$Cmd +=" -both "
	}
	if($CTL)
	{	
		$Cmd +=" -ctl "
	}
	if($Data)
	{	
		$Cmd +=" -data "
	}
	if ($Nodes)
	{
		$Cmd += " -nodes $Nodes"
	}
	if ($Slots)
	{
		$Cmd += " -slots $Slots"
	}
	if ($Ports)
	{
		$Cmd += " -ports $Ports"
	}
	if($Host)
	{	
		$Cmd +=" -host "
	}
	if($Disk)
	{	
		$Cmd +=" -disk "
	}
	if($RCFC)
	{	
		$Cmd +=" -rcfc "
	}
	if($PEER)
	{	
		$Cmd +=" -peer "
	}
	if ($Metric)
	{
		$Cmd += " -metric "
		$a1="both","time","size"
		$Metric = $Metric.toLower()
		if($a1 -eq $Metric )
		{
			$Cmd += "$Metric "
		}		
		else
		{
			return "FAILURE:  -Metric $Metric  is Invalid. Only [ both | time | size ] can be used."
		}
	}	
	if ($Previous)
	{
		$Cmd += " -prev "
	}
	if ($Beginning)
	{
		$Cmd += " -begin "
	}
	if ($Percentage)
	{
		$Cmd += " -pct "
	}
	if ($RW)
	{
		$Cmd += " -rw "
	}
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd 
	
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -lt "5")
	{
		return "No data available"
	}		
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		
		$LastItem = $Result.Count
		
		if("time" -eq $Metric.trim().tolower())
		{
			Add-Content -Path $tempFile -Value 'Port,Data/Ctrl,0.50,1,2,4,8,16,32,64,128,256,time,date'
		}
		elseif("size" -eq $Metric.trim().tolower())
		{
			#write-host " in size"
			Add-Content -Path $tempFile -Value 'Port,Data/Ctrl,4k,8k,16k,32k,64k,128k,256k,512k,1m,time,date'
		}
		elseif($RW)
		{
			#write-host " in else"
			Add-Content -Path $tempFile -Value 'Port,Data/Ctrl,R/W,0.50,1,2,4,8,16,32,64,128,256,4k,8k,16k,32k,64k,128k,256k,512k,1m,time,date'
		}
		else
		{
			#write-host " in else"
			Add-Content -Path $tempFile -Value 'Port,Data/Ctrl,0.50,1,2,4,8,16,32,64,128,256,4k,8k,16k,32k,64k,128k,256k,512k,1m,time,date'
		}
		
		foreach ($s in  $Result[0..$LastItem] )
		{		
			if ($s -match "millisec")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Ldname"))
			{
				continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			$s +=",$global:time1,$global:date1"	
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-HistPort

####################################################################################################################
## FUNCTION Get-HistRCopyVv
###################################################################################################################
Function Get-HistRCopyVv
{
<#
  .SYNOPSIS
   The Get-HistRCopyVv command shows a histogram of total remote-copy service times and backup system remote-copy service times in a timed loop.
	
  .DESCRIPTION
   The Get-HistRCopyVv command shows a histogram of total remote-copy service times and backup system 	remote-copy service times in a timed loop        
  
  .EXAMPLE
	Get-HistRCopyVv -iteration 1
	The Get-HistRCopyVv command shows a histogram of total remote-copy service iteration number of times
  
  .EXAMPLE
    Get-HistRCopyVv -iteration 1 -Sync
	The Get-HistRCopyVv command shows a histogram of total remote-copy service iteration number of times
	with option sync
	
  .EXAMPLE	
	Get-HistRCopyVv -group groupvv_1 -iteration

  .EXAMPLE	
	Get-HistRCopyVv -iteration 1 -Periodic
	
  .EXAMPLE	
	Get-HistRCopyVv -iteration 1 -PortSum
	
  .EXAMPLE	
	Get-HistRCopyVv -target name_vv1 -iteration 1
	The Get-HistRCopyVv command shows a histogram of total remote-copy service with specified target name.
	
  .EXAMPLE	
	Get-HistRCopyVv -group groupvv_1 -iteration   
	The Get-HistRCopyVv command shows a histogram of total remote-copy service with specified Group name.
	
  .PARAMETER Async - Show only volumes which are being copied in asynchronous mode.

  .PARAMETER sync - Show only volumes that are being copied in synchronous mode.
  
  .PARAMETER periodic- Show only volumes which are being copied in asynchronous periodic mode.
  
  .PARAMETER primary - Show only virtual volumes in the primary role.
  
  .PARAMETER secondary - Show only virtual volumes in the secondary role.
  
  .PARAMETER targetsum - Displays the sums for all volumes of a target.
  
  .PARAMETER portsum - Displays the sums for all volumes on a port.
  
  .PARAMETER groupsum - Displays the sums for all volumes of a volume group.
  
  .PARAMETER vvsum - Displays the sums for all targets and links of a virtual volume.
  
  .PARAMETER domainsum - Displays the sums for all volumes of a domain.

  .PARAMETER VV_Name
	Displays statistics only for the specified virtual volume or volume name
    pattern. Multiple volumes or patterns can be repeated (for example,
    <VV_name> <VV_name>). If not specified, all virtual volumes that are
    configured for remote copy are listed.
  
  .PARAMETER interval 
    <secs>  Specifies the interval in seconds that statistics are sampled from using an integer from 1 through 2147483. If no count is specified, the  command defaults to 2 seconds. 
  
  .PARAMETER Pct
	Shows the access count in each bucket as a percentage. If this option is
	not specified, the histogram shows the access counts.

  .PARAMETER Prev
	Specifies that the histogram displays data from a previous sample.
	If no option is specified, the histogram shows data from the beginning
	of the command's execution.
  
  .PARAMETER domain
	Shows only the virtual volumes that are in domains with names that match the specified domain name(s) or pattern(s).
	
  .PARAMETER target
   Shows only volumes whose group is copied to the specified target name or pattern. Multiple target names or patterns may be specified using a comma-separated list.
   
  .PARAMETER group
    Shows only volumes whose volume group matches the specified group name or pattern of names.
	Multiple group names or patterns may be specified using a comma-separated list.
  
  .PARAMETER iteration
    Specifies that the statistics are to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-HistRCopyVv
    LASTEDIT: November 2019
    KEYWORDS: Get-HistRCopyVv
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$ASync,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$Sync,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Periodic,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Primary,
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$Secondary,
		
		[Parameter(Position=5, Mandatory=$false)]
		[switch]
		$TargetSum,
		
		[Parameter(Position=6, Mandatory=$false)]
		[switch]
		$PortSum,
		
		[Parameter(Position=7, Mandatory=$false)]
		[switch]
		$GroupSum,
		
		[Parameter(Position=8, Mandatory=$false)]
		[switch]
		$VVSum,
		
		[Parameter(Position=9, Mandatory=$false)]
		[switch]
		$DomainSum,
		
		[Parameter(Position=10, Mandatory=$false)]
		[switch]
		$Pct,
		
		[Parameter(Position=11, Mandatory=$false)]
		[switch]
		$Prev,

		[Parameter(Position=12, Mandatory=$false)]
		[System.String]
		$VV_Name,
		
		[Parameter(Position=13, Mandatory=$false)]
		[System.String]
		$interval,	
		
		[Parameter(Position=14, Mandatory=$false)]
		[System.String]
		$domain,
		
		[Parameter(Position=15, Mandatory=$false)]
		[System.String]
		$group,
		
		[Parameter(Position=16, Mandatory=$false)]
		[System.String]
		$target,
		
		[Parameter(Position=17, Mandatory=$false)]
		[System.String]
		$iteration,		
		
		[Parameter(Position=18, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)	
	Write-DebugLog "Start: In Get-HistRCopyVv - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-HistRCopyVv since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-HistRCopyVv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$Cmd = "histrcvv "
	
	if($ASync)	
	{
		$Cmd += " -async "
	}
	if($Sync)	
	{
		$Cmd += " -sync "
	}
	if($Periodic)	
	{
		$Cmd += " -periodic "
	}
	if($Primary)	
	{
		$Cmd += " -primary "
	}
	if($Secondary)	
	{
		$Cmd += " -secondary "
	}
	if($TargetSum)	
	{
		$Cmd += " -targetsum "
	}
	if($PortSum)	
	{
		$Cmd += " -portsum "
	}
	if($GroupSum)	
	{
		$Cmd += " -groupsum "
	}
	if($VVSum)	
	{
		$Cmd += " -vvsum "
	}
	if($DomainSum)	
	{
		$Cmd += " -domainsum "
	}
	if($Pct)	
	{
		$Cmd += " -pct "
	}
	if($Prev)	
	{
		$Cmd += " -prev "
	}	
	if($interval)
	{
		$Cmd += " -d $interval"
	}
	if ($domain)
	{ 
		$Cmd += " -domain  $domain"
	}
	if ($group)
	{ 
		$Cmd += " -g $group"			
	}
	if ($target)
	{ 
		$Cmd += " -t $target"			
	}
	if ($VV_Name)
	{ 
		$Cmd += " $VV_Name"			
	}
	if ($iteration)
	{ 
		$Cmd += " -iter $iteration "			
	}	
	else
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "		
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
	write-debuglog " histograms sums for all synchronous remote - copy volumes" "INFO:" 
	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 2
		if($VVSum)
		{
			Add-Content -Path $tempFile -Value "VVname,RCGroup,Target,Mode,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,Time,Date" 
		}
		elseif($PortSum) 
		{
			Add-Content -Path $tempFile -Value "Link,Target,Type,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,Time,Date"
		}
		elseif($GroupSum) 
		{
			Add-Content -Path $tempFile -Value "Group,Target,Mode,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,Time,Date"
		}
		elseif($TargetSum)
		{
			Add-Content -Path $tempFile -Value "Target,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,Time,Date"
		}
		elseif($DomainSum)
		{
			Add-Content -Path $tempFile -Value "Domain,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,Time,Date"
		}
		else 
		{
			Add-Content -Path $tempFile -Value "VVname,RCGroup,Target,Mode,Port,Type,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,Time,Date"
		}
		foreach($s in  $Result[0..$LastItem] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			
			if($s -match "millisec")
			{			 
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]
				continue
			}
			$lent=$s.split(",").length
			
			$var2 = $lent[0]
			if( "total" -eq $var2)
			{
				continue
			}	
			if(($s -match "-------") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "RCGroup"))
			{
				continue
			}	
			
			# Replace one or more spaces with comma to build CSV line
			$s +=",$global:time1,$global:date1"	
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	elseif($Result -match "No virtual volume")
	{ 
		Return "No data available : $Result"
	}
	else
	{
		return $Result
	}
} # End Get-HistRCopyVv

####################################################################################################################
## FUNCTION Get-HistVLun
####################################################################################################################

Function Get-HistVLun
{
<#
  .SYNOPSIS
	The Get-HistVLun command displays Virtual Volume Logical Unit Number (VLUN) service time histograms.
	
  .DESCRIPTION
    The Get-HistVLun command displays Virtual Volume Logical Unit Number (VLUN) service time histograms.
        
  .EXAMPLE
    Get-HistVLun -iteration 1
	This example displays two iterations of a histogram of service times for all VLUNs.	
		
  .EXAMPLE	
	Get-HistVLun -iteration 1 -nodes 1
	This example displays two iterations of a histogram only exports from the specified nodes.	
	
  .EXAMPLE	
	Get-HistVLun -iteration 1 -domain DomainName
	Shows only VLUNs whose Virtual Volumes (VVs) are in domains with names that match one or more of the specified domain names or patterns.
	
  .EXAMPLE	
	Get-HistVLun -iteration 1 -Percentage
	Shows the access count in each bucket as a percentage.	 
	
  .PARAMETER domain
	Shows only VLUNs whose Virtual Volumes (VVs) are in domains with names that match one or more of the specified domain names or patterns. Multiple domain names or patterns can be
	repeated using a comma-separated list.
		
  .PARAMETER host
   Shows only VLUNs exported to the specified host(s) or pattern(s). Multiple host names or patterns
	can be repeated using a comma-separated list.
	
  .PARAMETER vvname
  Requests that only LDs mapped to VVs that match and of the specified names or patterns be displayed. Multiple volume names or patterns can be repeated using a comma-separated list.

  .PARAMETER Nodes
	Specifies that the display is limited to specified nodes and physical
	disks connected to those nodes. The node list is specified as a series
	of integers separated by commas (e.g. 1,2,3). The list can also consist
	of a single integer. If the node list is not specified, all disks on all
	nodes are displayed.

  .PARAMETER Slots
	Specifies that the display is limited to specified PCI slots and
	physical disks connected to those PCI slots. The slot list is specified
	as a series of integers separated by commas (e.g. 1,2,3). The list can
	also consist of a single integer. If the slot list is not specified, all
	disks on all slots are displayed.

  .PARAMETER Ports
	Specifies that the display is limited to specified ports and
	physical disks connected to those ports. The port list is specified
	as a series of integers separated by commas (e.g. 1,2,3). The list can
	also consist of a single integer. If the port list is not specified, all
	disks on all ports are displayed.
		
  .PARAMETER Metric
	Selects which metric to display. Metrics can be one of the following:
		both - (Default)Display both I/O time and I/O size histograms
		time - Display only the I/O time histogram
		size - Display only the I/O size histogram

  .PARAMETER Percentage
	Shows the access count in each bucket as a percentage. If this option is
	not specified, the histogram shows the access counts.

  .PARAMETER Previous
	Histogram displays data either from a previous sample(-prev) or from
	when the system was last started(-begin). If no option is specified, the
	histogram shows data from the beginning of the command's execution.
	
  .PARAMETER Beginning
	Histogram displays data either from a previous sample(-prev) or from
	when the system was last started(-begin). If no option is specified, the
	histogram shows data from the beginning of the command's execution.
		
  .PARAMETER Lun      
  Specifies that VLUNs with LUNs matching the specified LUN(s) or pattern(s) are displayed. Multiple LUNs or patterns can be repeated using a comma-separated list.
  
 .PARAMETER iteration
  Specifies that the statistics are to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-HistVLun
    LASTEDIT: November 2019
    KEYWORDS: Get-HistVLun
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$iteration,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$domain,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$host,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$vvname,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$lun,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Nodes,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$Slots,
		
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$Ports,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Percentage,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Previous,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Beginning,
		
		[Parameter(Position=11, Mandatory=$false)]
		[System.String]
		$Metric,			
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)		
	
	Write-DebugLog "Start: In Get-HistVLun - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-HistVLun since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-HistVLun since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$Cmd = "histvlun "
	if ($iteration)
	{ 
		$Cmd += " -iter $iteration"
	}	
	else
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error : -Iteration is mandatory. "
	}
	if ($domain)
	{ 
		$Cmd += " -domain $domain"
	}	
	if($host)
	{
		$objType = "host"
		$objMsg  = "hosts"		
		## Check Host Name 
		if ( -not (Test-CLIObject -objectType $objType -objectName $host -objectMsg $objMsg))
		{
			write-debuglog "host $host does not exist. Nothing to List" "INFO:" 
			return "FAILURE : No host $host found"
		}		
		$Cmd += " -host $host "		
	}
	if ($vvname)
	{ 
		$GetvVolumeCmd="showvv"
		$Res = Invoke-CLICommand -Connection $SANConnection -cmds  $GetvVolumeCmd
		if ($Res -match $vvname)
			{
				$Cmd += " -v $vvname"
			}
			else
			{ 
				write-debuglog "vvname $vvname does not exist. Nothing to List" "INFO:" 
				return "FAILURE : No vvname $vvname found"			
			}
	}	
	if ($lun)
	{ 
		$Cmd += " -l $lun"			
	}
	if ($Nodes)
	{
		$Cmd += " -nodes $Nodes"
	}
	if ($Slots)
	{
		$Cmd += " -slots $Slots"
	}
	if ($Ports)
	{
		$Cmd += " -ports $Ports"
	}	
	if($Metric)
	{
		$Met = $Metric
		$c = "both","time","size"
		$Metric = $metric.toLower()
		if($c -eq $Met)
		{
			$Cmd += " -metric $Metric "
		}
		else
		{
			return "FAILURE: -Metric $Metric is Invalid. Use only [ both | time | size ]."
		}
	}
	if ($Previous)
	{
		$Cmd += " -prev "
	}
	if ($Beginning)
	{
		$Cmd += " -begin "
	}
	if ($Percentage)
	{
		$Cmd += " -pct "
	}		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
	write-debuglog " histograms The Get-HistVLun command displays Virtual Volume Logical Unit Number (VLUN)  " "INFO:" 
	$range1 = $Result.Count
	#write-host "count = $range1"
	if($range1 -le "5" )
	{
		return "No Data Available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count 
		
		if("time" -eq $Metric.trim().tolower())
		{			
			Add-Content -Path $tempFile -Value 'Lun,VVname,Host,Port,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),time,date'
			$LastItem = $Result.Count -3
		}
		elseif("size" -eq $Metric.trim().tolower())
		{
			Add-Content -Path $tempFile -Value 'Lun,VVname,Host,Port,4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes),time,date'
			$LastItem = $Result.Count -3
		}
		else
		{
			Add-Content -Path $tempFile -Value 'Lun,VVname,Host,Port,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes),time,date'
		}
		foreach ($s in  $Result[0..$LastItem] )
		{			
			if ($s -match "millisec"){
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]

				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "VVname"))
			{
				continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "20")
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}	
	else
	{
		return $Result
	}
} # End Get-HistVLun

####################################################################################################################
## FUNCTION Get-HistVv
####################################################################################################################
Function Get-HistVv
{

<#
  .SYNOPSIS
	The Get-HistVv command displays Virtual Volume (VV) service time histograms in a timed loop.
	
  .DESCRIPTION
   The Get-HistVv command displays Virtual Volume (VV) service time histograms in a timed loop.
	      
  .EXAMPLE
    Get-HistVv -iteration 1
	This Example displays Virtual Volume (VV) service time histograms service iteration number of times.
	
	 
  .EXAMPLE
	Get-HistVv  -iteration 1 -domain domain.com
	This Example Shows only the VVs that are in domains with names that match the specified domain name(s)
	
  .EXAMPLE	
	Get-HistVv  -iteration 1 –Metric both
	This Example Selects which Metric to display.
	
  .EXAMPLE
	Get-HistVv -iteration 1 -Timecols "1 2"
	
  .EXAMPLE
	Get-HistVv -iteration 1 -Sizecols "1 2"
		
  .EXAMPLE	
	Get-HistVv –Metric both -VVname demoVV1 -iteration 1
	This Example Selects which Metric to display. associated with Virtual Volume name.
 
	
  .PARAMETER domain
	Shows only the VVs that are in domains with names that match the specified domain name(s) .
		
  .PARAMETER Metric
	Selects which Metric to display. Metrics can be one of the following:
	1)both - (Default) Displays both I/O time and I/O size histograms.
	2)time - Displays only the I/O time histogram.
	3)size - Displays only the I/O size histogram.
	
  .PARAMETER Timecols
	For the I/O time histogram, shows the columns from the first column
	<fcol> through last column <lcol>. The available columns range from 0
	through 31.

	The first column (<fcol>) must be a value greater than or equal to 0,
	but less than the value of the last column (<lcol>).

	The last column (<lcol>) must be less than or equal to 31.

	The first column includes all data accumulated for columns less than the
	first column and the last column includes accumulated data for all
	columns greater than the last column.

	The default value of <fcol> is 6.
	The default value of <lcol> is 15.

  .PARAMETER Sizecols
	For the I/O size histogram, shows the columns from the first column
	(<fcol>) through the last column (<lcol>). Available columns range from
	0 through 15.

	The first column (<fcol>) must be a value greater than or equal to 0,
	but less than the value of the last column (<lcol>) (default value of 3).
	The last column (<lcol>) must be less than or equal to 15 (default value
	of 11).

	The default value of <fcol> is 3.
	The default value of <lcol> is 11.
  
  .PARAMETER Percentage
	Shows the access count in each bucket as a percentage. If this option is
	not specified, the histogram shows the access counts.

  .PARAMETER Previous
	Histogram displays data either from a previous sample(-prev) or from
	when the system was last started(-begin). If no option is specified, the
	histogram shows data from the beginning of the command's execution.
	
  .PARAMETER Beginning
	Histogram displays data either from a previous sample(-prev) or from
	when the system was last started(-begin). If no option is specified, the
	histogram shows data from the beginning of the command's execution.
		
  .PARAMETER RW
	Specifies that the display includes separate read and write data. If not
	specified, the total is displayed.

  .PARAMETER IntervalInSeconds
	Specifies the interval in seconds that statistics are sampled from
	using an integer from 1 through 2147483. If no count is specified, the
	command defaults to 2 seconds.
    
  .PARAMETER FSpace 
	Specifies that histograms below the threshold specified by the <fspec>
	argument are not displayed. The <fspec> argument is specified in the
	syntax of <op>,<val_ms>, <count>.
	<op>
		The <op> argument can be specified as one of the following:
			r - Specifies read statistics.
			w - Specifies write statistics.
			t - Specifies total statistics.
			rw - Specifies total read and write statistics.
	<val_ms>
		Specifies the threshold service time in milliseconds.
	<count>
	Specifies the minimum number of access above the threshold service
	time. When filtering is done, the <count> is compared with the sum
	of all columns starting with the one which corresponds to the
	threshold service time. For example, -t,8,100 means to only display
	the rows where the 8ms column and all columns to the right adds
	up to more than 100.
	
  .PARAMETER VVName
	Virtual Volume name
	  
 .PARAMETER iteration
	Specifies that the statistics are to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:Get-HistVv
    LASTEDIT: November 2019
    KEYWORDS: Get-HistVv
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$iteration,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$domain,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Metric,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Timecols,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Sizecols,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$VVname,		
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Percentage,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Previous,	

		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$RW,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$IntervalInSeconds,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$FSpace,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-HistVv - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-HistVv since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-HistVv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$Cmd = "histvv "
	if ($iteration)
	{ 
		$Cmd += " -iter $iteration "	
	}
	else
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "
	}
	if ($domain)
	{ 
		$Cmd += " -domain $domain "		
	}
	if($Metric)
	{
		$opt="both","time","size"
		$Metric = $Metric.toLower()
		if ($opt -eq $Metric)
		{
			$Cmd += " -metric $Metric"					
		}
		else 
		{
			Write-DebugLog "Stop: Exiting Get-HistVv since SAN connection object values are null/empty" $Debug
			return " metrics $Metric not found only [ both | time | size ] can be passed one at a time "
		}
	}
	if ($Timecols)
	{ 
		$Cmd += " -timecols $Timecols "		
	}
	if ($Sizecols)
	{ 
		$Cmd += " -sizecols $Sizecols "		
	}
	if ($Previous)
	{
		$Cmd += " -prev "
	}	
	if ($Percentage)
	{
		$Cmd += " -pct "
	}
	if ($RW)
	{
		$Cmd += " -rw "
	}
	if ($IntervalInSeconds)
	{ 
		$Cmd += " -d $IntervalInSeconds "		
	}
	if ($FSpace)
	{ 
		$Cmd += " -filt $FSpace "		
	}
	if($VVname)
	{ 
		$vv=$VVname
		$Cmd1 ="showvv"
		$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd1
		if($Result1 -match $vv)			
		{
			$cmd += " $vv "
		}
		else
		{
			Write-DebugLog " Error : No VVname Found. "
			Return "Error: -VVname $VVname is not available `n Try Using Get-VvList to list all the VV's Available  "
		}
	}		
			
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
	write-debuglog " Get-HistVv command displays Virtual Volume Logical Unit Number (VLUN)  " "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -le "5")
	{
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		if("time" -eq $Metric.trim().tolower())
		{
		#write-host " in time"
			Add-Content -Path $tempFile -Value 'VVname,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),time,date'
		}
		elseif("size" -eq $Metric.trim().tolower())
		{
			#write-host " in size"
			Add-Content -Path $tempFile -Value 'VVname,4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes),time,date'
		}
		else
		{
			Add-Content -Path $tempFile -Value 		'VVname,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes),time,date'
		}
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "millisec")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]

				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "VVname"))
			{
				continue
			}			
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line			
			$s +=",$global:time1,$global:date1"	
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-HistVv

####################################################################################################################
## FUNCTION Get-StatChunklet
####################################################################################################################

Function Get-StatChunklet
{
<#
  .SYNOPSIS
   The Get-StatChunklet command displays chunklet statistics in a timed loop.
   
  .DESCRIPTION
   The Get-StatChunklet command displays chunklet statistics in a timed loop. 
	
  .EXAMPLE
	Get-StatChunklet -Iterration 1
	This example displays chunklet statistics in a timed loop.
	
  .EXAMPLE
   Get-StatChunklet -RW -Iteration 1
   This example Specifies that reads and writes are displayed separately.while displays chunklet statistics in a timed loop.  
   	
  .EXAMPLE  
	Get-StatChunklet -LDname demo1 -CHnum 5 -Iterration 1 
	This example Specifies particular chunklet number & logical disk.
	
  .PARAMETER RW	
	Specifies that reads and writes are displayed separately. If this option is not used, then the total
	of reads plus writes is displayed.
				
  .PARAMETER Idlep
  Specifies the percent of idle columns in the output.
	
  .PARAMETER Begin
  Specifies that I/O averages are computed from the system start time. If not specified, the average
  is computed since the first iteration of the command.
				
  .PARAMETER NI
  Specifies that statistics for only non-idle devices are displayed
	
  .PARAMETER Delay 
	Specifies the interval, in seconds, that statistics are sampled using an integer from 1 through
	2147483.
	
  .PARAMETER LDname 
	Specifies that statistics are restricted to chunklets from a particular logical disk.
	
  .PARAMETER CHnum  
	Specifies that statistics are restricted to a particular chunklet number.
	
  .PARAMETER Iteration 
	Specifies that CMP statistics are displayed a specified number of times as indicated by the num argument using an integer
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME: Get-StatChunklet
    LASTEDIT: November 2019
    KEYWORDS: Get-StatChunklet
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Iteration ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$RW,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$IDLEP,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Begin,
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$NI,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Delay,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$LDname ,
		
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$CHnum ,		
				
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-StatChunklet  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-StatChunklet since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-StatChunklet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statch"
	
	if($Iteration )
	{	
		$cmd+=" -iter $Iteration "	
	}
	else
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "		
	}
	
	if($RW)	
	{
		$cmd +=" -rw "
	}
	if($IDLEP)	
	{
		$cmd+=" -idlep "
	}
	if($Begin)	
	{
		$cmd+=" -begin "
	}
	if($NI)	
	{
		$cmd+=" -ni "
	}
	if($Delay)	
	{
		$cmd+=" -d $Delay"
	}
	if($LDname)	
	{
		$ld="showld"
		$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $ld
		if($Result1 -match $LDname )
		{
			$cmd+=" -ld $LDname "
		}
		else 
		{
			Write-DebugLog "Stop: Exiting  Get-StatChunklet   since -LDname $LDname in unavailable "
			Return "FAILURE : -LDname $LDname is not available . "
		}
	}
	if($CHnum)
	{
		$cmd+=" -ch $CHnum "
	}
	
	#write-host "$cmd"		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing  Get-StatChunklet command displays chunklet statistics in a timed loop. with the command  " "INFO:" 
	$range1 = $Result.Count
	if($range1 -le "5" )
	{
		return "No Data Available"
	}
	if( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		if($IDLEP)	
		{
			Add-Content -Path $tempFile -Value "Logical_Disk_I.D,LD_Name,Ld_Ch,Pd_id,Pd_Ch,R/W,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Idle_Cur,Idle_Avg,Time,Date" 
		}
		else 
		{
			Add-Content -Path $tempFile -Value "Logical_Disk_I.D,LD_Name,Ld_Ch,Pd_id,Pd_Ch,R/W,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Time,Date"
		}
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "r/w")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$global:time1 = $s.substring(0,8)
				$global:date1 = $s.substring(9,19)
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Qlen"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "11")
			{
				continue
			}
			if (($aa -eq "13") -and ($IDLEP))
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s
		}
		
		Import-Csv $tempFile
		del $tempFile
	}	
	else
	{
		return $Result
	}	
} # End Get-StatChunklet

####################################################################################################################
## FUNCTION Get-StatCMP
####################################################################################################################
Function Get-StatCMP
{
<#
  .SYNOPSIS
   The Get-StatCMP command displays Cache Memory Page (CMP) statistics by node or by Virtual Volume (VV).
   
  .DESCRIPTION
   The Get-StatCMP command displays Cache Memory Page (CMP) statistics by node or by Virtual Volume (VV).
  
	
  .EXAMPLE
	Get-StatCMP -Iteration 1
	This Example displays Cache Memory Page (CMP).
	
  .EXAMPLE
   Get-StatCMP -VVname Demo1 -Iteration 1
   This Example displays Cache Memory Page (CMP) statistics by node or by Virtual Volume (VV).
	
  		
  .PARAMETER VVname   
	Specifies that statistics are displayed for virtual volumes matching the specified name or pattern.
	
  .PARAMETER Domian 
	Shows VVs that are in domains with names that match one or more of the specified domains or patterns.
	
  .PARAMETER Delay  
	Specifies the interval, in seconds, that statistics are sampled using an integer from 1 through
	2147483.

  .PARAMETER NI
	Specifies that statistics for only non-idle VVs are displayed.
	This option is valid only if -v is also specified.
	
  .PARAMETER Iteration 
	Specifies that CMP statistics are displayed a specified number of times as indicated by the num argument using an integer
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME: Get-StatCMP
    LASTEDIT: November 2019
    KEYWORDS: Get-StatCMP
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$NI,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$VVname ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Domian ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Delay  ,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Iteration ,
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-StatCMP  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-StatCMP  since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-StatCMP since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statcmp -v "	
	
	if($Iteration)
	{
		$cmd+=" -iter $Iteration "
	}
	else
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "		
	}	
	if ($NI)
	{
		$cmd +=" -ni "
	}
	if($VVname)	
	{
		$cmd+=" -n $VVname "
	}		
	if ($Domian)
	{
		$cmd+= " -domain $Domian "	
	}
	if($Delay)	
	{
		$cmd+=" -d $Delay"
	}	
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing  Get-StatCMP command displays Cache Memory Page (CMP) statistics. with the command  " "INFO:" 
	$range1 = $Result.count
	
	if($range1 -le "3")
	{
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		Add-Content -Path $tempFile -Value "VVid,VVname,Type,Curr_Accesses,Curr_Hits,Curr_Hit%,Total_Accesses,Total_Hits,Total_Hit%,Time,Date"
		foreach ($s in  $Result[0..$LastItem] )
		{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				if ($s -match "Current"){	
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if (($s -match "---") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "VVname"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "11")
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s
			}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-StatCMP

####################################################################################################################
## FUNCTION Get-StatCPU
####################################################################################################################

Function Get-StatCPU
{
<#
  .SYNOPSIS
   The Get-StatCPU command displays CPU statistics for all nodes.
   
  .DESCRIPTION
   The Get-StatCPU command displays CPU statistics for all nodes.

  .EXAMPLE
	Get-StatCPU -iteration 1	
	This Example Displays CPU statistics for all nodes.
	
  .EXAMPLE  
	Get-StatCPU -delay 2  -total -iteration 1	
	This Example Show only the totals for all the CPUs on each node.
	
	  		
  .PARAMETER delay    
	Specifies the interval, in seconds, that statistics are sampled using an integer from 1 through 2147483
	
  .PARAMETER total 
	Show only the totals for all the CPUs on each node.
		
  .PARAMETER Iteration 
	Specifies that CMP statistics are displayed a specified number of times as indicated by the num argument using an integer
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME: Get-StatCPU
    LASTEDIT: November 2019
    KEYWORDS: Get-StatCPU
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$delay,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$total,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Iteration ,
				
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-StatCPU  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-StatCPU  since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-StatCPU since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	
	$cmd= "statcpu "
	
    if($Iteration)
	{
		$cmd+=" -iter $Iteration "
	}
	else
	{
		Write-DebugLog "Stop: Exiting  Get-StatCPU  Iteration in unavailable "
		Return "FAILURE : -Iteration  is Mandatory for Get-StatCPU command to execute. "
	}		
	if($delay)	
	{
		$cmd+=" -d $delay "
	}
	if ($total  )
	{
		$cmd+= " -t "	
	}
		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  Executing  Get-StatCPU command displays Cache Memory Page (CMP) statistics. with the command  " "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -eq "5"){
		return "No data available"
	}		
	if ( $Result.Count -gt 1)
	{
		$flg = "False"
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		Add-Content -Path $tempFile -Value "node,cpu,user,sys,idle,intr/s,ctxt/s,Time,Date"
		foreach ($s in  $Result[0..$LastItem] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")
			$s= [regex]::Replace($s,"---","")
			$s= [regex]::Replace($s,"-","")  
			$a=$s.split(",")
			$c=$a.length
			$b=$a.length
			if ( 2 -eq $b )
			{
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
			}
			if (([string]::IsNullOrEmpty($s)) -or ($s -match "node"))
			{
				continue
			}
			if($c -eq "6")
			{
				$s +=",,$global:time1,$global:date1"
			}
			else
			{
				$s +=",$global:time1,$global:date1"
			}
			if($flg -eq "True")
			{
				Add-Content -Path $tempFile -Value $s	
			}
			$flg = "True"			
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-StatCPU

####################################################################################################################
## FUNCTION Get-StatLD
####################################################################################################################

Function Get-StatLD
{
<#
  .SYNOPSIS
   The Get-StatLD command displays read/write (I/O) statistics about Logical Disks (LDs) in a timed loop.
   
  .DESCRIPTION
   The Get-StatLD command displays read/write (I/O) statistics about Logical Disks (LDs) in a timed loop.
	
  .EXAMPLE
	Get-StatLD -Iteration 1
	This example displays read/write (I/O) statistics about Logical Disks (LDs).
	
  .EXAMPLE
   Get-StatLD -rw -Iteration 1
   This example displays statistics about Logical Disks (LDs).with Specification read/write
   
  .EXAMPLE  
	Get-StatLD -Begin -delay 2 -Iteration 1
	This example displays statistics about Logical Disks (LDs).with Specification begin & delay in execution of 2 sec.	
	
  .EXAMPLE  
	Get-StatLD -Begin -VVname demo1 -Delay 2 -Iteration 1
	This example displays statistics about Logical Disks (LDs) Show only LDs that are mapped to Virtual Volumes (VVs)
	
	
  .EXAMPLE  
	Get-StatLD -begin -LDname demoLD1 -delay 2 -Iteration 1
	This example displays statistics about Logical Disks (LDs).With Only statistics are displayed for the specified LD

  .PARAMETER RW		
	Specifies that reads and writes are displayed separately. If this option is not used, then the total
	of reads plus writes is displayed.
			
  .PARAMETER Begin	
	Specifies that I/O averages are computed from the system start time. If not specified, the average
	is computed since the first iteration of the command.
			
  .PARAMETER IDLEP	
    Specifies the percent of idle columns in the output.
	
  .PARAMETER VVname  
	Show only LDs that are mapped to Virtual Volumes (VVs) with names matching any of names or patterns specified
	
  .PARAMETER LDname  
	Only statistics are displayed for the specified LD or pattern
	
  .PARAMETER Domain
	Shows only LDs that are in domains with names matching any of the names or specified patterns.
	
  .PARAMETER Delay 
	Specifies the interval, in seconds, that statistics are sampled using an integer from 1 through
	2147483.

  .PARAMETER Iteration 
	Specifies that I/O statistics are displayed a specified number of times as indicated by the number
	argument using an integer from 1 through 2147483647.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME: Get-StatLD
    LASTEDIT: November 2019
    KEYWORDS: Get-StatLD
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$RW,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$IDLEP,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Begin,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$NI,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$VVname ,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$LDname,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$Domain,
		
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$Delay,
				
		[Parameter(Position=8, Mandatory=$false)]
		[System.String]
		$Iteration,
				
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-StatLD  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-StatLD since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-StatLD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statld"	
	
	if($Iteration )
	{	
		$cmd+=" -iter $Iteration "	
	}
	else
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "
	}
	if($RW)	
	{
		$cmd +=" -rw "
	}
	if($IDLEP)	
	{
		$cmd+=" -idlep "
	}
	if($Begin)	
	{
		$cmd+=" -begin "
	}
	if($NI)	
	{
		$cmd+=" -ni "
	}
	if($VVname)	
	{
		$ld="showvv"
		$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $ld
		if($Result1 -match $VVname )
		{
			$cmd+=" -vv $VVname "
		}
		else 
		{
			Write-DebugLog "Stop: Exiting  Get-StatLD since -VVname $VVname in unavailable "
			Return "FAILURE : -VVname $VVname is not available .`n Try Using Get-VvList to get all available VV  "
		}
	}
	if($LDname)	
	{
		if($cmd -match "-vv")
		{
			return "Stop: Executing -VVname $VVname and  -LDname $LDname cannot be done in a single Execution "
		}
		$ld="showld"
		$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $ld		
		if($Result1 -match $LDname )
		{
			$cmd+=" $LDname "
		}
		else 
		{
			Write-DebugLog "Stop: Exiting  Get-StatLD since -LDname $LDname in unavailable "
			Return "FAILURE : -LDname $LDname is not available . "
		}
	}	
	if($Domain)	
	{
		$cmd+=" -domain $Domain "
	}	
	if($Delay)	
	{
		$cmd+=" -d $Delay "
	}		
		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing  Get-StatLD command displays read/write (I/O) statistics about Logical Disks (LDs) in a timed loop. with the command  " "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -le "5")
	{
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 1		
		if($IDLEP)	
		{
			Add-Content -Path $tempFile -Value "Ldname,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Idle_Cur,Idle_Avg,Time,Date"
		}
		else 
		{
			Add-Content -Path $tempFile -Value "Ldname,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Time,Date"	
		}
		foreach ($s in  $Result[0..$LastItem] )
		{
		if ($s -match "r/w")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Ldname"))
			{
				continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "11")
			{
				continue
			}
			if (($aa -eq "13") -and ($IDLEP))
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s		
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-StatLD

####################################################################################################################
## FUNCTION Get-StatLink
####################################################################################################################

Function Get-StatLink
{
<#
  .SYNOPSIS
  The Get-StatLink command displays statistics for link utilization for all nodes in a timed loop.
  
  .DESCRIPTION
  The Get-StatLink command displays statistics for link utilization for all nodes in a timed loop.
   
	
  .EXAMPLE
	Get-StatLink -Iteration 1
	This Example displays statistics for link utilization for all nodes in a timed loop.
		
  .EXAMPLE
	Get-StatLink -Interval 3 -Iteration 1 
   This Example displays statistics for link utilization for all nodes in a timed loop, with a delay of 3 sec.
  
  .EXAMPLE
	Get-StatLink -Detail -Iteration 1
  
  .PARAMETER Detail
	Displays detailed information regarding the Queue statistics.	 
  
  .PARAMETER Interval
	Specifies the interval, in seconds, that statistics are sampled using an integer from 1 through
	2147483.

  .PARAMETER Iteration 
	Specifies that I/O statistics are displayed a specified number of times as indicated by the number
	argument using an integer from 1 through 2147483647.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME: Get-StatLink
    LASTEDIT: November 2019
    KEYWORDS: Get-StatLink
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$Detail,
				
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Interval,
				
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Iteration,
				
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Get-StatLink  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-StatLink since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-StatLink since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statlink"
	if($Iteration )
	{
		$cmd+=" -iter $Iteration "
	}
	else
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "
	}
	if ($Detail)
	{
		$cmd+=" -detail "
	}
	if ($Interval)
	{
		$cmd+=" -d $Interval "
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing  Get-StatLink displays statistics for link utilization for all nodes in a timed loop. with the command  " "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -eq "3"){
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		Add-Content -Path $tempFile -Value "Node,Q,ToNode,XCB_Cur,XCB_Avg,XCB_Max,KB_Cur,KB_Avg,KB_Max,XCBSz_KB_Cur,XCBSz_KB_Avg,Time,Date"
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "Local DMA 0")
			{
				$s= [regex]::Replace($s,"Local DMA 0","Local_DMA_0")			
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")
			if ($s -match "XCB_sent_per_second")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if ($s -match "Local DMA 0")
			{
			 $s= [regex]::Replace($s,"Local DMA 0","Local_DMA_0")			
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "ToNode"))
			{
			continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-StatLink

####################################################################################################################
## FUNCTION Get-StatPD
####################################################################################################################

Function Get-StatPD
{
<#
  .SYNOPSIS
   The Get-StatPD command displays the read/write (I/O) statistics for physical disks in a timed loop.
   
 .DESCRIPTION
    The Get-StatPD command displays the read/write (I/O) statistics for physical disks in a timed loop.   
	
  .EXAMPLE
	Get-StatPD -RW –Iteration 1
	This example displays one iteration of I/O statistics for all PDs.
   
  .EXAMPLE  
	Get-StatPD -IDLEP –nodes 2 –Iteration 1
   This example displays one iteration of I/O statistics for all PDs with the specification idlep preference of node 2.
   
  .EXAMPLE  
	Get-StatPD -NI -wwn 1122112211221122 –nodes 2 –Iteration 1
	This Example Specifies that statistics for a particular Physical Disk (PD) identified by World Wide Names (WWNs) and nodes
  
  .PARAMETER Devinfo
	Indicates the device disk type and speed.
	
  .PARAMETER RW
	Specifies that reads and writes are displayed separately. If this option is not used, then the total
	of reads plus writes is displayed.
	
  .PARAMETER Begin
    Specifies that I/O averages are computed from the system start time. If not specified, the average
	is computed since the first iteration of the command.
	
  .PARAMETER IDLEP
   Specifies the percent of idle columns in the output.
	
  .PARAMETER NI
   Specifies that statistics for only non-idle devices are displayed. This option is shorthand for the option				
	
  .PARAMETER wwn 
	Specifies that statistics for a particular Physical Disk (PD) identified by World Wide Names (WWNs) are displayed.
	
  .PARAMETER nodes  
	Specifies that the display is limited to specified nodes and PDs connected to those nodes
		
  .PARAMETER ports   
	Specifies that the display is limited to specified ports and PDs connected to those ports

 .PARAMETER  Iteration
	Specifies that the histogram is to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-StatPD
    LASTEDIT: November 2019
    KEYWORDS: Get-StatPD
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$RW,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$IDLEP,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Begin,
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$NI,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$wwn ,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$nodes,
		
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$slots,
		
		[Parameter(Position=8, Mandatory=$false)]
		[System.String]
		$ports ,
		
		[Parameter(Position=9, Mandatory=$false)]
		[System.String]
		$Iteration ,
		
		[Parameter(Position=10, Mandatory=$false)]
		[switch]
		$DevInfo,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-StatPD   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-StatPD since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-StatPD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "statpd "	
	
	if($Iteration)
	{
		$cmd+=" -iter $Iteration "
	}
	else	
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "
	}
	if($RW)	
	{
		$cmd +=" -rw "
	}
	if($Begin)	
	{
		$cmd+=" -begin "
	}
	if($IDLEP)	
	{
		$cmd+=" -idlep "
	}	
	if($NI)	
	{
		$cmd+=" -ni "
	}
	if($DevInfo)	
	{
		$cmd+=" -devinfo "
	}
	
	if ($wwn)
	{
		$cmd+=" -w $wwn "
	}	
	if ($nodes)
	{
		$cmd+=" -nodes $nodes "
	}	
	if ($slots)
	{
		$cmd+=" -slots $slots "
	}	
	if ($ports )
	{
		$cmd+=" -ports $ports "
	}			
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  Executing Get-StatPD command displays the read/write (I/O) statistics for physical disks in a timed loop. with the command  " "INFO:" 
	$range1 = $Result.count	
	
	if($range1 -eq "4")
	{
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{		
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 3
		if($DevInfo)
		{
			Add-Content -Path $tempFile -Value "ID,Port,Type,K_RPM,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Idle_Cur,Idle_Avg,Time,Date"
		}
		else
		{
			Add-Content -Path $tempFile -Value "ID,Port,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Idle_Cur,Idle_Avg,Time,Date"
		}
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "r/w")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]				
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Port"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "13")
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{		
		return $Result
	}
} # End Get-StatPD

####################################################################################################################
## FUNCTION Get-StatPort
####################################################################################################################
Function Get-StatPort
{
<#
  .SYNOPSIS
   The Get-StatPort command displays read/write (I/O) statistics for ports.
   
 .DESCRIPTION
   The Get-StatPort command displays read/write (I/O) statistics for ports.
	
  .EXAMPLE
	Get-StatPort -Iteration 1
	This example displays one iteration of I/O statistics for all ports.
   
  .EXAMPLE  
	Get-StatPort -Both -Iteration 1
	This example displays one iteration of I/O statistics for all ports,Show data transfers only. 
   
  .EXAMPLE  
	Get-StatPort -Host -nodes 2 -Iteration 1
	This example displays I/O statistics for all ports associated with node 2.
  
  .PARAMETER Both
	Show data transfers only.
	 
  .PARAMETER Ctl
	Show control transfers only.
	 
  .PARAMETER Data
	Show both data and control transfers only.
	 
  .PARAMETER Rcfc
	includes only statistics for Remote Copy over Fibre Channel ports related to cached READ requests
	
  .PARAMETER Rcip
	Includes only statistics for Ethernet configured Remote Copy ports.
	 
  .PARAMETER RW
	Specifies that the display includes separate read and write data.
	 
  .PARAMETER Begin
	Specifies that I/O averages are computed from the system start time
	 
  .PARAMETER Idlep
	Specifies the percent of idle columns in the output.
	 
  .PARAMETER Host
	Displays only host ports (target ports).
	 
  .PARAMETER Disk
	Displays only disk ports (initiator ports).
	 
  .PARAMETER Rcfc
	Displays only Fibre Channel remote-copy configured ports.
	 
  .PARAMETER NI
	Specifies that statistics for only non-idle devices are displayed.
  
  .PARAMETER FS
	Includes only statistics for File Persona ports.

  .PARAMETER Peer
	Specifies to display only host ports (target ports), only disk ports
	(initiator ports), only Fibre Channel Remote Copy configured ports, or
	only Fibre Channel ports for Data Migration.
	If no option is specified, all ports are displayed.
	
  .PARAMETER nodes  
	Specifies that the display is limited to specified nodes and PDs connected to those nodes
		
  .PARAMETER ports   
	Specifies that the display is limited to specified ports and PDs connected to those ports

  .PARAMETER slots
	Specifies that the display is limited to specified PCI slots and
	physical disks connected to those PCI slots. The slot list is specified
	as a series of integers separated by commas (e.g. 1,2,3). The list can
	also consist of a single integer. If the slot list is not specified, all
	disks on all slots are displayed.
	
 .PARAMETER  Iteration
	Specifies that the histogram is to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-StatPort
    LASTEDIT: November 2019
    KEYWORDS: Get-StatPort
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$Both ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$Ctl ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Data ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Rcfc ,
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$Rcip ,
		
		[Parameter(Position=5, Mandatory=$false)]
		[switch]
		$RW ,
		
		[Parameter(Position=6, Mandatory=$false)]
		[switch]
		$FS ,
		
		[Parameter(Position=7, Mandatory=$false)]
		[switch]
		$Host ,
		
		[Parameter(Position=8, Mandatory=$false)]
		[switch]
		$Peer ,
		
		[Parameter(Position=9, Mandatory=$false)]
		[switch]
		$IDLEP,
		
		[Parameter(Position=10, Mandatory=$false)]
		[switch]
		$Begin,
		
		[Parameter(Position=11, Mandatory=$false)]
		[switch]
		$NI,
		
		[Parameter(Position=12, Mandatory=$false)]
		[switch]
		$Disk,
					
		[Parameter(Position=13, Mandatory=$false)]
		[System.String]
		$nodes,
		
		[Parameter(Position=14, Mandatory=$false)]
		[System.String]
		$slots,
		
		[Parameter(Position=15, Mandatory=$false)]
		[System.String]
		$ports ,
		
		[Parameter(Position=16, Mandatory=$false)]
		[System.String]
		$Iteration ,
				
		[Parameter(Position=17, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-StatPort   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-StatPort since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-StatPort since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statport "
	
	if($Iteration)
	{	
		$cmd+=" -iter $Iteration "	
	}
	else	
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "
	}	
	if($Both)	
	{
		$cmd +=" -both "
	}
	if($Ctl)	
	{
		$cmd +=" -ctl "
	}
	if($Data)	
	{
		$cmd +=" -data "
	}
	if($Rcfc)	
	{
		$cmd +=" -rcfc "
	}
	if($Rcip)	
	{
		$cmd +=" -rcip "
	}
	if($FS)	
	{
		$cmd +=" -fs "
	}
	if($Host)	
	{
		$cmd +=" -host "
	}
	if($Disk)	
	{
		$cmd +=" -disk "
	}
	if($Peer)	
	{
		$cmd +=" -peer "
	}	
	if($RW)	
	{
		$cmd +=" -rw "
	}
	if($Begin)	
	{
		$cmd+=" -begin "
	}
	if($IDLEP)	
	{
		$cmd+=" -idlep "
	}	
	if($NI)	
	{
		$cmd+=" -ni "
	}
	if ($nodes)
	{
		$cmd+=" -nodes $nodes "
	}
	if ($slots)
	{
		$cmd+=" -slots $slots "
	}
	if ($ports )
	{
		$cmd+=" -ports $ports "
	}				
		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  Executing Get-StatPort command displays the read/write (I/O) statistics for physical disks in a timed loop. with the command  " "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -eq "4")
	{
		return "No data available"
	}
	if(($Both) -And ($range -eq "6"))
	{
		return "No data available"
	}
		
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count -3
		if($Rcip)
		{
			Add-Content -Path $tempFile -Value "Port,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Errs,Drops,Time,Date"
		}
		elseif ($IDLEP)
		{
			Add-Content -Path $tempFile -Value "Port,D/C,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max, Svt_Cur, Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Idle_Cur,Idle_Avg,Time,Date"
		}
		else
		{
			Add-Content -Path $tempFile -Value "Port,D/C,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max, Svt_Cur, Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Time,Date"
		}	
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "r/w")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Port"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if (($aa -eq "12") -or ($aa -eq "8") -or ($aa -eq "8"))
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}	
	else
	{
		return $Result
	}
} # End Get-StatPort

####################################################################################################################
## FUNCTION Get-StatRcVv
####################################################################################################################

Function Get-StatRcVv
{
<#
	.SYNOPSIS
	The Get-StatRcVv command displays statistics for remote-copy volumes in a timed loop.
   
	.DESCRIPTION
    The Get-StatRcVv command displays statistics for remote-copy volumes in a timed loop.
  
	.EXAMPLE
	Get-StatRcVv -Iteration 1
	This Example displays statistics for remote-copy volumes in a timed loop.
   
	.EXAMPLE
	Get-StatRcVv -Iteration 1 -ASync

	.EXAMPLE
	Get-StatRcVv -Iteration 1 -Sync -VVname $VV

	.EXAMPLE
	Get-StatRcVv -Iteration 1 -TargetSum

	.EXAMPLE
	Get-StatRcVv -Iteration 1 -VVSum   
   
   .EXAMPLE  
	Get-StatRcVv -Iteration 1 -periodic 
	This Example displays statistics for remote-copy volumes in a timed loop and show only volumes that are being copied in asynchronous periodic mode	
   
	.EXAMPLE  
	Get-StatRcVv -target demotarget1  -Iteration 1
	This Example displays statistics for remote-copy volumes in a timed loop and Show only volumes whose group is copied to the specified target name.

  .PARAMETER Async      :  Show only volumes which are being copied in asynchronous mode.
	
  .PARAMETER sync		:	Show only volumes that are being copied in synchronous mode.
	
  .PARAMETER periodic	:	Show only volumes that are being copied in asynchronous periodic mode	
	
  .PARAMETER primary		:	Show only volumes that are in the primary role.
	
  .PARAMETER secondary	:	Show only volumes that are in the secondary role.
	
  .PARAMETER targetsum	:	Specifies that the sums for all volumes of a target are displayed.
	
  .PARAMETER portsum		:	Specifies that the sums for all volumes on a port are displayed.
	
  .PARAMETER groupsum	:	Specifies that the sums for all volumes of a group are displayed.
	
  .PARAMETER vvsum		:	Specifies that the sums for all targets and links of a volume are displayed.
	
  .PARAMETER domainsum	:	Specifies that the sums for all volumes of a domain are displayed.
	
  .PARAMETER ni			:	Specifies that statistics for only non-idle devices are displayed.
	
  .PARAMETER target   
	Show only volumes whose group is copied to the specified target name.
	
  .PARAMETER port    
	Show only volumes that are copied over the specified port or pattern.
	
  .PARAMETER group 
	Show only volumes whose group matches the specified group name or pattern.
	
  .PARAMETER VVname	
	Displays statistics only for the specified virtual volume or volume name pattern.
	
 .PARAMETER  Iteration
	Specifies that the histogram is to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
	
 .PARAMETER DomainName
	Shows only the virtual volumes that are in domains with names that match
	the specified domain name(s) or pattern(s).	
		
 .PARAMETER Interval
	Specifies the interval in seconds that statistics are sampled from
	using an integer from 1 through 2147483. If no count is specified, the
	command defaults to 2 seconds.
	
 .PARAMETER Subset
	Show subset statistics for Asynchronous Remote Copy on a per group basis.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-StatRcVv
    LASTEDIT: November 2019
    KEYWORDS: Get-StatRcVv
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Iteration ,		
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Interval ,	
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Target ,
						
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Port,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Group ,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$VVname  ,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$DomainName  ,

		[Parameter(Position=7, Mandatory=$false)]
		[switch]
		$ASync,
		
		[Parameter(Position=8, Mandatory=$false)]
		[switch]
		$Sync,
		
		[Parameter(Position=9, Mandatory=$false)]
		[switch]
		$Periodic,
		
		[Parameter(Position=10, Mandatory=$false)]
		[switch]
		$Primary,
		
		[Parameter(Position=11, Mandatory=$false)]
		[switch]
		$Secondary,
		
		[Parameter(Position=12, Mandatory=$false)]
		[switch]
		$TargetSum,
		
		[Parameter(Position=13, Mandatory=$false)]
		[switch]
		$PortSum,
		
		[Parameter(Position=14, Mandatory=$false)]
		[switch]
		$GroupSum,
		
		[Parameter(Position=15, Mandatory=$false)]
		[switch]
		$VVSum,
		
		[Parameter(Position=16, Mandatory=$false)]
		[switch]
		$DomainSum,
		
		[Parameter(Position=17, Mandatory=$false)]
		[switch]
		$NI,
		
		[Parameter(Position=18, Mandatory=$false)]
		[switch]
		$SubSet,
				
		[Parameter(Position=19, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-StatRcVv   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-StatRcVv since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-StatRcVv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statrcvv "	
	
	if($Iteration)
	{
		$cmd+=" -iter $Iteration "
	}
	else
	{
		Write-DebugLog "Stop: Exiting  Get-StatRcVv  Iteration in unavailable "
		Return "FAILURE : -Iteration  is Mandatory for Get-StatRcVv command to execute. "
	}
	if ($Interval)
	{
		$cmd+=" -d $Interval"
	}	
	if ($Target)
	{
		$cmd+=" -t $Target"
	}	
	if ($Port)
	{
		$cmd+=" -port $Port "
	}
	if ($Group)
	{
		$cmd+=" -g $Group"
	}
	if($ASync)	
	{
		$cmd += " -async "
	}
	if($Sync)	
	{
		$cmd += " -sync "
	}
	if($Periodic)	
	{
		$cmd += " -periodic "
	}
	if($Primary)	
	{
		$cmd += " -primary "
	}
	if($Secondary)	
	{
		$cmd += " -secondary "
	}
	if($TargetSum)	
	{
		$cmd += " -targetsum "
	}
	if($PortSum)	
	{
		$cmd += " -portsum "
	}
	if($GroupSum)	
	{
		$cmd += " -groupsum "
	}
	if($VVSum)	
	{
		$cmd += " -vvsum "
	}
	if($DomainSum)	
	{
		$cmd += " -domainsum "
	}
	if($DomainName)	
	{
		$cmd += " -domain $DomainName "
	}
	if($NI)	
	{
		$cmd += " -ni "
	}
	if($SubSet)	
	{
		$cmd += " -subset "
	}
	if ($VVname)
	{
		$s= Get-Vv -vvName  $VVname
		if ($s -match $VVname )
		{
			$cmd+=" $VVname"
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Get-StatRcVv  VVname in unavailable "
			Return "FAILURE : -VVname $VVname  is Unavailable to execute. "
		}		
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing Get-StatRcVv command displays statistics for remote-copy volumes in a timed loop. with the command  " "INFO:" 
	$range1 = $Result.count
	
	if($range1 -eq "4")
	{
		return "No data available"
	}
	if( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 2
		
		if($TargetSum)
		{
			Add-Content -Path $tempFile -Value "Target,Mode,I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg,Time,Date"		
		}
		elseif ($PortSum)
		{
			Add-Content -Path $tempFile -Value "Link,Target,Type,I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg,Time,Date"
		}
		elseif ($GroupSum)
		{
			Add-Content -Path $tempFile -Value "Group,Target,Mode,I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg,Time,Date"
		}
		elseif ($VVSum)
		{
			Add-Content -Path $tempFile -Value "VVname,RCGroup,Target,Mode,I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg,Time,Date"
		}
		elseif ($DomainSum)
		{
			Add-Content -Path $tempFile -Value "Domain,I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg,Time,Date"
		}
		else 
		{		
			Add-Content -Path $tempFile -Value "VVname,RCGroup,Target,Mode,Port,Type,I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg,Time,Date"
		}
		foreach ($s in  $Result[0..$LastItem] )
		{
			$s= [regex]::Replace($s,"^ +","")
			#$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			if ($s -match "I/O")
			{
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if (($s -match "-------") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Avg"))
			{
			continue
			}
			$aa=$s.split(",").length
			if ($aa -eq "11")
			{
				continue
			}			
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s		
			#$s= $s.Trim() -replace 'Cur,Avg,Max,Cur,Avg,Max,Cur,Avg,Cur,Avg,Cur,Avg','I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg' 	
			#Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
	
} # End Get-StatRcVv

####################################################################################################################
## FUNCTION Get-StatVLun
####################################################################################################################
Function Get-StatVLun
{
<#
  .SYNOPSIS
   The Get-StatVLun command displays statistics for Virtual Volumes (VVs) and Logical Unit Number (LUN) host attachments.
   
  .DESCRIPTION
   The Get-StatVLun command displays statistics for Virtual Volumes (VVs) and Logical Unit Number (LUN) host attachments.
   
  .EXAMPLE
	Get-StatVLun -Iteration 1
	This example displays statistics for Virtual Volumes (VVs) and Logical Unit Number (LUN) host attachments.
   
  .EXAMPLE  
	Get-StatVLun -vvSum -Iteration 1
	This example displays statistics for Virtual Volumes (VVs) and Specifies that sums for VLUNs of the same VV are displayed.
	
  .EXAMPLE  
	Get-StatVLun -vvSum -RW -Iteration 1
	
  .EXAMPLE  
	Get-StatVLun -vvSum -RW -VVname xxx -Iteration 1
   
  .EXAMPLE  
	Get-StatVLun -VVname demovv1 -Iteration 1
	This example displays statistics for Virtual Volumes (VVs) and only Logical Disks (LDs) mapped to VVs that match any of the specified names to be displayed.
 				
  .PARAMETER LW  		:	Lists the host’s World Wide Name (WWN) or iSCSI names.
			
  .PARAMETER Domainsum 	:	Specifies that sums for VLUNs are grouped by domain in the display.
	
  .PARAMETER vvSum 		:	Specifies that sums for VLUNs of the same VV are displayed.
	
  .PARAMETER Hostsum  	:	Specifies that sums for VLUNs are grouped by host in the display.
	
  .PARAMETER RW 			:	Specifies reads and writes to be displayed separately.
	
  .PARAMETER Begin		:	Specifies that I/O averages are computed from the system start time.
	
  .PARAMETER IDLEP  		:	Includes a percent idle columns in the output.
	
  .PARAMETER NI			:	Specifies that statistics for only nonidle devices are displayed.
	
  .PARAMETER domian    
	Shows only Virtual Volume Logical Unit Number (VLUNs) whose VVs are in domains with names that match one or more of the specified domain names or patterns.
	
  .PARAMETER VVname     
	Requests that only Logical Disks (LDs) mapped to VVs that match any of the specified names to be displayed.
	
  .PARAMETER LUN  
	Specifies that VLUNs with LUNs matching the specified LUN(s) or pattern(s) are displayed.
	
  .PARAMETER nodes
	Specifies that the display is limited to specified nodes and Physical Disks (PDs) connected to those
	nodes.
	
  .PARAMETER  Iteration
	Specifies that the histogram is to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-StatVLun
    LASTEDIT: November 2019
    KEYWORDS: Get-StatVLun
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$RW,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$IDLEP,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Begin,
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$NI, 
		
		[Parameter(Position=5, Mandatory=$false)]
		[switch]
		$LW,
		
		[Parameter(Position=6, Mandatory=$false)]
		[switch]
		$DomainSum,
		
		[Parameter(Position=7, Mandatory=$false)]
		[switch]
		$vvSum,
		
		[Parameter(Position=8, Mandatory=$false)]
		[switch]
		$HostSum,
		
		[Parameter(Position=9, Mandatory=$false)]
		[System.String]
		$domian  ,
						
		[Parameter(Position=10, Mandatory=$false)]
		[System.String]
		$VVname ,
		
		[Parameter(Position=11, Mandatory=$false)]
		[System.String]
		$LUN ,
		
		[Parameter(Position=12, Mandatory=$false)]
		[System.String]
		$nodes,
		
		[Parameter(Position=13, Mandatory=$false)]
		[System.String]
		$Iteration ,
				
		[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-StatVLun  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-StatVLun since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-StatVLun since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statvlun "
	if($Iteration)
	{	
		$cmd+=" -iter $Iteration "	
	}
	else	
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "
	}	
	
	if($RW)	
	{
		$cmd +=" -rw "
	}
	if($Begin)	
	{
		$cmd+=" -begin "
	}
	if($IDLEP)	
	{
		$cmd+=" -idlep "
	}	
	if($NI)	
	{
		$cmd+=" -ni "
	}	
	if($LW)	
	{
		$cmd +=" -lw "
	}
	if($DomainSum)	
	{
		$cmd+=" -domainsum "
	}
	if($vvSum)	
	{
		$cmd+=" -vvsum "
	}	
	if($HostSum)	
	{
		$cmd+=" -hostsum "
	}
	if ($domian)
	{
		$cmd+=" -domain $domian"
	}	
	if ($VVname)
	{
		$s= Get-Vv -vvName  $VVname
		if ($s -match $VVname )
		{
			$cmd+=" -v $VVname"
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Get-StatVLun  VVname in unavailable "
			Return "FAILURE : -VVname $VVname  is Unavailable to execute. "
		}		
	}
	if ($LUN)
	{
		$cmd+=" -l $LUN"
	}	
	if ($nodes)
	{
		$cmd+=" -nodes $nodes"
	}				
		
	#write-host " $cmd"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing Get-StatVLun command command displays statistics for Virtual Volumes (VVs) and Logical Unit Number (LUN) host attachments. with the command  " "INFO:"
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -eq "4")
	{
		return "No data available"
	}	
	if(($range1 -eq "6") -and ($NI))
	{
		return "No data available"
	}
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 3
		if($LW)
		{	
			Add-Content -Path $tempFile -Value "Lun,VVname,Host,Port,Host_WWN/iSCSI_Name,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date"
		}
		elseif($DomainSum)
		{
			Add-Content -Path $tempFile -Value "Domain,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date" 
		}
		elseif($vvSum)
		{
			Add-Content -Path $tempFile -Value "VVname,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date"
		}
		elseif($RW)
		{
			Add-Content -Path $tempFile -Value "Lun,VVname,Host,Port,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date"
		}
		elseif($Begin)
		{
			Add-Content -Path $tempFile -Value "Lun,VVname,Host,Port,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date"
		}
		elseif($IDLEP)
		{ #IOSz
			Add-Content -Path $tempFile -Value "Lun,VVname,Host,Port,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,IOSz_Cur,IOSz_Avg,Time,Date"
		}
		elseif($NI)
		{
			Add-Content -Path $tempFile -Value "Lun,VVname,Host,Port,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date"
		}
		elseif($HostSum)
		{
			Add-Content -Path $tempFile -Value "Hostname,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date"
		}
		else
		{
			Add-Content -Path $tempFile -Value "Lun,VVname,Host,Port,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date" 
		}
		foreach ($s in  $Result[0..$LastItem] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")	
			if ($s -match "r/w")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "cur"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "11")
			{
				continue
			}
			if (($aa -eq "13") -And ($IDLEP))
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-StatVLun

####################################################################################################################
## FUNCTION Get-StatVv
####################################################################################################################

Function Get-StatVv
{
<#
  .SYNOPSIS
   The Get-StatVv command displays statistics for Virtual Volumes (VVs) in a timed loop.
   
  .DESCRIPTION
	The Get-StatVv command displays statistics for Virtual Volumes (VVs) in a timed loop.
   
  .EXAMPLE
	Get-StatVv -Iteration 1
   This Example displays statistics for Virtual Volumes (VVs) in a timed loop.
   
   
  .EXAMPLE  
	Get-StatVv -RW -Iteration 1
   This Example displays statistics for Virtual Volumes (VVs) with specification of read/write option.
   
  .EXAMPLE  
	Get-StatVv -Delay -Seconds 2 -Iteration 1
	Specifies the interval in seconds that statistics are sampled from using an integer from 1 through 2147483.
	
  .EXAMPLE  
	Get-StatVv -RW -domain ZZZ -VVname demovv1 -Iteration 1
	This Example displays statistics for Virtual Volumes (VVs) with Only statistics are displayed for the specified VVname.			

  .PARAMETER RW :	Specifies reads and writes to be displayed separately.
 
  .PARAMETER Delay  : <Seconds> Specifies the interval in seconds that statistics are sampled from using an integer from 1 through 2147483. If no count is specified, the
						 command defaults to 2 seconds.
		
  .PARAMETER NI : Specifies that statistics for only non-idle devices are displayed. This option is shorthand for the option -filt curs,t,iops,0.
	
  .PARAMETER domian    
	Shows only Virtual Volume Logical Unit Number (VLUNs) whose VVs are in domains with names that match one or more of the specified domain names or patterns.
	
  .PARAMETER  Iteration
	Specifies that the histogram is to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
	
  .PARAMETER  VVname
	Only statistics are displayed for the specified VV.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-StatVv
    LASTEDIT: November 2019
    KEYWORDS: Get-StatVv
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$RW ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$NI ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Delay  ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$domian  ,
					
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$VVname ,	
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Iteration ,
				
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Get-StatVv  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-StatVv since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-StatVv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "statvv "
	if($Iteration)
	{
		$cmd+=" -iter $Iteration "	
	}
	else	
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "
	}	
	
	if ($RW)
	{
		$cmd+=" -rw "
	}
	if ($Delay)
	{
		$cmd+=" -d $Delay "
	}
	if ($NI)
	{
		$cmd+=" -ni "
	}
	if ($domian)
	{
		$cmd+=" -domain $domian"
	}			
	if ($VVname)
	{
		$cmd+="  $VVname"
	}	
		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  Executing The Get-StatVv command displays statistics for Virtual Volumes (VVs) in a timed loop. with the command  " "INFO:" 
	$range1 = $Result.count
	if($range1 -eq "4")
	{
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		Add-Content -Path $tempFile -Value "VVname,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Time,Date"
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "r/w")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "VVname"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "11")
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile	
		del $tempFile
	}
	else
	{
		return $Result
	}	
} # End Get-StatVv

####################################################################################################################
## FUNCTION Set-Statch
####################################################################################################################
Function Set-Statch
{
<#
  .SYNOPSIS
    The Set-Statch command sets the statistics collection mode for all in-use chunklets on a Physical Disk (PD).
  
  .DESCRIPTION
   The Set-Statch command sets the statistics collection mode for all in-use chunklets on a Physical Disk (PD).
  
  .EXAMPLE 
	Set-Statch -Start -LDname test1 -CLnum 1  
	This example starts and stops the statistics collection mode for chunklets.with the LD name test1.
	
  .PARAMETER Start  
    Specifies that the collection of statistics is either started or stopped for the specified Logical Disk
	(LD) and chunklet.
	
  .PARAMETER Stop  
    Specifies that the collection of statistics is either started or stopped for the specified Logical Disk
	(LD) and chunklet.
	
  .PARAMETER LDname 	
	Specifies the name of the logical disk in which the chunklet to be configured resides.
	
  .PARAMETER CLnum 	
	Specifies the chunklet that is configured using the setstatch command.	
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Set-Statch
    LASTEDIT: November 2019
    KEYWORDS: Set-Statch
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$Start,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$Stop,
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$LDname,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$CLnum,	
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Set-Statch   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Set-Statch since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Set-Statchsince no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	
	$cmd1 = "setstatch "
	if ($Start)
	{
		$cmd1 += " start "
	}
	if ($Stop)
	{
		$cmd1 += " stop "
	}
	
	if($LDname)
	{
		$cmd2="showld"
		$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd2
		if($Result1 -match $LDname)
		{
			$cmd1 += " $LDname "
		}
		Else
		{
			write-debuglog "LDname parameter is Unavailable. Simply return " "INFO:"
			return "Error:  LDname  is Invalid ."
		}
	}
	else
	{
		write-debuglog "-LDname parameter  is empty. Simply return " "INFO:"
		return "Error: -LDname parameter  is mandatory ."
	}
	if($CLnum)
	{
		$cmd1+="$CLnum"
	}
	else	
	{
		write-debuglog "-CLnum parameter is Unavailable. Simply return " "INFO:"
		return "Error: -CLnum parameter  is mandatory ."
	}	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd1
	write-debuglog "   The Set-Statch command sets the statistics collection mode for all in-use chunklets on a Physical Disk (PD).->$cmd" "INFO:"
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Set-Statch $Result "
	}
	else
	{
		return  "FAILURE : While Executing Set-Statch $Result"
	} 
} # End Set-Statch

####################################################################################################################
## FUNCTION Set-StatPdch
#####################################################################################################################

Function Set-StatPdch
{
<#
  .SYNOPSIS
    The Set-StatPdch command starts and stops the statistics collection mode for chunklets.

  .DESCRIPTION
    The Set-StatPdch command starts and stops the statistics collection mode for chunklets.
 
  .EXAMPLE
   Set-StatPdch -Start -PD_ID 2
   This Example sets the statistics collection mode for all in-use chunklets on a Physical Disk (PD) 2.

  
  .PARAMETER Start  
    Specifies that the collection of statistics is either started or stopped for the specified Logical Disk
	(LD) and chunklet.
	
  .PARAMETER Stop  
    Specifies that the collection of statistics is either started or stopped for the specified Logical Disk
	(LD) and chunklet.
	
  .PARAMETER PD_ID   
    Specifies the PD ID.

	 .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Set-StatPdch
    LASTEDIT: November 2019
    KEYWORDS: Set-StatPdch
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[switch]
		$Start,
		
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[switch]
		$Stop,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$PD_ID,		
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)			
	Write-DebugLog "Start: In Set-StatPdch   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Set-StatPdch since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Set-StatPdchsince no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd1 = "setstatpdch "
	if ($Start)
	{
		$cmd1 += " start "
	}
	if ($Stop)
	{
		$cmd1 += " stop "
	}
	if($PD_ID)
	{
		$cmd2="showpd"
		$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd2
		if($Result1 -match $PD_ID)
		{
			$cmd1 += " $PD_ID "
		}
		Else
		{
			write-debuglog "PD_ID parameter $PD_ID is Unavailable. Simply return " "INFO:"
			return "Error:  PD_ID   is Invalid ."
		}		
	}
	else
	{
		write-debuglog "PD_ID parameter $PD_ID is empty. Simply return " "INFO:"
		return "Error : PD_ID is mandatory . Command is not successful "
	}
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd1
	write-debuglog "  The Set-StatPdch command starts and stops the statistics collection mode for chunklets.->$cmd" "INFO:"
	if([string]::IsNullOrEmpty($Result))
	{
		$Result
		return  "Success : Executing Set-StatPdch 	 "
	}
	else
	{
		$Result
		return  "FAILURE : While Executing Set-StatPdch 	"
	} 
} # End Set-StatPdch

##########################################################################
#########################  FUNCTION Measure-SYS #########################
##########################################################################
Function Measure-SYS()
{
<#
  .SYNOPSIS
   Measure-SYS - Change the layout of a storage system.

  .DESCRIPTION
   The Measure-SYS command is used to analyze and detect poor layout
   and disk utilization across an entire storage system. The
   command runs a series of low level operations to re-balance
   resources on the system.

  .EXAMPLE
   Inter-node tuning options:

  .PARAMETER Cpg
   Limits the scope of a Measure-SYS operation to the named CPG(s).
   The specified CPGs must all be in the same domain as the user.
   If this option is specified the intra-node (tunenodech) phase is
   not run. -chunkpct and -tunenodech cannot be used with this
   option.

  .PARAMETER Nodepct
   Controls the detection of utilization imbalances between nodes.
   If any node has a PD devtype where the average utilization is
   more than <percentage> less than the average for that devtype,
   then detailed VV level analysis is performed. VVs which are
   poorly balanced between nodes will have a tune generated to
   correct the imbalance. <percentage> must be between 1 and 100.
   The default value is 3.

  .PARAMETER Spindlepct
   Specifies the percentage difference between node pairs that can
   exist before Measure-SYS warns that an imbalance exists. The percentage
   difference calculated between node pairs must be less than
   spindlepct. <percentage> must be between 1 and 200. 200 is the
   least restrictive and would allow the Measure-SYS to not warn with
   any difference in the number of PDs, while 1 is the most
   restrictive. 0 cannot be specified as this would always generate
   a warning. The default for <percentage> is 50 (allow for a 50%
   difference).

  .PARAMETER Force
   Bypass top-level inter-node balance checks and force detailed
   analysis of every VV. This option can be used to complete the
   re-balance of a relatively well balanced system where only a few
   volumes are unbalanced.

  .PARAMETER Slth
   Slice threshold. Volumes above this size will be tuned in slices.
   <threshold> must be in multiples of 128GiB. Minimum is 128GiB.
   Default is 2TiB. Maximum is 16TiB.

  .PARAMETER Slsz
   Slice size. Size of slice to use when volume size is greater than
   <threshold>. <size> must be in multiples of 128GiB. Minimum is 128GiB.
   Default is 2TiB. Maximum is 16TiB.
   
   Intra-node tuning options:

  .PARAMETER Chunkpct
   Controls the detection of any imbalance in PD chunklet
   allocation between PDs owned by individual nodes. If a PD has
   utilization of more than <percentage> less than the average for
   that device type, then that disk can potentially be tuned.
   <percentage> must be between 1 and 100. The default value is 10.
   This option cannot be used with the -cpg option.

  .PARAMETER Devtype
   Only tune the specified device type. Applies to the intra-node tune
   phase only and must be used with the -tunenodech option. Multiple
   devtypes can be specified. If -devtype is not used, all devtypes
   will be tuned when -tunenodech is specified.

  .PARAMETER Fulldiskpct
   This option is used in the intra-node tuning phase.
   If a PD has more than <percentage> of its capacity utilized, chunklet
   movement is used to reduce its usage to <percentage> before LD tuning
   is used to complete the rebalance. For example, if a PD is 98% utilized
   and <percentage> is 90, chunklets will be redistributed to other PDs until
   the utilization is less than 90%. If <percentage> is less than the
   devtype average then the calculated average will be used instead.
   <percentage> must be between 1 and 100. The default value is 90.

  .PARAMETER Maxchunk
   Specifies the maximum number of chunklets which can be moved
   from any PD in a single operation. <number> must be between
   1 and 8. The default value is 8.

  .PARAMETER Tunenodech
   Specifies that only intra-node rebalancing should be performed.
   
   LD tuning options:

  .PARAMETER Ss
   Trigger LD re-tuning for any LD where the stepsize value
   does not match the parent CPG.
   
   Cleaning and compacting options:

  .PARAMETER Cleanwait
   Maximum number of minutes to wait for chunklet cleaning after each tune.
   <value> must be between 0 (tunes will be started immediately) and
   720 (12 hours). The default value is 120 (2 hours).

  .PARAMETER Compactmb
   Used in the inter-node and LD tuning phases. Once tunes have moved an
   amount of space greater than <value> the source CPG will be compacted.
   <value> can be between 0 (compact after every tune) and 2TiB. The default
   is 512GiB.
   
   General tuning options:

  .PARAMETER Dr
   Specifies that the command is a dry run and that the system will
   not be tuned. The result of the analysis will be displayed.

  .PARAMETER Maxtasks
   Specifies the maximum number of individual inter-node tune tasks
   which the Measure-SYS command can run simultaneously. <number> must
   be between 1 and 8. The default value is 2.

  .PARAMETER Maxnodetasks
   Specifies the maximum number of tunenodech tasks which the Measure-SYS
   command can run simultaneously. <number> must be between 1 and 8.
   The default value is 1.

  .PARAMETER Waittask
   Wait for all tasks created by this command to complete before
   returning.

  .Notes
    NAME: Measure-SYS
    LASTEDIT January 2020
    KEYWORDS: Measure-SYS
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[System.String]
	$Cpg,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Nodepct,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Spindlepct,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Force,

	[Parameter(Position=4, Mandatory=$false)]
	[System.String]
	$Slth,

	[Parameter(Position=5, Mandatory=$false)]
	[System.String]
	$Slsz,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$Chunkpct,

	[Parameter(Position=7, Mandatory=$false)]
	[System.String]
	$Devtype,

	[Parameter(Position=8, Mandatory=$false)]
	[System.String]
	$Fulldiskpct,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$Maxchunk,

	[Parameter(Position=10, Mandatory=$false)]
	[switch]
	$Tunenodech,

	[Parameter(Position=11, Mandatory=$false)]
	[switch]
	$Ss,

	[Parameter(Position=12, Mandatory=$false)]
	[System.String]
	$Cleanwait,

	[Parameter(Position=13, Mandatory=$false)]
	[System.String]
	$Compactmb,

	[Parameter(Position=14, Mandatory=$false)]
	[switch]
	$Dr,

	[Parameter(Position=15, Mandatory=$false)]
	[System.String]
	$Maxtasks,

	[Parameter(Position=16, Mandatory=$false)]
	[System.String]
	$Maxnodetasks,

	[Parameter(Position=17, Mandatory=$false)]
	[switch]
	$Waittask,

	[Parameter(Position=18, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Measure-SYS - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Measure-SYS since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Measure-SYS since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " tunesys -f "

 if($Cpg)
 {
	$Cmd += " -cpg $Cpg "
 }

 if($Nodepct)
 {
	$Cmd += " -nodepct $Nodepct "
 }

 if($Spindlepct)
 {
	$Cmd += " -spindlepct $Spindlepct "
 }

 if($Force)
 {
	$Cmd += " -force "
 }

 if($Slth)
 {
	$Cmd += " -slth $Slth "
 }

 if($Slsz)
 {
	$Cmd += " -slsz $Slsz "
 }

 if($Chunkpct)
 {
	$Cmd += " -chunkpct $Chunkpct "
 }

 if($Devtype)
 {
	$Cmd += " -devtype $Devtype "
 }

 if($Fulldiskpct)
 {
	$Cmd += " -fulldiskpct $Fulldiskpct "
 }

 if($Maxchunk)
 {
	$Cmd += " -maxchunk $Maxchunk "
 }

 if($Tunenodech)
 {
	$Cmd += " -tunenodech "
 }

 if($Ss)
 {
	$Cmd += " -ss "
 }

 if($Cleanwait)
 {
	$Cmd += " -cleanwait $Cleanwait "
 }

 if($Compactmb)
 {
	$Cmd += " -compactmb $Compactmb "
 }

 if($Dr)
 {
	$Cmd += " -dr "
 }

 if($Maxtasks)
 {
	$Cmd += " -maxtasks $Maxtasks "
 }

 if($Maxnodetasks)
 {
	$Cmd += " -maxnodetasks $Maxnodetasks "
 }

 if($Waittask)
 {
	$Cmd += " -waittask "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Measure-SYS Command -->" INFO: 
 
 Return $Result
} ##  End-of Measure-SYS

##########################################################################
######################### FUNCTION Optimize-PD #######################
##########################################################################
Function Optimize-PD()
{
<#
  .SYNOPSIS
   Optimize-PD - show physical disks with high service times and optionally perform
   load balancing.

  .DESCRIPTION
   The Optimize-PD command identifies physical disks with high service times and
   optionally executes load balancing.

  .EXAMPLE
  
  .PARAMETER MaxSvct
	Specifies that either the maximum service time threshold (<msecs>) that
	is used to discover over-utilized physical disks, or the physical disks
	that have the highest maximum service times (highest). If a threshold is
	specified, then any disk whose maximum service time exceeds the
	specified threshold is considered a candidate for load balancing.
 
  .PARAMETER AvgSvct
	Specifies that either the average service time threshold (<msecs>) that
	is used to discover over-utilized physical disks, or the physical disks
	that have the highest average service time (highest). If a threshold is
	specified, any disk whose average service time exceeds the specified
	threshold is considered a candidate for load balancing.

  .PARAMETER Nodes
   Specifies that the display is limited to specified nodes and physical
   disks connected to those nodes. The node list is specified as a series
   of integers separated by commas (e.g. 1,2,3). The list can also consist
   of a single integer. If the node list is not specified, all disks on all
   nodes are displayed.

  .PARAMETER Slots
   Specifies that the display is limited to specified PCI slots and
   physical disks connected to those PCI slots. The slot list is specified
   as a series of integers separated by commas (e.g. 1,2,3). The list can
   also consist of a single integer. If the slot list is not specified, all
   disks on all slots are displayed.

  .PARAMETER Ports
   Specifies that the display is limited to specified ports and
   physical disks connected to those ports. The port list is specified
   as a series of integers separated by commas (e.g. 1,2,3). The list can
   also consist of a single integer. If the port list is not specified, all
   disks on all ports are displayed.

  .PARAMETER VV_Name
   Specifies that the physical disks used by the indicated virtual volume
   name are included for statistic sampling.

  .PARAMETER D
   Specifies the interval, in seconds, that statistics are sampled using an
   integer from 1 through 2147483. If no interval is specified, the option
   defaults to 30 seconds.

  .PARAMETER Iter
   Specifies that I/O statistics are sampled a specified number of times as
   indicated by the number argument using an integer greater than 0. If 0
   is specified, I/O statistics are looped indefinitely. If this option is
   not specified, the command defaults to 1 iteration.

  .PARAMETER Freq
   Specifies the interval, in minutes, that the command enters standby mode
   between iterations using an integer greater than 0. If this option is
   not specified, the number of iterations is looped indefinitely.

  .PARAMETER Vvlayout
   Specifies that the layout of the virtual volume is displayed. If this
   option is not specified, the layout of the virtual volume is not
   displayed.

  .PARAMETER Portstat
   Specifies that statistics for all disk ports in the system are
   displayed. If this option is not specified, statistics for ports are not
   displayed.

  .PARAMETER Pdstat
   Specifies that statistics for all physical disk, rather than only those
   with high service times, are displayed. If this option is not specified,
   statistics for all disks are not displayed.

  .PARAMETER Chstat
   Specifies that chunklet statistics are displayed. If not specified,
   chunklet statistics are not displayed. If this option is used with the

  .PARAMETER Maxpd
   Specifies that only the indicated number of physical disks with high
   service times are displayed. If this option is not specified, 10
   physical disks are displayed.

  .PARAMETER Movech_Auto
   Specifies that if any disks with unbalanced loads are detected that
   chunklets are moved from those disks for load balancing.
   auto
   Specifies that the system chooses source and destination chunklets.
   If not specified, you are prompted for selecting the source and
   destination chunklets.   
   
  .PARAMETER Movech_Manual
   Specifies that if any disks with unbalanced loads are detected that
   chunklets are moved from those disks for load balancing.
   manual
   Specifies that the source and destination chunklets are manually
   entered.

  .Notes
    NAME: Optimize-PD
    LASTEDIT January 2020
    KEYWORDS: Optimize-PD
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[System.String]
	$Nodes,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Slots,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Ports,

	[Parameter(Position=3, Mandatory=$false)]
	[System.String]
	$VV_Name,

	[Parameter(Position=4, Mandatory=$false)]
	[System.String]
	$D,

	[Parameter(Position=5, Mandatory=$false)]
	[System.String]
	$Iter,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$Freq,

	[Parameter(Position=7, Mandatory=$false)]
	[switch]
	$Vvlayout,

	[Parameter(Position=8, Mandatory=$false)]
	[switch]
	$Portstat,

	[Parameter(Position=9, Mandatory=$false)]
	[switch]
	$Pdstat,

	[Parameter(Position=10, Mandatory=$false)]
	[switch]
	$Chstat,

	[Parameter(Position=12, Mandatory=$false)]
	[System.String]
	$Maxpd,

	[Parameter(Position=13, Mandatory=$false)]
	[switch]
	$Movech_Auto,

	[Parameter(Position=14, Mandatory=$false)]
	[switch]
	$Movech_Manual,

	[Parameter(Position=15, Mandatory=$false)]
	[System.String]
	$MaxSvct,

	[Parameter(Position=16, Mandatory=$false)]
	[System.String]
	$AvgSvct,

	[Parameter(Position=17, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Optimize-PD - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Optimize-PD since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Optimize-PD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " tunepd "
 
 if($Nodes)
 {
	$Cmd += " -nodes $Nodes "
 }
 
 if($Slots)
 {
	$Cmd += " -slots $Slots "
 }
 
 if($Ports)
 {
	$Cmd += " -ports $Ports "
 }
 
 if($VV_Name)
 {
	$Cmd += " -vv $VV_Name "
 }
 
 if($D)
 {
	$Cmd += " -d $D "
 }
 
 if($Iter)
 {
	$Cmd += " -iter $Iter "
 }
 
 if($Freq)
 {
	$Cmd += " -freq $Freq "
 }
 
 if($Vvlayout)
 {
	$Cmd += " -vvlayout "
 }
 
 if($Portstat)
 {
	$Cmd += " -portstat"
 }
 
 if($Pdstat)
 {
	$Cmd += " -pdstat"
 }
 
 if($Chstat)
 {
	$Cmd += " -chstat"
 }
 
 if($Maxpd)
 {
	$Cmd += " -maxpd $Maxpd "
 }
 
 if($Movech_Auto)
 {
	$Cmd += " -movech auto "
 }
 
 if($Movech_Manual)
 {
	$Cmd += " -movech manual "
 } 
 
 if($MaxSvct)
 {
	$Cmd += " maxSvct $MaxSvct "
 } 
 elseif($AvgSvct)
 {
	$Cmd += " avgsvct $AvgSvct "
 }
 else
 {
	return	"Please select at list one from [ MaxSvct or AvgSvct]."
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Optimize-PD Command -->" INFO: 
 
 Return $Result
} ##  End-of Optimize-PD

Export-ModuleMember Compress-VV , Get-HistChunklet , Get-HistLD , Get-HistPD , Get-HistPort , Get-HistRCopyVv , Get-HistVLun ,
Get-HistVv , Get-StatChunklet , Get-StatCMP , Get-StatCPU , Get-StatLD , Get-StatLink , Get-StatPD , Get-StatPort , Get-StatRcVv , 
Get-StatVLun , Get-StatVv , Set-Statch , Set-StatPdch , Measure-SYS , Optimize-PD