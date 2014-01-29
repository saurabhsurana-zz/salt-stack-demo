#!/bin/bash

# Log to syslog and a separate file
exec > >(tee /var/log/install_master.log | logger -t master -s 2>/dev/console) 2>&1

set -x

SALT_HOME=/opt/salt
SALT_REPO=/opt/salt-stack-demo
DEMO_SALT_HOME=/opt/salt-stack-demo
DEMO_SALT_STATES_PATH=states
DEMO_SALT_PILLAR_PATH=pillar
EXT_MODULES_REPO_PATH=${SALT_REPO}/modules

create_salt_user() {
    cat /etc/passwd | grep salt
    if [ $? -eq 1 ]; then
       mkdir -p ${SALT_HOME}
       sudo useradd -m -d ${SALT_HOME} -r -U -c "Salt Master Daemon" salt
    fi
}

install_packages(){
    apt-get update
    apt-get install -y git
    apt-get install -y python-pip mysql-client nova-common
    pip install python-novaclient==2.13.0 python-keystoneclient python-glanceclient 
}

install_salt_master(){
   cd ${SALT_HOME}
   mkdir -p salt
   cat > salt/master <<EOF
user: salt

worker_threads: 3

fileserver_backend:
- roots

file_roots:
  base:
    - ${DEMO_SALT_HOME}/${DEMO_SALT_STATES_PATH}

pillar_roots:
  base:
    - ${DEMO_SALT_HOME}/${DEMO_SALT_PILLAR_PATH}

extension_modules: $SALT_HOME/extmods

state_output: mixed
log_level: info
log_file: /var/log/salt/master
key_logfile: /var/log/salt/key

pki_dir: $SALT_HOME/pki
EOF

   sudo mkdir /var/log/salt /etc/salt
   sudo chown salt /var/log/salt /etc/salt

   ln -s /etc/salt $SALT_HOME/etc

   curl -L http://bootstrap.saltstack.org | sudo sh -s -- -N -M -c `pwd`/salt git v0.16.0

}

checkout_states_and_pillar(){
    cd /opt
    git clone https://github.com/saurabhsurana/salt-stack-demo 
}


install_packages

checkout_states_and_pillar

create_salt_user

install_salt_master

chown -R salt:salt ${DEMO_SALT_HOME}

chmod -R 750 ${DEMO_SALT_HOME}/${DEMO_SALT_STATES_PATH}
chmod -R 750 ${DEMO_SALT_HOME}/${DEMO_SALT_PILLAR_PATH}
