# Deploying an Ethereum Decentralized Application on AWS using AWS Blockchain Templates
This is a simple 30-minute hands-on tutorial on how to write a details of a lease agreement smart contract on a Private Ethereum blockchain on Amazon Web Services.

Follow the steps below to download, install and run this project.

## Part 1: Overview of Blockchain, Ethereum, Smart Contracts and dApp Demo
This document will cover the following
- Setting up the development environment
- Creating a Truffle project using a Truffle Box
- Writing the smart contract
- Compiling and migrating the smart contract
- Testing the smart contract
- Creating a user interface to interact with the smart contract
- Interacting with the dapp in a browser

## Part 2: Setting up the development environment
Install these prerequisites to follow along.
- NPM: https://nodejs.org
- Truffle: https://github.com/trufflesuite/truffle
- Ganache: http://truffleframework.com/ganache/
- IDE: Visual Studio Code
- (Optional) Syntax Highlighting for your IDE: Solidity for VS Code
- Metamask: https://metamask.io/

## Part 3: Create Project and Scaffolding
### 3.1. Create Project Directory
```
$ mkdir lease-property
$ cd lease-property
```

### 3.2. Create Scaffolding
```
$ truffle unbox pet-shop
```

You should see output similar to the following:
```
Downloading...
Unpacking...
Setting up...
Unbox successful. Sweet!

Commands:

  Compile:        truffle compile
  Migrate:        truffle migrate
  Test contracts: truffle test
  Run dev server: npm run dev
```

### 3.3.(Optional) Remove files not needed
Remove images
```
$ rm box-img-lg.png
$ rm box-img-sm.png
$ rm src/images/scottish-terrier.jpeg
$ rm src/images/golden-retriever.jpeg
$ rm src/images/french-bulldog.jpeg
$ rm src/images/boxer.jpeg
$ rm src/pets.json
```

Remove index.thml and app.js because we will replace these later
```
$ rm src/index.html
$ rm src/js/app.js
```

## Part 4: Write, Compile and Migrate the Smart Contract
### 4.1. Create a new Contract File
```
$ vi contracts/LeaseProperty.sol
```

Replace code with this:
```solidity
pragma solidity ^0.4.24;

contract LeaseProperty {

    address[16] public lessees;

    // Lease a property
    function lease(uint propertyId) public returns (uint) {
        require(propertyId >= 0 && propertyId <= 15);
        lessees[propertyId] = msg.sender;
        return propertyId;
    }

    // Retrieving the lessees
    function getLessees() public view returns (address[16]) {
        return lessees;
    }
}
```

### 4.2. Let's compile our Application
```
$ truffle compile
```

You should see output similar to the following:
```
Compiling ./contracts/LeaseProperty.sol...
Compiling ./contracts/Migrations.sol...
Writing artifacts to ./build/contracts
```

### 4.3. Create New Migrations File
```
$ vi migrations/2_deploy_contracts.js
```

Replace code with this
```javascript
var LeaseProperty = artifacts.require("./LeaseProperty.sol");

module.exports = function(deployer) {
  deployer.deploy(LeaseProperty);
};
```

### 4.4. Before we can migrate our contract to the blockchain, we need to have a blockchain running. For this tutorial, we're going to use Ganache, a personal blockchain for Ethereum development you can use to deploy contracts, develop applications, and run tests

### 4.5. We can now migrate the contract to our local blockchain
```
$ truffle migrate --network development
```

You should see output similar to the following:
```
Using network 'development'.

Running migration: 1_initial_migration.js
  Deploying Migrations...
  ... 0xb191d286c9a2fcab68b1218cafc7c40477b3c5c4e5987582b7b53004ae776c5a
  Migrations: 0x534774eee39ec144dd188399cfb0a49b63c2c005
Saving successful migration to network...
  ... 0x8c282e8b29cb0692ec8d37a36d43986dfbdd684c3af92db6b1f7b6f531e36317
Saving artifacts...
Running migration: 2_deploy_contracts.js
  Deploying LeaseProperty...
  ... 0x0804a39647b115bf060cd269feff909564e8aac975ba3860c2165bcff73e8f0e
  LeaseProperty: 0xfa124fc5290ac561b69bcf8a23d4128e7ac22e5d
Saving successful migration to network...
  ... 0x0d35af9affae169a12bb8cddaca285dc5a0ab2599cc60b46ebea8c1e70e2b0fb
Saving artifacts...
```

