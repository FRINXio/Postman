#!/usr/bin/env bash
# Usage:
# ./test_replace_config_with_operational.sh <odl_ip> <first_device> <device_number> <logfile>

# set -exu
set +x

# run test
# parameters
collection="test_replace_config_with_operational.json"
device_prefix="netconf-"

# parameters from command line
odl_ip=$1
first_device=$2
device_number=$3
logfile=$4


rm_file () {
    local _file=$1
    if [ -f $_file ] ; then
	rm $_file
    fi
}

nodes_file="nodes.csv"
rm_file "$nodes_file"
echo "node_id" >> $nodes_file
for (( dev=$first_device; dev<=$first_device+$device_number; dev++ ))
do
    node_id=$device_prefix$dev
    echo "$node_id" >> $nodes_file
done


## since the devices simulated with netconf-testtool are without configuration
## in order to test the replace-config-with-operational is necessary to have some configuration inside the datastore
## before the test execution add some configuration for each of the <device_number> devices
## and commit them to devices

# put configuration for each device
folder="put_config_in_device"
_test_id="collection: $collection folder: $folder"
echo $_test_id
unbuffer newman run "$collection" --bail folder -n "$device_number" --folder "$folder" --env-var "odl_ip=$odl_ip" --iteration-data "$nodes_file" --reporters cli,junit --reporter-junit-export "./junit_results/${folder}_${node_id}.xml"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $logfile; fi

# commit configurations in devices
folder="commit"
_test_id="collection: $collection folder: $folder"
echo $_test_id
unbuffer newman run "$collection" --bail folder -n 1 --folder "$folder" --env-var "odl_ip=$odl_ip" --reporters cli,junit --reporter-junit-export "./junit_results/$folder.xml"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $logfile; fi


## once the devices

# repeat the request for 4 times if at least one of them takes more than 60s to terminate
# then the test fails

for iteration in `seq 1 4`;
do
  # replace config with operational
  folder="replace_config_with_operational"
  _test_id="iteration: $iteration collection: $collection folder: $folder"
  echo $_test_id
  unbuffer newman run "$collection" --bail folder -n 1 --folder "$folder" --env-var "odl_ip=$odl_ip" --reporters cli,junit --reporter-junit-export "./junit_results/$folder.xml"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $logfile; fi

  replace_config_with_operational_duration=`cat "./junit_results/replace_config_with_operational.xml" | grep "test_replace_config_with_operational" | grep -E -o 'time="[0-9]+.[0-9]+"' | grep -E -o '[0-9]+.[0-9]+'`
  echo "replace_config_with_operational for $device_number devices duration: $replace_config_with_operational_duration sec"

  if [ $(echo "$replace_config_with_operational_duration>60" | bc) -ne 0 ]; then
    echo "it is greater"
    error_msg="replace_config_with_operational for $device_number devices duration: $replace_config_with_operational_duration sec took more than 60sec test FAILED"
    echo $error_msg
    echo $error_msg >> $logfile
    exit 1
  fi

  # sleep a while between each iteration
  sleep 10
done
