var LeaseProperty = artifacts.require("./LeaseProperty.sol");

module.exports = function(deployer) {
  deployer.deploy(LeaseProperty);
};
