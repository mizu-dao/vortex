# <div align="center">Nouns Vortex: <br/>A privacy preserving voting for Nouns DAO</div>

## <div align="center">水 Homomorphic voting scheme 水</div>

We assume that we have achieved the following state:

- There is a Merkle tree with leaves ``leaf[i]`` where ``i`` runs through the set of all users who had non-zero voting balance at vote initialization block, in some canonical order. Leaf is calculated as ``leaf[i] = H(commit[i], nouns[i])``, where ``nouns`` is voting power at the checkpoint. In what follows, we assume this root is correct; otherwise, voting will be challenged and cancelled.

- There is a set of registered tally authorities, their decryption public keys live in the map ``auth_pub``. We assume that there is also a decyption public key ``D`` which is a sum of ``auth_pub``. It can be either calculated onchain, or also supplied by proposer and calculated optimistically.

- We also assume we are given some independent generators of babyJubJub, denoted ``G, Y, N``. 

Now, in order to vote, user needs to create the following proof.

Public inputs: ``voting_id, voting_merkle_root, null, enc_vote``, which are subject to the following relations:


* Public check: ``voting_id`` coincides with the current public voting id, ``voting_merkle_root`` coincides with supplied Merkle root.

* There exists the leaf of the Merkle tree ``voting_merkle_root``, denoted further as ``leaf``, which decomposes (eventually) to private inputs ``key, force, nouns``, subject to some relations:

* ``H(key.seed, voting_id) = null`` - unique nullifier to prevent double-voting

* There is an elliptic curve point ``vote_value`` which is subject to some additional relations:

    * The leaf  of the force Merkle tree ``force[i] == vote_value`` or ``force[i] == (0, 0)``.

    * If it was ``(0, 0)``, there are ``key.threshold`` signatures of the message ``(voting_id, H(vote_value, seed))`` with different public keys from an array ``key.pubkeys``. // here, additional hashing with seed done to prevent this signatures from revealing private information, so they can be exchanged over insecure channel

* ``vote_value = 0`` or ``Y`` or ``N``.


* The value ``enc_vote`` is a homomorphic El Gamal encryption of the vote, namely a pair of points: ``(C, K)``, where ``C = (vote_value * nouns) + (rand * D)`` and ``K = rand * G`` for some random scalar ``rand``.

Now, these proofs should be relayed on-chain and put in the proof-checking pool. We suggest that community spins up few public relayers for this purpose. Submitting proofs from some external EOA is fine, too, but it will require some collateral (relayers will require collateral too, but relatively small because they will submit proof in a batch).

When the proof-checking delay has passed, the resulting values ``enc_vote`` are submitted back and added up. This can also be done optimistically without much effort.

Let us denote the total sum of all valid ``enc_vote[i]`` as ``enc_result = (C_res, K_res)``.

Now, each decryption authourity ``i`` submits ``dec[i] = priv K_res`` with the proof that it was formed correctly with their private key ``priv`` satisfying ``priv*G = auth_pub[i]``. If they fail to submit it, they are slashed and the voting goes into fallback mode.

Denote ``dec`` to be sum of ``dec[i]``.

The ``res_point =  C_res - dec``. Now, anyone can provide values ``yay, nay`` such that ``yay*Y + nay*N = res_points``. The way to obtain these values is lookup. This lookup is quadratic in the amount of Nouns (which is fine on our scale), but if there will be more voting options, it is possible that the scheme will need to be altered a bit to instead send multiple points.