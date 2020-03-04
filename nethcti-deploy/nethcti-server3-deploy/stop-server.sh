#!/usr/bin/env bash
IP=$1

# kill opened live-server
PID=$(ssh $IP 'ps aux | grep "[n]ode /usr/lib/node/nethcti-server-dev/node_modules/.bin/nodemon nethcti.js" | awk "{print \$2}"')
echo "kill server [$PID]"
ssh $IP "kill $PID"
