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
    // Note: the input x here includes the aad and the ciphertext
    signal input X[NUM_BLOCKS][2][64]; // Input blocks (each 128 bits)
    signal output tag[2][64]; // Output tag (128 bits)

    // Initialize tag to zero
    signal Y[2][64];
    for (var i = 0; i < 64; i++) {
        Y[0][i] <== 0;
        Y[1][i] <== 0;
    }

    // Accumulate each block using GHASH multiplication
    for (var i = 0; i < NUM_BLOCKS; i++) {
        // XOR current block with the tag using BitwiseXor
        component xor0 = BitwiseXor(64);
        component xor1 = BitwiseXor(64);
        xor0.a <== Y[0];
        xor0.b <== X[i][0];
        xor1.a <== Y[1];
        xor1.b <== X[i][1];

        signal temp[2][64];
        for (var j = 0; j < 64; j++) {
            temp[0][j] <== xor0.out[j];
            temp[1][j] <== xor1.out[j];
        }

        // Multiply the accumulated tag with the hash subkey H
        component gfmul = MUL();
        gfmul.a <== temp;
        gfmul.b <== HashKey;

        // Update tag with the multiplication result
        for (var j = 0; j < 64; j++) {
            Y[0][j] <== gfmul.out[0][j];
            Y[1][j] <== gfmul.out[1][j];
        }
    }

    // Assign the final tag
    for (var i = 0; i < 64; i++) {
        tag[0][i] <== Y[0][i];
        tag[1][i] <== Y[1][i];
    }
}