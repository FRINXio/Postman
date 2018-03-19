#!/bin/bash
set +x

collection=postman_collection_unified.json

#https://superuser.com/questions/352697/preserve-colors-while-piping-to-tee
command -v unbuffer >/dev/null 2>&1 || { echo >&2 "It's not installed *unbuffer* script. Please install it: sudo apt-get install expect-dev"; exit 1; }

file=list.txt # list of failed tests
if [ -f $file ] ; then
    rm $file
fi

# this is preparation for collecting the results to summary table
file2=list_of_test2 # list of tests with their results
if [ -f $file2 ] ; then
    rm $file2
fi

# function to write result of test
# the first argument $1 is a result 0/1 of last newman execution (note: newman returs 0 also in case that all tests in folder have not any assertions! Solution is write some assertions.)
# the second argument $2 is a char r/s/ /t which define the postman collection purpose (reader test/setup/main test/teardown)
function test_pass() {
    #here process file folder_presence_check to prevent to make false entry to the file $file2
    number_of_tests=`grep -o " 0 " folder_presence_check | wc -l`
    if [ $number_of_tests -eq 10 ]
    then
        #this indicate that no test was found in folder or folder does not exists
        #│              iterations │        0 │        0 │
        #│                requests │        0 │        0 │
        #│            test-scripts │        0 │        0 │
        #│      prerequest-scripts │        0 │        0 │
        #│              assertions │        0 │        0 │
        # at the beginning of record there is number 9 to indicate that there was attempt to run test over empty folder
        case "$2" in
           "r")
               echo "9Environment_${device}_${folder}_results_readers.xml" >> $file2;;
           "s")
               echo "9Environment_${device}_${folder}_results_1_setup.xml" >> $file2;;
           "" | " ")
               echo "9Environment_${device}_${folder}_results_2.xml" >> $file2;;
           "t")
               echo "9Environment_${device}_${folder}_results_3_teardown.xml" >> $file2;;
        esac
    else
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
     fi
}


# function to write info about failure of test
# the first argument $1 is to specify the device e.g XR/XE/Classis
# the second argument $2 is a char r/s/ /t which define the postman collection purpose (reader test/setup/main test/teardown)
function test_failure_info() {
   case "$2" in
    "r")
        echo  "Collection $collection with environment $device testing ${1} $rfolder FAILED" >> $file;;
    "s")
        echo  "Collection $collection with environment $device testing ${1} $sfolder FAILED" >> $file;;
    "" | " ")
        echo  "Collection $collection with environment $device testing ${1} $folder FAILED" >> $file;;
    "t")
        echo  "Collection $collection with environment $device testing ${1} $tfolder FAILED" >> $file;;
  esac
}


