#!/usr/bin/env bash
# This script allows to enable white list for Cisco XR6 devices on ODL run:
# ./whitelist_xr6_device.sh <odl_ip>
# e.g.: ./whitelist_xr6_device.sh 127.0.0.1
#

#set -exu
set +x

# whitelist cisco xr6 device
# parameters
odl_ip=$1
collection="whitelist_xr6_device.json"
device_prefix="netconf-"

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

file=list.txt
rm_file "$file"

folder="whitelist xr6 device"
_test_id="collection: $collection folder: $folder"
echo "Performing: $_test_id"
unbuffer newman run $collection --bail folder -n 1 --folder "$folder" --env-var "odl_ip=$odl_ip" --reporters cli,junit --reporter-junit-export "./junit_results/mount.xml"; if [ "$?" != "0" ]; then
    echo "$_test_id FAILED" >> $file
    cat_rm_file "$file"
    echo "ERROR during whitelisting"
    exit 1
fi
cat_rm_file "$file"
