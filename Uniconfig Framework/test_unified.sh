#!/bin/bash
set +x

collection=postman_collection_unified.json
file=list.txt

if [ -f $file ] ; then
    rm $file
fi

### Mount unmount test case
devices=("mount_unmount_env.json" "mount_unmount_telnet_env.json" "mount_unmount_ios1553_env.json")
folders=("Mount/Unmount IOS")

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
XR_devices=("xrv_env.json" "asr_env.json" "xrv5_env.json")
#XR_folders=(need fix: "General information" "L2P2P connection CRUD Negative")
XR_folders=("Interface" "Interface IP" "subinterface common CRUD basic" "static route" "CDP" "LLDP" "ospf" "L2P2P connection" "L2P2P connection CRUD locifc-remote" "L2P2P connection CRUD locifc-sub" "L2P2P connection CRUD locsub-remote" "L2VPN connection" "L2VPN connection CRUD locifc-remote" "L2VPN connection CRUD locsub-remote" "BGP summary")
#XR5_folders=(need fix: "General information" ,SNMP"-CCASP-140)
XR5_folders=("subinterface common" "subinterface common CRUD global" "OSPF CRUD" "RSVP CRUD" "Mpls-te CRUD" "Mpls-tunnel CRUD" "SYSLOG CRUD" "LACP CRUD" "LACP IFC CRUD interface" "LACP IFC CRUD element" "IFC ACL CRUD basic" "IFC ACL CRUD containers" "PF IFC CRUD" "ETH IFC CRUD basic" "ETH IFC CRUD subinterface-part" "ETH IFC CRUD holdtime-part" "ETH IFC CRUD damping-part" "ETH IFC CRUD stats-part" "ETH IFC CRUD eth-part" "ETH IFC CRUD subinterface-container" "ETH IFC CRUD holdtime-container" "ETH IFC CRUD damping-container" "ETH IFC CRUD stats-container" "ETH IFC CRUD eth-container" "LAG without-BFD" "LAG without BFD basic" "LAG without BFD aggregation" "LAG without BFD statistics" "LAG without BFD damping" "LAG without BFD ipv4" "BGP CRUD" "BGP instance CRUD basic")
#ASR_folders=(need fix: "General information","5 LAG without BFD"-MU-212 "5 LAG with BFD"-MU-213, "SNMP"-MU-219 "SYSLOG CRUD"-MU-220  )
ASR_folders=("Platform unified" "Interface" "Interface IP" "subinterface common CRUD basic" "static route" "CDP" "LLDP" "ospf" "BGP summary")

for device in ${XR_devices[@]} 
do
   echo Collection running with $device
         if [ "$device" == "xrv_env.json" ]
         then
             folder="XR Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
             for folder in "${XR_folders[@]}"
             do
                rfolder="XR $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR) $rfolder FAILED" >> $file; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="XR ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR) $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR) $folder FAILED" >> $file; fi
                tfolder="XR ${coll_arr[@]:0:${ll}} Teardown"
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
                rfolder="XR5 $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR5) $rfolder FAILED" >> $file; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="XR5 ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR5) $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR5) $folder FAILED" >> $file; fi
                tfolder="XR5 ${coll_arr[@]:0:${ll}} Teardown"
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
                rfolder="XR $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (ASR) $rfolder FAILED" >> $file; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="XR ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (ASR) $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (ASR) $folder FAILED" >> $file; fi
                tfolder="XR ${coll_arr[@]:0:${ll}} Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (ASR) $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="XR Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (ASR) $folder FAILED" >> $file; fi
         fi
done


### Test for IOS
IOS_devices=("classic_152_env.json" "classic_1553_env.json" "xe_env.json" "xe4_env.json" "cat6500_env.json")
#Classic_folders=(need fix:"General information" "L2P2P connection CRUD Negative")
Classic_folders=("Interfaces" "Interfaces IP" "static route" "journal-dryrun" "CDP" "subinterface common" "subinterface common CRUD global" "L2P2P connection" "L2P2P connection CRUD locifc-remote" "L2P2P connection CRUD locifc-sub" "L2P2P connection CRUD locsub-remote" "ospf-vrf" "L3VPN OSPF CRUD" "BGP summary" "L3VPN BGP" "BGP instance CRUD global" "L3VPN BGP CRUD global" "L3VPN BGP CRUD Negative" )
#XE_folders=(need fix: "General information" ,"ospf-vrf"-bug MU-159,)
XE_folders=("Interfaces" "Interfaces IP"  "static route"  "journal-dryrun" "CDP" "LLDP" "subinterface common" "subinterface common CRUD global" "ospf-vrf" "L3VPN OSPF CRUD"  "BGP summary" "L3VPN BGP" "BGP instance CRUD global" "L3VPN BGP CRUD global" "L3VPN BGP CRUD Negative")
XE4_folders=("L2VPN connection" "L2VPN connection CRUD locifc-remote" "L2VPN connection CRUD locsub-remote")
CAT6500_folders=("Platform cli")



for device in ${IOS_devices[@]}
do
   echo Collection running with $device
         if [ "$device" == "classic_152_env.json" ]
         then
             folder="Classic Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
             for folder in "${Classic_folders[@]}"
             do
                rfolder="Classic $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $rfolder FAILED" >> $file; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="Classic ${coll_arr[@]:0:${ll}} Setup"       
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
                tfolder="Classic ${coll_arr[@]:0:${ll}} Teardown"
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
                rfolder="Classic $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $rfolder FAILED" >> $file; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="Classic ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing Classic $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing Classic $folder FAILED" >> $file; fi
                tfolder="Classic ${coll_arr[@]:0:${ll}} Teardown"
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
                rfolder="Classic $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE) $rfolder FAILED" >> $file; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="Classic ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE) $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE) $folder FAILED" >> $file; fi
                tfolder="Classic ${coll_arr[@]:0:${ll}} Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE) $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="Classic Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE) $folder FAILED" >> $file; fi
         fi

         if [ "$device" == "xe4_env.json" ]
         then
             folder="Classic Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE4) $folder FAILED" >> $file; fi
             for folder in "${XE4_folders[@]}"
             do
                rfolder="Classic $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE4) $rfolder FAILED" >> $file; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="Classic ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE4) $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE4) $folder FAILED" >> $file; fi
                tfolder="Classic ${coll_arr[@]:0:${ll}} Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE4) $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="Classic Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XE4) $folder FAILED" >> $file; fi
         fi

         if [ "$device" == "cat6500_env.json" ]
         then
             folder="Classic Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (CAT) $folder FAILED" >> $file; fi
             for folder in "${CAT6500_folders[@]}"
             do
                rfolder="Classic $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (CAT) $rfolder FAILED" >> $file; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="Classic ${coll_arr[@]:0:${ll}} Setup"       
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (CAT) $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (CAT) $folder FAILED" >> $file; fi
                tfolder="Classic ${coll_arr[@]:0:${ll}} Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (CAT) $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="Classic Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (CAT) $folder FAILED" >> $file; fi
         fi
done


### Test for Junos
junos_devices=("junos_env.json")
junos_folders=()

for device in ${junos_devices[@]}
do
   echo Collection running with $device
         if [ "$device" == "junos_env.json" ]
         then
             folder="Junos Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
             for folder in "${junos_folders[@]}"
             do
                sfolder="Junos $folder Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $sfolder FAILED" >> $file; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
                tfolder="Junos $folder Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="Junos Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
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
