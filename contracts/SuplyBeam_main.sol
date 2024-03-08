// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;


// This is the default state structure. You can add any other field you'd like,
// it will be automatically added to all objects and state changes: magic!
struct state {
    string name;
    string notes;
    address applied_by;
}

// This is the default object structure. You can add any other field you'd like,
// it will be automatically applied to all objects: magic!
struct object {
    string name;
    state state;
}

struct update {
    object object;
    address by;
    uint256 timestamp;
    state oldstate;
    state newstate;
    string notes;
}

contract SupplyBeam_main {
    string public name;
    address public owner;
    mapping(string => address) internal lock;
    mapping(string => object) internal objects;

    
    //Events to listen for from the web app side
    event Update (address indexed by, object indexed newobject, update update);
    event Create (address indexed by, object indexed newobject, update update);

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }
    modifier onlyLocker(string calldata obj_name) {
        require(msg.sender == lock[obj_name], "You are not the owner.");
        _;
    }
    modifier objExists(string calldata obj_name) {
        require(objectExists(obj_name));
        _;
    }
    modifier objLocked(string calldata obj_name) {
        require(isObjectLocked(obj_name), "Object not locked");
        _;
    }
    modifier objNotLocked(string calldata obj_name) {
        require(!isObjectLocked(obj_name), "Object locked");
        _;
    }
    
    constructor(string memory title, address owner_address) {
        name = title;
        owner = owner_address;
    }
    function lockObject(string calldata obj_name) public objNotLocked(obj_name) {
        lock[obj_name] = msg.sender;
    }

    function forceUnlockObject(string calldata obj_name) public onlyOwner objLocked(obj_name) {
        lock[obj_name] = address(0);
    }

    function unlockObject(string calldata obj_name) public objLocked(obj_name) onlyLocker(obj_name) {
        lock[obj_name] = address(0);
    }

    function isObjectLocked(string calldata obj_name) view  public returns(bool){
        return (lock[obj_name] != address(0));
    }

    function objectExists(string calldata obj_name) internal view returns (bool) {
    // Use keccak256 hash to compare strings
    return keccak256(abi.encodePacked(objects[obj_name].name)) == keccak256(abi.encodePacked(obj_name));
    }
    function getObject(string calldata obj_name) public view objExists(obj_name) returns (object memory) {
        return objects[obj_name];
    }

    function _create(string calldata obj_name, state memory obj_state) public {
        address by = msg.sender;
        obj_state.applied_by = by;
        object memory obj = object(obj_name, obj_state);
        objects[obj.name] = obj;
        update memory u = update(obj, by, block.timestamp, obj.state, obj.state, obj.state.notes);
        emit Create(by, obj, u);
    }

    function _update(string calldata obj_name, state memory obj_state) public objExists(obj_name) {
        address by = msg.sender;
        obj_state.applied_by = by;
        object memory obj = object(obj_name, obj_state);
        update memory u = update(objects[obj.name], by, block.timestamp, objects[obj.name].state, obj.state, obj.state.notes);
        objects[obj.name] = obj;
        emit Update(by, obj, u);

    }
}