### 4.6. In Ganache, note that the state of the blockchain has changed. The blockchain now shows that the current block, previously 0, is now 4. In addition, while the first account originally had 100 ether, it is now lower, due to the transaction costs of migration

## Part 5: Testing the smart contract
### 5.1. Create New Tests File
```
$ vi test/TestLeaseProperty.sol
```

Replace code with this
```solidity
pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/LeaseProperty.sol";

contract TestLeaseProperty {
    LeaseProperty leaseProperty = LeaseProperty(DeployedAddresses.LeaseProperty());

    // Testing the lease() function
    function testUserCanLeaseProperty() public {
        uint returnedId = leaseProperty.lease(8);
        uint expected = 8;
        Assert.equal(returnedId, expected, "Lease of property ID 8 should be recorded.");
    }

    // Testing retrieval of a single property's owner
    function testGetLesseeAddressByPropertyId() public {
        // Expected owner is this contract
        address expected = this;
        address lessee = leaseProperty.lessees(8);
        Assert.equal(lessee, expected, "Owner of property ID 8 should be recorded.");
    }

    // Testing retrieval of all lessors
    function testGetLesseeAddressByPropertyIdInArray() public {
        // Expected owner is this contract
        address expected = this;
        // Store lessees in memory rather than contract's storage
        address[16] memory lessees = leaseProperty.getLessees();
        Assert.equal(lessees[8], expected, "Owner of property ID 8 should be recorded.");
    }
}
```
### 5.2. Run the tests
```
$ truffle test
```

If all the tests pass, you'll see console output similar to this:
```
Using network 'development'.

Compiling ./contracts/LeaseProperty.sol...
Compiling ./test/TestLeaseProperty.sol...
Compiling truffle/Assert.sol...
Compiling truffle/DeployedAddresses.sol...


  TestLeaseProperty
    ✓ testUserCanLeaseProperty (131ms)
    ✓ testGetLesseeAddressByPropertyId (131ms)
    ✓ testGetLesseeAddressByPropertyIdInArray (147ms)


  3 passing (1s)
```

## Part 6: Let's create a user interface to interact with the smart contract
### 6.1. Modify the app.js file, 
```
$ vi src/js/app.js
```

Replace contents with code below to
- Instantiate web3, 
- Instantiate the contract, 
- Get The Leased Properties and Update The UI,
- Handle the lease() function

```javascript
App = {
  web3Provider: null,
  contracts: {},

  init: function() {
    // Load properties.
    $.getJSON('../properties.json', function(data) {
      var propertiesRow = $('#propertiesRow');
      var propertyTemplate = $('#propertyTemplate');

      for (i = 0; i < data.length; i ++) {
        propertyTemplate.find('.panel-amount').text(data[i].amount);
        propertyTemplate.find('img').attr('src', data[i].picture);
        propertyTemplate.find('.property-address').text(data[i].address);
        propertyTemplate.find('.property-bedrooms').text(data[i].bedrooms);
        propertyTemplate.find('.property-location').text(data[i].location);
        propertyTemplate.find('.btn-lease').attr('data-id', data[i].id);

        propertiesRow.append(propertyTemplate.html());
      }
    });

    return App.initWeb3();
  },

  initWeb3: function() {
    // Is there an injected web3 instance?
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider;
    } else {
      // If no injected web3 instance is detected, fall back to Ganache
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    }
    web3 = new Web3(App.web3Provider);
    return App.initContract();
  },

  initContract: function() {
    $.getJSON('LeaseProperty.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract
      var LeasePropertyArtifact = data;
      App.contracts.LeaseProperty = TruffleContract(LeasePropertyArtifact);

      // Set the provider for our contract
      App.contracts.LeaseProperty.setProvider(App.web3Provider);

      // Use our contract to retrieve and mark the leased properties
      return App.markLeased();
    });

    return App.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '.btn-lease', App.handleLease);
  },

  markLeased: function(lessees, account) {
    var leasePropertyInstance;

    App.contracts.LeaseProperty.deployed().then(function(instance) {
      leasePropertyInstance = instance;

      return leasePropertyInstance.getLessees.call();
    }).then(function(lessees) {
      for (i = 0; i < lessees.length; i++) {
        if (lessees[i] !== '0x0000000000000000000000000000000000000000') {
          $('.panel-property').eq(i).find('button').text('Success').attr('disabled', true);
        }
      }
    }).catch(function(err) {
      console.log(err.message);
    });
  },

  handleLease: function(event) {
    event.preventDefault();

    var propertyId = parseInt($(event.target).data('id'));

    var leasePropertyInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.LeaseProperty.deployed().then(function(instance) {
        leasePropertyInstance = instance;

        // Execute lease as a transaction by sending account
        return leasePropertyInstance.lease(propertyId, {from: account});
      }).then(function(result) {
        return App.markLeased();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
```

