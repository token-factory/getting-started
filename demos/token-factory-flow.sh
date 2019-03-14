#!/bin/sh

ENDPOINT="${ENDPOINT:-"http://token-factory-demo.us-east.containers.appdomain.cloud"}"
echo "Target deployment: ${ENDPOINT}"

listTenants=$(curl -s -H 'Accept-Encoding: gzip, deflate, br' \
	-H 'Content-Type: application/json' -H 'Accept: application/json'\
	-H 'Connection: keep-alive' -H 'DNT: 1' \
	-H "Origin: ${ENDPOINT}" \
	--data-binary '{"query":" {listTenants { id  name }}"}' \
	--compressed  "${ENDPOINT}/token-factory" | jq --raw-output '.data.listTenants')
echo "Current list of tenants ${listTenants}\n"

randomTenant=$(echo "mySimpleTenant_$(cat /dev/random | LC_CTYPE=C tr -dc "[:alpha:]" | head -c 8)")
echo ${randomTenant}

createTenant=$(curl -s  "${ENDPOINT}/token-factory" \
 -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' \
 -H 'Accept: application/json' \
 --data-binary "{\"query\":\"mutation {createTenant(name: \\\""${randomTenant}\\\"") {id name}  }\"}" \
 --compressed| jq --raw-output '.data.createTenant')
echo "Tenant created: ${createTenant}"

tenantId=$(echo ${createTenant} | jq --raw-output .id )
echo "tenantId: ${tenantId}\n"

EMAIL="${EMAIL:-"johndoe_$(cat /dev/random | LC_CTYPE=C tr -dc "[:alpha:]" | head -c 8)@example.com"}"
echo "User email: ${EMAIL}"
password="password"

createUser=$(curl -s "${ENDPOINT}/token-factory" \
	-H 'Accept-Encoding: gzip, deflate, br' \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createUser (tenantId: \\\""${tenantId}\\\"", email: \\\""${EMAIL}\\\"", password: \\\""${password}\\\"")  { tenantId id email }  }\"}" \
--compressed | jq --raw-output '.data.createUser')
echo "createdUser ${createUser}"

userEmail=$(echo ${createUser} | jq --raw-output .email )
userId=$(echo ${createUser} | jq --raw-output .id )

authToken=$(curl -s "${ENDPOINT}/token-factory" \
	-H 'Accept-Encoding: gzip, deflate, br' \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { login (email: \\\""${EMAIL}\\\"", password: \\\""${password}\\\"")  { authToken }  }\"}" \
--compressed | jq --raw-output '.data.login.authToken')

echo "Retrieved ${userEmail} authentication token ${authToken}\n"

me=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"query { me { email }  }\"}" \
--compressed | jq --raw-output '.data.me.email')
echo "Verify authentication token matches user email  [${userEmail}]==[${me}]\n"

echo "*******************************************************"

issuerAccountAstroDollarsPassphrase="passphrase"
issuerAccountAstroDollars=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createAccount (description: \\\""issuerAccountAstroDollars\\\"" passphrase: \\\""${issuerAccountAstroDollarsPassphrase}\\\"") { public_key ... on TF_Account { description email tenantId} } }\"}" --compressed | jq --raw-output '.data.createAccount')
issuerAccountAstroDollarsPublicKey=$(echo ${issuerAccountAstroDollars} | jq --raw-output .public_key )
echo "Created AstroDollars Issuer Account for user ${userEmail}: publicKey:[${issuerAccountAstroDollarsPublicKey}]\n"


echo "*******************************************************"
echo "Setting auth flags on account\n"

createFlagTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createFlagTransaction (public_key: \\\""${issuerAccountAstroDollarsPublicKey}\\\"" flag_operation: \\\""setFlags\\\""  flag_to_set: \\\""AuthRequiredFlag\\\"" ){id description} }\"}" \
--compressed | jq --raw-output '.data.createFlagTransaction')
createFlagTransactionId=$(echo ${createFlagTransaction} | jq --raw-output .id )
echo "Create flag on AstroDollars Issuer  account ${issuerAccountAstroDollarsPublicKey} Result: ${createFlagTransactionId}\n"

signCreateFlagTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${issuerAccountAstroDollarsPublicKey}\\\"" passphrase: \\\""${issuerAccountAstroDollarsPassphrase}\\\"" transaction_id: \\\""${createFlagTransactionId}\\\""  ){id description  submitted hash} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed flag transaction for AstroDollars Issuer  Account ${issuerAccountAstroDollarsPublicKey} and Gunther Dollar Issuer Result: ${signCreateFlagTransaction}\n"

createFlagTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createFlagTransaction (public_key: \\\""${issuerAccountAstroDollarsPublicKey}\\\"" flag_operation: \\\""clearFlags\\\""  flag_to_set: \\\""AuthRequiredFlag\\\"" ){id description} }\"}" \
--compressed | jq --raw-output '.data.createFlagTransaction')
createFlagTransactionId=$(echo ${createFlagTransaction} | jq --raw-output .id )
echo "Create flag on AstroDollars Issuer  account ${issuerAccountAstroDollarsPublicKey} Result: ${createFlagTransactionId}\n"

signCreateFlagTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${issuerAccountAstroDollarsPublicKey}\\\"" passphrase: \\\""${issuerAccountAstroDollarsPassphrase}\\\"" transaction_id: \\\""${createFlagTransactionId}\\\""  ){id description  submitted hash} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed flag transaction for AstroDollars Issuer Account ${issuerAccountAstroDollarsPublicKey} and Gunther Dollar Issuer Result: ${signCreateFlagTransaction}\n"

getCustomerHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${issuerAccountAstroDollarsPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance} ... on Payment {asset_type asset_issuer asset_code amount} ... on Manage_Offer {buying_asset_type buying_asset_code buying_asset_issuer selling_asset_type selling_asset_code selling_asset_issuer amount offer_id price }  ... on Account_Flags{ clear_flags clear_flags_s set_flags set_flags_s} } }\"}" \
--compressed | jq --raw-output '.data.getHistory')
echo "Verify AstroDollars Issuer Account history ${issuerAccountAstroDollarsPublicKey} ${getCustomerHistory}\n"

createAsset=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation{ createAsset (asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\"",  asset_code:\\\""Astro\\\"" description:\\\""AstroDollars\\\"" ){asset_issuer asset_code} }\"}" \
--compressed | jq --raw-output '.data.createAsset')
assetIssuer=$(echo ${createAsset} | jq --raw-output .asset_issuer )
assetCodeAstroDollars=$(echo ${createAsset} | jq --raw-output .asset_code )
echo "Issuer account created asset:[${assetCodeAstroDollars}] for user ${EMAIL}'s account publicKey:[${issuerAccountAstroDollarsPublicKey}]\n"


