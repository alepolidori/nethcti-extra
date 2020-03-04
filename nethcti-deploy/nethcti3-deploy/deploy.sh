#!/usr/bin/env bash
IP=$1

# copy all needed files
echo "copy files"
rsync -avz --delete ../ui-dev/node_modules $IP:/usr/share/cti-dev/
rsync -avz --delete ../ui-dev/app/* $IP:/usr/share/cti-dev/
rsync -avz --delete nethcti-dev.conf $IP:/etc/httpd/conf.d/

# reload httpd
echo "reload httpd"
ssh $IP "systemctl reload httpd"

./stop-live-server.sh $IP

# install live-server
ssh $IP "scl enable rh-nodejs10 'npm install -g live-server'"

# start live-server
echo "start live-server"
ssh $IP "cd /usr/share/cti-dev/ && scl enable rh-nodejs10 'live-server --host=127.0.0.1 --port=8080 --watch=index.html,scripts,styles,views --no-browser' &> /dev/null" &

echo "rsync files..."
watch -n1 "rsync -avz --delete ../ui-dev/app/* $IP:/usr/share/cti-dev/"

./stop-live-server.sh $IP
