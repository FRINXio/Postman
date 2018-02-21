#!/bin/bash
set +x

collection=postman_collection_unified.json
file=list.txt

if [ -f $file ] ; then
    rm $file
fi

# this is preparation for collecting the results to summary table
file2=list_of_test2
if [ -f $file2 ] ; then
    rm $file2
fi

# function to write result of test
# the first argument $1 is a result 0/1 of last newman execution
# the second argument $2 is a char r/s/ /t which define the postman collection purpose (reader test/setup/main test/teardown)
function test_pass() {
    case "$2" in
      "r")
          echo "${1}Environment_${device}_${folder}_results_readers.xml" >> $file2;;
      "s")
          echo "${1}Environment_${device}_${folder}_results_1_setup.xml" >> $file2;;
      "" | " ")
          echo "${1}Environment_${device}_${folder}_results_2.xml" >> $file2;;
      "t")
          echo "${1}Environment_${device}_${folder}_results_3_teardown.xml" >> $file2;;
    esac
}

# function to write info about failure of test
# the first argument $1 is to specify the device e.g XR/XE/Classis
# the second argument $2 is a char r/s/ /t which define the postman collection purpose (reader test/setup/main test/teardown) 
function test_failure_info() {
  case "$2" in
    "r")
        echo  "Collection $collection with environment $device testing ${1} $rfolder FAILED" >> $file;;
    "s")
        echo  "Collection $collection with environment $device testing ${1} $srfolder FAILED" >> $file;;
    "" | " ")
        echo  "Collection $collection with environment $device testing ${1} $folder FAILED" >> $file;;
    "t")
        echo  "Collection $collection with environment $device testing ${1} $tfolder FAILED" >> $file;;
  esac
}


### Mount unmount test case
devices=("mount_unmount_env.json" "mount_unmount_telnet_env.json" "mount_unmount_ios1553_env.json")
folders=("Mount/Unmount IOS")

for device in ${devices[@]}
do
   echo Collection running with $device
     for folder in "${folders[@]}"
     do
        newman run $collection --bail -e $device -n 2 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; fi
        sleep 5
     done
done


### Test for IOS XR
XR_devices=("xrv_env.json" "asr_env.json" "xrv5_env.json")
#XR_folders=(need fix: "General information" "L2P2P connection CRUD Negative")
XR_folders=("Interface" "Interface IP" "subinterface common CRUD basic" "static route" "CDP" "LLDP" "ospf" "L2P2P connection" "L2P2P connection CRUD locifc-remote" "L2P2P connection CRUD locifc-sub" "L2P2P connection CRUD locsub-remote" "L2VPN connection" "L2VPN connection CRUD locifc-remote" "L2VPN connection CRUD locsub-remote" "BGP summary" "L3VPN OSPF CRUD" "L3VPN BGP" "BGP instance CRUD global" "L3VPN BGP CRUD global" "L3VPN BGP CRUD Negative")
#XR5_folders=(need fix: "General information")
XR5_folders=("subinterface common" "subinterface common CRUD global" "OSPF CRUD" "RSVP CRUD" "Mpls-te CRUD" "Mpls-tunnel CRUD" "SYSLOG CRUD" "LACP CRUD" "LACP IFC CRUD interface" "LACP IFC CRUD element" "IFC ACL CRUD basic" "IFC ACL CRUD containers" "PF IFC CRUD" "ETH IFC CRUD basic" "ETH IFC CRUD subinterface-part" "ETH IFC CRUD holdtime-part" "ETH IFC CRUD damping-part" "ETH IFC CRUD stats-part" "ETH IFC CRUD eth-part" "ETH IFC CRUD subinterface-container" "ETH IFC CRUD holdtime-container" "ETH IFC CRUD damping-container" "ETH IFC CRUD stats-container" "ETH IFC CRUD eth-container" "LAG without-BFD" "LAG without BFD basic" "LAG without BFD aggregation" "LAG without BFD statistics" "LAG without BFD damping" "LAG without BFD ipv4" "SNMP CRUD GigabitEthernet" "SNMP server CRUD GigabitEthernet" "SNMP CRUD LAG" "SNMP server CRUD LAG" "SNMP server CRUD Negative" "BGP CRUD" "BGP instance CRUD basic")
#ASR_folders=(need fix: "General information","5 LAG without BFD"-MU-212 "5 LAG with BFD"-MU-213, "SNMP"-MU-219 "SYSLOG CRUD"-MU-220  )
ASR_folders=("Platform unified" "Interface" "Interface IP" "subinterface common CRUD basic" "static route" "CDP" "LLDP" "ospf" "L2VPN connection" "L2VPN connection CRUD locifc-remote" "L2VPN connection CRUD locsub-remote" "BGP summary" "L3VPN OSPF CRUD" "BGP instance CRUD global" "L3VPN BGP CRUD global" "L3VPN BGP CRUD Negative")

