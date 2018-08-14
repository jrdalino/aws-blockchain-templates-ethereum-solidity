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