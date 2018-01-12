#!/bin/bash
set +x

collection=postman_collection_unified.json
file=list.txt

if [ -f $file ] ; then
    rm $file
fi

### Mount unmount test case
#devices=("mount_unmount_env.json" "mount_unmount_telnet_env.json" "mount_unmount_ios1553_env.json")
#folders=("Mount/Unmount IOS")

for device in ${devices[@]}
do
   echo Collection running with $device
     for folder in "${folders[@]}"
     do
        newman run $collection --bail -e $device -n 2 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
        sleep 5
     done
done


### Test for IOS XR
#XR_devices=("xrv_env.json" "asr_env.json" "xrv5_env.json")
# TOTO: verify collections and add to uncommented
#XR_folders=("General information" "Interface" "Interface IP" "ospf" "static route" "BGP summary II" "CDP" "LLDP II" "subinterface common II" "BGP CRUD")
XR_folders=()
#XR5_folders=("General information" "BGP CRUD" "SNMP" "SYSLOG CRUD" "RSVP CRUD" "Mpls-te CRUD" "Mpls tunnel CRUD" "OSPF CRUD" "5 LAG without BFD" "subinterface common CRUD" "ETH IFC CRUD" "PF IFC CRUD" "LACP CRUD" "IFC ACL CRUD")
XR5_folders=()
#ASR_folders=("General information" "Interface" "Interface IP" "ospf" "static route" "Platform" "BGP summary II" "CDP" "LLDP II" "subinterface common II" "5 LAG without BFD" "5 LAG with BFD")
#asr may be tested also for "5 LAG without BFD" "5 LAG with BFD" "SNMP" and "SYSLOG CRUD", but only cli mount point may be used
ASR_folders=()

for device in ${XR_devices[@]}
do
   echo Collection running with $device
         if [ "$device" == "xrv_env.json" ]
         then
             folder="XR Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
             for folder in "${XR_folders[@]}"
             do
                sfolder="XR $folder Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR) $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR) $folder FAILED" >> $file; fi
                tfolder="XR $folder Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR) $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="XR Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
         fi

         if [ "$device" == "xrv5_env.json" ]
         then
             folder="XR5 Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
             for folder in "${XR5_folders[@]}"
             do
                sfolder="XR5 $folder Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR5) $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR5) $folder FAILED" >> $file; fi
                tfolder="XR5 $folder Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR5) $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="XR5 Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
         fi

         if [ "$device" == "asr_env.json" ]
         then
             folder="XR Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (ASR) $folder FAILED" >> $file; fi
             for folder in "${ASR_folders[@]}"
             do
                sfolder="XR $folder Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (ASR) $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (ASR) $folder FAILED" >> $file; fi
                tfolder="XR $folder Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (ASR) $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="XR Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (ASR) $folder FAILED" >> $file; fi
         fi
done


### Test for IOS
#IOS_devices=("classic_152_env.json" "classic_1553_env.json" "xe_env.json")
# TOTO: verify collections and add to uncommented
#Classic_folders=("General information" "Interface" "Interface IP" "ospf/vrf" "static route" "BGP summary" "CDP" "subinterface common" "L2P2P" "L2P2P CRUD" "journal/dry-run")
Classic_folders=()
#XE_folders=("General information" "Interface" "Interface IP" "ospf/vrf" "static route" "BGP summary" "CDP" "LLDP" "subinterface common" "journal/dry-run")
XE_folders=()

for device in ${IOS_devices[@]}
do
   echo Collection running with $device
         if [ "$device" == "classic_152_env.json" ]
         then
             folder="Classic Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
             for folder in "${Classic_folders[@]}"
             do
                sfolder="Classic $folder Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
                tfolder="Classic $folder Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="Classic Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
         fi

         if [ "$device" == "classic_1553_env.json" ]
         then
             folder="Classic Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
             for folder in "${Classic_folders[@]}"
             do
                sfolder="Classic $folder Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing Classic $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing Classic $folder FAILED" >> $file; fi
                tfolder="Classic $folder Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing Classic $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="Classic Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
         fi

         if [ "$device" == "xe_env.json" ]
         then
             folder="Classic Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE) $folder FAILED" >> $file; fi
             for folder in "${XE_folders[@]}"
             do
                sfolder="Classic $folder Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE) $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE) $folder FAILED" >> $file; fi
                tfolder="Classic $folder Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE) $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="Classic Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE) $folder FAILED" >> $file; fi
         fi
done



### Test for Linux generic
Linux_devices=("linux_157_env.json")
folders=("Linux")

for device in "${Linux_devices[@]}"
do
   echo Collection running with $device
     for folder in "${folders[@]}"
     do
        newman run $collection --bail -e $device -n 1 --folder "Linux"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
        sleep 5
     done
done


if [ -f $file ] ; then
    cat $file
    rm $file
fi

## For html and xml ouputs use this:  --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results.xml"  --reporter-html-export "/tmp/Environment_${device}_${folder}_results.html"
## For example:
##    newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results.xml"  --reporter-html-export "/tmp/Environment_${device}_${folder}_results.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing Classic $folder FAILED" >> $file; fi
