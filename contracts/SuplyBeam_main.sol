// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

struct object {
    string name;
    string state;
}

struct update {
    object object;
    address by;
    uint256 timestamp;
    string oldstate;
    string newstate;
    string notes;
}

contract SupplyBeam_main {
    string public name;
    address public owner;
    mapping(string => address) public lock;
    mapping(string => object) public objects;
    
    //Events to listen for from the web app side
    event Update (address indexed by, string indexed  newstate, object indexed newobject, update update);
    event Create (address indexed by, string indexed  newstate, object indexed newobject, update update);
    event Destroy (address indexed by, object indexed newobject, update update);
    
    constructor(string memory title, address owner_address) {
        name = title;
        owner = owner_address;
    }

    function create(address by, object calldata obj) public {
        objects[obj.name] = obj;
        update memory u = update(obj, by, block.timestamp, "N/A", obj.state, "");
        emit Create(by, obj.state, obj, u);
    }
}