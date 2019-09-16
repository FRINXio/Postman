#!/bin/bash
# This script allows to run daexim test
# to run it:
# ./test_daexim.sh env_file collection_file odl_ip logfile stream
# stream: [carbon, oxygen]

#set -exu
set +x

env_file=$1
collection_file=$2
odl_ip=$3
logfile=$4
stream=$5


rm_file () {
    local _file=$1
    if [ -f $_file ] ; then
	rm $_file
    fi
}

run_folder () {
    local _collection_file=$1
    local _env_file=$2
    local _folder=$3
    local _odl_ip=$4
    local _file=$5

    local _test_id="collection: $_collection_file folder: $_folder"
    echo $_test_id
    unbuffer newman run "$_collection_file" -e "$_env_file" --bail folder -n 1 --folder "$_folder" --env-var "odl_ip=$_odl_ip" --reporters cli,junit --reporter-junit-export "./junit_results/$_folder.xml"; if [ "$?" != "0" ]; then echo "$_test_id FAILED" >> $_file; fi
}


kill_and_get_log () {
    local _odl_ip=$1
    local _test=$2
    echo "Getting karaf.logs from odl vm: ${_odl_ip}"
    sleep 30

    echo "Killing karaf"
    ssh  vagrant@${_odl_ip} -i $WORKSPACE/scripts-repo/releng/sshkeysforlab/.ssh/id_rsa -o StrictHostKeyChecking=no killall java
    sleep 10  #sleep to wait for karaf not to write any more into karaf.log

    echo "Compressing karaf.log ${_odl_ip}"
    ssh  vagrant@${_odl_ip} -i $WORKSPACE/scripts-repo/releng/sshkeysforlab/.ssh/id_rsa -o \
    StrictHostKeyChecking=no tar -zcvf "${KARAF_INSTALLDIR}/${BUNDLEFOLDER}/${_test}_karaf.log.tar.gz" -C "${KARAF_INSTALLDIR}/${BUNDLEFOLDER}/data/" "log/"

    echo "Fetching compressed karaf.log ${_odl_ip}"
    scp -i $WORKSPACE/scripts-repo/releng/sshkeysforlab/.ssh/id_rsa "vagrant@${_odl_ip}:${KARAF_INSTALLDIR}/${BUNDLEFOLDER}/${_test}_karaf.log.tar.gz" "$WORKSPACE/${_test}_karaf.log.tar.gz" || true

}


check_odl_backup_created () {
    local _odl_ip=$1
    local _test_id=$2
    local _file=$3

    echo "Check odl backup created"

    if ssh  vagrant@${_odl_ip} -i $WORKSPACE/scripts-repo/releng/sshkeysforlab/.ssh/id_rsa -o StrictHostKeyChecking=no "test -d ${KARAF_INSTALLDIR}/${BUNDLEFOLDER}/daexim"; then
      echo "Backup exists"
    else
      echo "Backup NOT exists"
      echo "$_test_id FAILED" >> $_file
    fi

}


clean_karaf () {
    local _odl_ip=$1

    echo "Cleaning karaf"
    ssh  vagrant@${_odl_ip} -i $WORKSPACE/scripts-repo/releng/sshkeysforlab/.ssh/id_rsa -o StrictHostKeyChecking=no rm -rf "${KARAF_INSTALLDIR}/${BUNDLEFOLDER}/journal" "${KARAF_INSTALLDIR}/${BUNDLEFOLDER}/snapshots"

}


set_daexim_flag () {
    local _odl_ip=$1

    echo "Set daexim flag"
    ssh  vagrant@${_odl_ip} -i $WORKSPACE/scripts-repo/releng/sshkeysforlab/.ssh/id_rsa -o StrictHostKeyChecking=no "echo 'daexim.importOnInit=true' > ${KARAF_INSTALLDIR}/${BUNDLEFOLDER}/etc/org.opendaylight.daexim.cfg"

    echo "Show daexim flag"
    ssh  vagrant@${_odl_ip} -i $WORKSPACE/scripts-repo/releng/sshkeysforlab/.ssh/id_rsa -o StrictHostKeyChecking=no cat ${KARAF_INSTALLDIR}/${BUNDLEFOLDER}/etc/org.opendaylight.daexim.cfg

}


rm_daexim_config_file () {
    local _odl_ip=$1

    echo "Remove daexim config file"
    ssh  vagrant@${_odl_ip} -i $WORKSPACE/scripts-repo/releng/sshkeysforlab/.ssh/id_rsa -o StrictHostKeyChecking=no "rm ${KARAF_INSTALLDIR}/${BUNDLEFOLDER}/etc/org.opendaylight.daexim.cfg"

}