echo "*******************************************************"

issuerAccountGuntherDollarsPassphrase="passphrase"
issuerAccountGuntherDollars=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createAccount (description: \\\""issuerAccountGuntherDollars\\\"" passphrase: \\\""${issuerAccountGuntherDollarsPassphrase}\\\"") {public_key ... on TF_Account { description email tenantId } } }\"}" --compressed | jq --raw-output '.data.createAccount')
issuerAccountGuntherDollarsPublicKey=$(echo ${issuerAccountGuntherDollars} | jq --raw-output .public_key )
echo "Created GuntherDollars Issuer Account for user ${userEmail}: publicKey:[${issuerAccountGuntherDollarsPublicKey}]\n"

createAsset=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation{ createAsset (asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\"",  asset_code:\\\""Gunther\\\"" description:\\\""GuntherDollars\\\"" ){asset_issuer asset_code} }\"}" \
--compressed | jq --raw-output '.data.createAsset')
assetIssuer=$(echo ${createAsset} | jq --raw-output .asset_issuer )
assetCodeGuntherDollars=$(echo ${createAsset} | jq --raw-output .asset_code )
echo "Issuer account created asset:[${assetCodeGuntherDollars}] for user ${userEmail}'s account publicKey:[${issuerAccountGuntherDollarsPublicKey}]\n"

echo "*******************************************************"

getAccounts=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getAccounts {public_key ... on TF_Account { description email tenantId}  } }\"}" \
--compressed | jq --raw-output '.data.getAccounts[]')
echo "Verify list of Stellar accounts created for tenant: \n ${getAccounts}\n"

echo "*******************************************************"

getBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${issuerAccountAstroDollarsPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[] | select (.asset_code == "Astro")')
issuerAccountAstroDollarsAssetCode=$(echo ${getBalances} | jq --raw-output .asset_code )
issuerAccountAstroDollarsBalance=$(echo ${getBalances} | jq --raw-output .balance )
echo "Verify AstroDollar account balance for Issuer is zero: [${assetCodeAstroDollars}:${issuerAccountAstroDollarsBalance}]\n"

getBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${issuerAccountGuntherDollarsPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[] | select (.asset_code == "Gunther")')
issuerAccountGuntherDollarsAssetCode=$(echo ${getBalances} | jq --raw-output .asset_code )
issuerAccountGuntherDollarsBalance=$(echo ${getBalances} | jq --raw-output .balance )
echo "Verify GuntherDollar account balance for Issuer is zero: [${assetCodeGuntherDollars}:${issuerAccountGuntherDollarsBalance}]\n"

echo "*******************************************************"


getIssuerHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${issuerAccountAstroDollarsPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance} ... on Payment {asset_type asset_issuer asset_code amount} }  }\"}" \
--compressed | jq --raw-output '.data.getHistory[]')
echo "Verify Issuer account history for AstroDollars: \n ${getIssuerHistory}"

getIssuerHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${issuerAccountGuntherDollarsPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance } ... on Payment {asset_type asset_issuer asset_code amount} }  }\"}" \
--compressed | jq --raw-output '.data.getHistory[]')
echo "Verify Issuer account history for GuntherDollars: \n ${getIssuerHistory}"

echo "*******************************************************"

trustorAccountPassphrase="passphrase"
trustorAccount=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createAccount (description: \\\""trusterAccount\\\"" passphrase: \\\""${trustorAccountPassphrase}\\\"") { public_key ... on TF_Account { description email tenantId} } }\"}" \
--compressed | jq --raw-output '.data.createAccount')
trustorAccountPublicKey=$(echo ${trustorAccount} | jq --raw-output .public_key )
echo "Created Trustor Account for user ${userEmail}: trustorAccountPublicKey:[${trustorAccountPublicKey}]\n"

getTrustorBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${trustorAccountPublicKey}\\\"") {network asset_code asset_issuer balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify account balances for Trustor ${trustorAccountPublicKey} before receiving payment: ${getTrustorBalances}\n"


echo "*******************************************************"
echo "Trust AstroDollars and GuntherDollars"
echo "*******************************************************"

trustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createTrustTransaction (asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\"" asset_code: \\\""${assetCodeAstroDollars}\\\"" trustor_public_key: \\\""${trustorAccountPublicKey}\\\"" limit: \\\""1000\\\"" ){id description} }\"}" \
--compressed | jq --raw-output '.data.createTrustTransaction')
trustTransactionId=$(echo ${trustTransaction} | jq --raw-output .id )
echo "Establish trust between Trustor ${trustorAccountPublicKey} and AstroDollar Issuer ${issuerAccountAstroDollarsPublicKey}  Result: ${trustTransaction}\n"

signTrustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${trustorAccountPublicKey}\\\"" passphrase: \\\""${trustorAccountPassphrase}\\\"" transaction_id: \\\""${trustTransactionId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed trust transaction between Trustor ${trustorAccountPublicKey} and AstroDollar Issuer ${issuerAccountAstroDollarsPublicKey}  Result: ${signTrustTransaction}\n"


trustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createTrustTransaction (asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\"" asset_code: \\\""${assetCodeGuntherDollars}\\\"" trustor_public_key: \\\""${trustorAccountPublicKey}\\\"" limit: \\\""1000\\\"" ){id description} }\"}" \
--compressed | jq --raw-output '.data.createTrustTransaction')
trustTransactionId=$(echo ${trustTransaction} | jq --raw-output .id )
echo "Establish trust between Trustor ${trustorAccountPublicKey} and GuntherDollar Issuer ${issuerAccountGuntherDollarsPublicKey}  Result: ${trustTransaction}\n"

signTrustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${trustorAccountPublicKey}\\\"" passphrase: \\\""${trustorAccountPassphrase}\\\"" transaction_id: \\\""${trustTransactionId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed trust transaction between Trustor ${trustorAccountPublicKey} and GuntherDollar Issuer ${issuerAccountGuntherDollarsPublicKey}  Result: ${signTrustTransaction}\n"

echo "*******************************************************"

getTrustorBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${trustorAccountPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify account balances for Trustor ${trustorAccountPublicKey} after establishing trust: ${getTrustorBalances}\n"

getIssuerBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${issuerAccountAstroDollarsPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify account balances for AstroDollars Issuer after establishing trust ${issuerAccountAstroDollarsPublicKey}:\n${getIssuerBalances}\n"

getIssuerBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${issuerAccountGuntherDollarsPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify account balances for Gunther Dollars Issuer after establishing trust ${issuerAccountAstroDollarsPublicKey}:\n${getIssuerBalances}\n"


echo "*******************************************************"
echo "Payments AstroDollars and GuntherDollars"
echo "*******************************************************"


createPayment=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createPayment (asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\""  sender_public_key: \\\""${issuerAccountAstroDollarsPublicKey}\\\"" asset_code: \\\""${assetCodeAstroDollars}\\\"", receiver_public_key: \\\""${trustorAccountPublicKey}\\\"", amount: \\\""1000\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.createPayment')
createPaymentId=$(echo ${createPayment} | jq --raw-output .id )
echo "Initiate AstroDollar payment from Issuer ${issuerAccountAstroDollarsPublicKey} to  Trustor ${trustorAccountPublicKey} ${createPayment}\n"

signPaymentTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${issuerAccountAstroDollarsPublicKey}\\\"" passphrase: \\\""${issuerAccountAstroDollarsPassphrase}\\\"" transaction_id: \\\""${createPaymentId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed AstroDollar payment transaction between Trustor ${trustorAccountPublicKey} and Issuer ${issuerAccountAstroDollarsPublicKey}  Result: ${signPaymentTransaction}\n"


createPayment=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createPayment (asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\""  sender_public_key: \\\""${issuerAccountGuntherDollarsPublicKey}\\\"" asset_code: \\\""${assetCodeGuntherDollars}\\\"", receiver_public_key: \\\""${trustorAccountPublicKey}\\\"", amount: \\\""1000\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.createPayment')
createPaymentId=$(echo ${createPayment} | jq --raw-output .id )
echo "Initiate GuntherDollar payment from Issuer ${issuerAccountGuntherDollarsPublicKey} to  Trustor ${trustorAccountPublicKey} ${createPayment}\n"

signPaymentTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${issuerAccountGuntherDollarsPublicKey}\\\"" passphrase: \\\""${issuerAccountGuntherDollarsPassphrase}\\\"" transaction_id: \\\""${createPaymentId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed GuntherDollar payment transaction between Trustor ${trustorAccountPublicKey} and Issuer ${issuerAccountGuntherDollarsPublicKey}  Result: ${signPaymentTransaction}\n"


echo "*******************************************************"

getIssuerBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${issuerAccountAstroDollarsPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify AstroDollar Issuer balance ${issuerAccountAstroDollarsPublicKey} ${getIssuerBalances}\n"


getIssuerBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${issuerAccountGuntherDollarsPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify GuntherDollar Issuer balance ${issuerAccountGuntherDollarsPublicKey} ${getIssuerBalances}\n"


getTrustorBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${trustorAccountPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify Trustor balance ${trustorAccountPublicKey} ${getTrustorBalances}\n"

echo "*******************************************************"

getIssuerHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${issuerAccountAstroDollarsPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance} ... on Payment {asset_type asset_issuer asset_code amount} }  }\"}" \
--compressed | jq --raw-output '.data.getHistory[]')
echo "Verify Issuer Account History ${issuerAccountAstroDollarsPublicKey}: \n ${getIssuerHistory}"

getTrustorHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${trustorAccountPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance} ... on Payment {asset_type asset_issuer asset_code amount} }  }\"}" \
--compressed | jq --raw-output '.data.getHistory[]')
echo "Verify Trustor Account History ${trustorAccountPublicKey}: \n ${getTrustorHistory} \n"

echo "*******************************************************"
echo "Accounts that require trust to be authorized/allowed."
echo "*******************************************************"

lockedDownAccountPassphrase="passphrase"
lockedDownAccount=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createAccount (description: \\\""lockedDownAccountAstroDollars\\\"" passphrase: \\\""${lockedDownAccountPassphrase}\\\"" trust_auth_required: true) { public_key ... on TF_Account { description email tenantId} } }\"}" --compressed | jq --raw-output '.data.createAccount')
lockedDownPublicKey=$(echo ${lockedDownAccount} | jq --raw-output .public_key )
echo "Created LockedDown Account for user ${userEmail}: publicKey:[${lockedDownPublicKey}]\n"

createAsset=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation{ createAsset (asset_issuer: \\\""${lockedDownPublicKey}\\\"",  asset_code:\\\""Locked\\\"" description:\\\""LockedDownAsset\\\"" ){asset_issuer asset_code} }\"}" \
--compressed | jq --raw-output '.data.createAsset')
lockedDownAssetIssuer=$(echo ${createAsset} | jq --raw-output .asset_issuer )
lockedDownAssetCode=$(echo ${createAsset} | jq --raw-output .asset_code )
echo "Issuer account created asset:[${lockedDownAssetIssuer}] for user ${userEmail}'s account publicKey:[${lockedDownPublicKey}]\n"

createTrustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createTrustTransaction (asset_issuer: \\\""${lockedDownAssetIssuer}\\\"" asset_code: \\\""${lockedDownAssetCode}\\\"" trustor_public_key: \\\""${trustorAccountPublicKey}\\\"" limit: \\\""1000\\\"" ){id description} }\"}" \
--compressed | jq --raw-output '.data.createTrustTransaction')
createTrustTransactionId=$(echo ${createTrustTransaction} | jq --raw-output .id )
echo "Establish trust between Trustor ${trustorAccountPublicKey} and AstroDollar Issuer ${lockedDownAssetIssuer}  Result Transaction Id: ${createTrustTransactionId}\n"

signTrustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${trustorAccountPublicKey}\\\"" passphrase: \\\""${trustorAccountPassphrase}\\\"" transaction_id: \\\""${createTrustTransactionId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed trust transaction between Trustor ${trustorAccountPublicKey} and AstroDollar Issuer ${lockedDownAssetIssuer}  Result: ${signTrustTransaction}\n"


createAllowTrustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createAllowTrustTransaction (asset_issuer: \\\""${lockedDownAssetIssuer}\\\"" asset_code: \\\""${lockedDownAssetCode}\\\"" trustor_public_key: \\\""${trustorAccountPublicKey}\\\""  authorize_trust: true ){id description} }\"}" \
--compressed | jq --raw-output '.data.createAllowTrustTransaction')
allowTrustTransactionId=$(echo ${createAllowTrustTransaction} | jq --raw-output .id )
echo "Allow trust between Trustor ${trustorAccountPublicKey} and Locked Down Issuer ${lockedDownAssetIssuer}  Result Transaction Id: ${allowTrustTransactionId}\n"

signTrustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${lockedDownPublicKey}\\\"" passphrase: \\\""${lockedDownAccountPassphrase}\\\"" transaction_id: \\\""${allowTrustTransactionId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Allow trust transaction between Trustor ${trustorAccountPublicKey} and Asset Issuer ${lockedDownAssetIssuer}  Result: ${signTrustTransaction}\n"

echo "*******************************************************"
echo "COMPLETED THE TRUSTOR/ISSUER FLOW.. NOW DISTRIBUTION"
echo "*******************************************************"

distributionAccountPassphrase="passphrase"
distributionAccount=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createAccount (description: \\\""distributionAccount\\\"" passphrase: \\\""${distributionAccountPassphrase}\\\""){ public_key ... on TF_Account { description email tenantId} } }\"}" \
--compressed | jq --raw-output '.data.createAccount')
distributionAccountPublicKey=$(echo ${distributionAccount} | jq --raw-output .public_key )

echo "Created Distribution Account for user ${userEmail}: distributionAccountPublicKey:[${distributionAccountPublicKey}]\n"

echo "*******************************************************"
echo "Payments AstroDollars and GuntherDollars"
echo "*******************************************************"

trustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createTrustTransaction (asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\"" asset_code: \\\""${assetCodeAstroDollars}\\\"" trustor_public_key: \\\""${distributionAccountPublicKey}\\\"" limit: \\\""1000\\\"" ){id description} }\"}" \
--compressed | jq --raw-output '.data.createTrustTransaction')
trustTransactionId=$(echo ${trustTransaction} | jq --raw-output .id )
echo "Establish trust between Distribution Account ${distributionAccountPublicKey} and Issuer ${issuerAccountAstroDollarsPublicKey}  Result: ${trustTransaction}\n"

signTrustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${distributionAccountPublicKey}\\\"" passphrase: \\\""${distributionAccountPassphrase}\\\"" transaction_id: \\\""${trustTransactionId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed trust transaction between Distribution Account ${distributionAccountPublicKey} and Issuer ${issuerAccountAstroDollarsPublicKey}  Result: ${signTrustTransaction}\n"


createPayment=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createPayment (asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\""  sender_public_key: \\\""${trustorAccountPublicKey}\\\"" asset_code: \\\""${assetCodeAstroDollars}\\\"", receiver_public_key: \\\""${distributionAccountPublicKey}\\\"", amount: \\\""1000\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.createPayment')
createPaymentId=$(echo ${createPayment} | jq --raw-output .id )
echo "Initiate payment from Trustor ${trustorAccountPublicKey} to Distribution Account ${distributionAccountPublicKey} ${createPayment}\n"

signPaymentTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${trustorAccountPublicKey}\\\"" passphrase: \\\""${trustorAccountPassphrase}\\\"" transaction_id: \\\""${createPaymentId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed payment transaction between Trustor ${trustorAccountPublicKey} and Distribution Account ${distributionAccountPublicKey}  Result: ${signPaymentTransaction}\n"


trustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createTrustTransaction (asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\"" asset_code: \\\""${assetCodeGuntherDollars}\\\"" trustor_public_key: \\\""${distributionAccountPublicKey}\\\"" limit: \\\""1000\\\"" ){id description} }\"}" \
--compressed | jq --raw-output '.data.createTrustTransaction')
trustTransactionId=$(echo ${trustTransaction} | jq --raw-output .id )
echo "Establish trust between Distribution Account ${distributionAccountPublicKey} and Gunther Issuer ${issuerAccountGuntherDollarsPublicKey}  Result: ${trustTransaction}\n"

signTrustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${distributionAccountPublicKey}\\\"" passphrase: \\\""${distributionAccountPassphrase}\\\"" transaction_id: \\\""${trustTransactionId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed trust transaction between Distribution Account ${distributionAccountPublicKey} and GuntherIssuer ${issuerAccountGuntherDollarsPublicKey}  Result: ${signTrustTransaction}\n"


createPayment=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createPayment (asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\""  sender_public_key: \\\""${trustorAccountPublicKey}\\\"" asset_code: \\\""${assetCodeGuntherDollars}\\\"", receiver_public_key: \\\""${distributionAccountPublicKey}\\\"", amount: \\\""1000\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.createPayment')
createPaymentId=$(echo ${createPayment} | jq --raw-output .id )
echo "Initiate payment from Trustor ${trustorAccountPublicKey} to Distribution Account ${distributionAccountPublicKey} ${createPayment}\n"

signPaymentTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${trustorAccountPublicKey}\\\"" passphrase: \\\""${trustorAccountPassphrase}\\\"" transaction_id: \\\""${createPaymentId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed payment transaction between Trustor ${trustorAccountPublicKey} and Distribution Account ${distributionAccountPublicKey}  Result: ${signPaymentTransaction}\n"


echo "*******************************************************"


getDistributionHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${distributionAccountPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance} ... on Payment {asset_type asset_issuer asset_code amount} ... on Allow_Trust {asset_type asset_issuer asset_code trustor trustee authorize} ... on Change_Trust {asset_type asset_issuer asset_code limit trustor trustee } }  }\"}" \
--compressed | jq --raw-output '.data.getHistory[]')
echo "Verify Distribution Account History ${distributionAccountPublicKey}: \n ${getDistributionHistory}"


getTrustorHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${trustorAccountPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance} ... on Payment {asset_type asset_issuer asset_code amount} ... on Allow_Trust {asset_type asset_issuer asset_code trustor trustee authorize} ... on Change_Trust {asset_type asset_issuer asset_code limit trustor trustee } }  }\"}" \
--compressed | jq --raw-output '.data.getHistory[]')
echo "Verify Trustor Account History ${trustorAccountPublicKey}: \n ${getTrustorHistory}"


echo "*******************************************************"


getDistributionBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${distributionAccountPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify Distribution Account balance ${distributionAccountPublicKey} ${getDistributionBalances}\n"


getTrustorBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${trustorAccountPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify Trustor Account balance ${trustorAccountPublicKey} ${getTrustorBalances}\n"


echo "*******************************************************"
echo "COMPLETED DISTRIBUTION.. NOW MULTSIGNATURE"
echo "*******************************************************"

cosignerAccountPassphrase="passphrase"
cosignerAccount=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createAccount (description: \\\""cosignerAccount\\\"" passphrase: \\\""${cosignerAccountPassphrase}\\\""){ public_key ... on TF_Account { description email tenantId} } }\"}" \
--compressed | jq --raw-output '.data.createAccount')
cosignerAccountPublicKey=$(echo ${cosignerAccount} | jq --raw-output .public_key )

echo "Created Co-Signer Account for user ${userEmail}: cosignerAccountPublicKey:[${cosignerAccountPublicKey}]\n"

echo "*******************************************************"

createSignerTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createSignerTransaction (public_key: \\\""${distributionAccountPublicKey}\\\"" signer: \\\""${cosignerAccountPublicKey}\\\"" weight: 1 ){id description} }\"}" \
--compressed  | jq --raw-output '.data.createSignerTransaction')
createSignerTransactionId=$(echo ${createSignerTransaction} | jq --raw-output .id )
echo "Distribution Account ${distributionAccountPublicKey} added Co-Signer Account ${cosignerAccountPublicKey} as signer Result: ${createSignerTransaction}\n"

signTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${distributionAccountPublicKey}\\\"" passphrase: \\\""${distributionAccountPassphrase}\\\"" transaction_id: \\\""${createSignerTransactionId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed addSigner transaction between Distribution Account ${distributionAccountSecret} and Co-Signer Account ${distributionAccountPublicKey}  Result: ${signTransaction}\n"


createWeightThresholdTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createWeightThresholdTransaction (public_key: \\\""${distributionAccountPublicKey}\\\""  weight: 1 low: 1 medium:2 high:2 ){id description} }\"}" \
--compressed  | jq --raw-output '.data.createWeightThresholdTransaction')
createWeightThresholdTransactionId=$(echo ${createWeightThresholdTransaction} | jq --raw-output .id )
echo "Distribution Account ${distributionAccountPublicKey}  established tresholds for transaction Result: ${createSignerTransaction}\n"

signTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${distributionAccountPublicKey}\\\"" passphrase: \\\""${distributionAccountPassphrase}\\\"" transaction_id: \\\""${createWeightThresholdTransactionId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed weight treshold transaction for ${distributionAccountSecret} Result: ${signTransaction}\n"

echo "*******************************************************"
customerAccountPassphrase="passphrase"
customerAccount=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createAccount (description: \\\""customerAccount\\\"" passphrase: \\\""${customerAccountPassphrase}\\\"" ){public_key ... on TF_Account { email tenantId } } }\"}" \
--compressed | jq --raw-output '.data.createAccount')
customerAccountPublicKey=$(echo ${customerAccount} | jq --raw-output .public_key )
echo "Created Customer Account for user ${userEmail}: customerAccountPublicKey:[${customerAccountPublicKey}]\n"

trustAssetTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createTrustTransaction (asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\"" asset_code: \\\""${assetCodeAstroDollars}\\\"" trustor_public_key: \\\""${customerAccountPublicKey}\\\"" limit: \\\""1000\\\"" ){id description} }\"}" \
--compressed | jq --raw-output '.data.createTrustTransaction')
trustTransactionId=$(echo ${trustAssetTransaction} | jq --raw-output .id )
echo "Establish trust between Customer Account ${distributionAccountPublicKey} and Issuer ${issuerAccountAstroDollarsPublicKey}  Result: ${trustAssetTransaction}\n"

signTrustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${customerAccountPublicKey}\\\"" passphrase: \\\""${customerAccountPassphrase}\\\"" transaction_id: \\\""${trustTransactionId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed trust transaction between Customer Account ${distributionAccountPublicKey} and Issuer ${issuerAccountAstroDollarsPublicKey}  Result: ${signTrustTransaction}\n"

echo "*******************************************************"


createPayment=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createPayment (asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\""  sender_public_key: \\\""${distributionAccountPublicKey}\\\"" asset_code: \\\""${assetCodeAstroDollars}\\\"", receiver_public_key: \\\""${customerAccountPublicKey}\\\"", amount: \\\""1000\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.createPayment')
createPaymentId=$(echo ${createPayment} | jq --raw-output .id )
echo "Initiate payment from Distribution Account ${distributionAccountPublicKey} to Customer Account ${customerAccountPublicKey} ${createPayment}\n"

echo "*******************************************************"

signPaymentTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${distributionAccountPublicKey}\\\"" passphrase: \\\""${distributionAccountPassphrase}\\\"" transaction_id: \\\""${createPaymentId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed payment transaction between Distribution Account ${distributionAccountPublicKey} and Customer Account ${customerAccountPublicKey}  Result: ${signPaymentTransaction}\n"


signPaymentTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${cosignerAccountPublicKey}\\\"" passphrase: \\\""${cosignerAccountPassphrase}\\\"" transaction_id: \\\""${createPaymentId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Co-Signer (cosignerAccountPublicKey) signed payment transaction between Distribution Account ${distributionAccountPublicKey} and Customer Account ${customerAccountPublicKey}  Result: ${signPaymentTransaction}\n"


echo "*******************************************************"

getCustomerHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${customerAccountPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance} ... on Payment {asset_type asset_issuer asset_code amount} }  }\"}" \
--compressed | jq --raw-output '.data.getHistory[]')
echo "Verify Customer Account history ${customerAccountPublicKey} ${getCustomerHistory}\n"


getDistributionHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${distributionAccountPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance} ... on Payment {asset_type asset_issuer asset_code amount} }  }\"}" \
--compressed | jq --raw-output '.data.getHistory[]')
echo "Verify Distribution Account history ${distributionAccountPublicKey} ${getDistributionHistory}\n"


echo "*******************************************************"

getCustomerBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${customerAccountPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify Customer Account balance ${customerAccountPublicKey} ${getCustomerBalances}\n"


getDistributionBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${distributionAccountPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify Distribution Account balance ${distributionAccountPublicKey} ${getDistributionBalances}\n"


echo "*******************************************************"
echo "COMPLETED MULTISIGNATURE. NOW OFFERS"
echo "*******************************************************"
echo "Set thresholds back to default for Distribution Account\n"

createWeightThresholdTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createWeightThresholdTransaction (public_key: \\\""${distributionAccountPublicKey}\\\""  weight: 1 low: 0 medium:0 high:0 ){id description} }\"}" \
--compressed  | jq --raw-output '.data.createWeightThresholdTransaction')
createWeightThresholdTransactionId=$(echo ${createWeightThresholdTransaction} | jq --raw-output .id )
echo "Distribution Account ${distributionAccountPublicKey}  established tresholds for transaction Result: ${createSignerTransaction}\n"

signTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${distributionAccountPublicKey}\\\"" passphrase: \\\""${distributionAccountPassphrase}\\\"" transaction_id: \\\""${createWeightThresholdTransactionId}\\\""  ){id description submitted hash} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed weight treshold transaction for ${distributionAccountSecret} Result: ${signTransaction}\n"

signPaymentTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${cosignerAccountPublicKey}\\\"" passphrase: \\\""${cosignerAccountPassphrase}\\\"" transaction_id: \\\""${createWeightThresholdTransactionId}\\\""  ){id description submitted hash} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Co-Signer (cosignerAccountPublicKey) signed transaction to not require multi-signature  Result: ${signPaymentTransaction}\n"


