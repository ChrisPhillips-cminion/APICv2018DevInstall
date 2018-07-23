pwd 
. $(pwd)/envfile
echo --------
echo get access token
echo --------

access_token=$(curl -s  "https://$ep_cm/api/token" \
 -H 'Content-Type: application/json' \
 -H 'Accept: application/json' \
 --data-binary "{\"username\":\"admin\",\"password\":\"$admin_pass\",\"realm\":\"admin/default-idp-1\",\"client_id\":\"caa87d9a-8cd7-4686-8b6e-ee2cdc5ee267\",\"client_secret\":\"3ecff363-7eb3-44be-9e07-6d4386c48b0b\",\"grant_type\":\"password\"}" |  jq .access_token | sed -e s/\"//g  )



echo --------
echo get integration_ep
echo --------

curl -s  "https://$ep_cm/api/cloud/integrations/gateway-service/datapower-gateway" -H "Authorization: Bearer $access_token" -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-GB,en-US;q=0.9,en;q=0.8'  -H 'Accept: application/json' -H 'Referer: https://cm.px-chrisp.apicww.cloud/admin/services/availability-zone-default/register/datapower-gateway/' -H 'Connection: keep-alive' --compressed
integration_url=$(curl -s  "https://$ep_cm/api/cloud/integrations/gateway-service/datapower-gateway" -H "Authorization: Bearer $access_token" -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-GB,en-US;q=0.9,en;q=0.8'  -H 'Accept: application/json' -H 'Referer: https://cm.px-chrisp.apicww.cloud/admin/services/availability-zone-default/register/datapower-gateway/' -H 'Connection: keep-alive' --compressed | jq .url | sed -e s/\"//g)
echo --------
echo $integration_url
echo --------

orgUrl=$(curl -s "https://$ep_cm/api/cloud/orgs" \
 -H "Authorization: Bearer $access_token" \
 -H 'Accept: application/json' \
 --compressed | jq .results[0].url | sed -e s/\"//g);


tlsServer=$(curl -s "$orgUrl/tls-server-profiles" \
 -H "Authorization: Bearer $access_token" \
 -H 'Accept: application/json' --compressed | jq .results[0].url  | sed -e s/\"//g);

tlsClientDefault=$(curl -s "$orgUrl/tls-client-profiles" \
 -H "Authorization: Bearer $access_token" \
 -H 'Accept: application/json' --compressed | jq '.results[] | select(.name=="tls-client-profile-default")| .url' | sed -e s/\"//g);
tlsClientAnalytics=$(curl -s "$orgUrl/tls-client-profiles" \
 -H "Authorization: Bearer $access_token" \
 -H 'Accept: application/json' --compressed | jq '.results[] | select(.name=="analytics-client-default")| .url' | sed -e s/\"//g);
 
echo ---------
echo Create gateway Service
echo ---------

curl -s "$orgUrl/availability-zones/availability-zone-default/gateway-services" \
 -H "Authorization: Bearer $access_token" \
 -H 'Content-Type: application/json' \
 -H 'Accept: application/json' \
 -H 'Connection: keep-alive' \
 --data-binary "{\"name\":\"dp1\",\"title\":\"dp1\",\"endpoint\":\"http://$ep_gwd\",\"api_endpoint_base\":\"http://$ep_gw\",\"tls_client_profile_url\":\"$tlsClientDefault\",\"gateway_service_type\":\"datapower-gateway\",\"visibility\":{\"type\":\"public\"},\"sni\":[{\"host\":\"*\",\"tls_server_profile_url\":\"$tlsServer\"}],\"integration_url\":\"$integration_url\"}"

echo ---------
echo Create Analytics Service
echo ---------

curl -s "$orgUrl/availability-zones/availability-zone-default/analytics-services" \
 -H "Authorization: Bearer $access_token"\
 -H 'Content-Type: application/json'\
 -H 'Accept: application/json'\
 -H 'Connection: keep-alive'\
 --data-binary "{\"title\":\"a1\",\"name\":\"a1\",\"endpoint\":\"https://$ep_ac\"}" \
 --compressed
echo ---------
echo Create Mail Server
echo ---------
mailServerUrl=$(curl -s "$orgUrl/mail-servers"\
 -H "Accept: application/json"\
 --compressed\
 -H "authorization: Bearer $access_token"\
 -H "content-type: application/json"\
 -H "Connection: keep-alive"\
 --data "{\"title\":\"autoCreatedEMailServer 2 $(date +%s)\",\"name\":\"autocreatedemailserver$(date +%s)\",\"host\":\"$smtpServer\",\"port\":$smtpServerPort,\"credentials\":{}}" | jq .url);
#'{"mail_server_url":"https://cm.px-chrisp.apicww.cloud/api/orgs/898e65bb-7fdf-4bca-a6c4-807542685071/mail-servers/39bab9bb-4a63-49ef-85b2-a270e86db4a3","email_sender":{"name":"APIC Administrator","address":"chris.phillips@uk.ibm.com22"}}'
echo ---------
echo setReplyTo
echo ---------
curl -s "https://$ep_cm/api/cloud/settings"\
 -X PUT\
 -H "Accept: application/json"\
 -H "authorization: Bearer $access_token" \
 -H "content-type: application/json"\
 --data "{\"mail_server_url\":$mailServerUrl,\"email_sender\":{\"name\":\"APIC Administrator\",\"address\":\"$admin_email\"}}"
echo ---------
echo sleeping while portal starts
echo ---------
sleep 60
echo ---------
echo create portal
echo ---------
curl -s "$orgUrl/availability-zones/availability-zone-default/portal-services"\
 -H "Accept: application/json"\
 -H "authorization: Bearer $access_token"\
 -H "content-type: application/json"\
 --data "{\"title\":\"portal1\",\"name\":\"portal1\",\"endpoint\":\"https://$ep_padmin\",\"web_endpoint_base\":\"https://$ep_portal\",\"visibility\":{\"group_urls\":null,\"org_urls\":null,\"type\":\"public\"}}"
