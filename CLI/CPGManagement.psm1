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
##	File Name:		CPGManagement.psm1
##	Description: 	CPG Management cmdlets 
##		
##	Created:		October 2019
##	Last Modified:	May 2021
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

#####################################################################################################################
## FUNCTION Get-CPG
#####################################################################################################################

Function Get-CPG
{
<#
  .SYNOPSIS
    Get list of common provisioning groups (CPGs) in the system.
  
  .DESCRIPTION
    Get list of common provisioning groups (CPGs) in the system.
        
  .EXAMPLE
    Get-CPG
	List all/specified common provisioning groups (CPGs) in the system.  
  
  .EXAMPLE
	Get-CPG -cpgName "MyCPG" 
	List Specified CPG name "MyCPG"
	
  .EXAMPLE
	Get-CPG -Detailed -cpgName "MyCPG" 
	Displays detailed information about the CPGs.

  .EXAMPLE
	Get-CPG -RawSpace -cpgName "MyCPG" 
	Specifies that raw space used by the CPGs is displayed.
	  
  .EXAMPLE
	Get-CPG -AlertTime -cpgName "MyCPG" 
	Show times when alerts were posted (when applicable).
	  
  .EXAMPLE
	Get-CPG -Domain_Name XYZ -cpgName "MyCPG" 
	Show times with domain name depict.
	 
  .PARAMETER cpgName 
    Specify name of the cpg to be listed.

  .PARAMETER ListCols
	List the columns available to be shown in the -showcols option
	described below (see "clihelp -col showcpg" for help on each column).
		
  .PARAMETER Detailed
	Displays detailed information about the CPGs. The following columns
	are shown:
	Id Name Warn% VVs TPVVs TDVVs UsageUsr UsageSnp Base SnpUsed Free Total
	LDUsr LDSnp RC_UsageUsr RC_UsageSnp DDSType DDSSize

  .PARAMETER RawSpace
	Specifies that raw space used by the CPGs is displayed. The following
	columns are shown:
	Id Name Warn% VVs TPVVs TDVVs UsageUsr UsageSnp Base RBase SnpUsed
	SnpRUsed Free RFree Total RTotal

  .PARAMETER Alert
	Indicates whether alerts are posted. The following columns are shown:
	Id Name Warn% UsrTotal DataWarn DataLimit DataAlertW% DataAlertW
	DataAlertL DataAlertF

  .PARAMETER Alerttime
	Show times when alerts were posted (when applicable). The following
	columns are shown:
	Id Name DataAlertW% DataAlertW DataAlertL DataAlertF

  .PARAMETER SAG
	Specifies that the snapshot admin space auto-growth parameters are
	displayed. The following columns are displayed:
	Id Name AdmWarn AdmLimit AdmGrow AdmArgs

  .PARAMETER SDG
	Specifies that the snapshot data space auto-growth parameters are
	displayed. The following columns are displayed:
	Id Name DataWarn DataLimit DataGrow DataArgs

  .PARAMETER Space
	Show the space saving of CPGs. The following columns are displayed:
	Id Name Warn% Shared Private Free Total Compaction Dedup DataReduce Overprov
		
  .PARAMETER Hist
	Specifies that current data from the CPG, as well as the CPG's history
	data is displayed.

  .PARAMETER Domain_Name
	Shows only CPGs that are in domains with names matching one or more of
	the <domain_name_or_pattern> argument. This option does not allow
	listing objects within a domain of which the user is not a member.
	Patterns are glob-style (shell-style) patterns (see help on sub,globpat).

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-CPG  
    LASTEDIT: 17-10-2019
    KEYWORDS: Get-CPG
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param
	(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$ListCols,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$Detailed, 
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$RawSpace,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Alert,
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$AlertTime,
		
		[Parameter(Position=5, Mandatory=$false)]
		[switch]
		$SAG,
		
		[Parameter(Position=6, Mandatory=$false)]
		[switch]
		$SDG,
		
		[Parameter(Position=7, Mandatory=$false)]
		[switch]
		$Space,
		
		[Parameter(Position=8, Mandatory=$false)]
		[switch]
		$History,
		
		[Parameter(Position=9, Mandatory=$false)]
		[System.String]
		$Domain_Name,
		
		[Parameter(Position=10, Mandatory=$false)]
		[System.String]
		$cpgName,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-CPG - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-CPG since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-CPG since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$GetCPGCmd = "showcpg "
	
	if($ListCols)	
	{
		$GetCPGCmd += "-listcols "
	}
	if($Detailed)	
	{
		$GetCPGCmd += "-d "
	}
	if($RawSpace)	
	{
		$GetCPGCmd += "-r "
	}
	if($Alert)	
	{
		$GetCPGCmd += "-alert "
	}
	if($AlertTime)	
	{
		$GetCPGCmd += "-alerttime "
	}
	if($SAG)	
	{
		$GetCPGCmd += "-sag "
	}
	if($SDG)	
	{
		$GetCPGCmd += "-sdg "
	}
	if($Space)	
	{
		$GetCPGCmd += "-space "
	}
	if($History)	
	{
		$GetCPGCmd += "-hist "
	}
	if($Domain_Name)	
	{
		$GetCPGCmd += "-domain $Domain_Name "
	}
	if ($cpgName)
	{
		$objType = "cpg"
		$objMsg  = "cpg"
		
		## Check cpg Name 
		##
		if ( -not ( Test-CLIObject -objectType $objType -objectName $cpgName -objectMsg $objMsg -SANConnection $SANConnection)) 
		{
			write-debuglog " CPG name $cpgName does not exist. Nothing to display"  "INFO:"  
			return "FAILURE : No cpg $cpgName found"
		}
		$GetCPGCmd += "  $cpgName"
	}	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $GetCPGCmd	
	if($ListCols -or $History)
	{
		write-debuglog "$Result" "ERR:" 
		return $Result
	}
	if ( $Result.Count -gt 1)
	{		
		$3parosver = Get-Version -S -SANConnection  $SANConnection
		if($3parosver -eq "3.2.2")
		{			
			if($Alert -Or $AlertTime -Or $SAG -Or $SDG)
			{			
				$Cnt
				if($Alert)
				{
					$Cnt=2
				}
				if($AlertTime -Or $SAG -Or $SDG )
				{
					$Cnt=1
				}
				$tempFile = [IO.Path]::GetTempFileName()
				$LastItem = $Result.Count
				$incre = "true"
				foreach ($s in  $Result[$Cnt..$LastItem] )
				{			
					$s= [regex]::Replace($s,"^ ","")						
					$s= [regex]::Replace($s," +",",")			
					$s= [regex]::Replace($s,"-","")			
					$s= $s.Trim()
					if($AlertTime)
					{
						$TempRep = $s -replace 'L','L_Date,L_Time,L_Zone'
						$s = $TempRep
					}
					
					if($incre -eq "true")
					{		
						$sTemp1=$s				
						$sTemp = $sTemp1.Split(',')
						if($Alert)
						{
							$sTemp[3]="Total_MB_Data"
							$sTemp[10]="Total_MB_Adm"							
							$sTemp[11]="W%_Alerts_Adm"
							$sTemp[12]="F_Alerts_Adm"
						}
						if($AlertTime)
						{
							$sTemp[2]="W%_DataAlerts"
							$sTemp[3]="W_DataAlerts"
							$sTemp[7]="F_DataAlerts"
							$sTemp[8]="W%_AdmAlerts"
							$sTemp[9]="F_AdmAlerts"
						}						
						
						$newTemp= [regex]::Replace($sTemp,"^ ","")			
						$newTemp= [regex]::Replace($sTemp," ",",")				
						$newTemp= $newTemp.Trim()
						$s=$newTemp							
					}
					Add-Content -Path $tempFile -Value $s
					$incre="false"					
				}
				if ($CPGName)
				{ 					
					Import-Csv $tempFile | where  {$_.Name -like $CPGName} 
				}
				else
				{					
					Import-Csv $tempFile
				}			
				del $tempFile
			}
			elseif($Space -or $Domain_Name)
			{			
				$tempFile = [IO.Path]::GetTempFileName()
				$LastItem = $Result.Count-2
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
						if($Space)
						{
							$sTemp[2]="Warn%_User_MB"
							$sTemp[3]="Total_User_MB"							
							$sTemp[4]="Used_User_MB"
							$sTemp[5]="Total_Snp_MB"							
							$sTemp[6]="Used_Snp_MB"
							$sTemp[7]="Total_Adm_MB"							
							$sTemp[8]="Used_Adm_MB"
							
						}	
						if($Domain_Name)
						{
							$sTemp[8]="Total_User_MB"							
							$sTemp[9]="Used_User_MB"
							$sTemp[10]="Total_Snp_MB"							
							$sTemp[11]="Used_Snp_MB"
							$sTemp[12]="Total_Adm_MB"							
							$sTemp[13]="Used_Adm_MB"
						}
						$newTemp= [regex]::Replace($sTemp,"^ ","")			
						$newTemp= [regex]::Replace($sTemp," ",",")				
						$newTemp= $newTemp.Trim()
						$s=$newTemp							
					}
					Add-Content -Path $tempFile -Value $s
					$incre="false"				
				}
				if ($CPGName)
					{					
						Import-Csv $tempFile | where  {$_.Name -like $CPGName} 
					}
				else
					{
						Import-Csv $tempFile 
					}			
				del $tempFile
			}
			else
			{			
				$tempFile = [IO.Path]::GetTempFileName()
				$LastItem = $Result.Count - 2
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
						if($Detailed)
						{
							$sTemp[6]="Usr_Usage"
							$sTemp[7]="Snp_Usage"
							$sTemp[8]="Total_User_MB"							
							$sTemp[9]="Used_User_MB"
							$sTemp[10]="Total_Snp_MB"							
							$sTemp[11]="Used_Snp_MB"
							$sTemp[12]="Total_Adm_MB"							
							$sTemp[13]="Used_Adm_MB"
							$sTemp[14]="Usr_LD"
							$sTemp[15]="Snp_LD"
							$sTemp[16]="Adm_LD"
							$sTemp[17]="Usr_RC_Usage"
							$sTemp[18]="Snp_RC_Usage"	
						}
						elseif($RawSpace)
						{
							$sTemp[6]="Usr_Usage"
							$sTemp[7]="Snp_Usage"
							$sTemp[8]="Total_User_MB"
							$sTemp[9]="RTotal_User_MB"							
							$sTemp[10]="Used_User_MB"
							$sTemp[11]="RUsed_User_MB"
							$sTemp[12]="Total_Snp_MB"
							$sTemp[13]="RTotal_Snp_MB"
							$sTemp[14]="Used_Snp_MB"
							$sTemp[15]="RUsed_Snp_MB"
							$sTemp[16]="Total_Adm_MB"
							$sTemp[17]="RTotal_Adm_MB"
							$sTemp[18]="Used_Adm_MB"
							$sTemp[19]="RUsed_Adm_MB"
						}
						else
						{
							$sTemp[6]="Usr_Usage"
							$sTemp[7]="Snp_Usage"
							$sTemp[8]="Total_User_MB"							
							$sTemp[9]="Used_User_MB"
							$sTemp[10]="Total_Snp_MB"							
							$sTemp[11]="Used_Snp_MB"
							$sTemp[12]="Total_Adm_MB"							
							$sTemp[13]="Used_Adm_MB"
						}					
						$newTemp= [regex]::Replace($sTemp,"^ ","")			
						$newTemp= [regex]::Replace($sTemp," ",",")				
						$newTemp= $newTemp.Trim()
						$s=$newTemp							
					}						
					Add-Content -Path $tempFile -Value $s	
					$incre="false"
				}
				if ($CPGName)
				{					
					Import-Csv $tempFile | where  {$_.Name -like $CPGName} 
				}
				else
				{					
					Import-Csv $tempFile
				}			
				del $tempFile
			}
		}
		else
		{
			if($Alert -Or $AlertTime -Or $SAG -Or $SDG)
			{			
				$Cnt
				if($Alert)
				{
					$Cnt=2
				}
				if($AlertTime -Or $SAG -Or $SDG )
				{
					$Cnt=1
				}
				$tempFile = [IO.Path]::GetTempFileName()
				$LastItem = $Result.Count						
				foreach ($s in  $Result[$Cnt..$LastItem] )
				{			
					$s= [regex]::Replace($s,"^ ","")						
					$s= [regex]::Replace($s," +",",")			
					$s= [regex]::Replace($s,"-","")			
					$s= $s.Trim()									
					Add-Content -Path $tempFile -Value $s				
				}
				if ($CPGName)
				{ 					
					Import-Csv $tempFile | where  {$_.Name -like $CPGName} 
				}
				else
				{					
					Import-Csv $tempFile
				}			
				del $tempFile
			}
			elseif($Space -or $Domain_Name)
			{			
				$tempFile = [IO.Path]::GetTempFileName()
				$LastItem = $Result.Count-2
				$incre = "true" 			
				foreach ($s in  $Result[1..$LastItem] )
				{			
					$s= [regex]::Replace($s,"^ ","")						
					$s= [regex]::Replace($s," +",",")			
					$s= [regex]::Replace($s,"-","")			
					$s= $s.Trim()
					if($incre -eq "true")
					{		
						$sTemp1=$s				
						$sTemp = $sTemp1.Split(',')
						if($Space)
						{
							$sTemp[3]="Base(Private(MiB))"
							$sTemp[4]="Snp(Private(MiB))"							
							$sTemp[5]="Shared(MiB)"
							$sTemp[6]="Free(MiB)"
							$sTemp[7]="Total(MiB)"							
							$sTemp[8]="Compact(Efficiency)"						
							$sTemp[9]="Dedup(Efficiency)"						
							$sTemp[10]="Compress(Efficiency)"						
							$sTemp[11]="DataReduce(Efficiency)"	
							$sTemp[12]="Overprov(Efficiency)"
						}	
						if($Domain_Name)
						{
							$sTemp[3]="VVs(Volumes)"
							$sTemp[4]="TPVVs(Volumes)"							
							$sTemp[5]="TDVVs(Volumes)"
							$sTemp[6]="Usr(Usage)"
							$sTemp[7]="Snp(Usage)"							
							$sTemp[8]="Base(MiB)"						
							$sTemp[9]="Snp(MiB)"						
							$sTemp[10]="Free(MiB)"						
							$sTemp[11]="Total(MiB)"
						}
						$newTemp= [regex]::Replace($sTemp,"^ ","")			
						$newTemp= [regex]::Replace($sTemp," ",",")				
						$newTemp= $newTemp.Trim()
						$s=$newTemp							
					}
					Add-Content -Path $tempFile -Value $s
					$incre="false"				
				}
				if ($CPGName)
					{					
						Import-Csv $tempFile | where  {$_.Name -like $CPGName} 
					}
				else
					{
						Import-Csv $tempFile 
					}			
				del $tempFile
			}
			else
			{			
				$tempFile = [IO.Path]::GetTempFileName()
				$LastItem = $Result.Count - 2
				$incre = "true" 			
				foreach ($s in  $Result[1..$LastItem] )
				{			
					$s= [regex]::Replace($s,"^ ","")						
					$s= [regex]::Replace($s," +",",")			
					$s= [regex]::Replace($s,"-","")			
					$s= $s.Trim()
					if($incre -eq "true")
					{		
						$sTemp1=$s				
						$sTemp = $sTemp1.Split(',')
						if($Detailed)
						{
							$sTemp[3]="VVs(Volumes)"
							$sTemp[4]="TPVVs(Volumes)"							
							$sTemp[5]="TDVVs(Volumes)"
							$sTemp[6]="Usr(Usage)"
							$sTemp[7]="Snp(Usage)"							
							$sTemp[8]="Base(MiB)"						
							$sTemp[9]="Snp(MiB)"						
							$sTemp[10]="Free(MiB)"						
							$sTemp[11]="Total(MiB)"	
							$sTemp[12]="Usr(LD)"
							$sTemp[13]="Snp(LD)"
							$sTemp[14]="Usr(RC_Usage)"
							$sTemp[15]="Snp(RC_Usage)"
						}
						elseif($RawSpace)
						{
							$sTemp[3]="VVs(Volumes)"
							$sTemp[4]="TPVVs(Volumes)"							
							$sTemp[5]="TDVVs(Volumes)"
							$sTemp[6]="Usr(Usage)"
							$sTemp[7]="Snp(Usage)"							
							$sTemp[8]="Base(MiB)"
							$sTemp[9]="RBase(MiB)"
							$sTemp[10]="Snp(MiB)"
							$sTemp[11]="RSnp(MiB)"
							$sTemp[12]="Free(MiB)"
							$sTemp[13]="RFree(MiB)"
							$sTemp[14]="Total(MiB)"
							$sTemp[15]="RTotal(MiB)"
						}
						else
						{
							$sTemp[3]="VVs(Volumes)"
							$sTemp[4]="TPVVs(Volumes)"							
							$sTemp[5]="TDVVs(Volumes)"
							$sTemp[6]="Usr(Usage)"
							$sTemp[7]="Snp(Usage)"							
							$sTemp[8]="Base(MiB)"						
							$sTemp[9]="Snp(MiB)"						
							$sTemp[10]="Free(MiB)"						
							$sTemp[11]="Total(MiB)"
						}					
						$newTemp= [regex]::Replace($sTemp,"^ ","")			
						$newTemp= [regex]::Replace($sTemp," ",",")				
						$newTemp= $newTemp.Trim()
						$s=$newTemp
					}						
					Add-Content -Path $tempFile -Value $s	
					$incre="false"
				}
				if ($CPGName)
				{
					Import-Csv $tempFile 
				}
				else
				{					
					Import-Csv $tempFile
				}			
				del $tempFile
			}
		}
	}
	elseif($Result -match "FAILURE")
	{		
		write-debuglog "$Result" "ERR:" 
		return $Result
	}
	else
	{
		#write-host "FINALY RETURN.."
		return $Result
	}
		
} # End Get-CPG

