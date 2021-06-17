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
##	File Name:		HostManagement.psm1
##	Description: 	Host Management cmdlets 
##		
##	Created:		November 2019
##	Last Modified:	November 2019
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

############################################################################################################################################
################################################################## FUNCTION Get-Host #######################################################
############################################################################################################################################
Function Get-Host
{
<#
  .SYNOPSIS
	Lists hosts
  
  .DESCRIPTION
	Queries hosts
        
  .EXAMPLE
    Get-Host 
	Lists all hosts

  .EXAMPLE	
	Get-Host -hostName HV01A
	List host HV01A
	
  .EXAMPLE
	Get-Host -Domain scvmm
	
  .EXAMPLE	
	Get-Host -D

  .EXAMPLE
	Get-Host -CHAP

  .EXAMPLE
	Get-Host -Descriptor

  .EXAMPLE
	Get-Host -Agent

  .EXAMPLE
	Get-Host -Pathsum

  .EXAMPLE
	Get-Host -Persona

  .EXAMPLE
	Get-Host -Listpersona

  .PARAMETER D
	Shows a detailed listing of host and path information. This option can
	be used with -agent and -domain options.

  .PARAMETER Verb
	Shows a verbose listing of all host information. This option cannot
	be used with -d.

  .PARAMETER CHAP
	Shows the CHAP authentication properties. This option cannot be used
	with -d.

  .PARAMETER Descriptor
	Shows the host descriptor information. This option cannot be used with
	-d.

  .PARAMETER Agent
	Shows information provided by host agent.

  .PARAMETER Pathsum
	Shows summary information about hosts and paths. This option cannot be
	used with -d.

  .PARAMETER Persona
	Shows the host persona settings in effect. This option cannot be used
	with -d.

  .PARAMETER Listpersona
	Lists the defined host personas. This option cannot be used with -d.

  .PARAMETER NoName
	Shows only host paths (WWNs and iSCSI names) not assigned to any host.
	This option cannot be used with -d.

  .PARAMETER Domain 
	Shows only hosts that are in domains or domain sets that match one or
	more of the specifier <domainname_or_pattern> or set <domainset>
	arguments. The set name <domain_set> must start with "set:". This
	specifier does not allow listing objects within a domain of which the
	user is not a member.

  .PARAMETER CRCError
	Shows the CRC error counts for the host/port.
	
  .PARAMETER hostName
    Specify new name of the host
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-Host  
    LASTEDIT: 19/11/2019
    KEYWORDS: Get-Host
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Domain,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$D,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Verb,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$CHAP,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Descriptor,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Agent,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Pathsum,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Persona,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Listpersona,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$NoName,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$CRCError,
		
		[Parameter(Position=11, Mandatory=$false)]
		[System.String]
		$hostName,
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-Host - validating input values" $Debug 
	#check if connection object contents are null/empty
	if (!$SANConnection)
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
				Write-DebugLog "Stop: Exiting Get-Host since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-Host since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if($cliresult1 -match "FAILURE :")
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	
	$CurrentId = $CurrentName = $CurrentPersona = $null
	$ListofvHosts = @()	
	
	$GetHostCmd = "showhost "
	
	if ($Domain)
	{
		$GetHostCmd +=" -domain $Domain"
	}
	if ($D)
	{
		$GetHostCmd +=" -d "
	}
	if ($Verb)
	{
		$GetHostCmd +=" -verbose "
	}
	if ($CHAP)
	{
		$GetHostCmd +=" -chap "
	}
	if ($Descriptor)
	{
		$GetHostCmd +=" -desc "
	}
	if ($Agent)
	{
		$GetHostCmd +=" -agent "
	}
	if ($Pathsum)
	{
		$GetHostCmd +=" -pathsum "
	}
	if ($Persona)
	{
		$GetHostCmd +=" -persona "
	}
	if ($Listpersona)
	{
		$GetHostCmd +=" -listpersona "
	}
	if ($NoName)
	{
		$GetHostCmd +=" -noname "
	}
	if ($CRCError)
	{
		$GetHostCmd +=" -lesb "
	}	
	if($hostName)
	{
		$objType = "host"
		$objMsg  = "hosts"
		
		## Check Host Name 
		##
		if ( -not (Test-CLIObject -objectType $objType -objectName $hostName -objectMsg $objMsg -SANConnection $SANConnection))
		{
			write-debuglog "host $hostName does not exist. Nothing to List" "INFO:" 
			return "FAILURE : No host $hostName found"
		}
	}
	
	$GetHostCmd+=" $hostName"
	#write-host "$GetHostCmd"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $GetHostCmd	
	write-debuglog "Get list of Hosts" "INFO:" 
	if ($Result -match "no hosts listed")
	{
		return "Success : no hosts listed"
	}
	if ($Verb -or $Descriptor)
	{
		return $Result
	}
	
	$tempFile = [IO.Path]::GetTempFileName()
	$Header = $Result[0].Trim() -replace '-WWN/iSCSI_Name-' , ' Address' 
	
	set-content -Path $tempFile -Value $Header
	$Result_Count = $Result.Count - 3
	if($Agent)
	{
		$Result_Count = $Result.Count - 3			
	}
	if($Result.Count -gt 3)
	{	
		$CurrentId = $null
		$CurrentName = $null
		$CurrentPersona = $null		
		$address = $null
		$Port = $null
		
		$Flg = "false"
		
		foreach ($s in $Result[1..$Result_Count])
		{	
			if($Pathsum)
			{
				$s =  [regex]::Replace($s , "," , "|"  )  # Replace ','  with "|"	
			}			
			if($Flg -eq "true")
			{
				$temp = $s.Trim()
				$temp1 = $temp.Split(',')
				if($temp1[0] -match "--")
				{
					$temp =  [regex]::Replace($temp , "--" , ""  )  # Replace '--'  with ""				
					$s = $temp
				}
			}
		    $Flg = "true"
			
			$match = [regex]::match($s, "^  +")   # Match Line beginning with 1 or more spaces
			if (-not ($match.Success))
			{
				$s= $s.Trim()				
				$s= [regex]::Replace($s, " +" , "," )	# Replace spaces with comma (,)
								
				$sTemp = $s.Split(',')
				$TempCnt = $sTemp.Count
				if($TempCnt -eq 2)
				{
					$address = $sTemp[0]
					$Port = $sTemp[1] # [regex]::Replace($sTemp[4] , "-+" , ""  )  # Replace '----'  with ""  
				}
				else
				{
					$CurrentId =  $sTemp[0]
					$CurrentName = $sTemp[1]
					$CurrentPersona = $sTemp[2]			
					$address = $sTemp[3]
					$Port = $sTemp[4] # [regex]::Replace($sTemp[4] , "-+" , ""  )  # Replace '----'  with ""
				}
				
				$vHost = New-Object -TypeName _vHost 
				$vHost.ID = $CurrentId
				$vHost.Persona = $currentPersona
				$vHost.Name = $CurrentName
				$vHost.Address = $address
				$vHost.Port= $port
			}			
			else
			{
				$s = $s.trim()
				$s= [regex]::Replace($s, " +" , "," )								
				$sTemp = $s.Split(',')
				$TempCnt1 = $sTemp.Count
				
				if($TempCnt1 -eq 2)
				{
					$address = $sTemp[0]
					$Port = $sTemp[1] # [regex]::Replace($sTemp[4] , "-+" , ""  )  # Replace '----'  with ""  
				}
				else
				{
					$CurrentId =  $sTemp[0]
					$CurrentName = $sTemp[1]
					$CurrentPersona = $sTemp[2]			
					$address = $sTemp[3]
					$Port = $sTemp[4] # [regex]::Replace($sTemp[4] , "-+" , ""  )  # Replace '----'  with ""
				}
				
				$vHost = New-Object -TypeName _vHost 
				$vHost.ID = $CurrentId
				$vHost.Persona = $currentPersona
				$vHost.Name = $CurrentName
				$vHost.Address = $address
				$vHost.Port= $port
			}
			
			$ListofvHosts += $vHost		
		}	
	}	
	else
	{
		del $tempFile
		return "Success : No Data Available for Host Name :- $hostName"
	}
	del $tempFile
	$ListofvHosts	
	
} # ENd Get-Host