for device in ${XR_devices[@]}
do
   echo Collection running with $device
         if [ "$device" == "xrv_env.json" ]
         then
             folder="XR Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
             for folder in "${XR_folders[@]}"
             do
                rfolder="XR $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then test_failure_info "(XR)" "r"; test_pass "1" "r"; else test_pass "0" "r"; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="XR ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then test_failure_info "(XR)" "s"; test_pass "1" "s"; else test_pass "0" "s"; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(XR)" ""; test_pass "1" ""; else test_pass "0" ""; fi
                tfolder="XR ${coll_arr[@]:0:${ll}} Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then test_failure_info "(XR)" "t"; test_pass "1" "t"; else test_pass "0" "t"; fi
                sleep 2
             done
             folder="XR Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
         fi

         if [ "$device" == "xrv5_env.json" ]
         then
             folder="XR5 Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
             for folder in "${XR5_folders[@]}"
             do
                rfolder="XR5 $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then test_failure_info "(XR5)" "r"; test_pass "1" "r"; else test_pass "0" "r"; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="XR5 ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then test_failure_info "(XR5)" "s"; test_pass "1" "s"; else test_pass "0" "s"; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(XR5)" ""; test_pass "1" ""; else test_pass "0" ""; fi
                tfolder="XR5 ${coll_arr[@]:0:${ll}} Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then test_failure_info "(XR5)" "t"; test_pass "1" "t"; else test_pass "0" "t"; fi
                sleep 2
             done
             folder="XR5 Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
         fi

         if [ "$device" == "asr_env.json" ]
         then
             folder="XR Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(ASR)" ""; test_pass "1" ""; else test_pass "0" ""; fi
             for folder in "${ASR_folders[@]}"
             do
                rfolder="XR $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then test_failure_info "(ASR)" "r"; test_pass "1" "r"; else test_pass "0" "r"; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="XR ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then test_failure_info "(ASR)" "s"; test_pass "1" "s"; else test_pass "0" "s"; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(ASR)" ""; test_pass "1" ""; else test_pass "0" ""; fi
                tfolder="XR ${coll_arr[@]:0:${ll}} Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then test_failure_info "(ASR)" "t"; test_pass "1" "t"; else test_pass "0" "t"; fi
                sleep 2
             done
             folder="XR Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(ASR)" ""; test_pass "1" ""; else test_pass "0" ""; fi
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
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
             for folder in "${Classic_folders[@]}"
             do
                rfolder="Classic $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then test_failure_info "" "r"; test_pass "1" "r"; else test_pass "0" "r"; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="Classic ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then test_failure_info "" "s"; test_pass "1" "s"; else test_pass "0" "s"; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
                tfolder="Classic ${coll_arr[@]:0:${ll}} Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then test_failure_info "" "t"; test_pass "1" "t"; else test_pass "0" "t"; fi
                sleep 2
             done
             folder="Classic Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
         fi

         if [ "$device" == "classic_1553_env.json" ]
         then
             folder="Classic Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
             for folder in "${Classic_folders[@]}"
             do
                rfolder="Classic $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then test_failure_info "" "r"; test_pass "1" "r"; else test_pass "0" "r"; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="Classic ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then test_failure_info "Classic" "s"; test_pass "1" "s"; else test_pass "0" "s"; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; test_pass "1" ""; else test_pass "0" ""; fi
                tfolder="Classic ${coll_arr[@]:0:${ll}} Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then test_failure_info "Classic" "t"; test_pass "1" "t"; else test_pass "0" "t"; fi
                sleep 2
             done
             folder="Classic Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
         fi

         if [ "$device" == "xe_env.json" ]
         then
             folder="Classic Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(XE)" ""; test_pass "1" ""; else test_pass "0" ""; fi
             for folder in "${XE_folders[@]}"
             do
                rfolder="Classic $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then test_failure_info "(XE)" "r"; test_pass "1" "r"; else test_pass "0" "r"; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="Classic ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then test_failure_info "(XE)" "s"; test_pass "1" "s"; else test_pass "0" "s"; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(XE)" ""; test_pass "1" ""; else test_pass "0" ""; fi
                tfolder="Classic ${coll_arr[@]:0:${ll}} Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then test_failure_info "(XE)" "t"; test_pass "1" "t"; else test_pass "0" "t"; fi
                sleep 2
             done
             folder="Classic Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(XE)" ""; test_pass "1" ""; else test_pass "0" ""; fi
         fi

         if [ "$device" == "xe4_env.json" ]
         then
             folder="Classic Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(XE4)" ""; test_pass "1" ""; else test_pass "0" ""; fi
             for folder in "${XE4_folders[@]}"
             do
                rfolder="Classic $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then test_failure_info "(XE4)" "r"; test_pass "1" "r"; else test_pass "0" "r"; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="Classic ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then test_failure_info "(XE4)" "s"; test_pass "1" "s"; else test_pass "0" "s"; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(XE4)" ""; test_pass "1" ""; else test_pass "0" ""; fi
                tfolder="Classic ${coll_arr[@]:0:${ll}} Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then test_failure_info "(XE4)" "t"; test_pass "1" "t"; else test_pass "0" "t"; fi
                sleep 2
             done
             folder="Classic Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(XE4)" ""; test_pass "1" ""; else test_pass "0" ""; fi
         fi

         if [ "$device" == "cat6500_env.json" ]
         then
             folder="Classic Mount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(CAT)" ""; test_pass "1" ""; else test_pass "0" ""; fi
             for folder in "${CAT6500_folders[@]}"
             do
                rfolder="Classic $folder READERS"
                newman run $collection --bail -e $device -n 1 --folder "$rfolder"; if [ "$?" != "0" ]; then test_failure_info "(CAT)" "r"; test_pass "1" "r"; else test_pass "0" "r"; fi
                coll_len=`echo $folder | wc -w`
                coll_arr=($folder)
                ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
                sfolder="Classic ${coll_arr[@]:0:${ll}} Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then test_failure_info "(CAT)" "s"; test_pass "1" "s"; else test_pass "0" "s"; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(CAT)" ""; test_pass "1" ""; else test_pass "0" ""; fi
                tfolder="Classic ${coll_arr[@]:0:${ll}} Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then test_failure_info "(CAT)" "t"; test_pass "1" "t"; else test_pass "0" "t"; fi
                sleep 2
             done
             folder="Classic Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "(CAT)" ""; test_pass "1" ""; else test_pass "0" ""; fi
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
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
             for folder in "${junos_folders[@]}"
             do
                sfolder="Junos $folder Setup"
                newman run $collection --bail -e $device -n 1 --folder "$sfolder"; if [ "$?" != "0" ]; then test_failure_info "" "s"; test_pass "1" "s"; else test_pass "0" "s"; fi
                newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
                tfolder="Junos $folder Teardown"
                newman run $collection --bail -e $device -n 1 --folder "$tfolder"; if [ "$?" != "0" ]; then test_failure_info "" "t"; test_pass "1" "t"; else test_pass "0" "t"; fi
                sleep 2
             done
             folder="Junos Unmount"
             newman run $collection --bail -e $device -n 1 --folder "$folder"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
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
        newman run $collection --bail -e $device -n 1 --folder "Linux"; if [ "$?" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
        sleep 5
     done
done


if [ -f $file ] ; then
    cat $file
    rm $file
fi

## For html and xml ouputs use this:  --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results.xml"  --reporter-html-export "/tmp/Environment_${device}_${folder}_results.html"

## For example:
## newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results.xml"  --reporter-html-export "/tmp/Environment_${device}_${folder}_results.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; fi
## newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results_readers.xml" --reporter-html-export "/tmp/Environment_${device}_${folder}_results_readers.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; fi
## newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results_1_setup.xml" --reporter-html-export "/tmp/Environment_${device}_${folder}_results_1_setup.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; fi
## newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results_2.xml" --reporter-html-export "/tmp/Environment_${device}_${folder}_results_2.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; fi
##newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results_3_teardown.xml" --reporter-html-export "/tmp/Environment_${device}_${folder}_results_3_teardown.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; fi
##newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results.xml" --reporter-html-export "/tmp/Environment_${device}_${folder}_results.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; fi

# results of tests were collected to the file $file2
# one result on one row in the form "0Environment_${device}_${folder}_results_2.xml" when test passed
# one result on one row in the form "1Environment_${device}_${folder}_results_2.xml" when test failed
# this python script will proccess the results into html table
python3 - $file2 <<'____HERE'
import sys
from collections import defaultdict
# we use dictionary structure for storing summary table
matrix_dict = defaultdict(dict)
#g = []
# opening of file with results
with open(sys.argv[1]) as f:
    # reading file line after line
    for i in f:
        #print(i[-5:-1], i)
        # only main test will be processed - the results of reader tests, setup tests and teardown tests are not processed
        if i[-6:-1] == '2.xml':
            #g.append(i)
            # finding possition of environment file
            a = i.find('_env.json') + 9
            #print(i[12:a - 9])
            #print(i[a + 1:-6])
            # extracting environment file
            env = i[13:a - 9]
            # extracting the name of test
            tst = i[a + 1:-6-9]
            # storing the result of test to dictionary structure
            matrix_dict[tst][env] = i[0]
            #print(i[0],i)


## this is to select unique set of devices and of tests to the list structures and to alphabetically sort them
testy = []
devices = []
for kw1 in matrix_dict:
    if kw1 not in testy:
        testy.append(kw1)
    for kw2 in matrix_dict[kw1]:
        if kw2 not in devices:
            devices.append(kw2)
        #print(kw1,kw2,matrix_dict[kw1][kw2])
testy.sort()
devices.sort()


## this will construct HTML TABLE with results taken from dictiomary structure
tabulka = '<table border="1">'
tabulka = tabulka + '<tr><td/>'
for stlpec in devices:
    tabulka = tabulka + '<td style="writing-mode: vertical-rl;">' + stlpec + '</td>'

tabulka = tabulka + '</tr>'
for riadok in testy:
    tabulka = tabulka + '<tr><td>' + riadok + '</td>'
    for stlpec in devices:
        try:
            if matrix_dict[riadok][stlpec] == '1':
                tabulka = tabulka + '<td style="color:red;">' + 'fail' + '</td>'
            else:
                tabulka = tabulka + '<td  style="color:green;">' + 'pass' + '</td>'
        except KeyError:
            tabulka = tabulka + '<td></td>'
    tabulka = tabulka + '</tr>'

tabulka = tabulka + '</table>'


## this is to store TABLE to HTML file
f = open( 'tbl.html', 'w' )
f.write( tabulka )
f.close()
____HERE
