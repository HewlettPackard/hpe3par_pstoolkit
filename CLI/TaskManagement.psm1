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
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-Task
    LASTEDIT: January 2020
    KEYWORDS: Get-Task
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$TaskID,   

		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Task_type,
		
		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$All,	
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$Done,
		
		[Parameter(Position=4, Mandatory=$false)]
		[Switch]
		$Failed,
		
		[Parameter(Position=5, Mandatory=$false)]
		[Switch]
		$Active,

		[Parameter(Position=6, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Hours,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 		
	)		
	
	Write-DebugLog "Start: In Get-Task - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-Task since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-Task since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
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
	
	if($TaskID)	
	{
		$taskcmd +=" -d $TaskID "
	}
	if($Task_type)	
	{
		$taskcmd +=" -type $Task_type "
	}	
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
	
	$result = Invoke-CLICommand -Connection $SANConnection -cmds  $taskcmd
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
		return
		#return  " Success : Executing Get-Task"
	}
	else
	{			
		return  $Result
	}	
} #END Get-Task

####################################################################################################################
## FUNCTION Remove-Task
####################################################################################################################
Function Remove-Task {
    <#
  .SYNOPSIS
    Remove one or more tasks or task details.
                                                                                                           .
  .DESCRIPTION
    The Remove-Task command removes information about one or more completed tasks
    and their details.
 
  .PARAMETER A
    Remove all tasks including details.

  .PARAMETER D
    Remove task details only.

  .PARAMETER F
    Specifies that the command is to be forced. You are not prompted for
    confirmation before the task is removed.
   
  .PARAMETER T <hours>
     Removes tasks that have not been active within the past <hours>, where
     <hours> is an integer from 1 through 99999.

  .PARAMETER TaskID
    Allows you to specify tasks to be removed using their task IDs.

  .EXAMPLES
    Remove a task based on the task ID

    Remove-Task 2

    Remove the following tasks?
    2
    select q=quit y=yes n=no: y

  .EXAMPLES
    Remove all tasks, including details

    Remove-Task -A

    Remove all tasks?
    select q=quit y=yes n=no: y
  
  .NOTES
    With this command, the specified task ID and any information associated with
    it are removed from the system. However, task IDs are not recycled, so the
    next task started on the system uses the next whole integer that has not
    already been used. Task IDs roll over at 29999. The system stores
    information for the most recent 2000 tasks.

    NAME:  Remove-Task
    LASTEDIT: 25/04/2021
    KEYWORDS: Remove-Task
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false, HelpMessage="specify tasks to be removed using their task ID")]
        [System.String]
        $TaskID,
		
        [Parameter(Position = 1, Mandatory = $false, HelpMessage="Remove all tasks including details")]
        [Switch]
        $A,

        [Parameter(Position = 2, Mandatory = $false, HelpMessage="Remove task details only")]
        [Switch]
        $D,

        [Parameter(Position = 3, Mandatory = $false, HelpMessage="Specifies that the command is to be forced")]
        [Switch]
        $F,       

        [Parameter(Position = 4, Mandatory = $false, HelpMessage="Remove tasks that have not been active within the past <hours>, where
     <hours> is an integer from 1 through 99999")]
        [System.String]
        $T,		
		
        [Parameter(Position = 5, Mandatory = $false, ValueFromPipeline = $true)]
        $SANConnection = $global:SANConnection        
    )	
	
    Write-DebugLog "Start: In Remove-Task   - validating input values" $Debug 
    #check if connection object contents are null/empty
    if (!$SANConnection) {
        #check if connection object contents are null/empty
        $Validate1 = Test-CLIConnection $SANConnection
        if ($Validate1 -eq "Failed") {
            #check if global connection object contents are null/empty
            $Validate2 = Test-CLIConnection $global:SANConnection
            if ($Validate2 -eq "Failed") {
                Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
                Write-DebugLog "Stop: Exiting Remove-Task since SAN connection object values are null/empty" $Debug
                return "Unable to execute the cmdlet Remove-Task since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
            }
        }
    }
    $plinkresult = Test-PARCli
    if ($plinkresult -match "FAILURE :") {
        write-debuglog "$plinkresult" "ERR:" 
        return $plinkresult
    }		
    $cmd = "removetask "	
	
	if ($F) {
        $cmd += " -f "		
    }
	else {
		Return "Force removal is only supported with the Remove-Task cmdlet."
	}
    if ($TaskID) {
        $cmd += "$TaskID"		
    }
    if ($A) {
        $cmd += " -a"		
    }
    elseif ($D) {
        $cmd += " -d"		
    }
    elseif ($T) {
        $cmd += " -t $T"		
    }	
	
    $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd

    write-debuglog " The Remove-Task command removes hosts from a remote copy group" "INFO:" 
    return 	$Result	

} # End Remove-Task

