#!/bin/bash
set +x

collection=postman_collection_uniconfig.json
file=list.txt

if [ -f $file ] ; then
    rm $file
fi

### Test for IOS XR router
#XR_devices=("xrv5_env.json" "junos173virt_env.json")
XR_devices=()
#XR5_folders=("OSPF CRUD" "BGP CRUD" "LACP CRUD" "MPLS-TUNNEL-FULL CRUD" "MPLS-TUNNEL CRUD Config" "MPLS-TUNNEL CRUD Destination" "MPLS-TE CRUD" "LAG CRUD Config" "LAG CRUD Subinterface" "LAG CRUD IPv6" "LAG CRUD Damping" "LAG CRUD Statistics" "LAG CRUD AggegationNoBfd" "LAG-FULL CRUD" "IFC-ACL CRUD Full" "IFC-ACL CRUD Parts" "IFC-ACL CRUD Acl-sets" "RSVP CRUD" "PF-IFC CRUD CiscoExt" "SNMP Gig" "SNMP Lag" "SNMP Non" "IFC CRUD Config" "IFC CRUD HoldTime" "IFC CRUD Subinterface-IPv4" "IFC CRUD Subinterface-IPv6" "IFC CRUD Damping" "IFC CRUD Ethernet" "IFC CRUD Statistics" "IFC-FULL CRUD" "SYSLOG CRUD" "QOS CRUD" "RP CRUD")
XR5_folders=()
#JUNOS_folders=("MPLS-TUNNEL-FULL CRUD" "MPLS-TE CRUD" "LAG CRUD Config" "LAG CRUD Subinterface" "LAG CRUD AggegationBfdLinkSpeed" "IFC-ACL CRUD Full" "IFC-ACL CRUD Parts" "RSVP CRUD" "PF-IFC CRUD JunosExt" "SNMP Gig" "IFC-FULL CRUD" "IFC CRUD Config" "IFC CRUD HoldTime" "IFC CRUD Subinterface" "IFC CRUD Damping" "IFC CRUD Ethernet" "BGP CRUD")
JUNOS_folders=()

### Special case - some test written for XR5 do not run on virtual devices - we test them on ASR XR6 device
#XR_devices=("asr_env.json")
XR_devices=()
#XR5_folders=("IFC CRUD Flows" "IFC CRUD Acls" "LAG CRUD Flows" "LAG CRUD Acls")
XR5_folders=()


for device in ${XR_devices[@]}
do
   echo Collection running with $device
         if [ "$device" == "xrv5_env.json" ]
         then
             folder="XR5 Mount"
             #echo "$folder"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
             for folder in "${XR5_folders[@]}"
             do
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 2 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="XR5 ${coll_arr[@]:0:${ll}} Setup"
                #echo "$sfolder"
                newman run $collection -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR5) $sfolder FAILED" >> $file; fi
                #echo "$folder"
                newman run $collection -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR5) $folder FAILED" >> $file; fi
                
                tfolder="XR5 ${coll_arr[@]:0:${ll}} Teardown"
                #echo "$tfolder"
                newman run $collection -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR5) $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="XR5 Unmount"
             #echo "$folder"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
         fi

         if [ "$device" == "asr_env.json" ]
         then
             folder="XR6 Mount"
             #echo "$folder"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
             for folder in "${XR5_folders[@]}"
             do
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 2 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="XR6 ${coll_arr[@]:0:${ll}} Setup"
                #echo "$sfolder"
                newman run $collection -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR6) $sfolder FAILED" >> $file; fi
                #echo "$folder"
                newman run $collection -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR6) $folder FAILED" >> $file; fi
                
                tfolder="XR6 ${coll_arr[@]:0:${ll}} Teardown"
                #echo "$tfolder"
                newman run $collection -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (XR6) $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="XR6 Unmount"
             #echo "$folder"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
         fi


         if [ "$device" == "junos173virt_env.json" ]
         then
             folder="Junos Mount"
             #echo "$folder"
             newman run $collection -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
             for folder in "${JUNOS_folders[@]}"
             do
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 2 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="Junos ${coll_arr[@]:0:${ll}} Setup"
                #echo "$sfolder"
                newman run $collection -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (Junos) $sfolder FAILED" >> $file; fi
                #echo "$folder"
                newman run $collection -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (Junos) $folder FAILED" >> $file; fi

                tfolder="Junos ${coll_arr[@]:0:${ll}} Teardown"
                #echo "$tfolder"
                newman run $collection -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing (Junos) $tfolder FAILED" >> $file; fi
                sleep 2
             done
             folder="Junos Unmount"
             #echo "$folder"
             newman run $collection -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing $folder FAILED" >> $file; fi
         fi


done

if [ -f $file ] ; then
    cat $file
    rm $file
fi

## For html and xml ouputs use this:  --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results.xml"  --reporter-html-export "/tmp/Environment_${device}_${folder}_results.html"
## For example:
##    newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results.xml"  --reporter-html-export "/tmp/Environment_${device}_${folder}_results.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then echo "Collection $collection with environment $device testing Classic $folder FAILED" >> $file; fi
