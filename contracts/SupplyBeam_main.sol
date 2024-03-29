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

struct transaction {
    uint timestamp;
    uint gas;
    address by;
    string func;
}

contract SupplyBeam_main {
    string public name;
    address public owner;
    mapping(string => address) internal lock;
    string[] internal object_keys;
    mapping(string => object) internal objects;
    mapping(address => bool) public authorized;
    uint internal  authorizednumber;
    transaction[] public transactions;

    //Events to listen for from the web app side
    event Update(address indexed by, object indexed newobject, update update);
    event Create(address indexed by, object indexed newobject, update update);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }
    modifier onlyAuthorized() {
        require(
            authorized[msg.sender],
            "You are not authorized to interact with this contract"
        );
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
    modifier notObjExists(string calldata obj_name) {
        require(!objectExists(obj_name));
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
    modifier nLowerThanObjects(uint n) {
        require(n < object_keys.length, "index out of range");
        _;
    }

    constructor(string memory title, address owner_address) {
        name = title;
        owner = owner_address;
        authorized[owner] = true;
        authorizednumber = 1;
    }

    function addTransaction(uint maxgas, string memory func) internal {
        transaction memory t = transaction(
            block.timestamp,
            (maxgas - gasleft()) * tx.gasprice,
            msg.sender,
            func
        );
        transactions.push(t);
    }

    function getTransaction(uint n) public view onlyAuthorized returns (transaction memory) {
        return transactions[n];
    }

    function getTransactions(uint from, uint to) public view onlyAuthorized returns (transaction[] memory) {
        uint l = to-from;
        transaction[] memory result = new transaction[](l);
        for (uint i = to; i < ((from < transactions.length) ? from : transactions.length); i++) {
            result[i] = transactions[i];
        }
        return result;
    }

    function getNumberOfTransactions() public view onlyAuthorized returns (uint) {
        return transactions.length;
    }


    function lockObject(
        string calldata obj_name
    ) public objNotLocked(obj_name) onlyAuthorized {
        uint maxgas = gasleft();
        lock[obj_name] = msg.sender;
        addTransaction(maxgas, "lockObject");
    }

    function forceUnlockObject(
        string calldata obj_name
    ) public onlyOwner objLocked(obj_name) {
        uint maxgas = gasleft();
        lock[obj_name] = address(0);
        addTransaction(maxgas, "forceUnlockObject");
    }

    function unlockObject(
        string calldata obj_name
    ) public objLocked(obj_name) onlyLocker(obj_name) {
        uint maxgas = gasleft();
        lock[obj_name] = address(0);
        addTransaction(maxgas, "unlockObject");
    }

    function isObjectLocked(
        string calldata obj_name
    ) public view returns (bool) {
        return (lock[obj_name] != address(0));
    }

    function objectExists(
        string calldata obj_name
    ) internal view returns (bool) {
        // Use keccak256 hash to compare strings
        return
            keccak256(abi.encodePacked(objects[obj_name].name)) ==
            keccak256(abi.encodePacked(obj_name));
    }

    function getObject(
        string calldata obj_name
    ) public view objExists(obj_name) returns (object memory) {
        return objects[obj_name];
    }

    function getObjectsNumber() public view returns (uint) {
        return object_keys.length;
    }

    function getAllObjects() public view returns (object[] memory) {
        object[] memory result = new object[](object_keys.length);
        for (uint i = 0; i < object_keys.length; i++) {
            result[i] = objects[object_keys[i]];
        }
        return result;
    }

    function authorize(address addr) public onlyOwner {
        uint maxgas = gasleft();
        authorized[addr] = true;
        addTransaction(maxgas, "authorize");
    }

    function getNumberOfAuthorized() public onlyAuthorized view  returns (uint) {
        return authorizednumber;
    }

    function getObjects(
        uint from,
        uint to
    ) public view nLowerThanObjects(to) returns (object[] memory) {
        uint l = uint(to - from + 1);
        object[] memory result = new object[](l);
        for (uint i = 0; i < l; i++) {
            // Adjust indexing for 'result' to start from 0 and 'objects' to match 'object_keys'
            result[i] = objects[object_keys[from + i]]; // Adjusting the indexing here
        }
        return result;
    }

    function _create(
        string calldata obj_name,
        state memory obj_state
    ) public notObjExists(obj_name) onlyAuthorized {
        uint maxgas = gasleft();
        address by = msg.sender;
        obj_state.applied_by = by;
        object memory obj = object(obj_name, obj_state);
        objects[obj.name] = obj;
        object_keys.push(obj.name);
        update memory u = update(
            obj,
            by,
            block.timestamp,
            obj.state,
            obj.state,
            obj.state.notes
        );
        emit Create(by, obj, u);
        addTransaction(maxgas, "_create");
    }

    function _update(
        string calldata obj_name,
        state memory obj_state
    ) public objExists(obj_name) onlyAuthorized {
        uint maxgas = gasleft();
        address by = msg.sender;
        obj_state.applied_by = by;
        object memory obj = object(obj_name, obj_state);
        update memory u = update(
            objects[obj.name],
            by,
            block.timestamp,
            objects[obj.name].state,
            obj.state,
            obj.state.notes
        );
        objects[obj.name] = obj;
        emit Update(by, obj, u);
        addTransaction(maxgas, "_update");
    }
}
