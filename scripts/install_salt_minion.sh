#!/bin/bash

# Copyright 2014 Hewlett-Packard Development Company, L.P.
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#


salt_master_1=replace_with_IP_salt_master1
salt_master_2=replace_with_IP_salt_master2

# Log to syslog and a separate file
exec > >(tee /var/log/install_minion.log | logger -t minion -s 2>/dev/console) 2>&1

set -x

wget -O - http://bootstrap.saltstack.org | sudo sh -s -- git v0.16.0

if [[ "${salt_master_2}" =~ "replace" ]];
then
    cat > /etc/salt/minion <<EOF
master: ${salt_master_1}
id: $(hostname)
append_domain: salt-stack-demo
EOF
else
    cat > /etc/salt/minion <<EOF
master:
  - ${salt_master_1}
  - ${salt_master_2}
id: $(hostname)
append_domain: salt-stack-demo
EOF
fi
cat  /etc/salt/minion | grep "master: "

service salt-minion restart
