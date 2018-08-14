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