### 6.2. Modify the index.html file
```
$ vi src/index.html
```

Replace code this this:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <title>Properties For Lease</title>

    <!-- Bootstrap -->
    <link href="css/bootstrap.min.css" rel="stylesheet">

    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>
  <body>
    <div class="container">
      <div class="row">
        <div class="col-xs-12 col-sm-8 col-sm-push-2">
          <h1 class="text-center">Properties For Lease</h1>
          <hr/>
          <br/>
        </div>
      </div>

      <div id="propertiesRow" class="row">
        <!-- PROPERTIES LOAD HERE -->
      </div>
    </div>

    <div id="propertyTemplate" style="display: none;">
      <div class="col-sm-6 col-md-4 col-lg-3">
        <div class="panel panel-default panel-property">
          <div class="panel-heading">
            <h3 class="panel-amount">$1000 per week</h3>
          </div>
          <div class="panel-body">
            <img alt="140x140" data-src="holder.js/140x140" class="img-rounded img-center" style="width: 100%;" src="https://s3.amazonaws.com/jrdalino-public-images/house.png" data-holder-rendered="true">
            <br/><br/>
            <strong>Bedrooms</strong>: <span class="property-bedrooms">3</span><br/>            
            <strong>Address</strong>: <span class="property-address">123 Main St</span><br/>
            <strong>Location</strong>: <span class="property-location">Warren, MI</span><br/><br/>
            <button class="btn btn-default btn-lease" type="button" data-id="0">Lease</button>
          </div>
        </div>
      </div>
    </div>

    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="js/bootstrap.min.js"></script>
    <script src="js/web3.min.js"></script>
    <script src="js/truffle-contract.js"></script>
    <script src="js/app.js"></script>
  </body>
