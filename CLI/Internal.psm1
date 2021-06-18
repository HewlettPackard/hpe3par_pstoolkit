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
##	File Name:		Internal.psm1
##	Description: 	Internal cmdlets
##		
##	Created:		January 2020
##	Last Modified:	May 2021
##	History:		v3.0 - Created
##                  v3.1 - Modified to add HPE Alletra 9000
#####################################################################################

$Info = "INFO:"
$Debug = "DEBUG:"
$global:VSLibraries = Split-Path $MyInvocation.MyCommand.Path
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

######################################################################################################################
## FUNCTION Close-Connection
######################################################################################################################
Function Close-Connection
{
<#
  .SYNOPSIS   
   Session Management Command to close the connection
   
  .DESCRIPTION
   Session Management Command to close the connection
   
  .EXAMPLE
	Close-Connection
		
  .Notes
    NAME: Close-Connection  
    LASTEDIT: January 2020
    KEYWORDS: Close-Connection 
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
 [CmdletBinding()]
	param(
				
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)
	
	Write-DebugLog "Start : in Close-Connection function " "INFO:"
	
	if (($global:WsapiConnection) -or ($global:ConnectionType -eq "WSAPI")){
		return "A WSAPI Session is enabled. Use Close-WSAPIConnection cmdlet to close and exit from the current WSAPI session"
	}
	
	if (!$SANConnection){
		return "No active CLI/PoshSSH session/connection exists"
	}	
	
	$SANCOB = $SANConnection		
	$clittype = $SANCOB.CliType
	$SecnId =""
	
	if($clittype -eq "SshClient")
	{
		$SecnId = $SANCOB.SessionId
	}
	
	$global:SANConnection = $null
	#write-host "$global:SANConnection"
	$SANConnection = $global:SANConnection
	
	#write-host "$SANConnection"
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		#write-host "$Validate1"
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			#write-host "$Validate2"
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username, password, IPAaddress are null/empty. Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting GGet-UserConnection since SAN connection object values are null/empty" $Debug
				if($clittype -eq "SshClient")
				{
					$res = Remove-SSHSession -Index $SecnId 
				}
				
				write-host ""				
				# Set to the default prompt as current path
				if ($global:SANConnection -eq $null)
				{
					$global:ConnectionType = $null
					Function global:prompt {(Get-Location).Path + ">"}
				}
				return "Success : Exiting SAN connection session End`n"
			}
		}
	}	
} # End Function Close-Connection

