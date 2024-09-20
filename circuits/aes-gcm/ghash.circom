pragma circom 2.1.9;
include "helper_functions.circom";
include "nistgmul.circom";

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
//           │                       ▼                        ▼   
//           │                  ┌──────────┐             ┌──────────┐ 
//           │           ┌─────▶│   XOR    │      ┌─────▶│   XOR    │ 
//           │           │      └────┬─────┘      │      └────┬─────┘ 
//           │           │           │            │           |
//           ▼           │           ▼            │           ▼
//  ┌────────────────┐   │   ┌────────────────┐   │   ┌────────────────┐ 
//  │ multiply by H  │   │   │ multiply by H  │   │   │ multiply by H  │ 
//  └────────┬───────┘   │   └───────┬────────┘   │   └───────┬────────┘ 
//           │           │           │            │           |
//           ▼           │           ▼            │           ▼
//      ┌─────────┐      │      ┌─────────┐       │      ┌─────────┐
//      │  TAG1   │ ─────┘      │   TAG2  │ ──────┘      │   TAGM  │
//      └─────────┘             └─────────┘              └─────────┘
// 
template GHASH(NUM_BLOCKS) {
    signal input HashKey[16]; // Hash subkey (128 bits)
    signal input msg[NUM_BLOCKS][16]; // Input blocks (each 128 bits)
    signal output tag[16]; // Output tag (128 bits)

    // Intermediate tags
    signal intermediate[NUM_BLOCKS+1][16];

    // Initialize first intermediate block to zero
    for (var j = 0; j < 16; j++) {
        intermediate[0][j] <== 0;
    }

    // Initialize components
    // two 64bit xor components for each block
    component xor[NUM_BLOCKS];
    // one gfmul component for each block
    component gfmul[NUM_BLOCKS];

    // Accumulate each block using GHASH multiplication
    for (var i = 0; i < NUM_BLOCKS; i++) {
        xor[i] = XORBLOCK(16);
        gfmul[i] = NistGMulByte();

        // XOR current block with the previous intermediate result
        xor[i].a <== intermediate[i];
        xor[i].b <== msg[i];

        // Multiply the XOR result with the hash subkey H
        gfmul[i].X <== HashKey;
        gfmul[i].Y <== xor[i].out;

        // Store the result in the next intermediate tag
        intermediate[i+1] <== gfmul[i].out;
    }

    // Final tag is the last intermediate block
    tag <== intermediate[NUM_BLOCKS];

}


// Transform the GHASH hash key to a POLYVAL hash key
// reverse the bits of `in` and multiply `h` by x
// 
// h.reverse();
// let mut h_polyval = polyval::mulx(&h);
// let result = GHash(Polyval::new_with_init_block(&h_polyval, init_block)); 
template TranslateHashkey() {
    signal input in[128]; 
    signal output out[128]; 

//     signal mid[128];

//     // reverse bytes
//     for (i = 0; i < 16; i++) {
//         for (j = 0; j < 8; j++){
//             var IDX_FROM = 120-i*8+j;
//             var IDX_TO = i*8+j;
//             mid[IDX_TO] <== in[IDX_FROM];
//         }
//     }

//     component MULX;
//     MULX = polyval_GFMULX();
//     for (i = 0; i < 128; i++){
//         MULX.in[i] <== mid[i];
//     }

//     out <== MULX.out;
// }
