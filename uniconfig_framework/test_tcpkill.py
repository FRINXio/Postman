#!/usr/bin/env python

import os
import sys
import time
import subprocess
import requests
import argparse
import random
import datetime
import psutil
import threading


def get_args(argv=None):
    parser = argparse.ArgumentParser(description="Random tcpkill test")
    parser.add_argument('--odl-ip', action='store', type=str, default=None, required=True,
                        help='IP address of machine where is running ODL. In case of ODL cluster test this must be the leader IP.')
    parser.add_argument('--first-port', action='store', type=int, default=None, required=True,
                        help='First port number')
    parser.add_argument('--port-number', action='store', type=int, default=None, required=True,
                        help='Number of ports')
    parser.add_argument('--interface', action='store', type=str, default='lo',
                        help='Interface name to be blocked with tcpkill')
    parser.add_argument('--log-file', action='store', type=str, default='test_tcpkill.log',
                        help='log file where to store errors')
    parser.add_argument('--iterations', action='store', type=int, default=1,
                        help='Number of iterations of the test')
    parser.add_argument('--delay', action='store', type=float, default=1,
                        help='Delay between each tcpkill')
    parser.add_argument('--followers', action='store', type=str, default=None,
                        help='Commma separated list of followers, for the ODL cluster test.')

    return parser.parse_args(argv)


def get_from_netconf(odl_ip=None):
    response = requests.get('http://%s:8181/restconf/operational/network-topology:network-topology/topology/topology-netconf?depth=3' % (odl_ip),
                            auth=('admin', 'admin'), headers={'Content-Type': 'application/json'})
    return response.json()


def count_connected(odl_ip=None):
    response_json = get_from_netconf(odl_ip=odl_ip)
    connected_count = 0
    for node in response_json['topology'][0]['node']:
        if node['netconf-node-topology:connection-status'] == 'connected':
            connected_count += 1
    return connected_count


def count_connecting(odl_ip=None):
    response_json = get_from_netconf(odl_ip=odl_ip)
    connecting_count = 0
    for node in response_json['topology'][0]['node']:
        if node['netconf-node-topology:connection-status'] == 'connecting':
            connecting_count += 1
    return connecting_count


def add_iptables_rules(port_list=None):
    for port in port_list:
        add_iptables_rule = 'sudo /sbin/iptables -I INPUT -p tcp --dport %s -j DROP' % port
        p = subprocess.Popen(add_iptables_rule.split())
        p.wait()


def delete_iptables_rules(port_list=None):
    for port in port_list:
        delete_iptables_rule = 'sudo /sbin/iptables -D INPUT -p tcp --dport %s -j DROP' % port
        p = subprocess.Popen(delete_iptables_rule.split())
        p.wait()


def clean_log_file(log_file=None):
    # remove log file if exists
    if os.path.exists(log_file):
        os.remove(log_file)
    # create empty file
    open(log_file, 'a').close()


def print_and_log(log_file=None, error_msg=None):
    with open(log_file, "a") as logfile:
        print(error_msg)
        logfile.write('%s\n' % error_msg)


def check_connecting_devices(odl_ip=None, port_list=None, log_file=None, _iter=None):

    response_json = get_from_netconf(odl_ip=odl_ip)
    connecting_list = []
    for node in response_json['topology'][0]['node']:
        if node['netconf-node-topology:connection-status'] == 'connecting':
            connecting_list.append(str(node['netconf-node-topology:port']))

    connecting_list.sort()
    if connecting_list == port_list:
        print('%s: Devices in connecting status as expected: [%s]' % (
           str(datetime.datetime.now()), ','.join(connecting_list)))
    else:
        error_msg = 'ERROR: iteration: %s connecting devices: [%s] expected to be equal to port_list: [%s]' % (
            _iter, ','.join(connecting_list), ','.join(port_list))
        print_and_log(log_file=log_file, error_msg=error_msg)


def print_args(_args):
    print('Running test with:')
    for arg in vars(_args):
        print('%s: %s' % (arg, getattr(_args, arg)))


def check_arguments_consistency(_args):
    # check arguments
    interfaces_list = psutil.net_if_addrs().keys()
    if (_args.interface not in interfaces_list):
        print("ERROR: specified interface: '%s' not in: ['%s']. Choose a different interface" % (
            _args.interface, "', '".join(interfaces_list)))
        sys.exit(1)


def check_all_connected(odl_ip=None, _iter=None, port_number=None, when=None, log_file=None):
    # count connected devices
    connected_devices = count_connected(odl_ip=odl_ip)
    print('%s: Iteration: %s Connected devices %s: %s' % (str(datetime.datetime.now()), _iter, when, connected_devices))
    if connected_devices != port_number:
        error_msg = 'ERROR: Iteration: %s Connected devices %s: %s expected to be equal to: %s' % (
            _iter, when, connected_devices, port_number)
        print_and_log(log_file=log_file, error_msg=error_msg)


