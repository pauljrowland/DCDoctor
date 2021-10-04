########################
#####
#####   DCDoctor
#####
#####   Author:              Paul Rowland
#####   Created:             12/07/2021
#####   GitHub URL:          https://github.com/pauljrowland/DCDoctor
#####   ChangeLog:           https://github.com/pauljrowland/DCDoctor/commits/main/DCDoctor.ps1
#####   License:             GNU General Public License v3.0
#####   License Agreement:   https://github.com/pauljrowland/DCDoctor/blob/main/LICENSE
#####
#####   Version:             2.5
#####   Modified Date:       04/10/2021
#####
########################

[System.Console]::Clear()

##-START-## - IMPORT CONFIGURATION

$scriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent # Where is the script running from?

if (!(Test-Path -Path "$scriptRoot\DCDoctor_settings.conf")) { # If the config file doesn't exist - create it using the default file.

    if (!(Test-Path -Path "$scriptRoot\DCDoctor_settings.conf.defaults")) { # Firstly, if the defaults file is missing - get a copy from GitHub..

        $defaults = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pauljrowland/DCDoctor/main/DCDoctor_Settings.conf.defaults" -ErrorAction SilentlyContinue)

        Out-File -FilePath "$scriptRoot\DCDoctor_settings.conf" -InputObject $defaults.Content -ErrorAction SilentlyContinue # Create the config file.
    }

    else { # It does exist, so just copy the local version.

        Copy-Item -Path "$scriptRoot\DCDoctor_settings.conf.defaults" -Destination "$scriptRoot\DCDoctor_settings.conf"

    }

}

Get-Content "$scriptRoot\DCDoctor_settings.conf" | Foreach-Object { # Now the content file exists, import contents.
    $var = $_.Split('=') # Split the line at the equals '=' sign into an array.
    Set-Variable -Name $var[0] -Value $var[1] -ErrorAction SilentlyContinue # Create a variable using the left of the '=' as the name and right of the '=' as the value.
    [System.Console]::Clear()
}

##-END-## - Importing configuration

##-START-## - SCRIPT LOGGING SECTION - Function to output logs to screen & files. Written as a function to avoid repeading code.

if (!(Test-Path -Path "$scriptRoot\Logs" -ErrorAction SilentlyContinue)) { # The log directory is missing.
    
    New-Item -ItemType Directory "$scriptRoot\Logs" # Create log directory.

}

$LogFile = "$scriptRoot\Logs\DCDoctor_Results.txt" # Location of the log file which is always written.
$ErrorLogFile = "$scriptRoot\Logs\DCDoctor_Error.txt" # Location of the error log file (if required).
$eMailErrorLogFile = "$scriptRoot\Logs\DCDoctor_E-Mail-Error.txt" # Location of the error log file (if required).

# Remove log files to ensure clean sweep of script
Remove-Item -Path $LogFile -Force -ErrorAction SilentlyContinue
Remove-Item -Path $ErrorLogFile -ErrorAction SilentlyContinue
Remove-Item -Path $eMailErrorLogFile -ErrorAction SilentlyContinue

