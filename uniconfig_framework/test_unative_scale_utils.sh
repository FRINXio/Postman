#!/usr/bin/env bash
# this script contains the functions used by the test_unative_scale.sh test.

set +x

# function definitions

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


# Setup functions
run_setup_loop () {
    local _collection=$1
    local _folder=$2
    local _odl_ip=$3
    local _device_number=$4
    local _nodes_file=$5
    local _file=$6

    local _test_id="collection: $_collection folder: $_folder"
    echo $_test_id
    unbuffer newman run "$_collection" --bail folder -n "$_device_number" --folder "$_folder" --env-var "odl_ip=$_odl_ip" --iteration-data "$_nodes_file" --reporters cli,junit --reporter-junit-export "./junit_results/${_folder}_${_node_id}.xml"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $_file; fi

}


run_setup_folder_all_nodes () {
    local _collection=$1
    local _folder=$2
    local _odl_ip=$3
    local _device_number=$4
    local _file=$5

    local _test_id="collection: $_collection folder: $_folder"
    echo $_test_id
    unbuffer newman run "$_collection" --bail folder -n 1 --folder "$_folder" --env-var "odl_ip=$_odl_ip" --env-var "device_number=$_device_number" --reporters cli,junit --reporter-junit-export "./junit_results/$_folder.xml"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $_file; fi
}


# Iteration functions
run_iter_loop () {
    local _iter=$1
    local _collection=$2
    local _folder=$3
    local _odl_ip=$4
    local _device_number=$5
    local _nodes_file=$6
    local _file=$7

    local _test_id="iteration: $_iter collection: $_collection folder: $_folder"
    echo $_test_id
    unbuffer newman run "$_collection" --bail folder -n "$((_device_number+1))" --folder "$_folder" --env-var "odl_ip=$_odl_ip" --iteration-data "$_nodes_file" --reporters cli,junit --reporter-junit-export "./junit_results/$_iter/${_folder}_${_node_id}.xml"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $_file; fi

}

run_iter_folder_all_nodes () {
    local _iter=$1
    local _collection=$2
    local _folder=$3
    local _odl_ip=$4
    local _device_number=$5
    local _file=$6

    local _test_id="iteration: $_iter collection: $_collection folder: $_folder"
    echo $_test_id
    unbuffer newman run "$_collection" --bail folder -n 1 --folder "$_folder" --env-var "odl_ip=$_odl_ip" --env-var "device_number=$_device_number" --reporters cli,junit --reporter-junit-export "./junit_results/$_iter/$_folder.xml"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $_file; fi
}

run_iter_calculate_diff () {
    local _iter=$1
    local _collection=$2
    local _folder=$3
    local _odl_ip=$4
    local _device_number=$5
    local _file=$6

    local _test_id="iteration: $_iter collection: $_collection folder: $_folder device_number: $_device_number"
    echo $_test_id
    unbuffer newman run "$_collection" --bail folder -n 1  --folder "$_folder" --env-var "odl_ip=$_odl_ip" --env-var "device_number=$_device_number" --reporters cli,junit --reporter-junit-export "./junit_results/$iter/$_folder.xml"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $_file; fi

}


# Calculate duration functions

get_commit_duration () {
    local _iter=$1
    local _commit_folder=$2
    local _device_number=$3
    local _output_file=$4

    commit_duration=`cat "./junit_results/$_iter/$_commit_folder.xml" | grep "create / create commit all devices / commit all devices" | grep -E -o 'time="[0-9]+.[0-9]+"' | grep -E -o '[0-9]+.[0-9]+'`
    echo "Iteration: $_iter --- Commit duration for $_device_number devices: $commit_duration sec" >> $_output_file;
}

get_average_commit_duration () {
    # this function allows to get the commit duration from the xml output of the single device commit
    # then add to a counter and divide for the number of devices in order to get
    # the average commit duration
    local _iter=$1
    local _commit_folder=$2
    local _first_device=$3
    local _device_number=$4
    local _device_prefix=$5
    local _output_file=$6
    local commit_duration_counter=0.0

    for (( dev=$_first_device; dev<=$_first_device+$_device_number; dev++ ))
    do
	node_id=$_device_prefix$dev

	commit_duration=`cat "./junit_results/$_iter/${_commit_folder}_${node_id}.xml" | grep "create / create commit single device / commit single device" | grep -E -o 'time="[0-9]+.[0-9]+"' | grep -E -o '[0-9]+.[0-9]+'`
	commit_duration_counter=`echo "$commit_duration_counter $commit_duration" | awk '{printf "%.3f", $1 + $2}'`
    done

    _device_number=`echo "$_device_number + 1" | bc`
    average_commit_duration=`echo "$commit_duration_counter $_device_number" | awk '{printf "%.3f", $1 / $2}'`
    echo "Iteration: $_iter --- Average commit duration for $_device_number devices: $average_commit_duration sec" >> $_output_file;
}

get_calculate_diff_duration () {
    local _iter=$1
    local _calculate_diff_folder=$2
    local _device_number=$3
    local _output_file=$4

    calculate_diff_duration=`cat "./junit_results/$_iter/$_calculate_diff_folder.xml" | grep "update / update calculate diff all testtool devices / update calculate diff all testtool devices" | grep -E -o 'time="[0-9]+.[0-9]+"' | grep -E -o '[0-9]+.[0-9]+'`
    echo "Iteration: $_iter --- Calculate diff duration for $_device_number devices: $calculate_diff_duration sec" >> $_output_file;

}