def random_choice_port(port_list=None):
    random_port = random.choice(port_list)
    port_list.remove(random_port)

    return (str(random_port), port_list)


def kill_connection(random_port=None, interface=None):
    # print('Killing port %s' % random_port)
    # add iptables rule to close port
    # print('Add iptables rule')
    add_iptables_rules(port_list=[random_port])

    # run tcpkill
    run_tcpkill = ['sudo', 'tcpkill', '-i', interface, 'port', random_port]
    # print('run tcpkill command: %s' % ' '.join(run_tcpkill))

    # this code is to kill mutliple ports at the same time
    # run_tcpkill = ['sudo', 'tcpkill', '-i', interface]
    # run_tcpkill.extend(['port', str(port_list[0])])
    # for port in port_list[1:]:
    #    run_tcpkill.extend(['or', 'port', str(port)])
    pro = subprocess.Popen(run_tcpkill,
                           stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT)
    tcpkill_pid = pro.pid

    print('Connection closed on port: %s' % random_port)

    return tcpkill_pid


def reestablishing_connection(random_port_list=None, tcpkill_pid_list=None):
    # print('Reestablishing connection on port %s' % random_port)
    # to kill tcpkill is necessary to get the child pid
    for tcpkill_pid in tcpkill_pid_list:
        child_pid = subprocess.check_output(['ps', '--ppid', str(tcpkill_pid), '-o', 'pid='])
        subprocess.Popen(['sudo', 'kill', '-9', str(int(child_pid))])

    # delete iptables rules for each port
    # print('Delete iptables rules')
    delete_iptables_rules(port_list=random_port_list)

    print("Reestablished connection on ports ['%s']" % "', '".join(random_port_list))


def killing_phase(interface=None, first_port=None, port_number=None, delay=None):

    random_port_list = []
    tcpkill_pid_list = []
    port_list = range(first_port, first_port + port_number)

    for ki in range(port_number):
        print('#### Kill iter: %s' % ki)

        (random_port, port_list) = random_choice_port(port_list=port_list)
        random_port_list.append(random_port)
        tcpkill_pid = kill_connection(random_port=random_port, interface=interface)
        tcpkill_pid_list.append(tcpkill_pid)

        print('Wait: %s sec' % delay)
        time.sleep(delay)
        # reestablishing_connection(random_port=random_port, tcpkill_pid=tcpkill_pid)

    reestablishing_connection(random_port_list=random_port_list, tcpkill_pid_list=tcpkill_pid_list)


def connecting_monitor(stop, odl_ip):
    while True:
        time.sleep(30)
        connecting_devices_during = count_connecting(odl_ip=odl_ip)
        print('##################  MONITOR: %s Connecting devices: %s' % (
            str(datetime.datetime.now()), connecting_devices_during))

        if stop():
            break


def main(args):

    print_args(args)
    check_arguments_consistency(args)
    clean_log_file(log_file=args.log_file)

    odl_ip = args.odl_ip
    first_port = args.first_port
    port_number = args.port_number
    interface = args.interface
    log_file = args.log_file
    iterations = args.iterations
    delay = args.delay
    followers = args.followers

    _iter = 1
    while _iter <= iterations:
        print('###### Test iteration: %s' % _iter)

        slp = random.randint(1, 101)
        print('Wait: %s sec' % slp)
        time.sleep(slp)

        # check all connected before
        check_all_connected(odl_ip=odl_ip, _iter=_iter, port_number=port_number, when='before', log_file=log_file)

        stop_thread = False
        monitor = threading.Thread(target=connecting_monitor, args=(lambda: stop_thread, odl_ip))
        monitor.start()

        killing_phase(interface=interface, first_port=first_port, port_number=port_number, delay=delay)

        stop_thread = True
        monitor.join()
        print('Monitor killed')

        if followers is not None:
            followers_list = followers.split(',')
            odl_ip = random.choice(followers_list)
            print('Check connected devices on follower: %s' % odl_ip)

        # check all connected after
        # iterate the check because it may take time, in specific if the number of devices increase
        all_connected = False
        _i = 0
        slp = 60
        while _i <= 15 * slp:
            # sleep a bit
            time.sleep(slp)

            # count connected devices after
            connected_devices_after = count_connected(odl_ip=odl_ip)
            print('%s: Iteration: %s After: %s sec ODL node: %s Connected devices: %s' % (
                str(datetime.datetime.now()), _iter, _i, odl_ip, connected_devices_after))
            if connected_devices_after == port_number:
                all_connected = True
                break
            _i = _i + slp

        if not all_connected:
            error_msg = 'ERROR: Iteration: %s After: %s sec ODL node: %s Connected devices: %s expected to be equal to: %s' % (
                _iter, _i, odl_ip, connected_devices_after, port_number)
            print_and_log(log_file=log_file, error_msg=error_msg)

        _iter += 1


if __name__ == "__main__":
    args = get_args()
    main(args)
