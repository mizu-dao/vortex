# <div align="center">Nouns Vortex: <br/>A privacy preserving voting for Nouns DAO</div>

## <div align="center">水 Tl ; dr 水</div>

Here we provide non-technical high-level explanation of our system.

1. Users can register and deploy public key (or even multisig), which they can then rotate at will by submitting the re-register transaction on-chain.

2. If user doesn't want to use hot private keys for voting at all, they can use an alternative system, which enforces the vote by submitting a commitment from the main account on-chain.

    * If there is a significant improvement in ecdsa-circom, the hardware wallets can be integrated directly, however, currently we believe this is infeasible for most users.

3. Otherwise, individual proposals do not require registration for voting.

4. Each proposal has a permissionless set of tallying authorities. To register as an authority, user must deposit a collateral. These authorities have n-of-n secrecy threshold to collectively read the voting power of individual votes (i.e., if they all collude, it is possible to de-anonymize votes of whale accounts). Therefore, we believe it will be rational for whale accounts interested in their privacy to register as the tallying authorities.

5. Due to having n-of-n secrecy threshold, it also has 1-of-n liveness threshold. In case any of the authorities fails to follow the protocol, they are slashed (and the collateral is used to compensate gas expenses). The voting then goes into the fallback mode.

6. Normal voting mode uses account-hiding mechanic similar to Tornado Cash, and El Gamal homomorphic encryption to encrypt votes (similar to Open Vote Network).

7. Fallback voting uses account-hiding mechanic, and allows user to vote ``s`` times if they have ``s`` voting power. Big accounts in this regime will need to send votes separately and ensure they can not be correlated using timing / ip sniffing.

8. All zero knowledge proofs can be submitted from any on-chain account. The community is advised to spin up a few relayer servers to pass these proofs in batches.

9. The proofs are submitted to optimistic proof-checking pool to drastically reduce the cost of the system.

10. Every voter's frontend has a .js script to check voting integrity and alert them in case of the submission of the incorrect proof.