#!/bin/bash

#
# Linux time synchronization script Version 2
# current supports Ubuntu, Debian, CentOS, RedHat, OpenSuse
# Improvements
# - verifies if chrony exists on the computer
# - error handling, logging
# - generic functions
# --- to verify command exists runs on all distros
# --- to install packages on all distros
#    


#********************************************************************************
# Local variables section
#********************************************************************************
_date_time=$(date)


#********************************************************************************
# All the functions are in this section 
#********************************************************************************

# This script checks if the Linux distros has default ntp /timezone then it updates them
# simply add the timezone you prefer in the array below, and it will be added to the chrony.conf file
# for this example we use TC Active directory time, and Natural Resources Canada time

#********************************************************************************
# logging all the steps

# exec 3>&1 4>&2 
# Saves file descriptors so they can be restored to whatever they were before redirection or used themselves to output 
# to whatever they were before the following redirect.

# trap 'exec 2>&4 1>&3' 0 1 2 3
# Restore file descriptors for particular signals. Not generally necessary since they should be restored when the sub-shell exits.

# exec 1>log.out 2>&1
# Redirect stdout to file log.out then redirect stderr to stdout. Note that the order is important when you want them going to the same file. 
# stdout must be redirected before stderr is redirected to stdout.

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3 
exec 1>>timeLog.txt 2>&1

# Generic function to all Distros to install a package
installPackage()
{  
    _writeLog=$_date_time'-------->'                                                               
    _writeLog='Installing package'

    _command=$1
    _package=$2

    # echo 'Install command received ' $_package $_package
    $_command install $_package                                                                    
    _install_code=$?

    # if install successful
    if [[ $_install_code = 0 ]]
    then
        
        echo 'Installation of ' $_package ', succeeded  '                                          
        # echo 'Install code = 0' $_install_code
        return $_install_code

    elif [[ $_install_code = 127 ]]
    then
        echo 'Package ' $_package ', already exists '                                              
        # echo 'Install code = 127' $_install_code
        return $_install_code

    else 
        echo 'Installation of ' $_package ', failed '                                              
        # echo 'None of the numbers ' $_install_code
        return $_install_code

    fi # _install_code 

} #installPackage

#********************************************************************************
# For Ubuntu update the repos
# For CentOS/Rhel/openSuse don't update, only install
# if distro type = centos/rhel/opensuse-leap only install
# 
function updateRepos()
{
    echo $_date_time '--------> Updating Repositories  '                                                            
    
    _package=$1
    _distro_type=$2

    # echo 'Command sent to this function ' 
    # echo 'package name:' $_package ', distro type: ' $_distro_type

    if [[ $_distro_type = @(ubuntu) ]]
    then
        _command="apt-get -y"
        $_command update                                                                                             
        
        # grab the command result
        _update_code=$?

        # if update successful 
        if [[ $_update_code = 0 ]]
        then
            # then call install function
            # echo 'Calling install function '
            # _command="apt-get -y"
            
            installPackage "$_command" $_package
            _install_code=$?
            # echo 'Response back from install package function ' $_install_code

        # if first time installation failed then install the dependencies
            if [[ $_install_code -ne 0 ]]
            then
                echo 'Installing dependencies for ' $_package                                                        
                $_command install -f
                _install_code=$?

                if [[ $_install_code -ne 0 ]]
                then 
                    echo 'Installing of dependencies for ' $_package ' failed! '                                     
                    return $_install_code

                else
                    echo 'Installing of dependencies for ' $_package ' succeeded! '                                  
                    return $_install_code

                fi # if dependencies failed
            fi

            
        fi # update

    # if distro = CentOS/RedHat 
    elif [[ $_distro_type = @(centos|rhel) ]] 
    then
        
        # echo 'Your distro is ' $_distro_type
        # echo 'Call the install function '    
        _command="yum -y"
        installPackage "$_command" $_package
        _update_code=$?

        # echo $_update_code
        return $_install_code
        
    # if distro = opensuse-leap 
    elif [[ $_distro_type = @(opensuse-leap) ]] 
    then
        echo 'Distro is ' $_distro_type
        # echo 'Call the install function '    
        _command="zypper -n"
        installPackage "$_command" $_package
        _update_code=$?

        # echo $_update_code
        return $_install_code

    fi # distro
                                                             
    # echo $_update_code
    return $_install_code

} # updateRepos

