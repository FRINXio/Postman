#!/bin/bash

# Usage:
# ./test_scale.sh NODES_TO_CONFIGURE CONTROLLER_IP IOU1 IOU2 ...
#
# When NODES_TO_CONFIGURE=0 the configuration process goes until the first
# problems with setup connections

set -x

env_template_file="iou_scale_env_tmpl.json"
router_mount_folder="IOU Mount"
router_unmount_folder="IOU Unmount"
collection_file="postman_collection_scale.json"

max_devices_configured=$1
odl_ip_address=$2
iou_device_ips=(${@:3})
collection=postman_collection_scale.json
env_templ=iou_scale_env_tmpl.json
node_prefix="tested_node_"
nr_ious=${#iou_device_ips[@]}

echo "Input parameters:"
if [ $max_devices_configured -eq 0 ]; then
  echo "Nodes to be configured: max possible"
else
  echo "Nodes to be configured: $max_devices_configured"
fi
echo "Number of IOUs: $nr_ious"
echo "IOU device ips: ${iou_device_ips[@]}"
echo "Controller IP: $odl_ip_address"

sufix_msg_part="(out of $max_devices_configured)"
if [ $max_devices_configured -eq 0 ]; then
  sufix_msg_part="(continue infinitelly)"
fi

# Configuration part
i=0
mounted_peer_devices=0
for (( ; ; ))
do

   iou_idx_used=$(( $i % $nr_ious ))
   router_ip=${iou_device_ips[${iou_idx_used}]}
   ((i++))
   node_name=$node_prefix$i
   echo "Configuring router $router_ip as $node_name $sufix_msg_part"
 
   # copy env template file and fill with correct values
   env_file_name=iou_scale_env_$node_name.json
   cp $env_template_file $env_file_name
   sed -i "s/ODL_IP/$odl_ip_address/g" $env_file_name
   sed -i "s/NODE_NAME/$node_name/g" $env_file_name
   sed -i "s/NODE_IP/$router_ip/g" $env_file_name

   newman run $collection_file --bail -e $env_file_name -n 1 --folder "$router_mount_folder"
   nrc=$?
   echo "Newman return code $nrc"

   rm $env_file_name

   # let's break if miounting a node failed 
   if [ $nrc -ne 0 ]; then
     break
   fi
   mounted_peer_devices=$i

   # do not break the loop if unlimited nodes to be configured 
   if [ $max_devices_configured -eq 0 ]; then
     continue
   fi

   # check for nodes configured
   if [ $i -ge $max_devices_configured ]; then
       break
   fi
done

configured_peer_devices=$i
echo "Mounted devices: $mounted_peer_devices"
echo "Mounted_devices" > ./mounted_devices.csv
echo "$mounted_peer_devices" >> ./mounted_devices.csv

# Deconfiguration part missing for now
for (( i=1; i <= $configured_peer_devices; i++ ))
do
   node_name=$node_prefix$i
   echo "Deconfiguring router $node_name"

   # copy env template file and fill with correct values
   env_file_name=iou_scale_env_$node_name.json
   cp $env_template_file $env_file_name
   sed -i "s/ODL_IP/$odl_ip_address/g" $env_file_name
   sed -i "s/NODE_NAME/$node_name/g" $env_file_name

   newman run $collection_file --bail -e $env_file_name -n 1 --folder "$router_unmount_folder"
   echo "Deconfigure newman rc: $?"

   rm $env_file_name

done
