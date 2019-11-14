#!/bin/bash

# replace with your SOS username
username="<USERNAME_SOS>"

if [ $# -eq "0" ]; then
  echo "Use: $0 (<USERNAME_SSH@SERVER[:PORT]> | <SOS_ID> | localhost)"
  exit 0
fi

MODE="sos"
if [ "$1" == "localhost" ]; then
  MODE="localhost"
elif [[ $1 =~ "@" ]]; then
  MODE="ssh"
  PORT="22"
  if [[ $1 =~ ":" ]]; then
    IFS=':'
    read -ra ARR <<< $1
    ADDR=${ARR[0]}
    PORT=${ARR[1]}
  else
    ADDR=$1
  fi
fi

if [ "$MODE" == "sos" ]; then
  session=$1
  vpn_ip=$(ssh ${username}@sos.nethesis.it sancho session list ${session} | grep vpn | awk '{print $2}')
  if [ "$vpn_ip" == "" ]; then
    echo "Session id not found !"
    exit 1
  fi
fi

TEMPFILE=$(mktemp)
echo $'
# server
echo "# Server"
echo "Hostname: `hostname -f`"
echo "SO: `cat /etc/nethserver-release`"
echo "Date: `date`"
echo "Uptime:" `/usr/bin/uptime`
echo "Last machine boot:"
/usr/bin/last reboot -n 2 | grep "reboot" # or "who -b"
echo ""

# rpm
echo "RPMs"
/usr/bin/rpm -q nethcti3
/usr/bin/rpm -q nethcti-server3
/usr/bin/rpm -q janus-gateway
/usr/bin/rpm -q nethserver-janus
/usr/bin/rpm -q asterisk13-core
echo ""

# yum
echo "# Yum"
/usr/bin/ls -rt /var/log/messages* | xargs grep -h "Installed:\|Updated:\|Erased:" | grep "nethcti3" | tail -1
/usr/bin/ls -rt /var/log/messages* | xargs grep -h "Installed:\|Updated:\|Erased:" | grep "nethcti-server3" | tail -1
/usr/bin/ls -rt /var/log/messages* | xargs grep -h "Installed:\|Updated:\|Erased:" | grep "janus-gateway" | tail -1
/usr/bin/ls -rt /var/log/messages* | xargs grep -h "Installed:\|Updated:\|Erased:" | grep "nethserver-janus" | tail -1
/usr/bin/ls -rt /var/log/messages* | xargs grep -h "Installed:\|Updated:\|Erased:" | grep "nethserver-nethvoice14" | tail -1
/usr/bin/ls -rt /var/log/messages* | xargs grep -h "Installed:\|Updated:\|Erased:" | grep "nethserver-freepbx" | tail -1
/usr/bin/ls -rt /var/log/messages* | xargs grep -h "Installed:\|Updated:\|Erased:" | grep "asterisk13-core" | tail -1
echo ""

# boot time
echo "# Boot time"
ASTPID=`ps aux | grep "[/]usr/sbin/asterisk -f -C /etc/asterisk/asterisk.conf" | awk \'{print \$2}\'`
echo -e "Last boot Asterisk:\t" `ls -ld /proc/$ASTPID | awk \'{print \$6 \" \" \$7 \" \" \$8}\'`
echo -e "Asterisk uptime:\t" `/usr/sbin/asterisk -rx "core show uptime"`
echo -e "Last boot NethCTI:\t" `ls -rt /var/log/asterisk/nethcti.log* | xargs grep -h "STARTED" | tail -1 | cut -d ":" -f2-4`
echo -e "Last reload NethCTI:\t" `ls -rt /var/log/asterisk/nethcti.log* | xargs grep -h "RELOAD all components" | tail -1 | cut -d ":" -f2-4`
echo ""

# signal-event
echo "# last signal-event"
echo "nethcti3-update:"
ls -rt /var/log/messages* | xargs grep -h "Event: nethcti3-update" | tail -2
echo ""
echo "nethcti-server3-update:"
ls -rt /var/log/messages* | xargs grep -h "Event: nethcti-server3-update" | tail -2
echo ""
echo "nethserver-janus-update:"
ls -rt /var/log/messages* | xargs grep -h "Event: nethserver-janus-update" | tail -2
echo ""
echo "nethserver-nethvoice14-update:"
ls -rt /var/log/messages* | xargs grep -h "Event: nethserver-nethvoice14-update" | tail -2
echo ""
echo "nethserver-freepbx-update:"
ls -rt /var/log/messages* | xargs grep -h "Event: nethserver-freepbx-update" | tail -2
echo ""

# services
echo "# Services"
echo -e "nethcti-server:\t" `systemctl is-active nethcti-server`
echo -e "janus-gateway:\t" `systemctl is-active janus-gateway`
echo -e "asterisk:\t" `systemctl is-active asterisk`
echo -e "httpd:\t\t" `systemctl is-active httpd`
echo ""

# asterisk
echo "# Asterisk"
echo "Current calls:" `asterisk -rx "core show calls"`
echo ""

# janus
echo "# Janus"
echo "config show"
config show janus-gateway
echo ""

# nethcti
echo "# NethCTI"
echo "Configured users:" `grep \'"name": \' /etc/nethcti/users.json | wc -l`
echo ""
echo -e "NethCTI last BOOT output:"
ls -rt /var/log/asterisk/nethcti.log* | xargs grep -h -A15 "STARTED" | tail -16
echo ""
echo -e "NethCTI last RELOAD output:"
ls -rt /var/log/asterisk/nethcti.log* | xargs grep -h -A20 "RELOAD all components" /var/log/asterisk/nethcti.log | tail -21
echo ""
echo "Num UncaughtException: " `grep "UncaughtException" /var/log/asterisk/nethcti.log | wc -l`
echo ""
echo "Last errors:"
fgrep -A2 "error: [" /var/log/asterisk/nethcti.log | tail -30
echo ""
echo "config show"
config show nethcti-server
echo ""
echo "REST API profiling/all"
curl -k https://localhost/webrest/profiling/all | python -m json.tool
' > $TEMPFILE

if [ "$MODE" == "sos" ]; then
  ssh $username@sos.nethesis.it "ssh -oStrictHostKeyChecking=no root@$vpn_ip -p 981 \"bash -s\"" < $TEMPFILE
elif [ "$MODE" == "localhost" ]; then
  bash $TEMPFILE
else
  ssh -p $PORT $ADDR "bash -s" < $TEMPFILE
fi
rm -f $TEMPFILE
