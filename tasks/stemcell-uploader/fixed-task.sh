#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -eu
fi

#if [[ -n "$NO_PROXY" ]]; then
#  echo "$OM_IP $OPS_MGR_HOST" >> /etc/hosts
#fi

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

PIVNET_CLI=`find ./pivnet-cli -name "*linux-amd64*"`
chmod +x $PIVNET_CLI

STEMCELL_VERSION=$(
  cat ./pivnet-product/metadata.json | $JQ_CMD --raw-output \
    '
    [
      (.Dependencies // [])[]
      | select(.Release.Product.Name | contains("Stemcells"))
      | .Release.Version
    ]
    | map(split(".") | map(tonumber))
    | transpose | transpose
    | max // empty
    | map(tostring)
    | join(".")
    '
)

if [ -n "$STEMCELL_VERSION" ]; then
  diagnostic_report=$(
    $OM_CMD \
      --target https://$OPS_MGR_HOST \
      --client-id "${OPSMAN_CLIENT_ID}" \
      --client-secret "${OPSMAN_CLIENT_SECRET}" \
      --username "$OPS_MGR_USR" \
      --password "$OPS_MGR_PWD" \
      --skip-ssl-validation \
      curl --silent --path "/api/v0/diagnostic_report"
  )

  stemcell=$(
    echo $diagnostic_report |
    $JQ_CMD \
      --arg version "$STEMCELL_VERSION" \
      --arg glob "$IAAS_TYPE" \
    '.stemcells[] | select(contains($version) and contains($glob))'
  )

  if [[ -z "$stemcell" ]]; then
    echo "Downloading stemcell $STEMCELL_VERSION"

    product_slug=$(
      $JQ_CMD --raw-output \
        '
        if any(.Dependencies[]; select(.Release.Product.Name | contains("Stemcells for PCF (Windows)"))) then
          "stemcells-windows-server"
        else
          "stemcells"
        end
        ' < pivnet-product/metadata.json
    )

    $PIVNET_CLI login --api-token="$PIVNET_API_TOKEN"
    $PIVNET_CLI download-product-files -p "$product_slug" -r $STEMCELL_VERSION -g "*${IAAS_TYPE}*" --accept-eula

    SC_FILE_PATH=`find ./ -name *.tgz`

    if [ ! -f "$SC_FILE_PATH" ]; then
      echo "Stemcell file not found!"
      exit 1
    fi

    $OM_CMD -t https://$OPS_MGR_HOST \
      --client-id "${OPSMAN_CLIENT_ID}" \
      --client-secret "${OPSMAN_CLIENT_SECRET}" \
      -u "$OPS_MGR_USR" \
      -p "$OPS_MGR_PWD" \
      -k \
      upload-stemcell \
      -s $SC_FILE_PATH
  fi
fi