# complex function for calling newman instances (reader tests - setup - main test - teardown) over the list of tests
# in the funnction are used these variables usually defined before calling of the function:
# - mount folder
# - $collection
# - $formatter_bail   --bail --formatters ....
# - $device
# - $list_of_tests list of folders -> $folder
# - $device_folder_string rfolder modifiers
# - $device_id_string device specific string for test_failure_info
# - $unmount_folder unmount folder
#
# it was added unbuffer script before newman command redirected via tee command
# to preserve colloring of output
function newman_stuff {
  # https://stackoverflow.com/questions/6871859/piping-command-output-to-tee-but-also-save-exit-code-of-command
  # testing of newman output status was done via variable $?
  # using tee - in variable $? is stored the succees of tee - output of newman will be stored in ${PIPESTATUS[0]}
  folder=$mount_folder
  # in case that mount does not happen we will return from this function because it is useless to try to run all list of tests ...
  unbuffer newman run $collection $formatter_bail -e $device -n 1 --folder "$folder" | tee folder_presence_check; if [ "${PIPESTATUS[0]}" != "0" ]; then test_failure_info "" ""; test_pass "1" "";return; else test_pass "0" ""; fi
  for folder in "${list_of_tests[@]}"
  do
     rfolder="$device_folder_string $folder READERS"
     newman run $collection $formatter_bail -e $device -n 1 --folder "$rfolder" | tee folder_presence_check; if [ "${PIPESTATUS[0]}" != "0" ]; then test_failure_info "$device_id_string" "r"; test_pass "1" "r"; else test_pass "0" "r"; fi
     coll_len=`echo $folder | wc -w`
     coll_arr=($folder)
     ll=`if [ $coll_len -gt 3 ]; then le=$(($coll_len-1)); echo $le; else echo $coll_len;fi`
     sfolder="$device_folder_string ${coll_arr[@]:0:${ll}} Setup"
     unbuffer newman run $collection $formatter_bail -e $device -n 1 --folder "$sfolder" | tee folder_presence_check; if [ "${PIPESTATUS[0]}" != "0" ]; then test_failure_info "$device_id_string" "s"; test_pass "1" "s"; else test_pass "0" "s"; fi
     unbuffer newman run $collection $formatter_bail -e $device -n 1 --folder "$folder" | tee folder_presence_check; if [ "${PIPESTATUS[0]}" != "0" ]; then test_failure_info "$device_id_string" ""; test_pass "1" ""; else test_pass "0" ""; fi
     tfolder="$device_folder_string ${coll_arr[@]:0:${ll}} Teardown"
     unbuffer newman run $collection $formatter_bail -e $device -n 1 --folder "$tfolder" | tee folder_presence_check; if [ "${PIPESTATUS[0]}" != "0" ]; then test_failure_info "$device_id_string" "t"; test_pass "1" "t"; else test_pass "0" "t"; fi
     sleep 2
  done
  folder=$unmount_folder
  unbuffer newman run $collection $formatter_bail -e $device -n 1 --folder "$folder" | tee folder_presence_check; if [ "${PIPESTATUS[0]}" != "0" ]; then test_failure_info "" ""; test_pass "1" ""; else test_pass "0" ""; fi
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
XR_folders=("Interface CRUD" "subinterface common" "subinterface common CRUD basic" "static route" "CDP" "LLDP" "ospf" "L2P2P connection" "L2P2P connection CRUD locifc-remote" "L2P2P connection CRUD locifc-sub" "L2P2P connection CRUD locsub-remote" "L2VPN connection" "L2VPN connection CRUD locifc-remote" "L2VPN connection CRUD locsub-remote" "BGP summary" "L3VPN OSPF CRUD" "L3VPN BGP" "BGP instance CRUD global" "L3VPN BGP CRUD global" "L3VPN BGP CRUD Negative")
#XR5_folders=(need fix: "General information")
XR5_folders=("subinterface common" "subinterface common CRUD global" "OSPF CRUD" "RSVP CRUD" "Mpls-te CRUD" "Mpls-tunnel CRUD" "SYSLOG CRUD" "LACP CRUD" "LACP IFC CRUD interface" "LACP IFC CRUD element" "IFC ACL CRUD basic" "IFC ACL CRUD containers" "PF IFC CRUD" "ETH IFC" "ETH IFC CRUD basic" "ETH IFC CRUD subinterface-part" "ETH IFC CRUD holdtime-part" "ETH IFC CRUD damping-part" "ETH IFC CRUD stats-part" "ETH IFC CRUD eth-part" "ETH IFC CRUD subinterface-container" "ETH IFC CRUD holdtime-container" "ETH IFC CRUD damping-container" "ETH IFC CRUD stats-container" "ETH IFC CRUD eth-container" "LAG without-BFD" "LAG without BFD basic" "LAG without BFD aggregation" "LAG without BFD statistics" "LAG without BFD damping" "LAG without BFD ipv4" "SNMP CRUD GigabitEthernet" "SNMP server CRUD GigabitEthernet" "SNMP CRUD LAG" "SNMP server CRUD LAG" "SNMP server CRUD Negative" "BGP CRUD" "BGP instance CRUD basic")
#ASR_folders=(need fix: "General information","5 LAG without BFD"-MU-212 "5 LAG with BFD"-MU-213, "SNMP"-MU-219 "SYSLOG CRUD"-MU-220  )
ASR_folders=("Platform unified" "Interface CRUD" "subinterface common" "subinterface common CRUD basic" "static route" "CDP" "LLDP" "ospf" "L2VPN connection" "L2VPN connection CRUD locifc-remote" "L2VPN connection CRUD locsub-remote" "BGP summary" "L3VPN OSPF CRUD" "BGP instance CRUD global" "L3VPN BGP CRUD global" "L3VPN BGP CRUD Negative")

### Test for IOS
IOS_devices=("classic_152_env.json" "classic_1553_env.json" "xe_env.json" "xe4_env.json" "cat6500_env.json")
#Classic_folders=(need fix:"General information" "L2P2P connection CRUD Negative")
Classic_folders=("Interface" "static route" "journal-dryrun" "CDP" "subinterface common" "subinterface common CRUD global" "L2P2P connection" "L2P2P connection CRUD locifc-remote" "L2P2P connection CRUD locifc-sub" "L2P2P connection CRUD locsub-remote" "ospf-vrf" "L3VPN OSPF CRUD" "BGP summary" "L3VPN BGP" "BGP instance CRUD global" "L3VPN BGP CRUD global" "L3VPN BGP CRUD Negative" )
#XE_folders=(need fix: "General information" ,"ospf-vrf"-bug MU-159,)
XE_folders=("Interface"  "static route"  "journal-dryrun" "CDP" "LLDP" "subinterface common" "subinterface common CRUD global" "ospf-vrf" "L3VPN OSPF CRUD"  "BGP summary" "L3VPN BGP" "BGP instance CRUD global" "L3VPN BGP CRUD global" "L3VPN BGP CRUD Negative")
XE4_folders=("L2VPN connection" "L2VPN connection CRUD locifc-remote" "L2VPN connection CRUD locsub-remote")
CAT6500_folders=("Platform cli")

### Test for Junos
junos_devices=("junos_env.json")
junos_folders=()
junos_devices=()

# Here in the variable chosen_devices are default concatenated all devices which are routinelly run
# https://www.thegeekstuff.com/2010/06/bash-array-tutorial - explained concatenate arrays and copying arrays
chosen_devices=("${XR_devices[@]}" "${IOS_devices[@]}" "${junos_devices[@]}") # concatenate arrays
# you can ad hoc redefine chosen_devices like this
#chosen_devices=("classic_152_env.json" "cat6500_env.json" "xrv_env.json" "classic_1553_env.json")

# https://stackoverflow.com/questions/8880603/loop-through-an-array-of-strings-in-bash
for device in ${chosen_devices[@]}
do
  # common settings - used for all devices
  formatter_bail="--bail"
  # device specific settings
  case "$device" in
    ####################################
    "xrv_env.json" )
        mount_folder="XR Mount"
        device_id_string="(XR)" # present in texts
        device_folder_string="XR" # present in rfolder/sfolder/tfolder
        list_of_tests=("${XR_folders[@]}") # copying of array
        unmount_folder="XR Unmount"
        ;;
    "xrv5_env.json" )
        mount_folder="XR5 Mount"
        device_id_string="(XR5)" # present in texts
        device_folder_string="XR5" # present in rfolder/sfolder/tfolder
        list_of_tests=("${XR5_folders[@]}") # copying of array
        unmount_folder="XR5 Unmount"
        ;;
    "asr_env.json" )
        mount_folder="XR Mount"
        device_id_string="(ASR)" # present in texts
        device_folder_string="XR" # present in rfolder/sfolder/tfolder
        list_of_tests=("${ASR_folders[@]}") # copying of array
        unmount_folder="XR Unmount"
        ;;
    ####################################
    "classic_152_env.json" )
        mount_folder="Classic Mount"
        device_id_string="" # present in texts
        device_folder_string="Classic" # present in rfolder/sfolder/tfolder
        list_of_tests=("${Classic_folders[@]}") # copying of array
        unmount_folder="Classic Unmount"
        ;;
    "classic_1553_env.json" )
        mount_folder="Classic Mount"
        device_id_string="(Classic)" # present in texts
        device_folder_string="Classic" # present in rfolder/sfolder/tfolder
        list_of_tests=("${Classic_folders[@]}") # copying of array
        unmount_folder="Classic Unmount"
        ;;
    "xe_env.json" )
        mount_folder="Classic Mount"
        device_id_string="(XE)" # present in texts
        device_folder_string="Classic" # present in rfolder/sfolder/tfolder
        list_of_tests=("${XE_folders[@]}") # copying of array
        unmount_folder="Classic Unmount"
        ;;
    "xe4_env.json" )
        mount_folder="Classic Mount"
        device_id_string="(XE4)" # present in texts
        device_folder_string="Classic" # present in rfolder/sfolder/tfolder
        list_of_tests=("${XE4_folders[@]}") # copying of array
        unmount_folder="Classic Unmount"
        ;;
    "cat6500_env.json" )
        mount_folder="Classic Mount"
        device_id_string="(CAT)" # present in texts
        device_folder_string="Classic" # present in rfolder/sfolder/tfolder
        list_of_tests=("${CAT6500_folders[@]}") # copying of array
        unmount_folder="Classic Unmount"
        ;;
    ####################################
    "junos_env.json" )
        mount_folder="Junos Mount"
        device_id_string="" # present in texts
        device_folder_string="Junos" # present in rfolder/sfolder/tfolder
        list_of_tests=("${junos_folders[@]}") # copying of array
        unmount_folder="Junos Unmount"
        ;;
  esac

  if [ -f $device ] ; then
      echo Collection running with $device
      newman_stuff # calling function
  else
      echo "The environment file $device does not exist - collection IS NOT RUN" >> $file
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

