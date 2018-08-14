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

## Part 3: Write, Compile and Migrate the Smart Contract
### 3.1. Create Project Directory
```
$ mkdir lease
$ cd lease
```

### 3.2. Create Scaffolding
```
$ truffle unbox-petshop
```

### 3.3. Create a new Contract File
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

### 3.4. Create New Migrations File
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

### 3.5. Let's compile our Application
```
$ truffle compile
```

You should see output similar to the following:
```
Compiling ./contracts/Migrations.sol...
Compiling ./contracts/LeaseProperty.sol...
Writing artifacts to ./build/contracts
```

### 3.6. Before we can migrate our contract to the blockchain, we need to have a blockchain running. For this tutorial, we're going to use Ganache, a personal blockchain for Ethereum development you can use to deploy contracts, develop applications, and run tests

### 3.7. We can now migrate the contract to our local blockchain
```
$ truffle migrate --network development
```

You should see output similar to the following:
```
Using network 'development'.

Running migration: 1_initial_migration.js
  Deploying Migrations...
  ... 0xcc1a5aea7c0a8257ba3ae366b83af2d257d73a5772e84393b0576065bf24aedf
  Migrations: 0x8cdaf0cd259887258bc13a92c0a6da92698644c0
Saving successful migration to network...
  ... 0xd7bc86d31bee32fa3988f1c1eabce403a1b5d570340a3a9cdba53a472ee8c956
Saving artifacts...
Running migration: 2_deploy_contracts.js
  Deploying Adoption...
  ... 0x43b6a6888c90c38568d4f9ea494b9e2a22f55e506a8197938fb1bb6e5eaa5d34
  Adoption: 0x345ca3e014aaf5dca488057592ee47305d9b3e10
Saving successful migration to network...
  ... 0xf36163615f41ef7ed8f4a8f192149a0bf633fe1a2398ce001bf44c43dc7bdda0
Saving artifacts...
```

### 3.8. In Ganache, note that the state of the blockchain has changed. The blockchain now shows that the current block, previously 0, is now 4. In addition, while the first account originally had 100 ether, it is now lower, due to the transaction costs of migration

## Part 4: Testing the smart contract
### 4.1. Create New Tests File
```
$ vi test/TestLeaseProperty.sol
```

Replace code with this
```javascript
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
### 4.2. Run the tests
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

     TestAdoption
       ✓ testUserCanLeaseProperty (91ms)
       ✓ testGetLesseeAddressByPropertyId (70ms)
       ✓ testGetLesseeAddressByPropertyIdInArray (89ms)


     3 passing (670ms)
```

## Part 5: Let's create a user interface to interact with the smart contract
### 5.1. Modify the app.js file, 
```
$ vi /src/js/app.js
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

### 5.2. Modify the index.html file, 
```
$ vi /src/index.html
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
            <img alt="140x140" data-src="holder.js/140x140" class="img-rounded img-center" style="width: 100%;" src="https://animalso.com/wp-content/uploads/2017/01/Golden-Retriever_6.jpg" data-holder-rendered="true">
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

## Part 6: Interact with the dapp in a browser
### 6.1. Install and configure MetaMask
### 6.2. Installing and configuring lite-server

## Part 7: Let's run our dapp
### 7.1. Start the local web server:
```
$ npm run dev
```
The dev server will launch and automatically open a new browser tab containing your dapp.

### 7.2. To use the dapp, click the Lease button on the property of your choice.

### 7.3. You'll be automatically prompted to approve the transaction by MetaMask. Click Submit to approve the transaction.

### 7.4. You'll see the button next to the adopted pet change to say "Success" and become disabled, just as we specified, because the property has now been leased.

## Part 8: We're now ready to deploy to AWS
### 8.1. AWS Blockchain Template Prerequisites
Perform the following:
- Create an Elastic IP Address
- Create a VPC and Subnets
- Create Security Groups
- Create an IAM Role for Amazon ECS and EC2 Instance Profile
- Create a Bastion Host

Details can be found here:
https://docs.aws.amazon.com/blockchain-templates/latest/developerguide/blockchain-template-getting-started-prerequisites.html

### 8.2. Run AWS Blockchain Cloudformation Template for Ethereum
Download and run the CF Tempate from here:

https://aws-blockchain-templates-us-east-1.s3.us-east-1.amazonaws.com/ethereum/templates/latest/ethereum-network.template.yaml

### 8.3. Modify your truffle.js file
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

### 8.4. Compile & Deploy Lease Smart Contract to AWS
```
$ truffle migrate ––network awsNetwork
```

## We're done!
