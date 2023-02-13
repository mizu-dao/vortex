# <div align="center">Nouns Vortex: <br/>A privacy preserving voting for Nouns DAO</div>

## <div align="center">水 Fallback scheme 水</div>

Here, we describe an alternative, simpler scheme which does not encrypt the vote value, and, instead allows to vote with Nouns separately.

It has few disadvantages; first of all, the on-going amount of yes/no votes is readily observable. Therefore, whale user trying to hide their activity will need a significant amount of effort: they will need to send votes at different timings, and, ideally, submit them to relayer from different ip addresses.

Because this effort is significant, we suggest that this scheme is only used as a fallback in case one of decryption authorities fails to provide the decryption. The gas cost of the scheme is also higher (due to each Noun being a separate vote); totally, this will determine the amount of collateral the decryption authority needs to provide.

The changes to the proof are fairly minimal:

1) Instead of exposing ``enc_vote``, it should expose ``vote_value`` itself.

2) Nullifier is calculated as ``null = H(key.root, voting_id, s)`` where ``0 <= s < nouns``. This ensures that the holder of ``nouns`` voting power can vote exactly ``nouns`` times.

Otherwise, the scheme is completely analogous.