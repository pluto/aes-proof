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
// Computes:
// Y_0 = 0^128
// Y_{i+1} = (Y_i xor X_{i-1}) * H
// output: Y_{n+1} where n is the number of blocks.
// GHASH Process
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

template GHASHFOLDABLE(NUM_BLOCKS) {
    signal input HashKey[16]; // Hash subkey (128 bits)
    signal input msg[NUM_BLOCKS][16]; // Input blocks (each 128 bits)

    // folding signals, the last tag. 
    signal input lastTag[16];
    signal output possibleTags[NUM_BLOCKS][16]; // Output tag (16 bytes)

    // Intermediate tags
    signal intermediate[NUM_BLOCKS+1][16];
    intermediate[0] <== lastTag;

    component xor[NUM_BLOCKS];
    component gfmul[NUM_BLOCKS];

    // Accumulate each block using GHASH multiplication
    for (var i = 0; i < NUM_BLOCKS; i++) {
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
    for (var i = 0; i < NUM_BLOCKS; i++) {
        possibleTags[i] <== intermediate[i+1];
    }
}