#!/bin/bash

#title          :log-analyzer.sh
#description    :This script will allow us to gather data from multiple appserver in MH environments. Was based on automator.sh
#author         :Sergio Guzman @ sergio.guzman@blackboard.com
#date           :2019-11-13
#usage          :./log-analyzer.sh       
#=================================================================================================

#Font styles
bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)

#checks is it is being run from a writeable location
cwd=`pwd`
if [ ! -w "$cwd" ]; 
    then
      echo "${red}${bold}Error:${normal} Current Directory is not writeable by you."
      exit 0
fi

#Get the username for this session
read -p "Please provide your ${red}${bold}AD username:${normal}" vUSER
read -p "Please provide your ${red}${bold}AD password:${normal}" vPASS

#Specifies the name of the file that we will use along with a date variable
vFILENAME='clientenv_report.txt'
declare -a vDATERANGE=()
echo
echo "${green}${bold}We are downloading the client list to work on, please provide a second."

#Once the user exists the application it will remove the cookie created and the file with the MH data
function trap2exit (){
    echo "\n${normal}Exiting...";
    if [[ -f $vFILENAME ]]; 
    then
    rm -rf $vFILENAME 
    fi
exit 0;
}

trap trap2exit SIGHUP SIGINT SIGTERM

# Download file from opsmart
echo "${green}We will download the Client Database file into a temporal location...${normal}"
wget --post-data 'ExportReportsToCsv=Export+to+CSV'  https://opsmart.blackboard.com/reports/webtech/webtech_clientenv_report.php
mv webtech_clientenv_report.php clientenv_report.txt
echo
echo ">>> ${green}File downloaded ...${normal}"
echo

