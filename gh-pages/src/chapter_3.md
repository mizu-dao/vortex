# <div align="center">Nouns Vortex: <br/>A privacy preserving voting for Nouns DAO</div>

## <div align="center">水 Registration 水</div>

The registration phase looks as follows. Every account ``A`` can register in a system by sending a hash of the following pair: ``commit = H(key, force)``.

This is updateable, and will need a system similar to  ``ERC721Checkpointable.sol`` by Nouns DAO, because for a particular voting the snapshot of the commitment needs to be considered - notably, taken not at the proposal block (as done for Nouns count), but at the vote starting block.

In what follows, we will use proof-friendly primitives: Poseidon as hash function, denoted ``H``, and babyJubJub curve for the in-system elliptic curve operations.

Now, we explain what is contained in this commitment. It is not enforced at this stage, but it is an appropriate place for an explanation.

``key`` is a hash of the following data: 
```
{
    threshold, total: Fp, // satisfying 1 <= threshold <= total <= LIMIT; suggest LIMIT=7;
    pubkeys[total] : pubkey // an array of n public keys in babyJubJub curve
    seed : Fp // a random nonce used to produce nullifiers
}
```

On the registration phase, we suggest multisignature users to translate their operational logic to our proof system, by choosing ``threshold`` and ``total`` corresponding to parameters of their multisig, and providing temporary public keys of each multisig party.

``force`` is a root of a sparse Merkle tree which implements the key->value array, containing the enforced values (i.e., it has default value ``(0,0)``, and it having value either ``0, Y, N`` at leaf ``i`` means that in the proposal ``i`` this account will be able to vote only with corresponding value, ``0`` corresponding to abstaining, and ``Y`` and ``N`` being elliptic curve generators corresponding to "yes" and "no" votes). It basically just contains compressed commands that must be fulfilled by voting from this account.

This finishes the registration phase - no checks are done at this stage at all.