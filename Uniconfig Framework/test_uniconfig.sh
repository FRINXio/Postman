#!/bin/bash
set +x

collection=postman_uniconfig.json
file=list.txt

if [ -f $file ] ; then
    rm $file
fi

### Test for IOS XR
XR_devices=("xrv5_env.json")
XR5_folders=("Mount" "RSVP CRUD" "MPLS CRUD" "OSPF CRUD" "BGP CRUD" "5 LAG without BFD" "SNMP" "SYSLOG CRUD" "ETH IFC CRUD" "PF IFC CRUD" "LACP CRUD" "Unmount")

for device in ${XR_devices[@]}
do
   echo Collection running with $device
         if [ "$device" == "xrv5_env.json" ]
         then
             for folder in "${XR5_folders[@]}"
             do
                newman run $collection --bail -e $device -n 1 --folder "XR $folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing XR $folder FAILED" >> $file; fi
                sleep 5
             done
         fi

done

if [ -f $file ] ; then
    cat $file
    rm $file
fi

## For html and xml ouputs use this:  --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results.xml"  --reporter-html-export "/tmp/Environment_${device}_${folder}_results.html"
## For example:
##    newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results.xml"  --reporter-html-export "/tmp/Environment_${device}_${folder}_results.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing Classic $folder FAILED" >> $file; fi
