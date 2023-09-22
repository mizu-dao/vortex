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
        uint32 timestamp;
        uint256 collateral;
        uint256 blessing;
    }

    struct Queue {
        mapping(uint256 => QueueEntry) entries;
        uint32 tail;
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
    uint32 constant QUEUE_FEE_STEP = 2000;
    uint32 constant MAX_QUEUE_LENGTH = 100;
    uint32 constant GRACE_PERIOD = 21;
    uint32 constant RING_LENGTH = MAX_QUEUE_LENGTH + GRACE_PERIOD;

    uint32 constant BATCH_FREQUENCY = 2400;

    uint32 constant GAS_MAX = 300_000_000;

    uint32 constant BLESSING_PERIOD = 600;
    uint32 constant CANONICAL_BLESSING_PERIOD = BLESSING_PERIOD / 2;

    uint8 constant NO_BLESSER_STATUS_CODE = 3;
    uint8 constant EXPIRED_STATUS_CODE = 4;

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

    // head() - finalizing batch
    // head() + 1 - next batch to which blesser and claims will be added
    function enterQueue(uint256 poolId, uint32 fee) public payable {
        require(poolId < pools.length, "err, Router::enterQueue: no such pool");
        require(msg.value == QUEUE_BOND, "err, Router::enterQueue: wrong bond");

        uint32 tail = pools[poolId].queue.tail;
        uint32 head = _head() + 1;

        if (tail <= head) {
            require(fee <= MAX_QUEUE_LENGTH * QUEUE_FEE_STEP, "err, Router::enterQueue: wrong fee");

            pools[poolId].queue.entries[head % RING_LENGTH] = QueueEntry(msg.sender, fee, 0, head, 0, 0);
            pools[poolId].queue.tail = head + 1;
        } else {
            require(fee <= (MAX_QUEUE_LENGTH - (tail - head)) * QUEUE_FEE_STEP, "err, Router::enterQueue: wrong fee");

            pools[poolId].queue.entries[tail % RING_LENGTH] = QueueEntry(msg.sender, fee, 0, tail, 0, 0);
            pools[poolId].queue.tail = tail + 1;
        }
    }

    function addClaims(uint32 numNewClaims, uint256 poolId) external payable returns (uint32, uint256) {
        require(pools[poolId].claimKinds[msg.sender]);
        uint256 head = _head() + 1;
        QueueEntry memory _queueEntry = pools[poolId].queue.entries[head % RING_LENGTH];
        require(msg.value == uint256(numNewClaims) * uint256(_queueEntry.fee) * 1 gwei);
        require(pools[poolId].queue.tail > head);
        _queueEntry.numClaims += numNewClaims;
        pools[poolId].queue.entries[head % RING_LENGTH] = _queueEntry;
        return (_queueEntry.numClaims, head);
    }

    function bless(uint256 poolId, uint256[] calldata blessings) public payable Update {
        uint256 collateral = avgBaseFee * GAS_MAX;
        require(msg.value == collateral, "err: Router::bless: wrong collateral");
        require(poolId < pools.length, "err, Router::bless: no such pool");

        uint256 head = _head() % RING_LENGTH;
        require(pools[poolId].queue.entries[head].blessing == 0);
        require(pools[poolId].queue.entries[head].numClaims != 0);
        require(pools[poolId].queue.entries[head].timestamp == _head());

        uint256 slotBlockNumber = block.number % BATCH_FREQUENCY;
        require(slotBlockNumber < BLESSING_PERIOD);

        if (msg.sender != pools[poolId].queue.entries[head].guy) {
            require(slotBlockNumber >= CANONICAL_BLESSING_PERIOD);
        }

        pools[poolId].queue.entries[head].collateral = collateral;
        pools[poolId].queue.entries[head].guy = msg.sender;
        pools[poolId].queue.entries[head].blessing = uint256(keccak256(abi.encodePacked(blessings)));
    }

    function slash(
        uint256 poolId,
        uint256[] calldata blessings,
        uint256 challengeIndex,
        bool statement,
        address payable challenger
    ) public Update {
        require(pools[poolId].claimKinds[msg.sender], "err, Router::slash: claim kind is unauthorized");

        uint256 head = _head() % RING_LENGTH;

        uint256 blessing = uint256(keccak256(abi.encodePacked(blessings)));
        require(pools[poolId].queue.entries[head].blessing == blessing);
        require(pools[poolId].queue.entries[head].timestamp == _head());
        require(challengeIndex < pools[poolId].queue.entries[head].numClaims);

        uint256 x = challengeIndex / 256;
        uint256 y = challengeIndex - x * 256;

        bool claimedStatement;

        if (x < blessings.length) {
            claimedStatement = ((blessings[x] >> y) & 1 == 1);
        }

        require(claimedStatement != statement);

        pools[poolId].queue.entries[head].blessing = 0;

        uint256 collateral = pools[poolId].queue.entries[head].collateral;
        pools[poolId].queue.entries[head].collateral = 0;
        pools[poolId].queue.entries[head].guy = challenger;
        (bool success,) = challenger.call{value: collateral}("");
        require(success);
    }

    function check(uint256 poolId, uint256[] calldata blessings, uint256 position, uint256 batchId)
        public
        view
        returns (uint8)
    {
        uint256 batchIdMod = batchId % RING_LENGTH;
        uint32 timestamp = pools[poolId].queue.entries[batchIdMod].timestamp;

        if (timestamp + GRACE_PERIOD <= _head()) {
            return EXPIRED_STATUS_CODE;
        }
        if (pools[poolId].queue.entries[batchIdMod].blessing == 0) {
            return NO_BLESSER_STATUS_CODE;
        }

        uint256 blessing = uint256(keccak256(abi.encodePacked(blessings)));
        require(pools[poolId].queue.entries[batchIdMod].blessing == blessing);

        uint256 x = position / 256;
        uint256 y = position - x * 256;

        return uint8((blessings[x] >> y) & 1);
    }

    function withdraw(uint256 poolId, uint256 batchId) public {
        require(poolId < pools.length, "err, Router::slash: no such pool");

        uint256 head = _head();
        require(batchId < head);

        uint256 batchIdMod = batchId % RING_LENGTH;
        require(pools[poolId].queue.entries[batchIdMod].timestamp == batchId);

        QueueEntry memory entry = pools[poolId].queue.entries[batchIdMod];
        require(msg.sender == entry.guy);

        pools[poolId].queue.entries[batchIdMod].guy = address(0xDEAD);

        uint256 amount = entry.collateral + QUEUE_BOND + uint256(entry.numClaims) * uint256(entry.fee) * 1 gwei;
        (bool success,) = (msg.sender).call{value: amount}("");
        require(success);
    }

    function _head() internal view returns (uint32) {
        return uint32(block.number / BATCH_FREQUENCY);
    }
}