function Write-DCTestLog ([string]$logText,[switch]$warn,[switch]$pass,[switch]$fail,[switch]$plain,[switch]$info,[switch]$eMailFail) {

    # Function to write the log file. This accepts the "logTtext" parameter which created the variable "$logText"
    # and switches to decide the type of text to display, i.e.:
    # Write-DCTestLog -logText "This is a warning" -warn

    $date = (Get-Date -Format "dd/MM/yyy HH:mm:ss") # Get date and format for readability.

    if ($pass) { # Checks passed.
        $outputLogText = "$date   P!:   $logText`n" # Log output and add "P!:" to line.
        $fgColor = "green" # Change colour to green.
    }

    if ($fail) { # Checks failed.
        $outputLogText = "$date   E!:   $logText`n" # Log output and add "E!:" to line.
        $fgColor = "red" # Change colour to red.
    }

    if ($info) { # Information line to be written.
        $outputLogText = "$date   I!:   $logText`n" # Log output and add "I!:" to line.
        $fgColor = "yellow"  # Change colour to yellow.
    }

    if ($warn) { # Warning line to be written.
        $outputLogText = "$date   W!:   $logtext`n" # Log output and add "W!:" to line.
        $fgColor = "yellow"  # Change colour to yellow.
    }

    if ($plain) { # Plain white text block.
        $outputLogText = "$logText`n" # Text to output.
        $fgColor = "white"  # Change colour to white.
    }

    if ($eMailfail) { # E-Mail failed to send.
        $outputLogText = "$date   E!:   $logText`n" # Log output and add "E!:" to line.
        $fgColor = "red" # Change colour to red.
    }

    Write-Host $outputLogText -ForegroundColor $fgColor # Display the text on-screen if the script is being watched by a user.

    # This will output to the text file(s)depending on the type. Once the script ha completed, there may be an erro file. If E-Mails
    # are configured, the admin will be alerted with a copy of the report. If the error file does not exist - no E-Mail is sent.

    $outputLogText | Out-File -FilePath $LogFile -Append # Output the content to the log file.

    if ($fail) { # Established that there is a failure. In this case, add details to the error log ready to be E-Mailed.
        if (!(Test-Path -Path $ErrorLogFile -ErrorAction SilentlyContinue)) { # Does the error file exist? If not, make it...
            Write-Output "Error log for $env:COMPUTERNAME.$env:USERDNSDOMAIN`n"  | Out-File -FilePath $ErrorLogFile -Append
        }
        $outputLogText | Out-File -FilePath $ErrorLogFile -Append # Output the error content to the error log file.
    }

    if ($eMailFail) { # E-Mail failed to send. Logging now in a seperate log.
        $logo | Out-File -FilePath $eMailErrorLogFile -Append # Add the logo to the E-Mail error log
        Write-Output "Failed to send E-Mail (ERROR: $eMailError) for $env:COMPUTERNAME.$env:USERDNSDOMAIN`n"  | Out-File -FilePath $eMailErrorLogFile -Append
    }

}

##-START-## - BANNER - Display banner at the top of the PowerShell session and log file.

$date = (Get-Date -Format "dd/MM/yyy HH:mm:ss")
Write-Host @"
    Starting Script... $date
    
"@

$logo = @"

                          DCDoctor Diagnostic Report
                         Generated $date

           Paul Rowland - https://github.com/pauljrowland/DCDoctor

                              -/osyhhhhyys+:.
                            '/yhhhhhhhhhhhhhhhy/.
                           :yhhhhhhhhhhhhhhhhhhhh/
                        ./shhhhhhhhhhhhhhhhhhhhhhhs
                       :yhhhhhhhhhhhhhhhhhhhhhhhhhhy+
                      'yhhhh+ohhhhhhhhhhhhhhhs+-/hhhh+
                      :hhhh:  .+shhyyyyssoo+//   +hhhy
                      /hhh+     '.-/+ooooooo+/   .hhhy
                      -hhh:            '''        hhho
                      'yhh+                       hhh:
                     'ohhhy                      .hhhs+
                     .hhhhh-                     /hhhhy
                      :shhhs                    'yhhho-
                       '-/hh/                   +hh/-
                          /hh-                 /hh:
                           +hh:              '/hh:
                            :yh+'           .ohy-
                             .ohy/.      '-+hh+
                               -ohhso+/+oyhy+.
                                 '-/oooo+/-
                            --                 --
                     '.-/+syho                 shyo+/-.
                '-/oshhhhhhhhh-     '/o:'     /hhhhhhhhys+/-
              -oyhhhhys+/:.shhy'    shhh+    .hhho.:/osyhhhhyo-
            'shhhs+yh/     -hhho    /hhh-   'shhy'    '-hh+shhho
            ohhh-' +ho      /hhh/   shhh+   ohhh-      oho ':hhh/
           -hhh/   -hy'      +hhh: 'hhhhy  +hhh:  .-::/hh.   ohhh.
           ohhy'   'yh:      'ohhh::hhhhh-+hhh/':syysosyho-  .hhh+
          'hhh+     :hy'       +hhhyhhhhhyhhh:'+hs-'' '':yh/  shhy
          :hhh.      oho        :yhhhhhhhhhs-'+hs'       -hh' :hhh-
          ohhy       'yh/        .ohhhhhhh+''ohs'        .hh' 'hhh/
         'yhho        .yh+/:.      :yhhhs- 'oho'         +ho   shhs
         .hhh:         ohhhhy.      '/+:'  ohs'         'hh-   +hhh
         /hhh.         ohhhhh-            -hh'          /hs    -hhh-
         +hhh          '/os+-             :hh:'        'yh:    .hhh/
         yhhs                              :oy+     '''+hs      hhho
        'yhho                                      :ssyhs'      shhs
        .hhh/                                      '-::-'       ohhy
        :hhhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhhh.
        +hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh:

