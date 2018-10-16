#!/bin/bash

set -eu

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

echo "Entering Upload Injected PASW Task"

if [[ -n "$NO_PROXY" ]]; then
  echo "$OM_IP $OPSMAN_DOMAIN_OR_IP_ADDRESS" >> /etc/hosts
fi

# Should the slug contain more than one product, pick only the first.
FILE_PATH=`find ./pasw-injected -name *.pivotal | sort | head -1`
echo $FILE_PATH
$OM_CMD -t https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --client-id "${OPSMAN_CLIENT_ID}" \
  --client-secret "${OPSMAN_CLIENT_SECRET}" \
  -u "$OPS_MGR_USR" \
  -p "$OPS_MGR_PWD" \
  -k \
  --request-timeout 3600 \
  upload-product \
  -p $FILE_PATH
