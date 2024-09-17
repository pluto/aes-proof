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

template GHASH(NUM_BLOCKS) {
    signal input HashKey[4][4]; // Hash subkey (128 bits)
    signal input msg[NUM_BLOCKS][4][4]; // Input blocks (each 128 bits)
    signal output tag[128]; // Output tag (128 bits)
    // signal output tag[2][64]; // Output tag (128 bits)

    // Janky convert [4][4] block into [2][64] bit lists
    // TODO: Double check the endianness of this conversion.
    signal hashBits[2][64];
    for(var i = 0; i < 4; i++) {
        for(var j = 0; j < 4; j++) {
            for(var k = 0; k < 8; k++) {
                var bitIndex = (i*4*8)+(j*8)+k;
                hashBits[bitIndex\64][bitIndex%64] <== (HashKey[i][j] >> k) & 1;
                hashBits[bitIndex\64][bitIndex%64] * (hashBits[bitIndex\64][bitIndex%64] - 1) === 0;
            }
        }
    }

    signal msgBits[NUM_BLOCKS][2][64];
    for(var i = 0; i < NUM_BLOCKS; i++) {
        for(var j = 0; j < 4; j++) {
            for(var k=0; k < 4; k++) {
                for(var l = 0; l < 8; l++) {
                    var bitIndex = (j*4*8)+(k*8)+l;
                    msgBits[i][bitIndex\64][bitIndex%64] <== (msg[i][j][k] >> l) & 1;
                    msgBits[i][bitIndex\64][bitIndex%64] * (msgBits[i][bitIndex\64][bitIndex%64] - 1) === 0;
                }
            }
        }
    }

    // Intermediate tags
    signal intermediate[NUM_BLOCKS][2][64];

    // Initialize first intermediate to zero
    for (var j = 0; j < 64; j++) {
        intermediate[0][0][j] <== 0;
        intermediate[0][1][j] <== 0;
    }

    // Initialize components
    // two 64bit xor components for each block
    component xor[NUM_BLOCKS][2];
    // one gfmul component for each block
    component gfmul[NUM_BLOCKS];

    // Accumulate each block using GHASH multiplication
    for (var i = 1; i < NUM_BLOCKS; i++) {
        xor[i][0] = BitwiseXor(64);
        xor[i][1] = BitwiseXor(64);
        gfmul[i] = MUL();

        // XOR current block with the previous intermediate result
        // note: intermediate[0] is initialized to zero, so all rounds are valid
        xor[i][0].a <== intermediate[i-1][0];
        xor[i][1].a <== intermediate[i-1][1];
        xor[i][0].b <== msg[i][0];
        xor[i][1].b <== msg[i][1];

        // Multiply the XOR result with the hash subkey H
        gfmul[i].a[0] <== xor[i][0].out;
        gfmul[i].a[1] <== xor[i][1].out;
        gfmul[i].b <== hashBits;

        // Store the result in the next intermediate tag
        intermediate[i][0] <== gfmul[i].out[0];
        intermediate[i][1] <== gfmul[i].out[1];
    }
    // Assign the final tag
    for (var j = 0; j < 64; j++) {
        tag[j] <== intermediate[NUM_BLOCKS-1][0][j];
        tag[j+64] <== intermediate[NUM_BLOCKS-1][1][j];
    }
    // tag[0] <== intermediate[NUM_BLOCKS-1][0];
    // tag[1] <== intermediate[NUM_BLOCKS-1][1];
}
