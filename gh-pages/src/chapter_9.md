# <div align="center">Nouns Vortex: <br/>A privacy preserving voting for Nouns DAO</div>

## <div align="center">水 Optimistic pool 水</div>

Here, we outline our design of Optimistic Pool. It is an independent contract, serving as a co-processor to optimistically check large amount of independent operations. It could be treated as an optimistic rollup with extremely parallelized execution.

## High-level overview

Optimistic Pool holds a sequence of statements, called claims. Claims have types. Adding a new type is permissionless - typically, claim type is a particular kind of statement which needs to be checked - for example, a verifier for a certain zk-proof could be a claim type, (or maybe some other function which costs a lot of gas to verify directly).

In essence, claim type is just an external contract which is assumed to have a specific form. If it doesn't, validating it might be undesirable, so there is a way to opt out from validation of a specific claim type.

Claims periodically form batches - a sequence of claims which is then processed by the optimistic pool. When the batch is finalized, the special parties called blessers can declare which claims they deem correct (blessed), incorrect (cursed) or refuse to process. To do it in an orderly fashion, blessers form a queue.

To get into a queue, blesser needs to deposit a bond in ETH. Blessers can be challenged, and their stake will be taken if they:

* Bless some statement such that an actual ground truth checker for this claim type returns "false".

* Curse some statement such that ground truth checker returns "true".

* Process any statement and not process other statement *of the same type* in the same batch (censorship prevention).

Blessers collect small tips from the claimers.

After the end of the challenge period, it is possible to query a particular claim and check whether it got blessed. 

## API (wip)

This is an overview of the desired API. The actual implementation is not fully settled yet, there are some micro-optimizations possible.

---

``ClaimKind`` - an address of some external contract; there is an append-only, permissionless array of existing claim types, ``claimKindArray``.

``Claim`` - a struct ``(uint32 claimKindId, uint224 claimValue)``.

The ClaimKind contract is assumed to have some specific interface, in particular, it must have function which packs some data, obtains ``uint224`` value and calls ``deposit_claim(uint32 _claimKindId, uint224 _claimValue)`` payable function of the Optimistic Pool contract.

``deposit_claim`` does obvious checks (like ``msg.sender == claimKindArray[_claimKindId]``, and tip being enough), and adds the claim into the ``claimQueue``, which will be described further.

Typically, data should be packed using keccak hash from calldata, however, we have left the space for other implementations, considering the upcoming EIP4844 and other possible data availability solutions.

``check_claim(uint224 _claimValue, bytes[] _advice) returns bool`` - the function that checks whether the claim is correct or not. MUST return 0 if it is incorrect, 1 if it is correct, and revert in all other cases. It is not recommended to validate ClaimKind-s with checker functions not satisfying this requirement, as well as functions in which the result may change with time, or depend on sender address or other execution context.

---

``ClaimBatch`` - batched sequence of ``Claim``'s. Implementation details might vary, but likely it is some sort of append-only array. ClaimBatches occur every few hours, and ``deposit_claim`` only adds claims to the current batch.