####################################################################################################################
## FUNCTION Stop-Task
####################################################################################################################
Function Stop-Task {
  <#
.SYNOPSIS
  Cancel one or more tasks
                                                                                                         .
.DESCRIPTION
   The Stop-Task command cancels one or more tasks.

.PARAMETER F
  Forces the command. The command completes the process without prompting
  for confirmation.
 
.PARAMETER ALL
   Cancels all active tasks. If not specified, a task ID(s) must be
   specified.

.PARAMETER TaskID
   Cancels only tasks identified by their task IDs.
   TaskID must be an unsigned integer within 1-29999 range.

.EXAMPLES
  Cancel a task using the task ID

  Stop-Task 1        

.NOTES
  The Stop-Task command can return before a cancellation is completed. Thus,
  resources reserved for a task might not be immediately available. This can
  prevent actions like restarting the canceled task. Use the waittask command
  to ensure orderly completion of the cancellation before taking other
  actions. See waittask for more details.

  A Service user is only allowed to cancel tasks started by that specific user.

  NAME:  Stop-Task
  LASTEDIT: 25/04/2021
  KEYWORDS: Stop-Task
 
.Link
   http://www.hpe.com

#Requires PS -Version 3.0

#>
  [CmdletBinding()]
  param(

    [Parameter(Position = 0, Mandatory = $false)]
    [System.String]
    $TaskID,		


    [Parameter(Position = 1, Mandatory = $false)]
    [Switch]
    $F,       

    [Parameter(Position = 2, Mandatory = $false)]
    [System.String]
    $ALL,		
  
    [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $true)]
    $SANConnection = $global:SANConnection        
  )	

  Write-DebugLog "Start: In Stop-Task   - validating input values" $Debug 
  #check if connection object contents are null/empty
  if (!$SANConnection) {
    #check if connection object contents are null/empty
    $Validate1 = Test-CLIConnection $SANConnection
    if ($Validate1 -eq "Failed") {
      #check if global connection object contents are null/empty
      $Validate2 = Test-CLIConnection $global:SANConnection
      if ($Validate2 -eq "Failed") {
        Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
        Write-DebugLog "Stop: Exiting Stop-Task since SAN connection object values are null/empty" $Debug
        return "Unable to execute the cmdlet Stop-Task since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
      }
    }
  }
  $plinkresult = Test-PARCli
  if ($plinkresult -match "FAILURE :") {
    write-debuglog "$plinkresult" "ERR:" 
    return $plinkresult
  }		
  $cmd = "canceltask "	

  if ($F) {
    $cmd += " -f "		
  }
  else {
    Return "Force cancellation is only supported with the Stop-Task cmdlet."
  }
  if ($TaskID) {
    $cmd += "$TaskID"		
  }
  if ($ALL) {
    $cmd += " -all"		
  }    	

  $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd

  write-debuglog " The Stop-Task command removes hosts from a remote copy group" "INFO:" 
  return 	$Result	

} # End Stop-Task

####################################################################################################################
## FUNCTION Wait-Task
####################################################################################################################
Function Wait-Task {
    <#
  .SYNOPSIS
    Wait for tasks to complete.
                                                                                                           .
  .DESCRIPTION
     The Wait-Task cmdlet asks the CLI to wait for a task to complete before
     proceeding. The cmdlet automatically notifies you when the specified task
     is finished.

  .PARAMETER V
    Displays the detailed status of the task specified by <TaskID> as it
    executes. When the task completes, this command exits.
   
  .PARAMETER TaskID
      Indicates one or more tasks to wait for using their task IDs. When no
      task IDs are specified, the command waits for all non-system tasks
      to complete. To wait for system tasks, <TaskID> must be specified.

  .PARAMETER Q
     Quiet; do not report the end state of the tasks, only wait for them to
     exit.

  .EXAMPLES
    The following example shows how to wait for a task using the task ID. When
    successful, the command returns only after the task completes.

    Wait-Task 1  
    Task 1 done      
  
  .NOTES
    This cmdlet returns an error if any of the tasks it is waiting for fail.

    NAME:  Wait-Task
    LASTEDIT: 25/04/2021
    KEYWORDS: Wait-Task
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [Switch]
        $V, 
		
        [Parameter(Position = 1, Mandatory = $false)]
        [System.String]
        $TaskID,
		
        [Parameter(Position = 2, Mandatory = $false)]
        [Switch]
        $Q,		
		
        [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $true)]
        $SANConnection = $global:SANConnection        
    )	
	
    Write-DebugLog "Start: In Wait-Task   - validating input values" $Debug 
    #check if connection object contents are null/empty
    if (!$SANConnection) {
        #check if connection object contents are null/empty
        $Validate1 = Test-CLIConnection $SANConnection
        if ($Validate1 -eq "Failed") {
            #check if global connection object contents are null/empty
            $Validate2 = Test-CLIConnection $global:SANConnection
            if ($Validate2 -eq "Failed") {
                Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
                Write-DebugLog "Stop: Exiting Wait-Task since SAN connection object values are null/empty" $Debug
                return "Unable to execute the cmdlet Wait-Task since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."               
            }
        }
    }
    $plinkresult = Test-PARCli
    if ($plinkresult -match "FAILURE :") {
        write-debuglog "$plinkresult" "ERR:" 
        return $plinkresult
    }		
    $cmd = "waittask "	
	
    if ($V) {
        $cmd += " -v "		
    }
    if ($TaskID) {
        $cmd += "$TaskID"		
    }
    if ($Q) {
        $cmd += " -q"		
    }    	
	
    $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd

    write-debuglog " Executed the Wait-Task cmdlet" "INFO:" 

    return 	$Result	

} # End Wait-Task

Export-ModuleMember Get-Task , Remove-Task , Stop-Task , Wait-Task