customerToddAccountPassphrase="passphrase"
customerToddAccount=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createAccount (description: \\\""customerToddAccount\\\"" passphrase: \\\""${customerToddAccountPassphrase}\\\""){public_key  ... on TF_Account { email tenantId }  } }\"}" \
--compressed | jq --raw-output '.data.createAccount')
customerToddAccountPublicKey=$(echo ${customerToddAccount} | jq --raw-output .public_key )
echo "Created Customer Todd Account for user ${userEmail}: customerAccountPublicKey:[${customerToddAccountPublicKey}] \n"


echo "*******************************************************"
echo "Deposit funds into Customer Todd Account\n"

trustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createTrustTransaction (asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\"" asset_code: \\\""${assetCodeGuntherDollars}\\\"" trustor_public_key: \\\""${customerToddAccountPublicKey}\\\"" limit: \\\""1000\\\"" ){id description} }\"}" \
--compressed | jq --raw-output '.data.createTrustTransaction')
trustTransactionId=$(echo ${trustTransaction} | jq --raw-output .id )
echo "Establish trust between Customer Todd Account ${customerToddAccountPublicKey} and Gunther Issuer ${issuerAccountGuntherDollarsPublicKey}  Result: ${trustTransaction}\n"

signTrustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${customerToddAccountPublicKey}\\\"" passphrase: \\\""${customerToddAccountPassphrase}\\\"" transaction_id: \\\""${trustTransactionId}\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed trust transaction between Customer Todd Account ${customerToddAccountPublicKey} and GuntherIssuer ${issuerAccountGuntherDollarsPublicKey}  Result: ${signTrustTransaction}\n"


getDistributionBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${distributionAccountPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify Distribution Account balance ${distributionAccountPublicKey} ${getDistributionBalances}\n"


createPayment=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createPayment (asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\""  sender_public_key: \\\""${distributionAccountPublicKey}\\\"" asset_code: \\\""${assetCodeGuntherDollars}\\\"", receiver_public_key: \\\""${customerToddAccountPublicKey}\\\"", amount: \\\""1000\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.createPayment')
createPaymentId=$(echo ${createPayment} | jq --raw-output .id )
echo "Initiate payment from Distribution Account ${distributionAccountPublicKey} to Customer Todd Account ${customerToddAccountPublicKey} Result: ${createPayment}\n"

signPaymentTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${distributionAccountPublicKey}\\\"" passphrase: \\\""${distributionAccountPassphrase}\\\"" transaction_id: \\\""${createPaymentId}\\\""  ){id description submitted hash} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed payment transaction between Distribution Account ${distributionAccountPublicKey} to Customer Todd Account ${customerToddAccountPublicKey}  Result: ${signPaymentTransaction}\n"


getDistributionBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${distributionAccountPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify Distribution Account balance ${distributionAccountPublicKey} ${getDistributionBalances}\n"

getDistributionBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${customerToddAccountPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify Distribution Account balance ${customerToddAccountPublicKey} ${getDistributionBalances}\n"


getCustomerAccountToddHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${customerToddAccountPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance} ... on Payment {asset_type asset_issuer asset_code amount} }  }\"}" \
--compressed | jq --raw-output '.data.getHistory[]')
echo "Verify Customer Account Todd Account history ${customerToddAccountPublicKey} ${getCustomerAccountToddHistory}\n"



echo "*******************************************************"
echo "Establish trust of assets to exchange\n"

trustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createTrustTransaction (asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\"" asset_code: \\\""${assetCodeAstroDollars}\\\"" trustor_public_key: \\\""${customerToddAccountPublicKey}\\\"" limit: \\\""1000\\\"" ){id description } }\"}" \
--compressed | jq --raw-output '.data.createTrustTransaction')
trustTransactionId=$(echo ${trustTransaction} | jq --raw-output .id )
echo "Establish trust between Customer Todd Account ${customerToddAccountPublicKey} and Astro Dollar Issuer ${issuerAccountAstroDollarsPublicKey}  Result: ${trustTransaction}\n"

signTrustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${customerToddAccountPublicKey}\\\"" passphrase: \\\""${customerToddAccountPassphrase}\\\"" transaction_id: \\\""${trustTransactionId}\\\""  ){id description submitted hash} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed trust transaction between Customer Todd Account ${customerToddAccountPublicKey} and Astro Dollar Issuer ${issuerAccountGuntherDollarsPublicKey}  Result: ${signTrustTransaction}\n"

trustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createTrustTransaction (asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\"" asset_code: \\\""${assetCodeGuntherDollars}\\\"" trustor_public_key: \\\""${customerAccountPublicKey}\\\"" limit: \\\""1000\\\"" ){id description} }\"}" \
--compressed | jq --raw-output '.data.createTrustTransaction')
trustTransactionId=$(echo ${trustTransaction} | jq --raw-output .id )
echo "Establish trust between Customer Account ${customerAccountPublicKey} and Gunther Dollar Issuer ${issuerAccountGuntherDollarsPublicKey}  Result: ${trustTransaction}\n"

signTrustTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${customerAccountPublicKey}\\\"" passphrase: \\\""${customerAccountPassphrase}\\\"" transaction_id: \\\""${trustTransactionId}\\\""  ){id description submitted hash} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed trust transaction between Customer Account ${customerAccountPublicKey} and Gunther Dollar Issuer ${issuerAccountGuntherDollarsPublicKey}  Result: ${signTrustTransaction}\n"

echo "*******************************************************"
echo "Make exchanging offers\n"

createNewOffer=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createOffer (public_key: \\\""${customerToddAccountPublicKey}\\\"" sell_asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\""  sell_asset_code: \\\""${assetCodeGuntherDollars}\\\"" sell_amount: \\\""200\\\""  buy_asset_code: \\\""${assetCodeAstroDollars}\\\"" buy_asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\""  buy_amount: \\\""200\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.createOffer')
createNewOfferId=$(echo ${createNewOffer} | jq --raw-output .id )
echo "Initiate new offer from Customer Todd Account ${customerToddAccountPublicKey} Gunther for Astro Dollars account Result: ${createNewOffer}\n"

signNewOfferTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${customerToddAccountPublicKey}\\\"" passphrase: \\\""${customerToddAccountPassphrase}\\\"" transaction_id: \\\""${createNewOfferId}\\\""  ){id description submitted hash } }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed offer transaction for Customer Account ${customerToddAccountPublicKey}  Gunther for Astro Dollars account Result: ${signNewOfferTransaction}\n"

getOffers=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getOffers (public_key:\\\""${customerToddAccountPublicKey}\\\"") {id selling {asset_issuer asset_type asset_code} buying {asset_issuer asset_type asset_code} price amount} }\"}" \
--compressed | jq --raw-output '.data.getOffers[]')
offerId=$(echo ${getOffers} | jq --raw-output .id )
echo "Offer id: ${offerId}\n"

