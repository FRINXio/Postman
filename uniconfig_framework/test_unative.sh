#!/bin/bash
# This script allows to run unative collections
# The difference respect to the test_script.sh is that in this case
# it is not necessary to execute the mount and unmount tests since
# for unative is simple and it is already performend inside the
# testsetup of every collection
#
# Steps to run the script
# 1) create an input file in json format where keys are postman collection files
#    and values are tests to be run
# {
#  "pc_unified_mpls.json": ["Mpls-te CRUD","Mpls-tunnel CRUD"],
#  "another file": ["another","list of","tests"]
# }
# 2) to run it do:
# ./test_unative.sh env_file json_input_file


#set -exu
set +x

env_file=$1
tests_input_file=$2

if [ "$env_file" == "xrv6.1.2_env.json" ] ; then
  dev_pref="XR6"
elif [ "$env_file" == "xrv5.3.4_env.json" ] ; then
  dev_pref="XR5"
# For purpose: template version drop testing
elif [ "$env_file" == "vnf20_env.json" ] || [ "$env_file" == "vnf16_env.json" ] ; then
  dev_pref="VNF"
else
  echo "Unsupported env file: $env_file"
  exit 1
fi
device=$env_file

file=list.txt
if [ -f $file ] ; then
    rm $file
fi

echo "Going to test with env_file $env_file. Assigned prefix is: \"$dev_pref\"."
mkdir -p junit_results

txt_collections="`cat $tests_input_file | jq -c keys[]`"
echo $txt_collections
declare -a "collections=($txt_collections)"

i=0
for collection in "${collections[@]}"
do
  txt_folders=`cat $tests_input_file | jq -c ."\"$collection\""[]`
  declare -a "folders=($txt_folders)"

  for folder in "${folders[@]}"
  do
    ((i++))
    rfolder="$dev_pref $folder READERS"
    test_id="collection: $collection environment: $device device: $dev_pref folder: $rfolder"
    echo "Performing: $test_id"
    unbuffer newman run $collection -e $device -n 1 --folder "$rfolder" --reporters cli,junit --reporter-junit-export "./junit_results/$rfolder.xml"; if [ "$?" != "0" ]; then echo "$test_id FAILED" >> $file; fi

    coll_len=`echo $folder | wc -w`
    coll_arr=($folder)
    ll=`if [ $coll_len -gt 2 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`

    sfolder="$dev_pref ${coll_arr[@]:0:${ll}} Setup"
    test_id="collection: $collection environment: $device device: $dev_pref folder: $sfolder"
    echo "Performing: $test_id"
    unbuffer newman run $collection -e $device -n 1 --folder "$sfolder" --reporters cli,junit --reporter-junit-export "./junit_results/$sfolder$i.xml"; if [ "$?" != "0" ]; then echo "$test_id FAILED" >> $file; fi

    test_id="collection: $collection environment: $device device: $dev_pref folder: $folder"
    echo "Performing: $test_id"
    unbuffer newman run $collection -e $device -n 1 --folder "$folder" --reporters cli,junit --reporter-junit-export "./junit_results/$folder$i.xml"; if [ "$?" != "0" ]; then echo "$test_id FAILED" >> $file; fi

    tfolder="$dev_pref ${coll_arr[@]:0:${ll}} Teardown"
    test_id="collection: $collection environment: $device device: $dev_pref folder: $tfolder"
    echo "Performing: $test_id"
    unbuffer newman run $collection -e $device -n 1 --folder "$tfolder" --reporters cli,junit --reporter-junit-export "./junit_results/$tfolder$i.xml"; if [ "$?" != "0" ]; then echo "$test_id FAILED" >> $file; fi
    sleep 2
  done
done


if [ -f $file ] ; then
    cat $file
    rm $file
fi
