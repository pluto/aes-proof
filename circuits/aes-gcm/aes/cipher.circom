// from: https://github.com/crema-labs/aes-circom/tree/main/circuits
pragma circom 2.1.9;

include "key_expansion.circom";
include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/gates.circom";
include "transformations.circom";
include "mix_columns.circom";

// Cipher Process
// nk: number of keys which can be 4, 6, 8
// AES 128, 192, 256 have 10, 12, 14 rounds.
// Input Block   Initial Round Key          Round Key             Final Round Key
//     │                │                       │                       │
//     ▼                ▼                       ▼                       ▼
//  ┌─────────┐    ┌──────────┐ ┌────────┐ ┌──────────┐ ┌────────┐ ┌──────────┐
//  │ Block   │──► │   Add    │ │  Sub   │ │   Mix    │ │  Sub   │ │   Add    │
//  │         │    │  Round   │ │ Bytes  │ │ Columns  │ │ Bytes  │ │  Round   │
//  │         │    │   Key    │ │        │ │          │ │        │ │   Key    │
//  └─────────┘    └────┬─────┘ └───┬────┘ └────┬─────┘ └───┬────┘ └────┬─────┘
//                      │           │           │           │           │
//                      ▼           ▼           ▼           ▼           ▼
//                 ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
//                 │ Round 0 │ │ Round 1 │ │ Round 2 │ │ Round   │ │  Final  │
//                 │         │ │   to    │ │   to    │ │ Nr - 1  │ │  Round  │
//                 │         │ │ Nr - 2  │ │ Nr - 1  │ │         │ │         │
//                 └─────────┘ └─────────┘ └─────────┘ └─────────┘ └────┬────┘
//                                                                      │
//                                                                      ▼
//                                                                 Ciphertext


// @param nk: number of keys which can be 4, 6, 8
// @inputs block: 4x4 matrix representing the input block
// @inputs key: array of nk*4 bytes representing the key
// @outputs cipher: 4x4 matrix representing the output block
template Cipher(){
        signal input block[4][4];
        signal input key[16];
        signal output cipher[4][4];

        // var nr = Rounds(nk);
        
        component keyExpansion = KeyExpansion();
        keyExpansion.key <== key;

        component addRoundKey[11]; 
        component subBytes[10];
        component shiftRows[10];
        component mixColumns[9];

        signal interBlock[10][4][4];

        addRoundKey[0] = AddRoundKey();
        addRoundKey[0].state <== block;
        for (var i = 0; i < 4; i++) {
                addRoundKey[0].roundKey[i] <== keyExpansion.keyExpanded[i];
        }

        interBlock[0] <== addRoundKey[0].newState;
        for (var i = 1; i < 10; i++) {
                subBytes[i-1] = SubBlock();
                subBytes[i-1].state <== interBlock[i-1];

                shiftRows[i-1] = ShiftRows();
                shiftRows[i-1].state <== subBytes[i-1].newState;

                mixColumns[i-1] = MixColumns();
                mixColumns[i-1].state <== shiftRows[i-1].newState;

                addRoundKey[i] = AddRoundKey();
                addRoundKey[i].state <== mixColumns[i-1].out;
                 for (var j = 0; j < 4; j++) {
                        addRoundKey[i].roundKey[j] <== keyExpansion.keyExpanded[j + (i * 4)];
                }

                interBlock[i] <== addRoundKey[i].newState;
        }

        subBytes[9] = SubBlock();
        subBytes[9].state <== interBlock[9];

        shiftRows[9] = ShiftRows();
        shiftRows[9].state <== subBytes[9].newState;

        addRoundKey[10] = AddRoundKey();
        addRoundKey[10].state <== shiftRows[9].newState;
        for (var i = 0; i < 4; i++) {
                addRoundKey[10].roundKey[i] <== keyExpansion.keyExpanded[i + (40)];
        }

        cipher <== addRoundKey[10].newState;
}

// @param nk: number of keys which can be 4, 6, 8
// @returns number of rounds
// AES 128, 192, 256 have 10, 12, 14 rounds.
function Rounds (nk) {
    if (nk == 4) {
       return 10;
    } else if (nk == 6) {
        return 12;
    } else {
        return 14;
    }
}


