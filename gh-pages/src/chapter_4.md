# <div align="center">Nouns Vortex: <br/>A privacy preserving voting for Nouns DAO</div>

## <div align="center">水 Optimistic proofs 水</div>

Here, we will explain our scaling mechanic.

First, let us recall that in normal Tornado Cash the user actually need to provide two proofs - one on the deposit, of the correct update of the Merkle tree, and the other on the withdrawal.


## Merkle tree update issue and possible solutions

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

## <div align="center"> Sub-proposal! </div>
## Nounism ⌐◨-◨ : an optimistic proof checker from Nouns ecosystem

This part of the system is a separate smart contract, which, in our opinon, should be exposed to everyone for potential integration. Nouns DAO, therefore, will be able to contribute to the general Ethereum ecosystem. Specifically, it will allow anyone to use the same system to check their proofs at low cost, in particular, any roll-up and any voting or financial privacy protocol will be able to use it. Prototype of one such application - communicated to authors by @twisterdev is expected to be presented on Eth Denver.

The basic features of contract are really simple. This is, basically, a pool for Groth16 proofs. Each proof is put there on a timelock, and after the required time has passed, it "matures".

Anyone, at any point, can challenge the immature proof and force it to be calculated. A small collateral needs to be deposited with the proof to ensure that it can pay for its gas.

Multiple proofs can be deposited in the same transaction, to also save on 27k gas for signature check.

---

The only subtle issue to be tackled is the size of collateral. We would like to make it fully automatic and ungoverned from the start, but it is impossible to fully predict the upcoming gas prices. While the condition of gas prices suddenly spiking and then staying consistently high for few days is unusual, this must be settled in some way. We have different ideas on this topic, the simplest one would be requiring at least 3x collateral based on observed avg gas price on last few deposits, and supporting a small (limited from above) automatic treasury that covers the gas cost in case of collateral deficit.

In the unlikely scenario when even this doesn't work (for example, treasure got depleted by an attacker using the same mechanic) it is still possible to slash them. Both Nouns Vortex and other possible applications have more than enough incentives to do it.