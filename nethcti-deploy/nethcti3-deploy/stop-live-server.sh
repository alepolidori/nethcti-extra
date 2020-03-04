#!/usr/bin/env bash
IP=$1

# kill opened live-server
PID=$(ssh $IP 'ps aux | grep "[n]ode /opt/rh/rh-nodejs10/root/usr/bin/live-server" | awk "{print \$2}"')
echo "kill live-server [$PID]"
ssh $IP "kill $PID"
