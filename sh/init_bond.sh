#!/usr/bin/env bash

# Usage: init_bond.sh <device1> <device2>
#        init_bond.sh enp6s0 enp7s0

# Bond <n> network interfaces as one logical interface

BOND_DEVICE_MASTER=bond0
BOND_DEVICE_SLAVES=("$@")
BOND_DEVICE_SLAVE_PREFIX="${BOND_DEVICE_MASTER}-slave"
BOND_MODE="802.3ad"
# balance-rr    (0)
# active-backup (1)
# balance-xor   (2)
# broadcast     (3)
# 802.3ad       (4)
# balance-tlb   (5)
# balance-alb   (6)

source sh/lib/logger.sh || exit 1

bond_list() {
    modprobe bonding
    if [[ $? -ne 0 ]]; then
	      log::info "Command 'modprobe' returned non-zero code. Kernel module 'bonding' not loaded."
	      exit 1
    fi

    log::info "Listing network interfaces..."
    lshw -class network -short
    if [[ $? -ne 0 ]]; then
	      log::info "Command 'lshw' returned non-zero code. Failed to list all network interfaces."
	      exit 1
    fi
}

bond_delete() {
    log::info "Deleting network interfaces: ${BOND_DEVICE_SLAVES[@]}"
    nmcli connection del "${BOND_DEVICE_SLAVES[@]}"
    if [[ $? -ne 0 ]]; then
	      log::info "Command 'nmcli' returned non-zero code. Failed to delete devices: ${BOND_DEVICE_SLAVES[@]}"
    fi
}

bond_create_and_start() {
    log::info "Creating interface ${BOND_DEVICE_MASTER}"
    nmcli connection add type bond ifname ${BOND_DEVICE_MASTER} con-name ${BOND_DEVICE_MASTER} mode ${BOND_MODE}
    if [[ $? -ne 0 ]]; then
	      log::info"Command 'nmcli' returned non-zero code. Failed to create ${BOND_DEVICE_MASTER}"
	      exit 1
    fi

    for i in "${!BOND_DEVICE_SLAVES[@]}"; do
	      slave_name=${BOND_DEVICE_SLAVE_PREFIX}${i}

	      log::info "Creating interface ${slave_name}"
	      nmcli connection add type bond-slave ifname ${BOND_DEVICE_SLAVES[$i]} con-name ${slave_name} master ${BOND_DEVICE_MASTER}
	      if [[ $? -ne 0 ]]; then
	          log::info "Command 'nmcli' returned non-zero code. Failed to add slave '${BOND_DEVICE_SLAVES[$i]}' to '${BOND_DEVICE_MASTER}'"
	          exit 1
	      fi

	      log::info "Bringing up interface ${slave_name}"
	      nmcli connection up ${slave_name}
	      if [[ $? -ne 0 ]]; then
	          log::info "Command 'nmcli' returned non-zero code. Failed to bring up interface 'slave${i}'"
	          exit 1
	      fi
    done

    log::info "Bringing up interface ${BOND_DEVICE_MASTER}"
    nmcli connection up ${BOND_DEVICE_MASTER}
    if [[ $? -ne 0 ]]; then
	      log::info "Command 'nmcli' returned non-zero code. Failed to bring up interface '${BOND_DEVICE_MASTER}'"
	      exit 1
    fi
}

main() {
    bond_list
    bond_delete
    bond_create_and_start
    log::info "Completed"
}
main