########################################
##### FUNCTION Get-CmdList   ###########
########################################
Function Get-CmdList{
<#
  .SYNOPSIS
    Get list of  all HPE Alletra 9000, Primera and 3PAR PowerShell cmdlets
  
  .DESCRIPTION
    Note : This cmdlet (Get-CmdList) is deprecated and will be removed in a 
	subsequent release of PowerShell Toolkit. Consider using the cmdlet (Get-CmdList) instead.
  
    Get list of  all HPE Alletra 9000, Primera and 3PAR PowerShell cmdlets 
        
  .EXAMPLE
    Get-CmdList	
	List all available HPE Alletra 9000, Primera and 3PAR PowerShell cmdlets.
	
  .EXAMPLE
    Get-CmdList -WSAPI
	List all available HPE Alletra 9000, Primera and 3PAR PowerShell WSAPI cmdlets only.
	
  .EXAMPLE
    Get-CmdList -CLI
	List all available HPE Alletra 9000, Primera and 3PAR PowerShell CLI cmdlets only.
	
  .Notes
    NAME:  Get-CmdList
    CREATED: 05/14/2015
    LASTEDIT: 05/26/2020
    KEYWORDS: Get-CmdList
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
 [CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[Switch]
		$CLI, 
		
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$WSAPI
	)
 
    $Array = @()
    
    #$psToolKitModule = (Get-Module PowerShellToolkitForHPEPrimeraAnd3PAR);
	$psToolKitModule = (Get-Module HPEStoragePowerShellToolkit);
    $nestedModules = $psToolKitModule.NestedModules;
    $noOfNestedModules = $nestedModules.Count;
    
    $totalCmdlets = 0;
    $totalCLICmdlets = 0;
    $totalWSAPICmdlets = 0;
    $totalDeprecatedCmdlets = 0;

    # If chosen to select all WSAPI cmdlets
    if($WSAPI)
    {
        foreach ($nestedModule in $nestedModules[0..$noOfNestedModules])
        {        
            $ExpCmdlets = $nestedModule.ExportedCommands;

            if ($nestedModule.Path.Contains("\WSAPI\"))
            {    
                foreach ($h in $ExpCmdlets.GetEnumerator()) 
                {            
                    $Result1 = "" | Select CmdletName, CmdletType, ModuleVersion, SubModule, Module, Remarks
                    $Result1.CmdletName = $($h.Key);            
                    $Result1.ModuleVersion = $psToolKitModule.Version;
                    $Result1.CmdletType = "WSAPI";
                    $Result1.SubModule = $nestedModule.Name;
                    $Result1.Module = $psToolKitModule.Name;
                    
                    If ($nestedModule.Name -eq "HPE3PARPSToolkit-WSAPI")
                    {
                        $Result1.Remarks = "Deprecated";
                        $totalDeprecatedCmdlets += 1;
                    }
                    $totalCmdlets += 1;
                    $totalWSAPICmdlets += 1;
                
                    $Array += $Result1
                }
            }
        }
    }
    # If chosen to select all CLI cmdlets
    elseif($CLI)
    {
        foreach ($nestedModule in $nestedModules[0..$noOfNestedModules])
        {        
            $ExpCmdlets = $nestedModule.ExportedCommands;    
                
            if ($nestedModule.Path.Contains("\CLI\"))
            {    
                foreach ($h in $ExpCmdlets.GetEnumerator()) 
                {            
                    $Result1 = "" | Select CmdletName, CmdletType, ModuleVersion, SubModule, Module, Remarks
                    $Result1.CmdletName = $($h.Key);            
                    $Result1.ModuleVersion = $psToolKitModule.Version;
                    $Result1.CmdletType = "CLI";
                    $Result1.SubModule = $nestedModule.Name;
                    $Result1.Module = $psToolKitModule.Name;
                    
                    If ($nestedModule.Name -eq "HPE3PARPSToolkit-CLI")
                    {
                        $Result1.Remarks = "Deprecated";
                        $totalDeprecatedCmdlets += 1;
                    }

                    $totalCmdlets += 1;
                    $totalCLICmdlets += 1;
                
                    $Array += $Result1
                }
            }
        }
    }
    # If chosen to select all cmdlets
    else
    {    
        foreach ($nestedModule in $nestedModules[0..$noOfNestedModules])
        {        
            if ($nestedModule.Path.Contains("\CLI\") -or $nestedModule.Path.Contains("\WSAPI\"))        
            {
                $ExpCmdlets = $nestedModule.ExportedCommands;    
                
                foreach ($h in $ExpCmdlets.GetEnumerator()) 
                {            
                    $Result1 = "" | Select CmdletName, CmdletType, ModuleVersion, SubModule, Module, Remarks
                    $Result1.CmdletName = $($h.Key);            
                    $Result1.ModuleVersion = $psToolKitModule.Version;                
                    $Result1.SubModule = $nestedModule.Name;
                    $Result1.Module = $psToolKitModule.Name;                
                    $Result1.CmdletType = if ($nestedModule.Path.Contains("\CLI\")) {"CLI"} else {"WSAPI"}

                    If ($nestedModule.Name -eq "HPE3PARPSToolkit-WSAPI" -or $nestedModule.Name -eq "HPE3PARPSToolkit-CLI")
                    {
                        $Result1.Remarks = "Deprecated";
                        $totalDeprecatedCmdlets += 1;
                    }

                    $totalCmdlets += 1;                            
                    $Array += $Result1
                }            
            }        
        }
    }

    $Array | Format-Table
    $Array = $null;
    Write-Host "$totalCmdlets Cmdlets listed. ($totalDeprecatedCmdlets are deprecated)";

 }# Ended Get-CmdList
 
 #########################################################################
################### FUNCTION Get-FcPorts ################################
#########################################################################
Function Get-FcPorts
{
<#
   .SYNOPSIS
	Query to get FC ports

   .DESCRIPTION
	Get information for FC Ports
 
   .PARAMETER SANConnection
	Connection String to the array
  	
   .EXAMPLE
	Get-FcPorts 
			
  .Notes
    NAME:  Get-FcPorts
    LASTEDIT: January 2020
    KEYWORDS: Get-FcPorts
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3PAR cli.exe
 #>
 
[CmdletBinding()]
	Param(	
			[Parameter()]
			[_SANConnection]
			$SANConnection=$Global:SANConnection
		)
	$plinkresult = Test-PARCli -SANConnection $SANConnection 
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
			
	Write-Host "--------------------------------------`n"
	Write-host "Controller,WWN"	

	$ListofPorts = Get-HostPorts -SANConnection $SANConnection| where { ( $_.Type -eq "host" ) -and ($_.Protocol -eq "FC")}

	$Port_Pattern = "(\d):(\d):(\d)"							# Pattern matches value of port: 1:2:3
	$WWN_Pattern = "([0-9a-f][0-9a-f])" * 8						# Pattern matches value of WWN

	foreach ($Port in $ListofPorts)
	{
		$NSP  = $Port.Device
		#$SW = $NSP.Split(':')[-1]	
		
		$NSP = $NSP -replace $Port_Pattern , 'N$1:S$2:P$3'
		
		$WWN = $Port.Port_WWN
		$WWN = $WWN -replace $WWN_Pattern , '$1:$2:$3:$4:$5:$6:$7:$8'

		Write-Host "$NSP,$WWN"
		Write-host ""
	}
} # END FUNCTION Get-FcPorts

###########################################################################
####################### FUNCTION Get-FcPortsToCsv #########################
###########################################################################

Function Get-FcPortsToCsv
{
<#
  	.SYNOPSIS
		Query to get FC ports

	.DESCRIPTION
		Get information for FC Ports
 
	.PARAMETER ResultFile
		CSV file created that contains all Ports definitions
		
	.PARAMETER Demo
		Switch to list the commands to be executed 
  	
	.EXAMPLE
    	Get-FcPortsToCsv -ResultFile C:\3PAR-FC.CSV
			creates C:\3PAR-FC.CSV and stores all FCPorts information
			
  .Notes
    NAME:  Get-FcPortsToCsv
    LASTEDIT: January 2020
    KEYWORDS: Get-FcPortsToCsv
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3PAR cli.exe
 #>
 
[CmdletBinding()]
	Param(	
			[Parameter()]
			[_SANConnection]
			$SANConnection = $global:SANConnection,
			
			[Parameter()]
			[String]$ResultFile
		)

	$plinkresult = Test-PARCli -SANConnection $SANConnection 
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if(!($ResultFile)){
		return "FAILURE : Please specify csv file path `n example: -ResultFIle C:\portsfile.csv"
	}	
	Set-Content -Path $ResultFile -Value "Controller,WWN,SWNumber"

	$ListofPorts = Get-HostPorts -SANConnection $SANConnection| where { ( $_.Type -eq "host" ) -and ($_.Protocol -eq "FC")}
	if (!($ListofPorts)){
		return "FAILURE : No ports to display"
	}

	$Port_Pattern = "(\d):(\d):(\d)"							# Pattern matches value of port: 1:2:3
	$WWN_Pattern = "([0-9a-f][0-9a-f])" * 8						# Pattern matches value of WWN

	foreach ($Port in $ListofPorts)
	{
		$NSP  = $Port.Device
		$SW = $NSP.Split(':')[-1]
		if ( [Bool]($SW % 2) )			# Check whether the number is odd
		{
			$SwitchNumber = 1
		}
		else
		{
			$SwitchNumber = 2
		}
		
		
		$NSP = $NSP -replace $Port_Pattern , 'N$1:S$2:P$3'
		
		$WWN = $Port.Port_WWN
		$WWN = $WWN -replace $WWN_Pattern , '$1:$2:$3:$4:$5:$6:$7:$8'

		Add-Content -Path $ResultFile -Value "$NSP,$WWN,$SwitchNumber"
	}
	Write-DebugLog "FC ports are stored in $ResultFile" $Info
	return "Success: FC ports information stored in $ResultFile"
} # END FUNCTION Get-FcPortsToCsv

##################################################################
############# FUNCTION Get-ConnectedSession ######################
##################################################################
function Get-ConnectedSession 
{
<#
  .SYNOPSIS
    Command Get-ConnectedSession display connected session detail
	
  .DESCRIPTION
	Command Get-ConnectedSession display connected session detail 
        
  .EXAMPLE
    Get-ConnectedSession
	
  .Notes
    NAME:  Get-ConnectedSession    
    LASTEDIT: January 2020
    KEYWORDS: Get-ConnectedSession 
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>

    Begin{}
    Process
    {       
		return $global:SANConnection		 
    }
    End{}
} # END FUNCTION Get-ConnectedSession

############################################################################################################################################
## FUNCTION New-CLIConnection
############################################################################################################################################
Function New-CLIConnection
{
<#
  .SYNOPSIS
    Builds a SAN Connection object using HPE 3PAR CLI.
  
  .DESCRIPTION
	Creates a SAN Connection object with the specified parameters. 
    No connection is made by this cmdlet call, it merely builds the connection object. 
        
  .EXAMPLE
    New-CLIConnection  -ArrayNameOrIPAddress 10.1.1.1 -CLIDir "C:\cli.exe" -epwdFile "C:\HPE3parepwdlogin.txt"
	Creates a SAN Connection object with the specified Array Name or Array IP Address
	
  .PARAMETER ArrayNameOrIPAddress 
    Specify Array Name or Array IP Address
    
  .PARAMETER CLIDir 
    Specify the absolute path of HPE 3PAR cli.exe. Default is "C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin"
  
  .PARAMETER epwdFile 
    Specify the encrypted password file location , example “c:\HPE3parstoreserv244.txt” To create encrypted password file use “Set-Password” cmdlet           
	
  .Notes
    NAME:  New-CLIConnection    
    LASTEDIT: January 2020
    KEYWORDS: New-CLIConnection
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3PAR cli.exe 
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $ArrayNameOrIPAddress=$null,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        #$CLIDir="C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		$CLIDir="C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		[Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $epwdFile="C:\HPE3parepwdlogin.txt"       
	) 
		#Write-DebugLog "start: Entering function New-CLIConnection. Validating IP Address format." $Debug
		## Check IP Address Format
		#if(-not (Test-IPFormat $ArrayNameOrIPAddress))		
		#{
		#	Write-DebugLog "Stop: Invalid IP Address $ArrayNameOrIPAddress" "ERR:"
		#	return "Failure : Invalid IP Address $ArrayNameOrIPAddress"
		#}				
		#Write-DebugLog "Running: Completed validating IP address format." $Debug	
		
		# -------- Check any active CLI/PoshSSH session exists ------------ starts
		$check = Test-CLIConnection $global:SANConnection
		if($check -eq "Success"){
			$confirm = Read-Host "An active CLI/PoshSSH session exists.`nDo you want to close the current CLI/PoshSSH session and start a new CLI session (Enter y=yes n=no)"
			if ($confirm.tolower() -eq 'y') {
				Close-Connection
			}
			elseif ($confirm.tolower() -eq 'n') {
				return
			}
		}
		# -------- Check any active CLI/PoshSSH session exists ------------ ends
		
		# -------- Check any active WSAPI session exists ------------------ starts
		if($global:WsapiConnection){
			$confirm = Read-Host "An active WSAPI session exists.`nDo you want to close the current WSAPI session and start a new CLI session (Enter y=yes n=no)"
			if ($confirm.tolower() -eq 'y') {
				Close-WSAPIConnection
			}
			elseif ($confirm.tolower() -eq 'n') {
				return
			}
		}
		# -------- Check any active WSAPI session exists ------------------ ends
		
		Write-DebugLog "Running: Authenticating credentials - Invoke-CLI for user $SANUserName and SANIP= $ArrayNameOrIPAddress" $Debug
		$test = $env:Path		
		$test1 = $test.split(";")		
		if ($test1 -eq $CLIDir)
		{
			Write-DebugLog "Running: Environment variable path for $CLIDir already exists" "INFO:"			
		}
		else
		{
			Write-DebugLog "Running: Environment variable path for $CLIDir does not exists, so added $CLIDir to environment" "INFO:"
			$env:Path += ";$CLIDir"
		}
		if (-not (Test-Path -Path $CLIDir )) 
		{		
			Write-DebugLog "Stop: Path for HPE 3PAR cli was not found. Make sure you have installed HPE 3PAR CLI." "ERR:"			
			return "Failure : Path for HPE 3PAR cli was not found. Make sure you have cli.exe file under $CLIDir"
		}
		$clifile = $CLIDir + "\cli.exe"		
		if( -not (Test-Path $clifile))
		{
			Write-DebugLog "Stop: Path for HPE 3PAR cli was not found.Please enter only directory path with out cli.exe & Make sure you have installed HPE 3PAR CLI." "ERR:"			
			return "Failure : Path for HPE 3PAR cli was not found,Make sure you have cli.exe file under $CLIDir"
		}
		#write-host "Set HPE 3PAR CLI path if not"
		# Authenticate		
		try
		{
			if( -not (Test-Path $epwdFile))
			{
				write-host "Encrypted password file does not exist , creating encrypted password file"				
				Set-Password -CLIDir $CLIDir -ArrayNameOrIPAddress $ArrayNameOrIPAddress -epwdFile $epwdFile
				Write-DebugLog "Running: Path for encrypted password file  was not found. Now created new epwd file." "INFO:"
			}
			#write-host "pwd file : $epwdFile"
			Write-DebugLog "Running: Path for encrypted password file  was already exists." "INFO:"
			$global:epwdFile = $epwdFile	
			$Result9 = Invoke-CLI -DeviceIPAddress $ArrayNameOrIPAddress -CLIDir $CLIDir -epwdFile $epwdFile -cmd "showversion" 
			Write-DebugLog "Running: Executed Invoke-CLI. Check on PS console if there are any errors reported" $Debug
			if ($Result9 -match "FAILURE")
			{
				return $Result9
			}
		}
		catch 
		{	
			$msg = "In function New-CLIConnection. "
			$msg+= $_.Exception.ToString()	
			# Write-Exception function is used for exception logging so that it creates a separate exception log file.
			Write-Exception $msg -error		
			return "Failure : $msg"
		}
		
		$global:SANObjArr += @()
		#write-host "objarray",$global:SANObjArr

		if($global:SANConnection)
		{			
			#write-host "In IF loop"
			$SANC = New-Object "_SANConnection"  
			# Get the username
			$connUserName = Get-UserConnectionTemp -ArrayNameOrIPAddress $ArrayNameOrIPAddress -CLIDir $CLIDir -epwdFile $epwdFile -Option current
			$SANC.UserName = $connUserName.Name
			$SANC.IPAddress = $ArrayNameOrIPAddress
			$SANC.CLIDir = $CLIDir	
			$SANC.epwdFile = $epwdFile		
			$SANC.CLIType = "3parcli"
			$SANC.SessionId = "NULL"
			$global:SANConnection = $SANC
			$global:SANObjArr += @($SANC)
			
			$SystemDetails = Get-System
			$SANC.Name = $SystemDetails.Name
			$SANC.SystemVersion = Get-Version -S -B
			$SANC.Model = $SystemDetails.Model
			$SANC.Serial = $SystemDetails.Serial
			$SANC.TotalCapacityMiB = $SystemDetails.TotalCap
			$SANC.AllocatedCapacityMiB = $SystemDetails.AllocCap
			$SANC.FreeCapacityMiB = $SystemDetails.FreeCap
			
			$global:ArrayName = $SANC.Name
			$global:ConnectionType = "CLI"
		}
		else
		{		
			$global:SANObjArr = @()
			#write-host "In Else loop"			
			
			$SANC = New-Object "_SANConnection"       
			$connUserName = Get-UserConnectionTemp -ArrayNameOrIPAddress $ArrayNameOrIPAddress -CLIDir $CLIDir -epwdFile $epwdFile -Option current
			$SANC.UserName = $connUserName.Name
			$SANC.IPAddress = $ArrayNameOrIPAddress
			$SANC.CLIDir = $CLIDir
			$SANC.epwdFile = $epwdFile
			$SANC.CLIType = "3parcli"
			$SANC.SessionId = "NULL"
						
			#making this object as global
			$global:SANConnection = $SANC				
			$global:SANObjArr += @($SANC)	

			$SystemDetails = Get-System
			$SANC.Name = $SystemDetails.Name
			$SANC.SystemVersion = Get-Version -S -B
			$SANC.Model = $SystemDetails.Model
			$SANC.Serial = $SystemDetails.Serial
			$SANC.TotalCapacityMiB = $SystemDetails.TotalCap
			$SANC.AllocatedCapacityMiB = $SystemDetails.AllocCap
			$SANC.FreeCapacityMiB = $SystemDetails.FreeCap
			
			$global:ArrayName = $SANC.Name
			$global:ConnectionType = "CLI"
		}
		
		Write-DebugLog "End: If there are no errors reported on the console then the SAN connection object is set and ready to be used" $Info
		
		# Set to the prompt as "Array Name:Connection Type (WSAPI|CLI)\>"
		Function global:prompt {
			if ($global:SANConnection -ne $null){				
				$global:ArrayName + ":" + $global:ConnectionType + "\>"
			} else{
				(Get-Location).Path + "\>"
			}
		}
		return $SANC
} # End Function New-CLIConnection

################################################################################
######################### FUNCTION New-PoshSshConnection #######################
################################################################################
Function New-PoshSshConnection
{
<#
  .SYNOPSIS
    Builds a SAN Connection object using Posh SSH connection
  
  .DESCRIPTION
	Creates a SAN Connection object with the specified parameters. 
    No connection is made by this cmdlet call, it merely builds the connection object. 
        
  .EXAMPLE
    New-PoshSshConnection -SANUserName Administrator -SANPassword mypassword -ArrayNameOrIPAddress 10.1.1.1 
	Creates a SAN Connection object with the specified Array Name or Array IP Address
	
  .EXAMPLE
    New-PoshSshConnection -SANUserName Administrator -SANPassword mypassword -ArrayNameOrIPAddress 10.1.1.1 -AcceptKey
	Creates a SAN Connection object with the specified Array Name or Array IP Address
	
  .PARAMETER UserName 
    Specify the SAN Administrator user name.
	
  .PARAMETER Password 
    Specify the SAN Administrator password 
	
   .PARAMETER ArrayNameOrIPAddress 
    Specify Array Name or Array IP Address
              
  .Notes
    NAME:  New-PoshSshConnection    
    LASTEDIT: January 2020
    KEYWORDS: New-PoshSshConnection
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Enter Array Name or IP Address")]
		[System.String]
        $ArrayNameOrIPAddress=$null,
		
		[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$SANUserName=$null,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$SANPassword=$null,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$AcceptKey
		)
		
		$Session
		
		# Check if our module loaded properly
		if (Get-Module -ListAvailable -Name Posh-SSH) 
		{ <# do nothing #> }
		else 
		{ 
			try
			{
				# install the module automatically
				[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
				iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")
			}
			catch
			{
				#$msg = "Error occurred while installing POSH SSH Module. `nPlease check the internet connection.`nOr Install POSH SSH Module using given Link. `nhttp://www.powershellmagazine.com/2014/07/03/posh-ssh-open-source-ssh-powershell-module/  `n "
				$msg = "Error occurred while installing POSH SSH Module. `nPlease check if internet is enabled. If internet is enabled and you are getting this error,`n Execute Save-Module -Name Posh-SSH -Path <path Ex D:\xxx> `n Then Install-Module -Name Posh-SSH `n If you are getting error like Save-Module is incorrect then `n Check you Power shell Version and Update to 5.1 for this particular Process  `n Or visit https://www.powershellgallery.com/packages/Posh-SSH/2.0.2 `n"
				 
				return "`n Failure : $msg"
			}			
		}	
		
		#####
		#Write-DebugLog "start: Entering function New-PoshSshConnection. Validating IP Address format." $Debug		
		## Check IP Address Format
		#if(-not (Test-IPFormat $ArrayNameOrIPAddress))		
		#{
		#	Write-DebugLog "Stop: Invalid IP Address $ArrayNameOrIPAddress" "ERR:"
		#	return "Failure : Invalid IP Address $ArrayNameOrIPAddress"
		#}
		
		<#
		# -------- Check any active CLI/PoshSSH session exists ------------ starts		
		if($global:SANConnection){
			$confirm = Read-Host "`nAn active CLI/PoshSSH session exists.`nDo you want to close the current CLI/PoshSSH session and start a new PoshSSH session (Enter y=yes n=no)"
			if ($confirm.tolower() -eq 'y'){
				write-host "`nClosing the current CLI/PoshSSH connection."
				Close-Connection
			}
			elseif ($confirm.tolower() -eq 'n'){
				return
			}
		}
		# -------- Check any active CLI/PoshSSH session exists ------------ ends
		
		# -------- Check any active WSAPI session exists ------------------ starts
		if($global:WsapiConnection){
			$confirm = Read-Host "`nAn active WSAPI session exists.`nDo you want to close the current WSAPI session and start a new PoshSSH session (Enter y=yes n=no)"
			if ($confirm.tolower() -eq 'y'){
				write-host "`nClosing the current WSAPI connection."
				Close-WSAPIConnection
			}
			elseif ($confirm.tolower() -eq 'n'){
				return
			}
		}
		# -------- Check any active WSAPI session exists ------------------ ends
		#>
		
		# Authenticate		
		try
		{
			if(!($SANPassword))
			{				
				$securePasswordStr = Read-Host "SANPassword" -AsSecureString				
				$mycreds = New-Object System.Management.Automation.PSCredential ($SANUserName, $securePasswordStr)
			}
			else
			{				
				$tempstring  = convertto-securestring $SANPassword -asplaintext -force				
				$mycreds = New-Object System.Management.Automation.PSCredential ($SANUserName, $tempstring)									
			}
			try
			{
				if($AcceptKey) 
				{
				   #$Session = New-SSHSession -ComputerName $ArrayNameOrIPAddress -Credential (Get-Credential $SANUserName) -AcceptKey                      
				   $Session = New-SSHSession -ComputerName $ArrayNameOrIPAddress -Credential $mycreds -AcceptKey
			    }
			    else 
				{
				   #$Session = New-SSHSession -ComputerName $ArrayNameOrIPAddress -Credential (Get-Credential $SANUserName)                          
				    $Session = New-SSHSession -ComputerName $ArrayNameOrIPAddress -Credential $mycreds
			    }
			}
			catch 
			{	
				$msg = "In function New-PoshSshConnection. "
				$msg+= $_.Exception.ToString()	
				# Write-Exception function is used for exception logging so that it creates a separate exception log file.
				Write-Exception $msg -error		
				return "Failure : $msg"
			}
			Write-DebugLog "Running: Executed . Check on PS console if there are any errors reported" $Debug
			if (!$Session)
			{
				return "New-PoshSshConnection command failed to connect the array."
			}
		}
		catch 
		{	
			$msg = "In function New-PoshSshConnection. "
			$msg+= $_.Exception.ToString()	
			# Write-Exception function is used for exception logging so that it creates a separate exception log file.
			Write-Exception $msg -error		
			return "Failure : $msg"
		}					
		
		$global:SANObjArr += @()
		$global:SANObjArr1 += @()
		#write-host "objarray",$global:SANObjArr
		#write-host "objarray1",$global:SANObjArr1
		if($global:SANConnection)
		{			
			#write-host "In IF loop"
			$SANC = New-Object "_SANConnection"
			$SANC.SessionId = $Session.SessionId		
			$SANC.IPAddress = $ArrayNameOrIPAddress			
			$SANC.UserName = $SANUserName
			$SANC.epwdFile = "Secure String"			
			$SANC.CLIType = "SshClient"
			$SANC.CLIDir = "Null"			
			
			$global:SANConnection = $SANC
			
			$SystemDetails = Get-System
			$SANC.Name = $SystemDetails.Name
			$SANC.SystemVersion = Get-Version -S -B
			$SANC.Model = $SystemDetails.Model
			$SANC.Serial = $SystemDetails.Serial
			$SANC.TotalCapacityMiB = $SystemDetails.TotalCap
			$SANC.AllocatedCapacityMiB = $SystemDetails.AllocCap
			$SANC.FreeCapacityMiB = $SystemDetails.FreeCap
			
			$global:ArrayName = $SANC.Name
			$global:ConnectionType = "CLI"
			
			###making multiple object support
			$SANC1 = New-Object "_TempSANConn"
			$SANC1.IPAddress = $ArrayNameOrIPAddress			
			$SANC1.UserName = $SANUserName
			$SANC1.epwdFile = "Secure String"		
			$SANC1.SessionId = $Session.SessionId			
			$SANC1.CLIType = "SshClient"
			$SANC1.CLIDir = "Null"
			
			$global:SANObjArr += @($SANC)
			$global:SANObjArr1 += @($SANC1)			
		}
		else
		{
			$global:SANObjArr = @()
			$global:SANObjArr1 = @()
			#write-host "In Else loop"
						
			$SANC = New-Object "_SANConnection"
			$SANC.IPAddress = $ArrayNameOrIPAddress			
			$SANC.UserName = $SANUserName			
			$SANC.epwdFile = "Secure String"		
			$SANC.SessionId = $Session.SessionId
			$SANC.CLIType = "SshClient"
			$SANC.CLIDir = "Null"
						
			$global:SANConnection = $SANC		
			
			$SystemDetails = Get-System
			$SANC.Name = $SystemDetails.Name
			$SANC.SystemVersion = Get-Version -S -B
			$SANC.Model = $SystemDetails.Model
			$SANC.Serial = $SystemDetails.Serial
			$SANC.TotalCapacityMiB = $SystemDetails.TotalCap
			$SANC.AllocatedCapacityMiB = $SystemDetails.AllocCap
			$SANC.FreeCapacityMiB = $SystemDetails.FreeCap
			
			$global:ArrayName = $SANC.Name
			$global:ConnectionType = "CLI"
			
			###making multiple object support
			$SANC1 = New-Object "_TempSANConn"
			$SANC1.IPAddress = $ArrayNameOrIPAddress			
			$SANC1.UserName = $SANUserName
			$SANC1.epwdFile = "Secure String"
			$SANC1.SessionId = $Session.SessionId
			$SANC1.CLIType = "SshClient"
			$SANC1.CLIDir = "Null"		
				
			$global:SANObjArr += @($SANC)
			$global:SANObjArr1 += @($SANC1)		
		}
		Write-DebugLog "End: If there are no errors reported on the console then the SAN connection object is set and ready to be used" $Info		
		
		# Set to the prompt as "Array Name:Connection Type (WSAPI|CLI)\>"
		Function global:prompt {
			if ($global:SANConnection -ne $null){				
				$global:ArrayName + ":" + $global:ConnectionType + "\>"
			} else{
				(Get-Location).Path + "\>"
			}
		}
		return $SANC
 }# End Function New-PoshSshConnection

######################################################################################################################
## FUNCTION Set-PoshSshConnectionPasswordFile
######################################################################################################################
Function Set-PoshSshConnectionPasswordFile
{
<#
  .SYNOPSIS
   Creates a encrypted password file on client machine to be used by "Set-PoshSshConnectionUsingPasswordFile"
  
  .DESCRIPTION
	Creates an encrypted password file on client machine
        
  .EXAMPLE
   Set-PoshSshConnectionPasswordFile -ArrayNameOrIPAddress "15.1.1.1" -SANUserName "3parDemoUser"  -$SANPassword "demoPass1"  -epwdFile "C:\hpe3paradmepwd.txt"
	
	This examples stores the encrypted password file hpe3paradmepwd.txt on client machine c:\ drive, subsequent commands uses this encryped password file ,
	This example authenticates the entered credentials if correct creates the password file.
  
  .PARAMETER SANUserName 
    Specify the SAN SANUserName .
    
  .PARAMETER ArrayNameOrIPAddress 
    Specify Array Name or Array IP Address
    
  .PARAMETER SANPassword 
    Specify the Password with the Linked IP
  
  .PARAMETER epwdFile 
    Specify the file location to create encrypted password file
	
  .Notes
    NAME:   Set-PoshSshConnectionPasswordFile
	LASTEDIT: January 2020
    KEYWORDS:  Set-PoshSshConnectionPasswordFile
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 2.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $ArrayNameOrIPAddress=$null,
		
		[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$SANUserName=$null,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$SANPassword=$null,
		
		[Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $epwdFile=$null,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$AcceptKey       
	)
	
	## Check IP Address Format
	#if(-not (Test-IPFormat $ArrayNameOrIPAddress))		
	#{
	#	Write-DebugLog "Stop: Invalid IP Address $ArrayNameOrIPAddress" "ERR:"
	#	return "FAILURE : Invalid IP Address $ArrayNameOrIPAddress"
	#}		
	
	#Write-DebugLog "Running: Completed validating IP address format." $Debug		
	Write-DebugLog "Running: Authenticating credentials - for user $SANUserName and SANIP= $ArrayNameOrIPAddress" $Debug
	
	# Authenticate
	try
	{
		if(!($SANPassword))
		{				
			$securePasswordStr = Read-Host "SANPassword" -AsSecureString				
			$mycreds = New-Object System.Management.Automation.PSCredential ($SANUserName, $securePasswordStr)
			
			$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePasswordStr)
			$tempPwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		}
		else
		{				
			$tempstring  = convertto-securestring $SANPassword -asplaintext -force				
			$mycreds = New-Object System.Management.Automation.PSCredential ($SANUserName, $tempstring)	

			$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tempstring)
			$tempPwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		}			
		
		if($AcceptKey) 
		{
			#$Session = New-SSHSession -ComputerName $ArrayNameOrIPAddress -Credential (Get-Credential $SANUserName) -AcceptKey                           
			$Session = New-SSHSession -ComputerName $ArrayNameOrIPAddress -Credential $mycreds -AcceptKey
		}
		else 
		{
			#$Session = New-SSHSession -ComputerName $ArrayNameOrIPAddress -Credential (Get-Credential $SANUserName)                        
			$Session = New-SSHSession -ComputerName $ArrayNameOrIPAddress -Credential $mycreds
		}
		
		Write-DebugLog "Running: Executed . Check on PS console if there are any errors reported" $Debug
		if (!$Session)
		{
			return "FAILURE : In function Set-PoshSshConnectionPasswordFile."
		}
		else
		{
			$RemveResult = Remove-SSHSession -Index $Session.SessionId
		}
		
		$Enc_Pass = Protect-String $tempPwd 
		$Enc_Pass,$ArrayNameOrIPAddress,$SANUserName | Export-CliXml $epwdFile	
	}
	catch 
	{	
		$msg = "In function Set-PoshSshConnectionPasswordFile. "
		$msg+= $_.Exception.ToString()	
		
		Write-Exception $msg -error		
		return "FAILURE : $msg `n credentials incorrect"
	}

	Write-DebugLog "Running: encrypted password file has been created successfully and the file location is $epwdFile " "INFO:"
	return "`n Success : encrypted SANPassword file has been created successfully and the file location : $epwdFile"	

} #  End-of  Set-PoshSshConnectionPasswordFile
 
#####################################################################################
#   Function   Set-PoshSshConnectionUsingPasswordFile
#####################################################################################
Function Set-PoshSshConnectionUsingPasswordFile
{
<#
  .SYNOPSIS
    Creates a SAN Connection object using Encrypted password file
  
  .DESCRIPTION
	Creates a SAN Connection object using Encrypted password file.
    No connection is made by this cmdlet call, it merely builds the connection object. 
        
  .EXAMPLE
    Set-PoshSshConnectionUsingPasswordFile  -ArrayNameOrIPAddress 10.1.1.1 -SANUserName "3parUser" -epwdFile "C:\HPE3PARepwdlogin.txt"
	Creates a SAN Connection object with the specified the Array Name or Array IP Address and password file
		
  .PARAMETER ArrayNameOrIPAddress 
    Specify Array Name or Array IP Address
    
  .PARAMETER SANUserName
  Specify the SAN UserName.
  
  .PARAMETER epwdFile 
    Specify the encrypted password file location , example “c:\hpe3parstoreserv244.txt” To create encrypted password file use “New-3parSSHCONNECTION_PassFile” cmdlet           
	
  .Notes
    NAME:  Set-PoshSshConnectionUsingPasswordFile
	LASTEDIT: January 2020
    KEYWORDS: Set-PoshSshConnectionUsingPasswordFile
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3PAR cli.exe 
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $ArrayNameOrIPAddress=$null,
		[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $SANUserName,
		[Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $epwdFile        
	) 
					
	try{			
		if( -not (Test-Path $epwdFile))
		{
			Write-DebugLog "Running: Path for encrypted password file  was not found. Now created new epwd file." "INFO:"
			return " Encrypted password file does not exist , create encrypted password file using 'Set-3parSSHConnectionPasswordFile' "
		}	
		
		Write-DebugLog "Running: Patch for encrypted password file ." "INFO:"
		
		$tempFile=$epwdFile			
		$Temp=import-CliXml $tempFile
		$pass=$temp[0]
		$ip=$temp[1]
		$user=$temp[2]
		if($ip -eq $ArrayNameOrIPAddress)  
		{
			if($user -eq $SANUserName)
			{
				$Passs = UnProtect-String $pass 
				#New-SSHConnection -SANUserName $SANUserName  -SANPassword $Passs -ArrayNameOrIPAddress $ArrayNameOrIPAddress -SSHDir "C:\plink"
				New-PoshSshConnection -ArrayNameOrIPAddress $ArrayNameOrIPAddress -SANUserName $SANUserName -SANPassword $Passs

			}
			else
			{ 
				Return "Password file SANUserName $user and entered SANUserName $SANUserName dose not match  . "
				Write-DebugLog "Running: Password file SANUserName $user and entered SANUserName $SANUserName dose not match ." "INFO:"
			}
		}
		else 
		{
			Return  "Password file ip $ip and entered ip $ArrayNameOrIPAddress dose not match"
			Write-DebugLog "Password file ip $ip and entered ip $ArrayNameOrIPAddress dose not match." "INFO:"
		}
	}
	catch 
	{	
		$msg = "In function Set-PoshSshConnectionUsingPasswordFile. "
		$msg+= $_.Exception.ToString()	
		# Write-Exception function is used for exception logging so that it creates a separate exception log file.
		Write-Exception $msg -error		
		return "FAILURE : $msg"
	}
} #End Function Set-PoshSshConnectionUsingPasswordFile

######################################################################################################################
## FUNCTION Get-UserConnectionTemp
######################################################################################################################
Function Get-UserConnectionTemp
{
<#
  .SYNOPSIS
    Displays information about users who are currently connected (logged in) to the storage system.
  
  .DESCRIPTION
	Displays information about users who are currently connected (logged in) to the storage system.
        
  .EXAMPLE
    Get-UserConnection  -ArrayNameOrIPAddress 10.1.1.1 -CLIDir "C:\cli.exe" -epwdFile "C:\HPE3parepwdlogin.txt" -Option current
	Shows all information about the current connection only.
  .EXAMPLE
    Get-UserConnection  -ArrayNameOrIPAddress 10.1.1.1 -CLIDir "C:\cli.exe" -epwdFile "C:\HPE3parepwdlogin.txt" 
	Shows information about users who are currently connected (logged in) to the storage system.
	 
  .PARAMETER ArrayNameOrIPAddress 
    Specify Array Name or Array IP Address
    
  .PARAMETER CLIDir 
    Specify the absolute path of HPE 3PAR cli.exe. Default is "C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin"
  
  .PARAMETER epwdFile 
    Specify the encrypted password file , if file does not exists it will create encrypted file using deviceip,username and password  
	
  .PARAMETER Option
    current
	Shows all information about the current connection only.

  .Notes
    NAME:   Get-UserConnectionTemp
    LASTEDIT: January 2020
    KEYWORDS:  Get-UserConnectionTemp
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3PAR cli.exe 
 #>
 
[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=$false, ValueFromPipeline=$true)]
		[System.string]
		$CLIDir="C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		[Parameter(Position=1,Mandatory=$true, ValueFromPipeline=$true)]
		[System.string]
		$ArrayNameOrIPAddress=$null,
		[Parameter(Position=2,Mandatory=$true, ValueFromPipeline=$true)]
		[System.string]
		$epwdFile ="C:\HPE3parepwdlogin.txt",
		[Parameter(Position=3,Mandatory=$false, ValueFromPipeline=$true)]
		[System.string]
		$Option
	)
	if( Test-Path $epwdFile)
	{
		Write-DebugLog "Running: password file was found , it will use the mentioned file" "INFO:"
	}
	#$passwordFile = $epwdFile
	#$cmd1 = $CLIDir+"\showuserconn.bat"
	$cmd2 = "showuserconn "
	$options1 = "current"
	if(!($options1 -eq $option))
	{
		return "Failure : option should be in ( $options1 )"
	}
	if($option -eq "current")
	{
		$cmd2 += " -current "
	}
	#& $cmd1 -sys $ArrayNameOrIPAddress -file $passwordFile
	$result = Invoke-CLI -DeviceIPAddress $ArrayNameOrIPAddress -CLIDir $CLIDir -epwdFile $epwdFile -cmd $cmd2	
	$count = $result.count - 3
	$tempFile = [IO.Path]::GetTempFileName()	
	Add-Content -Path $tempFile -Value "Id,Name,IP_Addr,Role,Connected_since,Current,Client,ClientName"	
	foreach($s in $result[1..$count])
	{
		$s= [regex]::Replace($s,"^ +","")
		$s= [regex]::Replace($s," +"," ")
		$s= [regex]::Replace($s," ",",")
		$s = $s.trim()
		Add-Content -Path $tempFile -Value $s
	}
	Import-CSV $tempFile	
    del $tempFile
}

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

 
Export-ModuleMember Close-Connection , Get-CmdList , Get-FcPorts , Get-FcPortsToCsv , Get-ConnectedSession , New-CLIConnection , New-PoshSshConnection ,
Set-PoshSshConnectionPasswordFile , Set-PoshSshConnectionUsingPasswordFile