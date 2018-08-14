const HDWalletProvider = require("truffle-hdwallet-provider-privkey");
var mnemonic = "outdoor father modify...";
const privateKeys = ["afd21..."]; // private keys

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // Match any network id
    },
    awsNetwork: {
      provider: () => {
        return new HDWalletProvider(privateKeys, "http://internal-MyFir-LoadB-1ST6DYDCSRRUF-907719992.us-east-1.elb.amazonaws.com")
      },
      port: 8545,
      network_id: 1234
    }
  }
};