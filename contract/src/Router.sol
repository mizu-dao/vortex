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
        uint256 tail;
    }

    struct Batch {
        uint256 blessing;
        uint256 numberOfClaims;
    }

    struct Pool {
        mapping(address => bool) claimKinds;
        Queue queue;
        mapping(uint256 => Batch) batches;
    }

    /*//////////////////////////////////////////////////////////////
                  Helper fns, modifiers and constants
    //////////////////////////////////////////////////////////////*/

    uint32 constant ORACLE_UPDATE_COOLDOWN = 25;
    uint32 constant ORACLE_UPDATE_INVERSE_WEIGHT = 8;

    uint256 lastUpdateBlockNumber;
    uint256 public avgBaseFee;

    function update() internal {
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
    uint32 constant MAX_QUEUE_LENGTH = 100;
    uint32 constant GRACE_PERIOD = 16;

    uint32 constant BATCH_FREQUENCY = 2400;

    uint32 constant GAS_MAX = 300_000_000;

    /*//////////////////////////////////////////////////////////////
                        Contract storage & logic
    //////////////////////////////////////////////////////////////*/

    Pool[] pools;

    function createPool(address[] calldata claimKinds) public returns (uint256) {
        uint256 curLength = pools.length;

        pools.push();

        for (uint256 i = 0; i < claimKinds.length; i++) {
            pools[curLength].claimKinds[claimKinds[i]] = true;
        }

        return curLength;
    }

    function enterQueue(uint256 poolId, uint32 fee) public payable {
        require(poolId < pools.length, "err, Router::enterQueue: no such pool");
        require(msg.value == QUEUE_BOND, "err, Router::enterQueue: wrong bond");

        uint256 tail = pools[poolId].queue.tail;
        uint256 head = _head() + 1;

        if (tail <= head) {
            require(fee <= MAX_QUEUE_LENGTH * QUEUE_FEE_STEP, "err, Router::enterQueue: wrong fee");

            pools[poolId].queue.entries[head % (MAX_QUEUE_LENGTH + GRACE_PERIOD)] = QueueEntry(msg.sender, fee);
            pools[poolId].queue.tail = head + 1;
        } else {
            require(fee <= (MAX_QUEUE_LENGTH - (tail - head)) * QUEUE_FEE_STEP, "err, Router::enterQueue: wrong fee");

            pools[poolId].queue.entries[tail % (MAX_QUEUE_LENGTH + GRACE_PERIOD)] = QueueEntry(msg.sender, fee);
            pools[poolId].queue.tail = tail + 1;
        }
    }

    function bless(uint256 poolId, uint256[] calldata bless) public payable Update {
        require(msg.value == avgBaseFee * GAS_MAX, "err: Router::bless: wrong collateral");

        uint256 head = _head();
        // require(pools[poolId].queue.entries[head] == msg.)
    }

    function slash(uint256 poolId, uint256[] calldata bless, uint256 wrongIndex) public {}

    function _head() internal view returns (uint256) {
        return block.number / BATCH_FREQUENCY;
    }
}
