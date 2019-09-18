#!/bin/bash

if [ $# != "3" ]; then
  echo "Usage: $0 <SERVER> <USERNAME> <PASSWORD>"
  exit 1
fi

SERVER=$1
USERNAME=$2
PASSWORD=$3

NONCE=$(curl -k -i -X POST -d "username=$USERNAME&password=$PASSWORD" https://$SERVER/webrest/authentication/login | grep www | cut -d ' ' -f3 | sed 's/\n\|\r//g')
TOKEN=$(echo -ne "$USERNAME:$PASSWORD:$NONCE" | openssl dgst -sha1 -hmac "$PASSWORD" | awk '{print $2}')
echo "Token: $TOKEN"
echo
echo "REST API example:"
echo "curl -k -i -H \"Authorization: $USERNAME:$TOKEN\" https://$SERVER/webrest/astproxy/extensions"
