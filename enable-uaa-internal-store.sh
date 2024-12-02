if [ $# -ne 3 ]; then
  echo "Usage: enable-uaa-internal-store.sh AuthDomainUrl ClientId ClientSecret"
  exit 1
else
  export AuthDomainUrl=$1
  export ClientId=$2
  export ClientSecret=$3
fi


echo AuthDomain = $AuthDomainUrl
echo ClientId = $ClientId
echo ClientSecret = $ClientSecret

uaac target $AuthDomainUrl
uaac token client get $ClientId -s $ClientSecret
uaac curl -b $AuthDomainUrl/identity-providers

export IdpId=$(uaac curl -b https://internal.login.homelab2.fynesy.com/identity-providers | jq ".[] | select(.name == \"uaa\")" | jq -r .id)
echo IdpId = $IdpId
echo

export DomainConfig=$(uaac curl -b $AuthDomainUrl/identity-providers/$IdpId)

echo DomainConfig=$DomainConfig
echo
export ConfigAttribute=$(echo $DomainConfig | jq '.config | fromjson')
echo ConfigAttribute=$ConfigAttribute
echo

export UpdatedConfig=$(echo $ConfigAttribute | jq '.disableInternalUserManagement = false')
echo UpdatedConfig=$UpdatedConfig
echo
export UpdatedDomainConfig=$(echo $DomainConfig | jq ".config = $UpdatedConfig")
echo UpdatedDomainConfig=$UpdatedDomainConfig
echo
uaac curl $AuthDomainUrl/identity-providers/$IdpId?rawConfig=true  -X PUT -H 'Content-Type: application/json'  -d "$UpdatedDomainConfig"