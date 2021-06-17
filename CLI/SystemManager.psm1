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
##	File Name:		SystemManager.psm1
##	Description: 	System Manager cmdlets 
##		
##	Created:		December 2019
##	Last Modified:	December 2019
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

##########################################################################
######################### FUNCTION Get-Cert #########################
##########################################################################
Function Get-Cert()
{
<#
  .SYNOPSIS
   Get-Cert - Show information about SSL certificates of the Storage System.

  .DESCRIPTION
   The Get-Cert command has two forms. The first is a table with a high level
   overview of the certificates used by the SSL Services. This table is
   customizable with the -showcols option. The second form provides detailed
   certificate information in either human readable format or in PEM (Privacy
   Enhanced Mail) format. It can also save the certificates in a specified
   file.

  .EXAMPLE
	Get-Cert -Service unified-server -Pem
	
  .EXAMPLE
	Get-Cert -Service unified-server -Text

  .PARAMETER Listcols
   Displays the valid table columns.

  .PARAMETER Showcols
   Changes the columns displayed in the table.

  .PARAMETER Service
   Displays only the certificates used by the service(s).
   Multiple services must be delimited by a comma.
   Valid service names are cim, cli, ekm-client, ekm-server, ldap,
   syslog-gen-client, syslog-gen-server, syslog-sec-client,
   syslog-sec-server, wsapi, vasa, and unified-server.

  .PARAMETER Type
   Displays only certificates of the specified type, e.g.,
   only root CA. Multiple types must be delimited by a comma.
   Valid types are csr, cert, intca, and rootca.

  .PARAMETER Pem
   Displays the certificates in PEM format. When a filename is specified
   the certificates are exported to the file.

  .PARAMETER Text
   Displays the certificates in human readable format. When a filename
   is specified the certificates are exported to the file.

  .PARAMETER File
   Specifies the export file of the -pem or -text option.

  .Notes
    NAME: Get-Cert
    LASTEDIT December 2019
    KEYWORDS: Get-Cert
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Listcols,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Showcols,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Service,

	[Parameter(Position=3, Mandatory=$false)]
	[System.String]
	$Type,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Pem,

	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$Text,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$File,

	[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-Cert - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Get-Cert since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-Cert since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

 $Cmd = " showcert "

 if($Listcols)
 {
	$Cmd += " -listcols "
 }
 
 if($Showcols)
 {
	$Cmd += " -showcols $Showcols "
 }
 
 if($Service)
 {
	$Cmd += " -service $Service "
 }
 
 if($Type)
 {
	$Cmd += " -type $Type "
 }
 
 if($Pem)
 {
	$Cmd += " -pem "
 }
 
 if($Text)
 {
	$Cmd += " -text "
 }
 
 if($File)
 {
	$Cmd += " -file $File "
 }
 
 if($Listcols -Or $Pem -Or $Text)
 {
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
	Write-DebugLog "Executing Function : Get-Cert Command -->" INFO: 

	Return $Result
 }
 else
 {
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
	Write-DebugLog "Executing Function : Get-Cert Command -->" INFO: 
	if($Result.count -gt 1)
	{	
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count 

		foreach ($s in  $Result[0..$LastItem] )
		{		
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")	
			$s= [regex]::Replace($s,"-","")
			$s= $s.Trim()			
			$temp1 = $s -replace 'Enddate','Month,Date,Time,Year,Zone'
			$s = $temp1
			
			## added code to replace blanc Enddate 			
			$sTemp1=$s				
			$sTemp = $sTemp1.Split(',')	
			if ([string]::IsNullOrEmpty($sTemp[3]))
			{
				$sTemp[3] = "--,--,--,--,---"
			}				
			$newTemp= [regex]::Replace($sTemp,"^ ","")			
			$newTemp= [regex]::Replace($sTemp," ",",")				
			$newTemp= $newTemp.Trim()
			$s=$newTemp
			
			Add-Content -Path $tempfile -Value $s				
		}
		Import-Csv $tempFile 
		del $tempFile 	
	}
	else
	{
		return  $Result
	}

	if($Result.count -gt 1)
	{
		return  " Success : Executing Get-Cert"
	}
	else
	{			
		return  $Result
	} 
 }
 
} ##  End-of Get-Cert

##########################################################################
######################### FUNCTION Get-Encryption ####################
##########################################################################
Function Get-Encryption()
{
<#
  .SYNOPSIS
   Get-Encryption - Show Data Encryption information.

  .DESCRIPTION
   The Get-Encryption command shows Data Encryption information.

  .EXAMPLE

  .PARAMETER D
   Provides details on the encryption status.

  .Notes
    NAME: Get-Encryption
    LASTEDIT December 2019
    KEYWORDS: Get-Encryption
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$D,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-Encryption - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Get-Encryption since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-Encryption since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " showencryption "

 if($D)
 {
	$Cmd += " -d "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-Encryption Command -->" INFO: 

if($Result.count -gt 1)
 {
	$LastItem = 0
	$Fcnt = 0
	
	if($D)
	{
		$Fcnt = 4
		$LastItem = $Result.Count -2
	}
	else
	{
		$LastItem = $Result.Count -0
	}
		
	$tempFile = [IO.Path]::GetTempFileName	
	foreach ($s in  $Result[$Fcnt..$LastItem] )
	{		
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s," +",",")	
		$s= [regex]::Replace($s,"-","")
		$s= $s.Trim() 
		$temp1 = $s -replace 'AdmissionTime','Date,Time,Zone'
		$s = $temp1		
		Add-Content -Path $tempfile -Value $s				
	}
	Import-Csv $tempFile 
	del $tempFile 	
 }
 
 if($Result.count -gt 1)
 {
	return  " Success : Executing Get-Encryption"
 }
 else
 {			
	return  $Result
 } 
 
} ##  End-of Get-Encryption

##########################################################################
############################ FUNCTION Get-SR #############################
##########################################################################
Function Get-SR
{
<#
  .SYNOPSIS
    Displays the amount of space consumed by the various System Reporter databases on the System Reporter volume.
  
  .DESCRIPTION
    Displays the amount of space consumed by the various System Reporter databases on the System Reporter volume.
        
  .EXAMPLE
    Get-SR 
	shows how to display the System Reporter status:
	
  .EXAMPLE
    Get-SR -Btsecs 10

  .PARAMETER ldrg
	Displays which LD region statistic samples are available.  This is used
	with the -btsecs and -etsecs options.

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
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-SR
    LASTEDIT: December 2019
    KEYWORDS: Get-SR
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$ldrg,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Btsecs,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Etsecs,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-SR - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-SR since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-SR since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "showsr "
	
	if($ldrg)
	{
		$srinfocmd += "-ldrg "
	}
	if($Btsecs)
	{
		$srinfocmd += "-btsecs $Btsecs "
	}
	if($Etsecs)
	{
		$srinfocmd += "-etsecs $Etsecs "
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
	write-host ""
	return  $Result	
}
## EndOf Get-SR

##########################################################################
########################### FUNCTION Import-Cert #########################
##########################################################################
Function Import-Cert()
{
<#
  .SYNOPSIS
   Import-Cert - imports a signed certificate and supporting certificate authorities
   (CAs) for the Storage System SSL services.

  .DESCRIPTION
   The Import-Cert command allows a user to import certificates for a given
   service. The user can import a CA bundle containing the intermediate and/or
   root CAs prior to importing the service certificate. The CA bundle can also
   be imported alongside the service certificate.

  .EXAMPLE
	Import-Cert -SSL_service wsapi -Service_cert  wsapi-service.pem
  
  .PARAMETER SSL_service
	Valid service names are cim, cli, ekm-client, ekm-server, ldap,
	syslog-gen-client, syslog-gen-server, syslog-sec-client,
	syslog-sec-server, wsapi, vasa, and unified-server.

  .PARAMETER CA_bundle
   Allows the import of a CA bundle without importing a service
   certificate. Note the filename "stdin" can be used to paste the
   CA bundle into the CLI.
   
  .PARAMETER Ca
   Allows the import of a CA bundle without importing a service
   certificate. Note the filename "stdin" can be used to paste the
   CA bundle into the CLI.

  .Notes
    NAME: Import-Cert
    LASTEDIT December 2019
    KEYWORDS: Import-Cert
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(

	[Parameter(Position=0, Mandatory=$true)]
	[System.String]
	$SSL_service,
	
	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Service_cert, 
	
	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$CA_bundle,

	[Parameter(Position=3, Mandatory=$false)]
	[System.String]
	$Ca,

	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Import-Cert - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Import-Cert since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Import-Cert since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

	$Cmd = " importcert "

 if($SSL_service)
 {
	$Cmd += " $SSL_service -f "
 }
 
 if($Service_cert)
 {
	$Cmd += " $Service_cert "
 }
 
 if($CA_bundle)
 {
	$Cmd += " $CA_bundle "
 }
 
 if($Ca)
 {
	$Cmd += " -ca $Ca "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Import-Cert Command -->" INFO: 
 Return $Result
} ##  End-of Import-Cert

##########################################################################
######################### FUNCTION New-Cert #######################
##########################################################################
Function New-Cert()
{
<#
  .SYNOPSIS
   New-Cert - Create self-signed SSL certificate or a certificate signing request (CSR) for the Storage System SSL services.

  .DESCRIPTION
   The New-Cert command creates a self-signed certificate or a certificate signing request for a specified service.

  .EXAMPLE
	New-Cert -SSL_service unified-server -Selfsigned -Keysize 2048 -Days 365
	
  .EXAMPLE
	New-Cert -SSL_service wsapi -Selfsigned -Keysize 2048 -Days 365
  
  .PARAMETER SSL_service
	Valid service names are cim, cli, ekm-client, ekm-server, ldap,
	syslog-gen-client, syslog-gen-server, syslog-sec-client,
	syslog-sec-server, wsapi, vasa, and unified-server.
  
  .PARAMETER Csr
   Creates a certificate signing request for the service. No certificates
   are modified and no services are restarted.

  .PARAMETER Selfsigned
   Creates a self-signed certificate for the service. The previous
   certificate is removed and the service restarted. The intermediate
   and/or root certificate authorities for a service are not removed.

  .PARAMETER Keysize
   Specifies the encryption key size in bits of the self-signed
   certificate. Valid values are 1024 and 2048. The default value
   is 2048.

  .PARAMETER Days
   Specifies the valid days of the self-signed certificate. Valid
   values are between 1 and 3650 days (10 years). The default
   value is 1095 days (3 years).

  .PARAMETER C
   Specifies the value of country (C) attribute of the subject of
   the certificate.

  .PARAMETER ST
   Specifies the value of state (ST) attribute of the subject of
   the certificate.

  .PARAMETER L
   Specifies the value of locality (L) attribute of the subject of
   the certificate.

  .PARAMETER O
   Specifies the value of organization (O) attribute of the subject
   of the certificate.

  .PARAMETER OU
   Specifies the value of organizational unit (OU) attribute of the
   subject of the certificate.

  .PARAMETER CN
   Specifies the value of common name (CN) attribute of the subject
   of the certificate. Over ssh, -CN must be specified.

  .PARAMETER SAN
   Subject alternative name is a X509 extension that allows other
   pieces of information to be associated with the certificate. Multiple
   SANs may delimited with a comma.

  .Notes
    NAME: New-Cert
    LASTEDIT December 2019
    KEYWORDS: New-Cert
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(

	[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
	[System.String]
	$SSL_service,
	
	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Csr,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Selfsigned,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Keysize,

	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Days,

	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$C,

	[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$ST,

	[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$L,

	[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$O,

	[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$OU,

	[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$CN,

	[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$SAN,
	
	[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In New-Cert - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting New-Cert since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet New-Cert since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

	$Cmd = " createcert "

 if($SSL_service)
 {
	$Cmd += " $SSL_service "
 }	
	
 if($Csr)
 {
	$Cmd += " -csr -f"
 } 
 Elseif($Selfsigned)
 {
	$Cmd += " -selfsigned -f"
 }
 else
 {
	Return "Select at least one from [Csr | Selfsigned]..."
 }
 
 if($Keysize)
 {
	$Cmd += " -keysize $Keysize "
 } 
 
 if($Days)
 {
	$Cmd += " -days $Days "
 }
 
 if($C)
 {
	$Cmd += " -C $C "
 }
 
 if($ST)
 {
	$Cmd += " -ST $ST "
 }
 
 if($L)
 {
	$Cmd += " -L $L "
 }
 
 if($O)
 {
	$Cmd += " -O $O "
 }
 
 if($OU)
 {
	$Cmd += " -OU $OU "
 }
 
 if($CN)
 {
	$Cmd += " -CN $CN "
 }
 
 if($SAN)
 {
	$Cmd += " -SAN $SAN "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : New-Cert Command -->" INFO: 
 
 Return $Result
} ##  End-of New-Cert

####################################################################################################################
## FUNCTION New-RCopyGroup
###################################################################################################################

Function New-RCopyGroup
{
<#
  .SYNOPSIS
   The New-RCopyGroup command creates a remote-copy volume group.
   
  .DESCRIPTION
    The New-RCopyGroup command creates a remote-copy volume group.   
	
  .EXAMPLE	
	New-RCopyGroup -GroupName AS_TEST -TargetName CHIMERA03 -Mode sync

  .EXAMPLE
	New-RCopyGroup -GroupName AS_TEST1 -TargetName CHIMERA03 -Mode async

  .EXAMPLE
	New-RCopyGroup -GroupName AS_TEST2 -TargetName CHIMERA03 -Mode periodic

  .EXAMPLE
	New-RCopyGroup -domain DEMO -GroupName AS_TEST3 -TargetName CHIMERA03 -Mode periodic     
		
  .PARAMETER domain
	Creates the remote-copy group in the specified domain.
	
  .PARAMETER Usr_Cpg_Name
	Specify the local user CPG and target user CPG that will be used for volumes that are auto-created.
	
  .PARAMETER Target_TargetCPG
	Specify the local user CPG and target user CPG that will be used for volumes that are auto-created.
	
  .PARAMETER Snp_Cpg_Name
	 Specify the local snap CPG and target snap CPG that will be used for volumes that are auto-created.
	
  .PARAMETER Target_TargetSNP
	 Specify the local snap CPG and target snap CPG that will be used for volumes that are auto-created.
	
  .PARAMETER GroupName
	Specifies the name of the volume group, using up to 22 characters if the mirror_config policy is set, or up to 31 characters otherwise. This name is assigned with this command.	
	
  .PARAMETER TargetName	
	Specifies the target name associated with this group.
	
  .PARAMETER Mode 	
	sync—synchronous replication
	async—asynchronous streaming replication
	periodic—periodic asynchronous replication
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  New-RCopyGroup
    LASTEDIT: December 2019
    KEYWORDS: New-RCopyGroup
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$GroupName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,	
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Mode,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$domain,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Usr_Cpg_Name,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Target_TargetCPG,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Snp_Cpg_Name,		
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Target_TargetSNP,
				
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	Write-DebugLog "Start: In New-RCopyGroup   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting New-RCopyGroup since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet New-RCopyGroup since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "creatercopygroup"	
	if ($domain)	
	{
		$cmd+=" -domain $domain"
	}
	if ($Usr_Cpg_Name)	
	{
		$cmd+=" -usr_cpg $Usr_Cpg_Name "
		if($Target_TargetCPG)
		{
			$cmd+= " $TargetName"
			$cmd+= ":$Target_TargetCPG "			
		}
		else
		{
			return "Target_TargetCPG is required with Usr CPG option"
		}
	}
	if ($Snp_Cpg_Name)	
	{
		$cmd+=" -snp_cpg $Snp_Cpg_Name "
		if($Target_TargetSNP)
		{
			$cmd+= " $TargetName"
			$cmd+= ":$Target_TargetSNP "			
		}
		else
		{
			return "Target_TargetSNP is required with Usr CPG option"
		}
	}
	if ($GroupName)
	{
		$cmd+=" $GroupName"
	}
	else
	{
		Write-DebugLog "Stop: GroupName is mandatory" $Debug
		return "Error :  -GroupName is mandatory. "			
	}	
	if ($TargetName)
	{		
		$cmd+=" $TargetName"
	}
	else
	{
		Write-DebugLog "Stop: TargetName is mandatory" $Debug
		return "Error :  -TargetName is mandatory. "			
	}
	if ($Mode)
	{		
		$a = "sync","async","periodic"
		$l=$Mode
		if($a -eq $l)
		{
			$cmd+=":$Mode "	
			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  New-RCopyGroup   since Mode $Mode in incorrect "
			Return "FAILURE : Mode :- $Mode is an Incorrect Mode  [a]  can be used only . "
		}		
	}
	else
	{
		Write-DebugLog "Stop: Mode is mandatory" $Debug
		return "Error :  -Mode is mandatory. "			
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  The command creates a remote-copy volume group..   " "INFO:" 	
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Executing  New-RCopyGroup Command $Result"
	}
	else
	{
		return  "FAILURE : While Executing  New-RCopyGroup 	$Result "
	} 	
} # End New-RCopyGroup

####################################################################################################################
## FUNCTION New-RCopyGroupCPG
###################################################################################################################
Function New-RCopyGroupCPG
{
<#
  .SYNOPSIS
   The New-RCopyGroupCPG command creates a remote-copy volume group.
   
  .DESCRIPTION
    The New-RCopyGroupCPG command creates a remote-copy volume group.   
	
  .EXAMPLE
	New-RCopyGroupCPG -GroupName ABC -TargetName XYZ -Mode Sync	
	
  .EXAMPLE  
	New-RCopyGroupCPG -UsrCpg -LocalUserCPG BB -UsrTargetName XYZ -TargetUserCPG CC -GroupName ABC -TargetName XYZ -Mode Sync

  .PARAMETER UsrCpg
  
  .PARAMETER SnpCpg
  
  .PARAMETER UsrTargetName
  
  .PARAMETER SnpTargetName
	  
  .PARAMETER LocalUserCPG
	Specifies the local user CPG and target user CPG that will be used for volumes that are auto-created.
	
  .PARAMETER TargetUserCPG
	-TargetUserCPG target:Targetcpg The local CPG will only be used after fail-over and recovery.
	
  .PARAMETER LocalSnapCPG
	Specifies the local snap CPG and target snap CPG that will be used for volumes that are auto-created. 
	
  .PARAMETER TargetSnapCPG
	-LocalSnapCPG  target:Targetcpg
		
  .PARAMETER domain
	Creates the remote-copy group in the specified domain.
	
  .PARAMETER GroupName
	Specifies the name of the volume group, using up to 22 characters if the mirror_config policy is set, or up to 31 characters otherwise. This name is assigned with this command.	
	
  .PARAMETER TargetName
	Specifies the target name associated with this group.
	
  .PARAMETER Mode 	
	sync—synchronous replication
	async—asynchronous streaming replication
	periodic—periodic asynchronous replication
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-PoshSshConnection Or New-CLIConnection
	
  .Notes
    NAME:  New-RCopyGroupCPG
    LASTEDIT: December 2019
    KEYWORDS: New-RCopyGroupCPG
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$GroupName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Mode,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$domain,
			
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$UsrCpg,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$LocalUserCPG,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetUserCPG,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$UsrTargetName,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$SnpCpg,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$LocalSnapCPG,
				
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetSnapCPG,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$SnpTargetName,
				
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
	)		
	Write-DebugLog "Start: In New-RCopyGroupCPG - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting New-RCopyGroupCPG since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet New-RCopyGroupCPG since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
		
	$cmd= "creatercopygroup"
	
	if ($domain)	
	{
		$cmd+=" -domain $domain"
	}	
	if($UsrCpg)
	{
		$cmd+=" -usr_cpg"
		if($LocalUserCPG)
		{
			$cmd+=" $LocalUserCPG"
		}
		if ($UsrTargetName)
		{		
			$cmd+=" $UsrTargetName"
		}
		if($TargetUserCPG)
		{
			$cmd+=":$TargetUserCPG "				
		}
	}
	if($SnpCpg)
	{
		$cmd+=" -snp_cpg"
		if($LocalSnapCPG)
		{
			$cmd+=" $LocalSnapCPG"
		}
		if ($SnpTargetName)
		{		
			$cmd+=" $SnpTargetName"
		}
		if($TargetSnapCPG)
		{
			$cmd+=":$TargetSnapCPG "				
		}
	}
	if ($GroupName)
	{
		$cmd+=" $GroupName"
	}
	else
	{
		Write-DebugLog "Stop: GroupName is mandatory" $Debug
		return "Error :  -GroupName is mandatory. "			
	}	
	if ($TargetName)
	{		
		$cmd+=" $TargetName"
	}
	else
	{
		Write-DebugLog "Stop: TargetName is mandatory" $Debug
		return "Error :  -TargetName is mandatory. "			
	}
	if ($Mode)
	{		
		$a = "sync","async","periodic"
		$l=$Mode
		if($a -eq $l)
		{
			$cmd+=":$Mode "				
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  New-RCopyGroupCPG   since Mode $Mode in incorrect "
			Return "FAILURE : Mode :- $Mode is an Incorrect Mode  [sync | async | periodic]  can be used only . "
		}		
	}
	else
	{
		Write-DebugLog "Stop: Mode is mandatory" $Debug
		return "Error :  -Mode is mandatory. "			
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  The command creates a remote-copy volume group..   " "INFO:" 	
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Executing  New-RCopyGroupCPG Command $Result"
	}
	else
	{
		return  "FAILURE : While Executing  New-RCopyGroupCPG 	$Result "
	} 	
} # End New-RCopyGroupCPG	

####################################################################################################################
## FUNCTION New-RCopyTarget
####################################################################################################################
Function New-RCopyTarget
{
<#
  .SYNOPSIS
   The New-RCopyTarget command creates a remote-copy target definition.
   
 .DESCRIPTION
    The New-RCopyTarget command creates a remote-copy target definition.
   
  .EXAMPLE  
	New-RCopyTarget -TargetName demo1 -RCIP -NSP_IP 1:2:3:10.1.1.1
	This Example creates a remote-copy target, with option N_S_P_IP Node ,Slot ,Port and IP address. as 1:2:3:10.1.1.1 for Target Name demo1
	
  .EXAMPLE
	New-RCopyTarget -TargetName demo1 -RCIP -NSP_IP "1:2:3:10.1.1.1,1:2:3:10.20.30.40"
	This Example creates a remote-copy with multiple targets
	
  .EXAMPLE 
	 New-RCopyTarget -TargetName demo1 -RCFC -Node_WWN 1122112211221122 -NSP_WWN 1:2:3:1122112211221122
	This Example creates a remote-copy target, with option NSP_WWN Node ,Slot ,Port and WWN as 1:2:3:1122112211221122 for Target Name demo1
		
  .EXAMPLE 
	 New-RCopyTarget -TargetName demo1 -RCFC -Node_WWN 1122112211221122 -NSP_WWN "1:2:3:1122112211221122,1:2:3:2244224422442244"
	This Example creates a remote-copy of FC with multiple targets
		
  .PARAMETER TargetName
	The name of the target definition to be created, specified by using up to 23 characters.

  .PARAMETER RCIP	:	remote copy over IP (RCIP).
	
  .PARAMETER RCFC	:	remote copy over Fibre Channel (RCFC).
		
  .PARAMETER Node_WWN
	The node's World Wide Name (WWN) on the target system (Fibre Channel target only).
	
  .PARAMETER NSP_IP
	Node number:Slot number:Port Number:IP Address of the Target to be created.
	
  .PARAMETER NSP_WWN
	Node number:Slot number:Port Number:World Wide Name (WWN) address on the target system.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  New-RCopyTarget
    LASTEDIT: December 2019
    KEYWORDS: New-RCopyTarget
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$RCIP,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$RCFC,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Disabled,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Node_WWN,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$NSP_IP,
		
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$NSP_WWN,
				
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In New-RCopyTarget   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting New-RCopyTarget since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet New-RCopyTarget since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "creatercopytarget"
	
	if ($Disabled)	
	{	
		$cmd+=" -disabled "
	}
	if ($TargetName)	
	{	
		$cmd+=" $TargetName "
	}
	else
	{
		Write-DebugLog "Stop: -TargetName is mandatory" $Debug
		return "Error :  -TargetName is mandatory. "			
	}
	
	if ($RCIP)	
	{	
		if($RCFC)
		{
			return "FAILURE : Use either RCIP or RCFC"
		}
		else
		{
			$cmd+=" IP "
		}
	}
	if ($RCFC)	
	{	
		if($RCIP)
		{
			return "FAILURE : Use either RCIP or RCFC"
		}
		else
		{
			$cmd+=" FC "
		}		
	}
	if($NSP_IP)
	{
		if($RCFC)
		{
			return "Error : -NSP_IP $NSP_IP cannot be used, Along with $RCFC.  "
		}
		$s = $NSP_IP
		$s= [regex]::Replace($s,","," ")	
		$cmd+="$s"
	}
	if ($Node_WWN)
	{
		if($RCIP)
		{
			return "Error : -Node_WWN $Node_WWN cannot be used, Along with $RCIP.  "
		}		
		$cmd+=" $Node_WWN "	
		if ($NSP_WWN)
		{				
			$s = $NSP_WWN
			$s= [regex]::Replace($s,","," ")	
			$cmd+="$s"
		}
	}	
	if ($cmd -eq "creatercopytarget")
	{
		write-debuglog "Error: no parameters passed "
		return get-help New-RCopyTarget		
	}
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  The New-RCopyTarget command creates a remote-copy target definition.   " "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Executing New-RCopyTarget Command "
	}
	else
	{
		return  "FAILURE : While Executing New-RCopyTarget $Result "
	} 	
} # End New-RCopyTarget

##########################################################################
######################### FUNCTION Remove-Cert #######################
##########################################################################
Function Remove-Cert()
{
<#
  .SYNOPSIS
   Remove-Cert - Removes SSL certificates from the Storage System.

  .DESCRIPTION
   The Remove-Cert command is used to remove certificates that are no longer
   trusted. In most cases it is better to overwrite the offending certificate
   with importcert. The user specifies which service to have its certificates
   removed. The removal can be limited to a specific type.

  .EXAMPLE
	Remove-Cert -SSL_Service_Name "xyz" -Type "xyz"
	
  .EXAMPLE
	Remove-Cert -SSL_Service_Name "all" -Type "xyz"

  .PARAMETER SSL_Service_Name
	Valid service names are cim, cli, ekm-client, ekm-server, ldap,
	syslog-gen-client, syslog-gen-server, syslog-sec-client,
	syslog-sec-server, wsapi, vasa, and unified-server.
	The user may also specify all, which will remove certificates for all
	services.
	
  .PARAMETER F
	Skips the prompt warning the user of which certificates will be removed and which services will be restarted.  

  .PARAMETER Type
   Allows the user to limit the removal to a specific type. Note that types
   are cascading. For example, intca will cause the service certificate to
   also be removed.
   Valid types are csr, cert, intca, and rootca.

  .Notes
    NAME: Remove-Cert
    LASTEDIT December 2019
    KEYWORDS: Remove-Cert
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$true)]
	[System.String]
	$SSL_Service_Name,
	
	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$F,
	
	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Type,
	
	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Remove-Cert - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Remove-Cert since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Remove-Cert since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

	$Cmd = " removecert "

 if($SSL_Service_Name)
 {
	$Cmd += " $SSL_Service_Name "
 }

 if($F)
 {
	$Cmd += " -f "
 }
 
 if($Type)
 {
	$Cmd += " -type $Type "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Remove-Cert Command -->" INFO: 
 
 Return $Result
} ##  End-of Remove-Cert

##########################################################################
######################### FUNCTION Measure-Upgrade #####################
##########################################################################
Function Measure-Upgrade()
{
<#
  .SYNOPSIS
   Measure-Upgrade - Determine if a system can do an online upgrade. (HIDDEN)

  .EXAMPLE
  
  .PARAMETER Allow_singlepathhost
	Overrides the default behavior of preventing an online upgrade if a host
	is at risk of losing connectivity to the array due to only having a
	single access path to the StoreServ. Use of this option will result in a
	loss of connectivity for the host when the path to the array disconnects
	as the node reboots to the new version. This option should be used with
	extreme caution.

  .PARAMETER Debug
	Display debug level information from check scripts.

  .PARAMETER Extraverbose
	Display test output, even for passing or not applicable scripts.

  .PARAMETER Getpostabortresults
	Displays results of the latest set of postabort scripts.

  .PARAMETER Getresults
	Displays results of the latest set of scripts that have been run (except
	postabort scripts).

  .PARAMETER Getworkarounds
	Displays information about workarounds that apply to an upgrade.

  .PARAMETER Nopatch
	Do not check for any checkupgrade update packages.

  .PARAMETER Offline
	Checks that apply only to online upgrades will be skipped.

  .PARAMETER Phase <phasename>
	Set of scripts to run. phasename can be any one of the following:
	postabort, postcheck, postchecklist, postunpack, preboot, precheck,
	prechecklist, preswitch, preupgrade, preupgradelist

  .PARAMETER Revertnode
	Used to check when reverting nodes as part of aborting an upgrade.

  .PARAMETER Verbose
	Display output from the checkupgrade update package check.

  .Notes
    NAME: Measure-Upgrade
    LASTEDIT: March 2020 
    KEYWORDS: Measure-Upgrade
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(

	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Allow_singlepathhost,
	
	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$Extraverbose,
	
	[Parameter(Position=2, Mandatory=$false)]
	[switch]
	$Getpostabortresults,
	
	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Getresults,
	
	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Getworkarounds,
	
	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$Nopatch,
	
	[Parameter(Position=6, Mandatory=$false)]
	[switch]
	$Offline,
	
	[Parameter(Position=7, Mandatory=$false)]
	[System.String]
	$Phase,
	
	[Parameter(Position=8, Mandatory=$false)]
	[switch]
	$Revertnode,
	
	[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Measure-Upgrade - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Measure-Upgrade since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Measure-Upgrade since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }
 
	$Cmd = " checkupgrade "

 if($Allow_singlepathhost)
 {
	$Cmd += " -allow_singlepathhost "
 }
 
 if($Debug)
 {
	$Cmd += " -debug "
 }
 
 if($Extraverbose)
 {
	$Cmd += " -extraverbose "
 }
 
 if($Getpostabortresults)
 {
	$Cmd += " -getpostabortresults "
 }
 
 if($Getresults)
 {
	$Cmd += " -getresults "
 }
 
 if($Getworkarounds)
 {
	$Cmd += " -getworkarounds "
 }
 
 if($Nopatch)
 {
	$Cmd += " -nopatch "
 }
 
 if($Offline)
 {
	$Cmd += " -offline "
 }
 
 if($Phase)
 {
	$Cmd += " -phase $Phase "
 }
 
 if($Revertnode)
 {
	$Cmd += " -revertnode "
 }
 
 if($Verbose)
 {
	$Cmd += " -verbose "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Measure-Upgrade Command -->" INFO: 
 
 Return $Result
} ##  End-of Measure-Upgrade

##########################################################################
######################### FUNCTION Optimize-LD #######################
##########################################################################
Function Optimize-LD()
{
<#
  .SYNOPSIS
   Optimize-LD - Change the layout of a logical disk. (HIDDEN)
   
  .DESCRIPTION (HIDDEN)
    The Optimize-LD command is used to make changes to
    a logical disk (LD) by creating a new LD and moving
    regions from the original LD to the new LD.

    The new LD will always have the same space type (SA, SD,
    USR) as the original LD.

    If the original LD belongs to a CPG, the new LD inherits
    the characteristics of that CPG. SA and SD space LDs have
    growth and allocations blocked so the original LD can be
    completely emptied during the tune.

    If the original LD does not belong to a CPG, a new LD
    will be created, inheriting the characteristics of the
    original LD.

    When a new LD is created it will spread to whatever PDs are
    available as determined by availability and pattern rules.

    The options detailed below can be used to control some
    aspects of the new LD.
	
	
  .EXAMPLE
  
  .PARAMETER LD_name
	Name of the LD to tune.
  
  .PARAMETER Waittask
	Wait for the command to complete before returning.
		  
  .PARAMETER DR
	Specifies that the command is a dry run and that the
	logical disk will not be tuned. The command will return
	any error messages that would be displayed or a
	summary of the actions that would be performed.

  .PARAMETER Shared
	Where possible, share the destination LDs and do not
	create new LDs.

  .PARAMETER Regions 
	Number of regions to move at a time. Range is
	1-1024, default is 1024.

  .PARAMETER Tunesys
	Only to be used when called from tunesys. When present,
	tuneld will update task information in the calling tunesys
	task with progress information. Also, when present tuneld
	will exit the CLI if certain errors occur, otherwise only an
	error will be displayed.

  .PARAMETER Tunenodech
	Only to be used when called from tunenodech. When present
	tuneld will exit the CLI if certain errors occur, otherwise
	only an error will be displayed.

  .PARAMETER Preserved
	Only to be used when source LD is in a preserved state. This option
	will move all good regions from the source LD to a new LD.

  .Notes
    NAME: Optimize-LD
    LASTEDIT: March 2020
    KEYWORDS: Optimize-LD
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Waittask,
	
	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$DR,
	
	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Shared,
	
	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Regions,
	
	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Tunesys,
	
	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Tunenodech,
	
	[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Preserved,
	
	[Parameter(Position=7, Mandatory=$true)]
	[System.String]
	$LD_name,
 
	[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Optimize-LD - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Optimize-LD since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Optimize-LD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }
 
	$Cmd = " tuneld -f "

 if($Waittask)
 {
	$Cmd += " -waittask "
 }
 
 if($DR)
 {
	$Cmd += " -dr "
 }
 
 if($Shared)
 {
	$Cmd += " -shared "
 }
 
 if($Regions)
 {
	$Cmd += " -regions $Regions "
 }
 if($Tunesys)
 {
	$Cmd += " -tunesys "
 }
 
 if($Tunenodech)
 {
	$Cmd += " -tunenodech "
 }
 
 if($Preserved)
 {
	$Cmd += " -preserved "
 }
 
 if($LD_name)
 {
	$Cmd += " $LD_name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Optimize-LD Command -->" INFO: 
 
 Return $Result
} ##  End-of Optimize-LD

##########################################################################
######################### FUNCTION Optimize-Nodech #######################
##########################################################################
Function Optimize-Nodech()
{
<#
  .SYNOPSIS
   Optimize-Nodech - Rebalance PD utilization on a node after upgrades. (HIDDEN)
   
  .DESCRIPTION 
    The tunenodech command is used to analyze and detect poor layout
    and disk utilization across PDs with a specified node owner.
    Rebalancing is achieved using a combination of chunklet movement and
    re-laying out LDs associated with the node.

  .EXAMPLE
  
  .PARAMETER Node
	The ID of the node to be tuned. <number> must be in the range 0-7. This parameter must be supplied.
	
  .PARAMETER Chunkpct 
	Controls the detection of underutilized PDs associated with a node.
	The average utilization of all PDs of a devtype is calculated and
	any PD with a utilization of (average - <percentage>) will trigger
	node tuning for that devtype. For example, if the average is 70%
	and <percentage> is 10%, then the threshold will be 60%.
	<percentage> must be between 1 and 100. The default value is 10.
	
  .PARAMETER Maxchunk 
	Controls how many chunklets are moved from each PD per move
	operation. <number> must be between 1 and 8. The default value
	is 8.
		
  .PARAMETER Fulldiskpct 
	If a PD has more than <percentage> of its capacity utilized, chunklet
	movement is used to reduce its usage to <percentage> before LD tuning
	is used to complete the rebalance. e.g. if a PD is 98% utilized and
	<percentage> is 90, chunklets will be redistributed to other PDs until the
	utilization is less than 90%. If <percentage> is less than the devtype
	average then the calculated average will be used instead.
	<percentage> must be between 1 and 100. The default value is 90.
	
  .PARAMETER Devtype 
	Specifies a comma separated list of one or more devtypes to be tuned.
	<devtype> can be one of SSD, FC or NL. Default is all devtypes.
	All named devtypes must be present on the node being tuned.
	
  .PARAMETER DR
	Perform a dry-run analysis of the system and report details on what
	tuning would be performed with the supplied settings.  

  .Notes
    NAME: Optimize-Nodech
    LASTEDIT: March 2020
    KEYWORDS: Optimize-Nodech
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Node,
	
	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Chunkpct,
	
	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Maxchunk,
	
	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Fulldiskpct,
	
	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Devtype,
	
	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$DR,
 
	[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection	
 )

 Write-DebugLog "Start: In Optimize-Nodech - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Optimize-Nodech since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Optimize-Nodech since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " tunenodech -f "
	
 if($Node)
 {
	$Cmd += " -node $Node "
 }
 
 if($Chunkpct)
 {
	$Cmd += " -chunkpct $Chunkpct "
 }
 
 if($Maxchunk)
 {
	$Cmd += " -maxchunk $Maxchunk "
 }
 
 if($Fulldiskpct)
 {
	$Cmd += " -fulldiskpct $Fulldiskpct "
 }
 
 if($Devtype)
 {
	$Cmd += " -devtype $Devtype "
 }
 
 if($DR)
 {
	$Cmd += " -dr "
 }
 
 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Optimize-Nodech Command -->" INFO: 
 
 Return $Result
} ##  End-of Optimize-Nodech

#################################################################################
############################ Function Start-SR ##################################
#################################################################################
Function Start-SR
{
<#
  .SYNOPSIS
    To start System reporter.
  
  .DESCRIPTION
    To start System reporter.
        
  .EXAMPLE
    Start-SR 
	Starts System Reporter
 	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Start-SR
    LASTEDIT: March 2020
    KEYWORDS: Start-SR
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(

		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Start-SR - validating input values" $Debug 
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
				Write-DebugLog "Connection object is null/empty or Connection object username, password, IPAaddress are null/empty. Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Start-SR since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Start-SR since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}

	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "startsr -f "
	write-debuglog "System reporter command => $srinfocmd" "INFO:"
	$3parosver = Get-Version -S -SANConnection  $SANConnection 
	if($3parosver -ge "3.1.2")
	{
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		if(-not $Result)
		{
			return "Success: Started System Reporter $Result"
		}
		elseif($Result -match "Cannot startsr, already started")
		{
			Return "Command Execute Successfully :- Cannot startsr, already started"
		}
		else
		{
			return $Result
		}		
	}
	else
	{
		return "Current version $3parosver does not support these cmdlet"
	}
}
#### End Start-SR 

#################################################################################
############################ Function Stop-SR ###################################
#################################################################################
Function Stop-SR
{
<#
  .SYNOPSIS
    To stop System reporter.
  
  .DESCRIPTION
    To stop System reporter.
        
  .EXAMPLE
    Stop-SR 
	Stop System Reporter
 	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Stop-SR
    LASTEDIT: March 2020
    KEYWORDS: Stop-SR
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(

		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Stop-SR - validating input values" $Debug 
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
				Write-DebugLog "Connection object is null/empty or Connection object username, password, IPAaddress are null/empty. Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Stop-SR since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Stop-SR since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}

	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "stopsr -f "
	$3parosver = Get-Version -S -SANConnection  $SANConnection
	write-debuglog "System reporter command => $srinfocmd" "INFO:"
	if($3parosver -ge "3.1.2")
	{
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $srinfocmd
		if(-not $Result)
		{
			return "Success: Stopped System Reporter $Result"
		}
		else
		{
			return $Result
		}
	}
	else
	{
		return "Current OS version $3parosver does not support these cmdlet"
	}
}
#### End Stop-SR

Export-ModuleMember Get-Cert , Get-Encryption , Get-SR , Import-Cert , New-Cert , New-RCopyGroup , New-RCopyGroupCPG , New-RCopyTarget , Remove-Cert , Measure-Upgrade , Optimize-LD , Optimize-Nodech , Start-SR , Stop-SR
