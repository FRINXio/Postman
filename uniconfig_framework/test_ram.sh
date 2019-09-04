#!/bin/bash
set +x

# To run the test script:
# ./test_ram.sh <postman_env> <time_duration> <logfile>
# e.g.: ./test_ram.sh xrv5.3.4_env.json "+10 minutes" "test_ram.log"
# e.g.: ./test_ram.sh xrv5.3.4_env.json "+30 days" "test_ram.log"

device=$1
test_duration=$2
logfile=$3
collection=pc_uniconfig_RPC_test_ram.json

if [ -f $logfile ] ; then
    rm $logfile
fi
touch $logfile

end_test_date=$(date --utc -d "$test_duration" +%s);
echo "##### Expected end test date: `date --utc -d @$end_test_date`"

# run setup
folder="xr5_RPC_test_ram_setup"
_test_id="collection: $collection folder: $folder"
echo $_test_id
unbuffer newman run $collection --bail --bail folder -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $logfile; fi

# run the main test in a loop
folder="RPC_configure_and_delete_loopback"
while [ $(date --utc +%s) -lt $end_test_date ]; do
    timestamp=$(date --utc '+%Y-%m-%d-%H.%M.%S')
    _test_id="$timestamp collection: $collection folder: $folder"
    echo $_test_id
    unbuffer newman run $collection --bail --bail folder -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $logfile; fi
    sleep 60
done

# run teardown
folder="xr5_RPC_test_ram_teardown"
_test_id="collection: $collection folder: $folder"
echo $_test_id
unbuffer newman run $collection --bail --bail folder -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $logfile; fi

if [ -f $logfile ] ; then
    cat $logfile
fi
