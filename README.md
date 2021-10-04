# **DCDoctor**

DCDoctor is designed to be run automatically as a scheduled task on Domain Controllers to check their integrity and log any detected issues, however can also be run in an Administrative PowerShell Window to achieve the same results.
The script will always create a log file, however if it finds any errors or issues - it will create an error log and E-Mail to the user explaining the problem (if configured).
DCDoctor requires PowerShell v2.0 however for best results - please ensure you are using at least PowerShell v5.0 as some checks will be skipped on older versions.

## Installation Guide:

1) Clone the repository to a location on your Domain Controller. For the purpose of this guide, it will be ***C:\DCDoctor***.
2) The script will log everything to the same location as the script, in a subfolder called "Logs" (i.e. ***C:\DCDoctor\Logs***)
3) To bypass servers, rename the ***DCDoctor_Settings.conf.example*** file to ***DCDoctor_Settings.conf*** (if it does not already exist) and set the following:
*  excludedServers=SERVER1,SERVER2,SERVER3
4) To enable E-Mail reporting, open the ***DCDoctor_Settings.conf*** file, locate and set to look like the following:
*  sendMailReport=YES
*  to=username@example.com
*  from=noreply@example.com
*  smtpServer=smtp.server.com
*  smtpServerPort=587
5) To disable E-Mail reporting (default), set ***sendMailReport*** to ***NO*** or leave blank (i.e. ***sendMailReport=No*** or ***sendMailReport=***)
6) Create a Scheduled Task to run at 1am every day, you can import the ***DCDoctor_ScheduledTask.xml*** file into the Windows Task Scheduler.
7) This assumes the script is in the ***C:\DCDoctor*** directory, however you can edit the task afterwards to suit your needs (script location and time etc.)
8) You should see a text file named ***C:\DCDoctor\Logs\DCDcotor_Results.txt*** file with an output of the test results.
9) If there are any errors, there will be a ***C:\DCDoctor\Logs\DCDoctor_Error.txt*** explaining any issues (and an E-Mail containing a copy of this file).


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
