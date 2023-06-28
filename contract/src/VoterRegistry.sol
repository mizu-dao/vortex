// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface Nouns {
    function tokenByIndex(uint256) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function getCurrentVotes(address account) external view returns (uint96);
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}

address constant NOUNS_TOKEN_ADDRESS = address(0x5FC8d32690cc91D4c39d9d3abcBD16989F875707);



// if user decides to unregister and then register back, they will have to use a different nonce
// 32 last bits are used for nonce - i.e. x>>32 is address, and x%(1<<32) is nonce
// therefore, we keep extended addresses in 192-bit values

struct Checkpoint{
    uint32 fromBlock;
    uint192 voter;
}

struct RegistrationData{
    bool is_nullified; // will be set to True on unregister
    uint24 collateral_value;
    uint224 data;
}

contract VoterRegistry{
    
    uint256 GRACE_PERIOD; // amount of blocks that a user has to unregister

    uint24 public CURRENT_COLLATERAL_VALUE;
    address public owner;

    uint32 public numVoters;                                
    mapping(uint32 => mapping(uint32 => Checkpoint)) public votersById; 
    mapping(uint32 => uint32) public numIdCheckpoints;                
    // this is a voter registry by id, Merkle tree construction iterates over it
    // 0 value voters are possible,
    // but can be ejected after a short delay

    mapping(uint192 => mapping(uint32 => uint32)) public votersByAddress;
    mapping(uint192 => uint32) public numAddrUpdates;
    // this can be used to find user's place in the queue 
    // theoretically it could be skipped with a bit of gas savings, but it will make
    // automatic un-register simpler, so it seems like a good tradeoff from UX standpoint
    // +registration is typically done infrequently, so gas savings here are not that important

    mapping(uint192 => RegistrationData) public registrationData; //contains registration data of the user.


    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address nouns_gov_addr) {
        CURRENT_COLLATERAL_VALUE = uint24(2**12)/10; // 2**12 will correspond to 1 eth 
        GRACE_PERIOD = 7200; // which roughly corresponds to 1 day = 5*60*24 blocks at blocktime 5/minute
        owner = nouns_gov_addr;
    }

    function setOwner(address addr) public onlyOwner{
        owner = addr;
    }

    function setCollateralValue(uint24 value) public onlyOwner{
        CURRENT_COLLATERAL_VALUE = value;
    }

    function setGracePeriod(uint256 grace_period) public onlyOwner{
        GRACE_PERIOD = grace_period;
    }

    function isPopulated(uint192 addr) public view returns (bool){
        return (numAddrUpdates[addr]>0);
    }

    function findNonce(address addr) external view returns (uint192){
        uint192 res = uint192(uint160(addr))<<32;
        while (isPopulated(res)){
            res++;
        }
        return res;
    }

    function to_ether(uint24 value) public pure returns(uint256) {
        return (1 gwei)*(2**18)*value; // value 2**12 corresponds to 1 eth
    }

    function register(uint224 data, uint32 nonce) external payable {
        Nouns nouns = Nouns(NOUNS_TOKEN_ADDRESS);
        require(block.number < 2**32);
        require(nouns.getCurrentVotes(msg.sender) > 0); // can not register without having votes (either balance or delegated)
        uint192 addr_ext = uint192(uint160(msg.sender))<<32 + nonce;
        require(!isPopulated(addr_ext)); // can not register if already registered with the same nonce
        require(msg.value == to_ether(CURRENT_COLLATERAL_VALUE));

        // set registration data
        RegistrationData memory reg_data = RegistrationData(false, CURRENT_COLLATERAL_VALUE, data);
        registrationData[addr_ext] = reg_data;

        // set checkpoint
        Checkpoint memory checkpoint = Checkpoint(uint32(block.number), addr_ext);

        uint32 _numVoters = numVoters;
        votersById[_numVoters][numIdCheckpoints[_numVoters]] = checkpoint;
        numIdCheckpoints[_numVoters]++;
        numVoters=_numVoters+1;

        // set 1st voter update
        votersByAddress[addr_ext][0] = _numVoters;
        numAddrUpdates[addr_ext] = 1;
    }

    function _unregister_internal(uint192 addr_ext) internal {
        require(isPopulated(addr_ext));
        
        RegistrationData memory _registrationData = registrationData[addr_ext];
        require(!_registrationData.is_nullified);
        
        require(block.number < 2**32);

        uint32 _numAddrUpdates_eject = numAddrUpdates[addr_ext];
        uint32 id = votersByAddress[addr_ext][_numAddrUpdates_eject]; //compute id of the cell we need to eject

        uint32 _numVoters = numVoters;
        uint32 _numIdCheckpoints_last = numIdCheckpoints[_numVoters];
        uint32 _numIdCheckpoints_eject = numIdCheckpoints[id];
        uint192 last_addr = votersById[_numVoters][_numIdCheckpoints_last].voter;
    
        uint32 _numAddrUpdates_last = numAddrUpdates[last_addr];

        // update voters by id: eject and swap method
        
        // write an update in the cell we ejected
        votersById[id][_numIdCheckpoints_eject] = Checkpoint(uint32(block.number), last_addr);
        numIdCheckpoints[id] = _numIdCheckpoints_eject + 1;
        //and decrease amount of voters by 1
        numVoters = _numVoters-1;

        // update voters by address:
        // this only updates the last_addr

        votersByAddress[last_addr][_numAddrUpdates_last] = id; // push the pointer to the new position of user address in the voter registry
        numAddrUpdates[last_addr] = _numAddrUpdates_last + 1;

        // nullify registration data
        registrationData[addr_ext].is_nullified = true;
    
        // transfer collateral to message sender
        // this value is fixed at the moment of registration
        // for example - if owner changes CURRENT_COLLATERAL_VALUE, it shall not break any invariants
        // amount of money that is transferred during registration is exactly captured on unregister
        payable(msg.sender).transfer(to_ether(_registrationData.collateral_value));
    
    }

    function unregister_self(uint32 nonce) external { // voluntary unregistration
        uint192 addr_ext = uint192(uint160(msg.sender))<<32 + nonce;
        _unregister_internal(addr_ext);
    }

    function unregister_other(address guy, uint32 nonce) external { // involuntary unregistration
        uint192 addr_ext = uint192(uint160(guy))<<32 + nonce;
        require(Nouns(NOUNS_TOKEN_ADDRESS).getPriorVotes(guy, block.number-GRACE_PERIOD) == 0); // a day ago a guy had 0 votes in total
        _unregister_internal(addr_ext);
    }
}