#####################################################################################################################
## FUNCTION Get-HostSet
#####################################################################################################################
Function Get-HostSet
{
<#
  .SYNOPSIS
    show host set(s) information	
  
  .DESCRIPTION
    The showhostset command lists the host sets defined on the storage system and their members.
        
  .EXAMPLE
    Get-HostSet	
	List all host set information

  .EXAMPLE
	Get-HostSet -D myset
	Show the details of myset
	
  .EXAMPLE
	Get-HostSet -hostSetName "MyVVSet"	
	List Specific HostSet name "MyVVSet"
	
  .EXAMPLE	
	Get-HostSet -hostName "MyHost"	 
	Show the host sets containing host "MyHost"	
	
  .EXAMPLE	
	Get-HostSet -D	 
	Show a more detailed listing of each set
	
  .PARAMETER D
	Show a more detailed listing of each set.
	
  .PARAMETER hostSetName 
    Specify name of the hostsetname to be listed.

  .PARAMETER hostName 
    Show host sets that contain the supplied hostnames or patterns.

  .PARAMETER summary 
    Shows host sets with summarized output with host set names and number of hosts in those sets.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-HostSet  
    LASTEDIT: 29/05/2021
    KEYWORDS: Get-HostSet
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$hostSetName,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$hostName,

		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$D,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$summary,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-HostSet - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-HostSet since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-HostSet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}

	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$GetHostSetCmd = "showhostset "
	if($D)
	{
		$GetHostSetCmd +=" -d"
	}
	if($summary)
	{
		$GetHostSetCmd +=" -summary"
	}	
	if ($hostName)
	{		
		$GetHostSetCmd +=" -host $hostName"
	}
	if ($hostSetName)
	{		
		$GetHostSetCmd +=" $hostSetName"
	}	
	else
	{
		write-debuglog "HostSet parameter is empty. Simply return all hostset information " "INFO:"
	}
		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $GetHostSetCmd
	$Result
	
	<#
	if($Result -match "total")
	{	
		if($summary)
		{
			$ID = $null
			$Name = $null
			$HOST_Cnt = $null
			$VVOLSC = $null
			$Flashcache = $null
			$QoS = $null
			$RC_host = $null

			$ListofvHosts = @()	
			
			$tempFile = [IO.Path]::GetTempFileName()
			$Header = $Result[0].Trim() -replace 'id' , ' ID' 
			set-content -Path $tempFile -Value $Header
			
			$LastItem = $Result.Count -3  
			#Write-Host " Result Count =" $Result.Count
			foreach ($s in  $Result[1..$LastItem] )
			{				
				$s= $s.Trim()				
				$s= [regex]::Replace($s, " +" , "," )	# Replace spaces with comma (,)						
				$sTemp = $s.Split(',')
				$TempCnt = $sTemp.Count			
				
				if($TempCnt -gt 1)
				{
					$ID = $sTemp[0]
					$Name = $sTemp[1]
					$HOST_Cnt = $sTemp[2]
					$VVOLSC = $sTemp[3]
					$Flashcache = $sTemp[4]
					$QoS = $sTemp[5]
					$RC_host = $sTemp[6]						
				}				
				$vHostSummary = New-Object -TypeName _vHostSetSummary
				$vHostSummary.ID = $ID
				$vHostSummary.Name = $Name
				$vHostSummary.HOST_Cnt = $HOST_Cnt
				$vHostSummary.VVOLSC = $VVOLSC
				$vHostSummary.Flashcache = $Flashcache
				$vHostSummary.QoS = $QoS
				$vHostSummary.RC_host = $RC_host
				
				$ListofvHosts += $vHostSummary
			}
		}
		else
		{
			$ID = $null
			$Name = $null
			$Membr = $null		
			#$address = $null
			
			$ListofvHosts = @()	
			
			$tempFile = [IO.Path]::GetTempFileName()
			$Header = $Result[0].Trim() -replace 'id' , ' ID' 
			set-content -Path $tempFile -Value $Header
		
			$LastItem = $Result.Count -3  
			#Write-Host " Result Count =" $Result.Count
			foreach ($s in  $Result[1..$LastItem] )
			{				
				$s= $s.Trim()				
				$s= [regex]::Replace($s, " +" , "," )	# Replace spaces with comma (,)						
				$sTemp = $s.Split(',')
				$TempCnt = $sTemp.Count			
				
				if($TempCnt -gt 1)
				{
					$ID =  $sTemp[0]
					$Name = $sTemp[1]
					$Membr = $sTemp[2]	
				}
				else
				{
					$Membr = $sTemp[0]
				}
				
				$vHost = New-Object -TypeName _vHostSet 
				$vHost.ID = $ID
				$vHost.Name = $Name
				$vHost.Members = $Membr			
				
				$ListofvHosts += $vHost
			}
		}
	}
	else
	{
		return $Result
	}
	del $tempFile
	$ListofvHosts
	
	<#
	if($Result -match "total")
	{
		Return $Result + "`n `n Success : Executing Get-HostSet"
	}
	else
	{
		return $Result
	}
	#>
	
} # End Get-HostSet

