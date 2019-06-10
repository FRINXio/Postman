#!/bin/bash
# Steps to run the script
# 1) create an input file in json format where keys are postman collection files
#    and values are tests to be run
# {
#  "pc_unified_mpls.json": ["Mpls-te CRUD","Mpls-tunnel CRUD"],
#  "another file": ["another","list of","tests"]
# }
# 2) to run it do:
# ./test_script env_file json_input_file layer
# where layer = uniconfig | unified

#set -exu
set +x

env_file=$1
tests_input_file=$2
layer="uniconfig"
if [ "$3" == "unified" ]; then
    layer="unified"
fi

mount_collection=pc_mount_unmount.json
if [ "$env_file" == "xrv_env.json" ] ; then
  dev_pref="XR6"
  mount_pref="XR6"
elif [ "$env_file" == "xrv5_env.json" ] ; then
  dev_pref="XR5"
  mount_pref="XR5"
elif [ "$env_file" == "classic_152_env.json" ] ; then
  dev_pref="Classic"
  mount_pref="Classic"
elif [ "$env_file" == "xe_env.json" ] ; then
  dev_pref="XE"
  mount_pref="XE"
elif [ "$env_file" == "junos173virt_env.json" ] ; then
  dev_pref="Junos"
  mount_pref="Junos"
elif [ "$env_file" == "xrv5.3.4asAsr.json" ] ; then
  dev_pref="ASR"
  mount_pref="ASR"
elif [ "$env_file" == "xrv6.1.2as5_env.json" ] ; then
  dev_pref="XR5"
  mount_pref="XR5"
elif [ "$env_file" == "asr_env.json" ] ; then
  dev_pref="ASR"
  mount_pref="ASR"
elif [ "$env_file" == "xrv6.2.3as5_env.json" ] ; then
  dev_pref="XR5"
  mount_pref="XRV6.2.3"
elif [ "$env_file" == "xrv7.0.1as5_env.json" ] ; then
  dev_pref="XR5"
  mount_pref="XR5"
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

folder="$mount_pref Mount $layer"
echo "Performing $folder"
unbuffer newman run $mount_collection --bail -e $device -n 1 --folder "$folder" --reporters cli,junit --reporter-junit-export "./junit_results/mount.xml"; if [ "$?" != "0" ]; then
    echo "Collection $mount_collection with environment $device testing $folder FAILED" >> $file
    if [ -f $file ] ; then
        cat $file
        rm $file
    fi
    echo "DEVICE HAS NOT BEEN MOUNTED"
    exit 1
fi

txt_collections="`cat $tests_input_file | jq -c keys[]`"
echo $txt_collections
declare -a "collections=($txt_collections)"
echo ${collections[@]}
i=0
for collection in "${collections[@]}"
do
  txt_folders=`cat $tests_input_file | jq -c ."\"$collection\""[]`
  declare -a "folders=($txt_folders)"
  for folder in "${folders[@]}"
  do
    ((i++))
    rfolder="$dev_pref $folder READERS"
    echo "Performing $rfolder from file $collection"
    unbuffer newman run $collection -e $device -n 1 --folder "$rfolder" --reporters cli,junit --reporter-junit-export "./junit_results/$rfolder.xml"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing ($dev_pref) $rfolder FAILED" >> $file; fi

    coll_len=`echo $folder | wc -w`
    coll_arr=($folder)
    ll=`if [ $coll_len -gt 2 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
    sfolder="$dev_pref ${coll_arr[@]:0:${ll}} Setup"
    echo "Performing $sfolder from file $collection"
    unbuffer newman run $collection -e $device -n 1 --folder "$sfolder" --reporters cli,junit --reporter-junit-export "./junit_results/$sfolder$i.xml"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing ($dev_pref) $sfolder FAILED" >> $file; fi
    echo "Performing $folder from file $collection"
    unbuffer newman run $collection -e $device -n 1 --folder "$folder" --reporters cli,junit --reporter-junit-export "./junit_results/$folder$i.xml"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing ($dev_pref) $folder FAILED" >> $file; fi

    tfolder="$dev_pref ${coll_arr[@]:0:${ll}} Teardown"
    echo "Performing $tfolder from file $collection"
    unbuffer newman run $collection -e $device -n 1 --folder "$tfolder" --reporters cli,junit --reporter-junit-export "./junit_results/$tfolder$i.xml"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing ($dev_pref) $tfolder FAILED" >> $file; fi
    sleep 2
  done
done

folder="$mount_pref Unmount $layer"
echo "Performing $folder"
unbuffer newman run $mount_collection --bail -e $device -n 1 --folder "$folder" --reporters cli,junit --reporter-junit-export "./junit_results/unmount.xml"; if [ "$?" != "0" ]; then echo "Collection $mount_collection with environment $device testing $folder FAILED" >> $file; fi

if [ -f $file ] ; then
    cat $file
    rm $file
fi