#********************************************************************************
# Applies to all distros
setTimezoneEnableChrony()
{
    _distro_type=$1
    # set the time zone 
    echo 'Setting the new timezone'                                                                                                 
    timedatectl set-timezone America/Toronto                                                                                        
   
    if [[ $_distro_type = @(ubuntu) ]]
    then 
            # Ubuntu uses chrony instead of chronyd'                                                                           
            echo 'Enabling chrony'                                                                                                  
            systemctl enable chrony                                                                                                 
            
            echo 'Restarting chrony'                                                                                                
            systemctl restart chrony                                                                                                 
    else
            echo 'Enabling chronyd'                                                                                                 
            systemctl enable chronyd                                                                                                
            
            echo 'Restarting chronyd'                                                                                               
            systemctl restart chronyd                                                                                                 
    fi
          
  
} # setTimezoneEnableChrony


#********************************************************************************

# find the old time zone info 
findOldTimeReplaceNewTime()
{
    _chronyFilePath=$1
    _distro_type=$2
    # echo 'Chrony is located at ' $chronyFilePath

    preferredTimeZone=()
    # change these values to your preferred time zone 
    # I am using pool time.nrc.ca iburst, and pool time.chu.nrc.ca iburst
    preferredTimeZone+=('pool time.nrc.ca iburst')
    preferredTimeZone+=('pool time.chu.nrc.ca iburst')

    
    # if pool is used, then write them in temp file oldTimeZoneList
    awk '/pool[ ]/{print $N}' $_chronyFilePath   > oldTimeZoneList.txt
    # remove the hash tags
    sed -E -i "s/#pool|#\spool/pool/"              oldTimeZoneList.txt
    
    # in some cases CentOS/Redhat/openSuse used server, then write them in temp file oldTimeZoneList
    awk '/server[ ]/{print $N}' $_chronyFilePath >> oldTimeZoneList.txt
    # remove the hash tags
    sed -E -i "s/#server|#\sserver/server/"        oldTimeZoneList.txt

 
    # read the file into an array 
    readarray -t oldTimeZoneArray < "oldTimeZoneList.txt"
    counter=0

# loop through the oldTimeZoneArray 
for eachOldRecord in "${oldTimeZoneArray[@]}"; do
    
    # loop through the preferredTimeZone
    for eachNewRecord in "${preferredTimeZone[@]}"; do 

        # check if eachOldRecord in oldTimeZoneArray matches a line in preferredTimeZone

        if [ "$eachOldRecord" = "$eachNewRecord" ]; then
            
            # if one or 4 record matches, then increment the counter
            
            ((counter++))
                # when counter <= preferredTimeZone array length then exit, dont' modify the file
                if [ "$counter" -le ${#preferredTimeZone[@]} ]; then
                    echo 'Match found! no changes made to the conf file' $eachOldRecord                                 
                    
                fi

        # if eachOldRecord in oldTimeZoneArray is not equal to the preferredTimeZone 
        elif [ "$eachOldRecord" != "$eachNewRecord" ]; then
            ((counter+=1)) 
              counter2=0
              # get the lenghts of both arrays
              lengthOfPreferredTimeZoneArray=${#preferredTimeZone[@]}
              lengthOfOldTimeZoneArray=${#oldTimeZoneArray[@]}
            
                # if counter = length of oldTimeZoneArray x length of preferredTimeZone; that means it went through all the record
                if [[ "$counter" ==  $(( lengthOfPreferredTimeZoneArray * lengthOfOldTimeZoneArray )) ]]; then
                    
                    # delete all the pool information using sed and write new line, then new records to the file
                    echo 'Deleting all the existing pool or server info '                                                                   
                    sed -i '/pool/d' $_chronyFilePath
                    sed -i '/server/d' $_chronyFilePath
                    echo -e "\n" >>  $_chronyFilePath
                    
                    echo 'Writing new pool info '                                                                                           
                    for newTimeZoneRecord in "${preferredTimeZone[@]}"; do 
                        echo $newTimeZoneRecord >> $_chronyFilePath
                        
                    done
                   
                fi      

        fi 
        
    done
    
done

} # findOldTimeReplaceNewTime()

#********************************************************************************

# Find out which distribution we are running on
function getDistributionName
{
    # awk offers to specify the field delimiter '=', $1=ID, we print $2
    withQuotes=$(awk -F'=' '$1 == "ID" {print $2}' /etc/os-release)

    # sed replaces a leading " with nothing, and a trailing " with nothing too. 
    # Using -e you can have multiple text processing).
    distributionName=$( sed -e 's/^"//' -e 's/"$//' <<< "$withQuotes" )

    echo $distributionName
    return 0
} # getDistributionName

#********************************************************************************

# check if a command is already installed 
function isPackageInstalled()
{
    _package=$1
    if ! command -v $_package &> /dev/null 
    then
        echo 'no'
        return 1
    else 
        echo 'yes'
        return 0
    fi

} # isPackageInstalled

#********************************************************************************
# main control section, function calling 

# local variables 
# get distro info

_distributionName=$(getDistributionName)
_message=''

# if distro is ubuntu, then update and install chrony
if [[ $_distributionName = @(ubuntu) ]]
then
        _distro_type=ubuntu
        _package=chrony

        echo ''   
        echo 'Your distro is: '$_distro_type  
        echo ''                                                                                     
        echo 'Checking if  chrony is installed on your distro '                                                                  
    
        _message=$(isPackageInstalled $_package)

        if [[ $_message = @(no)  ]]  
        then 
            # if chrony doesn't exist then 
            # call update function , update will call install function
            updateRepos $_package $_distro_type

        fi

        # make a back up of chrony
        cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.original                                                                 
        _chronyFilePath="/etc/chrony/chrony.conf"                                                                                   
        findOldTimeReplaceNewTime $_chronyFilePath                                                                                  
        
        # call common function for all distros to set timezone, enable, restart chrony
        setTimezoneEnableChrony $_distro_type

else # if distro = centos/rhel/opensuse-leap

    # call CentOS/RedHat

    # check if chrony is installed
    _package=chrony  

    echo '' 
    echo 'Checking if  chrony is installed on your distro '                                                                        
    
    _message=$(isPackageInstalled $_package)                                                                                       
    _distro_type=''

    if [[ $_distributionName = @(centos|rhel) ]]
    then  
        _distro_type=centos

        echo '' 
        echo 'Your distro is: '$_distro_type                                                                                       

        if [[ $_message = @(no)  ]]  
        then
            # call updateRepos, updateRepos will call install function if necessary   
            # echo 'updating repos' 
            updateRepos $_package $_distro_type                                 
            #echo 'command NOT installed'
        fi

    elif [[ $_distributionName = @(opensuse-leap) ]]
    then

        echo '' 
        echo 'Your distro is: '$_distro_type                                                                                      

        if [[ $_message = @(no)  ]]  
        then 
            _distro_type='opensuse-leap'
            # zypper -n install chrony
            updateRepos $_package $_distro_type   
            #echo 'command NOT installed'
        fi
    fi

    # make a back up of chrony
    echo 'Making a backup of chrony.conf '                                                                                     
    cp /etc/chrony.conf /etc/chrony.conf.original                                                                              
    chronyFilePath="/etc/chrony.conf"                                                                                          
    
    # cp chrony.txt chrony.txt.original                                                                                          
    # chronyFilePath="chrony.txt"                                                                                                

    echo 'Replaced old values in chrony.conf '                                                                                 
    findOldTimeReplaceNewTime $chronyFilePath                                                                                  

    # call common function for all distros to set timezone, enable, restart chrony
    echo 'Setting new timezone, enable chrony, restart chrony '                                                                
    setTimezoneEnableChrony $_distro_type

fi # if distro = centos/rhel/opensuse-leap
