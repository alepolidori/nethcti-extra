const https = require('https');
const crypto = require('crypto');
const server = process.argv[2];
const username = process.argv[3];
const password = process.argv[4];
const data = JSON.stringify({
  username: username,
  password: password
});
const options = {
  hostname: server,
  port: 443,
  path: '/webrest/authentication/login',
  method: 'POST',
  rejectUnauthorized: false,
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};
const req = https.request(options, res => {
  if (res.statusCode === 401 && res.headers['www-authenticate']) {
    let nonce = res.headers['www-authenticate'].split('Digest')[1].trim();
    var token = crypto.createHmac('sha1', password).update(username + ':' + password + ':' + nonce).digest('hex');
    console.log(token);
  }
});

req.on('error', error => {
  console.error(error);
});

req.write(data);
req.end();