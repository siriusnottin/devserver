#!/bin/bash

# =============================================================================
#                               Local Setup                                   #
# =============================================================================

source $SCRIPT_DIR/utils/hosts.sh

###############################################################################
step "Local setup"
###############################################################################

# do the local setup for the unraid server
add_to_local_hosts "$UNRAID_NAME" "$UNRAID_IP" "${UNRAID_HOSTS[*]}"

source $SCRIPT_DIR/utils/vm.sh
get_vm_infos "$VM_DOMAIN"
# do the local setup for the vm
add_to_local_hosts "$vm_description" "$vm_ip" "$VM_DOMAIN"
