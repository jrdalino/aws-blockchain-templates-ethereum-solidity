# Deploying an Ethereum Decentralized Application on AWS using AWS Blockchain Templates
This is a simple 30-minute hands-on tutorial on how to write a details of a lease agreement smart contract on a Private Ethereum blockchain on Amazon Web Services.

Follow the steps below to download, install and run this project.

## Part 1: Overview of Blockchains and Ethereum
Slides can be found here https://github.com/jrdalino/lease/raw/master/deploying-a-dapp-aws-blockchain-templates.pdf

## Part 2: Dependencies
Install these prerequisites to follow along.
- NPM: https://nodejs.org
- Truffle: https://github.com/trufflesuite/truffle
- Ganache: http://truffleframework.com/ganache/
- IDE: Visual Studio Code
- (Optional) Syntax Highlighting for your IDE: Solidity for VS Code
- (Optional) Metamask: https://metamask.io/

## Part 3.a: Clone and Run the Project
### 1. Clone the project
```
git clone https://github.com/jrdalino/lease
```

### 2. Install dependencies
```
$ cd lease
$ npm install
```

### 3. Start Ganache
Open the Ganache GUI client that you downloaded and installed. This will start your local blockchain instance.

### 4. Compile & Deploy Lease Smart Contract Locally
```
$ truffle migrate –reset –-network development
```

You must migrate the lease smart contract each time your restart ganache.

## (Optional) Part 3.b: Setup the project from scratch
### 1. Create Project Directory
```
$ mkdir lease
$ cd lease
```

### 2. Create Scaffolding
```
$ truffle unbox-petshop
```

### 3. Create a new Contract File

```
$ vi contracts/Lease.sol
```

Replace code with this:

```solidity
pragma solidity ^0.4.24;

contract Lease {
    // Read/write lessor and lessee
    string public lessor;
    string public lessee;
    string public startDate;	// change data type
    string public endDate;	// change data type
    string public amountUSD;	// change data type

    // Constructor
    function Lease () public {
        lessor = "Jose Dalino";
        lessee = "Juan Dela Cruz";
        startDate = "January 1, 2019";
        endDate = "December 31, 2019";
        amountPerMonthUSD = "3000";
    }
}
```

### 4. Create New Migrations File
```
$ vi migrations/2_deploy_contracts.js
```

Replace code with this

```javascript
var Lease = artifacts.require("./Lease.sol");

module.exports = function(deployer) {
  deployer.deploy(Lease);
};
```

### 5. Let's run our Migrations
```
$ truffle migrate –network development
```

## Part 4: Let's interact with the Smart Contract
Run this command:

```
$ truffle console
```

Once inside, let’s get an instance of our deployed smart contract and see if we can read the lease details from the contract. From the console, run this code

```
truffle(development)> Lease.deployed().then(function(instance) { app = instance })
```

Now we can read the values of the lessor, lessee, start and end date and amounts like this

```
app.lessor()
// => 'Jose Dalino'

app.lessee()
// => 'Juan Dela Cruz'

app.startDate()
// => 'January 1, 2019'

app.endDate()
// => 'December 31, 2019'

app.amountPerMonthUSD()
// => '3000'
```

Congratulations! You've just written your first smart contract, deployed to the blockchain, and retrieved some of its data.

## Part 5: We're now ready to deploy to AWS
### 1. AWS Blockchain Template Prerequisites
Perform the following:
- Create an Elastic IP Address
- Create a VPC and Subnets
- Create Security Groups
- Create an IAM Role for Amazon ECS and EC2 Instance Profile
- Create a Bastion Host

Details can be found here:
https://docs.aws.amazon.com/blockchain-templates/latest/developerguide/blockchain-template-getting-started-prerequisites.html

### 2. Run AWS Blockchain Cloudformation Template for Ethereum
Download and run the CF Tempate from here:

https://aws-blockchain-templates-us-east-1.s3.us-east-1.amazonaws.com/ethereum/templates/latest/ethereum-network.template.yaml

### 3. Modify your truffle.js file
```
$ vi truffle.js
```

Replace code with this

```javascript
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
```

### 4. Compile & Deploy Lease Smart Contract to AWS
```
$ truffle migrate ––network awsNetwork
```

## We're done!
