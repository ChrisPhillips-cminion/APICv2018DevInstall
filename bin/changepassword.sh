if [ -z $1 ] ; then
	echo "NO PARAMS";
	url="$url"
	email="admin@example.com"
	pass="Passw0rd!"
else
	url=$1
	email=$2
	pass=$3
fi

access_token=$(curl "https://$url/api/token" \
 -H 'Content-Type: application/json' \
 -H 'Accept: application/json' \
 --data-binary '{"username":"admin","password":"7iron-hide","realm":"admin/default-idp-1","client_id":"caa87d9a-8cd7-4686-8b6e-ee2cdc5ee267","client_secret":"3ecff363-7eb3-44be-9e07-6d4386c48b0b","grant_type":"password"}' |  jq .access_token | sed -e s/\"//g  )






curl "https://$url/api/me" \
 -X PUT \
 -H "Authorization: Bearer $access_token" \
 -H 'Content-Type: application/json' \
 -H 'Accept: application/json' \
 --data-binary "{\"email\":\"$email\"}" \
 --compressed


curl "https://$url/api/me/change-password" \
 -H "Authorization: Bearer $access_token" \
 -H 'Content-Type: application/json' \
 -H 'Accept: application/json' \
 --data-binary "{\"current_password\":\"7iron-hide\",\"password\":\"$pass\"}" \

