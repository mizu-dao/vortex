# <div align="center">Nouns Vortex: <br/>A privacy preserving voting for Nouns DAO</div>

## <div align="center">水 Merkle tree update 水</div>

First, let us recall that, for example, in Tornado Cash the user actually need to provide two proofs - one on the deposit, of the correct update of the Merkle tree, and the other on the withdrawal.

For Nouns Vortex, the tree update becomes a much more pressing issue. The appropriate "naive" way of doing it would involve changing ``ERC721Checkpointable.sol`` in such a way that any transfer or delegation would incur the update of a tree. This would incur a huge additional gas cost on every transfer, not to mention that it is actually just incompatible with allowance mechanic - smart contract is not able to provide us with the proof.

In our framework, the natural solution looks as follows: proposer, at the start of the voting, needs to send two transactions: first one "takes the snapshot", and the second one submits the Merkle tree root of all the accounts with nonzero voting power, ordered lexicographically, together with their snapshot states of voting power and ``commit``'s.

Now, we need some sort of the challenge game to prevent the proposer from submitting an incorrect Merkle root. The most naive game would be the following 1-round interaction:

```
Proposer: propose Merkle tree root, put up some collateral

Challenger: calculate Merkle tree root on-chain, if it is different - slash the proposer and take the collateral
```

This, however, requires a lot of gas. We are considering low-round games as possible replacement, to reduce collateral requirement on the proposer.

Generally, this is not too big of an issue, because this game can be played in parallel with normal voting flow (and any user that is executing a proof against an incorrect Merkle root is fraudulent anyway).

We reserve this part for further research.

*Addendum (19.02.2023):* there is an approach which reduces Merkle tree construction to the validation of the proving pool, described in the next chapter. This works roughly as follows:

1. Each nouns tx or redelegation is logged into the block chain of operations in a following way: ``head[n] = keccak(head[n-1], operation)``. This will incur additional ~3000 gas cost per tx.

2. In order to validate the new Merkle tree root, proposer needs to produce a proof with public inputs ``old_merkle_root``, ``old_head``, ``new_merkle_root``, ``new_head``, attesting the transition to the new Merkle tree. The amount of constraints in such a proof depends on the amount of txs between the last validated checkpoint and new checkpoint; therefore in case there were more than ~15 txs, multiple proofs will need to be constructed instead.

3. The cost of proof checking is relatively small thanks to the proving pool mechanism, described in the next chapter.