############################################################################################################################################
## FUNCTION New-Host
############################################################################################################################################
Function New-Host
{
<#
  .SYNOPSIS
    Creates a new host.
  
  .DESCRIPTION
	Creates a new host.
        
  .EXAMPLE
    New-Host -HostName HV01A -Persona 2 -WWN 10000000C97B142E
	Creates a host entry named HV01A with WWN equals to 10000000C97B142E
	
  .EXAMPLE	
	New-Host -HostName HV01B -Persona 2 -iSCSI
	Creates a host entry named HV01B with iSCSI equals to iqn.1991-06.com.microsoft:dt-391-xp.hq.3par.com
	
  .EXAMPLE
    New-Host -HostName HV01A -Persona 2 

  .EXAMPLE New-Host -HostName Host3 -iSCSI

  .EXAMPLE New-Host -HostName Host4 -iSCSI -Domain ZZZ
	
  .PARAMETER HostName
    Specify new name of the host
	
  .PARAMETER Add
	Add the specified WWN(s) or iscsi_name(s) to an existing host (at least
	one WWN or iscsi_name must be specified).  Do not specify host persona.

  .PARAMETER Domain
	Create the host in the specified domain or domain set. The default is to
	create it in the current domain, or no domain if the current domain is
	not set. The domain set name must start with "set:".

  .PARAMETER Forces
	Forces the tear down of lower priority VLUN exports if necessary.

  .PARAMETER Persona
	Sets the host persona that specifies the personality for all ports
	which are part of the host set.  This selects certain variations in
	scsi command behavior which certain operating systems expect.
	<hostpersonaval> is the host persona id number with the desired
	capabilities.  These can be seen with showhost -listpersona.

  .PARAMETER Location
	Specifies the host's location.

  .PARAMETER IPAddress
	Specifies the host's IP address.

  .PARAMETER OS
	Specifies the operating system running on the host.

  .PARAMETER Model
	Specifies the host's model.

  .PARAMETER Contact
	Specifies the host's owner and contact information.

  .PARAMETER Comment
	Specifies any additional information for the host.

  .PARAMETER NSP
	Specifies the desired relationship between the array port(s) and host
	for target-driven zoning. Multiple array ports can be specified by
	either using a pattern or a comma-separated list.  This option is used
	only when the Smart SAN license is installed.  At least one WWN needs
	to be specified with this option.
	
  .PARAMETER WWN
	Specifies the World Wide Name(WWN) to be assigned or added to an
	existing host. This specifier can be repeated to specify multiple WWNs.
	This specifier is optional.

  .PARAMETER IscsiName
	Host iSCSI name to be assigned or added to a host. This specifier is
	optional.

  .PARAMETER iSCSI
    when specified, it means that the address is an iSCSI address
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  New-Host  
    LASTEDIT: 19/11/2019
    KEYWORDS: New-Host
   
	.Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$HostName,	
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$Iscsi,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Add,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Domain,
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$Forces, 
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Persona = 2,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$Location,
		
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$IPAddress,
		
		[Parameter(Position=8, Mandatory=$false)]
		[System.String]
		$OS,
		
		[Parameter(Position=9, Mandatory=$false)]
		[System.String]
		$Model,
		
		[Parameter(Position=10, Mandatory=$false)]
		[System.String]
		$Contact,
		
		[Parameter(Position=11, Mandatory=$false)]
		[System.String]
		$Comment,
		
		[Parameter(Position=12, Mandatory=$false)]
		[System.String]
		$NSP,
		
		[Parameter(Position=13, Mandatory=$false)]
		[System.String]
		$WWN,
		
		[Parameter(Position=14, Mandatory=$false)]
		[System.String]
		$IscsiName,
		
		[Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In New-Host - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting New-Host since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet New-Host since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$cmd ="createhost "
	
	if($Iscsi)
	{
		$cmd +="-iscsi "
	}
	if($Add)
	{
		$cmd +="-add "
	}
	if($Domain)
	{
		$cmd +="-domain $Domain "
	}
	if($Forces)
	{
		$cmd +="-f "
	}
	if($Persona)
	{
		$cmd +="-persona $Persona "
	}
	if($Location)
	{
		$cmd +="-loc $Location "
	}
	if($IPAddress)
	{
		$cmd +="-ip $IPAddress "
	}
	if($OS)
	{
		$cmd +="-os $OS "
	}
	if($Model)
	{
		$cmd +="-model $Model "
	}
	if($Contact)
	{
		$cmd +="-contact $Contact "
	}
	if($Comment)
	{
		$cmd +="-comment $Comment "
	}
	if($NSP)
	{
		$cmd +="-port $NSP "
	}
	if ($HostName)
	{
		$cmd +="$HostName "
	}
	else
	{
		write-debugLog "No name specified for new host. Skip creating host" "ERR:"
		Get-help New-Host
		return
	}
	if ($WWN)
	{
		$cmd +="$WWN "
	}
	if ($IscsiName)
	{
		$cmd +="$IscsiName "
	}
		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds $cmd	
		
	if([string]::IsNullOrEmpty($Result))
	{
		write-host""
		return "Success : New-Host command executed Host Name : $HostName is created."
	}
	else
	{
		write-host""
		return $Result
	}	   
	 
} # End New-Host

############################################################################################################################################
## FUNCTION New-HostSet
############################################################################################################################################
Function New-HostSet
{
<#
  .SYNOPSIS
    Creates a new host set.
  
  .DESCRIPTION
	Creates a new host set.
        
  .EXAMPLE
    New-HostSet -HostSetName xyz 
	Creates an empty host set named "xyz"

  .EXAMPLE
	To create an empty hostset:
    New-HostSet hostset

  .EXAMPLE
    To add a host to the set:
    New-HostSet -Add -HostSetName hostset -HostName hosta

  .EXAMPLE
    To create a host set with hosts in it:
    New-HostSet -HostSetName hostset -HostName "host1 host2"
    or
    New-HostSet -HostSetName set:hostset -HostName "host1 host2" 

  .EXAMPLE
    To create a host set with a comment and a host in it:
    New-HostSet -Comment "A host set" -HostSetName hostset -HostName hosta
	
  .EXAMPLE
    New-HostSet -HostSetName xyz -Domain xyz
	Create the host set in the specified domain
	
  .EXAMPLE
    New-HostSet -hostSetName HV01C-HostSet -hostName "MyHost"
	Creates an empty host set and  named "HV01C-HostSet" and adds host "MyHost" to hostset
			(or)
	Adds host "MyHost" to hostset "HV01C-HostSet" if hostset already exists
	
  .PARAMETER HostSetName
    Specify new name of the host set

  .PARAMETER hostName
    Specify new name of the host

  .PARAMETER Add
	Specifies that the hosts listed should be added to an existing set.
	At least one host must be specified.

  .PARAMETER Comment
	Specifies any comment or additional information for the set. The
	comment can be up to 255 characters long. Unprintable characters are
	not allowed.

  .PARAMETER Domain
	Create the host set in the specified domain. For an empty set the
	default is to create it in the current domain, or no domain if the
	current domain is not set. A host set must be in the same domain as
	its members; if hosts are specified as part of the creation then
	the set will be created in their domain. The -domain option should
	still be used to specify which domain to use for the set when the
	hosts are members of domain sets. A domain cannot be specified
	when adding a host to an existing set with the -add option.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  New-HostSet  
    LASTEDIT:19/11/2019
    KEYWORDS: New-HostSet
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$HostSetName,

		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$hostName,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Add,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Comment,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Domain,				
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In New-HostSet - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting New-HostSet since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet New-HostSet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	
	$cmdCrtHostSet =" createhostset "
	
	if($Add)
	{
		$cmdCrtHostSet +="-add "
	}
	if($Comment)
	{
		$cmdCrtHostSet +="-comment $Comment "
	}
	if($Domain)
	{
		$cmdCrtHostSet +="-domain $Domain "
	}	
	if ($HostSetName)
	{
		$cmdCrtHostSet +=" $HostSetName "
	}
	else
	{
		write-debugLog "No name specified for new host set. Skip creating host set" "ERR:"
		Get-help New-HostSet
		return	
	}
	if($hostName)
	{
		$cmdCrtHostSet +=" $hostName "
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmdCrtHostSet
	if($Add)
	{
		if([string]::IsNullOrEmpty($Result))
		{
			write-host""
			return "Success : New-HostSet command executed Host Name : $hostName is added to Host Set : $HostSetName"
		}
		else
		{
			write-host""
			return $Result
		}
	}	
	else
	{
		if([string]::IsNullOrEmpty($Result))
		{
			write-host""
			return "Success : New-HostSet command executed Host Set : $HostSetName is created with Host : $hostName"
		}
		else
		{
			write-host""
			return $Result
		}			
	}	
		 
} # End New-HostSet

############################################################################################################################################
## FUNCTION Remove-Host
############################################################################################################################################
Function Remove-Host
{
<#
  .SYNOPSIS
    Removes a host.
  
  .DESCRIPTION
	Removes a host.
 
  .EXAMPLE
    Remove-Host -hostName HV01A 
	Remove the host named HV01A
	
  .EXAMPLE
    Remove-Host -hostName HV01A -address 10000000C97B142E
	Remove the WWN address of the host named HV01A
	
  .EXAMPLE	
	Remove-Host -hostName HV01B -iSCSI -Address  iqn.1991-06.com.microsoft:dt-391-xp.hq.3par.com
	Remove the iSCSI address of the host named HV01B
	
  .PARAMETER hostName
    Specify name of the host.

  .PARAMETER Address
    Specify the list of addresses to be removed.
	
  .PARAMETER Rvl
    Remove WWN(s) or iSCSI name(s) even if there are VLUNs exported to the host.

  .PARAMETER iSCSI
    Specify twhether the address is WWN or iSCSI
	
  .PARAMETER Pat
	Specifies that host name will be treated as a glob-style pattern and that all hosts matching the specified pattern are removed. T

  .PARAMETER  Port 
	Specifies the NSP(s) for the zones, from which the specified WWN will be removed in the target driven zoning. 
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Remove-Host  
    LASTEDIT: 19/11/2019
    KEYWORDS: Remove-Host
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$hostName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[switch] $Rvl,
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[switch] $ISCSI = $false,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch] $Pat = $false,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Port,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
		$Address,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Remove-Host - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Remove-Host since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Remove-Host since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}      
	if ($hostName)
	{
		$objType = "host"
		$objMsg  = "hosts"
		
		## Check Host Name 
		if ( -not ( Test-CLIObject -objectType $objType -objectName $hostName -objectMsg $objMsg -SANConnection $SANConnection)) 
		{
			write-debuglog " Host $hostName does not exist. Nothing to remove"  "INFO:"  
			return "FAILURE : No host $hostName found"
		}
		else
		{
		    $RemoveCmd = "removehost "			
			if ($address)
			{			
				if($Rvl)
				{
					$RemoveCmd += " -rvl "
				}	
				if($ISCSI)
				{
					$RemoveCmd += " -iscsi "
				}
				if($Pat)
				{
					$RemoveCmd += " -pat "
				}
				if($Port)
				{
					$RemoveCmd += " -port $Port "
				}
			}			
			$Addr = [string]$address 
			$RemoveCmd += " $hostName $Addr"
			$Result1 = Get-HostSet -hostName $hostName -SANConnection $SANConnection
			
			if(($Result1 -match "No host set listed"))
			{
				$Result2 = Invoke-CLICommand -Connection $SANConnection -cmds  $RemoveCmd
				write-debuglog "Removing host  with the command --> $RemoveCmd" "INFO:" 
				if([string]::IsNullOrEmpty($Result2))
				{
					return "Success : Removed host $hostName"
				}
				else
				{
					return "FAILURE : While removing host $hostName"
				}				
			}
			else
			{
				$Result3 = Invoke-CLICommand -Connection $SANConnection -cmds  $RemoveCmd
				return "FAILURE : Host $hostName is still a member of set"
			}			
		}				
	}
	else
	{
		write-debuglog  "No host name mentioned to remove" "INFO:"
		Get-help Remove-Host			
	}
} # End of Remove-Host