createAnotherNewOffer=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createOffer (public_key: \\\""${customerToddAccountPublicKey}\\\"" sell_asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\""  sell_asset_code: \\\""${assetCodeGuntherDollars}\\\"" sell_amount: \\\""100\\\""  buy_asset_code: \\\""${assetCodeAstroDollars}\\\"" buy_asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\""  buy_amount: \\\""100\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.createOffer')
createAnotherNewOfferId=$(echo ${createAnotherNewOffer} | jq --raw-output .id )
echo "Initiate another new offer from Customer Todd Account ${customerToddAccountPublicKey} Gunther for Astro Dollars account Result: ${createAnotherNewOffer}\n"

signAnotherNewOfferTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${customerToddAccountPublicKey}\\\"" passphrase: \\\""${customerToddAccountPassphrase}\\\"" transaction_id: \\\""${createAnotherNewOfferId}\\\""  ){id description submitted hash } }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed offer transaction for Customer Account ${customerToddAccountPublicKey}  Gunther for Astro Dollars account Result: ${signNewOfferTransaction}\n"

getOfferWithAmount100=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getOffers (public_key:\\\""${customerToddAccountPublicKey}\\\"") {id selling {asset_issuer asset_type asset_code} buying {asset_issuer asset_type asset_code} price amount} }\"}" \
--compressed | jq --raw-output '.data.getOffers[] | select (.amount == "100.0000000")')
offerWithAmountId=$(echo ${getOfferWithAmount100} | jq --raw-output .id )
echo "Offer id with amount 100: ${offerWithAmountId}\n"

deleteOffer=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { deleteOffer (public_key: \\\""${customerToddAccountPublicKey}\\\"" offer_id: \\\""${offerWithAmountId}\\\"" sell_asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\""  sell_asset_code: \\\""${assetCodeGuntherDollars}\\\""  buy_asset_code: \\\""${assetCodeAstroDollars}\\\"" buy_asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\""){id description} }\"}" \
--compressed | jq --raw-output '.data.deleteOffer')
deleteOfferId=$(echo ${deleteOffer} | jq --raw-output .id )
echo "Initiate deletion of offer from Customer Todd Account ${customerToddAccountPublicKey} Gunther for Astro Dollars account Result: ${deleteOffer}\n"

signDeleteOfferTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${customerToddAccountPublicKey}\\\"" passphrase: \\\""${customerToddAccountPassphrase}\\\"" transaction_id: \\\""${deleteOfferId}\\\""  ){id description submitted hash } }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed delete offer transaction for Customer Account ${customerToddAccountPublicKey}  Gunther for Astro Dollars account Result: ${signDeleteOfferTransaction}\n"

createAnotherNewOffer=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createOffer (public_key: \\\""${customerToddAccountPublicKey}\\\"" sell_asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\""  sell_asset_code: \\\""${assetCodeGuntherDollars}\\\"" sell_amount: \\\""400\\\""  buy_asset_code: \\\""${assetCodeAstroDollars}\\\"" buy_asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\""  buy_amount: \\\""400\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.createOffer')
createAnotherNewOfferId=$(echo ${createAnotherNewOffer} | jq --raw-output .id )
echo "Initiate another new offer from Customer Todd Account ${customerToddAccountPublicKey} Gunther for Astro Dollars account Result: ${createNewOffer}\n"

signAnotherNewOfferTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${customerToddAccountPublicKey}\\\"" passphrase: \\\""${customerToddAccountPassphrase}\\\"" transaction_id: \\\""${createAnotherNewOfferId}\\\""  ){id description submitted hash } }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed offer transaction for Customer Account ${customerToddAccountPublicKey}  Gunther for Astro Dollars account Result: ${signNewOfferTransaction}\n"

getOrderBook=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getOrderbook (buy_asset_code:\\\""${assetCodeAstroDollars}\\\"" buy_asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\"" sell_asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\"" sell_asset_code: \\\""${assetCodeGuntherDollars}\\\"") { bids { price amount } asks { price amount} base {asset_code asset_type} counter {asset_code asset_type}  } }\"}" \
--compressed | jq --raw-output '.data.getOrderbook')
echo "OrderBook ${getOrderBook}\n"
counterAssetCode=$(echo ${getOrderBook} | jq --raw-output .counter.asset_code )
baseAssetCode=$(echo ${getOrderBook} | jq --raw-output .base.asset_code )
echo "OrderBook counter asset code ${counterAssetCode}\n"
echo "OrderBook base asset code ${baseAssetCode}\n"

createNewOffer=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createOffer (public_key: \\\""${customerAccountPublicKey}\\\"" sell_asset_issuer: \\\""${issuerAccountAstroDollarsPublicKey}\\\""  sell_asset_code: \\\""${assetCodeAstroDollars}\\\"" sell_amount: \\\""400\\\""  buy_asset_code: \\\""${assetCodeGuntherDollars}\\\"" buy_asset_issuer: \\\""${issuerAccountGuntherDollarsPublicKey}\\\""  buy_amount: \\\""400\\\""  ){id description} }\"}" \
--compressed | jq --raw-output '.data.createOffer')
createNewOfferId=$(echo ${createNewOffer} | jq --raw-output .id )
echo "Initiate new offer from Customer Account ${customerAccountPublicKey} Astro for Gunther Dollars account Result: ${createNewOffer}\n"

signNewOfferTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { signTransaction (public_key: \\\""${customerAccountPublicKey}\\\"" passphrase: \\\""${customerAccountPassphrase}\\\"" transaction_id: \\\""${createNewOfferId}\\\""  ){id description  submitted hash} }\"}" \
--compressed | jq --raw-output '.data.signTransaction')
echo "Signed offer transaction for Customer Account ${customerAccountPublicKey} and Gunther Dollar Issuer Result: ${signNewOfferTransaction}\n"


getCustomerBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${customerAccountPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify Customer Account balance ${customerAccountPublicKey} ${getCustomerBalances}\n"


getCustomerToddBalances=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getBalances(public_key: \\\""${customerToddAccountPublicKey}\\\"") {network asset_code balance } }\"}" \
--compressed | jq --raw-output '.data.getBalances[]')
echo "Verify Customer Todd Account balance ${customerToddAccountPublicKey} ${getCustomerToddBalances}\n"


echo "*******************************************************"
echo "Demo a pre-authorized transaction with followup submission\n"

newPreAuthingAccountPassphrase="passphrase"
newPreAuthingAccount=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createAccount (description: \\\""newPreAuthingAccount\\\"" passphrase: \\\""${newPreAuthingAccountPassphrase}\\\"") {public_key ... on TF_Account { description email tenantId } } }\"}" --compressed | jq --raw-output '.data.createAccount')
newPreAuthingAccountPublicKey=$(echo ${newPreAuthingAccount} | jq --raw-output .public_key )
echo "Created New Pre-Authorizing Account for user ${userEmail}: publicKey:[${newPreAuthingAccountPublicKey}]\n"