if [ -f folder_presence_check ] ; then
    rm folder_presence_check
fi


## For html and xml ouputs use this:  --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results.xml"  --reporter-html-export "/tmp/Environment_${device}_${folder}_results.html"
## For example:
## newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results.xml"  --reporter-html-export "/tmp/Environment_${device}_${folder}_results.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; fi
## newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results_readers.xml" --reporter-html-export "/tmp/Environment_${device}_${folder}_results_readers.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; fi
## newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results_1_setup.xml" --reporter-html-export "/tmp/Environment_${device}_${folder}_results_1_setup.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; fi
## newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results_2.xml" --reporter-html-export "/tmp/Environment_${device}_${folder}_results_2.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; fi
##newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results_3_teardown.xml" --reporter-html-export "/tmp/Environment_${device}_${folder}_results_3_teardown.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; fi
##newman run $collection --reporters html,cli,junit  --reporter-junit-export "/tmp/Environment_${device}_${folder}_results.xml" --reporter-html-export "/tmp/Environment_${device}_${folder}_results.html" --bail -e $device -n 1 --folder "Classic $folder"; if [ "$?" != "0" ]; then test_failure_info "Classic" ""; fi


if ! [ -f "$file2" ] ; then
    exit
fi
echo "Running python script to prepare summary table tbl.html..."
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
        # all tests will be processed - the results of reader tests, setup tests and teardown tests
        # readers
        if i[-6+1-7:-1] == 'readers.xml':
            #g.append(i)
            # finding possition of environment file
            a = i.find('_env.json') + 9
            #print(i[12:a - 9])
            #print(i[a + 1:-6])
            # extracting environment file
            env = i[13:a - 9]
            # extracting the name of test
            tst = i[a + 1:-6-9+1-7]
            # storing the result of test to dictionary structure
            matrix_dict[tst][env + " 0:r"] = i[0]
            #print(i[0],i)
        # setups
        if i[-6-6:-1] == '1_setup.xml':
            #g.append(i)
            # finding possition of environment file
            a = i.find('_env.json') + 9
            #print(i[12:a - 9])
            #print(i[a + 1:-6])
            # extracting environment file
            env = i[13:a - 9]
            # extracting the name of test
            tst = i[a + 1:-6-9-6]
            # storing the result of test to dictionary structure
            matrix_dict[tst][env + " 1:s"] = i[0]
            #print(i[0],i)
        # main tests
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
            matrix_dict[tst][env + " 2:m"] = i[0]
            #print(i[0],i)
        # teardown tests
        if i[-6-9:-1] == '3_teardown.xml':
            #g.append(i)
            # finding possition of environment file
            a = i.find('_env.json') + 9
            #print(i[12:a - 9])
            #print(i[a + 1:-6])
            # extracting environment file
            env = i[13:a - 9]
            # extracting the name of test
            tst = i[a + 1:-6-9-9]
            # storing the result of test to dictionary structure
            matrix_dict[tst][env + " 3:t"] = i[0]
            #print(i[0],i)