rm_daexim_folder () {
    local _odl_ip=$1

    echo "Remove daexim folder"
    ssh  vagrant@${_odl_ip} -i $WORKSPACE/scripts-repo/releng/sshkeysforlab/.ssh/id_rsa -o StrictHostKeyChecking=no "rm -r ${KARAF_INSTALLDIR}/${BUNDLEFOLDER}/daexim"

}


start_karaf () {
    local _odl_ip=$1

    echo "Start karaf"
    ssh  vagrant@${_odl_ip} -i $WORKSPACE/scripts-repo/releng/sshkeysforlab/.ssh/id_rsa -o StrictHostKeyChecking=no nohup ${KARAF_INSTALLDIR}/${BUNDLEFOLDER}/bin/start


}




change_karaf_features () {
    local _odl_ip=$1
    local _features=$2
    local features_file="${KARAF_INSTALLDIR}/${BUNDLEFOLDER}/etc/org.apache.karaf.features.cfg"

    echo "Change karaf features in config file: "
    ssh  vagrant@${_odl_ip} -i $WORKSPACE/scripts-repo/releng/sshkeysforlab/.ssh/id_rsa -o StrictHostKeyChecking=no "sed -i \"s/\(odlFeaturesBoot=odl-netconf-topology\).*/\1,${_features}/\" $features_file"

    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "Show updated karaf features config file: "
    ssh  vagrant@${_odl_ip} -i $WORKSPACE/scripts-repo/releng/sshkeysforlab/.ssh/id_rsa -o StrictHostKeyChecking=no "cat $features_file"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}






rm_file "$logfile"
touch $logfile

mkdir -p junit_results



if [ "$stream" == "oxygen" ]
then
    echo "Executing test for oxygen"

    echo "############################################################################"
    ##  test_case_1
    # start odl with uniconfig features
    folder="daexim_uniconfig_simple_export"
    echo "######### test_case_1: $folder"

    # run postman collection with mount R1, R2, simple export
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # check if there is content in the two odl backup files
    check_odl_backup_created "$odl_ip" "$folder" "$logfile"

    # clean karaf
    clean_karaf "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    # test_case_2
    #  import from scratch
    folder="daexim_uniconfig_import_from_scratch"
    echo "######### test_case_2: $folder"

    # set flag in configuration
    set_daexim_flag "$odl_ip"

    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    cd $WORKSPACE/scripts-repo/scripts/; ./check_uniconfig_ready.sh $odl_ip uniconfig
    cd -;

    # run postman collection to check if is imported
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # rm daexim config file
    rm_daexim_config_file "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    # test_case_3
    #  immediate import
    folder="daexim_uniconfig_immediate_import"
    echo "######### test_case_3: $folder"

    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    cd $WORKSPACE/scripts-repo/scripts/; ./check_uniconfig_ready.sh $odl_ip uniconfig
    cd -;

    # run postman collection to check if is imported
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # rm daexim folder
    rm_daexim_folder "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    # test_case_4  whitelist uniconfig all nodes
    #   export
    folder="daexim_uniconfig_whitelist_all_nodes_export"
    echo "######### test_case_4 export: $folder"
    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    cd $WORKSPACE/scripts-repo/scripts/; ./check_uniconfig_ready.sh $odl_ip uniconfig
    cd -;

    # run postman collection to export
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    #   import
    folder="daexim_uniconfig_whitelist_all_nodes_import"
    echo "######### test_case_4 import: $folder"
    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    cd $WORKSPACE/scripts-repo/scripts/; ./check_uniconfig_ready.sh $odl_ip uniconfig
    cd -;

    # run postman collection to import
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # rm daexim folder
    rm_daexim_folder "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    # test_case_5  whitelist uniconfig one node
    #   export
    folder="daexim_uniconfig_whitelist_one_node_export"
    echo "######### test_case_5 export: $folder"

    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    cd $WORKSPACE/scripts-repo/scripts/; ./check_uniconfig_ready.sh $odl_ip uniconfig
    cd -;

    # run postman collection to export
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    #   import
    folder="daexim_uniconfig_whitelist_one_node_import"
    echo "######### test_case_5 import: $folder"
    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    cd $WORKSPACE/scripts-repo/scripts/; ./check_uniconfig_ready.sh $odl_ip uniconfig
    cd -;

    # run postman collection to export
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # rm daexim folder
    rm_daexim_folder "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    # test_case_6  whitelist unative all nodes
    #   export whitelist
    folder="daexim_unative_whitelist_all_nodes_export"
    echo "######### test_case_6 export: $folder"

    # change karaf features from uniconfig to unative
    change_karaf_features "$odl_ip" "${KARAF_UNATIVE_FEATURES}"

    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    cd $WORKSPACE/scripts-repo/scripts/; ./check_uniconfig_ready.sh $odl_ip unative
    cd -;

    # run postman collection to export
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    #    import 1: just run odl and install unative features
    #   import whitelist
    folder="daexim_unative_whitelist_all_nodes_import_with_features"
    echo "######### test_case_6 import: $folder"
    # change karaf features from uniconfig to unative
    change_karaf_features "$odl_ip" "${KARAF_UNATIVE_FEATURES}"

    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    cd $WORKSPACE/scripts-repo/scripts/; ./check_uniconfig_ready.sh $odl_ip unative
    cd -;

    # run postman collection to export
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    #    import 2: don't install features and run command
    #   import whitelist
    folder="daexim_unative_whitelist_all_nodes_import"
    echo "######### test_case_6 import: $folder"
    # change karaf features from uniconfig to unative
    # for this test do not install features
    change_karaf_features "$odl_ip" ""

    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    # in this case no features are installed
    # just wait a while to have karaf ready
    sleep 120

    # run postman collection to export
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # rm daexim folder
    rm_daexim_folder "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30



    echo "############################################################################"
    # test_case_7  whitelist unative one node
    #   export whitelist
    folder="daexim_unative_whitelist_one_node_export"
    echo "######### test_case_7 export: $folder"

    # change karaf features from uniconfig to unative
    change_karaf_features "$odl_ip" "${KARAF_UNATIVE_FEATURES}"

    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    cd $WORKSPACE/scripts-repo/scripts/; ./check_uniconfig_ready.sh $odl_ip unative
    cd -;

    # run postman collection to export
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    #    import 1: just run odl and install unative features
    #   import whitelist
    folder="daexim_unative_whitelist_one_node_import_with_features"
    echo "######### test_case_7 import: $folder"
    # change karaf features from uniconfig to unative
    change_karaf_features "$odl_ip" "${KARAF_UNATIVE_FEATURES}"

    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    cd $WORKSPACE/scripts-repo/scripts/; ./check_uniconfig_ready.sh $odl_ip unative
    cd -;

    # run postman collection to export
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    #    import 2: don't install features and run commant
    #   import whitelist
    folder="daexim_unative_whitelist_one_node_import"
    echo "######### test_case_7 import: $folder"
    # change karaf features from uniconfig to unative
    # for this test do not install features
    change_karaf_features "$odl_ip" ""

    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    # in this case no features are installed
    # just wait a while to have karaf ready
    sleep 120

    # run postman collection to export
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30