"@

Write-DCTestLog -logText $logo -plain # Put the above logo on screen and in to the log files.

Write-DCTestLog -logText "DCDoctor Health Report for $env:COMPUTERNAME.$env:USERDNSDOMAIN" -plain # Put the PC details and date etc. into the log and on screen.

Start-Sleep -Seconds 5 # Sleep for 5 seconds

[System.Console]::Clear()

##-END-## -  BANNER

##-START-## - EXCLUSION CHECK (Un-comment all lines in the EXCLUSION CHECK section if Required by removing the <# & #>)
#             Check for excluded servers in the list to prevent those with known / unfixable errors from constantly sending E-Mails.

$serverName = $env:computerName
$counter = 0
foreach ($excludedServer in $excludedServers) { # Loop through all excluded servers
    $counter++
    Write-Progress -Activity 'DCDoctor Domain Controller Checks - Checking: Excluded Servers...' -CurrentOperation $excludedServer -PercentComplete (($counter / $excludedServers.count) * 100)

    if ($excludedServer -like $serverName) { # If the server is on the list - end the script
        Write-DCTestLog -logText "This machine is present on the excluded server list, ending test..." -info
        Write-DCTestLog -logText "Ended test on $date as this was not required!" -plain
        exit
    }

}

##-END-## -  EXCLUSION CHECK

##-START-## - DC Check - Check to see whether the machine is indeed a domain controller
         
Write-DCTestLog -logText "Checking whether this machine is indeed an Active Directory Domain Controller..." -info

# Get the return code of the domain role
$domainRole = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty DomainRole

if (!($domainRole -match '4|5')) { # If the domain role doesn't match '4' (PDC) or '5' (BDC (legacy)) - end the script

    Write-DCTestLog -logText "This machine is not an Active Directory domain controller, ending test..." -info

    # Complete and end script
    $date = (Get-Date -Format "dd/MM/yyy HH:mm:ss")
    Write-DCTestLog -logText "Completed test on $date" -plain
    exit

}

else { # The role does match so continue processing the script
    Write-DCTestLog -logText "This machine is an Active Directory domain controller" -pass
}

##-END-## -  DC CHECK

##-START-## - SERVICE CHECK MODULE - Function for checking services

function checkServices {

Write-Host @"

    Performing Active-Directory critical service checks...

"@

    # List of Active Directory-Related Services to Check
    $Services = "Active Directory Domain Services","Kerberos Key Distribution Center","Intersite Messaging","DHCP Server","DNS Server" # List services to check

    $counter = 0
    ForEach ($Service in $Services) { # Loop through each service
        $counter++
        Write-Progress -Activity 'DCDoctor Domain Controller Checks - Checking: Service...' -CurrentOperation $Service -PercentComplete (($counter / $Services.count) * 100)

        Write-DCTestLog -logText "Checking $Service Service" -info

        if (Get-Service -DisplayName $Service -ErrorAction SilentlyContinue) { # If the service is installed - continue to check status

            # Get the status of the service
            $ServiceStatus = (Get-Service -DisplayName $Service | Select-Object -ExpandProperty Status)

            # Get the start mode of the service
            $ServiceStartType = Get-WmiObject -Class Win32_Service -Property StartMode -Filter "DisplayName='$Service'"
            $ServiceStartType = $ServiceStartType.StartMode

            if ($ServiceStatus -ne "Running") { # If the service isn't running, find out why and try to rectify it
            
                if ($ServiceStartType -ne "Disabled") { # If the service isn't disabled, try to start it

                    Write-DCTestLog -logText "$Service is not running, trying to start..." -warn

                    # Try to start the service
                    Start-Service -DisplayName $Service

                    # Pause for 20 seconds to give the service time to start
                    Start-Sleep -Seconds 20

                    # Get the status of the service
                    $ServiceStatus = (Get-Service -DisplayName $Service | Select-Object -ExpandProperty Status)

                    if ($ServiceStatus -ne "Running") { # If the service still isn't running - log an error
                        Write-DCTestLog -logText "$Service failed to start and is currently $ServiceStatus with a Startup Type as $ServiceStartType" -fail
                    }

                    else { # The service has now started - don't log an error
                        Write-DCTestLog -logText "$Service has now started with a Startup Type as $ServiceStartType" -pass
                    }

                }

                else { # The service isn't running as it is disabled - don't log an error
                    Write-DCTestLog -logText "$Service is currently disabled" -info
                }

            }

            else  { # The service must be running - don't log an error
                Write-DCTestLog -logText "$Service is running with a Startup Type as $ServiceStartType" -pass
            }

        }

        else { # The service isn't installed on the server (i.e. 'DHCP Server') - don't log an error
            Write-DCTestLog -logText "$Service is not installed as a service on this system" -info
        }

    }

    [System.Console]::Clear()

}