#####################################################################################################################
## FUNCTION Remove-HostSet
#####################################################################################################################

Function Remove-HostSet
{
<#
  .SYNOPSIS
    Remove a host set or remove hosts from an existing set
  
  .DESCRIPTION
	Remove a host set or remove hosts from an existing set
        
  .EXAMPLE
    Remove-HostSet -hostsetName "MyHostSet"  -force 
	Remove a hostset  "MyHostSet"
	
  .EXAMPLE
	Remove-HostSet -hostsetName "MyHostSet" -hostName "MyHost" -force
	Remove a single host "MyHost" from a hostset "MyHostSet"
	
  .PARAMETER hostsetName 
    Specify name of the hostsetName

  .PARAMETER hostName 
    Specify name of  a host to remove from hostset
 
  .PARAMETER force
	If present, perform forcible delete operation
	
  .PARAMETER Pat
	Specifies that both the set name and hosts will be treated as glob-style patterns.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
              
  .Notes
    NAME:  Remove-HostSet 
    LASTEDIT: 19/11/2019
    KEYWORDS: Remove-HostSet
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[System.String]
		$hostsetName,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$hostName,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$force,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Pat,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		

	Write-DebugLog "Start: In Remove-HostSet - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Remove-HostSet since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Remove-HostSet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$RemovehostsetCmd = "removehostset "
	if ($hostsetName)
	{
		if (!($force))
		{
			write-debuglog "no force option selected to remove hostset, Exiting...." "INFO:"
			return "FAILURE : no -force option selected to remove hostset"
		}
		$objType = "hostset"
		$objMsg  = "host set"
		
		## Check hostset Name 
		##
		if ( -not ( Test-CLIObject -objectType $objType -objectName $hostsetName -objectMsg $objMsg -SANConnection $SANConnection)) 
		{
			write-debuglog " hostset $hostsetName does not exist. Nothing to remove"  "INFO:"  
			return "FAILURE : No hostset $hostsetName found"
		}
		else
		{	
			if($force)
			{
				$RemovehostsetCmd += " -f "
			}
			if($Pat)
			{
				$RemovehostsetCmd += " -pat "
			}
			
			$RemovehostsetCmd += " $hostsetName "
			
			if($hostName)
			{
				$RemovehostsetCmd +=" $hostName"
			}
		
			$Result2 = Invoke-CLICommand -Connection $SANConnection -cmds  $RemovehostsetCmd
			
			write-debuglog "Removing hostset  with the command --> $RemovehostsetCmd" "INFO:"
			if([string]::IsNullOrEmpty($Result2))
			{
				if($hostName)
				{
					return "Success : Removed host $hostName from hostset $hostsetName "
				}
				else
				{
					return "Success : Removed hostset $hostsetName "
				}
			}
			else
			{
				return "FAILURE : While removing hostset $hostsetName"
			}			
		}
	}
	else
	{
			write-debuglog  "No hostset name mentioned to remove" "INFO:"
			Get-help Remove-HostSet
	}
} # End of Remove-HostSet 

