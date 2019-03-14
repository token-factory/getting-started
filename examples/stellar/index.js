const Stellar = require('stellar-sdk');
const rp = require('request-promise');
//global stellar variable
Stellar.Network.useTestNetwork();
const server = new Stellar.Server('https://horizon-testnet.stellar.org');

createAccount = async function(){
	let keyPair = Stellar.Keypair.random();

        await rp.get({
            //get initial token from testnet firendbot
            uri: 'https://horizon-testnet.stellar.org/friendbot',
            qs: { addr: keyPair.publicKey() },
            json: true
        });
        return keyPair;
}

changeData = async function (publicKey, secret){
	const account = await server.loadAccount(publicKey);
    const trustTransaction = await new Stellar.TransactionBuilder(account)
        .addOperation(
            Stellar.Operation.manageData(
				{ name: 'foo', value : 'bar'}
            )
        ).addOperation(
            Stellar.Operation.manageData(
				{ name: 'todd', value : '5'}
            )
        ).build();
    const keypair = Stellar.Keypair.fromSecret(secret);
    await trustTransaction.sign(keypair);
	await server.submitTransaction(trustTransaction);
	
	console.log('account data var ref', account.data );
	console.log('account data_attr var ref', account.data_attr );
	console.log('account data function ref', await account.data("") );

    return trustTransaction;
}


createAsset = async function(account, assetCode){
	console.log('assetCode', [assetCode, account.publicKey()]);
	const asset = await new Stellar.Asset(assetCode, account.publicKey());
	return asset;
}
changeAssetTrustLevel = async function (publicKey, secret, asset, limit){
	const account = await server.loadAccount(publicKey);
    const trustTransaction = await new Stellar.TransactionBuilder(account)
        .addOperation(
            Stellar.Operation.changeTrust({
                asset: asset,
                limit: limit
            })
        ).build();
    const keypair = Stellar.Keypair.fromSecret(secret);
    await trustTransaction.sign(keypair);
    await server.submitTransaction(trustTransaction);
    return trustTransaction;
}

makePayment = async function (publicKey, receiverPublicKey, asset, amount){
	const account = await server.loadAccount(publicKey);
    const transaction = await new Stellar.TransactionBuilder(account)
        .addOperation(
            Stellar.Operation.payment({
                destination: receiverPublicKey,
                asset: asset,
                amount: amount
            })
        ).build();

  return transaction;
}

signTransaction = async function (transaction, secret){
	const keypair = await Stellar.Keypair.fromSecret(secret);
	await transaction.sign(keypair);
	return transaction;
}

commitTransaction = async function (transaction){
	const transactionResult = await server.submitTransaction(transaction);
	return transactionResult;
}

serializeTransaction = async function (transaction){
	const base64XDR = transaction.toEnvelope().toXDR().toString('base64');
	return base64XDR;
}

deserializeTransaction = async function (base64XDR){
	const rehydratedTransaction = new Stellar.Transaction(base64XDR);
	return rehydratedTransaction;
}

getBalances = async function (publicKey){
	const account = await server.loadAccount(publicKey);
    return account.balances;
}

getHistory = async function (publicKey){
    let historyPage = await server
	    .transactions()
	    .forAccount(publicKey)
	    .call();
	let history = [];
	let records = historyPage.records;
	while (records.length !== 0) {
	    for (let i = 0; i < records.length; i += 1) {
	        let transaction = records[i];
	        let operations = await transaction.operations();
	        let record = operations.records[0];
	        history.push(record);
	    }
	    historyPage = await historyPage.next();
	    records = historyPage.records;
	}
    return history;
}


addSigner = async function (publicKey, secret, secondaryAddress){
	const rootKeypair = await Stellar.Keypair.fromSecret(secret);
	const account = await server.loadAccount(publicKey);
	const transaction = await new Stellar.TransactionBuilder(account)
		.addOperation(Stellar.Operation.setOptions({
			signer: {
				ed25519PublicKey: secondaryAddress,
				weight: 1
			}
		})).build();
	await transaction.sign(rootKeypair);
	const transactionResult = await server.submitTransaction(transaction);
    return transactionResult;
}


setWeights = async function (publicKey, secret, masterWeight, lowThreshold, medThreshold, highThreshold){
	const rootKeypair = await Stellar.Keypair.fromSecret(secret);
	const account = await server.loadAccount(publicKey);
	const transaction = await new Stellar.TransactionBuilder(account)
		.addOperation(Stellar.Operation.setOptions({
			masterWeight: masterWeight, // set master key weight
			lowThreshold: lowThreshold,
			medThreshold: medThreshold, // a payment is medium threshold
			highThreshold: highThreshold // make sure to have enough weight to add up to the high threshold!
	  	}
	)).build();
	await transaction.sign(rootKeypair);
	const transactionResult = await server.submitTransaction(transaction);
    return transactionResult;
}