##-END-## -  SERVICE CHECK MODULE

##-START-## - ACTIVE DIRECTORY CHECK MODULE - Checking AD Communication etc.

function checkDCConnectivity{

Write-Host @"

    Performing Active-Directory FSMO connectivity checks...

"@

    if ($PSVersionTable.PSVersion.Major -gt 2) { # Only run if PowerShell is running a verion greater than 2 as some CMDLETS are not compatible with older versions

        # Check whether the ActiveDirectory PowerShell module is installed to prevent the script failing on older DCs

        Write-DCTestLog -logText "Importing Acive Directory Module..." -info

        if (Get-Module -ListAvailable -Name ActiveDirectory -ErrorAction SilentlyContinue) { # If the AD module is present, import it and set the $ADModuleInstalled variable to $true to ensure the function continues to run

            # Set the variable
            $ADModuleInstalled = $true

            # Import the ActiveDirectory Module
            Import-Module ActiveDirectory
            
            Write-DCTestLog -logText "Active Directory Module has been imported" -pass

        } 

        else { # If the AD module is NOT present, don't try to import it and set $ADModuleInstalled variable to $false to end the function

            # Set the variable
            $ADModuleInstalled = $false

            Write-DCTestLog -logText "Active Directory Module is not available so some tests may not run!" -warn

        }

        ##-END-## -  AD MODULE CHECK

        if ($ADModuleInstalled) { # If the AD module was previously detected - continue the check
        
            # Create an array of FSMO roles and who the masters are.
            $FSMOHolders = @(("InfrastructureMaster", (Get-ADDomain | Select-Object -ExpandProperty InfrastructureMaster)),
            ("RIDMaster",(Get-ADDomain | Select-Object -ExpandProperty RIDMaster)),
            ("PDCEmulator",(Get-ADDomain | Select-Object -ExpandProperty PDCEmulator)),
            ("DomainNamingMaster",(Get-ADForest | Select-Object -ExpandProperty DomainNamingMaster)),
            ("SchemaMaster",(Get-ADForest | Select-Object -ExpandProperty SchemaMaster)))

            $counter = 0
            foreach ($FSMOHolder in $FSMOHolders) { # Check every FSMO role holder for connectivity. (If one DC holds more then one role, the test will repeat against the same target)

                # Split the role and holder into two variables
                $FSMORole,$FSMOHolder = $FSMOHolder.split(' ')

                $counter++
                Write-Progress -Activity 'DCDoctor Domain Controller Checks - Checking: FSMO Holder...' -CurrentOperation $FSMOHolder -PercentComplete (($counter / $FSMOHolders.count) * 100)
    
                Write-DCTestLog -logText "Checking $FSMORole - $FSMOHolder" -info

                if (Test-Connection $FSMOHolder -Count 2 -ErrorAction SilentlyContinue) { # Connectivity was a success - don't log an error
                    Write-DCTestLog -logText "The $FSMORole $FSMOHolder is available" -pass
                }

                else { # Failed to connect - log an error
                    Write-DCTestLog -logText "The $FSMORole $FSMOHolder is NOT available!" -fail
                }

            }

Write-Host @"

Performing Domain Controller connectivity and SYSVOL/NETLOGON share checks...

"@

            # Get a list of all listed Domain Controllers in the domain
            $domainControllers = (Get-ADDomainController -Filter "isGlobalCatalog -eq `$true")

            $counter = 0
            foreach ($DomainController in $DomainControllers) { # Loop through every domain controller
                $counter++
                Write-Progress -Activity 'DCDoctor Domain Controller Checks - Checking: Domain Controller Connectivity...' -Status "Domain Controller (Domain Controller $($counter) of $($DomainControllers.count)" -CurrentOperation $DomainController -PercentComplete (($counter / $DomainControllers.count) * 100)
                Write-DCTestLog -logText "Checking connection to domain controller $DomainController" -info
                
                if (Test-Connection $DomainController -Count 2 -ErrorAction SilentlyContinue) { # If the domain controller is available - check SYSVOL and NETLOGON shares

                    Write-DCTestLog -logText "Domain Controller $DomainController is available" -pass

                    # SYSVOL Path
                    $SYSVOL = "\\$DomainController\SYSVOL"

                    if (Test-Path -Path $SYSVOL -ErrorAction SilentlyContinue) { # Connected to the SYSVOL directory correctly - don't log an error
                        Write-DCTestLog -logText "$SYSVOL is available on $DomainController" -pass
                    }
                    else { # SYSVOL is unavailable - log an error
                        Write-DCTestLog -logText "$SYSVOL is NOT available on $DomainController!" -fail
                    }

                    # NETLOGON Path
                    $NETLOGON = "\\$DomainController\NETLOGON"
                    
                    if (Test-Path -Path $NETLOGON -ErrorAction SilentlyContinue) { # Connected to the NETLOGON directory correctly - don't log an error
                        Write-DCTestLog -logText "$NETLOGON is available on $DomainController" -pass
                    }
                    else { # NETLOGON is unavailable - log an error
                        Write-DCTestLog -logText "$NETLOGON is NOT available on $DomainController!" -fail
                    }
                
                }
                
                else { # Domain controller listed is unavailable - log an error
                    Write-DCTestLog -logText "Partner Active Directory Domain Controller $DomainController is NOT available!" -fail
                }

            }

            [System.Console]::Clear()

        }

        [System.Console]::Clear()

    }

}