##########################################################################
######################### FUNCTION Update-HostSet ####################
##########################################################################
Function Update-HostSet()
{
<#
  .SYNOPSIS
   Update-HostSet - set parameters for a host set

  .DESCRIPTION
   The Update-HostSet command sets the parameters and modifies the properties of a host set.

  .EXAMPLE

  .PARAMETER Setname
	Specifies the name of the host set to modify.
  
  .PARAMETER Comment
   Specifies any comment or additional information for the set. The comment can be up to 255 characters long. Unprintable characters are not allowed.

  .PARAMETER NewName
   Specifies a new name for the host set, using up to 27 characters in length.

  .Notes
    NAME: Update-HostSet
    LASTEDIT 19/11/2019
    KEYWORDS: Update-HostSet
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Comment,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$NewName,

	[Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
	[System.String]                         
	$Setname,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Update-HostSet - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Update-HostSet since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Update-HostSet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

	$Cmd = " sethostset "
	
 if($Comment)
 {
	$Cmd += " -comment $Comment "
 }

 if($NewName)
 {
	$Cmd += " -name $NewName "
 } 

 if($Setname)
 {
	$Cmd += " $Setname "
 } 
 else
 {
	return "Setname is mandatory Please enter..."
 } 
 
 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Update-HostSet Command -->" INFO: 
 
 if ([string]::IsNullOrEmpty($Result))
 {
    Get-HostSet -hostSetName $NewName
 }
 else
 { 
	Return $Result
 }
} ##  End-of Update-HostSet


Export-ModuleMember Get-Host , Get-HostSet , New-Host , New-HostSet , Remove-Host , Remove-HostSet , Update-HostSet