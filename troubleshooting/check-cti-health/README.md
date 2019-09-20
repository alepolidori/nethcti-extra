Check the health status of the nethcti-server every 5 minutes.
It does three connection attempts and if all fail a mattermost alert message is sent and the `nethcti-server` service is restarted. Each connection attempt consists of the following actions:

- HTTP POST authentication/login
- WebSocket connection and login
- HTTP POST authentication/logout

Each request has a timeout of 10 seconds. Connection attempts are made every minute.
So an alert message and a restart of the service will happen if the `nethcti-server` doesn't work correctly for 3 minutes interval time.

## How to use

1. replace mattermost url inside the script

2. copy project into the machine

`scp -r check-cti-health root@server:/usr/lib/node/`

3. skip into the machine

`cd /usr/lib/node/check-cti-health && scl enable rh-nodejs10 'npm install'`

4. add cron job replacing user and password fields

`*/5 * * * * /usr/bin/scl enable rh-nodejs10 -- node /usr/lib/node/check-cti-health/check-cti-health.js 127.0.0.1 <USER> <PASSWORD> &> /dev/null`

5. make sure that `/etc/httpd/conf.d/nethcti-server.conf` has `retry=0` at the end of the line:
`ProxyPass /webrest http://127.0.0.1:8179`
