var StellarSdk = require('stellar-sdk')
var server = new StellarSdk.Server('https://horizon-testnet.stellar.org');
StellarSdk.Network.useTestNetwork();
const rp = require('request-promise');


createAccount = async function(){
	let keyPair = StellarSdk.Keypair.random();

        await rp.get({
            //get initial token from testnet firendbot
            uri: 'https://horizon-testnet.stellar.org/friendbot',
            qs: { addr: keyPair.publicKey() },
            json: true
        });
        return keyPair;
}


createAsset = async function(account, assetCode){
	console.log('assetCode', [assetCode, account.publicKey()]);
	const asset = await new StellarSdk.Asset(assetCode, account.publicKey());
	return asset;
}

changeAssetTrustLevel = async function (publicKey, secret, asset, limit){
	const account = await server.loadAccount(publicKey);
    const trustTransaction = await new StellarSdk.TransactionBuilder(account)
        .addOperation(
            StellarSdk.Operation.changeTrust({
                asset: asset,
                limit: limit
            })
        ).build();
    const keypair = StellarSdk.Keypair.fromSecret(secret);
    await trustTransaction.sign(keypair);
    await server.submitTransaction(trustTransaction);
    return trustTransaction;
}
getOffers = async function getOffers(publicKey) {
    const offers = await server.offers('accounts', publicKey).call();
    return offers.records;
}

makePayment = async function (publicKey, receiverPublicKey, asset, amount){
	const account = await server.loadAccount(publicKey);
    const transaction = await new StellarSdk.TransactionBuilder(account)
        .addOperation(
            StellarSdk.Operation.payment({
                destination: receiverPublicKey,
                asset: asset,
                amount: amount
            })
        ).build();

  return transaction;
}

signTransaction = async function (transaction, secret){
	const keypair = await StellarSdk.Keypair.fromSecret(secret);
	await transaction.sign(keypair);
	return transaction;
}


demoFlow = async function(){
    const issuingAccount = await createAccount();
    console.log('issuingAccount', issuingAccount);
        
    console.log('creating new trustor account');
    const asset1 = await createAsset(issuingAccount, 'AstroDollars');
    const asset2 = await createAsset(issuingAccount, 'Gunther');

    console.log('make payment asset1');
    const trustorAccount = await createAccount();
    const changedtrustorTrustLevel2 = await changeAssetTrustLevel(trustorAccount.publicKey(), trustorAccount.secret(), asset1, '1000000');
    await changeAssetTrustLevel(trustorAccount.publicKey(), trustorAccount.secret(), asset2, '1000000');
    
    const payment1 = await makePayment(issuingAccount.publicKey(), trustorAccount.publicKey(), asset1, '1000000' )
    const pay1Trans = await signTransaction (payment1, issuingAccount.secret());
    await server.submitTransaction(pay1Trans);

    console.log('make payment asset2');
    const distributorAccount = await createAccount();
    await changeAssetTrustLevel(distributorAccount.publicKey(), distributorAccount.secret(), asset2, '1000000');
    await changeAssetTrustLevel(distributorAccount.publicKey(), distributorAccount.secret(), asset1, '1000000');
    
    
    const payment2 = await makePayment(issuingAccount.publicKey(), distributorAccount.publicKey(), asset2, '1000000' )
    const pay2Trans = await signTransaction (payment2, issuingAccount.secret());
   await server.submitTransaction(pay2Trans);


    let offer = StellarSdk.Operation.manageOffer({
        selling: asset1,
        buying: asset2,
        amount: '60',
        price: 4
    })

    const offeringAccount = await server.loadAccount(trustorAccount.publicKey());
    let stellarTransaction = new StellarSdk.TransactionBuilder(offeringAccount).addOperation(offer).build();
    const signedTransaction = await signTransaction (stellarTransaction, trustorAccount.secret());
    const transactionResult = await server.submitTransaction(signedTransaction);
    
    const offers = await getOffers(trustorAccount.publicKey() );
    console.log('offers', offers);


    offer = StellarSdk.Operation.manageOffer({
        selling: asset2,
        buying: asset1,
        amount: '240',
        price: .25
    })

    const offeringAccount2 = await server.loadAccount(distributorAccount.publicKey());
    stellarTransaction = new StellarSdk.TransactionBuilder(offeringAccount2).addOperation(offer).build();
    const signedTransaction2 = await signTransaction (stellarTransaction, distributorAccount.secret());
    const transactionResult2 = await server.submitTransaction(signedTransaction2);

    const offersDist = await getOffers(distributorAccount.publicKey() );
    console.log('offers', offersDist);

    const orderbook = await server.orderbook(asset1, asset2).call()
    console.log('orderbook', orderbook);

}

demoFlow();
