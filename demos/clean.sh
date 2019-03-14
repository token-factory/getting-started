#!/bin/sh

ENDPOINT="http://token-factory-demo.us-east.containers.appdomain.cloud"
#ENDPOINT="http://localhost:9000"

listTenants=$(curl -s -H 'Accept-Encoding: gzip, deflate, br' \
	-H 'Content-Type: application/json' -H 'Accept: application/json' \
	-H 'Connection: keep-alive' -H 'DNT: 1' \
	-H "Origin: ${ENDPOINT}" \
	--data-binary '{"query":" {listTenants { id  name } }"}' \
	--compressed  "${ENDPOINT}/token-factory" | jq --raw-output '.data.listTenants[] | select(.name|startswith("my")) | .id')

echo ${listTenants}

for tenantId in $(echo ${listTenants}); do
	echo "**${tenantId}**"
	deleteTenant=$(curl -s "${ENDPOINT}/token-factory" \
	 -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' \
	 -H 'Accept: application/json' -H 'Connection: keep-alive' \
	 -H 'DNT: 1' -H "Origin: ${ENDPOINT}" \
	 --data-binary "{\"query\":\"mutation {deleteTenant(id: \\\""${tenantId}\\\"") {name} }\" }" \
	 --compressed)
	echo "Verify deletion of tenant ${tenantId}: ${deleteTenant}\n"
done



listUsers=$(curl -s -H 'Accept-Encoding: gzip, deflate, br' \
	-H 'Content-Type: application/json' -H 'Accept: application/json' \
	-H 'Connection: keep-alive' -H 'DNT: 1' \
	-H "Origin: ${ENDPOINT}" \
	--data-binary '{"query":" {listUsers { id  name } }"}' \
	--compressed  "${ENDPOINT}/token-factory" | jq --raw-output '.data.listUsers[] | select(.name|startswith("johndoe_")) | .id')

echo ${listUsers}

# for tenantId in $(echo ${listTenants}); do
# 	echo "**${tenantId}**"
# 	deleteTenant=$(curl -s "${ENDPOINT}/token-factory" \
# 	 -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' \
# 	 -H 'Accept: application/json' -H 'Connection: keep-alive' \
# 	 -H 'DNT: 1' -H "Origin: ${ENDPOINT}" \
# 	 --data-binary "{\"query\":\"mutation {deleteTenant(id: \\\""${tenantId}\\\"") {name} }\" }" \
# 	 --compressed)
# 	echo "Verify deletion of tenant ${tenantId}: ${deleteTenant}\n"
# done

