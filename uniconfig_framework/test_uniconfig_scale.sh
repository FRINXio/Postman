#!/usr/bin/env bash
# This script allows to run uniconfig scale test with cli-testtool
# it assumes to have already karaf and the <device_number> devices set up
# to run test call the script with:
# ./test_uniconfig_scale.sh <odl_ip> <first_device_number> <device_number>
# e.g.: ./test_uniconfig_scale.sh 127.0.0.1 18500 100
# where:
# <odl_ip>: ip address of machine where is running odl
# <first_device_number>: port number of first device
# <device_number>: how many devices will be tested in netconftesttool

#set -exu
set +x

# run test
# parameters
collection="pc_uniconfig_RPC_scale_test.json"
device_prefix="cli-"
# parameters from command line
odl_ip=$1
first_device=$2
device_number=$3


rm_file () {
    if [ -f $1 ] ; then
	rm $1
    fi
}

cat_rm_file () {
    if [ -f $1 ] ; then
	cat $1
	rm $1
    fi
}


file="report_setup.txt"
rm_file "$file"

output_file="output_file.txt"
rm_file "$output_file"

mkdir -p junit_results


get_duration () {
    local _folder=$1
    local _device_number=$2
    local _output_file=$3

    _duration=`cat "./junit_results/$_folder.xml" | grep "$_folder / $_folder" | grep -E -o 'time="[0-9]+.[0-9]+"' | grep -E -o '[0-9]+.[0-9]+'`
    echo "Devices: $_device_number Request: $_folder --- Duration: $_duration sec" >> $_output_file;
}


get_overall_duration () {
    local _folder=$1
    local _device_number=$2
    local _output_file=$3

    _duration=`cat "./junit_results/$_folder.xml" | grep "pc_uniconfig_RPC_scale_test" | grep -E -o 'time="[0-9]+.[0-9]+"' | grep -E -o '[0-9]+.[0-9]+'`
    echo "Devices: $_device_number Request: $_folder --- Overall Duration: $_duration sec" >> $_output_file;
}


# run functions
run_loop () {
    local _collection=$1
    local _folder=$2
    local _odl_ip=$3
    local _device_number=$4
    local _nodes_file=$5
    local _file=$6

    local _test_id="collection: $_collection folder: $_folder"
    echo $_test_id
    unbuffer newman run "$_collection" --bail folder -n "$_device_number" --folder "$_folder" --env-var "odl_ip=$_odl_ip" --iteration-data "$_nodes_file" --reporters cli,junit --reporter-junit-export "./junit_results/${_folder}.xml"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $_file; fi

}


run_all_nodes () {
    local _collection=$1
    local _folder=$2
    local _odl_ip=$3
    local _device_number=$4
    local _file=$5

    local _test_id="collection: $_collection folder: $_folder device_number: $_device_number"
    echo $_test_id
    unbuffer newman run "$_collection" --bail folder -n 1  --folder "$_folder" --env-var "odl_ip=$_odl_ip" --env-var "device_number=$_device_number" --reporters cli,junit --reporter-junit-export "./junit_results/$_folder.xml"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $_file; fi

}


# check number mounted devices unified
folder="check_number_mounted_devices_unified"
run_all_nodes "$collection" "$folder" "$odl_ip" "$device_number" "$file"

# create nodes.csv
# this file contains
#
# node_id
# cli-18000
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


# put configurations on all devices
folder="put_configuration"
run_loop "$collection" "$folder" "$odl_ip" "$device_number" "$nodes_file" "$file"
get_overall_duration "$folder" "$device_number" "$output_file"

# calculate diff
folder="calculate_diff"
run_all_nodes "$collection" "$folder" "$odl_ip" "$device_number" "$file"
get_duration "$folder" "$device_number" "$output_file"

# commit all
folder="commit_all"
run_all_nodes "$collection" "$folder" "$odl_ip" "$device_number" "$file"
get_duration "$folder" "$device_number" "$output_file"

# dry run
folder="dry_run"
run_all_nodes "$collection" "$folder" "$odl_ip" "$device_number" "$file"
get_duration "$folder" "$device_number" "$output_file"

# sync from network
folder="sync_from_network"
run_all_nodes "$collection" "$folder" "$odl_ip" "$device_number" "$file"
get_duration "$folder" "$device_number" "$output_file"



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
