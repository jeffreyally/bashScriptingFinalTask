#!/usr/bin/bash

# Udemy course can be found here: https://www.udemy.com/course/linux-shell-scripting-projects/?couponCode=ST9MT22024
# The course had the learner download vagrant and spin up virtual machines with CentOS 7 as the OS
# The goal of the final project for the course was to create a bash script that allowed a user to execute one or multiple
# commands on remote servers without having to manually SSH into each one individually.

# e.g. Instead of having to SSH into 25 servers manually and running the command "sudo yum update" on each one imagine
# running this script and passing in a list of servers along with the "sudo yum update" command once and having that 
# command run on each server one by one

FILEPATH="/vagrant/servers"
DRYRUN=""
SUDO=""
VERBOSE=""

# function below is called when the script is called incorrectly and without proper arguments and flags
function usage(){

 echo "USAGE ${0} [-nsv] [-f FILEPATH] COMMAND(S)"
 echo "Executes command passed in on every server in list of servers. Default path is: ${FILEPATH}"
 echo "-f FILE Overwrites default filepath here: ${FILEPATH} to new list of servers to execute command(s) on"
 echo "-n DRY RUN Displays command(s) that would have been executed without running them on the list of servers"
 echo "-v VERBOSE Shows which server the command(s) are currently being executed on"
 echo "-s SUDO Runs the command(s) using sudo on the remote server"


 exit 2
}

# logic below is used for when the -v flag is passed in while using the script
function verboseMode(){

  if [[ $VERBOSE == "true" ]]; then echo "Currently running commands on ${1}"
  fi
}


# function below takes in server name and command to be executed on said server
function executeCMDs(){

  
  local server="$1"
  local cmd="$2"
  
  # if statement below runs commands on server with sudo or as a regular user

  if [[ $SUDO == "sudo" ]]
  then
    
    echo "sudo logic running: ssh -o ConnectTimeout=2 ${server} ${SUDO} ${cmd}"
    ssh -o ConnectTimeout=2 $server $SUDO $cmd
    if [[ ${?} -ne 0 ]]
    then
      echo "error after cmd: ${cmd}"
      
    fi
  else
    
    echo "sudo off running ssh -o ConnectTimeout=2 ${server} ${cmd}"
    ssh -o ConnectTimeout=2 "${server}" "${cmd}"
    if [[ ${?} -ne 0 ]]
    then
      echo "error after trying to execute cmd: ${cmd}"
      
    fi
    

  
  fi
}


# while loop that processes flags and arguments passed in
while getopts f:nsv OPTION
do
  case ${OPTION} in
    f)
      echo "new filepath passed in"
      FILEPATH="${OPTARG}"
      #test if file exists
      if [ -f "${FILEPATH}" ]
      then
        
        echo "path to list of servers is now ${FILEPATH}" 
      else
        echo "Error please doublecheck filepath"
        exit 2
      fi;;
    n)
      echo "dry run"
      DRYRUN="true"
      ;;
    s)
      echo "sudo mode"
      SUDO="sudo"
      ;;
    v)
      echo "verbose mode"
      VERBOSE="true"
      ;;
    ?)
      echo "invalid flag"
      usage
      
      ;;
  esac
    
done

#To remove flags and args.

#echo "$(( ${OPTIND} - 1 )) is index of arg after flags"
shift $(( $OPTIND - 1 ))

# ${#} is the number of arguments that were passed in to the script
if [[ ${#} -lt 1 ]]
then
  
  usage
  exit 1
fi

# goes through each server name in file located at $FILEPATH
for server in $(cat "$FILEPATH")

do
  verboseMode "${server}"    
  for cmd in "${@}"
    do
      
      if [[ $DRYRUN == "true" ]]
      then
        
        echo "DRY RUN: ssh -o ConnectTimeout=2 ${server} ${SUDO} ${cmd}"
      # if doing dry run, continue keyword below will stop loop at this point and move on to next command  
      # the idea being that the executeCMDs function would never be reached and that only the echo statement above would be executed
	    continue 1
      fi
      
      executeCMDs "${server}" "${cmd}" 
    done

done
