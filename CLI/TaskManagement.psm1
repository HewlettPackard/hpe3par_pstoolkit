####################################################################################
## 	© 2019,2020 Hewlett Packard Enterprise Development LP
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
##	File Name:		TaskManagement.psm1
##	Description: 	Task Management cmdlets 
##		
##	Created:		January 2020
##	Last Modified:	January 2020
##	History:		v3.0 - Created	
#####################################################################################

$Info = "INFO:"
$Debug = "DEBUG:"
$global:VSLibraries = Split-Path $MyInvocation.MyCommand.Path
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

############################################################################################################################################
## FUNCTION Test-3parObject
############################################################################################################################################
Function Test-3parobject 
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
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmds
	if ($Result -like "no $ObjectMsg listed")
	{
		$IsObjectExisted = $false
	}
	return $IsObjectExisted
	
} # End FUNCTION Test-3parObject

############################################################################
########################### Function Get-Task ##############################
############################################################################
Function Get-Task
{
<#
  .SYNOPSIS
    Displays information about tasks.
  
  .DESCRIPTION
	Displays information about tasks.
	
  .EXAMPLE
    Get-Task 
	Display all tasks.
        
  .EXAMPLE
    Get-Task -All
	Display all tasks. Unless the -all option is specified, system tasks
	are not displayed.
	
  .EXAMPLE		
	Get-Task -Done
	 Display includes only tasks that are successfully completed

  .EXAMPLE
	Get-Task -Failed
	 Display includes only tasks that are unsuccessfully completed.
	
  .EXAMPLE	
	Get-Task -Active
	 Display includes only tasks that are currently in progress.
	
  .EXAMPLE	
	Get-Task -Hours 10
	 Show only tasks started within the past <hours>
	 
  .EXAMPLE	
	Get-Task -Task_type xyz
	 Specifies that specified patterns are treated as glob-style patterns and that all tasks whose types match the specified pattern are displayed
	
  .EXAMPLE	
	Get-Task -taskID 4
	 Show detailed task status for specified task 4.

  .PARAMETER All	
	Displays all tasks.
  
  .PARAMETER Done	
	Displays only tasks that are successfully completed.
  
  .PARAMETER Failed	
	Displays only tasks that are unsuccessfully completed.
  
  .PARAMETER Active	
	Displays only tasks that are currently in progress
	
  .PARAMETER Hours 
    Show only tasks started within the past <hours>, where <hours> is an integer from 1 through 99999.
	
  .PARAMETER Task_type 
     Specifies that specified patterns are treated as glob-style patterns and that all tasks whose types match the specified pattern are displayed. To see the different task types use the showtask column help.
	
  .PARAMETER TaskID 
     Show detailed task status for specified tasks. Tasks must be explicitly specified using their task IDs <task_ID>. Multiple task IDs can be specified. This option cannot be used in conjunction with other options.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-Task
    LASTEDIT: January 2020
    KEYWORDS: Get-Task
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[Switch]
		$All,	
		
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$Done,
		
		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$Failed,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$Active,

		[Parameter(Position=4, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Hours,
		
		[Parameter(Position=5, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Task_type,
		
		[Parameter(Position=6, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$TaskID,   

		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 		
	)		
	
	Write-DebugLog "Start: In Get-Task - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-Task since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-Task since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$taskcmd = "showtask "
	
	if($All)	
	{
		$taskcmd +=" -all "
	}
	if($Done)	
	{
		$taskcmd +=" -done "
	}
	if($Failed)	
	{
		$taskcmd +=" -failed "
	}
	if($Active)	
	{
		$taskcmd +=" -active "
	}
	if($Hours)	
	{
		$taskcmd +=" -t $Hours "
	}
	if($Task_type)	
	{
		$taskcmd +=" -type $Task_type "
	}
	if($TaskID)	
	{
		$taskcmd +=" -d $TaskID "
	}	
	
	$result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $taskcmd
	#write-host $result 
	write-debuglog " Running get task status  with the command --> $taskcmd" "INFO:"
	if($TaskID)	
	{
		return $result
	}	
	if($Result -match "Id" )
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count  
		$incre = "true"
		foreach ($s in  $Result[0..$LastItem] )
		{		
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")	
			$s= [regex]::Replace($s,"-","")			
			$s= $s.Trim() -replace 'StartTime,FinishTime','Date(ST),Time(ST),Zome(ST),Date(FT),Time(FT),Zome(FT)' 
			if($incre -eq "true")
			{
				$s=$s.Substring(1)					
			}
			Add-Content -Path $tempFile -Value $s
			$incre="false"		
		}
		Import-Csv $tempFile 
		del $tempFile
	}	
	if($Result -match "Id")
	{
		return  " Success : Executing Get-Task"
	}
	else
	{			
		return  $Result
	}	
} #END Get-Task

Export-ModuleMember Get-Task