pragma circom 2.1.9;
include "utils.circom";
include "ghash_gmul.circom";

// GHASH computes the authentication tag for AES-GCM.
// Inputs:
// - `HashKey` the hash key
// - `X` the input blocks
// 
// Outputs:
// - `tag` the authentication tag
//
//
//           X1                      X2          ...          XM 
//           │                       │                        │ 
//           ▼                       ▼                        ▼   
//  ┌────────────────┐          ┌──────────┐             ┌──────────┐ 
//  │ multiply by H  │   ┌─────▶│   XOR    │      ┌─────▶│   XOR    │ 
//  └────────┬───────┘   |      └────┬─────┘      |      └────┬─────┘ 
//           │           │           │            |           |
//           │           │           ▼            |           ▼
//           │           │   ┌────────────────┐   |   ┌────────────────┐ 
//           │           │   │ multiply by H  │   |   │ multiply by H  │ 
//           │           │   └───────┬────────┘   |   └───────┬────────┘ 
//           │           │           │            |           |
//           ▼           │           ▼            |           ▼
//      ┌─────────┐      │      ┌─────────┐       |      ┌─────────┐
//      │  TAG1   │ ─────┘      │   TAG2  │ ──────┘      │   TAGM  │
//      └─────────┘             └─────────┘              └─────────┘
// 
// TODO(WJ 2024-10-23): Question: why are we folding just three blocks? Ask Tracy about this.
// should only fold a single aes block at a time.
template GHASHFOLDABLE() {
    signal input HashKey[16]; // Hash subkey (128 bits)
    signal input msg[3][16]; // Input blocks (each 128 bits)

    // folding signals, the last tag. 
    signal input lastTag[16];
    // TODO(WJ 2024-10-23): Okay so not that we know that each ghash fold has a msg of 48 bytes: three 16 byte blocks
    // the next question is why we are outputting intermediate tags from the first three blocks?
    signal output possibleTags[3][16]; // Output tag (16 bytes)

    // Intermediate tags
    signal intermediate[4][16];
    intermediate[0] <== lastTag;

    component xor[3];
    component gfmul[3];

    // Accumulate each block using GHASH multiplication
    for (var i = 0; i < 3; i++) {
        xor[i] = XORBLOCK(16);
        gfmul[i] = GhashMul();

        // XOR current block with the previous intermediate result
        xor[i].a <== intermediate[i];
        xor[i].b <== msg[i];

        // Multiply the XOR result with the hash subkey H
        gfmul[i].X <== HashKey;
        gfmul[i].Y <== xor[i].out;

        // Store the result in the next intermediate tag
        intermediate[i+1] <== gfmul[i].out;
    }

    // For foldable ghash, we must output all intermediates and select the correct one 
    // dependent on where we are in the encryption process. 
    for (var i = 0; i < 3; i++) {
        possibleTags[i] <== intermediate[i+1];
    }
}