##-END-## -  ACTIVE DIRECTORY CHECK MODULE

##-START-## - EVENT VIEWER CHECKS - Checking for error codes and resolutions in Event Viewer

function checkEventViewer {

    <#
    Error List (Type, Error, Resolution ID)

    The sources are shortend for ease of typing.

    Currently the tested Sources are AD, DFS, DNS, DHCP

    You need the following three pieces of information: Source, Error ID, Resolutioun ID
    
    i.e.:

    Source:              "DNS"
    Error:               1234
    ResolutionCode:      9876

    ...would become

    ("DNS",1234,9876)
    #>

    # Multi-dimensional aray of locations, error codes and resolution codes
    $Errorlist = @("DFS",1202,1206),
    ("DFS",4614,4604),
    ("DFS",6016,6018),
    ("DFS",6104,6102),
    ("DFS",5008,5004),
    # To review - causing endless isues on single DCs ("DFS",4012,4602),
    # To review - check success code is correct!!    ("DFS",5014,5004),
    # To review - check success code is correct!!    ("AD",1311,1394),
    ("DNS",4013,2)

Write-Host @"

    Performing Event Viewer checks...

"@

    $counter = 0
    foreach ($Error in $Errorlist) { # Loop through errors in the array
        $counter++
        Write-Progress -Activity 'DCDoctor Domain Controller Checks - Checking: Event Log Errors...' -CurrentOperation $Error[1] -PercentComplete (($counter / $ErrorList.count) * 100)

        # Expand the shortcuts above into full names
        if ($error[0] -eq "AD") {$LogName = "Directory Service"}
        if ($error[0] -eq "DFS") {$LogName = "DFS Replication"}
        if ($error[0] -eq "DNS") {$LogName = "DNS Server"}
        if ($error[0] -eq "DHCP") {$LogName = "DHCP Server"}

        $failureErrorID = $error[1]
        $resolutionID = $error[2]

        # Skip some error checks for single domain controller scenarios. One skip per line, add multiple lines if required.
        # i.e for event ID 9999
        # if (($failureErrorID -eq 9999) -And ($domainControllers | Measure-Object).Count -eq 1) { continue 
        if (($failureErrorID -eq 4012) -And ($domainControllers | Measure-Object).Count -eq 1) { continue }

        if (Get-WinEvent -FilterHashtable @{Logname=$LogName;ID=$failureErrorID} -ErrorAction SilentlyContinue) { # There is an event present - check whether it has since cleared

            # Date of last error message, converted to UK date format...
            $errorDate = (Get-WinEvent -FilterHashtable @{Logname=$LogName;ID=$failureErrorID} -MaxEvents 1 | Select-Object -ExpandProperty TimeCreated)
            $errorDateString = $errorDate.ToString("dd MMMM yyyy - hh:mm:ss")

            # Get the contents of the error message
            $errorDescription = (Get-WinEvent -FilterHashtable @{Logname=$LogName;ID=$failureErrorID} -MaxEvents 1 | Select-Object -ExpandProperty Message)

            Write-DCTestLog -logText "$LogName Error $failureErrorID Occurred on $errorDateString" -info

            Write-DCTestLog -logText "$errorDescription" -plain
                   
            if (Get-WinEvent -FilterHashtable @{Logname=$LogName;ID=$resolutionID} -MaxEvents 1 -ErrorAction SilentlyContinue) { # The event has been cleared at least once (Don't know when though)

                # Get the date the error was resolved, converted to UK date format...
                $resolutionDate = (Get-WinEvent -FilterHashtable @{Logname=$LogName;ID=$resolutionID} -MaxEvents 1 | Select-Object -ExpandProperty TimeCreated)
                $resolutionDateString = $resolutionDate.ToString("dd MMMM yyyy - hh:mm:ss")

                # Get the content of the resolution message
                $resolutionDescription = (Get-WinEvent -FilterHashtable @{Logname=$LogName;ID=$resolutionID} -MaxEvents 1 | Select-Object -ExpandProperty Message)

                if ($resolutionDate -gt $errorDate) { # The resolution was after the latest error and has therefore cleared - don't log an error

                    Write-DCTestLog -logText "$LogName Resolution Event ID $resolutionID Occurred on $resolutionDateString" -pass

                    Write-DCTestLog -logText "$resolutionDescription" -plain

                }

                else { # There was a resolution as determined by this "if" - however it was before the error re-appeared - log an error

                    Write-DCTestLog -logText "$LogName Error $failureErrorID has re-ocurred since it was last rectified on $resolutionDateString and is still in an errored state!" -fail

                    Write-DCTestLog -logText "$errorDescription" -plain
                    
                }

            }

            else { # Because there is no resolution ID available - the error must still be and always has been present - log an error

                Write-DCTestLog -logText "$LogName Error $failureErrorID has never been rectified!" -fail

                Write-DCTestLog -logText "$errorDescription" -plain
                
            }

        }

        [System.Console]::Clear()

    }

}

