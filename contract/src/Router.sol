// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

contract Router {
    /*//////////////////////////////////////////////////////////////
                            Helper Structs
    //////////////////////////////////////////////////////////////*/

    struct QueueEntry {
        address guy;
        uint32 fee;
        uint32 numClaims;
    }

    struct Queue {
        mapping(uint256 => QueueEntry) entries;
        uint256 tail;
    }

    struct Pool {
        mapping(address => bool) claimKinds;
        Queue queue;
        mapping(uint256 => uint256) batches;
    }

    // struct ClaimCounter {
    //     uint128 counter;
    //     uint128 lastUpdate;
    // }

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

    uint32 constant BLESSING_PERIOD = 600;
    uint32 constant CANONICAL_BLESSING_PERIOD = BLESSING_PERIOD / 2;

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

    // head() - это финализирующийся батч
    // head() + 1 - это батч в который добавляется клеймы и блессер
    function enterQueue(uint256 poolId, uint32 fee) public payable {
        require(poolId < pools.length, "err, Router::enterQueue: no such pool");
        require(msg.value == QUEUE_BOND, "err, Router::enterQueue: wrong bond");

        uint256 tail = pools[poolId].queue.tail;
        uint256 head = _head() + 1;

        if (tail <= head) {
            require(fee <= MAX_QUEUE_LENGTH * QUEUE_FEE_STEP, "err, Router::enterQueue: wrong fee");

            pools[poolId].queue.entries[head % (MAX_QUEUE_LENGTH + GRACE_PERIOD)] = QueueEntry(msg.sender, fee, 0);
            pools[poolId].queue.tail = head + 1;
        } else {
            require(fee <= (MAX_QUEUE_LENGTH - (tail - head)) * QUEUE_FEE_STEP, "err, Router::enterQueue: wrong fee");

            pools[poolId].queue.entries[tail % (MAX_QUEUE_LENGTH + GRACE_PERIOD)] = QueueEntry(msg.sender, fee, 0);
            pools[poolId].queue.tail = tail + 1;
        }
    }

    function addClaims(uint32 numNewClaims, uint256 poolId) external payable returns (uint256) {
        require(pools[poolId].claimKinds[msg.sender]);
        uint256 head = _head() + 1;
        QueueEntry memory _queueEntry = pools[poolId].queue.entries[head % (MAX_QUEUE_LENGTH + GRACE_PERIOD)];
        require(msg.value == numNewClaims * _queueEntry.fee);
        require(pools[poolId].queue.tail > head);
        _queueEntry.numClaims += numNewClaims;
        pools[poolId].queue.entries[head % (MAX_QUEUE_LENGTH + GRACE_PERIOD)] = _queueEntry;
        return _queueEntry.numClaims;
    }

    function bless(uint256 poolId, uint256[] calldata blessings) public payable Update {
        require(msg.value == avgBaseFee * GAS_MAX, "err: Router::bless: wrong collateral");
        require(poolId < pools.length, "err, Router::bless: no such pool");

        uint256 head = _head() % (MAX_QUEUE_LENGTH + GRACE_PERIOD);
        require(pools[poolId].batches[head] == 0);
        require(pools[poolId].queue.entries[head].numClaims != 0);

        uint256 slotBlockNumber = block.number % BATCH_FREQUENCY;
        require(slotBlockNumber < BLESSING_PERIOD);

        if (msg.sender != pools[poolId].queue.entries[head].guy) {
            require(slotBlockNumber >= CANONICAL_BLESSING_PERIOD);
        }

        pools[poolId].queue.entries[head].guy = msg.sender;
        pools[poolId].batches[head] = uint256(keccak256(abi.encodePacked(blessings)));
    }

    function slash(uint256 poolId, uint256[] calldata blessings, uint256 wrongIndex) public {}

    function _head() internal view returns (uint256) {
        return block.number / BATCH_FREQUENCY;
    }
}
