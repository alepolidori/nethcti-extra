#!/usr/bin/env bash
IP=$1

# copy files
rsync -avz --delete ../* $IP:/usr/lib/node/nethcti-server-dev/

# stop systemd service
echo "stop nethcti-server"
ssh $IP "systemctl stop nethcti-server"

./stop-server.sh $IP

# run nodemon nethcti.js
ssh $IP "cd /usr/lib/node/nethcti-server-dev && scl enable rh-nodejs10 'npm run dev' &> /dev/null" &

echo "rsync files..."
watch -n1 "rsync -avz --delete ../* $IP:/usr/lib/node/nethcti-server-dev/"

./stop-server.sh $IP
