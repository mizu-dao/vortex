# <div align="center">Nouns Vortex: <br/>A privacy preserving voting for Nouns DAO</div>

## <div align="center">水 Required frontend infra 水</div>

Because our scheme heavily relies on (albeit simple, but still) optimistic validation, we believe that the best way to ensure its security is giving every user a tool to validate vote integrity.

We suggest that the frontend of the voting site is pinned in IPFS (which is generally a good practice), and there is a short snarkjs script verifying integrity of both the proving pool and initial Merkle tree - the scale more than admits it.