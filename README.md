# log_analyzer script V 2.0
the idea of this script is to have a tool capable of pulling logs from multiple app servers at once. Currently it can download all the bb-access logs, perform greps on the access logs and bb-services. 
This can be improved or more options added based on feedback. I took some other scripts as a reference, since those scripts where outdated the creation of a new script was needed. Some features from those scripts were imported into this one.

## Summary
Since both tier 1 and tier 2 teams are constantly doing researching on MH environments, an automatted tool was necesary to imrove the efficiency of this process. 
This tool will automate the process of gathering logs by removing the need of loging into every single MH server to get the data. 

## Installation
The process is quite simple as you just need to download the folder into a linux machine. Since this is bash you will need aither a linux system or a mac. For windows users you can use the linux system that can be downloaded for windows systems. 
Once you have the folder, make sure that you grant full privileges to the script and then run ./log_analyzer 

## Deliverables
The folder has 2 subfolders called client-reports and script-logs. The result of the task you performed will be located at client-reports, while any error thrown by the search will be located at script-logs.

## Fixes in version 2.0
- Fixed an issue with mass downloads being overwriteen thus leaving only the last downloaded file.
- Added a better folder structure in order to organize the results in a more efficient way.
- Added a new option in which it is possible to download all bb-services-logs from all appservers.

## Example 

$ ./log-analyzer.sh
Please provide your AD username:*******
Please provide your AD password:*******

We are downloading the client list to work on, please provide a second.
We will download the Client Database file into a temporal location...
--2019-11-14 13:50:50--  **********
Resolving ******* (**********)... ******
Connecting to ********** (********)|********|:****... connected.
HTTP request sent, awaiting response... 200 OK
Length: 1200792 (1.1M) [application/csv]
Saving to: ‘*******.php’

******.php                                100%[========================================================================================================================================>]   1.14M  1018KB/s    in 1.2s

2019-11-14 13:50:53 (1018 KB/s) - ‘*********.php’ saved [1200792/1200792]


>>> File downloaded ...

What client  do you want to work on: ********
What environment do you want to work on (Production, Staging, Test...): Staging

We found this VIP:
0) ******

Input the above id number you want to work on: 0
We found the following Apps to work based on your input:
1) *******-app001
2) *******-app002

NOTE: If the above is not correct, please CTRL+C to exit the app and restart it.

Input the Start Date you want to search (YYYY-MM-DD) (e.g: lower than end date): 2019-11-14

Input the End Date you want to search (YYYY-MM-DD) (e.g: higher than start date): 2019-11-14

Possible tasks

1) Download all the Access-logs
2) Perform a search in the Access-logs
3)  Perform a search in all the bb-services-logs

Input the above id number from the task that you want to perform:  2

Input the Information String you want to search (wrap in double quotes if using special characters): "1_1"

==============================================================================

User: *******
Client Name: *********
Client Environment: Staging
Start Date: 2019-11-14
End Date: 2019-11-14
Search String: "1_1"

==============================================================================


Connecting to *******-app001
Disconnecting *******-app001

Connecting to *******-app002
Disconnecting *******-app002
