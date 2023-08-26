// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

contract Router {
    /*//////////////////////////////////////////////////////////////
                            Helper Structs
    //////////////////////////////////////////////////////////////*/

    struct QueueEntry {
        address guy;
        uint32 fee;
    }

    struct Queue {
        mapping(uint256 => QueueEntry) entries;
        uint128 head;
        uint128 tail;
    }

    struct Pool {
        mapping(address => bool) claimKinds;
        Queue queue;
    }

    /*//////////////////////////////////////////////////////////////
                  Helper fns, modifiers and constants
    //////////////////////////////////////////////////////////////*/

    uint32 constant ORACLE_UPDATE_COOLDOWN = 25;
    uint32 constant ORACLE_UPDATE_INVERSE_WEIGHT = 8;

    uint256 lastUpdateBlockNumber;
    uint256 public avgBaseFee;

    function update() private {
        if ((block.number - lastUpdateBlockNumber) < ORACLE_UPDATE_COOLDOWN) return;
        lastUpdateBlockNumber = block.number;
        avgBaseFee = (block.basefee + (ORACLE_UPDATE_INVERSE_WEIGHT - 1) * avgBaseFee) / ORACLE_UPDATE_INVERSE_WEIGHT;
    }

    modifier Update() {
        update();
        _;
    }

    uint256 constant QUEUE_BOND = 1 ether;
    uint256 constant QUEUE_FEE_STEP = 2000;
    uint32 constant QUEUE_LENGTH = 100;

    /*//////////////////////////////////////////////////////////////
                        Contract storage & logic
    //////////////////////////////////////////////////////////////*/

    Pool[] pools;

    mapping(address => uint256) balances;

    function createPool(address[] calldata claimKinds) public returns (uint256) {
        uint256 curLength = pools.length;

        pools.push();

        for (uint256 i = 0; i < claimKinds.length; i++) {
            pools[curLength].claimKinds[claimKinds[i]] = true;
        }

        return curLength;
    }

    function withdraw(uint256 amount) external Update {
        balances[msg.sender] -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "err, Router::withdraw: failed to withdraw");
    }

    function withdrawAll() external Update {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "err, Router::withdrawAll: failed to withdraw");
    }

    function queueLength(uint256 poolId) public view returns (uint256) {
        Queue storage queue = pools[poolId].queue;
        return (queue.tail + QUEUE_LENGTH - queue.head) % QUEUE_LENGTH;
    }

    function queuePop(uint256 poolId) private Update returns (QueueEntry memory) {
        uint128 _head = pools[poolId].queue.head;
        uint128 _tail = pools[poolId].queue.tail;
        require(_head != _tail, "err, Router::queuePop: queue is empty");

        pools[poolId].queue.head = (_head + 1) % QUEUE_LENGTH;

        return pools[poolId].queue.entries[_head];
    }

    function queuePush(uint256 poolId, QueueEntry memory entry) private Update {
        uint128 _head = pools[poolId].queue.head;
        uint128 _tail = pools[poolId].queue.tail;
        require((_tail + 1 + QUEUE_LENGTH - _head) % QUEUE_LENGTH != 0, "err, Router::queuePush: queue is full");

        pools[poolId].queue.tail = (_tail + 1) % QUEUE_LENGTH;
        pools[poolId].queue.entries[_tail] = entry;
    }

    function enter(uint256 poolId, uint32 fee) external payable {
        require(poolId < pools.length, "err, Router::enter: no such pool");
        require(msg.value == QUEUE_BOND, "err, Router::enter: wrong bond");
        require(fee <= (QUEUE_LENGTH - queueLength(poolId)) * QUEUE_FEE_STEP, "err, Router::enter: wrong fee");

        QueueEntry memory entry = QueueEntry(msg.sender, fee);
        queuePush(poolId, entry);
    }
}
