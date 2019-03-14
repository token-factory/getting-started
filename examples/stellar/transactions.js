var StellarSdk = require('stellar-sdk')
var server = new StellarSdk.Server('https://horizon-testnet.stellar.org');
var accountId = 'GDTNSTVNYWGYSYNU2MFNHI7XCGJRDCM23SHP2UHPKQENR6Z7ZUHJV6MP';

server.transactions()
    .forAccount(accountId)
    .call()
    .then(function (page) {
        console.log('Page 1: ');
        console.log(JSON.stringify(page.records, null, 5) ) ;
        return page.next();
    })
    .then(function (page) {
        console.log('Page 2: ');
        console.log(page.records);
    })
    .catch(function (err) {
        console.log(err);
    });