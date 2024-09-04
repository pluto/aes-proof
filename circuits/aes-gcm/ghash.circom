pragma circom 2.1.9;
include "helper_functions.circom";
include "gfmul.circom";

// GHASH computes the authentication tag for AES-GCM.
// Inputs:
// - `HashKey` the hash key
// - `X` the input blocks
// 
// Outputs:
// - `tag` the authentication tag
//
// TODO(WJ 2024-09-04): maybe move the below comment to the aes-gcm.circom file when it's ready
// Computes:
// let M = pad(AAD) || pad(msg) || len_64(AAD) || let_64(msg)
// X_0 = 0^128
// X_{i+1} = (X_i xor M_{i+1}) * H
// output: X_{n+1} where n is the number of blocks.
// GHASH Process
//
//           X1                     X2          ...          XM 
//           │                       │                        │ 
//           ▼                       ▼                        ▼   
//  ┌────────────────┐          ┌──────────┐             ┌──────────┐ 
//  │ multiply by H  │   ┌─────▶│   XOR    │      ┌─────▶│   XOR    │ 
//  └────────┬───────┘   |      └────┬─────┘      |      └────┬─────┘ 
//           │           │           │            |           |
//           ▼           │           ▼            |           ▼
//      ┌─────────┐      │   ┌────────────────┐   |   ┌────────────────┐ 
//      │  TAG1   │ ─────┘   │ multiply by H  │   |   │ multiply by H  │ 
//      └─────────┘          └───────┬────────┘   |   └───────┬────────┘ 
//                                   │            |           |
//                                   ▼            |           ▼
//                              ┌─────────┐       |      ┌─────────┐
//                              │   TAG2  │ ──────┘      │   TAGM  │
//                              └─────────┘              └─────────┘
// 

template GHASH(NUM_BLOCKS) {
    signal input HashKey[2][64]; // Hash subkey (128 bits)
    signal input X[NUM_BLOCKS][2][64]; // Input blocks (each 128 bits)
    signal output tag[2][64]; // Output tag (128 bits)

    // Intermediate tags
    signal intermediate[NUM_BLOCKS-1][2][64];

    // Initialize first intermediate to zero
    for (var j = 0; j < 64; j++) {
        intermediate[0][0][j] <== 0;
        intermediate[0][1][j] <== 0;
    }

    // Initialize components
    component xor[NUM_BLOCKS][2];
    component gfmul[NUM_BLOCKS];

    // Accumulate each block using GHASH multiplication
    for (var i = 0; i < NUM_BLOCKS; i++) {
        xor[i][0] = BitwiseXor(64);
        xor[i][1] = BitwiseXor(64);
        gfmul[i] = MUL();

        // XOR current block with the previous intermediate result
        // note: intermediate[0] is initialized to zero, so all rounds are valid
        xor[i][0].a <== intermediate[i][0];
        xor[i][0].b <== X[i][0];
        xor[i][1].a <== intermediate[i][1];
        xor[i][1].b <== X[i][1];

        // Multiply the XOR result with the hash subkey H
        for (var j = 0; j < 64; j++) {
            gfmul[i].a[0][j] <== xor[i][0].out[j];
            gfmul[i].a[1][j] <== xor[i][1].out[j];
        }
        gfmul[i].b <== HashKey;

        // Store the result in the next intermediate tag
        // TODO(WJ 2024-09-04): this is erroring on out of bounds even with this check 
        // i need to think about this more
         if (i < NUM_BLOCKS - 1) { 
            for (var j = 0; j < 64; j++) {
                intermediate[i+1][0][j] <== gfmul[i].out[0][j];
                intermediate[i+1][1][j] <== gfmul[i].out[1][j];
            }
        }
    }

    // Assign the final tag
    for (var j = 0; j < 64; j++) {
        tag[0][j] <== intermediate[NUM_BLOCKS][0][j];
        tag[1][j] <== intermediate[NUM_BLOCKS][1][j];
    }
}