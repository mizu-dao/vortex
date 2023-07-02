// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;


// this is a prototype of a proprietary Nouns DAO pool for voting
// should work by itself, but if we want to make a public good version,
// we will need to integrate it into shared pools paradigm

contract ClaimPool {

    struct QueueEntry {
        address guy;
        uint32 fee;
    }

    struct ClaimBatch {

    }


    // --- blessers balances ---

    mapping(address => uint256) public balances;

    function withdraw(uint256 amount) external Update {
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function withdraw_all() external Update {
        uint256 _to_withdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(_to_withdraw);
    }

    // --- blessers priority queue ---
    
    uint256 constant QUEUE_BOND = 1 ether;
    uint256 constant QUEUE_FEE_STEP = 2000;
    uint32 constant QUEUE_LENGTH= 100;

    // that means that the first blesser in queue can set fee up to 200k gas per claim, and then it falls gradually

    mapping(uint32 => QueueEntry) queue;

    uint32 HeadPointer = 0;
    uint32 TailPointer = 0;

    function queueLength() public view returns ( uint32 ) {
        return (TailPointer + QUEUE_LENGTH - HeadPointer) % QUEUE_LENGTH;
    }

    function queuePop() private Update returns ( QueueEntry memory ) {
        uint32 _HeadPointer = HeadPointer;
        require(_HeadPointer != TailPointer, "queue is empty"); // check that queue is non-empty
        HeadPointer = (_HeadPointer+1)%QUEUE_LENGTH;
        return queue[_HeadPointer];
    }

    function queuePush(QueueEntry memory entry) private Update {
        uint32 _TailPointer = TailPointer;
        require((_TailPointer+1+QUEUE_LENGTH-HeadPointer)%QUEUE_LENGTH != 0, "queue is full");
        TailPointer = (_TailPointer+1)%QUEUE_LENGTH;
        queue[_TailPointer]=entry;
    }

    function enter(uint32 fee) external payable {
        require(msg.value == QUEUE_BOND);
        require(fee <= (QUEUE_LENGTH-queueLength())*QUEUE_FEE_STEP);
        QueueEntry memory entry = QueueEntry(msg.sender, fee);
        queuePush(entry);
    }

    // --- gas oracle ---

    uint32 constant ORACLE_UPDATE_COOLDOWN = 25; // amount of blocks that need to pass between successful updates
    uint32 constant  ORACLE_UPDATE_INVERSE_WEIGHT = 8;

    uint256 lastUpdateBlockNumber;
    uint256 public avgBaseFee;

    function update() private{
        if ((block.number - lastUpdateBlockNumber) < ORACLE_UPDATE_COOLDOWN) { return; }
        lastUpdateBlockNumber = block.number;
        avgBaseFee = (block.basefee + (ORACLE_UPDATE_INVERSE_WEIGHT-1)*avgBaseFee)/ORACLE_UPDATE_INVERSE_WEIGHT;
    }

    modifier Update() {
        update();
        _;
    }

    // ---


}