#!/usr/bin/env bash
# SG: tobe done update this documentation
# This script allows to run uniconfig-native scale test with netconftest-tool
# it assumes to have already karaf and the <device_number> devices set up
# to run it do:
# ./test_uniconfig_native_scale.sh --mount-xr6 <postman_env_file>
# e.g.: ./test_uniconfig_native_scale.sh --mount-xr6 xrv_env.json
# to mount the xr6 device
#
# otherwise to run the real test call the script with:
# ./test_uniconfig_native_scale.sh <odl_ip> <first_device_number> <device_number> <iter_number> <test_scenario>
# e.g.: ./test_uniconfig_native_scale_scale.sh 127.0.0.1 18500 100 1 --commit-all
# where:
# <odl_ip>: ip address of machine where is running odl
# <first_device_number>: port number of first device
# <device_number>: how many devices will be tested in netconftesttool
# <iter_number>: how many iterations of CUD will be done
# the output of the test is the duration of commit and duration of calculate diff
#
# <test_scenario>: allows to specify which scenario to test
# two different scenarios are available
# --commit-all : all changes are commited to devices with one single commit command
# --commit-single : the config changes in each device are commited using a commit related to the single device

#set -exu
set +x

# import the test_uniconfig_native_scale_utils.sh file to have the elementary functions available here in the test
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
source "$SCRIPTPATH"/test_uniconfig_native_scale_utils.sh


# parameters
collection="pc_uniconfig-native_RPC_scale_test.json"
device_prefix="netconf-"


# whitelist cisco xr6 device
if [[ "$1" == "--whitelist" ]]; then

    # parameters
    odl_ip=$2

    file=list.txt
    rm_file "$file"

    folder="whitelist cisco xr6 device"
    echo "Performing $folder"
    unbuffer newman run $collection --bail -n 1 --folder "$folder" --env-var "odl_ip=$odl_ip" --reporters cli,junit --reporter-junit-export "./junit_results/mount.xml"; if [ "$?" != "0" ]; then
	echo "Collection $collection testing $folder FAILED" >> $file
	cat_rm_file "$file"
	echo "ERROR during whitelisting"
	exit 1
    fi
    cat_rm_file "$file"
    exit 0

fi


# run test
# parameters from command line
odl_ip=$1
first_device=$2
device_number=$3
iter_number=$4
test_scenario=$5

# check iter_number
if [[ "$iter_number" < 1 ]] ; then
  echo "ERROR: the number of iterations of the test must be at least 1"
  exit 1
fi

# check test_scenario
if [[ "$test_scenario" != "--commit-all" ]] && [[ "$test_scenario" != "--commit-single" ]] ; then
    echo "ERROR: wrong test scenario parameter, must be: '--commit-all' or '--commit-single'"
    exit 1
fi

scenario_commit_all=false
if [[ "$test_scenario" == "--commit-all" ]] ; then
    scenario_commit_all=true
else
    scenario_commit_all=false
fi



file="report_setup.txt"
rm_file "$file"

output_file="output_file.txt"
rm_file "$output_file"

mkdir -p junit_results


# This test is to check that all the n devices are mounted through netconf
# the test must be repeated several times in a for loop
### setup testtool devices
echo "Starting check device mounted with netconf with $device_number devices"

for (( iter=1; iter<=$iter_number; iter++ ))
do
    echo "Starting check device mounnted with netconf devices number $device_number iteration: $iter"

    folder="setup show testtool device netconf existence"
    run_iter_loop "$iter" "$collection" "$folder" "$odl_ip" "$first_device" "$device_number" "$device_prefix" "$file"
done # end of iteration


# if there is a failure in the setup phase abort the test
if [ -f $file ] ; then
    cat $file
    rm $file
    echo "ERROR DURING TEST SETUP -> TEST ABORTED"
    exit 1
fi