approvingAccountPassphrase="passphrase"
approvingAccount=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createAccount (description: \\\""approvingAccount\\\"" passphrase: \\\""${approvingAccountPassphrase}\\\"") {public_key ... on TF_Account { description email tenantId } } }\"}" --compressed | jq --raw-output '.data.createAccount')
approvingAccountPublicKey=$(echo ${approvingAccount} | jq --raw-output .public_key )
echo "Created New Approving Account for user ${userEmail}: publicKey:[${approvingAccountPublicKey}]\n"

paymentReceivingAccountPassphrase="passphrase"
paymentReceivingAccount=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createAccount (description: \\\""paymentReceivingAccount\\\"" passphrase: \\\""${paymentReceivingAccountPassphrase}\\\"") {public_key ... on TF_Account { description email tenantId } } }\"}" --compressed | jq --raw-output '.data.createAccount')
paymentReceivingAccountPublicKey=$(echo ${paymentReceivingAccount} | jq --raw-output .public_key )
echo "Created Payment Receiving Account for user ${userEmail}: publicKey:[${paymentReceivingAccountPublicKey}]\n"

createPreAuthorizedPayment=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { createPayment (sender_public_key: \\\""${newPreAuthingAccountPublicKey}\\\"" asset_code: \\\""XLM\\\"" asset_issuer: \\\""\\\"" receiver_public_key: \\\""${paymentReceivingAccountPublicKey}\\\"" amount: \\\""100\\\"" pre_authorize_transaction: true){id description} }\"}" \
--compressed | jq --raw-output '.data.createPayment')
createPreAuthPaymentId=$(echo ${createPreAuthorizedPayment} | jq --raw-output .id )
echo "Initiate Pre-Authorized XLM payment from Pre-Authing Acct ${newPreAuthingAccountPublicKey} to Receiver ${paymentReceivingAccountPublicKey} ${createPayment}\n"

preAuthorizeTransactionWithAnApprover=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { preAuthorizeTransaction (public_key: \\\""${newPreAuthingAccountPublicKey}\\\"" passphrase: \\\""${newPreAuthingAccountPassphrase}\\\"" transaction_id: \\\""${createPreAuthPaymentId}\\\""  final_approver: \\\""${approvingAccountPublicKey}\\\""  ){id description submitted hash } }\"}" \
--compressed | jq --raw-output '.data.preAuthorizeTransaction')
echo "Pre-Authorize Payment Transaction from account with Approver Result: ${preAuthorizeTransactionWithAnApprover}\n"

getTransactionToApprove=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getTransactionsToSign(public_key: \\\""${approvingAccountPublicKey}\\\"") {id type source_acct description  submitted signers{public_key signed} preAuthApprovers{public_key signed}  } }\"}" \
--compressed | jq --raw-output '.data.getTransactionsToSign[].id')
echo "Verify transaction to approve for ${approvingAccountPublicKey}: ${getTransactionToApprove}\n"

approvePreAuthorizedTransaction=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \"mutation { submitPreAuthorizedTransaction (transaction_id: \\\""${getTransactionToApprove}\\\""  final_approver: \\\""${approvingAccountPublicKey}\\\""  ){id description submitted hash } }\"}" \
--compressed | jq --raw-output '.data.submitPreAuthorizedTransaction')
echo "Approve Pre-Authorized Payment Transaction - Result: ${approvePreAuthorizedTransaction}\n"

echo "*******************************************************"

getCustomerHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${customerAccountPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance} ... on Payment {asset_type asset_issuer asset_code amount} ... on Manage_Offer {buying_asset_type buying_asset_code buying_asset_issuer selling_asset_type selling_asset_code selling_asset_issuer amount offer_id price } } }\"}" \
--compressed | jq --raw-output '.data.getHistory[]')
echo "Verify Customer Account history ${customerAccountPublicKey} ${getCustomerHistory}\n"


getCustomerHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${customerToddAccountPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance} ... on Payment {asset_type asset_issuer asset_code amount} ... on Manage_Offer {buying_asset_type buying_asset_code buying_asset_issuer selling_asset_type selling_asset_code selling_asset_issuer amount offer_id price } } }\"}" \
--compressed | jq --raw-output '.data.getHistory[]')
echo "Verify Customer Todd Account history ${customerToddAccountPublicKey} ${getCustomerHistory}\n"


echo "*******************************************************"

getCustomerHistory=$(curl -s "${ENDPOINT}/token-factory" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H "Authorization: Bearer ${authToken}"  \
-H 'Content-Type: application/json' -H 'Accept: application/json' \
--data "{\"query\": \" { getHistory (public_key: \\\""${customerAccountPublicKey}\\\"") { id source_account type created_at ... on Create_Account {starting_balance} ... on Payment {asset_type asset_issuer asset_code amount} ... on Manage_Offer {buying_asset_type buying_asset_code buying_asset_issuer selling_asset_type selling_asset_code selling_asset_issuer amount offer_id price }  ... on Account_Flags{ clear_flags_s set_flags_s} } }\"}" \
--compressed | jq --raw-output '.data.getHistory[]')
echo "Verify Customer Account history ${customerAccountPublicKey} ${getCustomerHistory}\n"



if [[ -z ${CLEAN} || ${CLEAN} == "true" ]]; then
	echo "*******************************************************"
	echo "CLEANUP"
	echo "*******************************************************"

	# CLEANUP
	deleteUser=$(curl -s "${ENDPOINT}/token-factory" \
	-H 'Accept-Encoding: gzip, deflate, br' \
	-H "Authorization: Bearer ${authToken}"  \
	-H 'Content-Type: application/json' -H 'Accept: application/json' \
	--data "{\"query\": \"mutation { deleteUser (id: \\\""${userId}\\\"")  { email }  }\"}" \
	--compressed)
	echo "Verify deletion of user ${EMAIL}: ${deleteUser}\n"


	deleteTenant=$(curl -s "${ENDPOINT}/token-factory" \
	 -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' \
	 -H 'Accept: application/json' -H 'Connection: keep-alive' \
	 --data-binary "{\"query\":\"mutation {deleteTenant(id: \\\""${tenantId}\\\"") { name} }\"}" \
	 --compressed | jq --raw-output '.data.deleteTenant')
	echo "Verify deletion of tenant ${randomTenant}: ${deleteTenant}\n"
else
  	echo "*******************************************************"
	echo "SKIP CLEANUP"
	echo "*******************************************************"
fi