## this is to select unique set of devices and of tests to the list structures and to alphabetically sort them
testy = []
devices = []
for kw1 in matrix_dict:
    if kw1 not in testy:
        if kw1 not in ('Classic Mount' 'Classic Unmount' 'XR Mount' 'XR Unmount'):
            testy.append(kw1)
    for kw2 in matrix_dict[kw1]:
        if kw2 not in devices:
            if (kw2[-4:] == ' 2:m') and (kw2[0:-4] not in devices):
                devices.append(kw2[0:-4])
        #print(kw1,kw2,matrix_dict[kw1][kw2])
testy.sort()
devices.sort()


## this will construct HTML TABLE with results taken from dictiomary structure
tabulka = '<h1>Summary table</h1>'
tabulka = tabulka + '<table border="1">'
tabulka = tabulka + '<tr><td/>'
for stlpec in devices:
    tabulka = tabulka + '<td style="writing-mode: vertical-rl;">' + stlpec + '</td>'

tabulka = tabulka + '</tr>'
for riadok in testy:
    tabulka = tabulka + '<tr><td>' + riadok + '</td>'
    for stlpec in devices:
        #print(stlpec)

        # reader
        try:
            if matrix_dict[riadok][stlpec + ' 0:r'] == '1':
                tabulka = tabulka + '<td><span style="color:red;">' + 'fail' + '</span><br/>'
            elif matrix_dict[riadok][stlpec + ' 0:r'] == '0':
                tabulka = tabulka + '<td><span style="color:green;">' + 'pass' + '</span><br/>'
            elif matrix_dict[riadok][stlpec + ' 0:r'] == '9':
                tabulka = tabulka + '<td><span>' + 'null' + '</span><br/>'
            else:
                tabulka = tabulka + '<td><span>' + '????' + '</span><br/>'
        except KeyError:
            tabulka = tabulka + '<td>&nbsp;<br/>'

        # CRUD (or main test ...)
        try:
            if matrix_dict[riadok][stlpec + ' 2:m'] == '1':
                tabulka = tabulka + '<span style="color:red;">' + 'fail' + '</span></td>'
            elif matrix_dict[riadok][stlpec + ' 2:m'] == '0':
                tabulka = tabulka + '<span style="color:green;">' + 'pass' + '</span></td>'
            elif matrix_dict[riadok][stlpec + ' 2:m'] == '9':
                tabulka = tabulka + '<span>' + 'null' + '</span></td>'
            else:
                tabulka = tabulka + '<span>' + '????' + '</span></td>'
        except KeyError:
            tabulka = tabulka + '&nbsp;</td>'

    tabulka = tabulka + '</tr>'

tabulka = tabulka + '</table>'
#tabulka = tabulka + '<hr/>'
#tabulka = tabulka + 'Explanatory notes:<br/>'
#tabulka = tabulka + '0:r - readers test / 1:s - setup test / 2:m - main test / 3:t - teardown test'

## this is to store TABLE to HTML file
f = open( 'tbl.html', 'w' )
f.write( tabulka )
f.close()
____HERE

if [ -f $file2 ] ; then
    rm $file2
fi

echo "The results of all test are summarized in the table tbl.html..."
