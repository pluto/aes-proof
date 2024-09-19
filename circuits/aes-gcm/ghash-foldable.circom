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

template GHASHFOLDABLE(NUM_BLOCKS) {
    signal input HashKey[4][4]; // Hash subkey (128 bits)
    signal input msg[NUM_BLOCKS][4][4]; // Input blocks (each 128 bits)

    // folding signals, the last tag. 
    signal input lastTag[4][4];

    signal output possibleTags[NUM_BLOCKS][128]; // Output tag (128 bits)

    // Janky convert [4][4] block into [2][64] bit lists
    // TODO: Double check the endianness of this conversion.
    signal hashBits[2][64];
    for(var i = 0; i < 4; i++) {
        for(var j = 0; j < 4; j++) {
            var bit = 1;
            var lc = 0;
            for(var k = 0; k < 8; k++) {
                var bitIndex = (i*4*8)+(j*8)+k;
                var bitValue = (HashKey[i][j] >> k) & 1;
                var rowIndex = bitIndex\64;
                var colIndex = bitIndex%64;
                hashBits[rowIndex][colIndex] <-- bitValue;
                hashBits[rowIndex][colIndex] * (hashBits[rowIndex][colIndex] - 1) === 0;
                lc += hashBits[rowIndex][colIndex] * bit;
                bit = bit+bit;
            }
            HashKey[i][j] === lc;
        }
    }

    signal msgBits[NUM_BLOCKS][2][64];
    for(var i = 0; i < NUM_BLOCKS; i++) {
        for(var j = 0; j < 4; j++) {
            for(var k=0; k < 4; k++) {
                var bit = 1;
                var lc = 0;
                for(var l = 0; l < 8; l++) {
                    var bitIndex = (j*4*8)+(k*8)+l;
                    var bitValue = (msg[i][j][k] >> l) & 1;
                    var rowIndex = bitIndex\64;
                    var colIndex = bitIndex%64;
                    msgBits[i][rowIndex][colIndex] <-- bitValue;
                    msgBits[i][rowIndex][colIndex] * (msgBits[i][rowIndex][colIndex] - 1) === 0;
                    lc += msgBits[i][rowIndex][colIndex] * bit;
                    bit = bit+bit;
                }
                msg[i][j][k] === lc;
            }
        }
    }

    signal lastTagBits[2][64];
    for(var i = 0; i < 4; i++) {
        for(var j = 0; j < 4; j++) {
            var bit = 1;
            var lc = 0;
            for(var k = 0; k < 8; k++) {
                var bitIndex = (i*4*8)+(j*8)+k;
                var bitValue = (lastTag[i][j] >> k) & 1;
                var rowIndex = bitIndex\64;
                var colIndex = bitIndex%64;
                lastTagBits[rowIndex][colIndex] <-- bitValue;
                lastTagBits[rowIndex][colIndex] * (lastTagBits[rowIndex][colIndex] - 1) === 0;
                lc += lastTagBits[rowIndex][colIndex] * bit;
                bit = bit+bit;
            }
            lastTag[i][j] === lc;
        }
    }

    // Intermediate tags
    signal intermediate[NUM_BLOCKS][2][64];

    // Initialize first intermediate to zero
    for (var j = 0; j < 64; j++) {
        intermediate[0][0][j] <== lastTagBits[0][j];  // Instead of starting at zero, start at lastTag. If it's the first block, start at zero.
        intermediate[0][1][j] <== lastTagBits[1][j];
    }

    // Initialize components
    // two 64bit xor components for each block
    component xor[NUM_BLOCKS][2];
    // one gfmul component for each block
    component gfmul[NUM_BLOCKS];

    for (var i = 1; i < NUM_BLOCKS; i++) {
        xor[i][0] = BitwiseXor(64);
        xor[i][1] = BitwiseXor(64);
        gfmul[i] = MUL();

        // XOR current block with the previous intermediate result
        // note: intermediate[0] is initialized to zero, so all rounds are valid
        xor[i][0].a <== intermediate[i-1][0];
        xor[i][1].a <== intermediate[i-1][1];
        xor[i][0].b <== msgBits[i][0];
        xor[i][1].b <== msgBits[i][1];

        // Multiply the XOR result with the hash subkey H
        gfmul[i].a[0] <== xor[i][0].out;
        gfmul[i].a[1] <== xor[i][1].out;
        gfmul[i].b <== hashBits;

        // Store the result in the next intermediate tag
        intermediate[i][0] <== gfmul[i].out[0];
        intermediate[i][1] <== gfmul[i].out[1];
    }

    // For foldable ghash, we must output all intermediates and select the correct one 
    // dependent on where we are in the encryption process. 
    //
    // Case 1: We are at the starting, tag is last one.
    // Case 2: We are in the middle, tag is first one.
    // Case 3: We are at the end, tag is second one. 


    // Assign the final tag
    for (var i = 0; i < NUM_BLOCKS; i++) {
        for (var j = 0; j < 64; j++) {
            possibleTags[i][j] <== intermediate[i][0][j];
            possibleTags[i][j+64] <== intermediate[i][1][j];
        }
    } 
}
