'use strict';

const https = require('https');
const crypto = require('crypto');
const io = require('socket.io-client');
const { spawnSync } = require('child_process');
const shell = require('shelljs');

const TIMEOUT_REQ = 5000; // timeout of each request
const MAX_ATTEMPTS = 3; // max attempts
const INTERVAL_ATTEMPTS = 10000; // interval for connection attemps
const MATTERMOST_WEBHOOK = 'URL' // customize mattermost webhook url
const server = process.argv[2];
const username = process.argv[3];
const password = process.argv[4];
const data = JSON.stringify({
  username: username,
  password: password
});

let token, socket, timeoutWsLogin, options, req;
let countAttempts = 0;
//
let restLogin = () => {
  options = {
    hostname: server,
    port: 443,
    path: '/webrest/authentication/login',
    method: 'POST',
    rejectUnauthorized: false,
    timeout: TIMEOUT_REQ,
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length
    }
  };
  req = https.request(options, res => {
    if (res.statusCode === 401 && res.headers['www-authenticate']) {
      let nonce = res.headers['www-authenticate'].split('Digest')[1].trim();
      token = crypto.createHmac('sha1', password).update(username + ':' + password + ':' + nonce).digest('hex');
      wsLogin();
    } else {
      failed('restLogin');
    }
  });
  req.on('error', error => {
    failed('restLogin');
  });
  req.on('timeout', () => {
    failed('restLogin');
  });
  req.write(data);
  req.end();
};

let restLogout = () => {
  options = {
    hostname: server,
    port: 443,
    path: '/webrest/authentication/logout',
    method: 'POST',
    rejectUnauthorized: false,
    timeout: TIMEOUT_REQ,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': username + ':' + token
    }
  };
  req = https.request(options, res => {
    if (res.statusCode === 200) {
      success();
    } else {
      failed('restLogout');
    }
  });
  req.on('error', error => {
    failed('restLogout');
  });
  req.on('timeout', () => {
    failed('restLogout');
  });
  req.write(data);
  req.end();
};

let failed = id => {
  clear();
  if (countAttempts === MAX_ATTEMPTS) {
    mattermostAlert(id + ': failed')
    restartNethctiServer();
    process.exit(1);
  }
};

let restartNethctiServer = () => {
  spawnSync('/usr/bin/systemctl', [ 'restart', 'nethcti-server' ]);
};

let success = () => {
  clear();
  process.exit(0);
};

let clear = () => {
  if (socket && socket.connected === true && socket.close) {
    socket.off('disconnect');
    socket.close();
    socket = undefined;
  }
  options = undefined;
  req = undefined;
};

let wsLogin = () => {
  socket = io('https://' + server, {
    upgrade: false,
    transports: [ 'websocket' ],
    reconnection: false,
    rejectUnauthorized: false,
    timeout: TIMEOUT_REQ
  });
  socket.on('connect', () => {
    socket.emit('login', {
      accessKeyId: username,
      token: token
    });
    timeoutWsLogin = setTimeout(() => {
      failed('wsLogin');
    }, TIMEOUT_REQ);
  });
  socket.on('authe_ok', res => {
    clearTimeout(timeoutWsLogin);
    if (res.message === 'authorized successfully') {
      restLogout();
    } else {
      failed('wsLogin');
    }
  });
  socket.on('error', err => {
    failed('wsLogin');
  });
  socket.on('disconnect', err => {
    failed('wsLogin');
  });
  socket.on('connect_error', err => {
    failed('wsLogin');
  });
  socket.on('connect_timeout', err => {
    failed('wsLogin');
  });
};

let start = () => {
  restLogin();
};

let mattermostAlert = (msg) => {
  let child = spawnSync('/usr/bin/hostname', [ '-f' ]);
  let text = `# NethCTI RESTARTED`;
  text += `\n# Date: ${new Date()}`;
  text += `\n# Hostname: ${child.stdout.toString()}`;

  child = spawnSync('/sbin/e-smith/config', [ 'getprop','subscription','SystemId' ]);
  text += `# SystemId: ${child.stdout.toString()}`;
  text += `# Failure:\n${msg}\n`;

  text += `\n# Services:\n`;
  child = spawnSync('/usr/bin/systemctl', [ 'is-active', 'nethcti-server' ]);
  text += `nethcti-server: ${child.stdout.toString()}`;
  child = spawnSync('/usr/bin/systemctl', [ 'is-active', 'janus-gateway' ]);
  text += `janus-gateway: ${child.stdout.toString()}`;
  child = spawnSync('/usr/bin/systemctl', [ 'is-active', 'asterisk' ]);
  text += `asterisk: ${child.stdout.toString()}`;
  child = spawnSync('/usr/bin/systemctl', [ 'is-active', 'httpd' ]);
  text += `httpd: ${child.stdout.toString()}`;

  child = spawnSync('/usr/sbin/asterisk', [ '-rx', 'core show calls' ]);
  text += `\n# Asterisk:\n${child.stdout.toString()}`;

  child = spawnSync('/usr/bin/free', [ '-m' ]);
  text += `\n# free -m:\n${child.stdout.toString()}`;

  var cmd = shell.exec('/usr/bin/top -b -c -n 1 -w512', { silent: true })
    .exec('/usr/bin/head -11', { silent: true });
  text += `\n# top:\n${cmd.stdout}`;

  child = spawnSync('/usr/bin/curl', [
    '-X', 'POST',
    '-H', 'Content-Type: application/json',
    '-d', '{"text": "```\n' + text + '\n```"}',
    MATTERMOST_WEBHOOK
  ]);
};

start();

setInterval(() => {
  countAttempts += 1;
  start();
}, INTERVAL_ATTEMPTS);