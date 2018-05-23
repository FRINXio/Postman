#!/bin/bash
# Steps to run the script
# 1) create an input file in json format where keys are postman collection files
#    and values are tests to be run
# {
#  "pc_unified_mpls.json": ["Mpls-te CRUD","Mpls-tunnel CRUD"],
#  "another file": ["another","list of","tests"]
# }
# 2) to run it do:
# ./test_script env_file json_input_file

#set -exu
set +x

env_file=$1
tests_input_file=$2
mount_collection=pc_mount_unmount.json
if [ "$env_file" == "xrv_env.json" ] ; then
  dev_pref="XR"
elif [ "$env_file" == "xrv5_env.json" ] ; then
  dev_pref="XR5"
elif [ "$env_file" == "classic_152_env.json" ] ; then
  dev_pref="Classic"
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

folder="$dev_pref Mount"
echo "Performing $folder"
unbuffer newman run $mount_collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $mount_collection with environment $device testing $folder FAILED" >> $file; fi

txt_collections="`cat $tests_input_file | jq -c keys[]`"
echo $txt_collections
declare -a "collections=($txt_collections)"
echo ${collections[@]}
for collection in "${collections[@]}"
do
  txt_folders=`cat $tests_input_file | jq -c ."\"$collection\""[]`
  declare -a "folders=($txt_folders)"
  for folder in "${folders[@]}"
  do 
    rfolder="$dev_pref $folder READERS"
    echo "Performing $rfolder from file $collection"
    unbuffer newman run $collection -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing ($dev_pref) $rfolder FAILED" >> $file; fi

    coll_len=`echo $folder | wc -w`
    coll_arr=($folder)
    ll=`if [ $coll_len -gt 2 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
    sfolder="$dev_pref ${coll_arr[@]:0:${ll}} Setup"
    echo "Performing $sfolder from file $collection"
    unbuffer newman run $collection -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing ($dev_pref) $sfolder FAILED" >> $file; fi
    echo "Performing $folder from file $collection"
    unbuffer newman run $collection -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing ($dev_pref) $folder FAILED" >> $file; fi

    tfolder="$dev_pref ${coll_arr[@]:0:${ll}} Teardown"
    echo "Performing $tfolder from file $collection"
    unbuffer newman run $collection -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing ($dev_pref) $tfolder FAILED" >> $file; fi
    sleep 2
  done
done

folder="$dev_pref Unmount"
echo "Performing $folder"
unbuffer newman run $mount_collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $mount_collection with environment $device testing $folder FAILED" >> $file; fi

if [ -f $file ] ; then
    cat $file
    rm $file
fi