elif [ "$stream" == "carbon" ]
then

    echo "Executing test for carbon"

    echo "############################################################################"
    ##  test_case_1
    # start odl with uniconfig features
    folder="daexim_uniconfig_simple_export"
    echo "######### test_case_1: $folder"

    # run postman collection with mount R1, R2, simple export
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # check if there is content in the two odl backup files
    check_odl_backup_created "$odl_ip" "$folder" "$logfile"

    # clean karaf
    clean_karaf "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    # test_case_2
    #  import from scratch
    folder="daexim_uniconfig_import_from_scratch_carbon"
    echo "######### test_case_2: $folder"

    # set flag in configuration
    set_daexim_flag "$odl_ip"

    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    cd $WORKSPACE/scripts-repo/scripts/; ./check_uniconfig_ready.sh $odl_ip uniconfig
    cd -;

    # run postman collection to check if is imported
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # rm daexim config file
    rm_daexim_config_file "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30


    echo "############################################################################"
    # test_case_3
    #  immediate import
    folder="daexim_uniconfig_immediate_import_carbon"
    echo "######### test_case_3: $folder"

    # start karaf
    start_karaf "$odl_ip"

    # check karaf ready
    cd $WORKSPACE/scripts-repo/scripts/; ./check_uniconfig_ready.sh $odl_ip uniconfig
    cd -;

    # run postman collection to check if is imported
    run_folder "$collection_file" "$env_file" "$folder" "$odl_ip" "$logfile"

    # kill and get log
    kill_and_get_log "$odl_ip" "$folder"

    # clean karaf
    clean_karaf "$odl_ip"

    # rm daexim folder
    rm_daexim_folder "$odl_ip"

    # add a sleep to wait a bit everything is cleaned
    sleep 30

else
   echo "Unknown stream: it must be 'carbon' or 'oxygen'"
fi



# test output presentation
if [ -f $logfile ] ; then
    echo "-------TEST FAILURE LIST-------"
    cat $logfile
fi