simpleFlow = async function(){
	console.log("Simple Flow");

	console.log('creating new issuing account');
	const issuingAccount = await createAccount();

	await changeData(issuingAccount.publicKey(), issuingAccount.secret());

	console.log('issuingAccount', issuingAccount);
	return;


	console.log('creating new trustor account');
	const trustorAccount = await createAccount();
	const asset = await createAsset(issuingAccount, 'AstroDollars');
	console.log('created new asset for trustor account', JSON.stringify( asset, null, 2)) ;
	const changedtrustorTrustLevel = await changeAssetTrustLevel(trustorAccount.publicKey(), trustorAccount.secret(), asset, '1000000');
	console.log('Creating trust level: trustorAccount balance', await getBalances(trustorAccount.publicKey()));

	const payment = await makePayment(issuingAccount.publicKey(), trustorAccount.publicKey(),  asset, '1000000');
	let transaction = await signTransaction (payment, issuingAccount.secret());
	await commitTransaction (transaction);

	console.log('After transfer to issuing: issuingAccount balance', JSON.stringify(await getBalances(issuingAccount.publicKey()), null, 2));
	console.log('After transfer to issuing: trustorAccount balance', JSON.stringify(await getBalances(trustorAccount.publicKey()), null, 2));


	console.log('After transfer to issuing: trustorAccount history', JSON.stringify(await getHistory(trustorAccount.publicKey()), null, 2));


	console.log('creating new distribution account');
	const distributionAccount = await createAccount();
	const changedTrustLevel = await changeAssetTrustLevel(distributionAccount.publicKey(), distributionAccount.secret(), asset, '40000');


	console.log('Making payment to end user');
	const changedDistributor = await makePayment(trustorAccount.publicKey(),  distributionAccount.publicKey(),  asset, '40000');
	transaction = await signTransaction (changedDistributor, trustorAccount.secret());
	await commitTransaction (transaction);

	console.log('After transfer to distributor: issuingAccount balance', JSON.stringify(await getBalances(issuingAccount.publicKey()), null, 2));
	console.log('After transfer to distributor: trustorAccount balance', JSON.stringify(await getBalances(trustorAccount.publicKey()), null, 2));
	console.log('After transfer to distributor: distributionAccount balance', JSON.stringify(await getBalances(distributionAccount.publicKey()), null, 2));


	console.log('creating new distribution2 account');
	const distributionAccount2 = await createAccount();
	const changedTrustLevel2 = await changeAssetTrustLevel(distributionAccount2.publicKey(), distributionAccount2.secret(), asset, '40000');


	console.log('Making payment to end user');
	const changedDistributor2 = await makePayment(trustorAccount.publicKey(), distributionAccount2.publicKey(),  asset, '40000');
	transaction = await signTransaction (changedDistributor2, trustorAccount.secret());
	await commitTransaction (transaction);
	console.log('After transfer to distributor: issuingAccount balance', JSON.stringify(await getBalances(issuingAccount.publicKey()), null, 2));
	console.log('After transfer to distributor: trustorAccount balance', JSON.stringify(await getBalances(trustorAccount.publicKey()), null, 2));
	console.log('After transfer to distributor: distributionAccount2 balance', JSON.stringify(await getBalances(distributionAccount2.publicKey()), null, 2));
};


multisigFlow = async function(){
	console.log("Multi Signature Flow");
	console.log('creating new issuing account');
	const issuingAccount = await createAccount();

	console.log('creating new trustor account');
	const trustorAccount = await createAccount();

	console.log('Added trustor account to issuing account');
	const addedSigner = await addSigner (issuingAccount.publicKey(), issuingAccount.secret(), trustorAccount.publicKey())

	console.log('Established threshold and weights for signing');
	const setThreshold = await setWeights (issuingAccount.publicKey(), issuingAccount.secret(), 1, 1, 2, 2)

	const asset = await createAsset(issuingAccount, 'AstroDollars');
	console.log('created new asset for trustor account', JSON.stringify(asset, null, 2));

	console.log('Before transfer to issuing: issuingAccount balance', JSON.stringify(await getBalances(issuingAccount.publicKey()), null, 2));
	console.log('Before transfer to issuing: trustorAccount balance', JSON.stringify(await getBalances(trustorAccount.publicKey()), null, 2));

	const changedtrustorTrustLevel = await changeAssetTrustLevel(trustorAccount.publicKey(), trustorAccount.secret(), asset, '1000000');

	const payment = await makePayment(issuingAccount.publicKey(), trustorAccount.publicKey(),  asset, '1000000');

	let serializedPayment = await serializeTransaction(payment);
	console.log('Serialized payment: ' + serializedPayment);

	let transaction = await signTransaction (payment, issuingAccount.secret());
	let serializedPaymentWithOneSig = await serializeTransaction(transaction);
	console.log('Serialized payment after one sig: ' + serializedPaymentWithOneSig);

	let rehydratedTransaction = await deserializeTransaction(serializedPaymentWithOneSig);
	rehydratedTransaction = await signTransaction (rehydratedTransaction, trustorAccount.secret());
	let serializedTransactionWithTwoSigs = await serializeTransaction(rehydratedTransaction);
	console.log('Serialized payment after two sigs:' + serializedTransactionWithTwoSigs);
	await commitTransaction (rehydratedTransaction);

	console.log('After transfer to issuing: issuingAccount balance', JSON.stringify(await getBalances(issuingAccount.publicKey()), null, 2));
	console.log('After transfer to issuing: trustorAccount balance', JSON.stringify(await getBalances(trustorAccount.publicKey()), null, 2));

	console.log('After transfer to issuing: trustorAccount history', JSON.stringify(await getHistory(issuingAccount.publicKey()), null, 2));
	console.log('After transfer to issuing: trustorAccount history', JSON.stringify(await getHistory(trustorAccount.publicKey()), null, 2));


};

demoFlow = async function(){
	await simpleFlow();
	// console.log("\n\n\*********************************************\n\n");
	// await multisigFlow();
}

demoFlow();