##-END-## -  EVENT VIEWER CHECKS 

# Call the individual functions defined above
checkServices
[System.Console]::Clear()
checkDCConnectivity
[System.Console]::Clear()
checkEventViewer
[System.Console]::Clear()

##-START-## - E-MAIL

if (Test-Path $ErrorLogFile) { # If the error log file exists, send E-Mail if configured

    [System.Console]::Clear()

    if ($sendMailReport -eq "YES") { # E-Mail Reporting enabled
 
        $subject = "DCDoctor Failure for $env:COMPUTERNAME.$env:USERDNSDOMAIN on $date" # E-Mail Subject
 
        $eMailBody = "Dear User,<br /><br />Please note, <b>$env:COMPUTERNAME.$env:USERDNSDOMAIN</b> has failed the DCDoctor tests on $date.<br /><br />Please see attached a summary of the errors.<br /><br />Regards,<br />DCDoctor<br /><br />"
 
        Write-DCTestLog -logText "Sending E-Mail Message..." -info

        # Try to send E-Mail and alert on failure...
        $smtpSecurePassword = ConvertTo-SecureString $smtpPassword -AsPlainText -Force
        $smtpCredentials = New-Object System.Management.Automation.PSCredential ($smtpUsername, $smtpSecurePassword)
        try { Send-MailMessage -To $sendMailTo -From $sendMailFrom -Subject $subject -Body $eMailBody -SmtpServer $smtpServer -Port $smtpServerPort -Credential $smtpCredentials -Priority High -Attachments $ErrorLogFile -BodyAsHtml -ErrorAction Stop }
        catch {
            $eMailError = $_
            Write-DCTestLog -logText "Failed to send E-Mail (ERROR: $eMailError)!" -eMailfail

            Write-Host @"

ERROR SENDING E-MAIL!!

Please check $eMailErrorLogFile for more information...

"@ -ForegroundColor Yellow -BackgroundColor Red

            Start-Sleep -Seconds 5

            [System.Console]::Clear()
            
        }
    
    }

}

##-END-## -  E-MAIL

# Complete and end script
$date = (Get-Date -Format "dd/MM/yyy HH:mm:ss")
Write-DCTestLog -logText "Completed test on $date" -plain
[System.Console]::Clear()
Write-Host @"

Completed test on $date

$logo
"@