# Security Loop
# Input Client and environment and outputs the list of VIP.
# If nothing is found then ask again.
until ((0));
do
    # Ask for Client Name
    read -p "${normal}What ${red}client${normal}  do you want to work on: ${bold}" vCLIENTNAME
    # Ask for Environment type (Production or Staging or Test)
    read -p "${normal}What ${red}environment${normal} do you want to work on (Production, Staging, Test...): ${bold}" vENVIRONMENT
    echo "${normal}"
    #Takes the VIP ip of the client   
    vOPTIONS=($(cat $vFILENAME | grep --color=auto -i "$vCLIENTNAME" | grep --color=auto -i $vENVIRONMENT | awk 'BEGIN { FS = "," }; {print $13}'| grep --color=auto -iv "db0" | sed 's/"//g' | sort | uniq))

    if [ ${#vOPTIONS[@]} -eq 0 ]; 
    then
        echo "${normal} -------------------------------------------------------------------------------------"
        echo "${bold}${red}ERROR:${normal} We could not found any information with your parameters, please try again."
        echo "-------------------------------------------------------------------------------------"
        echo
        else
        echo "${green}We found this VIP: ${normal}"
        vCOUNTER=0
            for i in "${vOPTIONS[@]}"
                do
                  echo "$vCOUNTER) $i"
                  vCOUNTER=$[$vCOUNTER +1]
                done
            echo
            break
    fi
done

# Ask to select one of the options above
until ((0));
    do
    # Ask to select one of the options above
    read -p "Input the above ${red}id number${normal} you want to work on: ${bold}" vARRAYID
    # Set the WorkingVIP
    vWORKINGVIP=${vOPTIONS[$vARRAYID]}

    if  [[ "$vWORKINGVIP" == "" ]]; 
    then
        echo "${normal} -------------------------------------------------------------------------------------"
        echo "${bold}${red}ERROR:${normal} Invalid option, please try again."
        echo "-------------------------------------------------------------------------------------"
        echo
        else
        break
    fi
    done

#Create a list of the app servers and IP.
vAPPS=($(grep --color=auto -i "$vCLIENTNAME" $vFILENAME | grep --color=auto -i $vENVIRONMENT | grep --color=auto -i $vWORKINGVIP | awk 'BEGIN { FS=","}; {print $14}' | grep --color=auto -iv "db0" | sed 's/"//g' | sort | uniq))

#Create an array with the IPs of the app servers
declare -a vAPPSIP=()
for eachapp in "${vAPPS[@]}"; 
    do
        tempip=$(grep --color=auto "$eachapp" clientenv_report.txt | awk 'BEGIN { FS=","}; {print $11}' | sed 's/"//g' | sort | uniq)
        vAPPSIP+=($tempip)
    done

# deleting the file so we are always up to date
rm -rf $vFILENAME

echo "${normal}We found the following Apps to work based on your input: "
vCOUNTER=1
for servername in "${vAPPS[@]}"; 
    do
        echo "$vCOUNTER) $servername"
        vCOUNTER=$[$vCOUNTER +1]
    done
echo
echo "${bold}NOTE: ${normal}If the above is not correct, please CTRL+C to exit the app and restart it."
echo 

# this outer check is to validate if the start date is lower than the end date
until ((0)); 
    do
    # Ask for Start date
        until ((0)); 
            do
            read -p "Input the ${red}Start Date${normal} you want to search (YYYY-MM-DD) (e.g: lower than end date): ${bold}" vSTARTDATE
            echo "${normal}"
                if [[ $vSTARTDATE =~ ^[0-9]{4}-(0[0-9]|1[0-2])-([0-2][0-9]|3[0-1])$ ]]; 
                then
                  break
                else
                  echo "${normal} -------------------------------------------------------------------------------------"
                  echo "${bold}${red}ERROR:${normal} Invalid Start date, please try again."
                  echo "-------------------------------------------------------------------------------------"
                  echo
                fi
            done
        # Ask for End date
        until ((0)); 
            do
            read -p "Input the ${red}End Date${normal} you want to search (YYYY-MM-DD) (e.g: higher than start date): ${bold}" vENDDATE
            echo "${normal}"
                if [[ $vENDDATE =~ ^[0-9]{4}-(0[0-9]|1[0-2])-([0-2][0-9]|3[0-1])$ ]]; 
                then
                  break
                else
                  echo "${normal} -------------------------------------------------------------------------------------"
                  echo "${bold}${red}ERROR:${normal} Invalid End date, please try again."
                  echo "-------------------------------------------------------------------------------------"
                  echo
                fi
            done
        # check if start date is lower than end date
        if [[ "$vSTARTDATE" > "$vENDDATE" ]]; 
        then
            echo "${normal} -------------------------------------------------------------------------------------"
            echo "${bold}${red}ERROR:${normal} Start Date is higher than End Date"
            echo "-------------------------------------------------------------------------------------"
            echo
            else
            break
        fi
    done

# Create Date Ranges
if date -v 1d > /dev/null 2>&1; 
then
    currentDateTs=$(date -j -f "%Y-%m-%d" $vSTARTDATE "+%s")
    endDateTs=$(date -j -f "%Y-%m-%d" $vENDDATE "+%s")
    offset=86400

    while [ "$currentDateTs" -le "$endDateTs" ]
        do
        date=$(date -j -f "%s" $currentDateTs "+%Y-%m-%d")
        datearrange+=($date)
        currentDateTs=$(($currentDateTs+$offset))
        done
else
    d=$vSTARTDATE
    while [ "$d" != "$vENDDATE" ]; 
        do
        datearrange+=($d)
        d=$(date -I -d "$d + 1 day")
        done
    datearrange+=($vENDDATE)
fi

until ((0));
	do
		#Print the list of possible tasks
		echo "${bold}Possible tasks${bold}"
		echo
		echo -e "${bold}${red}1) ${bold}${normal}Download all the Access-logs \n${bold}${red}2) ${bold}${normal}Perform a search in the Access-logs \n${bold}${red}3) ${bold}${normal}Perform a search in all the bb-services-logs"
		echo
		read -p "${bold}Input the above ${red}id number from the task that you want to perform: ${bold}${normal} " vCHOICE
		echo
		#Checks for a valid answer
		if [ "$vCHOICE" -eq 1 ] || [ "$vCHOICE" -eq 2 ] || [ "$vCHOICE" -eq 3 ];
		then
			break
		        else
			echo "${normal} -------------------------------------------------------------------------------------"
                        echo "${bold}${red}ERROR:${normal} Invalid option, please try again."
                        echo "-------------------------------------------------------------------------------------"
                        echo
    		fi
	done
	
currentDate=`date +%Y-%m-%d-%k_%M_%S`

if [ $vCHOICE -eq 1 ]
then
    # Create a header for easy replication
    echo "=============================================================================="
    echo 
    echo "User: $vUSER" 
    echo "Client Name: $vCLIENTNAME" 
    echo "Client Environment: $vENVIRONMENT" 
    echo "Start Date: $vSTARTDATE" 
    echo "End Date: $vENDDATE" 
    echo 
    echo "==============================================================================" 
    echo 
    # Connect to server
    echo
    vCOUNTER=0
    for ip in "${vAPPSIP[@]}"; 
        do
        echo "Connecting to ${vAPPS[$vCOUNTER]}"
        for day in "${datearrange[@]}"; 
            do
              sshpass -p $vPASS scp -pqo StrictHostKeyChecking=no $vUSER@$ip:/usr/local/blackboard/logs/tomcat/bb-access-log.$day.txt ./client-reports/ 2>>./script-logs/error-logs.txt
              sshpass -p $vPASS scp -pqo StrictHostKeyChecking=no $vUSER@$ip:/usr/local/blackboard/asp/${vAPPS[$vCOUNTER]}/tomcat/bb-access-log.$day.txt.gz ./client-reports/ 2>>./script-logs/error-logs.txt
            done
        echo "Disconnecting from ${vAPPS[$vCOUNTER]}"
        echo ""
        vCOUNTER=$[$vCOUNTER+1]
        done
elif [ $vCHOICE -eq 2 ]
then
    filename="access-logs-search-$vUSER-$vCLIENTNAME-$currentDate.log"
    read -p "Input the ${red}Information String${normal} you want to search (wrap in double quotes if using special characters): ${bold}" vSTRINGSEARCH
    echo "${normal}"
    # Create a header for easy replication
    echo "==============================================================================" 
    echo 
    echo "User: $vUSER" 
    echo "Client Name: $vCLIENTNAME" 
    echo "Client Environment: $vENVIRONMENT" 
    echo "Start Date: $vSTARTDATE" 
    echo "End Date: $vENDDATE" 
    echo "Search String: $vSTRINGSEARCH" 
    echo
    echo "==============================================================================" 
    echo 
    # Create a header for the file
    echo "==============================================================================" >> ./client-reports/"$filename"
    echo >> ./client-reports/"$filename"
    echo "User: $vUSER" >> ./client-reports/"$filename"
    echo "Client Name: $vCLIENTNAME" >> ./client-reports/"$filename"
    echo "Client Environment: $vENVIRONMENT" >> ./client-reports/"$filename"
    echo "Start Date: $vSTARTDATE" >> ./client-reports/"$filename"
    echo "End Date: $vENDDATE" >> ./client-reports/"$filename"
    echo "Search String: $vSTRINGSEARCH" >> ./client-reports/"$filename"
    echo >> ./client-reports/"$filename"
    echo "==============================================================================" >> ./client-reports/"$filename"
    echo >> ./client-reports/"$filename"
    # Connect to server
    echo
    vCOUNTER=0
    for ip in "${vAPPSIP[@]}"; 
        do
        echo "Connecting to ${vAPPS[$vCOUNTER]}"
        echo "Connecting to ${vAPPS[$vCOUNTER]}" >> ./client-reports/"$filename"
        echo >> ./client-reports/"$filename"
        for day in "${datearrange[@]}"; 
            do
                sshpass -p $vPASS ssh -o StrictHostKeyChecking=no $vUSER@$ip grep --color=auto -iH $vSTRINGSEARCH /usr/local/blackboard/logs/tomcat/bb-access-log.$day.txt >> ./client-reports/"$filename" 2>>./script-logs/error-logs.txt
                sshpass -p $vPASS ssh -o StrictHostKeyChecking=no $vUSER@$ip zgrep --color=auto $vSTRINGSEARCH /usr/local/blackboard/asp/${vAPPS[$vCOUNTER]}/tomcat/bb-access-log.$day.txt.gz >> ./client-reports/"$filename" 2>>./script-logs/error-logs.txt
            done
        echo "Disconnecting from ${vAPPS[$vCOUNTER]}"
        echo >> ./client-reports/"$filename"
        echo "Disconnecting from ${vAPPS[$vCOUNTER]}" >> ./client-reports/"$filename"
        echo >> ./client-reports/"$filename"
        echo ""
        vCOUNTER=$[$vCOUNTER+1]
        done
elif [ $vCHOICE -eq 3 ]
then
    filename="bb-services-search-$vUSER-$vCLIENTNAME-$currentDate.log"
    read -p "Input the ${red}Information String${normal} you want to search (wrap in double quotes if using special characters): ${bold}" vSTRINGSEARCH
    echo "${normal}"
    # Create a header for easy replication
    echo "==============================================================================" 
    echo
    echo "User: $vUSER" 
    echo "Client Name: $vCLIENTNAME" 
    echo "Client Environment: $vENVIRONMENT"
    echo "Start Date: $vSTARTDATE" 
    echo "End Date: $vENDDATE" 
    echo "Search String: $vSTRINGSEARCH" 
    echo 
    echo "==============================================================================" 
    echo 
    # Create a header for the file
    echo "==============================================================================" >> ./client-reports/"$filename"
    echo >> ./client-reports/"$filename"
    echo "User: $vUSER" >> ./client-reports/"$filename"
    echo "Client Name: $vCLIENTNAME" >> ./client-reports/"$filename"
    echo "Client Environment: $vENVIRONMENT" >> ./client-reports/"$filename"
    echo "Start Date: $vSTARTDATE" >> ./client-reports/"$filename"
    echo "End Date: $vENDDATE" >> ./client-reports/"$filename"
    echo "Search String: $vSTRINGSEARCH" >> ./client-reports/"$filename"
    echo >> ./client-reports/"$filename"
    echo "==============================================================================" >> ./client-reports/"$filename"
    echo >> ./client-reports/"$filename"
    # Connect to server
    echo
    vCOUNTER=0
    for ip in "${vAPPSIP[@]}"; 
        do
        echo "Connecting to ${vAPPS[$vCOUNTER]}"
        echo "Connecting to ${vAPPS[$vCOUNTER]}" >> ./client-reports/"$filename"
        echo >> ./client-reports/"$filename"
        for day in "${datearrange[@]}"; 
            do
                sshpass -p $vPASS ssh -o StrictHostKeyChecking=no $vUSER@$ip grep --color=auto -iA 1000 $vSTRINGSEARCH /usr/local/blackboard/logs/bb-services-log.$day.txt >> ./client-reports/"$filename" 2>>./script-logs/error-logs.txt
                sshpass -p $vPASS ssh -o StrictHostKeyChecking=no $vUSER@$ip grep --color=auto -iA 1000 $vSTRINGSEARCH /usr/local/blackboard/logs/bb-services-log.txt >> ./client-reports/"$filename" 2>>./script-logs/error-logs.txt
            done
        echo "Disconnecting from ${vAPPS[$vCOUNTER]}"
        echo >> ./client-reports/"$filename"
        echo "Disconnecting from ${vAPPS[$vCOUNTER]}" >> ./client-reports/"$filename"
        echo >> ./client-reports/"$filename"
        echo ""
        vCOUNTER=$[$vCOUNTER+1]
        done
else
  #invalid choice
  echo "${red}${bold}Invalid Input ${normal}"
  echo "${red}${bold}Task canceled ${normal}"
fi