############################################################################################################################################
## FUNCTION New-CPG
############################################################################################################################################

Function New-CPG
{
<#
  .SYNOPSIS
    The New-CPG command creates a Common Provisioning Group (CPG).
  
  .DESCRIPTION
    The New-CPG command creates a Common Provisioning Group (CPG).
        
  .EXAMPLE
    New-CPG -cpgName "MyCPG" -Size 32G	-RAIDType r1 
	 Creates a CPG named MyCPG with initial size of 32GB and Raid configuration is r1 (RAID 1)
	 
  .EXAMPLE 
	New-CPG -cpgName asCpg

  .EXAMPLE 
	New-CPG -cpgName asCpg1 -TemplateName temp

  .EXAMPLE	
	New-CPG -cpgName asCpg1 -AW 1
	
  .EXAMPLE	
	New-CPG -cpgName asCpg1 -SDGS 1
	
  .EXAMPLE	
	New-CPG -cpgName asCpg1 -SDGL 12241
	
  .EXAMPLE	
	New-CPG -cpgName asCpg1 -saLD_name XYZ
	
  .EXAMPLE	
	New-CPG -cpgName asCpg1 -sdLD_name XYZ
	
  .EXAMPLE	
	New-CPG -cpgName asCpg1 -RAIDType r1	
	
  .PARAMETER TemplateName
	Use the options defined in template <template_name>. The template is
	created using the createtemplate command.  Options specified in the
	template are read-only or read-write. The read-write options may be
	overridden with new options at the time of their creation, but read-only
	options may not be overridden at the time of creation.

	Options not explicitly specified in the template take their default
	values, and all of these options are either read-only or read-write
	(using the -nro or -nrw options of the createtemplate command).
		
  .PARAMETER AW
	Specifies the percentage of used snapshot administration or snapshot
	data space that results in a warning alert. A percent value of 0
	disables the warning alert generation. The default is 0.
	This option is deprecated and will be removed in a subsequent release.

  .PARAMETER SDGS
	Specifies the growth increment, the amount of logical disk storage
	created on each auto-grow operation. The default growth increment may
	vary according to the number of controller nodes in the system. If <size>
	is non-zero it must be 8G or bigger. The size can be specified in MB (default)
	or GB (using g or G) or TB (using t or T). A size of 0 disables the auto-grow
	feature. The following table displays the default and minimum growth
	increments per number of nodes:
					Number of Nodes       Default     Minimum
						  1-2               32G          8G
						  3-4               64G         16G
						  5-6               96G         24G
						  7-8              128G         32G

  .PARAMETER SDGL
	Specifies that the auto-grow operation is limited to the specified
	storage amount. The storage amount can be specified in MB (default) or
	GB (using g or G) or TB (using t or T). A size of 0 (default) means no
	limit is enforced.  To disable auto-grow, set the limit to 1.

  .PARAMETER SDGW
	Specifies that the threshold of used logical disk space, when exceeded,
	results in a warning alert. The size can be specified in MB (default) or
	GB (using g or G) or TB (using t or T). A size of 0 (default) means no
	warning limit is enforced. To set the warning for any used space,
	set the limit to 1.

  .PARAMETER saLD_name
	Specifies that existing logical disks are added to the CPG and are used
	for snapshot admin (SA) space allocation. The <LD_name> argument can be
	repeated to specify multiple logical disks.
	This option is deprecated and will be removed in a subsequent release.

  .PARAMETER sdLD_name
	Specifies that existing logical disks are added to the CPG and are used
	for snapshot data (SD) space allocation. The <LD_name> argument can be
	repeated to specify multiple logical disks.
	This option is deprecated and will be removed in a subsequent release.

  .PARAMETER Domain
	Specifies the name of the domain with which the object will reside. The
	object must be created by a member of a particular domain with Edit or
	Super role. The default is to create it in the current domain, or
	no domain if the current domain is not set.

  .PARAMETER RAID_type
	Specifies the RAID type of the logical disk: r0 for RAID-0, r1 for
	RAID-1, r5 for RAID-5, or r6 for RAID-6. If no RAID type is specified,
	then the default is r6.

  .PARAMETER SSZ
	Specifies the set size in terms of chunklets. The default depends on
	the RAID type specified: 2 for RAID-1, 4 for RAID-5, and 8 for RAID-6.

  .PARAMETER RS
	Specifies the number of sets in a row. The <size> is a positive integer.
	If not specified, no row limit is imposed.

  .PARAMETER SS
	Specifies the step size from 32 KB to 512 KB. The step size should be a
	power of 2 and a multiple of 32. The default value depends on raid type and
	device type used. If no value is entered and FC or NL drives are used, the
	step size defaults to 256 KB for RAID-0 and RAID-1, and 128 KB for RAID-5.
	If SSD drives are used, the step size defaults to 32 KB for RAID-0 and
	RAID-1, and 64 KB for RAID-5. For RAID-6, the default is a function of the
	set size.

  .PARAMETER HA
	Specifies that the layout must support the failure of one port pair,
	one cage, or one drive magazine (mag). This option has no meaning
	for RAID-0. The default is cage availability.

  .PARAMETER CH
	Specifies the chunklet location characteristics: either first (attempt
	to use the lowest numbered available chunklets) or last(attempt to use
	the highest numbered available chunklets). If no argument is specified,
	the default characteristic is first.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	              
  .Notes
    NAME:  New-CPG 
    LASTEDIT: 17-10-2019
    KEYWORDS: New-CPG
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$cpgName,	
	
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$TemplateName,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$AW,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$SDGS,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$SDGL,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$SDGW,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$saLD_name,
		
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$sdLD_name,
		
		[Parameter(Position=8, Mandatory=$false)]
		[System.String]
		$Domain,
		
		[Parameter(Position=9, Mandatory=$false)]
		[System.String]
		$RAIDType,
		
		[Parameter(Position=10, Mandatory=$false)]
		[System.String]
		$SSZ,
		
		[Parameter(Position=11, Mandatory=$false)]
		[System.String]
		$RS,
		
		[Parameter(Position=12, Mandatory=$false)]
		[System.String]
		$SS,
		
		[Parameter(Position=13, Mandatory=$false)]
		[System.String]
		$HA,
		
		[Parameter(Position=14, Mandatory=$false)]
		[System.String]
		$CH,
		
		[Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In new-CPG - validating input values" $Debug 
	
	#####
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
				Write-DebugLog "Stop: Exiting New-CPG since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet New-CPG since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection 
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	if(!($cpgName))
	{
		write-debuglog " No CPG name specified  - No action required" "INFO:"
		Get-Help New-CPG
		return
	}
	
	$CreateCPGCmd =" createcpg -f" 
	
	if($TemplateName)
	{
		$CreateCPGCmd += " -templ $TemplateName "
	}
	if($AW)
	{
		$CreateCPGCmd += " -aw $AW "
	}
	if($SDGS)
	{
		$CreateCPGCmd += " -sdgs $SDGS "
	}
	if($SDGL)
	{
		$CreateCPGCmd += " -sdgl $SDGL "
	}
	if($SDGW)
	{
		$CreateCPGCmd += " -sdgw $SDGW "
	}
	if($saLD_name)
	{
		$CreateCPGCmd += " -sa $saLD_name "
	}
	if($sdLD_name)
	{
		$CreateCPGCmd += " -sd $sdLD_name "
	}
	if($Domain)
	{
		$CreateCPGCmd += " -domain $Domain "
	}
	if($RAIDType)
	{
		$CreateCPGCmd += " -t $RAIDType "
	}
	if($SSZ)
	{
		$CreateCPGCmd += " -ssz $SSZ "
	}
	if($RS)
	{
		$CreateCPGCmd += " -rs $RS "
	}
	if($SS)
	{
		$CreateCPGCmd += " -ss $SS "
	}
	if($HA)
	{
		$a = "port","cage","mag"
		$l=$HA
		if($a -eq $l)
		{
			$CreateCPGCmd += " -ha $HA "			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  New-CPG since -HA $HA in incorrect "
			Return "FAILURE : -HA :- $HA is an Incorrect HA  [ port | cage | mag ]  can be used only . "
		}
		$CreateCPGCmd += " -ha $HA "
	}
	if($CH)
	{		
		$a = "first","last"
		$l=$CH
		if($a -eq $l)
		{
			$CreateCPGCmd += " -ch $CH "			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  New-CPG since -CH $CH in incorrect "
			Return "FAILURE : -CH :- $CH is an Incorrect CH  [ first | last ]  can be used only . "
		}	
	}
	
	$CreateCPGCmd += " $cpgName"
	
	$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $CreateCPGCmd	
	return $Result1
	
} # End of New-CPG

#####################################################################################################################
## FUNCTION Remove-CPG
#####################################################################################################################
Function Remove-CPG
{
<#
  .SYNOPSIS
    Removes a Common Provisioning Group(CPG)
  
  .DESCRIPTION
	 Removes a Common Provisioning Group(CPG)
        
  .EXAMPLE
    Remove-CPG -cpgName "MyCPG"  -force
	 Removes a Common Provisioning Group(CPG) "MyCPG"

  .PARAMETER force
	forcefully execute the command.
 
  .PARAMETER saLDname
	Specifies that the logical disk, as identified with the <LD_name>
	argument, used for snapshot administration space allocation is removed.
	The <LD_name> argument can be repeated to specify multiple logical
	disks.
	This option is deprecated and will be removed in a subsequent release.

  .PARAMETER sdLDname
	Specifies that the logical disk, as identified with the <LD_name>
	argument, used for snapshot data space allocation is removed. The
	<LD_name> argument can be repeated to specify multiple logical disks.
	This option is deprecated and will be removed in a subsequent release.
	
  .PARAMETER cpgName 
    Specify name of the CPG
	
  .PARAMETER Pat 
    The specified patterns are treated as glob-style patterns and that all common provisioning groups matching the specified pattern are removed.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
              
  .Notes
    NAME:  Remove-CPG 
    LASTEDIT: 17-10-2019
    KEYWORDS: Remove-CPG
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$force,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$cpgName,
		
	    [Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$sdLDname,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$saLDname,

		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$Pat,	
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)

	Write-DebugLog "Start: In Remove-CPG - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Remove-CPG since SAN connection object values are null/empty" $Debug
				return "FAILURE: Exiting Remove-CPG since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	if ($cpgName)
	{
		if(!($force))
		{
			write-debuglog "no force option selected to remove CPG, Exiting...." "INFO:"
			return "FAILURE: No -force option selected to remove cpg $cpgName"
		}
		$objType = "cpg"
		$objMsg  = "cpg"
		$RemoveCPGCmd = "removecpg "
		## Check CPG Name 
		##
		if ( -not ( Test-CLIObject -objectType $objType -objectName $cpgName -objectMsg $objMsg -SANConnection $SANConnection)) 
		{
			write-debuglog " CPG $cpgName does not exist. Nothing to remove"  "INFO:"  
			return "FAILURE: No cpg $cpgName found"
		}
		else
		{			
			if($force)
			{
				$RemoveCPGCmd +=" -f "
			}
			if($Pat)
			{
				$RemoveCPGCmd +=" -pat "
			}
			if ($saLDname)
			{
				$RemoveCPGCmd +=" -sa $saLDname "
			}
			if ($sdLDname)
			{
				$RemoveCPGCmd +=" -sd $sdLDname "
			}
			$RemoveCPGCmd += " $cpgName "
			$Result3 = Invoke-CLICommand -Connection $SANConnection -cmds  $RemoveCPGCmd
			write-debuglog "Removing CPG  with the command --> $RemoveCPGCmd" "INFO:" 
			
			if (Test-CLIObject -objectType $objType -objectName $cpgName -objectMsg $objMsg -SANConnection $SANConnection)
			{
				write-debuglog " CPG $cpgName exists. Nothing to remove"  "INFO:"  
				return "FAILURE: While removing cpg $cpgName `n $Result3"
			}
			else
			{
				if ($Result3 -match "Removing CPG")
				{
					return "Success : Removed cpg $cpgName"
				}
				else
				{
					return "FAILURE: While removing cpg $cpgName $Result3"
				}
			}			
		}		
	}
	else
	{
		write-debuglog  "No CPG name mentioned to remove " "INFO:"
		Get-help Remove-CPG
	}
		
} # End of Remove-CPG

##########################################################################
#########################  FUNCTION Set-CPG  #########################
##########################################################################
Function Set-CPG()
{
<#
  .SYNOPSIS
   Set-CPG - Update a Common Provisioning Group (CPG)

  .DESCRIPTION
   The Set-CPG command modifies existing Common Provisioning Groups (CPG).

  .EXAMPLE

  .PARAMETER Sa
   Specifies that existing logical disks are added to the CPG and are used
   for snapshot admin (SA) space allocation. The <LD_name> argument can be
   repeated to specify multiple logical disks.
   This option is deprecated and will be removed in a subsequent release.

  .PARAMETER Sd
   Specifies that existing logical disks are added to the CPG and are used
   for snapshot data (SD) space allocation. The <LD_name> argument can be
   repeated to specify multiple logical disks.
   This option is deprecated and will be removed in a subsequent release.
	
  .PARAMETER Aw
   Specifies the percentage of used snapshot administration or snapshot
   data space that results in a warning alert. A percent value of 0
   disables the warning alert generation. The default is 0.
   This option is deprecated and will be removed in a subsequent release.

  .PARAMETER Sdgs
   Specifies the growth increment, the amount of logical disk storage
   created on each auto-grow operation. The default growth increment may
   vary according to the number of controller nodes in the system. If <size>
   is non-zero it must be 8G or bigger. The size can be specified in MB (default)
   or GB (using g or G) or TB (using t or T). A size of 0 disables the auto-grow
   feature. The following table displays the default and minimum growth
   increments per number of nodes:
   Number of Nodes       Default     Minimum
   1-2               32G          8G
   3-4               64G         16G
   5-6               96G         24G
   7-8              128G         32G

  .PARAMETER Sdgl
   Specifies that the auto-grow operation is limited to the specified
   storage amount. The storage amount can be specified in MB (default) or
   GB (using g or G) or TB (using t or T). A size of 0 (default) means no
   limit is enforced.  To disable auto-grow, set the limit to 1.

  .PARAMETER Sdgw
   Specifies that the threshold of used logical disk space, when exceeded,
   results in a warning alert. The size can be specified in MB (default) or
   GB (using g or G) or TB (using t or T). A size of 0 (default) means no
   warning limit is enforced. To set the warning for any used space,
   set the limit to 1.

  .PARAMETER T
   Specifies the RAID type of the logical disk: r1 for RAID-1, or r6 for
   RAID-6. If no RAID type is specified, then the default is r6.

  .PARAMETER Ssz
   Specifies the set size in terms of chunklets. The default depends on
   the RAID type specified: 3 for RAID-1, and 8 for RAID-6.

  .PARAMETER Rs
   Specifies the number of sets in a row. The <size> is a positive integer.
   If not specified, no row limit is imposed.

  .PARAMETER Ss
   Specifies the step size from 32 KiB to 512 KiB. The step size should be a
   power of 2 and a multiple of 32. The default value depends on raid type and
   device type used. If no value is entered and FC or NL drives are used, the
   step size defaults to 256 KiB for RAID-1.
   If SSD drives are used, the step size defaults to 32 KiB for RAID-1.
   For RAID-6, the default is a function of the set size.

  .PARAMETER Ha
   Specifies that the layout must support the failure of one port pair,
   one cage, or one drive magazine (mag). The default is cage availability.

  .PARAMETER Ch
   Specifies the chunklet location characteristics: either first (attempt
   to use the lowest numbered available chunklets) or last(attempt to use
   the highest numbered available chunklets). If no argument is specified,
   the default characteristic is first.

  .PARAMETER P
   Specifies a pattern for candidate disks. Patterns are used to select
   disks that are used for creating logical disks. If no pattern is
   specified, the option defaults to Fast Class (FC) disks. If specified
   multiple times, each instance of the specified pattern adds additional
   candidate disks that match the pattern. The -devtype pattern cannot be
   used to mix Nearline (NL), FC, and Solid State Drive (SSD) drives. An
   item is specified as an integer, a comma-separated list of integers, or
   a range of integers specified from low to high.
   The following arguments can be specified as patterns for this option:
   An item is specified as an integer, a comma-separated list of integers,
   or a range of integers specified from low to high.

  .PARAMETER Nd
   Specifies one or more nodes. Nodes are identified by one or more
   integers (item). Multiple nodes are separated with a single comma
   (e.g. 1,2,3). A range of nodes is separated with a hyphen (e.g. 0-
   7). The primary path of the disks must be on the specified node(s).

  .PARAMETER St
   Specifies one or more PCI slots. Slots are identified by one or more
   integers (item). Multiple slots are separated with a single comma
   (e.g. 1,2,3). A range of slots is separated with a hyphen (e.g. 0-
   7). The primary path of the disks must be on the specified PCI
   slot(s).

  .PARAMETER Pt
   Specifies one or more ports. Ports are identified by one or more
   integers (item). Multiple ports are separated with a single comma
   (e.g. 1,2,3). A range of ports is separated with a hyphen (e.g. 0-
   4). The primary path of the disks must be on the specified port(s).

  .PARAMETER Cg
   Specifies one or more drive cages. Drive cages are identified by one
   or more integers (item). Multiple drive cages are separated with a
   single comma (e.g. 1,2,3). A range of drive cages is separated with
   a hyphen (e.g. 0-3). The specified drive cage(s) must contain disks.

  .PARAMETER Mg
   Specifies one or more drive magazines. The "1." or "0." displayed
   in the CagePos column of showpd output indicating the side of the
   cage is omitted when using the -mg option. Drive magazines are
   identified by one or more integers (item). Multiple drive magazines
   are separated with a single comma (e.g. 1,2,3). A range of drive
   magazines is separated with a hyphen(e.g. 0-7). The specified drive
   magazine(s) must contain disks.

  .PARAMETER Pn
   Specifies one or more disk positions within a drive magazine. Disk
   positions are identified by one or more integers (item). Multiple
   disk positions are separated with a single comma(e.g. 1,2,3). A
   range of disk positions is separated with a hyphen(e.g. 0-3). The
   specified position(s) must contain disks.

  .PARAMETER Dk
   Specifies one or more physical disks. Disks are identified by one or
   more integers(item). Multiple disks are separated with a single
   comma (e.g. 1,2,3). A range of disks is separated with a hyphen(e.g.
   0-3).  Disks must match the specified ID(s).

  .PARAMETER Tc_gt
   Specifies that physical disks with total chunklets greater than the
   number specified be selected.

  .PARAMETER Tc_lt
   Specifies that physical disks with total chunklets less than the
   number specified be selected.

  .PARAMETER Fc_gt
   Specifies that physical disks with free chunklets greater than the
   number specified be selected.

  .PARAMETER Fc_lt
   Specifies that physical disks with free chunklets less than the
   number specified be selected.

  .PARAMETER Devid
   Specifies that physical disks identified by their models be
   selected. Models can be specified in a comma-separated list.
   Models can be displayed by issuing the "showpd -i" command.

  .PARAMETER Devtype
   Specifies that physical disks must have the specified device type
   (FC for Fast Class, NL for Nearline, SSD for Solid State Drive) to
   be used. Device types can be displayed by issuing the "showpd"
   command. If it is not specified, the default device type is FC.

  .PARAMETER Rpm
   Disks must be of the specified speed. Device speeds are shown in the
   RPM column of the showpd command. The number does not represent a
   rotational speed for the drives without spinning media (SSD). It is
   meant as a rough estimation of the performance difference between
   the drive and the other drives in the system. For FC and NL drives,
   the number corresponds to both a performance measure and actual
   rotational speed. For SSD drive, the number is to be treated as
   relative performance benchmark that takes into account in I/O per
   second, bandwidth and the access time.
   Disks that satisfy all of the specified characteristics are used.
   For example -p -fc_gt 60 -fc_lt 230 -nd 2 specifies all the disks that
   have greater than 60 and less than 230 free chunklets and that are
   connected to node 2 through their primary path.

  .PARAMETER Sax
   Specifies that the logical disk, as identified with the <LD_name>
   argument, used for snapshot administration space allocation be removed.
   The <LD_name> argument can be repeated to specify multiple logical disks

  .PARAMETER Sdx
   Specifies that the logical disk, as identified with the <LD_name>
   argument, used for snapshot data space allocation be removed. The
   <LD_name> argument can be repeated to specify multiple logical disks.

  .PARAMETER NewName
   Specifies the name of the Common Provisioning Group (CPG) to be modified to.
   <newname> can be up to 31 characters in length.

  .Notes
    NAME: Set-CPG
    LASTEDIT 17-10-2019
    KEYWORDS: Set-CPG
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Sa,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Sd,
	
	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Aw,

	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Sdgs,

	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Sdgl,

	[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Sdgw,

	[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$T,

	[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Ssz,

	[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Rs,

	[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Ss,

	[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Ha,

	[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Ch,

	[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$P,

	[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Nd,

	[Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$St,

	[Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Pt,

	[Parameter(Position=17, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Cg,

	[Parameter(Position=18, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Mg,

	[Parameter(Position=19, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Pn,

	[Parameter(Position=20, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Dk,

	[Parameter(Position=21, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Tc_gt,

	[Parameter(Position=22, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Tc_lt,

	[Parameter(Position=23, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Fc_gt,

	[Parameter(Position=24, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Fc_lt,

	[Parameter(Position=25, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Devid,

	[Parameter(Position=26, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Devtype,

	[Parameter(Position=27, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Rpm,

	[Parameter(Position=28, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Sax,

	[Parameter(Position=29, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Sdx,

	[Parameter(Position=30, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$NewName,

	[Parameter(Position=31, Mandatory=$true, ValueFromPipeline=$true)]
	[System.String]
	$CPG_name,

	[Parameter(Position=32, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Set-CPG - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Set-CPG since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Set-CPG since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

	$Cmd = " setcpg -f"

 if($Sa)
 {
	$Cmd += " -sa $Sa "
 }

 if($Sd)
 {
	$Cmd += " -sd $Sd "
 }

 if($Aw)
 {
	$Cmd += " -aw $Aw "
 }

 if($Sdgs)
 {
	$Cmd += " -sdgs $Sdgs "
 }

 if($Sdgl)
 {
	$Cmd += " -sdgl $Sdgl "
 }

 if($Sdgw)
 {
	$Cmd += " -sdgw $Sdgw "
 }

 if($T)
 {
	$Cmd += " -t $T "
 }

 if($Ssz)
 {
	$Cmd += " -ssz $Ssz "
 }

 if($Rs)
 {
	$Cmd += " -rs $Rs "
 }

 if($Ss)
 {
	$Cmd += " -ss $Ss "
 }

 if($Ha)
 {
	$Cmd += " -ha $Ha "
 }

 if($Ch)
 {
	$Cmd += " -ch $Ch "
 }

 if($P)
 {
	$Cmd += " -p "
 }

 if($Nd)
 {
	$Cmd += " -nd $Nd "
 }

 if($St)
 {
	$Cmd += " -st $St "
 }

 if($Pt)
 {
	$Cmd += " -pt $Pt "
 }

 if($Cg)
 {
	$Cmd += " -cg $Cg "
 }

 if($Mg)
 {
	$Cmd += " -mg $Mg "
 }

 if($Pn)
 {
	$Cmd += " -pn $Pn "
 }

 if($Dk)
 {
	$Cmd += " -dk $Dk "
 }

 if($Tc_gt)
 {
	$Cmd += " -tc_gt $Tc_gt "
 }

 if($Tc_lt)
 {
	$Cmd += " -tc_lt $Tc_lt "
 }

 if($Fc_gt)
 {
	$Cmd += " -fc_gt $Fc_gt "
 }

 if($Fc_lt)
 {
	$Cmd += " -fc_lt $Fc_lt "
 }

 if($Devid)
 {
	$Cmd += " -devid $Devid "
 }

 if($Devtype)
 {
	$Cmd += " -devtype $Devtype "
 }

 if($Rpm)
 {
	$Cmd += " -rpm $Rpm "
 }

 if($Sax)
 {
	$Cmd += " -sax $Sax "
 }

 if($Sdx)
 {
	$Cmd += " -sdx $Sdx "
 }

 if($NewName)
 {
	$Cmd += " -name $NewName "
 }

 if($CPG_name)
 {
	$Cmd += " $CPG_name "
 }
 else
 {
	Return "CPG Name is mandatory please enter..."
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Set-CPG Command -->" INFO: 
 
 if ([string]::IsNullOrEmpty($Result))
 {
    Get-CPG -Detailed -cpgName $CPG_name
 }
 else
 { 
	Return $Result
 }
} ##  End-of Set-CPG

##########################################################################
######################### FUNCTION Compress-CPG #################
##########################################################################
Function Compress-CPG()
{
<#
  .SYNOPSIS
   Compress-CPG - Consolidate space in common provisioning groups.

  .DESCRIPTION
   The Compress-CPG command consolidates logical disk space in Common
   Provisioning Groups (CPGs) into as few logical disks as possible, allowing
   unused logical disks to be removed and their space reclaimed.

  .EXAMPLE
	Compress-CPG -CPG_name xxx 
	
  .EXAMPLE
	Compress-CPG -CPG_name tstCPG

  .PARAMETER Pat
   Compacts CPGs that match any of the specified patterns. This option
   must be used if the pattern specifier is used.

  .PARAMETER Waittask
   Waits for any created tasks to complete.

  .PARAMETER Trimonly
   Removes unused logical disks after consolidating the space. This option
   will not perform any region moves.

  .PARAMETER Nomatch
   Removes only unused logical disks whose characteristics do not match
   the growth characteristics of the CPG. Must be used with the -trimonly
   option. If all logical disks match the CPG growth characteristics,
   this option has no effect.

  .PARAMETER Dr
   Specifies that the operation is a dry run, and the tasks are not
   actually performed.

  .Notes
    NAME: Compress-CPG
    LASTEDIT 17-10-2019
    KEYWORDS: Compress-CPG
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Pat,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Waittask,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Trimonly,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Nomatch,

	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Dr,

	[Parameter(Position=5, Mandatory=$true, ValueFromPipeline=$true)]
	[System.String]
	$CPG_name,

	[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Compress-CPG - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Compress-CPG since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Compress-CPG since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " compactcpg -f "

 if($Pat)
 {
	$Cmd += " -pat "
 }

 if($Waittask)
 {
	$Cmd += " -waittask "
 }

 if($Trimonly)
 {
	$Cmd += " -trimonly "
 }

 if($Nomatch)
 {
	$Cmd += " -nomatch "
 }

 if($Dr)
 {
	$Cmd += " -dr "
 }

 if($CPG_name)
 {
	$Cmd += " $CPG_name "
 }
 else
 {
	Return "CPG Name is mandatory please enter...."
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Compress-CPG Command -->" INFO: 
 
 Return $Result
} ##  End-of Compress-CPG

Export-ModuleMember Get-CPG , New-CPG , Remove-CPG , Set-CPG , Compress-CPG