``claimQueue`` is a sequence of ``ClaimBatch``-es. (in practice, it doesn't need to be an actual infinite queue, and will likely cycle once in a ~ month to save on the gas costs).

``Blessing`` - tightly packed sequence of 0, 1 and 2 - s + some auxiliary information.

* 0-s mean "Claim incorrect"
* 1-s mean "Claim correct"
* 2-s mean "Refuse to assess"

Auxiliary information is the ``claimedAmount`` of 0's and 1's in a blessing, and blesser address. *We are so lazy we do not even want to compute this, so instead it will be checked optimistically*.

---

Each ``ClaimBatch`` goes through the following process:

Formation --> Blessing period -> Challenge period --> Finalized

New claims can be added only during the formation period. In the blessing period, new blessings can occur. In both blessing and challenge period the blessings can be challenged, but in challenge period new blessings can not occur.

In the finalized state, external contracts can query and check whether the claim is blessed, cursed, or not processed. *we have also considered adding some automatic call-back system, but we feel it can be added independently and is not actually required by the core functionality of the contract.*

---

Blessings for a particular ``ClaimBatch`` are kept in the append-only array, together with ``address blesser`` and ``bool isInvalidated`` value.

Any blessing can be challenged using the following API:

``challenge_blessing(uint _batch_id, uint _blessing_id, bytes[] _challenge)`` which is a function that

* Checks that this blessing is ``!isInvalidated``.
* Parses ``_challenge`` and depending on these either:
* * Checks that ``claimedAmount`` is incorrect.
* * Checks that there are two elements satisfying censorship requirement (i.e. there are 2 claims of the same ClaimKind one of which is processed, and other is ignored).
* * Calls ``check_claim`` on the contested claim and checks that the answer differs from claimed by the blesser.
* In any of those cases, it sets ``isInvalidated = true``, and slashes the blesser.

---

Blessers form a blesser queue. In order to participate in a queue, one must call ``blesser_get_into_queue()``, which is a payable function, pledging the ``CURRENT_BOND_VALUE`` of eth.

Function ``bless(uint _batchId, Blessing _blessing)`` only works in the blessing period of the batch ``_batchId``. Moreover, for the first half of the blessing period the available blessers are only blessers from the queue - with a running requirement ``blesserOffset * CUTOFF_SPEED < block.timestamp - batchBlessingInitTimestamp``. In the end of the first half there should be ~10 blessers available. In the second half, anyone is allowed to bless.

Any blesser that is not the first one in the queue must still pledge the bond independently, and is not ejected from the queue (and by all means functions as a normal independent blesser).

---

In order to withdraw tips, blessers also use optimistic computations - with the exception of the main blesser (the one in the head of the queue), which can just take ``claimedAmount`` and leave.

Other blessers only get tips for things that they have blessed and previous ones did not. Therefore, in order to do it, they must submit a statement of a particular ``ClaimKind``, which consists of a withdrawal statement - sequence of 0s and 1s, with 1 meaning that the corresponding claim was blessed or cursed, and was not blessed or cursed by anyone before them, and ``amount`` being the amount of ``1``s. This statement is then processed normally using the aforementioned mechanism.

---

The system has few constants and few moving variables. Constants are ``BLESSING_PERIOD`` and ``CHALLENGE_PERIOD`` - these need to be chosen based on censorship-resistance properties of Ethereum, and the time required to socially coordinate challenge in case of known watchers being DOSed. We believe few hours are likely enough, and conservatively put ``CHALLENGE_PERIOD = 6 hours`` and ``BLESSING_PERIOD = 2 hours``.

Arguably, in a more mature system this could be much lower, though varying gas costs are also a concern. *compared to 7 day finality of classic multi-round optimistic rollup we believe this performance is still okay-ish for most applications; we are open to hear analysis of this problem from different PoVs*

The ``BATCH_FORMATION_PERIOD`` should optimally be quite big (up to 8 hours) to ensure there are enough statements to efficiently process. It can be lowered when batches become bigger, because the gas savings stop at ``log_3(2**256)``-sized batches (the maximal size such that ternary blessing word fits into ``uint256``).

---

Two main moving variables are ``CURRENT_BOND_VALUE`` and ``CURRENT_BASE_TIP_VALUE``. Each ClaimKind should also declare multiplier, which represents the amount of gas spent on checking the claim. Base tip value is then modified by this multiplier.

This part is largely "here be dragons", still, but we describe some way of adjusting them automatically.

1. Tip value grows if blesser queue is too short (say, less than 10) and lowers if blesser queue is too long (say, more than 100).

2. Collateral can not be smaller than some base value (say, ~1 ETH), and increases and decreases based on avg block base gas cost. This requires some sort of gas logging mechanism, but generally it doesn't need to be very precise. Generally, the potential to go into the failure mode only occurs if the gas spikes in such a way that cost of the singular challenge becomes > than collateral. This puts some upper limit on ``CLAIM_KIND_MULTIPLIER[_claimKindId]``, likely unachieveable due to block gas limit. Generally, targeting something like the cost of 300M gas (according to ``block.basefee`` averaged along few previous batches) should be a reasonably effective strategy. This value becomes bigger than 1 ETH at ~300 gwei sustained gas cost. The failure mode here would be gas spiking at least 30x times (for ClaimKind taking 10M gas to check) in an instant and staying there forever.

3. Even in the case of such failure mode, the bad challenges can be slashed at loss. One can consider dao-ish or even automatic treasury targeting some larger value, which can be automatically used in such a failure mode to compensate for slashing expenses. In such case, bottom for collateral and hence fee can be even lower than 1 ETH.