#!/bin/bash

cd /tmp
mkdir ca-init && cd casper-setup
#!TODO: PLACEHOLDER FOR CODE TO PULL THE CONFIG/VARIABLES FROM ANYWHERE
# $CANAME="voldemorts mcplayplace"
# $PROVISIONER="svc_voldemort"
# $PROVISIONERPASS=$(cat /proc/sys/kernel/random/uuid)
# $DNS="ca1,172.30.3.42,localhost"
# $ADDRESS=":443"
#  STUB
#  STUB
#  STUB
#######################################################################


#  Install the latest version of the Step tool
wget -O step.tar.gz https://github.com/smallstep/cli/releases/download/v0.15.16/step_linux_0.15.16_amd64.tar.gz
tar -xf step.tar.gz
sudo cp step_0.15.16/bin/step /usr/bin

#  Install the latest version of the step-ca tool (our CA)
wget -O step-ca.tar.gz https://github.com/smallstep/certificates/releases/download/v0.15.14/step-ca_linux_0.15.14_amd64.tar.gz
tar -xf step-ca.tar.gz
sudo cp step-ca_0.15.14/bin/step-ca /usr/bin



#  Begin the process of setting the step-ca service to run as a daemon on the host
sudo useradd --system --home /etc/step-ca --shell /bin/false step
#  Allows for the step-ca binary to utilize low port-binding capabilities as anything below 1024 is restricted use
sudo setcap CAP_NET_BIND_SERVICE=+eip $(which step-ca)  #  comment out if using any port above 1024

#  Perform the initialization of the new PKI
cd /etc/step-ca
echo $PROVISIONERPASS > password.txt
chmod 600 password.txt
step ca init --name $CANAME --provisioner $PROVISIONER \
               --dns $DNS --address $ADDRESS \
               --password-file password.txt \
               --provisioner-password-file password.txt
sudo mkdir -p /etc/step-ca/db
sudo chown -R step:step /etc/step-ca

echo "
[Unit]
Description=step-ca service
Documentation=https://smallstep.com/docs/step-ca
Documentation=https://smallstep.com/docs/step-ca/certificate-authority-server-production
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=30
StartLimitBurst=3
ConditionFileNotEmpty=/etc/step-ca/config/ca.json
ConditionFileNotEmpty=/etc/step-ca/password.txt


[Service]
Type=simple
User=step
Group=step
Environment=STEPPATH=/etc/step-ca
WorkingDirectory=/etc/step-ca
ExecStart=/usr/bin/step-ca config/ca.json --password-file password.txt
ExecReload=/bin/kill --signal HUP $MAINPID
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=30
StartLimitBurst=3


; Process capabilities & privileges
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
SecureBits=keep-caps
NoNewPrivileges=yes


; Sandboxing
ProtectSystem=full
ProtectHome=true
RestrictNamespaces=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
PrivateTmp=true
PrivateDevices=true
ProtectControlGroups=true
ProtectKernelTunables=true
ProtectKernelModules=true
LockPersonality=true
RestrictSUIDSGID=true
RemoveIPC=true
RestrictRealtime=true
SystemCallFilter=@system-service
SystemCallArchitectures=native
MemoryDenyWriteExecute=true
ReadWriteDirectories=/etc/step-ca/db


[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/step-ca.service

#!TODO: PLACEHOLDER FOR CODE TO SECURE THE DEFAULT CA.JSON FILE CONFIGS
#  STUB
#  STUB
#  STUB
#######################################################################

sudo systemctl daemon-reload
systemctl enable --now step-ca