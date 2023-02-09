# <div align="center">Nouns Vortex: <br/>A privacy preserving voting for Nouns DAO</div>

## <div align="center">水 Design rationale and outline 水</div>


We would like to briefly state our general design goals, to ensure that we are on the same page with the DAO.

- Unconditional privacy.
- Minimal dependency on off-chain computation.
- - Ideally, voting should be on mainnet fully.
- Auditability, minimal external dependencies.
- Optimized gas costs.

We do not yet know what is exactly implied by Nounesness ⌐◨-◨, but we feel these should be the main points.

That leads us to some decisions. First of all, we regrettably reject any notion of non-coercibility. The best current solution in this direction is MACI, and while one of the authors works on improving its centralized dependencies, it is very far from being figured out.

We understand that voter collusion or bribing might be an issue, but we also do not feel that non-coercibility notion provides enough incentives against malicious 51% attacks; maybe only improves situation a little bit. Therefore, we would recommend DAO to continue using the veto power against bribing attacks, and at the same time to keep researching into the game-theoretic mechanisms allowing to eventually replace it (likely, with some sort of Schelling point mechanic and ragequit option).

Our technique is a merge of two approaches.

The main approach we want to employ is similar in nature to Tornado.Cash, Semaphore and similar projects. One of the authors have implemented it in [VoAn](https://voan.site). By design, it hides the voter identity, but can not hide the vote power. Naively, this can be fixed by requiring to vote with each Noun separately, but that is inconvenient.

Second approach is using homomorphic ElGamal encryption and lookup tables, similar to [Open Vote Network](https://eprint.iacr.org/2020/033). This approach is sound, however it requires every voter to not DoS the protocol after the first round. As we do not want to require everyone to deposit a big collateral, we use similar, but distinct method allowing us to separate voters from tally authorities. We require n-of-n secrecy threshold for them, and inclusion in the tally authorities must be permissionless; therefore DoS attack is possible. We, however, will require the collateral from an authority proportional to the expected cost of doing the voting in a non-efficient way described above; that way such an attacker would only delay the voting. Our design rationale here is that bigger accounts who benefit the most from this upgraded value hiding system will be likely able to present the required collateral and actually have an incentive to participate as authority to ensure the secrecy of their own vote.

We also use two additional techniques, one to deal with multisigs and hardware wallets, and one to deal with scalability.

For multisigs and hardware wallets, we suggest creating a key rotation mechanic, allowing any account (either EOA or smart contract) to register in the system. It then obtains a key which , internally, can act as a multisig with some reasonable threshold adjustable in a registration phase. We also provide a system which allows to commit to the vote from the account, in case this level of security is still not enough for some hardware wallet users.

*Should we implement ECDSA signature option which would support hardware wallets natively? It requires quite a beefy hardware to work, sorry state of affairs can be checked [here.](https://github.com/0xPARC/circom-ecdsa). Currently we believe it is optional.*

Second technique (which we call "mini-rollup") is our main gas cost optimization trick. It basically boils down to doing almost *everything* optimistically, namely, both validating the proofs and validating the required Merkle tree root. However, we argue that it doesn't incur most of the issues normally related to optimistic rollups because the challenge game is 1-round for proofs, and for Merkle tree it can be played in parallel with voting (this is the part where we are figuring out exact details). This also, apparently, gives the Nouns DAO an interesting promotion opportunity which we will describe further.

One could argue that we actually could instead scale the system using some custom zk-recursion technique. However, we believe such undertaking to be out of scale for this project, both in terms of our operational capability and auditability of dependencies. Therefore, we'd like to come up with surprisingly effective simple solution, not the one that is surprisingly hard to execute.

In what follows, we provide a description of each of these systems in detail, in the following order: registration, optimistic proof pool, homomorphic approach, fallback approach.