</html>
```

### 6.3.Copy images of houses in this directory ~/src/images/

### 6.5 Create properties.json file
```
$ vi src/properties.json
```

Replace code this this:

```json
[
  {
    "id": 0,
    "amount": "$750 per week",
    "picture": "images/house-00.jpeg",
    "bedrooms": 3,
    "address": "1 Park Blvd",
    "location": "Lisco, Alabama"
  },
  {
    "id": 1,
    "amount": "$650 per week",
    "picture": "images/house-01.jpeg",
    "bedrooms": 3,
    "address": "2 W Ash St ",
    "location": "Tooleville, West Virginia"
  },
  {
    "id": 2,
    "amount": "$1250 per week",
    "picture": "images/house-02.jpeg",
    "bedrooms": 2,
    "address": "3 Broadway Ave",
    "location": "Freeburn, Idaho"
  },
  {
    "id": 3,
    "amount": "$800 per week",
    "picture": "images/house-03.jpeg",
    "bedrooms": 2,
    "address": "4 Market St",
    "location": "Camas, Pennsylvania"
  },
  {
    "id": 4,
    "amount": "$900 per week",
    "picture": "images/house-04.jpeg",
    "bedrooms": 2,
    "address": "5 Cedar Rd",
    "location": "Gerber, South Dakota"
  },
  {
    "id": 5,
    "amount": "$1100 per week",
    "picture": "images/house-05.jpeg",
    "bedrooms": 3,
    "address": "6 Elm St",
    "location": "Innsbrook, Illinois"
  },
  {
    "id": 6,
    "amount": "$680 per week",
    "picture": "images/house-06.jpeg",
    "bedrooms": 3,
    "address": "7 Island Ave",
    "location": "Soudan, Louisiana"
  },
  {
    "id": 7,
    "amount": "$700 per week",
    "picture": "images/house-07.jpeg",
    "bedrooms": 3,
    "address": "8 Imperial Ave",
    "location": "Jacksonwald, Palau"
  },
  {
    "id": 8,
    "amount": "$850 per week",
    "picture": "images/house-08.jpeg",
    "bedrooms": 2,
    "address": "9 National St",
    "location": "Honolulu, Hawaii"
  },
  {
    "id": 9,
    "amount": "$1120 per week",
    "picture": "images/house-09.jpeg",
    "bedrooms": 3,
    "address": "10 Commercial Rd",
    "location": "Matheny, Utah"
  },
  {
    "id": 10,
    "amount": "$900 per week",
    "picture": "images/house-10.jpeg",
    "bedrooms": 2,
    "address": "11 Harrison Rd",
    "location": "Tyhee, Indiana"
  },
  {
    "id": 11,
    "amount": "$770 per week",
    "picture": "images/house-11.jpeg",
    "bedrooms": 3,
    "address": "12 Jullian St",
    "location": "Windsor, Montana"
  },
  {
    "id": 12,
    "amount": "$1300 per week",
    "picture": "images/house-12.jpeg",
    "bedrooms": 3,
    "address": "13 Irving Ave",
    "location": "Kingstowne, Nevada"
  },
  {
    "id": 13,
    "amount": "$450 per week",
    "picture": "images/house-13.jpeg",
    "bedrooms": 4,
    "address": "14 Valley Rd",
    "location": "Sultana, Massachusetts"
  },
  {
    "id": 14,
    "amount": "$1000 per week",
    "picture": "images/house-14.jpeg",
    "bedrooms": 2,
    "address": "15 Clay St",
    "location": "Broadlands, Oregon"
  },
  {
    "id": 15,
    "amount": "$900 per week",
    "picture": "images/house-15.jpeg",
    "bedrooms": 2,
    "address": "16 Franklin Ave",
    "location": "Dawn, Wisconsin"
  }
]
```

## Part 7: Interact with the dapp in a browser
### 7.1. Install and configure MetaMask
- Install MetaMask in your browser. https://chrome.google.com/webstore/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn?hl=en
- Once installed, you'll see the MetaMask fox icon next to your address bar.
- Click Accept to accept the Privacy Notice.
- Then you'll see the Terms of Use. Read them, scrolling to the bottom, and then click Accept there too.
- Now you'll see the initial MetaMask screen. Click Import Existing DEN.
- In the box marked Wallet Seed, enter the mnemonic that is displayed in Ganache.
- Now we need to connect MetaMask to the blockchain created by Ganache. Click the menu that shows "Main Network" and select Custom RPC.
- In the box titled "New RPC URL" enter http://127.0.0.1:7545 and click Save.
- Click the left-pointing arrow next to "Settings" to close out of the page and return to the Accounts page.

### 7.2. Installing and configuring lite-server

## Part 8: Let's run our dapp
- Start the local web server:
```
$ npm run dev
```
- The dev server will launch and automatically open a new browser tab containing your dapp.
- To use the dapp, click the Lease button on the property of your choice.
- You'll be automatically prompted to approve the transaction by MetaMask. Click Submit to approve the transaction.
- You'll see the button next to the leased property change to say "Success" and become disabled, just as we specified, because the property has now been leased.

## Part 9: We're now ready to deploy to AWS
### 9.1. AWS Blockchain Template Prerequisites
Perform the following:
- Create an Elastic IP Address
- Create a VPC and Subnets
- Create Security Groups
- Create an IAM Role for Amazon ECS and EC2 Instance Profile
- Create a Bastion Host

Details can be found here:
https://docs.aws.amazon.com/blockchain-templates/latest/developerguide/blockchain-template-getting-started-prerequisites.html

### 9.2. Run AWS Blockchain Cloudformation Template for Ethereum
Download and run the CF Tempate from here:

https://aws-blockchain-templates-us-east-1.s3.us-east-1.amazonaws.com/ethereum/templates/latest/ethereum-network.template.yaml

### 9.3. Install Truffle HDWallet Provider Private Key
https://www.npmjs.com/package/truffle-hdwallet-provider-privkey
```
npm install truffle-hdwallet-provider-privkey
```

### 9.3. Modify your truffle.js file
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

### 9.4. Compile & Deploy Lease Smart Contract to AWS
```
$ truffle migrate --network awsNetwork
```

## And we're done!
