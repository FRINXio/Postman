#!/usr/bin/env bash
# This script allows to run uniconfig-native scale test with netconftest-tool
# it assumes to have already karaf and the <device_number> devices set up
# to run test call the script with:
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


# run test
# parameters
collection="pc_uniconfig-native_RPC_scale_test.json"
device_prefix="netconf-"
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


# create nodes.csv
# this file contains
#
# node_id
# netconf-18000
# ...
# one row for each device that will be tested
# this file will be passed to newman to iterate
# the test for each device present in the file

nodes_file="nodes.csv"
rm_file "$nodes_file"
echo "node_id" >> $nodes_file
for (( dev=$first_device; dev<=$first_device+$device_number; dev++ ))
do
    node_id=$device_prefix$dev
    echo "$node_id" >> $nodes_file
done


### setup testtool devices
echo "Starting setup configuration inside netconf testtool devices with $device_number devices"

# add the initial configuration to the empty device
folder="setup config to testtool device"
run_setup_loop "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"

if [ "$scenario_commit_all" = true ]; then
    folder="setup commit all devices"
    run_setup_folder_all_nodes "$collection" "$folder" "$odl_ip" "$device_number" "$file"
else
    folder="setup commit single device"
    run_setup_loop "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"
fi

folder="setup show config in testtool device"
run_setup_loop "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"

folder="setup sync from network"
run_setup_folder_all_nodes "$collection" "$folder" "$odl_ip" "$device_number" "$file"

folder="setup calculate diff"
run_setup_folder_all_nodes "$collection" "$folder" "$odl_ip" "$device_number" "$file"


# if there is a failure in the setup phase abort the test
if [ -f $file ] ; then
    cat $file
    rm $file
    echo "ERROR DURING TEST SETUP -> TEST ABORTED"
    exit 1
fi

echo "Done setup configuration inside netconf testtool devices with $device_number devices"


# set report file name
file="report_iterations.txt"

for (( iter=1; iter<=$iter_number; iter++ ))
do
    echo "Starting uniconfig-native scale test devices number $device_number iteration: $iter"

    ### create
    # add an interface to the device configuration
    folder="create add interface to testtool device"
    run_iter_loop "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"

    if [ "$scenario_commit_all" = true ]; then
	# commit all devices with one single commit
	commit_folder="create commit all devices"
	run_iter_folder_all_nodes "$iter" "$collection" "$commit_folder" "$odl_ip" "$device_number" "$file"
    else
	# commit devices one by one with a specific commit
	commit_folder="create commit single device"
	run_iter_loop "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"
    fi

    # check changes in the device through netconf
    folder="create show config in testtool device"
    run_iter_loop "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"

    # sync from network to get commmited changes also in the operational
    folder="create sync from network"
    run_iter_folder_all_nodes "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$file"

    # calculate diff
    folder="create calculate diff"
    run_iter_folder_all_nodes "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$file"


    ### update
    # update the description in the interface already created
    folder="update add config to testtool device"
    run_iter_loop "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"

    # here pass device_number to the test to be sure that exactly device_number devices have a change
    calculate_diff_folder="update calculate diff all testtool devices"
    run_iter_calculate_diff "$iter" "$collection" "$calculate_diff_folder" "$odl_ip" "$device_number" "$file"

    if [ "$scenario_commit_all" = true ]; then
	# commit all devices with one single commit
	folder="update commit all devices"
	run_iter_folder_all_nodes "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$file"
    else
	# commit devices one by one with a specific commit
	folder="update commit single device"
	run_iter_loop "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"
    fi

    # check changes in the device through netconf
    folder="update show config in testtool device"
    run_iter_loop "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"

    # sync from network to get commmited changes also in the operational
    folder="update sync from network"
    run_iter_folder_all_nodes "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$file"

    # calculate diff
    folder="update calculate diff"
    run_iter_folder_all_nodes "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$file"


    ### delete
    # delete interface on each device
    folder="delete config to testtool device"
    run_iter_loop "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"

    if [ "$scenario_commit_all" = true ]; then
	# commit all devices with one single commit
	folder="delete commit all devices"
	run_iter_folder_all_nodes "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$file"
    else
	# commit devices one by one with a specific commit
	folder="delete commit single device"
	run_iter_loop "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"
    fi

    # check changes in the device through netconf
    folder="delete show config in testtool device"
    run_iter_loop "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"

    # sync from network to get commmited changes also in the operational
    folder="delete sync from network"
    run_iter_folder_all_nodes "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$file"

    # calculate diff
    folder="delete calculate diff"
    run_iter_folder_all_nodes "$iter" "$collection" "$folder" "$odl_ip" "$device_number" "$file"


    # Show meaningful test output:
    # commit duration
    if [ "$scenario_commit_all" = true ]; then
	get_commit_duration "$iter" "$commit_folder" "$device_number" "$output_file"
    else
	get_average_commit_duration "$iter" "$commit_folder" "$first_device" "$device_number" "$device_prefix" "$output_file"
    fi

    # calculate diff
    get_calculate_diff_duration "$iter" "$calculate_diff_folder" "$device_number" "$output_file"

    echo "End uniconfig-native scale test devices number $device_number iteration: $iter"
done # end of iteration


# test output presentation
if [ -f $file ] ; then
    echo "-------TEST FAILURE LIST-------"
    cat $file
fi

echo "-------TEST OUTPUT-------"
cat_rm_file "$output_file"

# if there is a failure make jenkins job failing
if [ -f $file ] ; then
    rm $file
    exit 1
fi
