# <div align="center">Nouns Vortex: <br/>A privacy preserving voting for Nouns DAO</div>

## <div align="center">水 Nounism 水</div>

## <div align="center"> Sub-proposal! </div>
## Nounism ⌐◨-◨ : an optimistic proof checker from Nouns ecosystem

This part of the system is a separate smart contract, which, in our opinon, should be exposed to everyone for potential integration. Nouns DAO, therefore, will be able to contribute to the general Ethereum ecosystem. Specifically, it will allow anyone to use the same system to check their proofs at low cost, in particular, any roll-up and any voting or financial privacy protocol will be able to use it. Prototype of one such application - communicated to authors by @twisterdev is expected to be presented on Eth Denver.

The basic features of contract are really simple. This is, basically, a pool for Groth16 proofs. Each proof is put there on a timelock, and after the required time has passed, it "matures".

Anyone, at any point, can challenge the immature proof and force it to be calculated. A small collateral needs to be deposited with the proof to ensure that it can pay for its gas.

Multiple proofs can be deposited in the same transaction, to also save on 27k gas for signature check.

---

The only subtle issue to be tackled is the size of collateral. We would like to make it fully automatic and ungoverned from the start, but it is impossible to fully predict the upcoming gas prices. While the condition of gas prices suddenly spiking and then staying consistently high for few days is unusual, this must be settled in some way. We have different ideas on this topic, the simplest one would be requiring at least 3x collateral based on observed avg gas price on last few deposits, and supporting a small (limited from above) automatic treasury that covers the gas cost in case of collateral deficit.

In the unlikely scenario when even this doesn't work (for example, treasury got depleted by an attacker using the same mechanic) it is still possible to slash them. Both Nouns Vortex and other possible applications have more than enough incentives to do it.