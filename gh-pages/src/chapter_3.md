# <div align="center">Nouns Vortex: <br/>A privacy preserving voting for Nouns DAO</div>

## <div align="center">水 Registration 水</div>

The registration phase looks as follows. Every account ``A`` can register in a system by sending a hash of the following pair: ``commit = H(key, force)``.

This is updateable, and will need a system similar to  ``ERC721Checkpointable.sol`` by Nouns DAO, because for a particular voting the snapshot of the commitment needs to be considered - notably, taken not at the proposal block (as done for Nouns count), but at the vote starting block.

In what follows, we will use proof-friendly primitives: Poseidon as hash function, denoted ``H``, and babyJubJub curve for the in-system elliptic curve operations.

Now, we explain what is contained in this commitment. It is not enforced at this stage, but it is an appropriate place for an explanation.

``key`` is a hash of the following data: 
```
{
    k, n: felt, // satisfying 0 <= k <= n <= LIMIT; suggest LIMIT=7;
    P[n] : pubkey // an array of n public keys in babyJubJub curve
    root: felt // a proof field element working as a seed for nullifiers
}
```

On the registration phase, we suggest multisignature users to translate their operational logic to our proof system, by choosing ``k`` and ``n`` corresponding to parameters of their multisig, and providing temporary public keys of each multisig party.

``force`` is either 0 or a root of a Merkle tree that contains in (some) leaves the enforced vote values in a form ``H(voting_id, vote_value)``. It basically just contains compressed commands that must be fulfilled by voting from this account.

This finishes the registration phase - no checks are done at this stage at all.