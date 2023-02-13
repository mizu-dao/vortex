# <div align="center">Nouns Vortex: <br/>A privacy preserving voting for Nouns DAO</div>

## <div align="center">水 Additional techniques 水</div>


For multisigs and hardware wallets, we suggest creating a key rotation mechanic, allowing any account (either EOA or smart contract) to register in the system. It then obtains a key which , internally, can act as a multisig with some reasonable threshold adjustable in a registration phase. We also provide a system which allows to commit to the vote from the account, in case this level of security is still not enough for some hardware wallet users.

*Should we implement ECDSA signature option which would support hardware wallets natively? It requires quite a beefy hardware to work, sorry state of affairs can be checked [here](https://github.com/0xPARC/circom-ecdsa). Currently we believe it is optional.*

Second technique (which we call "mini-rollup") is our main gas cost optimization trick. It basically boils down to doing almost *everything* optimistically, namely, both validating the proofs and validating the required Merkle tree root. However, we argue that it doesn't incur most of the issues normally related to optimistic rollups because the challenge game is 1-round for proofs, and for Merkle tree it can be played in parallel with voting (this is the part where we are figuring out exact details). This also, apparently, gives the Nouns DAO an interesting promotion opportunity which we will describe further.

One could argue that we actually could instead scale the system using some custom zk-recursion technique. However, we believe such undertaking to be out of scale for this project, both in terms of our operational capability and auditability of dependencies. Therefore, we'd like to come up with surprisingly effective simple solution, not the one that is surprisingly hard to execute.

In what follows, we provide a description of each of these systems in detail, in the following order: registration, optimistic proof pool, homomorphic approach, fallback approach.